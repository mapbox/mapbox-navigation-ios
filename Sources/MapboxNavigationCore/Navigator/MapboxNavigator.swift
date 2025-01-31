import _MapboxNavigationHelpers
import Combine
import Foundation
import MapboxDirections
@preconcurrency import MapboxNavigationNative

final class MapboxNavigator: @unchecked Sendable {
    struct Configuration: @unchecked Sendable {
        let navigator: CoreNavigator
        let routeParserType: RouteParser.Type
        let locationClient: LocationClient
        let alternativesAcceptionPolicy: AlternativeRoutesDetectionConfig.AcceptionPolicy?
        let billingHandler: BillingHandler
        let multilegAdvancing: CoreConfig.MultilegAdvanceMode
        let prefersOnlineRoute: Bool
        let disableBackgroundTrackingLocation: Bool
        let fasterRouteController: FasterRouteProvider?
        let electronicHorizonConfig: ElectronicHorizonConfig?
        let congestionConfig: CongestionRangesConfiguration
        let movementMonitor: NavigationMovementMonitor
    }

    actor NavigatorState {
        var privateRouteProgress: RouteProgress?
        var setRoutesTask: Task<Void, Never>?
        var previousArrivalWaypoint: MapboxDirections.Waypoint?

        func update(privateRouteProgress: RouteProgress?) async {
            self.privateRouteProgress = privateRouteProgress
        }

        func update(setRoutesTask: Task<Void, Never>?) {
            self.setRoutesTask?.cancel()
            self.setRoutesTask = setRoutesTask
        }

        func update(previousArrivalWaypoint: MapboxDirections.Waypoint?) {
            self.previousArrivalWaypoint = previousArrivalWaypoint
        }
    }

    // MARK: - Navigator Implementation

    @CurrentValuePublisher var session: AnyPublisher<Session, Never>
    @MainActor
    var currentSession: Session {
        _session.value
    }

    var privateSession: CurrentValuePublisher<Session> {
        _session
    }

    @CurrentValuePublisher var routeProgress: AnyPublisher<RouteProgressState?, Never>
    @MainActor
    var currentRouteProgress: RouteProgressState? {
        _routeProgress.value
    }

    @CurrentValuePublisher var mapMatching: AnyPublisher<MapMatchingState?, Never>
    @MainActor
    var currentMapMatching: MapMatchingState? {
        _mapMatching.value
    }

    @EventPublisher<FallbackToTilesState> var offlineFallbacks

    @EventPublisher<SpokenInstructionState> var voiceInstructions

    @EventPublisher<VisualInstructionState> var bannerInstructions

    @EventPublisher<WaypointArrivalStatus> var waypointsArrival

    @EventPublisher<ReroutingStatus> var rerouting

    @EventPublisher<AlternativesStatus> var continuousAlternatives

    @EventPublisher<FasterRoutesStatus> var fasterRoutes

    @EventPublisher<RefreshingStatus> var routeRefreshing

    @EventPublisher<EHorizonStatus> var eHorizonEvents

    @EventPublisher<NavigatorError> var errors

    var heading: AnyPublisher<CLHeading, Never> {
        locationClient.headings
    }

    @CurrentValuePublisher var navigationRoutes: AnyPublisher<NavigationRoutes?, Never>
    var currentNavigationRoutes: NavigationRoutes? {
        _navigationRoutes.value
    }

    let roadMatching: RoadMatching

    @MainActor
    func startActiveGuidance(with navigationRoutes: NavigationRoutes, startLegIndex: Int) {
        send(navigationRoutes)
        Task {
            await updateRouteProgress(with: navigationRoutes)
        }
        taskManager.withBarrier {
            setRoutes(
                navigationRoutes: navigationRoutes,
                startLegIndex: startLegIndex,
                reason: .newRoute
            )
        }
        let profile = navigationRoutes.mainRoute.route.legs.first?.profileIdentifier
        configuration.movementMonitor.currentProfile = profile
    }

    func startActiveGuidanceAsync(with navigationRoutes: NavigationRoutes, startLegIndex: Int) async {
        await send(navigationRoutes)

        await updateRouteProgress(with: navigationRoutes)

        await taskManager.withAsyncBarrier {
            await setRoutes(
                navigationRoutes: navigationRoutes,
                startLegIndex: startLegIndex,
                reason: .newRoute
            )
        }
        let profile = navigationRoutes.mainRoute.route.legs.first?.profileIdentifier
        configuration.movementMonitor.currentProfile = profile
    }

    func setToIdleAsync() async {
        await taskManager.withAsyncBarrier {
            let hadActiveGuidance = await billingSessionIsActive(withType: .activeGuidance)
            if let sessionUUID,
               await billingSessionIsActive()
            {
                billingHandler.pauseBillingSession(with: sessionUUID)
            }

            guard await currentSession.state != .idle else {
                Log.warning("Duplicate setting to idle state attempted", category: .navigation)
                await send(NavigatorErrors.FailedToSetToIdle())
                return
            }

            await send(NavigationRoutes?.none)
            await send(RouteProgressState?.none)
            await locationClient.stopUpdatingLocation()
            await locationClient.stopUpdatingHeading()
            await navigator.pause()

            guard hadActiveGuidance else {
                await send(Session(state: .idle))
                return
            }
            guard let sessionUUID = self.sessionUUID else {
                Log.error(
                    "`MapboxNavigator.setToIdle` failed to reset routes due to missing session ID.",
                    category: .billing
                )
                await send(NavigatorErrors.FailedToSetToIdle())
                return
            }

            do {
                try await navigator.unsetRoutes(uuid: sessionUUID)
            } catch {
                Log.warning(
                    "`MapboxNavigator.setToIdle` failed to reset routes with error: \(error)",
                    category: .navigation
                )
            }
            await self.send(Session(state: .idle))
            billingHandler.stopBillingSession(with: sessionUUID)
            self.sessionUUID = nil
        }
        configuration.movementMonitor.currentProfile = nil
    }

