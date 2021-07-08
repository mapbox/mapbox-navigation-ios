import Foundation
import MapboxMobileEvents
import MapboxDirections

let NavigationEventTypeRouteRetrieval = "mobile.performance_trace"

/**
 The `EventsManagerFreeDriveDataSource` protocol declares values required for recording free drive events.
 */
public protocol EventsManagerFreeDriveDataSource: AnyObject {
    var rawLocation: CLLocation? { get }
}

extension PassiveLocationManager: EventsManagerFreeDriveDataSource {
    public var rawLocation: CLLocation? {
        return self.lastRawLocation
    }
}

/**
 The `EventsManagerDataSource` protocol declares values required for recording route following events.
 */
public protocol EventsManagerDataSource: AnyObject {
    var routeProgress: RouteProgress { get }
    var router: Router! { get }
    var desiredAccuracy: CLLocationAccuracy { get }
    var locationProvider: NavigationLocationManager.Type { get }
}

open class FreeDriveNavigationEventsManager: NavigationEventsManager {
    public weak var freeDriveDataSource: EventsManagerFreeDriveDataSource?
    
    public init(freeDriveDataSource: EventsManagerFreeDriveDataSource) {
        self.freeDriveDataSource = freeDriveDataSource
        super.init(dataSource: nil)
    }
    
    public required init(dataSource source: EventsManagerDataSource?, accessToken possibleToken: String? = nil, mobileEventsManager: MMEEventsManager = .shared()) {
        super.init(dataSource: nil)
    }
    
    override func navigationFeedbackEvent() -> EventDetails? {
        guard let freeDriveDataSource = freeDriveDataSource else { return nil }
        var event = FreeDriveEventDetails(dataSource: freeDriveDataSource)
        event.event = MMEEventTypeNavigationFeedback
        event.userId = UIDevice.current.identifierForVendor?.uuidString
                
        event.screenshot = captureScreen(scaledToFit: 250)?.base64EncodedString()

        return event
    }
}

/**
 The `NavigationEventsManager` is responsible for being the liaison between MapboxCoreNavigation and the Mapbox telemetry framework.
 */
open class NavigationEventsManager {
    var sessionState: SessionState?
    
    var outstandingFeedbackEvents = [CoreFeedbackEvent]()
    
    func withBackupDataSource(_ forcedDataSource: EventsManagerDataSource, action: () -> Void) {
        backupDataSource = forcedDataSource
        action()
        backupDataSource = nil
    }
    
    private var backupDataSource: EventsManagerDataSource?
    private weak var _dataSource: EventsManagerDataSource?
    var dataSource: EventsManagerDataSource?
    {
        get {
            return _dataSource ?? backupDataSource
        }
        set {
            _dataSource = newValue
        }
    }
    
    /**
     Indicates whether the application depends on MapboxNavigation in addition to MapboxCoreNavigation.
     */
    var usesDefaultUserInterface = {
        return Bundle.mapboxNavigationIfInstalled != nil
    }()

    /// :nodoc: the internal lower-level mobile events manager is an implementation detail which should not be manipulated directly
    private var mobileEventsManager: MMEEventsManager!

    lazy var accessToken: String = {
        guard let token = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String ??
                Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAccessToken") as? String
        else {
            //we can assert here because if the token was passed in, it would of overriden this closure.
            //we return an empty string so we don't crash in production (in keeping with behavior of `assert`)
            assertionFailure("`accessToken` must be set in the Info.plist as `MGLMapboxAccessToken` or the `Route` passed into the `NavigationService` must have the `accessToken` property set.")
            return ""
        }
        return token
    }()
    
