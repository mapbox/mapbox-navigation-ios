// IMPORTANT: Tampering with any file that contains billing code is a violation of our ToS
// and will result in enforcement of the penalties stipulated in the ToS.

import Foundation
import CoreLocation
import MapboxCommon
import MapboxNavigationNative
import MapboxMobileEvents
import MapboxDirections
import Polyline
import Turf
import os.log

/**
 A `RouteController` tracks the user’s progress along a route, posting notifications as the user reaches significant points along the route. On every location update, the route controller evaluates the user’s location, determining whether the user remains on the route. If not, the route controller calculates a new route.
 
 `RouteController` is responsible for the core navigation logic whereas
 `NavigationViewController` is responsible for displaying a default drop-in navigation UI.

 - important: Creating an instance of this type will start an Active Guidance session. The trip session is stopped when
 the instance is deallocated. From more info read the [Pricing Guide](https://docs.mapbox.com/ios/beta/navigation/guides/pricing/).
 - precondition: There should be only one `RouteController` alive to any given time.
 */
open class RouteController: NSObject {
    public enum DefaultBehavior {
        public static let shouldRerouteFromLocation: Bool = true
        public static let shouldDiscardLocation: Bool = false
        public static let didArriveAtWaypoint: Bool = true
        public static let shouldPreventReroutesWhenArrivingAtWaypoint: Bool = true
        public static let shouldDisableBatteryMonitoring: Bool = true
    }

    public static let log: OSLog = .init(subsystem: "com.mapbox.navigation", category: "RouteController")
    /// Holds currently alive instance of `RouteController`.
    private static weak var instance: RouteController?
    private static let instanceLock: NSLock = .init()


    private let sessionUUID: UUID = .init()
    private var isInitialized: Bool = false
    
    // MARK: Configuring Route-Related Data
    
    /**
     A `TileStore` instance used by navigator
     */
    open var navigatorTileStore: TileStore {
        return sharedNavigator.tileStore
    }
    
    /**
     The route controller’s associated location manager.
     */
    public unowned var dataSource: RouterDataSource
    
    /**
     A reference to a MapboxDirections service. Used for rerouting.
     */
    @available(*, deprecated, message: "Use `routingProvider` instead. If route controller was not initialized using `Directions` object - this property is unused and ignored.")
    public lazy var directions: Directions = routingProvider as? Directions ?? Directions.shared
    
    /**
     `RoutingProvider`, used to create route.
     */
    public var routingProvider: RoutingProvider
    
    public var route: Route {
        return routeProgress.route
    }
    
    public internal(set) var indexedRouteResponse: IndexedRouteResponse {
        didSet {
            if let routes = indexedRouteResponse.routeResponse.routes {
                precondition(routes.indices.contains(indexedRouteResponse.routeIndex), "Route index is out of bounds.")
            }
        }
    }
    
    // MARK: Tracking the Progress
    
    /**
     Details about the user’s progress along the current route, leg, and step.

     To advance the route progress to next leg, use `RouteController.advanceLegIndex(completionHandler:)` method.
     */
    public private(set) var routeProgress: RouteProgress

    /**
     The idealized user location. Snapped to the route line, if applicable, otherwise raw.
     - seeAlso: snappedLocation, rawLocation
     */
    public var location: CLLocation? {
        return snappedLocation ?? rawLocation
    }
    
    /**
     The most recently received user location.
     - note: This is a raw location received from `locationManager`. To obtain an idealized location, use the `location` property.
     */
    public var rawLocation: CLLocation? {
        didSet {
            if isFirstLocation == true {
                isFirstLocation = false
            }
        }
    }
    
    /**
     The raw location, snapped to the current route.
     - important: If the rawLocation is outside of the route snapping tolerances, this value is nil.
     */
    var snappedLocation: CLLocation? {
        guard lastLocationUpdateDate != nil,
              let status = sharedNavigator.mostRecentNavigationStatus else {
            return nil
        }
        
        guard status.routeState == .tracking || status.routeState == .complete else {
            return nil
        }
        return CLLocation(status.location)
    }

    private var lastLocationUpdateDate: Date? {
        return rawLocation?.timestamp
    }