    func startFreeDriveAsync() async throws {
        await taskManager.withAsyncBarrier {
            let activeGuidanceSession = await verifyFreeDriveBillingSession()

            guard sessionUUID != nil else {
                Log.error(
                    "`MapboxNavigator.startFreeDrive` failed to start new session due to missing session ID.",
                    category: .billing
                )
                return
            }

            await send(NavigationRoutes?.none)
            await send(RouteProgressState?.none)
            await locationClient.startUpdatingLocation()
            await locationClient.startUpdatingHeading()
            await navigator.resume()
            if let activeGuidanceSession {
                do {
                    try await navigator.unsetRoutes(uuid: activeGuidanceSession)
                } catch {
                    Log.warning(
                        "`MapboxNavigator.startFreeDrive` failed to reset routes with error: \(error)",
                        category: .navigation
                    )
                }
            }

            await send(Session(state: .freeDrive(.active)))
        }
    }

    private let statusUpdateEvents: AsyncStreamBridge<NavigationStatus>

    enum SetRouteReason {
        case newRoute
        case reroute
        case alternatives
        case fasterRoute
        case fallbackToOffline
        case restoreToOnline
    }

    @MainActor
    func setRoutes(navigationRoutes: NavigationRoutes, startLegIndex: Int, reason: SetRouteReason) {
        verifyActiveGuidanceBillingSession(for: navigationRoutes)

        guard let sessionUUID else {
            Log.error(
                "Failed to set routes due to missing session ID.",
                category: .billing
            )
            send(NavigatorErrors.FailedToSetRoute(underlyingError: nil))
            return
        }

        locationClient.startUpdatingLocation()
        locationClient.startUpdatingHeading()
        navigator.resume()

        navigator.setRoutes(
            navigationRoutes.asRoutesData(),
            uuid: sessionUUID,
            legIndex: UInt32(startLegIndex),
            reason: reason.navNativeValue
        ) { [weak self] result in
            guard let self else { return }

            let newTask = Task.detached { [weak self] in
                guard let self else { return }

                switch result {
                case .success(let info):
                    var navigationRoutes = navigationRoutes
                    let alternativeRoutes = await AlternativeRoute.fromNative(
                        alternativeRoutes: info.alternativeRoutes,
                        relateveTo: navigationRoutes.mainRoute
                    )

                    guard !Task.isCancelled else { return }
                    navigationRoutes.allAlternativeRoutesWithIgnored = alternativeRoutes
                    await updateRouteProgress(with: navigationRoutes)
                    await send(navigationRoutes)
                    switch reason {
                    case .newRoute:
                        // Do nothing, routes updates are already sent
                        break
                    case .reroute:
                        await send(
                            ReroutingStatus(event: ReroutingStatus.Events.Fetched())
                        )
                    case .alternatives:
                        let event = AlternativesStatus.Events.SwitchedToAlternative(navigationRoutes: navigationRoutes)
                        await send(AlternativesStatus(event: event))
                    case .fasterRoute:
                        await send(FasterRoutesStatus(event: FasterRoutesStatus.Events.Applied()))
                    case .fallbackToOffline:
                        await send(
                            FallbackToTilesState(usingLatestTiles: false)
                        )
                    case .restoreToOnline:
                        await send(FallbackToTilesState(usingLatestTiles: true))
                    }
                    await send(Session(state: .activeGuidance(.uncertain)))
                case .failure(let error):
                    Log.error("Failed to set routes, error: \(error).", category: .navigation)
                    await send(NavigatorErrors.FailedToSetRoute(underlyingError: error))
                }
                await state.update(setRoutesTask: nil)
                await rerouteController?.abortReroutePipeline = navigationRoutes.isCustomExternalRoute
            }
            Task { [weak self] in
                await self?.state.update(setRoutesTask: newTask)
            }
        }
    }

    @MainActor
    func selectAlternativeRoute(at index: Int) {
        taskManager.cancellableTask { [weak self] in
            guard let self else { return }

            guard case .activeGuidance = await currentSession.state,
                  let alternativeRoutes = await currentNavigationRoutes?.selectingAlternativeRoute(at: index),
                  !Task.isCancelled
            else {
                Log.warning(
                    "Attempt to select invalid alternative route (index '\(index)' of alternatives - '\(String(describing: currentNavigationRoutes))').",
                    category: .navigation
                )
                await send(NavigatorErrors.FailedToSelectAlternativeRoute())
                return
            }

            await setRoutes(
                navigationRoutes: alternativeRoutes,
                startLegIndex: 0,
                reason: .alternatives
            )
        }
    }

    @MainActor
    func selectAlternativeRoute(with routeId: RouteId) {
        guard let index = currentNavigationRoutes?.alternativeRoutes.firstIndex(where: { $0.routeId == routeId }) else {
            Log.warning(
                "Attempt to select invalid alternative route with '\(routeId)' available ids - '\((currentNavigationRoutes?.alternativeRoutes ?? []).map(\.routeId))'",
                category: .navigation
            ); return
        }

        selectAlternativeRoute(at: index)
    }

    func switchLeg(newLegIndex: Int) {
        taskManager.cancellableTask { @MainActor [self] in
            guard case .activeGuidance = currentSession.state,
                  billingSessionIsActive(withType: .activeGuidance),
                  !Task.isCancelled
            else {
                Log.warning("Attempt to switch route leg while not in Active Guidance.", category: .navigation)
                return
            }

            navigator.updateRouteLeg(to: UInt32(newLegIndex)) { [weak self] success in
                Task { [weak self] in
                    if success {
                        guard let sessionUUID = self?.sessionUUID else {
                            Log.error(
                                "Route leg switching failed due to missing session ID.",
                                category: .billing
                            )
                            await self?.send(NavigatorErrors.FailedToSelectRouteLeg())
                            return
                        }
                        self?.billingHandler.beginNewBillingSessionIfExists(with: sessionUUID)
                        let event = WaypointArrivalStatus.Events.NextLegStarted(newLegIndex: newLegIndex)
                        await self?.send(WaypointArrivalStatus(event: event))
                    } else {
                        Log.warning("Route leg switching failed.", category: .navigation)
                        await self?.send(NavigatorErrors.FailedToSelectRouteLeg())
                    }
                }
            }
        }
    }

