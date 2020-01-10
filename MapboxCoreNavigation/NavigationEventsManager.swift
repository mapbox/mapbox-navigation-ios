import Foundation
import MapboxMobileEvents
import MapboxDirections

let NavigationEventTypeRouteRetrieval = "mobile.performance_trace"

/**
 The `EventsManagerDataSource` protocol declares values required for recording route following events.
 */
public protocol EventsManagerDataSource: class {
    var routeProgress: RouteProgress { get }
    var router: Router! { get }
    var desiredAccuracy: CLLocationAccuracy { get }
    var locationProvider: NavigationLocationManager.Type { get }
}

@available(*, deprecated, renamed: "NavigationEventsManager")
public typealias EventsManager = NavigationEventsManager

/**
 The `NavigationEventsManager` is responsible for being the liaison between MapboxCoreNavigation and the Mapbox telemetry framework.
 */
open class NavigationEventsManager: NSObject {
    var sessionState: SessionState?
    
    var outstandingFeedbackEvents = [CoreFeedbackEvent]()
    
    weak var dataSource: EventsManagerDataSource?
    
    /**
     Indicates whether the application depends on MapboxNavigation in addition to MapboxCoreNavigation.
     */
    var usesDefaultUserInterface = {
        // Assumption: MapboxNavigation.framework includes NavigationViewController and exposes it to the Objective-C runtime as MapboxNavigation.NavigationViewController.
        return NSClassFromString("MapboxNavigation.NavigationViewController") != nil
    }()

    /// :nodoc: the internal lower-level mobile events manager is an implementation detail which should not be manipulated directly
    private var mobileEventsManager: MMEEventsManager!