    public required init(dataSource source: EventsManagerDataSource?, accessToken possibleToken: String? = nil, mobileEventsManager: MMEEventsManager = .shared()) {
        dataSource = source
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

        guard let stringForShortVersion = Bundle.string(forMapboxCoreNavigationInfoDictionaryKey: "CFBundleShortVersionString") else {
            preconditionFailure("CFBundleShortVersionString must be set in the Info.plist.")
        }
        mobileEventsManager.initialize(withAccessToken: accessToken, userAgentBase: userAgent, hostSDKVersion: String(describing:stringForShortVersion))
        mobileEventsManager.sendTurnstileEvent()
    }
    
    func navigationCancelEvent(rating potentialRating: Int? = nil, comment: String? = nil) -> ActiveGuidanceEventDetails? {
        guard let dataSource = dataSource, let sessionState = sessionState else { return nil }
        
        let rating = potentialRating ?? MMEEventsManager.unrated
        var event = ActiveGuidanceEventDetails(dataSource: dataSource, session: sessionState, defaultInterface: usesDefaultUserInterface)
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
    
    func navigationDepartEvent() -> ActiveGuidanceEventDetails? {
        guard let dataSource = dataSource, let sessionState = sessionState else { return nil }

        var event = ActiveGuidanceEventDetails(dataSource: dataSource, session: sessionState, defaultInterface: usesDefaultUserInterface)
        event.event = MMEEventTypeNavigationDepart
        return event
    }
    
    func navigationArriveEvent() -> ActiveGuidanceEventDetails? {
        guard let dataSource = dataSource, let sessionState = sessionState else { return nil }

        var event = ActiveGuidanceEventDetails(dataSource: dataSource, session: sessionState, defaultInterface: usesDefaultUserInterface)
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
    
    func navigationFeedbackEvent() -> EventDetails? {
        guard let dataSource = dataSource, let sessionState = sessionState else { return nil }

        var event = ActiveGuidanceEventDetails(dataSource: dataSource, session: sessionState, defaultInterface: usesDefaultUserInterface)
        event.event = MMEEventTypeNavigationFeedback
        
        event.userId = UIDevice.current.identifierForVendor?.uuidString
        
        event.screenshot = captureScreen(scaledToFit: 250)?.base64EncodedString()
        
        return event
    }
    
    func navigationRerouteEvent(eventType: String = MMEEventTypeNavigationReroute) -> ActiveGuidanceEventDetails? {
        guard let dataSource = dataSource, let sessionState = sessionState else { return nil }

        let timestamp = dataSource.router.rawLocation?.timestamp ?? Date()
        
        var event = ActiveGuidanceEventDetails(dataSource: dataSource, session: sessionState, defaultInterface: usesDefaultUserInterface)
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
     Create feedback about the current road segment/maneuver to be sent to the Mapbox data team.
     
     You can pair this with a custom feedback UI in your app to flag problems during navigation such as road closures, incorrect instructions, etc.
     
     @return Returns a feedback event
     
     If you provide a custom feedback UI that lets users elaborate on an issue, you should call this before you show the custom UI so the location and timestamp are more accurate.
     
     You can then call `sendFeedback(_:type:source:description:)` with the returned feedback to attach any additional metadata to the feedback and send it.
     */
    public func createFeedback() -> FeedbackEvent? {
        guard let feedbackEvent = navigationFeedbackEvent() else { return nil }
        let eventDictionary = try? feedbackEvent.asDictionary()
        let event = FeedbackEvent(timestamp: Date(), eventDictionary: eventDictionary ?? [:])
        return event
    }
    
    /**
     Send feedback to the Mapbox data team.
     
     You can pair this with a custom feedback UI in your app to flag problems during navigation such as road closures, incorrect instructions, etc.
     
     @param feedback A `FeedbackEvent` created with `createFeedback()` method.
     @param type A `FeedbackType` used to specify the type of feedback
     @param source A `FeedbackSource` used to specify the source of feedback.
     @param description A custom string used to describe the problem in detail.
     */
    public func sendFeedback(_ feedback: FeedbackEvent, type: FeedbackType, source: FeedbackSource, description: String?) {
        feedback.update(type: type, source: source, description: description)
        sendFeedbackEvents([feedback])
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