    @MainActor
    func setToIdle() {
        taskManager.withBarrier {
            let hadActiveGuidance = billingSessionIsActive(withType: .activeGuidance)
            if let sessionUUID,
               billingSessionIsActive()
            {
                billingHandler.pauseBillingSession(with: sessionUUID)
            }

            guard currentSession.state != .idle else {
                Log.warning("Duplicate setting to idle state attempted", category: .navigation)
                send(NavigatorErrors.FailedToSetToIdle())
                return
            }
            send(NavigationRoutes?.none)
            send(RouteProgressState?.none)
            locationClient.stopUpdatingLocation()
            locationClient.stopUpdatingHeading()
            navigator.pause()

            guard hadActiveGuidance else {
                send(Session(state: .idle))
                return
            }
            guard let sessionUUID = self.sessionUUID else {
                Log.error(
                    "`MapboxNavigator.setToIdle` failed to reset routes due to missing session ID.",
                    category: .billing
                )
                send(NavigatorErrors.FailedToSetToIdle())
                return
            }

            navigator.unsetRoutes(uuid: sessionUUID) { result in
                Task {
                    if case .failure(let error) = result {
                        Log.warning(
                            "`MapboxNavigator.setToIdle` failed to reset routes with error: \(error)",
                            category: .navigation
                        )
                    }
                    await self.send(Session(state: .idle))
                }
            }
            billingHandler.stopBillingSession(with: sessionUUID)
            self.sessionUUID = nil
        }
        configuration.movementMonitor.currentProfile = nil
    }

    @MainActor
    func startFreeDrive() {
        taskManager.withBarrier {
            let activeGuidanceSession = verifyFreeDriveBillingSession()

            guard sessionUUID != nil else {
                Log.error(
                    "`MapboxNavigator.startFreeDrive` failed to start new session due to missing session ID.",
                    category: .billing
                )
                return
            }
            send(NavigationRoutes?.none)
            send(RouteProgressState?.none)
            locationClient.startUpdatingLocation()
            locationClient.startUpdatingHeading()
            navigator.resume()
            if let activeGuidanceSession {
                navigator.unsetRoutes(uuid: activeGuidanceSession) { result in
                    Task {
                        if case .failure(let error) = result {
                            Log.warning(
                                "`MapboxNavigator.startFreeDrive` failed to reset routes with error: \(error)",
                                category: .navigation
                            )
                        }
                        await self.send(Session(state: .freeDrive(.active)))
                    }
                }
            } else {
                send(Session(state: .freeDrive(.active)))
            }
        }
        configuration.movementMonitor.currentProfile = nil
    }

    @MainActor
    func pauseFreeDrive() {
        taskManager.withBarrier {
            guard case .freeDrive = currentSession.state,
                  let sessionUUID,
                  billingSessionIsActive(withType: .freeDrive)
            else {
                send(NavigatorErrors.FailedToPause())
                Log.warning(
                    "Attempt to pause navigation while not in Free Drive.",
                    category: .navigation
                )
                return
            }
            locationClient.stopUpdatingLocation()
            locationClient.stopUpdatingHeading()
            navigator.pause()
            billingHandler.pauseBillingSession(with: sessionUUID)
            send(Session(state: .freeDrive(.paused)))
        }
    }

    func startUpdatingEHorizon() {
        guard let config = configuration.electronicHorizonConfig else {
            return
        }

        Task { @MainActor in
            navigator.startUpdatingElectronicHorizon(with: config)
        }
    }

    func stopUpdatingEHorizon() {
        Task { @MainActor in
            navigator.stopUpdatingElectronicHorizon()
        }
    }

    // MARK: - Billing checks

    @MainActor
    private func billingSessionIsActive(withType type: BillingHandler.SessionType? = nil) -> Bool {
        guard let sessionUUID,
              billingHandler.sessionState(uuid: sessionUUID) == .running
        else {
            return false
        }

        if let type,
           billingHandler.sessionType(uuid: sessionUUID) != type
        {
            return false
        }

        return true
    }

    @MainActor
    private func beginNewSession(of type: BillingHandler.SessionType) {
        let newSession = UUID()
        sessionUUID = newSession
        billingHandler.beginBillingSession(
            for: type,
            uuid: newSession
        )
    }

    @MainActor
    private func verifyActiveGuidanceBillingSession(for navigationRoutes: NavigationRoutes) {
        if let sessionUUID,
           let sessionType = billingHandler.sessionType(uuid: sessionUUID)
        {
            switch sessionType {
            case .freeDrive:
                billingHandler.stopBillingSession(with: sessionUUID)
                beginNewSession(of: .activeGuidance)
            case .activeGuidance:
                if billingHandler.shouldStartNewBillingSession(
                    for: navigationRoutes.mainRoute.route,
                    remainingWaypoints: currentRouteProgress?.routeProgress.remainingWaypoints ?? []
                ) {
                    billingHandler.stopBillingSession(with: sessionUUID)
                    beginNewSession(of: .activeGuidance)
                }
            }
        } else {
            beginNewSession(of: .activeGuidance)
        }
    }

    @MainActor
    private func verifyFreeDriveBillingSession() -> UUID? {
        if let sessionUUID,
           let sessionType = billingHandler.sessionType(uuid: sessionUUID)
        {
            switch sessionType {
            case .freeDrive:
                billingHandler.resumeBillingSession(with: sessionUUID)
            case .activeGuidance:
                billingHandler.stopBillingSession(with: sessionUUID)
                beginNewSession(of: .freeDrive)
                return sessionUUID
            }
        } else {
            beginNewSession(of: .freeDrive)
        }
        return nil
    }

    // MARK: - Implementation

    private let taskManager = TaskManager()

    @MainActor
    private let billingHandler: BillingHandler

    private var sessionUUID: UUID?

    private var navigator: CoreNavigator {
        configuration.navigator
    }

    private let configuration: Configuration

    @MainActor
    private var rerouteController: RerouteController?

    private let state = NavigatorState()

    private let locationClient: LocationClient