    lazy var accessToken: String = {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
        let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject],
        let token = dict["MGLMapboxAccessToken"] as? String else {
            //we can assert here because if the token was passed in, it would of overriden this closure.
            //we return an empty string so we don't crash in production (in keeping with behavior of `assert`)
            assertionFailure("`accessToken` must be set in the Info.plist as `MGLMapboxAccessToken` or the `Route` passed into the `NavigationService` must have the `accessToken` property set.")
            return ""
        }
        return token
    }()
    
    public required init(dataSource source: EventsManagerDataSource?, accessToken possibleToken: String? = nil, mobileEventsManager: MMEEventsManager = .shared()) {
        dataSource = source
        super.init()
        if let tokenOverride = possibleToken {
            accessToken = tokenOverride
        }
        self.mobileEventsManager = mobileEventsManager
        start()
        resumeNotifications()
    }
    
    deinit {
        suspendNotifications()
        sessionState = nil
    }
    
    private func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(_:)), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeOrientation(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeApplicationState(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeApplicationState(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    private func suspendNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    /**
     When set to `false`, flushing of telemetry events is not delayed. Is set to `true` by default.
     */
    public var delaysEventFlushing = true

    func start() {
        let userAgent = usesDefaultUserInterface ? "mapbox-navigation-ui-ios" : "mapbox-navigation-ios"
        mobileEventsManager.initialize(withAccessToken: accessToken, userAgentBase: userAgent, hostSDKVersion: String(describing: Bundle.mapboxCoreNavigation.object(forInfoDictionaryKey: "CFBundleShortVersionString")!))
        mobileEventsManager.disableLocationMetrics()
        mobileEventsManager.sendTurnstileEvent()
    }
    
    func navigationCancelEvent(rating potentialRating: Int? = nil, comment: String? = nil) -> NavigationEventDetails? {
        guard let dataSource = dataSource, let sessionState = sessionState else { return nil }
        
        let rating = potentialRating ?? MMEEventsManager.unrated
        var event = NavigationEventDetails(dataSource: dataSource, session: sessionState, defaultInterface: usesDefaultUserInterface)
        event.event = MMEEventTypeNavigationCancel
        event.arrivalTimestamp = sessionState.arrivalTimestamp
        
        let validRating: Bool = (rating >= MMEEventsManager.unrated && rating <= 100)
        assert(validRating, "MMEEventsManager: Invalid Rating. Values should be between \(MMEEventsManager.unrated) (none) and 100.")
        guard validRating else { return event }
        
        event.rating = rating
        event.comment = comment
        
        return event
    }
    
    func navigationRouteRetrievalEvent() -> PerformanceEventDetails? {
        guard let sessionState = sessionState,
            let responseEndDate = sessionState.currentRoute.responseEndDate,
            let fetchStartDate = sessionState.currentRoute.fetchStartDate else {
            return nil
        }

        var event = PerformanceEventDetails(event: NavigationEventTypeRouteRetrieval, session: sessionState, createdOn: sessionState.currentRoute.responseEndDate)
        event.counters.append(PerformanceEventDetails.Counter(name: "elapsed_time",
                                                              value: responseEndDate.timeIntervalSince(fetchStartDate)))
        if let routeIdentifier = sessionState.currentRoute.routeIdentifier {
            event.attributes.append(PerformanceEventDetails.Attribute(name: "route_uuid", value: routeIdentifier))
        }
        return event
    }
    
    func navigationDepartEvent() -> NavigationEventDetails? {
        guard let dataSource = dataSource, let sessionState = sessionState else { return nil }

        var event = NavigationEventDetails(dataSource: dataSource, session: sessionState, defaultInterface: usesDefaultUserInterface)
        event.event = MMEEventTypeNavigationDepart
        return event
    }
    
    func navigationArriveEvent() -> NavigationEventDetails? {
        guard let dataSource = dataSource, let sessionState = sessionState else { return nil }

        var event = NavigationEventDetails(dataSource: dataSource, session: sessionState, defaultInterface: usesDefaultUserInterface)
        event.event = MMEEventTypeNavigationArrive
        
        event.arrivalTimestamp = dataSource.router.rawLocation?.timestamp ?? Date()
        return event
    }
    
    func navigationFeedbackEventWithLocationsAdded(event: CoreFeedbackEvent) -> [String: Any] {
        var eventDictionary = event.eventDictionary
        eventDictionary["feedbackId"] = event.id.uuidString
        eventDictionary["locationsBefore"] = sessionState?.pastLocations.allObjects.filter { $0.timestamp <= event.timestamp}.map {$0.dictionaryRepresentation}
        eventDictionary["locationsAfter"] = sessionState?.pastLocations.allObjects.filter {$0.timestamp > event.timestamp}.map {$0.dictionaryRepresentation}
        return eventDictionary
    }
    
    func navigationFeedbackEvent(type: FeedbackType, description: String?) -> NavigationEventDetails? {
        guard let dataSource = dataSource, let sessionState = sessionState else { return nil }

        var event = NavigationEventDetails(dataSource: dataSource, session: sessionState, defaultInterface: usesDefaultUserInterface)
        event.event = MMEEventTypeNavigationFeedback
        
        event.userId = UIDevice.current.identifierForVendor?.uuidString
        event.feedbackType = type.description
        event.description = description
        
        event.screenshot = captureScreen(scaledToFit: 250)?.base64EncodedString()
        
        return event
    }
    
    func navigationRerouteEvent(eventType: String = MMEEventTypeNavigationReroute) -> NavigationEventDetails? {
        guard let dataSource = dataSource, let sessionState = sessionState else { return nil }

        let timestamp = dataSource.router.rawLocation?.timestamp ?? Date()
        
        var event = NavigationEventDetails(dataSource: dataSource, session: sessionState, defaultInterface: usesDefaultUserInterface)
        event.event = eventType
        event.created = timestamp
        
        if let lastRerouteDate = sessionState.lastRerouteDate {
            event.secondsSinceLastReroute = round(timestamp.timeIntervalSince(lastRerouteDate))
        } else {
            event.secondsSinceLastReroute = -1
        }
        
        // These are placeholders until the route controller's RouteProgress is updated after rerouting
        event.newDistanceRemaining = -1
        event.newDurationRemaining = -1
        event.newGeometry = nil
        event.screenshot = captureScreen(scaledToFit: 250)?.base64EncodedString()
        
        return event
    }

    public func sendCarPlayConnectEvent() {
        let date = Date()
        mobileEventsManager.enqueueEvent(withName: MMEventTypeNavigationCarplayConnect, attributes: [MMEEventKeyEvent: MMEventTypeNavigationCarplayConnect, MMEEventKeyCreated: date.ISO8601])
        mobileEventsManager.flush()
    }

    public func sendCarPlayDisconnectEvent() {
        let date = Date()
        mobileEventsManager.enqueueEvent(withName: MMEventTypeNavigationCarplayDisconnect, attributes: [MMEEventKeyEvent: MMEventTypeNavigationCarplayDisconnect, MMEEventKeyCreated: date.ISO8601])
        mobileEventsManager.flush()
    }
    
    func sendRouteRetrievalEvent() {
        guard let attributes = (try? navigationRouteRetrievalEvent()?.asDictionary()) as [String: Any]?? else { return }
        mobileEventsManager.enqueueEvent(withName: NavigationEventTypeRouteRetrieval, attributes: attributes ?? [:])
        mobileEventsManager.flush()
    }

    func sendDepartEvent() {
        guard let attributes = (try? navigationDepartEvent()?.asDictionary()) as [String: Any]?? else { return }
        mobileEventsManager.enqueueEvent(withName: MMEEventTypeNavigationDepart, attributes: attributes ?? [:])
        mobileEventsManager.flush()
    }
    
    func sendArriveEvent() {
        guard let attributes = (try? navigationArriveEvent()?.asDictionary()) as [String: Any]?? else { return }
        mobileEventsManager.enqueueEvent(withName: MMEEventTypeNavigationArrive, attributes: attributes ?? [:])
        mobileEventsManager.flush()
    }
    
    func sendCancelEvent(rating: Int? = nil, comment: String? = nil) {
        guard let attributes = (try? navigationCancelEvent(rating: rating, comment: comment)?.asDictionary()) as [String: Any]?? else { return }
        mobileEventsManager.enqueueEvent(withName: MMEEventTypeNavigationCancel, attributes: attributes ?? [:])
        mobileEventsManager.flush()
    }
    
    func sendFeedbackEvents(_ events: [CoreFeedbackEvent]) {
        events.forEach { event in
            // remove from outstanding event queue
            if let index = outstandingFeedbackEvents.firstIndex(of: event) {
                outstandingFeedbackEvents.remove(at: index)
            }
            
            let eventName = event.eventDictionary["event"] as! String
            let eventDictionary = navigationFeedbackEventWithLocationsAdded(event: event)
            
            mobileEventsManager.enqueueEvent(withName: eventName, attributes: eventDictionary)
        }
        mobileEventsManager.flush()
    }
    
    func enqueueFeedbackEvent(type: FeedbackType, description: String?) -> UUID? {
        guard let eventDictionary = (try? navigationFeedbackEvent(type: type, description: description)?.asDictionary()) as [String: Any]?? else { return nil }
        let event = FeedbackEvent(timestamp: Date(), eventDictionary: eventDictionary ?? [:])
        outstandingFeedbackEvents.append(event)
        return event.id
    }

    func enqueueRerouteEvent() {
        guard let eventDictionary = (try? navigationRerouteEvent()?.asDictionary()) as [String: Any]?? else { return }
        let timestamp = dataSource?.router.location?.timestamp ?? Date()
        
        sessionState?.lastRerouteDate = timestamp
        sessionState?.numberOfReroutes += 1
        
        let event = RerouteEvent(timestamp: timestamp, eventDictionary: eventDictionary ?? [:])
        
        outstandingFeedbackEvents.append(event)
    }
    
    func resetSession() {
        guard let dataSource = dataSource else { return }

        let route = dataSource.routeProgress.route
        sessionState = SessionState(currentRoute: route, originalRoute: route)
    }

    func enqueueFoundFasterRouteEvent() {
        guard let eventDictionary = (try? navigationRerouteEvent(eventType: FasterRouteFoundEvent)?.asDictionary()) as [String: Any]?? else { return }

        let timestamp = Date()
        sessionState?.lastRerouteDate = timestamp
        
        let event = RerouteEvent(timestamp: Date(), eventDictionary: eventDictionary ?? [:])
        
        outstandingFeedbackEvents.append(event)
    }
    
    func sendOutstandingFeedbackEvents(forceAll: Bool) {
        let flushAll = forceAll || !shouldDelayEvents()
        let eventsToPush = eventsToFlush(flushAll: flushAll)
        
        sendFeedbackEvents(eventsToPush)
    }
    
    func eventsToFlush(flushAll: Bool) -> [CoreFeedbackEvent] {
        let now = Date()
        let eventsToPush = flushAll ? outstandingFeedbackEvents : outstandingFeedbackEvents.filter {
            now.timeIntervalSince($0.timestamp) > SecondsBeforeCollectionAfterFeedbackEvent
        }
        return eventsToPush
    }
    
    private func shouldDelayEvents() -> Bool {
        return delaysEventFlushing
    }
    
    /**
     Send feedback about the current road segment/maneuver to the Mapbox data team.
     
     You can pair this with a custom feedback UI in your app to flag problems during navigation such as road closures, incorrect instructions, etc.
     
     @param type A `FeedbackType` used to specify the type of feedback
     @param description A custom string used to describe the problem in detail.
     @return Returns a UUID used to identify the feedback event
     
     If you provide a custom feedback UI that lets users elaborate on an issue, you should call this before you show the custom UI so the location and timestamp are more accurate.
     
     You can then call `updateFeedback(uuid:type:source:description:)` with the returned feedback UUID to attach any additional metadata to the feedback.
     */
    public func recordFeedback(type: FeedbackType = .general, description: String? = nil) -> UUID? {
        return enqueueFeedbackEvent(type: type, description: description)
    }
    
    /**
     Update the feedback event with a specific feedback identifier. If you implement a custom feedback UI that lets a user elaborate on an issue, you can use this to update the metadata.
     
     Note that feedback is sent 20 seconds after being recorded, so you should promptly update the feedback metadata after the user discards any feedback UI.
     */
    public func updateFeedback(uuid: UUID, type: FeedbackType, source: FeedbackSource, description: String?) {
        if let lastFeedback = outstandingFeedbackEvents.first(where: { $0.id == uuid}) as? FeedbackEvent {
            lastFeedback.update(type: type, source: source, description: description)
        }
    }
    
    /**
     Discard a recorded feedback event, for example if you have a custom feedback UI and the user canceled feedback.
     */
    public func cancelFeedback(uuid: UUID) {
        if let index = outstandingFeedbackEvents.firstIndex(where: {$0.id == uuid}) {
            outstandingFeedbackEvents.remove(at: index)
        }
    }
    
    //MARK: - Session State Management
    @objc private func didChangeOrientation(_ notification: NSNotification) {
        sessionState?.reportChange(to: UIDevice.current.orientation)
    }
    
    @objc private func didChangeApplicationState(_ notification: NSNotification) {
        sessionState?.reportChange(to: UIApplication.shared.applicationState)
    }
    
    @objc private func applicationWillTerminate(_ notification: NSNotification) {
        if sessionState?.terminated == false {
            sendCancelEvent(rating: nil, comment: nil)
            sessionState?.terminated = true
        }
        
        sendOutstandingFeedbackEvents(forceAll: true)
    }
    
    func reportReroute(progress: RouteProgress, proactive: Bool) {
        let route = progress.route
        
        // if the user has already arrived and a new route has been set, restart the navigation session
        if sessionState?.arrivalTimestamp != nil {
            resetSession()
        } else {
            sessionState?.currentRoute = route
        }
        
        if (proactive) {
            enqueueFoundFasterRouteEvent()
        }
        let latestReroute = outstandingFeedbackEvents.compactMap({ $0 as? RerouteEvent }).last
        latestReroute?.update(newRoute: route)
    }
    
    func update(progress: RouteProgress) {
        defer {
            // ensure we always flush, irrespective of how the method exits
            sendOutstandingFeedbackEvents(forceAll: false)
        }
        
        if sessionState?.arrivalTimestamp == nil,
            progress.currentLegProgress.userHasArrivedAtWaypoint {
            sessionState?.arrivalTimestamp = dataSource?.router.location?.timestamp ?? Date()
            sendArriveEvent()
            
            return
        }
        
        if sessionState?.departureTimestamp == nil {
            sessionState?.departureTimestamp = dataSource?.router.location?.timestamp ?? Date()
            sendDepartEvent()
        }
    }
}
