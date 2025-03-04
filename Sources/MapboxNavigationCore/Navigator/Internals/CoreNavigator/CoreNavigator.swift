import CoreLocation
import MapboxCommon_Private
import MapboxDirections
import MapboxNavigationNative
import UIKit

protocol CoreNavigator {
    var rawLocation: CLLocation? { get }
    var mostRecentNavigationStatus: NavigationStatus? { get }
    var tileStore: TileStore { get }
    var roadGraph: RoadGraph { get }
    var roadObjectStore: RoadObjectStore { get }
    var roadObjectMatcher: RoadObjectMatcher { get }
    var rerouteController: RerouteController? { get }

    @MainActor
    func startUpdatingElectronicHorizon(with options: ElectronicHorizonConfig?)
    @MainActor
    func stopUpdatingElectronicHorizon()

    @MainActor
    func setRoutes(
        _ routesData: RoutesData,
        uuid: UUID,
        legIndex: UInt32,
        reason: SetRoutesReason,
        completion: @escaping @Sendable (Result<RoutesCoordinator.RoutesResult, Error>) -> Void
    )
    @MainActor
    func setAlternativeRoutes(
        with routes: [RouteInterface],
        completion: @escaping @Sendable (Result<[RouteAlternative], Error>) -> Void
    )
    @MainActor
    func updateRouteLeg(to index: UInt32, completion: @escaping @Sendable (Bool) -> Void)
    @MainActor
    func unsetRoutes(
        uuid: UUID,
        completion: @escaping @Sendable (Result<RoutesCoordinator.RoutesResult, Error>) -> Void
    )

    func unsetRoutes(uuid: UUID) async throws

    @MainActor
    func updateLocation(_ location: CLLocation, completion: @escaping @Sendable (Bool) -> Void)

    @MainActor
    func resume()
    @MainActor
    func pause()
}

final class NativeNavigator: CoreNavigator, @unchecked Sendable {
    struct Configuration: @unchecked Sendable {
        let credentials: ApiConfiguration
        let nativeHandlersFactory: NativeHandlersFactory
        let routingConfig: RoutingConfig
        let predictiveCacheManager: PredictiveCacheManager?
    }

    let configuration: Configuration

    private(set) var navigator: NavigationNativeNavigator
    private(set) var telemetrySessionManager: NavigationSessionManager

    private(set) var cacheHandle: CacheHandle

    var mostRecentNavigationStatus: NavigationStatus? {
        navigatorStatusObserver?.mostRecentNavigationStatus
    }

    private(set) var rawLocation: CLLocation?

    private(set) var tileStore: TileStore

    // Current Navigator status in terms of tile versioning.
    var tileVersionState: NavigatorFallbackVersionsObserver.TileVersionState {
        navigatorFallbackVersionsObserver?.tileVersionState ?? .nominal
    }

    @MainActor
    private lazy var routeCoordinator: RoutesCoordinator = .init(
        routesSetupHandler: { @MainActor [weak self] routesData, legIndex, reason, completion in

            let dataParams = routesData.map { SetRoutesDataParams(
                routes: $0,
                legIndex: legIndex
            ) }

            self?.navigator.native.setRoutesDataFor(
                dataParams,
                reason: reason
            ) { [weak self] result in
                if result.isValue(),
                   let routesResult = result.value
                {
                    Log.info(
                        "Navigator has been updated, including \(routesResult.alternatives.count) alternatives.",
                        category: .navigation
                    )
                    completion(.success((routesData?.primaryRoute().getRouteInfo(), routesResult.alternatives)))
                } else if result.isError() {
                    let reason = (result.error as String?) ?? ""
                    Log.error("Failed to update navigator with reason: \(reason)", category: .navigation)
                    completion(.failure(NativeNavigatorError.failedToUpdateRoutes(reason: reason)))
                } else {
                    assertionFailure("Invalid Expected value: \(result)")
                    completion(.failure(
                        NativeNavigatorError
                            .failedToUpdateRoutes(reason: "Unexpected internal response")
                    ))
                }
            }
        },
        alternativeRoutesSetupHandler: { @MainActor [weak self] routes, completion in
            self?.navigator.native.setAlternativeRoutesForRoutes(routes, callback: { result in
                if result.isValue(),
                   let alternatives = result.value as? [RouteAlternative]
                {
                    Log.info(
                        "Navigator alternative routes has been updated (\(alternatives.count) alternatives set).",
                        category: .navigation
                    )
                    completion(.success(alternatives))
                } else {
                    let reason = (result.error as String?) ?? ""
                    Log.error(
                        "Failed to update navigator alternative routes with reason: \(reason)",
                        category: .navigation
                    )
                    completion(.failure(NativeNavigatorError.failedToUpdateAlternativeRoutes(reason: reason)))
                }
            })
        }
    )