    @MainActor
    init(configuration: Configuration) {
        self.configuration = configuration
        self.locationClient = configuration.locationClient
        self.roadMatching = .init(
            roadGraph: configuration.navigator.roadGraph,
            roadObjectStore: configuration.navigator.roadObjectStore,
            roadObjectMatcher: configuration.navigator.roadObjectMatcher
        )

        self._session = .init(.init(state: .idle))
        self._mapMatching = .init(nil)
        self._offlineFallbacks = .init()
        self._voiceInstructions = .init()
        self._bannerInstructions = .init()
        self._waypointsArrival = .init()
        self._rerouting = .init()
        self._continuousAlternatives = .init()
        self._fasterRoutes = .init()
        self._routeRefreshing = .init()
        self._eHorizonEvents = .init()
        self._errors = .init()
        self._routeProgress = .init(nil)
        self._navigationRoutes = .init(nil)
        self.rerouteController = configuration.navigator.rerouteController
        self.billingHandler = configuration.billingHandler
        let statusUpdateEvents = AsyncStreamBridge<NavigationStatus>(bufferingPolicy: .bufferingNewest(1))
        self.statusUpdateEvents = statusUpdateEvents

        Task.detached { [weak self] in
            for await status in statusUpdateEvents {
                guard let self else { return }

                taskManager.cancellableTask {
                    await self.update(to: status)
                }
            }
        }

        subscribeNotifications()
        subscribeLocationUpdates()

        navigator.pause()
    }

    deinit {
        unsubscribeNotifications()
    }

    // MARK: - NavigationStatus processing

    private func updateRouteProgress(with routes: NavigationRoutes?) async {
        if let routes {
            let waypoints = routes.mainRoute.route.legs.enumerated()
                .reduce(into: [MapboxDirections.Waypoint]()) { partialResult, element in
                    if element.offset == 0 {
                        element.element.source.map { partialResult.append($0) }
                    }
                    element.element.destination.map { partialResult.append($0) }
                }
            let routeProgress = RouteProgress(
                navigationRoutes: routes,
                waypoints: waypoints,
                congestionConfiguration: configuration.congestionConfig
            )
            await state.update(privateRouteProgress: routeProgress)
            await send(RouteProgressState(routeProgress: routeProgress))
        } else {
            await state.update(privateRouteProgress: nil)
            await send(RouteProgressState?.none)
        }
    }

    private func update(to status: NavigationStatus) async {
        guard await currentSession.state != .idle else {
            await send(NavigatorErrors.UnexpectedNavigationStatus())
            Log.warning(
                "Received `NavigationStatus` while not in Active Guidance or Free Drive.",
                category: .navigation
            )
            return
        }

        guard await billingSessionIsActive() else {
            Log.error(
                "Received `NavigationStatus` while billing session is not running.",
                category: .billing
            )
            return
        }

        guard !Task.isCancelled else { return }
        await updateMapMatching(status: status)

        guard case .activeGuidance = await currentSession.state else {
            return
        }

        guard !Task.isCancelled else { return }
        await send(Session(state: .activeGuidance(.init(status.routeState))))

        guard !Task.isCancelled else { return }
        await updateIndices(status: status)
        await updateAlternativesPassingForkPoint(status: status)

        let routeProgress = await state.privateRouteProgress
        if let routeProgress, !Task.isCancelled {
            await send(RouteProgressState(routeProgress: routeProgress))
        }
        await handleRouteProgressUpdates(status: status, routeProgress: routeProgress)
    }

    func updateMapMatching(status: NavigationStatus) async {
        let snappedLocation = CLLocation(status.location)
        let roadName = status.localizedRoadName()

        let localeUnit: UnitSpeed? = {
            switch status.speedLimit.localeUnit {
            case .kilometresPerHour:
                return .kilometersPerHour
            case .milesPerHour:
                return .milesPerHour
            @unknown default:
                Log.fault("Unhandled speed limit locale unit: \(status.speedLimit.localeUnit)", category: .navigation)
                return nil
            }
        }()

        let signStandard: SignStandard = {
            switch status.speedLimit.localeSign {
            case .mutcd:
                return .mutcd
            case .vienna:
                return .viennaConvention
            @unknown default:
                Log.fault(
                    "Unknown native speed limit sign locale \(status.speedLimit.localeSign)",
                    category: .navigation
                )
                return .viennaConvention
            }
        }()

        let speedLimit: Measurement<UnitSpeed>? = {
            if let speed = status.speedLimit.speed?.doubleValue, let localeUnit {
                return Measurement(value: speed, unit: localeUnit)
            } else {
                return nil
            }
        }()

        let currentSpeedUnit: UnitSpeed = {
            if let localeUnit {
                return localeUnit
            } else {
                switch signStandard {
                case .mutcd:
                    return .milesPerHour
                case .viennaConvention:
                    return .kilometersPerHour
                }
            }
        }()

        await send(MapMatchingState(
            location: navigator.rawLocation ?? snappedLocation,
            mapMatchingResult: MapMatchingResult(status: status),
            speedLimit: SpeedLimit(
                value: speedLimit,
                signStandard: signStandard
            ),
            currentSpeed: Measurement<UnitSpeed>(
                value: CLLocation(status.location).speed,
                unit: .metersPerSecond
            ).converted(to: currentSpeedUnit),
            roadName: roadName.text.isEmpty ? nil : roadName
        ))
    }

