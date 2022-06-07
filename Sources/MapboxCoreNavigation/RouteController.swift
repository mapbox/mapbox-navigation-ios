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
    @available(*, deprecated, message: "Use `customRoutingProvider` instead. If route controller was not initialized using `Directions` object - this property is unused and ignored.")
    public lazy var directions: Directions = routingProvider as? Directions ?? Directions.shared
    
    /**
     `RoutingProvider`, used to create a route during refreshing or rerouting.
     */
    @available(*, deprecated, message: "Use `customRoutingProvider` instead. This property will be equal to `customRoutingProvider` if that is provided or a `MapboxRoutingProvider` instance otherwise.")
    public lazy var routingProvider: RoutingProvider = resolvedRoutingProvider
    
    /**
     Custom `RoutingProvider`, used to create a route during refreshing or rerouting.
     
     If set to `nil` - default Mapbox implementation will be used.
     */
    public var customRoutingProvider: RoutingProvider? = nil
    
    // TODO: remove when NN implements RouteRefreshing and Continuos Alternatives
    private lazy var defaultRoutingProvider: RoutingProvider = MapboxRoutingProvider(NavigationSettings.shared.routingProviderSource)

    var resolvedRoutingProvider: RoutingProvider {
        customRoutingProvider ?? defaultRoutingProvider
    }
    
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
        guard !hasFinishedRouting else { return }
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
    
    // MARK: Controlling and Altering the Route
    
    var rerouteController: RerouteController {
        sharedNavigator.rerouteController
    }
    
    public var reroutesProactively: Bool = true
    
    var lastProactiveRerouteDate: Date?
    
    var isRerouting = false
    
    var lastRerouteLocation: CLLocation?
    
    public var initialManeuverAvoidanceRadius: TimeInterval {
        get {
            rerouteController.initialManeuverAvoidanceRadius
        }
        set {
            rerouteController.initialManeuverAvoidanceRadius = newValue
        }
    }
    
    public var refreshesRoute: Bool = true
    
    var isRefreshing = false
    
    var lastRouteRefresh: Date?
    
    var didFindFasterRoute = false
    
    var routeTask: NavigationProviderRequest?
    
    // MARK: Navigating
    
    private lazy var sharedNavigator: Navigator = {
        return Navigator.shared
    }()
    
    var navigator: MapboxNavigationNative.Navigator {
        return sharedNavigator.navigator
    }
    
    var userSnapToStepDistanceFromManeuver: CLLocationDistance?
    
    var previousArrivalWaypoint: MapboxDirections.Waypoint?
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !hasFinishedRouting else { return }
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
        guard !hasFinishedRouting else { return }
        heading = newHeading
    }
    
    /**
     Asynchronously updates NavNative navigator with the new `IndexedRouteResponse`.
     - parameter indexedRouteResponse: New route response to apply to the navigator.
     - parameter legIndex: A leg index, to start routing from.
     - parameter completion: A completion that will be called once the navigator is updated indicating
     whether the change was successful.
     */
    private func updateNavigator(with indexedRouteResponse: IndexedRouteResponse,
                                 fromLegIndex legIndex: Int,
                                 completion: ((Result<RouteInfo?, Error>) -> Void)?) {
        guard case .route(let routeOptions) = indexedRouteResponse.routeResponse.options else {
            completion?(.failure(RouteControllerError.internalError))
            return
        }
        let encoder = JSONEncoder()
        encoder.userInfo[.options] = routeOptions
        guard let routeData = try? encoder.encode(indexedRouteResponse.routeResponse),
              let routeJSONString = String(data: routeData, encoding: .utf8) else {
                  completion?(.failure(RouteControllerError.failedToSerializeRoute))
                  return
        }
        
        let routeRequest = Directions(credentials: indexedRouteResponse.routeResponse.credentials)
                                .url(forCalculating: routeOptions).absoluteString
        if let route = indexedRouteResponse.currentRoute {
            alternativeRoutesCenter?.mainRoute = route
        }
        
        let parsedRoutes = RouteParser.parseDirectionsResponse(forResponse: routeJSONString,
                                                               request: routeRequest, routeOrigin: RouterOrigin.custom)
        if parsedRoutes.isValue(),
           var routes = parsedRoutes.value as? [RouteInterface],
           routes.count > indexedRouteResponse.routeIndex {
            self.sharedNavigator.setRoutes(routes.remove(at: indexedRouteResponse.routeIndex),
                                           uuid: sessionUUID,
                                           legIndex: UInt32(legIndex),
                                           alternativeRoutes: routes) { result in
                completion?(result)
            }
        } else if parsedRoutes.isError() {
            let reason = (parsedRoutes.error as String?) ?? ""
            completion?(.failure(NavigatorError.failedToUpdateRoutes(reason: reason)))
        } else {
            completion?(.failure(RouteControllerError.internalError))
        }
    }
    
    /// updateRouteLeg is used to notify nav-native of the developer changing the active route-leg.
    private func updateRouteLeg(to value: Int, completionHandler: AdvanceLegCompletionHandler? = nil) {
        let legIndex = UInt32(value)
        
        navigator.changeLeg(forLeg: legIndex) { [weak self] success in
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

    private var hasFinishedRouting = false
    public func finishRouting() {
        guard !hasFinishedRouting else { return }
        hasFinishedRouting = true
        removeRoutes(completion: nil)
        BillingHandler.shared.stopBillingSession(with: sessionUUID)
        unsubscribeNotifications()
        routeTask?.cancel()
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
        
        updateSpokenInstructionProgress(status: status, willReRoute: isRerouting)
        updateVisualInstructionProgress(status: status)
        updateRoadName(status: status)
        updateDistanceToIntersection(from: snappedLocation)
        
        rerouteAfterArrivalIfNeeded(snappedLocation, status: status)
        
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
        updateNavigator(with: indexedRouteResponse, fromLegIndex: self.routeProgress.legIndex, completion: nil)
    }
    
    @objc func restoreToOnline(_ notification: Notification) {
        updateNavigator(with: indexedRouteResponse, fromLegIndex: self.routeProgress.legIndex, completion: nil)
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
    
    private func announceReroutingError(with error: Error) {
        delegate?.router(self, didFailToRerouteWith: error)
        NotificationCenter.default.post(name: .routeControllerDidFailToReroute, object: self, userInfo: [
            NotificationUserInfoKey.routingErrorKey: error,
        ])
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
    
    @available(*, deprecated, renamed: "init(alongRouteAtIndex:in:options:customRoutingProvider:dataSource:)")
    public convenience init(alongRouteAtIndex routeIndex: Int, in routeResponse: RouteResponse, options: RouteOptions, directions: Directions = NavigationSettings.shared.directions, dataSource source: RouterDataSource) {
        self.init(alongRouteAtIndex: routeIndex,
                  in: routeResponse,
                  options: options,
                  routingProvider: directions,
                  dataSource: source)
    }
    
    @available(*, deprecated, renamed: "init(alongRouteAtIndex:in:options:customRoutingProvider:dataSource:)")
    required public convenience init(alongRouteAtIndex routeIndex: Int,
                                     in routeResponse: RouteResponse,
                                     options: RouteOptions,
                                     routingProvider: RoutingProvider,
                                     dataSource source: RouterDataSource) {
        self.init(alongRouteAtIndex:routeIndex,
                  in: routeResponse,
                  options: options,
                  customRoutingProvider: routingProvider,
                  dataSource: source)
    }
    
    required public init(alongRouteAtIndex routeIndex: Int,
                         in routeResponse: RouteResponse,
                         options: RouteOptions,
                         customRoutingProvider: RoutingProvider? = nil,
                         dataSource source: RouterDataSource) {
        Self.instanceLock.lock()
        let twoInstances = Self.instance != nil
        Self.instanceLock.unlock()
        if twoInstances {
            os_log("[BUG] Two simultaneous active navigation sessions. This might happen if there are two NavigationViewController or RouteController instances exists at the same time. Profile the app and make sure that NavigationViewController and RouteController is deallocated once not in use.", log: Self.log, type: .fault)
        }

        Navigator.datasetProfileIdentifier = options.profileIdentifier
        
        self.indexedRouteResponse = .init(routeResponse: routeResponse, routeIndex: routeIndex)
        self.routeProgress = RouteProgress(route: routeResponse.routes![routeIndex], options: options)
        self.dataSource = source
        self.refreshesRoute = options.profileIdentifier == .automobileAvoidingTraffic && options.refreshingEnabled
        UIDevice.current.isBatteryMonitoringEnabled = true

        if NavigationSettings.shared.alternativeRouteDetectionStrategy != nil {
            self.alternativeRoutesCenter = AlternativeRoutesCenter(mainRoute: routeProgress.route)
        }
        
        super.init()
        
        self.alternativeRoutesCenter?.delegate = self
        
        if let customRoutingProvider = customRoutingProvider {
            self.customRoutingProvider = customRoutingProvider
            self.rerouteController.customRoutingProvider = customRoutingProvider
        }
        
        BillingHandler.shared.beginBillingSession(for: .activeGuidance, uuid: sessionUUID)

        subscribeNotifications()
        updateNavigator(with: self.indexedRouteResponse, fromLegIndex: 0) { [weak self] _ in
            self?.isInitialized = true
        }
        Self.instanceLock.lock()
        Self.instance = self
        Self.instanceLock.unlock()
    }
    
    deinit {
        finishRouting()
        rerouteController.resetToDefaultSettings()
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
        rerouteController.delegate = self
    }
    
    private func unsubscribeNotifications() {
        NotificationCenter.default.removeObserver(self)
        rerouteController.delegate = nil
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
    
    /// Provides access to detected `AlternativeRoute`s.
    private var alternativeRoutesCenter: AlternativeRoutesCenter?
}

extension RouteController: HistoryRecording { }

extension RouteController: Router {
    
    // MARK: Controlling and Altering the Route
    
    public func userIsOnRoute(_ location: CLLocation) -> Bool {
        return userIsOnRoute(location, status: nil)
    }
    
    public func userIsOnRoute(_ location: CLLocation, status: NavigationStatus?) -> Bool {
        return rerouteController.userIsOnRoute()
    }
    
    func rerouteAfterArrivalIfNeeded(_ location: CLLocation, status: NavigationStatus?) {
        guard let destination = routeProgress.currentLeg.destination else {
            preconditionFailure("Route legs used for navigation must have destinations")
        }
        
        // If the user has arrived, do not continue monitor reroutes, step progress, etc
        if routeProgress.currentLegProgress.userHasArrivedAtWaypoint &&
            (delegate?.router(self, shouldPreventReroutesWhenArrivingAt: destination) ??
             DefaultBehavior.shouldPreventReroutesWhenArrivingAtWaypoint) {
            return
        }
        
        // If we still wait for the first status from NavNative, there is no need to reroute
        guard let status = status ?? sharedNavigator.mostRecentNavigationStatus else { return }

        // NavNative doesn't support reroutes after arrival.
        // The code below is a port of logic from LegacyRouteController
        // This should be removed once NavNative adds support for reroutes after arrival.
        if status.routeState == .complete {
            // If the user has arrived and reroutes after arrival should be prevented, do not continue monitor
            // reroutes, step progress, etc
            if routeProgress.currentLegProgress.userHasArrivedAtWaypoint &&
                (delegate?.router(self, shouldPreventReroutesWhenArrivingAt: destination) ??
                 RouteController.DefaultBehavior.shouldPreventReroutesWhenArrivingAtWaypoint) {
                return
            }

            func userIsWithinRadiusOfDestination(location: CLLocation) -> Bool {
                let lastStep = routeProgress.currentLegProgress.currentStep
                let isCloseToFinalStep = location.isWithin(RouteControllerMaximumDistanceBeforeRecalculating,
                                                           of: lastStep)
                return isCloseToFinalStep
            }

            if !userIsWithinRadiusOfDestination(location: location) &&
                (delegate?.router(self, shouldRerouteFrom: location)
                 ?? DefaultBehavior.shouldRerouteFromLocation) {
                reroute(from: location, along: routeProgress)
            }
        }
    }
    
    public func reroute(from location: CLLocation, along progress: RouteProgress) {
        guard !hasFinishedRouting else { return }
        guard customRoutingProvider != nil else {
            rerouteController.forceReroute()
            return
        }
        
        // Avoid interrupting an ongoing reroute
        if isRerouting { return }
        isRerouting = true

        announceImpendingReroute(at: location)
        
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
                self.announceReroutingError(with: error)
                self.isRerouting = false
            }
        }
    }

    public func updateRoute(with indexedRouteResponse: IndexedRouteResponse,
                            routeOptions: RouteOptions?,
                            completion: ((Bool) -> Void)?) {
        guard !hasFinishedRouting else { return }
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
        let routeProgress = RouteProgress(route: route, options: routeOptions)
        updateNavigator(with: indexedRouteResponse,
                        fromLegIndex: routeProgress.legIndex) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.routeProgress = routeProgress
                self.announce(reroute: route, at: self.location, proactive: isProactive)
                self.indexedRouteResponse = indexedRouteResponse
                completion?(true)
            case .failure:
                completion?(false)
            }
        }
    }

    private func removeRoutes(completion: ((Error?) -> Void)?) {
        sharedNavigator.unsetRoutes(uuid: sessionUUID) { result in
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

extension RouteController: ReroutingControllerDelegate {
    func rerouteControllerWantsSwitchToAlternative(_ rerouteController: RerouteController,
                                                   response: RouteResponse,
                                                   routeIndex: Int,
                                                   options: RouteOptions) {
        let newRouteResponse = IndexedRouteResponse(routeResponse: response,
                                                    routeIndex: routeIndex)
                                                    
        guard let newMainRoute = newRouteResponse.currentRoute else {
            return
        }
              
        var userInfo = [RouteController.NotificationUserInfoKey: Any]()
        userInfo[.locationKey] = location
        userInfo[.routeKey] = newMainRoute
        NotificationCenter.default.post(name: .routeControllerWillTakeAlternativeRoute,
                                        object: self,
                                        userInfo: userInfo)
        
        delegate?.router(self,
                         willTakeAlternativeRoute: newMainRoute,
                         at: location)
        updateRoute(with: newRouteResponse,
                    routeOptions: options,
                    isProactive: false,
                    completion: { [weak self] success in
            guard let self = self else { return }
            var userInfo = [RouteController.NotificationUserInfoKey: Any]()
            userInfo[.locationKey] = self.location
            if success {
                NotificationCenter.default.post(name: .routeControllerDidTakeAlternativeRoute,
                                                object: self,
                                                userInfo: userInfo)
                self.delegate?.router(self, didTakeAlternativeRouteAt: self.location)
            } else {
                NotificationCenter.default.post(name: .routeControllerDidFailToTakeAlternativeRoute,
                                                object: self,
                                                userInfo: userInfo)
                self.delegate?.router(self, didFailToTakeAlternativeRouteAt: self.location)
            }
        })
    }
    
    func rerouteControllerDidDetectReroute(_ rerouteController: RerouteController) -> Bool {
        guard let location = location else { return false }
        
        if delegate?.router(self, shouldRerouteFrom: location) ?? DefaultBehavior.shouldRerouteFromLocation {
            announceImpendingReroute(at: location)
            
            isRerouting = true
            return true
        } else {
            return false
        }
    }
    
    func rerouteControllerDidRecieveReroute(_ rerouteController: RerouteController, response: RouteResponse, options: RouteOptions) {
        updateRoute(with: IndexedRouteResponse(routeResponse: response,
                                               routeIndex: 0),
                    routeOptions: options,
                    isProactive: false) { [weak self] _ in
            self?.isRerouting = false
        }
    }
    
    func rerouteControllerDidCancelReroute(_ rerouteController: RerouteController) {
        self.isRerouting = false
    }
    
    func rerouteControllerDidFailToReroute(_ rerouteController: RerouteController, with error: DirectionsError) {
        announceReroutingError(with: error)
        self.isRerouting = false
    }
}

extension RouteController: AlternativeRoutesCenterDelegate {
    func alternativeRoutesCenter(_ center: AlternativeRoutesCenter, didUpdateAlternatives updatedAlternatives: [AlternativeRoute], removedAlternatives: [AlternativeRoute]) {
        var userInfo = [RouteController.NotificationUserInfoKey: Any]()
        userInfo[.updatedAlternativesKey] = updatedAlternatives
        userInfo[.removedAlternativesKey] = removedAlternatives
        
        NotificationCenter.default.post(name: .routeControllerDidUpdateAlternatives,
                                        object: self,
                                        userInfo: userInfo)
        delegate?.router(self,
                         didUpdateAlternatives: updatedAlternatives,
                         removedAlternatives: removedAlternatives)
    }
    
    func alternativeRoutesCenter(_ center: AlternativeRoutesCenter, didFailToUpdateAlternatives error: AlternativeRouteError) {
        var userInfo = [RouteController.NotificationUserInfoKey: Any]()
        userInfo[.alternativesErrorKey] = error
        NotificationCenter.default.post(name: .routeControllerDidFailToUpdateAlternatives,
                                        object: self,
                                        userInfo: userInfo)
        delegate?.router(self, didFailToUpdateAlternatives: error)
    }
}


enum RouteControllerError: Error {
    case internalError
    case failedToChangeRouteLeg
    case failedToSerializeRoute
}