    private(set) var rerouteController: RerouteController?

    @MainActor
    init(with configuration: Configuration) {
        self.configuration = configuration

        let factory = configuration.nativeHandlersFactory
        self.tileStore = factory.tileStore
        self.cacheHandle = factory.cacheHandle
        self.roadGraph = factory.roadGraph
        self.navigator = factory.navigator
        self.telemetrySessionManager = NavigationSessionManagerImp(navigator: navigator)
        self.roadObjectStore = RoadObjectStore(navigator.native.roadObjectStore())
        self.roadObjectMatcher = RoadObjectMatcher(MapboxNavigationNative.RoadObjectMatcher(cache: cacheHandle))
        self.rerouteController = RerouteController(
            configuration: .init(
                credentials: configuration.credentials,
                navigator: navigator,
                configHandle: factory.configHandle(),
                rerouteConfig: configuration.routingConfig.rerouteConfig,
                initialManeuverAvoidanceRadius: configuration.routingConfig.initialManeuverAvoidanceRadius
            )
        )

        subscribeNavigator()
        setupAlternativesControllerIfNeeded()
        setupPredictiveCacheIfNeeded()
        subscribeToNotifications()
    }

    /// Destroys and creates new instance of Navigator together with other related entities.
    ///
    /// Typically, this method is used to restart a Navigator with a specific Version during switching to offline or
    /// online modes.
    /// - Parameter version: String representing a tile version name. `nil` value means "latest". Specifying exact
    /// version also enables `fallback` mode which will passively monitor newer version available and will notify
    /// `tileVersionState` if found.
    @MainActor
    func restartNavigator(forcing version: String? = nil) {
        let previousNavigationSessionState = navigator.native.storeNavigationSession()
        let previousSession = telemetrySessionManager as? NavigationSessionManagerImp
        unsubscribeNavigator()
        navigator.native.shutdown()

        let factory = configuration.nativeHandlersFactory.targeting(version: version)

        tileStore = factory.tileStore
        cacheHandle = factory.cacheHandle
        roadGraph = factory.roadGraph
        navigator = factory.navigator

        navigator.native.restoreNavigationSession(for: previousNavigationSessionState)
        telemetrySessionManager = NavigationSessionManagerImp(navigator: navigator, previousSession: previousSession)
        roadObjectStore.native = navigator.native.roadObjectStore()
        roadObjectMatcher.native = MapboxNavigationNative.RoadObjectMatcher(cache: cacheHandle)
        rerouteController = RerouteController(
            configuration: .init(
                credentials: configuration.credentials,
                navigator: navigator,
                configHandle: factory.configHandle(),
                rerouteConfig: configuration.routingConfig.rerouteConfig,
                initialManeuverAvoidanceRadius: configuration.routingConfig.initialManeuverAvoidanceRadius
            )
        )

        subscribeNavigator()
        setupAlternativesControllerIfNeeded()
        setupPredictiveCacheIfNeeded()
    }

    // MARK: - Subscriptions

    private weak var navigatorStatusObserver: NavigatorStatusObserver?
    private weak var navigatorFallbackVersionsObserver: NavigatorFallbackVersionsObserver?
    private weak var navigatorElectronicHorizonObserver: NavigatorElectronicHorizonObserver?
    private weak var navigatorAlternativesObserver: NavigatorRouteAlternativesObserver?
    private weak var navigatorRouteRefreshObserver: NavigatorRouteRefreshObserver?

    private func setupPredictiveCacheIfNeeded() {
        guard let predictiveCacheManager = configuration.predictiveCacheManager,
              case .nominal = tileVersionState else { return }

        Task { @MainActor in
            predictiveCacheManager.updateNavigationController(with: navigator)
            predictiveCacheManager.updateSearchController(with: navigator)
        }
    }