    /**
     The route controller’s delegate.
     */
    public weak var delegate: RouterDelegate?
    
    /**
     The route controller’s heading.
     */
    public var heading: CLHeading?
    var isFirstLocation: Bool = true
    
    /**
     Advances current `RouteProgress.legIndex` by 1.
     
     - parameter completionHandler: Completion handler, which is called to report a status whether
     `RouteLeg` was changed or not.
     */
    public func advanceLegIndex(completionHandler: AdvanceLegCompletionHandler? = nil) {
        updateRouteLeg(to: routeProgress.legIndex + 1) { result in
            completionHandler?(result)
        }
    }
    
    /**
     Starts electronic horizon updates.

     Pass `nil` to use the default configuration.
     Updates will be delivered in `Notification.Name.electronicHorizonDidUpdatePosition` notification.
     For more info, read the [Electronic Horizon Guide](https://docs.mapbox.com/ios/beta/navigation/guides/electronic-horizon/).

     - parameter options: Options which will be used to configure electronic horizon updates.

     - postcondition: To change electronic horizon options call this method again with new options.
     
     - note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the feature.
     */
    public func startUpdatingElectronicHorizon(with options: ElectronicHorizonOptions? = nil) {
        sharedNavigator.startUpdatingElectronicHorizon(with: options)
    }

    /**
     Stops electronic horizon updates.
     */
    public func stopUpdatingElectronicHorizon() {
        sharedNavigator.stopUpdatingElectronicHorizon()
    }