    func handleRouteProgressUpdates(status: NavigationStatus, routeProgress: RouteProgress?) async {
        guard let routeProgress else { return }

        if let newSpokenInstruction = routeProgress.currentLegProgress.currentStepProgress
            .currentSpokenInstruction
        {
            await send(SpokenInstructionState(spokenInstruction: newSpokenInstruction))
        }

        if let newVisualInstruction = routeProgress.currentLegProgress.currentStepProgress
            .currentVisualInstruction
        {
            await send(VisualInstructionState(visualInstruction: newVisualInstruction))
        }

        let legProgress = routeProgress.currentLegProgress

        // We are at least at the "You will arrive" instruction
        if legProgress.remainingSteps.count <= 2 {
            if status.routeState == .complete {
                let previousArrivalWaypoint = await state.previousArrivalWaypoint
                guard previousArrivalWaypoint != legProgress.leg.destination else {
                    return
                }
                if let destination = legProgress.leg.destination {
                    await state.update(previousArrivalWaypoint: destination)
                    let event: any WaypointArrivalEvent = if routeProgress.isFinalLeg {
                        WaypointArrivalStatus.Events.ToFinalDestination(destination: destination)
                    } else {
                        WaypointArrivalStatus.Events.ToWaypoint(
                            waypoint: destination,
                            legIndex: routeProgress.legIndex
                        )
                    }
                    await send(WaypointArrivalStatus(event: event))
                }
                let advancesToNextLeg = switch configuration.multilegAdvancing {
                case .automatically:
                    true
                case .manually(let approval):
                    await approval(.init(arrivedLegIndex: routeProgress.legIndex))
                }
                guard !routeProgress.isFinalLeg, advancesToNextLeg else {
                    return
                }
                switchLeg(newLegIndex: Int(status.legIndex) + 1)
            }
        }
    }

    fileprivate func updateAlternativesPassingForkPoint(status: NavigationStatus) async {
        var routeProgress = await state.privateRouteProgress
        guard var navigationRoutes = currentNavigationRoutes else { return }

        guard navigationRoutes.updateForkPointPassed(with: status) else { return }

        routeProgress?.updateAlternativeRoutes(using: navigationRoutes)
        await state.update(privateRouteProgress: routeProgress)
        await send(navigationRoutes)
        let alternativesStatus = AlternativesStatus(
            event: AlternativesStatus.Events.Updated(
                actualAlternativeRoutes: navigationRoutes.alternativeRoutes
            )
        )
        await send(alternativesStatus)
    }

    func updateIndices(status: NavigationStatus) async {
        var routeProgress = await state.privateRouteProgress
        if let currentNavigationRoutes {
            routeProgress?.updateAlternativeRoutes(using: currentNavigationRoutes)
        }
        routeProgress?.update(using: status)
        await state.update(privateRouteProgress: routeProgress)
    }

    // MARK: - Notifications handling

    var subscriptions = Set<AnyCancellable>()

    @MainActor
    private func subscribeNotifications() {
        rerouteController?.delegate = self

        [
            // Navigator
            (Notification.Name.navigationDidSwitchToFallbackVersion, MapboxNavigator.fallbackToOffline(_:)),
            (Notification.Name.navigationDidSwitchToTargetVersion, MapboxNavigator.restoreToOnline(_:)),
            (Notification.Name.navigationStatusDidChange, MapboxNavigator.navigationStatusDidChange(_:)),
            (
                Notification.Name.navigatorDidChangeAlternativeRoutes,
                MapboxNavigator.navigatorDidChangeAlternativeRoutes(_:)
            ),
            (
                Notification.Name.navigatorDidFailToChangeAlternativeRoutes,
                MapboxNavigator.navigatorDidFailToChangeAlternativeRoutes(_:)
            ),
            (
                Notification.Name.navigatorWantsSwitchToCoincideOnlineRoute,
                MapboxNavigator.navigatorWantsSwitchToCoincideOnlineRoute(_:)
            ),
            (Notification.Name.routeRefreshDidUpdateAnnotations, MapboxNavigator.didRefreshAnnotations(_:)),
            (Notification.Name.routeRefreshDidFailRefresh, MapboxNavigator.didFailToRefreshAnnotations(_:)),
            // EH
            (
                Notification.Name.electronicHorizonDidUpdatePosition,
                MapboxNavigator.didUpdateElectronicHorizonPosition(_:)
            ),
            (
                Notification.Name.electronicHorizonDidEnterRoadObject,
                MapboxNavigator.didEnterElectronicHorizonRoadObject(_:)
            ),
            (
                Notification.Name.electronicHorizonDidExitRoadObject,
                MapboxNavigator.didExitElectronicHorizonRoadObject(_:)
            ),
            (
                Notification.Name.electronicHorizonDidPassRoadObject,
                MapboxNavigator.didPassElectronicHorizonRoadObject(_:)
            ),
        ]
            .forEach(subscribe(to:))

        subscribeFasterRouteController()
    }

    func disableTrackingBackgroundLocationIfNeeded() {
        Task {
            guard configuration.disableBackgroundTrackingLocation,
                  await currentSession.state == .freeDrive(.active)
            else {
                return
            }

            await pauseFreeDrive()
            await send(Session(state: .freeDrive(.active)))
        }
    }

    func restoreTrackingLocationIfNeeded() {
        Task {
            guard configuration.disableBackgroundTrackingLocation,
                  await currentSession.state == .freeDrive(.active)
            else {
                return
            }

            await startFreeDrive()
        }
    }

