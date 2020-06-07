import Foundation
import CoreLocation
import MapboxNavigationNative
import MapboxMobileEvents
import MapboxDirections
import Polyline
import Turf

/**
 A `RouteController` tracks the user’s progress along a route, posting notifications as the user reaches significant points along the route. On every location update, the route controller evaluates the user’s location, determining whether the user remains on the route. If not, the route controller calculates a new route.
 
 `RouteController` is responsible for the core navigation logic whereas
 `NavigationViewController` is responsible for displaying a default drop-in navigation UI.
 */
open class RouteController: NSObject {
    public enum DefaultBehavior {
        public static let shouldRerouteFromLocation: Bool = true
        public static let shouldDiscardLocation: Bool = true
        public static let didArriveAtWaypoint: Bool = true
        public static let shouldPreventReroutesWhenArrivingAtWaypoint: Bool = true
        public static let shouldDisableBatteryMonitoring: Bool = true
    }

    lazy var navigator: Navigator = {
        let settingsProfile = SettingsProfile(application: ProfileApplication.kMobile,
                                              platform: ProfilePlatform.KIOS)
        return Navigator(profile: settingsProfile, customConfig: "")
    }()
    
    public var route: Route {
        get {
            return routeProgress.route
        }
        set {
            routeProgress = RouteProgress(route: newValue, options: routeProgress.routeOptions)
            updateNavigator(with: routeProgress)
        }
    }
    
    private var _routeProgress: RouteProgress {
        willSet {
            resetObservation(for: _routeProgress)
        }
        didSet {
            movementsAwayFromRoute = 0
            updateNavigator(with: _routeProgress)
            updateObservation(for: _routeProgress)
        }
    }
    
    var movementsAwayFromRoute = 0
    
    var routeTask: URLSessionDataTask?
    
    var lastRerouteLocation: CLLocation?
    
    var didFindFasterRoute = false
    
    var isRerouting = false
    
    var userSnapToStepDistanceFromManeuver: CLLocationDistance?
    
    var previousArrivalWaypoint: Waypoint?
    
    var isFirstLocation: Bool = true
    
    public var config: NavigatorConfig? {
        get {
            return navigator.getConfig()
        }
        set {
            navigator.setConfigFor(newValue)
        }
    }
    
    /**
     Details about the user’s progress along the current route, leg, and step.
     */
    public var routeProgress: RouteProgress {
        get {
            return _routeProgress
        }
        set {
            if let location = self.location {
                delegate?.router(self, willRerouteFrom: location)
            }
            _routeProgress = newValue
            announce(reroute: routeProgress.route, at: rawLocation, proactive: didFindFasterRoute)
        }
    }
    
    /**
     The raw location, snapped to the current route.
     - important: If the rawLocation is outside of the route snapping tolerances, this value is nil.
     */
    var snappedLocation: CLLocation? {
        let status = navigator.getStatusForTimestamp(Date())
        guard status.routeState == .tracking || status.routeState == .complete else {
            return nil
        }
        return CLLocation(status.location)
    }
    
    var heading: CLHeading?
    
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
    
    public var reroutesProactively: Bool = true
    
    var lastProactiveRerouteDate: Date?
    
    /**
     The route controller’s delegate.
     */
    public weak var delegate: RouterDelegate?
    
    /**
     The route controller’s associated location manager.
     */
    public unowned var dataSource: RouterDataSource
    
    /**
     The Directions object used to create the route.
     */
    public var directions: Directions
    
    /**
     The idealized user location. Snapped to the route line, if applicable, otherwise raw.
     - seeAlso: snappedLocation, rawLocation
     */
    public var location: CLLocation? {
        return snappedLocation ?? rawLocation
    }
    
    required public init(along route: Route, options: RouteOptions, directions: Directions = Directions.shared, dataSource source: RouterDataSource) {
        self.directions = directions
        self._routeProgress = RouteProgress(route: route, options: options)
        self.dataSource = source
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        super.init()
        
        updateNavigator(with: _routeProgress)
        updateObservation(for: _routeProgress)
    }
    