    func changeRouteProgress(_ routeProgress: RouteProgress,
                             completion: @escaping (Bool) -> Void) {
        updateNavigator(with: routeProgress) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.routeProgress = routeProgress
                completion(true)
            case .failure:
                completion(false)
            }
        }
    }
    
    // MARK: Controlling and Altering the Route
    
    public var reroutesProactively: Bool = true
    
    var lastProactiveRerouteDate: Date?
    
    var isRerouting = false
    
    var lastRerouteLocation: CLLocation?
    
    public var refreshesRoute: Bool = true
    
    var isRefreshing = false
    
    var lastRouteRefresh: Date?
    
    var didFindFasterRoute = false
    
    var routeTask: NavigationProviderRequest?
    
    // MARK: Navigating
    
    private let sharedNavigator = Navigator.shared
    
    var navigator: MapboxNavigationNative.Navigator {
        return sharedNavigator.navigator
    }
    
    var userSnapToStepDistanceFromManeuver: CLLocationDistance?
    
    var previousArrivalWaypoint: MapboxDirections.Waypoint?
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        guard !(delegate?.router(self, shouldDiscard: location) ?? DefaultBehavior.shouldDiscardLocation) else {
            return
        }
        
        rawLocation = location
        
        locations.forEach {
            sharedNavigator.updateLocation($0) { _ in
                // No-op
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }
    
    /**
     Asynchronously updates NavNative navigator with the new `RouteProgress`.

     - parameter progress: New route progress to apply to the navigator.
     - parameter completion: A completion that will be called once the navigator is updated with a boolean indicating
     whether the change was successful.
     */
    private func updateNavigator(with progress: RouteProgress,
                                 completion: ((Result<RouteInfo, Error>) -> Void)?) {
        let encoder = JSONEncoder()
        encoder.userInfo[.options] = progress.routeOptions
        guard let routeData = try? encoder.encode(progress.route),
              let routeJSONString = String(data: routeData, encoding: .utf8) else {
                  completion?(.failure(RouteControllerError.failedToSerializeRoute))
                  return
        }

        let routeRequest = Directions().url(forCalculating: progress.routeOptions).absoluteString
        let routes = Routes(routesResponse: routeJSONString,
                            routeIndex: 0,
                            legIndex: UInt32(progress.legIndex),
                            routesRequest: routeRequest)

        sharedNavigator.setRoutes(routes, uuid: sessionUUID) { result in
            completion?(result)
        }
    }
    
    /// updateRouteLeg is used to notify nav-native of the developer changing the active route-leg.
    private func updateRouteLeg(to value: Int, completionHandler: AdvanceLegCompletionHandler? = nil) {
        let legIndex = UInt32(value)
        
        navigator.changeRouteLeg(forRoute: 0, leg: legIndex) { [weak self] success in
            guard let self = self else {
                completionHandler?(.failure(RouteControllerError.internalError))
                return
            }
            
            // Since it's not possible to get navigator status synchronously `RouteProgress` related
            // information will be updated in `RouteController.navigationStatusDidChange(_:)`.
            let result: Result<RouteProgress, Error>
            if success {
                result = .success(self.routeProgress)
                /** NOTE:
                 `navigator.changeRouteLeg(forRoute:leg:)` will return true if the leg actually changed.
                 */
                BillingHandler.shared.beginNewBillingSessionIfRunning(with: self.sessionUUID)                
            } else {
                result = .failure(RouteControllerError.failedToChangeRouteLeg)
            }
            
            completionHandler?(result)
        }
    }
    
    @objc private func navigationStatusDidChange(_ notification: NSNotification) {
        assert(Thread.isMainThread)

        guard let userInfo = notification.userInfo,
              let status = userInfo[Navigator.NotificationUserInfoKey.statusKey] as? NavigationStatus else { return }
        update(to: status)
    }

    private func update(to status: NavigationStatus) {
        guard let rawLocation = rawLocation,
              isValidNavigationStatus(status)
        else { return }
        
        let snappedLocation = CLLocation(status.location)
        
        // Notify observers if the step’s remaining distance has changed.
        update(progress: routeProgress,
               with: snappedLocation,
               rawLocation: rawLocation,
               upcomingRouteAlerts: status.upcomingRouteAlerts,
               mapMatchingResult: MapMatchingResult(status: status))
        
        updateIndexes(status: status, progress: routeProgress)
        updateRouteLegProgress(status: status)
        let willReroute = !userIsOnRoute(snappedLocation, status: status)
        && (delegate?.router(self, shouldRerouteFrom: snappedLocation)
            ?? DefaultBehavior.shouldRerouteFromLocation)
        
        updateSpokenInstructionProgress(status: status, willReRoute: willReroute)
        updateVisualInstructionProgress(status: status)
        updateRoadName(status: status)
        updateDistanceToIntersection(from: snappedLocation)
        
        if willReroute {
            reroute(from: snappedLocation, along: routeProgress)
        }

        if status.routeState != .complete {
            // Check for faster route proactively (if reroutesProactively is enabled)
            refreshAndCheckForFasterRoute(from: snappedLocation, routeProgress: routeProgress)
        }
    }
    
    func updateDistanceToIntersection(from location: CLLocation) {
        guard var intersections = routeProgress.currentLegProgress.currentStepProgress.step.intersections else { return }
        
        // The intersections array does not include the upcoming maneuver intersection.
        if let upcomingStep = routeProgress.currentLegProgress.upcomingStep,
           let upcomingIntersection = upcomingStep.intersections?.first {
            intersections += [upcomingIntersection]
        }
        
        routeProgress.currentLegProgress.currentStepProgress.intersectionsIncludingUpcomingManeuverIntersection = intersections
        
        if let shape = routeProgress.currentLegProgress.currentStepProgress.step.shape,
           let upcomingIntersection = routeProgress.currentLegProgress.currentStepProgress.upcomingIntersection {
            routeProgress.currentLegProgress.currentStepProgress.userDistanceToUpcomingIntersection = shape.distance(from: location.coordinate, to: upcomingIntersection.location)
        }
        
        updateIntersectionDistances()
    }
    
    func updateIntersectionDistances() {
        if routeProgress.currentLegProgress.currentStepProgress.intersectionDistances == nil {
            routeProgress.currentLegProgress.currentStepProgress.intersectionDistances = [CLLocationDistance]()
            
            if let shape = routeProgress.currentLegProgress.currentStep.shape,
               let intersections = routeProgress.currentLegProgress.currentStep.intersections {
                let distances: [CLLocationDistance] = intersections.compactMap { shape.distance(from: shape.coordinates.first, to: $0.location) }
                routeProgress.currentLegProgress.currentStepProgress.intersectionDistances = distances
            }
        }
    }
    
    @objc func fallbackToOffline(_ notification: Notification) {
        updateNavigator(with: self.routeProgress, completion: nil)
    }
    
    @objc func restoreToOnline(_ notification: Notification) {
        updateNavigator(with: self.routeProgress, completion: nil)
    }

    func isValidNavigationStatus(_ status: NavigationStatus) -> Bool {
        return isInitialized && routeProgress.currentLegProgress.leg.steps.indices.contains(Int(status.stepIndex))
    }
    
    func updateIndexes(status: NavigationStatus, progress: RouteProgress) {
        let newLegIndex = Int(status.legIndex)
        let newStepIndex = Int(status.stepIndex)
        let newIntersectionIndex = Int(status.intersectionIndex)
        
        let oldLegIndex = progress.legIndex
        if newLegIndex != progress.legIndex {
            progress.legIndex = newLegIndex
        }
        
        if newStepIndex != progress.currentLegProgress.stepIndex {
            precondition(progress.currentLegProgress.leg.steps.indices.contains(newStepIndex), "The stepIndex: \(newStepIndex) is higher than steps count: \(progress.currentLegProgress.leg.steps.count) of the leg :\(newLegIndex) or not included. The old leg index: \(oldLegIndex) will not be updated in this case.")

            progress.currentLegProgress.stepIndex = newStepIndex
        }
        
        if newIntersectionIndex != progress.currentLegProgress.currentStepProgress.intersectionIndex {
            progress.currentLegProgress.currentStepProgress.intersectionIndex = newIntersectionIndex
        }
        
        if let spokenIndexPrimitive = status.voiceInstruction?.index,
           progress.currentLegProgress.currentStepProgress.spokenInstructionIndex != Int(spokenIndexPrimitive) {
            progress.currentLegProgress.currentStepProgress.spokenInstructionIndex = Int(spokenIndexPrimitive)
        }
        
        if let visualInstructionIndex = status.bannerInstruction?.index,
           routeProgress.currentLegProgress.currentStepProgress.visualInstructionIndex != Int(visualInstructionIndex) {
            routeProgress.currentLegProgress.currentStepProgress.visualInstructionIndex = Int(visualInstructionIndex)
        }
    }
    
    func updateSpokenInstructionProgress(status: NavigationStatus, willReRoute: Bool) {
        let didUpdate = status.voiceInstruction?.index != nil

        // Announce voice instruction if it was updated and we are not going to reroute
        if didUpdate && !willReRoute,
            let spokenInstruction = routeProgress.currentLegProgress.currentStepProgress.currentSpokenInstruction {
            announcePassage(of: spokenInstruction, routeProgress: routeProgress)
        }
    }
    
    func updateVisualInstructionProgress(status: NavigationStatus) {
        let didUpdate = status.bannerInstruction != nil
        
        // Announce visual instruction if it was updated or it is the first location being reported
        if didUpdate || isFirstLocation {
            if let instruction = routeProgress.currentLegProgress.currentStepProgress.currentVisualInstruction {
                announcePassage(of: instruction, routeProgress: routeProgress)
            }
        }
    }
    
    func updateRoadName(status: NavigationStatus) {
        let userInfo: [NotificationUserInfoKey: Any] = [
            NotificationUserInfoKey.roadNameKey: status.roadName,
            NotificationUserInfoKey.routeShieldRepresentationKey: status.routeShieldRepresentation
        ]
        NotificationCenter.default.post(name: .currentRoadNameDidChange, object: self, userInfo: userInfo)
    }
    
    func updateRouteLegProgress(status: NavigationStatus) {
        let legProgress = routeProgress.currentLegProgress
        
        guard let currentDestination = legProgress.leg.destination else {
            preconditionFailure("Route legs used for navigation must have destinations")
        }
        let remainingVoiceInstructions = legProgress.currentStepProgress.remainingSpokenInstructions ?? []
        
        // We are at least at the "You will arrive" instruction
        if legProgress.remainingSteps.count <= 2 && remainingVoiceInstructions.count <= 2 {
            let willArrive = status.routeState == .tracking
            let didArrive = status.routeState == .complete && currentDestination != previousArrivalWaypoint
            
            if willArrive {
                delegate?.router(self, willArriveAt: currentDestination, after: legProgress.durationRemaining, distance: legProgress.distanceRemaining)
            } else if didArrive {
                previousArrivalWaypoint = currentDestination
                legProgress.userHasArrivedAtWaypoint = true
                
                announceArrival(didArriveAt: currentDestination)
                let advancesToNextLeg = delegate?.router(self, didArriveAt: currentDestination) ?? DefaultBehavior.didArriveAtWaypoint
                guard !routeProgress.isFinalLeg && advancesToNextLeg else {
                    return
                }
                let legIndex = Int(status.legIndex + 1)
                updateRouteLeg(to: legIndex)
            }
        }
    }
    
    private func update(progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation, upcomingRouteAlerts routeAlerts: [UpcomingRouteAlert], mapMatchingResult: MapMatchingResult) {
        progress.updateDistanceTraveled(with: rawLocation)
        progress.upcomingRouteAlerts = routeAlerts.map { RouteAlert($0) }
        
        //Fire the delegate method
        delegate?.router(self, didUpdate: progress, with: location, rawLocation: rawLocation)
        
        //Fire the notification (for now)
        
        var userInfo: [RouteController.NotificationUserInfoKey: Any] = [
            .routeProgressKey: progress,
            .locationKey: location, // guaranteed value
            .rawLocationKey: rawLocation, // raw
        ]
        userInfo[.headingKey] = heading
        userInfo[.mapMatchingResultKey] = mapMatchingResult
        
        NotificationCenter.default.post(name: .routeControllerProgressDidChange, object: self, userInfo: userInfo)
    }
    
    private func announcePassage(of spokenInstructionPoint: SpokenInstruction, routeProgress: RouteProgress) {
        delegate?.router(self, didPassSpokenInstructionPoint: spokenInstructionPoint, routeProgress: routeProgress)
        
        let info: [NotificationUserInfoKey: Any] = [
            .routeProgressKey: routeProgress,
            .spokenInstructionKey: spokenInstructionPoint,
        ]
        
        NotificationCenter.default.post(name: .routeControllerDidPassSpokenInstructionPoint, object: self, userInfo: info)
    }
    
    private func announcePassage(of visualInstructionPoint: VisualInstructionBanner, routeProgress: RouteProgress) {
        delegate?.router(self, didPassVisualInstructionPoint: visualInstructionPoint, routeProgress: routeProgress)
        
        let info: [NotificationUserInfoKey: Any] = [
            .routeProgressKey: routeProgress,
            .visualInstructionKey: visualInstructionPoint,
        ]
        
        NotificationCenter.default.post(name: .routeControllerDidPassVisualInstructionPoint, object: self, userInfo: info)
    }
    
    private func announceArrival(didArriveAt waypoint: MapboxDirections.Waypoint) {
        let info: [NotificationUserInfoKey: Any] = [.waypointKey: waypoint]
        NotificationCenter.default.post(name: .didArriveAtWaypoint, object: self, userInfo: info)
    }
    
    func geometryEncoding(_ routeShapeFormat: RouteShapeFormat) -> ActiveGuidanceGeometryEncoding {
        switch routeShapeFormat {
        case .geoJSON:
            return .geoJSON
        case .polyline:
            return .polyline5
        case .polyline6:
            return .polyline6
        }
    }
    
    // MARK: Handling Lifecycle
    
    @available(*, deprecated, renamed: "init(alongRouteAtIndex:in:options:routingProvider:dataSource:)")
    public convenience init(alongRouteAtIndex routeIndex: Int, in routeResponse: RouteResponse, options: RouteOptions, directions: Directions = NavigationSettings.shared.directions, dataSource source: RouterDataSource) {
        self.init(alongRouteAtIndex: routeIndex,
                  in: routeResponse,
                  options: options,
                  routingProvider: directions,
                  dataSource: source)
    }
    
    required public init(alongRouteAtIndex routeIndex: Int,
                         in routeResponse: RouteResponse,
                         options: RouteOptions,
                         routingProvider: RoutingProvider,
                         dataSource source: RouterDataSource) {
        Self.instanceLock.lock()
        let twoInstances = Self.instance != nil
        Self.instanceLock.unlock()
        if twoInstances {
            os_log("[BUG] Two simultaneous active navigation sessions. This might happen if there are two NavigationViewController or RouteController instances exists at the same time. Profile the app and make sure that NavigationViewController and RouteController is deallocated once not in use.", log: Self.log, type: .fault)
        }

        Navigator.datasetProfileIdentifier = options.profileIdentifier
        
        self.routingProvider = routingProvider
        self.indexedRouteResponse = .init(routeResponse: routeResponse, routeIndex: routeIndex)
        self.routeProgress = RouteProgress(route: routeResponse.routes![routeIndex], options: options)
        self.dataSource = source
        self.refreshesRoute = options.profileIdentifier == .automobileAvoidingTraffic && options.refreshingEnabled
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        super.init()
        BillingHandler.shared.beginBillingSession(for: .activeGuidance, uuid: sessionUUID)

        subscribeNotifications()
        updateNavigator(with: routeProgress) { [weak self] _ in
            self?.isInitialized = true
        }
        Self.instanceLock.lock()
        Self.instance = self
        Self.instanceLock.unlock()
    }
    
    deinit {
        removeRoutes(completion: nil)
        BillingHandler.shared.stopBillingSession(with: sessionUUID)
        unsubscribeNotifications()
        routeTask?.cancel()
        Self.instanceLock.lock()
        Self.instance = nil
        Self.instanceLock.unlock()
    }

    private func subscribeNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(fallbackToOffline),
                                               name: .navigationDidSwitchToFallbackVersion,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(restoreToOnline),
                                               name: .navigationDidSwitchToTargetVersion,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(navigationStatusDidChange),
                                               name: .navigationStatusDidChange,
                                               object: nil)
    }
    
    private func unsubscribeNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Accessing Relevant Routing Data
    
    /// The road graph that is updated as the route controller tracks the user’s location.
    public var roadGraph: RoadGraph {
        return sharedNavigator.roadGraph
    }

    /// The road object store that is updated as the route controller tracks the user’s location.
    public var roadObjectStore: RoadObjectStore {
        return sharedNavigator.roadObjectStore
    }

    /// The road object matcher that allows to match user-defined road objects.
    public var roadObjectMatcher: RoadObjectMatcher {
        return sharedNavigator.roadObjectMatcher
    }
}