    private func subscribeLocationUpdates() {
        locationClient.locations
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self else { return }
                Task { @MainActor in
                    guard self.billingSessionIsActive() else {
                        Log.warning(
                            "Received location update while billing session is not running.",
                            category: .billing
                        )
                        return
                    }

                    self.navigator.updateLocation(location, completion: { _ in })
                }
            }.store(in: &subscriptions)
    }

    @MainActor
    private func subscribeFasterRouteController() {
        guard let fasterRouteController = configuration.fasterRouteController else { return }

        routeProgress
            .compactMap { $0 }
            .sink { currentRouteProgress in
                fasterRouteController.checkForFasterRoute(
                    from: currentRouteProgress.routeProgress
                )
            }
            .store(in: &subscriptions)

        navigationRoutes
            .sink { navigationRoutes in
                fasterRouteController.navigationRoute = navigationRoutes?.mainRoute
            }
            .store(in: &subscriptions)

        mapMatching
            .compactMap { $0 }
            .sink { mapMatch in
                fasterRouteController.currentLocation = mapMatch.enhancedLocation
            }
            .store(in: &subscriptions)

        rerouting
            .sink {
                fasterRouteController.isRerouting = $0.event is ReroutingStatus.Events.FetchingRoute
            }
            .store(in: &subscriptions)

        fasterRouteController.fasterRoutes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fasterRoutes in
                Task { [weak self] in
                    self?.send(
                        FasterRoutesStatus(
                            event: FasterRoutesStatus.Events.Detected()
                        )
                    )
                    self?.taskManager.cancellableTask { [weak self] in
                        guard !Task.isCancelled else { return }
                        await self?.setRoutes(
                            navigationRoutes: fasterRoutes,
                            startLegIndex: 0,
                            reason: .fasterRoute
                        )
                    }
                }
            }
            .store(in: &subscriptions)
    }

    private func subscribe(
        to item: (name: Notification.Name, sink: (MapboxNavigator) -> (Notification) -> Void)
    ) {
        NotificationCenter.default
            .publisher(for: item.name)
            .sink { [weak self] notification in
                self.map { item.sink($0)(notification) }
            }
            .store(in: &subscriptions)
    }

    private func unsubscribeNotifications() {
        subscriptions.removeAll()
    }

    func fallbackToOffline(_ notification: Notification) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            rerouteController = configuration.navigator.rerouteController
            rerouteController?.delegate = self

            let routeProgress = await state.privateRouteProgress

            guard let navigationRoutes = currentNavigationRoutes,
                  let routeProgress else { return }
            taskManager.cancellableTask { [weak self] in
                guard !Task.isCancelled else { return }
                await self?.setRoutes(
                    navigationRoutes: navigationRoutes,
                    startLegIndex: routeProgress.legIndex,
                    reason: .fallbackToOffline
                )
            }
        }
    }

    func restoreToOnline(_ notification: Notification) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            rerouteController = configuration.navigator.rerouteController
            rerouteController?.delegate = self

            let routeProgress = await state.privateRouteProgress

            guard let navigationRoutes = currentNavigationRoutes,
                  let routeProgress else { return }
            taskManager.cancellableTask { [weak self] in
                guard !Task.isCancelled else { return }
                await self?.setRoutes(
                    navigationRoutes: navigationRoutes,
                    startLegIndex: routeProgress.legIndex,
                    reason: .restoreToOnline
                )
            }
        }
    }

    private func navigationStatusDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let status = userInfo[NativeNavigator.NotificationUserInfoKey.statusKey] as? NavigationStatus
        else { return }
        statusUpdateEvents.yield(status)
    }

    private func navigatorDidChangeAlternativeRoutes(_ notification: Notification) {
        guard let alternativesAcceptionPolicy = configuration.alternativesAcceptionPolicy,
              let mainRoute = currentNavigationRoutes?.mainRoute,
              let userInfo = notification.userInfo,
              let alternatives =
              userInfo[NativeNavigator.NotificationUserInfoKey.alternativesListKey] as? [RouteAlternative]
        else {
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }

            navigator.setAlternativeRoutes(with: alternatives.map(\.route))
                { [weak self] result /* Result<[RouteAlternative], Error> */ in
                    guard let self else { return }

                    Task { [weak self] in
                        guard let self else { return }

                        switch result {
                        case .success(let routeAlternatives):
                            let alternativeRoutes = await AlternativeRoute.fromNative(
                                alternativeRoutes: routeAlternatives,
                                relateveTo: mainRoute
                            )

                            guard var navigationRoutes = currentNavigationRoutes else { return }
                            navigationRoutes.allAlternativeRoutesWithIgnored = alternativeRoutes
                                .filter { alternativeRoute in
                                    if alternativesAcceptionPolicy.contains(.unfiltered) {
                                        return true
                                    } else {
                                        if alternativesAcceptionPolicy.contains(.fasterRoutes),
                                           alternativeRoute.expectedTravelTimeDelta < 0
                                        {
                                            return true
                                        }
                                        if alternativesAcceptionPolicy.contains(.shorterRoutes),
                                           alternativeRoute.distanceDelta < 0
                                        {
                                            return true
                                        }
                                    }
                                    return false
                                }
                            if let status = navigator.mostRecentNavigationStatus {
                                navigationRoutes.updateForkPointPassed(with: status)
                            }
                            await send(navigationRoutes)
                            await send(
                                AlternativesStatus(
                                    event: AlternativesStatus.Events.Updated(
                                        actualAlternativeRoutes: navigationRoutes.alternativeRoutes
                                    )
                                )
                            )
                        case .failure(let updateError):
                            Log.warning(
                                "Failed to update alternative routes, error: \(updateError)",
                                category: .navigation
                            )
                            let error = NavigatorErrors.FailedToUpdateAlternativeRoutes(
                                localizedDescription: updateError.localizedDescription
                            )
                            await send(error)
                        }
                    }
                }
        }
    }

    private func navigatorDidFailToChangeAlternativeRoutes(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let message = userInfo[NativeNavigator.NotificationUserInfoKey.messageKey] as? String
        else {
            return
        }
        Log.error("Failed to change alternative routes: \(message)", category: .navigation)
        Task { @MainActor in
            send(NavigatorErrors.FailedToUpdateAlternativeRoutes(localizedDescription: message))
        }
    }

    private func navigatorWantsSwitchToCoincideOnlineRoute(_ notification: Notification) {
        guard configuration.prefersOnlineRoute,
              let userInfo = notification.userInfo,
              let onlineRoute =
              userInfo[NativeNavigator.NotificationUserInfoKey.coincideOnlineRouteKey] as? RouteInterface
        else {
            return
        }

        Task {
            guard let route = await NavigationRoute(nativeRoute: onlineRoute) else {
                return
            }

            let navigationRoutes = await NavigationRoutes(
                mainRoute: route,
                alternativeRoutes: []
            )

            taskManager.cancellableTask { [weak self] in
                guard let self else { return }

                guard !Task.isCancelled else { return }
                await setRoutes(
                    navigationRoutes: navigationRoutes,
                    startLegIndex: 0,
                    reason: .restoreToOnline
                )
            }
        }
    }

    func didUpdateElectronicHorizonPosition(_ notification: Notification) {
        guard let position = notification.userInfo?[RoadGraph.NotificationUserInfoKey.positionKey] as? RoadGraph
            .Position,
            let startingEdge = notification.userInfo?[RoadGraph.NotificationUserInfoKey.treeKey] as? RoadGraph.Edge,
            let updatesMostProbablePath = notification
                .userInfo?[RoadGraph.NotificationUserInfoKey.updatesMostProbablePathKey] as? Bool,
                let distancesByRoadObject = notification
                    .userInfo?[RoadGraph.NotificationUserInfoKey.distancesByRoadObjectKey] as? [DistancedRoadObject]
        else {
            return
        }

        let event = EHorizonStatus.Events.PositionUpdated(
            position: position,
            startingEdge: startingEdge,
            updatesMostProbablePath: updatesMostProbablePath,
            distances: distancesByRoadObject
        )
        Task { @MainActor in
            send(EHorizonStatus(event: event))
        }
    }

    func didEnterElectronicHorizonRoadObject(_ notification: Notification) {
        guard let objectId = notification
            .userInfo?[RoadGraph.NotificationUserInfoKey.roadObjectIdentifierKey] as? RoadObject.Identifier,
            let hasEnteredFromStart = notification
                .userInfo?[RoadGraph.NotificationUserInfoKey.didTransitionAtEndpointKey] as? Bool
        else {
            return
        }
        let event = EHorizonStatus.Events.RoadObjectEntered(
            roadObjectId: objectId,
            enteredFromStart: hasEnteredFromStart
        )

        Task { @MainActor in
            send(EHorizonStatus(event: event))
        }
    }

    func didExitElectronicHorizonRoadObject(_ notification: Notification) {
        guard let objectId = notification
            .userInfo?[RoadGraph.NotificationUserInfoKey.roadObjectIdentifierKey] as? RoadObject.Identifier,
            let hasExitedFromEnd = notification
                .userInfo?[RoadGraph.NotificationUserInfoKey.didTransitionAtEndpointKey] as? Bool
        else {
            return
        }
        let event = EHorizonStatus.Events.RoadObjectExited(
            roadObjectId: objectId,
            exitedFromEnd: hasExitedFromEnd
        )
        Task { @MainActor in
            send(EHorizonStatus(event: event))
        }
    }

    func didPassElectronicHorizonRoadObject(_ notification: Notification) {
        guard let objectId = notification
            .userInfo?[RoadGraph.NotificationUserInfoKey.roadObjectIdentifierKey] as? RoadObject.Identifier
        else {
            return
        }
        let event = EHorizonStatus.Events.RoadObjectPassed(roadObjectId: objectId)
        Task { @MainActor in
            send(EHorizonStatus(event: event))
        }
    }

    func didRefreshAnnotations(_ notification: Notification) {
        guard let refreshRouteResult = notification
            .userInfo?[NativeNavigator.NotificationUserInfoKey.refreshedRoutesResultKey] as? RouteRefreshResult,
            let legIndex = notification.userInfo?[NativeNavigator.NotificationUserInfoKey.legIndexKey] as? UInt32,
            let currentNavigationRoutes
        else {
            return
        }

        Task {
            guard case .activeGuidance = await currentSession.state else {
                return
            }

            var newMainRoute = currentNavigationRoutes.mainRoute
            let isMainRouteUpdate = refreshRouteResult.updatedRoute.getRouteId() ==
                currentNavigationRoutes.mainRoute.routeId.rawValue
            if isMainRouteUpdate {
                guard let updatedMainRoute = await NavigationRoute(nativeRoute: refreshRouteResult.updatedRoute)
                else { return }
                newMainRoute = updatedMainRoute
            }
            let event = RefreshingStatus.Events.Refreshing()
            await send(RefreshingStatus(event: event))

            var refreshedNavigationRoutes = await NavigationRoutes(
                mainRoute: newMainRoute,
                alternativeRoutes: await AlternativeRoute.fromNative(
                    alternativeRoutes: refreshRouteResult.alternativeRoutes,
                    relateveTo: newMainRoute
                )
            )
            if let status = self.navigator.mostRecentNavigationStatus {
                refreshedNavigationRoutes.updateForkPointPassed(with: status)
            }
            let routeProgress = await state.privateRouteProgress
            let updatedRouteProgress = routeProgress?.refreshingRoute(
                with: refreshedNavigationRoutes,
                legIndex: Int(legIndex),
                legShapeIndex: 0, // TODO: NN should provide this value in `MBNNRouteRefreshObserver`
                congestionConfiguration: configuration.congestionConfig
            )
            await state.update(privateRouteProgress: updatedRouteProgress)
            await self.send(refreshedNavigationRoutes)

            if let updatedRouteProgress {
                await send(RouteProgressState(routeProgress: updatedRouteProgress))
            }
            let endEvent = RefreshingStatus.Events.Refreshed()
            await send(RefreshingStatus(event: endEvent))
        }
    }

    func didFailToRefreshAnnotations(_ notification: Notification) {
        guard let refreshRouteFailure = notification
            .userInfo?[NativeNavigator.NotificationUserInfoKey.refreshRequestErrorKey] as? RouteRefreshError,
            refreshRouteFailure.refreshTtl == 0,
            let currentNavigationRoutes
        else {
            return
        }

        Task {
            await send(
                RefreshingStatus(
                    event: RefreshingStatus.Events.Invalidated(
                        navigationRoutes: currentNavigationRoutes
                    )
                )
            )
        }
    }
}