    deinit {
        resetObservation(for: _routeProgress)
    }
    
    func resetObservation(for progress: RouteProgress) {
        progress.legIndexHandler = nil
    }
    
    func updateObservation(for progress: RouteProgress) {
        progress.legIndexHandler = { [weak self] (oldValue, newValue) in
            guard newValue != oldValue else {
                return
            }
            self?.updateRouteLeg(to: newValue)
        }
    }
    
    /// updateNavigator is used to pass the new progress model onto nav-native.
    private func updateNavigator(with progress: RouteProgress) {
        let encoder = JSONEncoder()
        encoder.userInfo[.options] = progress.routeOptions
        guard let routeData = try? encoder.encode(progress.route),
            let routeJSONString = String(data: routeData, encoding: .utf8) else {
            return
        }
        // TODO: Add support for alternative route
        navigator.setRouteForRouteResponse(routeJSONString, route: 0, leg: UInt32(routeProgress.legIndex))
    }
    
    /// updateRouteLeg is used to notify nav-native of the developer changing the active route-leg.
    private func updateRouteLeg(to value: Int) {
        let legIndex = UInt32(value)
        navigator.changeRouteLeg(forRoute: 0, leg: legIndex)
        let newStatus = navigator.changeRouteLeg(forRoute: 0, leg: legIndex)
        updateIndexes(status: newStatus, progress: routeProgress)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        guard delegate?.router(self, shouldDiscard: location) ?? DefaultBehavior.shouldDiscardLocation else {
            return
        }
        
        rawLocation = locations.last
        
        locations.forEach { navigator.updateLocation(for: FixLocation($0)) }
        
        let status = navigator.getStatusForTimestamp(location.timestamp)
        
        // Notify observers if the step’s remaining distance has changed.
        update(progress: routeProgress, with: CLLocation(status.location), rawLocation: location)
        
        let willReroute = !userIsOnRoute(location, status: status) && delegate?.router(self, shouldRerouteFrom: location)
            ?? DefaultBehavior.shouldRerouteFromLocation
        
        updateIndexes(status: status, progress: routeProgress)
        updateRouteLegProgress(status: status)
        updateSpokenInstructionProgress(status: status, willReRoute: willReroute)
        updateVisualInstructionProgress(status: status)
        
        if willReroute {
            reroute(from: location, along: routeProgress)
        }
        
        // Check for faster route proactively (if reroutesProactively is enabled)
        checkForFasterRoute(from: location, routeProgress: routeProgress)
    }
    