extension RouteController: HistoryRecording { }

extension RouteController: Router {
    
    // MARK: Controlling and Altering the Route
    
    public func userIsOnRoute(_ location: CLLocation) -> Bool {
        return userIsOnRoute(location, status: nil)
    }
    
    public func userIsOnRoute(_ location: CLLocation, status: NavigationStatus?) -> Bool {
        
        guard let destination = routeProgress.currentLeg.destination else {
            preconditionFailure("Route legs used for navigation must have destinations")
        }
        
        // If the user has arrived, do not continue monitor reroutes, step progress, etc
        if routeProgress.currentLegProgress.userHasArrivedAtWaypoint &&
            (delegate?.router(self, shouldPreventReroutesWhenArrivingAt: destination) ??
                DefaultBehavior.shouldPreventReroutesWhenArrivingAtWaypoint) {
            return true
        }
        
        // If we still wait for the first status from NavNative, there is no need to reroute
        guard let status = status ?? sharedNavigator.mostRecentNavigationStatus else { return true }

        /// NavNative doesn't support reroutes after arrival.
        /// The code below is a port of logic from LegacyRouteController
        /// This should be removed once NavNative adds support for reroutes after arrival. 
        if status.routeState == .complete {
            // If the user has arrived and reroutes after arrival should be prevented, do not continue monitor
            // reroutes, step progress, etc
            if routeProgress.currentLegProgress.userHasArrivedAtWaypoint &&
                (delegate?.router(self, shouldPreventReroutesWhenArrivingAt: destination) ??
                    RouteController.DefaultBehavior.shouldPreventReroutesWhenArrivingAtWaypoint) {
                return true
            }

            func userIsWithinRadiusOfDestination(location: CLLocation) -> Bool {
                let lastStep = routeProgress.currentLegProgress.currentStep
                let isCloseToFinalStep = location.isWithin(RouteControllerMaximumDistanceBeforeRecalculating,
                                                           of: lastStep)
                return isCloseToFinalStep
            }

            return userIsWithinRadiusOfDestination(location: location)
        }
        else {
            let offRoute = status.routeState == .offRoute
            return !offRoute
        }
    }
    
