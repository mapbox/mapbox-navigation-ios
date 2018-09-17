import Foundation
import MapboxMobileEvents
import MapboxDirections

/**
 The `EventsManager` is responsible for being the liaison between the RouteController and the telemetry framework.
 
 `SessionState` is a struct that stores all memoized statistics that we later send to the telemetry engine.
 */
@objc(MBEventsManager)
open class EventsManager: NSObject {
    
    @objc public var manager = MMEEventsManager.shared()
    
    var sessionState: SessionState?
    
    var outstandingFeedbackEvents = [CoreFeedbackEvent]()
    
    weak var routeController: Router?
    
    /// :nodoc: This is used internally when the navigation UI is being used
    var usesDefaultUserInterface = false
    
    lazy var accessToken: String = {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
        let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject],
        let token = dict["MGLMapboxAccessToken"] as? String else {
            //we can assert here because if the token was passed in, it would of overriden this closure.
            //we return an empty string so we don't crash in production (in keeping with behavior of `assert`)
            assertionFailure("`accessToken` must be set in the Info.plist as `MGLMapboxAccessToken` or the `Route` passed into the `RouteController` must have the `accessToken` property set.")
            return ""
        }
        return token
    }()
    
    @objc public init(accessToken possibleToken: String? = nil) {
        super.init()
        if let tokenOverride = possibleToken {
            accessToken = tokenOverride
        }
        
        resumeNotifications()
    }
    
    deinit {
        suspendNotifications()
    }
    
    private func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(_:)), name: .UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeOrientation(_:)), name: .UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeApplicationState(_:)), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeApplicationState(_:)), name: .UIApplicationDidEnterBackground, object: nil)
    }
    
    private func suspendNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    /**
     When set to `false`, flushing of telemetry events is not delayed. Is set to `true` by default.
     */
    @objc public var delaysEventFlushing = true
    
    func start() {
        let eventLoggingEnabled = UserDefaults.standard.bool(forKey: NavigationMetricsDebugLoggingEnabled)
        
        manager.isDebugLoggingEnabled = eventLoggingEnabled
        manager.isMetricsEnabledInSimulator = true
        manager.isMetricsEnabledForInUsePermissions = true
        let userAgent = usesDefaultUserInterface ? "mapbox-navigation-ui-ios" : "mapbox-navigation-ios"
        manager.initialize(withAccessToken: accessToken, userAgentBase: userAgent, hostSDKVersion: String(describing: Bundle(for: RouteController.self).object(forInfoDictionaryKey: "CFBundleShortVersionString")!))
        manager.disableLocationMetrics()
        manager.sendTurnstileEvent()
    }
    
    func navigationCancelEvent(rating potentialRating: Int? = nil, comment: String? = nil) -> EventDetails? {
        guard let routeController = routeController else {
            return nil
        }
        
        guard var event = EventDetails.defaultEvents(router: routeController) else {
            return nil
        }
        
        let rating = potentialRating ?? MMEEventsManager.unrated
        
        event.event = MMEEventTypeNavigationCancel
        event.arrivalTimestamp = sessionState?.arrivalTimestamp
        
        let validRating: Bool = (rating >= MMEEventsManager.unrated && rating <= 100)
        assert(validRating, "MMEEventsManager: Invalid Rating. Values should be between \(MMEEventsManager.unrated) (none) and 100.")
        guard validRating else { return event }
        
        event.rating = rating
        event.comment = comment
        
        return event
    }
    
    func navigationDepartEvent() -> EventDetails? {
        guard let routeController = routeController else {
            return nil
        }
        
        guard var event = EventDetails.defaultEvents(router: routeController) else {
            return nil
        }
        
        event.event = MMEEventTypeNavigationDepart
        return event
    }
    
    func navigationArriveEvent() -> EventDetails? {
        guard let routeController = routeController else {
            return nil
        }
        
        guard var event = EventDetails.defaultEvents(router: routeController) else {
            return nil
        }
        
        event.event = MMEEventTypeNavigationArrive
        return event
    }
    
    func navigationFeedbackEventWithLocationsAdded(event: CoreFeedbackEvent) -> [String: Any] {
        var eventDictionary = event.eventDictionary
        eventDictionary["feedbackId"] = event.id.uuidString
        eventDictionary["locationsBefore"] = sessionState?.pastLocations.allObjects.filter { $0.timestamp <= event.timestamp}.map {$0.dictionaryRepresentation}
        eventDictionary["locationsAfter"] = sessionState?.pastLocations.allObjects.filter {$0.timestamp > event.timestamp}.map {$0.dictionaryRepresentation}
        return eventDictionary
    }
    
    func navigationFeedbackEvent(type: FeedbackType, description: String?) -> EventDetails? {
        guard let routeController = routeController else {
            return nil
        }
        
        guard var event = EventDetails.defaultEvents(router: routeController) else {
            return nil
        }
        
        event.event = MMEEventTypeNavigationFeedback
        
        event.userId = UIDevice.current.identifierForVendor?.uuidString
        event.feedbackType = type.description
        event.description = description
        
        event.screenshot = captureScreen(scaledToFit: 250)?.base64EncodedString()
        
        return event
    }
    
    func navigationRerouteEvent(eventType: String = MMEEventTypeNavigationReroute) -> EventDetails? {
        guard let routeController = routeController else {
            return nil
        }
        
        guard var event = EventDetails.defaultEvents(router: routeController) else {
            return nil
        }
        
        let timestamp = Date()
        
        event.event = eventType
        if let lastRerouteDate = sessionState?.lastRerouteDate {
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
}

extension EventsManager {
    
    func sendDepartEvent() {
        guard let departEvent = navigationDepartEvent(),
              let attributes = try? departEvent.asDictionary() else { return }
        manager.enqueueEvent(withName: MMEEventTypeNavigationDepart, attributes: attributes)
        manager.flush()
    }
    
    
    func sendArriveEvent() {
        guard let arriveEvent = navigationArriveEvent(), let attributes = try? arriveEvent.asDictionary() else { return }
        manager.enqueueEvent(withName: MMEEventTypeNavigationArrive, attributes: attributes)
        manager.flush()
    }
    
    func sendCancelEvent(rating: Int? = nil, comment: String? = nil) {
        guard routeController != nil else { return }
        guard let cancelEvent = navigationCancelEvent(rating: rating, comment: comment), let attributes = try? cancelEvent.asDictionary() else { return }
        manager.enqueueEvent(withName: MMEEventTypeNavigationCancel, attributes: attributes)
        manager.flush()
    }
    
    func sendFeedbackEvents(_ events: [CoreFeedbackEvent]) {
        events.forEach { event in
            // remove from outstanding event queue
            if let index = outstandingFeedbackEvents.index(of: event) {
                outstandingFeedbackEvents.remove(at: index)
            }
            
            let eventName = event.eventDictionary["event"] as! String
            let eventDictionary = navigationFeedbackEventWithLocationsAdded(event: event)
            
            manager.enqueueEvent(withName: eventName, attributes: eventDictionary)
        }
        manager.flush()
    }
    
    func enqueueFeedbackEvent(type: FeedbackType, description: String?) -> UUID? {
        guard let feedbackEvent = navigationFeedbackEvent(type: type, description: description) else {
            return nil
        }
        let eventDictionary = try! feedbackEvent.asDictionary()
        let event = FeedbackEvent(timestamp: Date(), eventDictionary: eventDictionary)
        outstandingFeedbackEvents.append(event)
        return event.id
    }
    
    func enqueueRerouteEvent() -> String? {
        guard let rerouteEvent = navigationRerouteEvent() else {
            return nil
        }
        
        let timestamp = Date()
        let eventDictionary = try! rerouteEvent.asDictionary()
        
        sessionState?.lastRerouteDate = timestamp
        sessionState?.numberOfReroutes += 1
        
        let event = RerouteEvent(timestamp: Date(), eventDictionary: eventDictionary)
        
        outstandingFeedbackEvents.append(event)
        
        return event.id.uuidString
    }
    
    func resetSession() {
        guard let route = routeController?.routeProgress.route else {
            return
        }
        sessionState = SessionState(currentRoute: route, originalRoute: route)
    }
    
    func enqueueFoundFasterRouteEvent() -> String? {
        guard let rerouteEvent = navigationRerouteEvent(eventType: FasterRouteFoundEvent) else {
            return nil
        }
        let timestamp = Date()
        let eventDictionary = try! rerouteEvent.asDictionary()
        
        sessionState?.lastRerouteDate = timestamp
        
        let event = RerouteEvent(timestamp: Date(), eventDictionary: eventDictionary)
        
        outstandingFeedbackEvents.append(event)
        
        return event.id.uuidString
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
    @objc public func recordFeedback(type: FeedbackType = .general, description: String? = nil) -> UUID? {
        return enqueueFeedbackEvent(type: type, description: description)
    }
    
    /**
     Update the feedback event with a specific feedback identifier. If you implement a custom feedback UI that lets a user elaborate on an issue, you can use this to update the metadata.
     
     Note that feedback is sent 20 seconds after being recorded, so you should promptly update the feedback metadata after the user discards any feedback UI.
     */
    @objc public func updateFeedback(uuid: UUID, type: FeedbackType, source: FeedbackSource, description: String?) {
        if let lastFeedback = outstandingFeedbackEvents.first(where: { $0.id == uuid}) as? FeedbackEvent {
            lastFeedback.update(type: type, source: source, description: description)
        }
    }
    
    /**
     Discard a recorded feedback event, for example if you have a custom feedback UI and the user canceled feedback.
     */
    @objc public func cancelFeedback(uuid: UUID) {
        if let index = outstandingFeedbackEvents.index(where: {$0.id == uuid}) {
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
    
    func reportReroute(newRoute: Route, proactive: Bool) {
        if (proactive) {
            _ = enqueueFoundFasterRouteEvent()
        }
        let latestReroute = outstandingFeedbackEvents.compactMap({ $0 as? RerouteEvent }).last
        latestReroute?.update(newRoute: newRoute)
    }
    
    @objc func update(progress: RouteProgress) {
        if sessionState?.departureTimestamp == nil {
            sessionState?.departureTimestamp = Date()
            sendDepartEvent()
        }
        
        if sessionState?.arrivalTimestamp == nil,
            progress.currentLegProgress.userHasArrivedAtWaypoint {
            sessionState?.arrivalTimestamp = Date()
            sendArriveEvent()
        }
        
        sendOutstandingFeedbackEvents(forceAll: false)
    }
}
