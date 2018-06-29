import Foundation
import CoreLocation
import MapboxDirections
import MapboxMobileEvents

protocol Routable: class {
    
    init(along route: Route, directions: Directions, locationManager: NavigationLocationManager, eventsManager: MMEEventsManager)
    
    var eventsManager: MMEEventsManager { get set }
    
    var usesDefaultUserInterface: Bool { get set }
    
    var outstandingFeedbackEvents: [CoreFeedbackEvent] { get set }
    
    var locationManager: NavigationLocationManager { get set }
    
    var routeProgress: RouteProgress { get set }
    
    var sessionState: SessionState { get set }
    
    /**
     When set to `false`, flushing of telemetry events is not delayed. Is set to `true` by default.
     */
    var delaysEventFlushing: Bool { get set }
}

// MARK: - Telemetry
extension Routable {
    
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
            eventsManager.isDebugLoggingEnabled = eventLoggingEnabled
            eventsManager.isMetricsEnabledInSimulator = true
            eventsManager.isMetricsEnabledForInUsePermissions = true
            let userAgent = usesDefaultUserInterface ? "mapbox-navigation-ui-ios" : "mapbox-navigation-ios"
            eventsManager.initialize(withAccessToken: mapboxAccessToken, userAgentBase: userAgent, hostSDKVersion: String(describing: Bundle(for: RouteController.self).object(forInfoDictionaryKey: "CFBundleShortVersionString")!))
            eventsManager.disableLocationMetrics()
            eventsManager.sendTurnstileEvent()
        } else {
            assert(false, "`accessToken` must be set in the Info.plist as `MGLMapboxAccessToken` or the `Route` passed into the `RouteController` must have the `accessToken` property set.")
        }
    }
    
    // MARK: Sending events
    func sendDepartEvent() {
        eventsManager.enqueueEvent(withName: MMEEventTypeNavigationDepart, attributes: eventsManager.navigationDepartEvent(routeController: self))
        eventsManager.flush()
    }
    
    func sendArriveEvent() {
        eventsManager.enqueueEvent(withName: MMEEventTypeNavigationArrive, attributes: eventsManager.navigationArriveEvent(routeController: self))
        eventsManager.flush()
    }
    
    func sendCancelEvent(rating: Int? = nil, comment: String? = nil) {
        let attributes = eventsManager.navigationCancelEvent(routeController: self, rating: rating, comment: comment)
        eventsManager.enqueueEvent(withName: MMEEventTypeNavigationCancel, attributes: attributes)
        eventsManager.flush()
    }
    
    
    func sendFeedbackEvents(_ events: [CoreFeedbackEvent]) {
        events.forEach { event in
            // remove from outstanding event queue
            if let index = outstandingFeedbackEvents.index(of: event) {
                outstandingFeedbackEvents.remove(at: index)
            }
            
            let eventName = event.eventDictionary["event"] as! String
            let eventDictionary = eventsManager.navigationFeedbackEventWithLocationsAdded(event: event, routeController: self)
            
            eventsManager.enqueueEvent(withName: eventName, attributes: eventDictionary)
        }
        eventsManager.flush()
    }
    
    // MARK: Enqueue feedback
    
    func enqueueFeedbackEvent(type: FeedbackType, description: String?) -> UUID {
        let eventDictionary = eventsManager.navigationFeedbackEvent(routeController: self, type: type, description: description)
        let event = FeedbackEvent(timestamp: Date(), eventDictionary: eventDictionary)
        
        outstandingFeedbackEvents.append(event)
        
        return event.id
    }
    
    func enqueueRerouteEvent() -> String {
        let timestamp = Date()
        let eventDictionary = eventsManager.navigationRerouteEvent(routeController: self)
        
        sessionState.lastRerouteDate = timestamp
        sessionState.numberOfReroutes += 1
        
        let event = RerouteEvent(timestamp: Date(), eventDictionary: eventDictionary)
        
        outstandingFeedbackEvents.append(event)
        
        return event.id.uuidString
    }
    
    func enqueueFoundFasterRouteEvent() -> String {
        let timestamp = Date()
        let eventDictionary = eventsManager.navigationRerouteEvent(routeController: self, eventType: FasterRouteFoundEvent)
        
        sessionState.lastRerouteDate = timestamp
        
        let event = RerouteEvent(timestamp: Date(), eventDictionary: eventDictionary)
        
        outstandingFeedbackEvents.append(event)
        
        return event.id.uuidString
    }
    
    func shouldDelayEvents() -> Bool {
        return delaysEventFlushing
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
    
    func resetSession() {
        sessionState = SessionState(currentRoute: routeProgress.route, originalRoute: routeProgress.route)
    }
}