    public func reroute(from location: CLLocation, along progress: RouteProgress) {
        if let lastRerouteLocation = lastRerouteLocation {
            guard location.distance(from: lastRerouteLocation) >= RouteControllerMaximumDistanceBeforeRecalculating else {
                return
            }
        }
        
        announceImpendingReroute(at: location)
        
        self.lastRerouteLocation = location
        
        // Avoid interrupting an ongoing reroute
        if isRerouting { return }
        isRerouting = true
        
        calculateRoutes(from: location, along: progress) { [weak self] (session, result) in
            guard let self = self else { return }

            switch result {
            case let .success(indexedResponse):
                let response = indexedResponse.routeResponse
                guard case let .route(routeOptions) = response.options else {
                    //TODO: Can a match hit this codepoint?
                    self.isRerouting = false; return
                }
                self.updateRoute(with: indexedResponse,
                                 routeOptions: routeOptions,
                                 isProactive: false) { [weak self] success in
                    self?.isRerouting = false
                }
            case let .failure(error):
                self.delegate?.router(self, didFailToRerouteWith: error)
                NotificationCenter.default.post(name: .routeControllerDidFailToReroute, object: self, userInfo: [
                    NotificationUserInfoKey.routingErrorKey: error,
                ])
                self.isRerouting = false
            }
        }
    }