    @MainActor
    private func setupAlternativesControllerIfNeeded() {
        guard let alternativeRoutesDetectionConfig = configuration.routingConfig.alternativeRoutesDetectionConfig
        else { return }

        guard let refreshIntervalSeconds = UInt16(exactly: alternativeRoutesDetectionConfig.refreshIntervalSeconds)
        else {
            assertionFailure("'refreshIntervalSeconds' has an unexpected value.")
            return
        }

        let configManeuverAvoidanceRadius = configuration.routingConfig.initialManeuverAvoidanceRadius
        guard let initialManeuverAvoidanceRadius = Float(exactly: configManeuverAvoidanceRadius) else {
            assertionFailure("'initialManeuverAvoidanceRadius' has an unexpected value.")
            return
        }

        navigator.native.getRouteAlternativesController().setRouteAlternativesOptionsFor(
            RouteAlternativesOptions(
                requestIntervalSeconds: refreshIntervalSeconds,
                minTimeBeforeManeuverSeconds: initialManeuverAvoidanceRadius
            )
        )
    }

    @MainActor
    fileprivate func subscribeContinuousAlternatives() {
        if configuration.routingConfig.alternativeRoutesDetectionConfig != nil {
            let alternativesObserver = NavigatorRouteAlternativesObserver()
            navigatorAlternativesObserver = alternativesObserver
            navigator.native.getRouteAlternativesController().addObserver(for: alternativesObserver)
        } else if let navigatorAlternativesObserver {
            navigator.native.getRouteAlternativesController().removeObserver(for: navigatorAlternativesObserver)
            self.navigatorAlternativesObserver = nil
        }
    }

    @MainActor
    fileprivate func subscribeFallbackObserver() {
        let versionsObserver = NavigatorFallbackVersionsObserver(restartCallback: { [weak self] targetVersion in
            if let self {
                _Concurrency.Task { @MainActor in
                    self.restartNavigator(forcing: targetVersion)
                }
            }
        })
        navigatorFallbackVersionsObserver = versionsObserver
        navigator.native.setFallbackVersionsObserverFor(versionsObserver)
    }

    @MainActor
    fileprivate func subscribeStatusObserver() {
        let statusObserver = NavigatorStatusObserver()
        navigatorStatusObserver = statusObserver
        navigator.native.addObserver(for: statusObserver)
    }

    @MainActor
    fileprivate func subscribeElectornicHorizon() {
        guard isSubscribedToElectronicHorizon else {
            return
        }
        startUpdatingElectronicHorizon(
            with: electronicHorizonConfig,
            on: navigator
        )
    }

    @MainActor
    fileprivate func subscribeRouteRefreshing() {
        guard let refreshPeriod = configuration.routingConfig.routeRefreshPeriod else {
            return
        }

        let refreshObserver = NavigatorRouteRefreshObserver(refreshCallback: { [weak self] in
            guard let self else { return nil }

            guard let primaryRoute = navigator.native.getPrimaryRoute() else { return nil }
            return RouteRefreshResult(
                updatedRoute: primaryRoute,
                alternativeRoutes: navigator.native.getAlternativeRoutes()
            )
        })
        navigator.native.addRouteRefreshObserver(for: refreshObserver)
        navigator.native.startRoutesRefresh(
            forDefaultRefreshPeriodMs: UInt64(refreshPeriod * 1000),
            ignoreExpirationTime: true
        )
    }

    @MainActor
    private func subscribeNavigator() {
        subscribeElectornicHorizon()
        subscribeStatusObserver()
        subscribeFallbackObserver()
        subscribeContinuousAlternatives()
        subscribeRouteRefreshing()
    }

    fileprivate func unsubscribeRouteRefreshing() {
        guard let navigatorRouteRefreshObserver else {
            return
        }
        navigator.removeRouteRefreshObserver(
            for: navigatorRouteRefreshObserver
        )
    }

    fileprivate func unsubscribeContinuousAlternatives() {
        guard let navigatorAlternativesObserver else {
            return
        }
        navigator.removeRouteAlternativesObserver(
            navigatorAlternativesObserver
        )
        self.navigatorAlternativesObserver = nil
    }

    fileprivate func unsubscribeFallbackObserver() {
        navigator.setFallbackVersionsObserverFor(
            nil
        )
    }

    fileprivate func unsubscribeStatusObserver() {
        if let navigatorStatusObserver {
            navigator.removeObserver(
                for: navigatorStatusObserver
            )
        }
    }

    private func unsubscribeNavigator() {
        stopUpdatingElectronicHorizon(on: navigator)
        unsubscribeStatusObserver()
        unsubscribeFallbackObserver()
        unsubscribeContinuousAlternatives()
        unsubscribeRouteRefreshing()
    }