// MARK: - ReroutingControllerDelegate

extension MapboxNavigator: ReroutingControllerDelegate {
    func rerouteControllerWantsSwitchToAlternative(
        _ rerouteController: RerouteController,
        route: RouteInterface,
        legIndex: Int
    ) {
        Task {
            guard let navigationRoute = await NavigationRoute(nativeRoute: route) else {
                return
            }

            taskManager.cancellableTask { [weak self] in
                guard let self else { return }

                guard !Task.isCancelled else { return }
                await setRoutes(
                    navigationRoutes: NavigationRoutes(
                        mainRoute: navigationRoute,
                        alternativeRoutes: []
                    ),
                    startLegIndex: legIndex,
                    reason: .alternatives
                )
            }
        }
    }

    func rerouteControllerDidDetectReroute(_ rerouteController: RerouteController) {
        Log.debug("Reroute was detected.", category: .navigation)
        Task { @MainActor in
            send(
                ReroutingStatus(
                    event: ReroutingStatus.Events.FetchingRoute()
                )
            )
        }
    }

    func rerouteControllerDidReceiveReroute(_ rerouteController: RerouteController, routesData: RoutesData) {
        Log.debug(
            "Reroute was fetched with primary route id '\(routesData.primaryRoute().getRouteId())' and \(routesData.alternativeRoutes().count) alternative route(s).",
            category: .navigation
        )
        Task {
            guard let navigationRoutes = try? await NavigationRoutes(routesData: routesData) else {
                Log.error(
                    "Reroute was fetched but could not convert it to `NavigationRoutes`.",
                    category: .navigation
                )
                return
            }
            taskManager.cancellableTask { [weak self] in
                guard let self else { return }

                guard !Task.isCancelled else { return }
                await setRoutes(
                    navigationRoutes: navigationRoutes,
                    startLegIndex: 0,
                    reason: .reroute
                )
            }
        }
    }