    public func updateRoute(with indexedRouteResponse: IndexedRouteResponse,
                            routeOptions: RouteOptions?,
                            completion: ((Bool) -> Void)?) {
        updateRoute(with: indexedRouteResponse, routeOptions: routeOptions, isProactive: false, completion: completion)
    }

    func updateRoute(with indexedRouteResponse: IndexedRouteResponse,
                     routeOptions: RouteOptions?,
                     isProactive: Bool,
                     completion: ((Bool) -> Void)?) {
        guard let route = indexedRouteResponse.currentRoute else {
            preconditionFailure("`indexedRouteResponse` does not contain route for index `\(indexedRouteResponse.routeIndex)` when updating route.")
        }
        if shouldStartNewBillingSession(for: route, routeOptions: routeOptions) {
            BillingHandler.shared.stopBillingSession(with: sessionUUID)
            BillingHandler.shared.beginBillingSession(for: .activeGuidance, uuid: sessionUUID)
        }

        let routeOptions = routeOptions ?? routeProgress.routeOptions
        changeRouteProgress(RouteProgress(route: route, options: routeOptions)) { [weak self] success in
            guard let self = self else { return }
            if success {
                self.announce(reroute: route, at: self.location, proactive: isProactive)
                self.indexedRouteResponse = indexedRouteResponse
            }
            completion?(success)
        }
    }

