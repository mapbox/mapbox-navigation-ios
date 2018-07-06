import Foundation
import MapboxMobileEvents
import MapboxDirections


@objc(MBEventsManager)
open class EventsManager: NSObject {
    
    @objc public var manager = MMEEventsManager.shared()
    
    var sessionState: SessionState! // TODO: avoid IUO
    
    var outstandingFeedbackEvents = [CoreFeedbackEvent]()
    
    // TODO: replace by the `delegate`
    weak var routeController: RouteController! // TODO: avoid IUO
    
    /// :nodoc: This is used internally when the navigation UI is being used
    var usesDefaultUserInterface = false
    
    var endOfRouteStarRating: Int?
    var endOfRouteComment: String?
    
    /**
     When set to `false`, flushing of telemetry events is not delayed. Is set to `true` by default.
     */
    @objc public var delaysEventFlushing = true
    
    func startEvents(accessToken: String?) {
        let eventLoggingEnabled = UserDefaults.standard.bool(forKey: NavigationMetricsDebugLoggingEnabled)
        
        var mapboxAccessToken: String? = nil
        
        if let accessToken = accessToken {
            mapboxAccessToken = accessToken
        } else if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject],
            let token = dict["MGLMapboxAccessToken"] as? String {
            mapboxAccessToken = token
        }
        
        if let mapboxAccessToken = mapboxAccessToken {
            manager.isDebugLoggingEnabled = eventLoggingEnabled
            manager.isMetricsEnabledInSimulator = true
            manager.isMetricsEnabledForInUsePermissions = true
            let userAgent = usesDefaultUserInterface ? "mapbox-navigation-ui-ios" : "mapbox-navigation-ios"
            manager.initialize(withAccessToken: mapboxAccessToken, userAgentBase: userAgent, hostSDKVersion: String(describing: Bundle(for: RouteController.self).object(forInfoDictionaryKey: "CFBundleShortVersionString")!))
            manager.disableLocationMetrics()
            manager.sendTurnstileEvent()
        } else {
            assert(false, "`accessToken` must be set in the Info.plist as `MGLMapboxAccessToken` or the `Route` passed into the `RouteController` must have the `accessToken` property set.")
        }
    }
    
    func navigationCancelEvent(rating potentialRating: Int? = nil, comment: String? = nil) -> EventDetails {
        let rating = potentialRating ?? MMEEventsManager.unrated
        var event = EventDetails.defaultEvents(routeController: routeController)
        event.event = MMEEventTypeNavigationCancel
        event.arrivalTimestamp = sessionState.arrivalTimestamp
        
        let validRating: Bool = (rating >= MMEEventsManager.unrated && rating <= 100)
        assert(validRating, "MMEEventsManager: Invalid Rating. Values should be between \(MMEEventsManager.unrated) (none) and 100.")
        guard validRating else { return event }
        
        event.rating = rating
        event.comment = comment
        
        return event
    }
    
    func navigationDepartEvent() -> EventDetails {
        var event = EventDetails.defaultEvents(routeController: routeController)
        event.event = MMEEventTypeNavigationDepart
        return event
    }
    
    func navigationArriveEvent() -> EventDetails {
        var event = EventDetails.defaultEvents(routeController: routeController)
        event.event = MMEEventTypeNavigationArrive
        return event
    }
    
    func navigationFeedbackEventWithLocationsAdded(event: CoreFeedbackEvent) -> [String: Any] {
        var eventDictionary = event.eventDictionary
        eventDictionary["feedbackId"] = event.id.uuidString
        eventDictionary["locationsBefore"] = sessionState.pastLocations.allObjects.filter { $0.timestamp <= event.timestamp}.map {$0.dictionaryRepresentation}
        eventDictionary["locationsAfter"] = sessionState.pastLocations.allObjects.filter {$0.timestamp > event.timestamp}.map {$0.dictionaryRepresentation}
        return eventDictionary
    }
    
    func navigationFeedbackEvent(type: FeedbackType, description: String?) -> EventDetails {
        var event = EventDetails.defaultEvents(routeController: routeController)
        event.event = MMEEventTypeNavigationFeedback
        
        event.userId = UIDevice.current.identifierForVendor?.uuidString
        event.feedbackType = type.description
        event.description = description
        
        event.routeLegProgress = routeController.routeProgress.currentLegProgress
        event.screenshot = captureScreen(scaledToFit: 250)?.base64EncodedString()
        
        return event
    }
    
    func navigationRerouteEvent(eventType: String = MMEEventTypeNavigationReroute) -> EventDetails {
        let timestamp = Date()
        
        var event = EventDetails.defaultEvents(routeController: routeController)
        event.event = eventType
        event.secondsSinceLastReroute = sessionState.lastRerouteDate != nil ? round(timestamp.timeIntervalSince(sessionState.lastRerouteDate!)) : -1
        
        event.routeLegProgress = routeController.routeProgress.currentLegProgress
        
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
        guard let attributes = try? navigationDepartEvent().asDictionary() else { return }
        manager.enqueueEvent(withName: MMEEventTypeNavigationDepart, attributes: attributes)
        manager.flush()
    }
    
    
    func sendArriveEvent() {
        guard let attributes = try? navigationArriveEvent().asDictionary() else { return }
        manager.enqueueEvent(withName: MMEEventTypeNavigationArrive, attributes: attributes)
        manager.flush()
    }
    
    func sendCancelEvent(rating: Int? = nil, comment: String? = nil) {
        // TODO: Fix routeController is nilled out too early
        guard routeController != nil else { return }
        guard let attributes = try? navigationCancelEvent(rating: rating, comment: comment).asDictionary() else { return }
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
    
    func enqueueFeedbackEvent(type: FeedbackType, description: String?) -> UUID {
        let eventDictionary = try! navigationFeedbackEvent(type: type, description: description).asDictionary()
        let event = FeedbackEvent(timestamp: Date(), eventDictionary: eventDictionary)
        outstandingFeedbackEvents.append(event)
        return event.id
    }
    
    func enqueueRerouteEvent() -> String {
        let timestamp = Date()
        let eventDictionary = try! navigationRerouteEvent().asDictionary()
        
        sessionState.lastRerouteDate = timestamp
        sessionState.numberOfReroutes += 1
        
        let event = RerouteEvent(timestamp: Date(), eventDictionary: eventDictionary)
        
        outstandingFeedbackEvents.append(event)
        
        return event.id.uuidString
    }
    
    func resetSession() {
        let route = routeController.routeProgress.route
        sessionState = SessionState(currentRoute: route, originalRoute: route)
    }
    
    func enqueueFoundFasterRouteEvent() -> String {
        let timestamp = Date()
        let eventDictionary = try! navigationRerouteEvent(eventType: FasterRouteFoundEvent).asDictionary()
        
        sessionState.lastRerouteDate = timestamp
        
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
    @objc public func recordFeedback(type: FeedbackType = .general, description: String? = nil) -> UUID {
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
    
    /**
     Set the rating and any comment the user may have about their route. Only used when exiting navigaiton.
     */
    @objc public func setEndOfRoute(rating: Int, comment: String?) {
        endOfRouteStarRating = rating
        endOfRouteComment = comment
    }
}