    func updateIndexes(status: NavigationStatus, progress: RouteProgress) {
        let newLegIndex = Int(status.legIndex)
        let newStepIndex = Int(status.stepIndex)
        let newIntersectionIndex = Int(status.intersectionIndex)
        
        if (newLegIndex != progress.legIndex) {
            progress.legIndex = newLegIndex
        }
        if (newStepIndex != progress.currentLegProgress.stepIndex) {
            progress.currentLegProgress.stepIndex = newStepIndex
        }
        
        if (newIntersectionIndex != progress.currentLegProgress.currentStepProgress.intersectionIndex) {
            progress.currentLegProgress.currentStepProgress.intersectionIndex = newIntersectionIndex
        }
        
        if let spokenIndexPrimitive = status.voiceInstruction?.index, progress.currentLegProgress.currentStepProgress.spokenInstructionIndex != Int(spokenIndexPrimitive)
            {
            progress.currentLegProgress.currentStepProgress.spokenInstructionIndex = Int(spokenIndexPrimitive)
        }
        
        if let visualInstructionIndex = status.bannerInstruction?.index, routeProgress.currentLegProgress.currentStepProgress.visualInstructionIndex != Int(visualInstructionIndex) {
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
                
                let advancesToNextLeg = delegate?.router(self, didArriveAt: currentDestination) ?? DefaultBehavior.didArriveAtWaypoint
                guard !routeProgress.isFinalLeg && advancesToNextLeg else {
                    return
                }
                let legIndex = Int(status.legIndex + 1)
                updateRouteLeg(to: legIndex)
            }
        }
    }
    
    private func update(progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        let stepProgress = progress.currentLegProgress.currentStepProgress
        let step = stepProgress.step
        
        //Increment the progress model
        guard let polyline = step.shape else {
            preconditionFailure("Route steps used for navigation must have shape data")
        }
        if let closestCoordinate = polyline.closestCoordinate(to: rawLocation.coordinate) {
            let remainingDistance = polyline.distance(from: closestCoordinate.coordinate)!
            let distanceTraveled = step.distance - remainingDistance
            stepProgress.distanceTraveled = distanceTraveled
            
            //Fire the delegate method
            delegate?.router(self, didUpdate: progress, with: location, rawLocation: rawLocation)
            
            //Fire the notification (for now)
            NotificationCenter.default.post(name: .routeControllerProgressDidChange, object: self, userInfo: [
                NotificationUserInfoKey.routeProgressKey: progress,
                NotificationUserInfoKey.locationKey: location, //guaranteed value
                NotificationUserInfoKey.rawLocationKey: rawLocation, //raw
                ])
        }
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
    
    /**
     Returns an estimated location at a given timestamp. The timestamp must be
     a future timestamp compared to the last location received by the location manager.
     */
    public func projectedLocation(for timestamp: Date) -> CLLocation {
        return CLLocation(navigator.getStatusForTimestamp(timestamp).location)
    }
    
    public func advanceLegIndex(location: CLLocation) {
        let status = navigator.getStatusForTimestamp(location.timestamp)
        routeProgress.legIndex = Int(status.legIndex)
    }
    
    public func enableLocationRecording() {
        navigator.toggleHistoryFor(onOff: true)
    }
    
    public func disableLocationRecording() {
        navigator.toggleHistoryFor(onOff: false)
    }
    
    public func locationHistory() -> String? {
        return navigator.getHistory()
    }
}

extension RouteController: Router {
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
        
        let status = status ?? navigator.getStatusForTimestamp(location.timestamp)
        let offRoute = status.routeState == .offRoute
        return !offRoute
    }
    
    public func reroute(from location: CLLocation, along progress: RouteProgress) {
        if let lastRerouteLocation = lastRerouteLocation {
            guard location.distance(from: lastRerouteLocation) >= RouteControllerMaximumDistanceBeforeRecalculating else {
                return
            }
        }
        
        delegate?.router(self, willRerouteFrom: location)
        NotificationCenter.default.post(name: .routeControllerWillReroute, object: self, userInfo: [
            NotificationUserInfoKey.locationKey: location,
        ])
        
        self.lastRerouteLocation = location
        
        // Avoid interrupting an ongoing reroute
        if isRerouting { return }
        isRerouting = true
        
        getDirections(from: location, along: progress) { [weak self] (session, result) in
            self?.isRerouting = false
            
            guard let strongSelf: RouteController = self else {
                return
            }
            
            switch result {
            case let .success(response):
                guard let route = response.routes?.first else { return }
                guard case let .route(routeOptions) = response.options else { return } //TODO: Can a match hit this codepoint?
                strongSelf._routeProgress = RouteProgress(route: route, options: routeOptions, legIndex: 0)
                strongSelf._routeProgress.currentLegProgress.stepIndex = 0
                strongSelf.announce(reroute: route, at: location, proactive: false)
                
            case let .failure(error):
                strongSelf.delegate?.router(strongSelf, didFailToRerouteWith: error)
                NotificationCenter.default.post(name: .routeControllerDidFailToReroute, object: self, userInfo: [
                    NotificationUserInfoKey.routingErrorKey: error,
                ])
                return
            }

            

        }
    }
}

extension RouteController: InternalRouter { }