    private func removeRoutes(completion: ((Error?) -> Void)?) {
        sharedNavigator.setRoutes(nil, uuid: sessionUUID) { result in
            switch result {
            case .success:
                completion?(nil)
            case .failure(let error):
                completion?(error)
            }
        }
    }

    private func shouldStartNewBillingSession(for newRoute: Route, routeOptions: RouteOptions?) -> Bool {
        guard let routeOptions = routeOptions else {
            // Waypoints are read from routeOptions.
            // If new route without routeOptions, it means we have the same waypoints.
            return false
        }
        guard !routeOptions.waypoints.isEmpty else {
            return false // Don't need to bil for routes without waypoints
        }

        let newRouteWaypoints = routeOptions.waypoints.dropFirst()
        let currentRouteRemaingWaypoints = routeProgress.remainingWaypoints

        guard newRouteWaypoints.count == currentRouteRemaingWaypoints.count else {
            return true
        }

        for (newWaypoint, currentWaypoint) in zip(newRouteWaypoints, currentRouteRemaingWaypoints) {
            if newWaypoint.coordinate.distance(to: currentWaypoint.coordinate) > 100 {
                return true
            }
        }

        return false
    }
}

extension RouteController: InternalRouter { }

enum RouteControllerError: Error {
    case internalError
    case failedToChangeRouteLeg
    case failedToSerializeRoute
}