    func rerouteControllerDidCancelReroute(_ rerouteController: RerouteController) {
        Log.warning("Reroute was cancelled.", category: .navigation)
        Task { @MainActor in
            send(
                ReroutingStatus(
                    event: ReroutingStatus.Events.Interrupted()
                )
            )
            send(NavigatorErrors.InterruptedReroute(underlyingError: nil))
        }
    }

    func rerouteControllerDidFailToReroute(_ rerouteController: RerouteController, with error: DirectionsError) {
        Log.error("Failed to reroute, error: \(error)", category: .navigation)
        Task { @MainActor in
            send(
                ReroutingStatus(
                    event: ReroutingStatus.Events.Failed(error: error)
                )
            )
            send(NavigatorErrors.InterruptedReroute(underlyingError: error))
        }
    }
}

extension MapboxNavigator {
    @MainActor
    private func send(_ details: NavigationRoutes?) {
        if details == nil {
            Task {
                await state.update(previousArrivalWaypoint: nil)
            }
        }
        _navigationRoutes.emit(details)
    }

    @MainActor
    private func send(_ details: Session) {
        _session.emit(details)
    }

    @MainActor
    private func send(_ details: MapMatchingState) {
        _mapMatching.emit(details)
    }

    @MainActor
    private func send(_ details: RouteProgressState?) {
        _routeProgress.emit(details)
    }

    @MainActor
    private func send(_ details: FallbackToTilesState) {
        _offlineFallbacks.emit(details)
    }

    @MainActor
    private func send(_ details: SpokenInstructionState) {
        _voiceInstructions.emit(details)
    }

    @MainActor
    private func send(_ details: VisualInstructionState) {
        _bannerInstructions.emit(details)
    }

    @MainActor
    private func send(_ details: WaypointArrivalStatus) {
        _waypointsArrival.emit(details)
    }

    @MainActor
    private func send(_ details: ReroutingStatus) {
        _rerouting.emit(details)
    }

    @MainActor
    private func send(_ details: AlternativesStatus) {
        _continuousAlternatives.emit(details)
    }

    @MainActor
    private func send(_ details: FasterRoutesStatus) {
        _fasterRoutes.emit(details)
    }

    @MainActor
    private func send(_ details: RefreshingStatus) {
        _routeRefreshing.emit(details)
    }

    @MainActor
    private func send(_ details: NavigatorError) {
        _errors.emit(details)
    }

    @MainActor
    private func send(_ details: EHorizonStatus) {
        _eHorizonEvents.emit(details)
    }
}

// MARK: - TaskManager

extension MapboxNavigator {
    fileprivate final class TaskManager: Sendable {
        private let tasksInFlight_ = UnfairLocked([String: Task<Void, any Error>]())
        func cancellableTask(
            id: String = #function,
            operation: @Sendable @escaping () async throws -> Void
        ) rethrows {
            Task {
                defer {
                    _ = tasksInFlight_.mutate {
                        $0.removeValue(forKey: id)
                    }
                }

                guard !barrier.read() else { return }
                let task = Task { try await operation() }
                tasksInFlight_.mutate {
                    $0[id]?.cancel()
                    $0[id] = task
                }
                _ = try await task.value
            }
        }

        func cancelTasks() {
            tasksInFlight_.mutate {
                $0.forEach {
                    $0.value.cancel()
                }
                $0.removeAll()
            }
        }

        private let barrier: UnfairLocked = .init(false)

        @MainActor
        func withBarrier(_ operation: () -> Void) {
            barrier.update(true)
            cancelTasks()
            operation()
            barrier.update(false)
        }

        @MainActor
        func withAsyncBarrier(_ operation: () async -> Void) async {
            barrier.update(true)
            cancelTasks()
            await operation()
            barrier.update(false)
        }
    }
}

extension MapboxNavigator.SetRouteReason {
    var navNativeValue: MapboxNavigationNative.SetRoutesReason {
        switch self {
        case .newRoute:
            return .newRoute
        case .alternatives:
            return .alternative
        case .reroute:
            return .reroute
        case .fallbackToOffline:
            return .fallbackToOffline
        case .restoreToOnline:
            return .restoreToOnline
        case .fasterRoute:
            return .fastestRoute
        }
    }
}

extension NavigationRoutes {
    @discardableResult
    mutating func updateForkPointPassed(with status: NavigationStatus) -> Bool {
        let newPassedForkPointRouteIds = Set(
            status.alternativeRouteIndices
                .compactMap { $0.isForkPointPassed ? $0.routeId : nil }
        )
        let oldPassedForkPointRouteIds = Set(
            allAlternativeRoutesWithIgnored
                .compactMap { $0.isForkPointPassed ? $0.routeId.rawValue : nil }
        )
        guard newPassedForkPointRouteIds != oldPassedForkPointRouteIds else { return false }

        for (index, route) in allAlternativeRoutesWithIgnored.enumerated() {
            allAlternativeRoutesWithIgnored[index].isForkPointPassed =
                newPassedForkPointRouteIds.contains(route.routeId.rawValue)
        }
        return true
    }
}