    // MARK: - Electronic horizon

    private(set) var roadGraph: RoadGraph

    private(set) var roadObjectStore: RoadObjectStore

    private(set) var roadObjectMatcher: RoadObjectMatcher

    private var isSubscribedToElectronicHorizon = false

    private var electronicHorizonConfig: ElectronicHorizonConfig? {
        didSet {
            let nativeOptions = electronicHorizonConfig.map(MapboxNavigationNative.ElectronicHorizonOptions.init)
            navigator.setElectronicHorizonOptionsFor(
                nativeOptions
            )
        }
    }

    @MainActor
    func startUpdatingElectronicHorizon(with config: ElectronicHorizonConfig?) {
        startUpdatingElectronicHorizon(with: config, on: navigator)
    }

    @MainActor
    private func startUpdatingElectronicHorizon(
        with config: ElectronicHorizonConfig?,
        on navigator: NavigationNativeNavigator
    ) {
        isSubscribedToElectronicHorizon = true

        let observer = NavigatorElectronicHorizonObserver()
        navigatorElectronicHorizonObserver = observer
        navigator.native.setElectronicHorizonObserverFor(observer)
        electronicHorizonConfig = config
    }

    @MainActor
    func stopUpdatingElectronicHorizon() {
        stopUpdatingElectronicHorizon(on: navigator)
    }

    private func stopUpdatingElectronicHorizon(on navigator: NavigationNativeNavigator) {
        isSubscribedToElectronicHorizon = false
        navigator.setElectronicHorizonObserverFor(nil)
        electronicHorizonConfig = nil
    }

    // MARK: - Navigator Updates

    @MainActor
    func setRoutes(
        _ routesData: RoutesData,
        uuid: UUID,
        legIndex: UInt32,
        reason: SetRoutesReason,
        completion: @escaping (Result<RoutesCoordinator.RoutesResult, Error>) -> Void
    ) {
        routeCoordinator.beginActiveNavigation(
            with: routesData,
            uuid: uuid,
            legIndex: legIndex,
            reason: reason,
            completion: completion
        )
    }

    @MainActor
    func setAlternativeRoutes(
        with routes: [RouteInterface],
        completion: @escaping (Result<[RouteAlternative], Error>) -> Void
    ) {
        routeCoordinator.updateAlternativeRoutes(with: routes, completion: completion)
    }

    @MainActor
    func updateRouteLeg(to index: UInt32, completion: @escaping (Bool) -> Void) {
        let legIndex = UInt32(index)

        navigator.native.changeLeg(forLeg: legIndex, callback: completion)
    }

    @MainActor
    func unsetRoutes(uuid: UUID, completion: @escaping (Result<RoutesCoordinator.RoutesResult, Error>) -> Void) {
        routeCoordinator.endActiveNavigation(with: uuid, completion: completion)
    }

    @MainActor
    func unsetRoutes(uuid: UUID) async throws {
        try await withCheckedThrowingContinuation { continuation in
            routeCoordinator.endActiveNavigation(with: uuid) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let failure):
                    continuation.resume(throwing: failure)
                }
            }
        }
    }

    @MainActor
    func updateLocation(_ rawLocation: CLLocation, completion: @escaping (Bool) -> Void) {
        self.rawLocation = rawLocation
        navigator.native.updateLocation(for: FixLocation(rawLocation), callback: completion)
    }

    @MainActor
    func pause() {
        navigator.native.pause()
        telemetrySessionManager.reportStopNavigation()
    }

    @MainActor
    func resume() {
        navigator.native.resume()
        telemetrySessionManager.reportStartNavigation()
    }

    deinit {
        unsubscribeNavigator()
        if let predictiveCacheManager = configuration.predictiveCacheManager {
            Task { @MainActor in
                predictiveCacheManager.updateNavigationController(with: nil)
                predictiveCacheManager.updateSearchController(with: nil)
            }
        }
    }

    private func subscribeToNotifications() {
        _Concurrency.Task { @MainActor in
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(applicationWillTerminate),
                name: UIApplication.willTerminateNotification,
                object: nil
            )
        }
    }

    @objc
    private func applicationWillTerminate(_ notification: NSNotification) {
        telemetrySessionManager.reportStopNavigation()
    }
}

enum NativeNavigatorError: Swift.Error {
    case failedToUpdateRoutes(reason: String)
    case failedToUpdateAlternativeRoutes(reason: String)
}
