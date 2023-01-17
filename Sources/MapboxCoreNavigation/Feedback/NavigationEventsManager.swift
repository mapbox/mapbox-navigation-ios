import Foundation
import CoreLocation
import UIKit
import MapboxMobileEvents
import MapboxDirections
@_implementationOnly import MapboxCommon_Private

private let secondsBeforeCollectionAfterFeedbackEvent: TimeInterval = 20

/**
 A data source that declares values required for recording passive location events.
 */
public protocol PassiveNavigationEventsManagerDataSource: AnyObject {
    var rawLocation: CLLocation? { get }
    var locationManagerType: NavigationLocationManager.Type { get }
}

extension PassiveLocationManager: PassiveNavigationEventsManagerDataSource {
    public var locationManagerType: NavigationLocationManager.Type {
        return type(of: systemLocationManager)
    }
}

/**
 The `ActiveNavigationEventsManagerDataSource` protocol declares values required for recording route following events.
 */
public protocol ActiveNavigationEventsManagerDataSource: AnyObject {
    var routeProgress: RouteProgress { get }
    var router: Router { get }
    var desiredAccuracy: CLLocationAccuracy { get }
    var locationManagerType: NavigationLocationManager.Type { get }
}

/**
 The `NavigationEventsManager` is responsible for being the liaison between MapboxCoreNavigation and the Mapbox telemetry framework.
 */
open class NavigationEventsManager {
    static let applicationSessionIdentifier = UUID()
    
    // MARK: Configuring Events
    
    /**
     Optional application metadata that that can help Mapbox more reliably diagnose problems that occur in the SDK.
     For example, you can provide your application’s name and version, a unique identifier for the end user, and a session identifier.
     To include this information, use the following keys: "name", "version", "userId", and "sessionId".
    */
    public var userInfo: [String: String?]? = nil
    
    /**
     When set to `false`, flushing of telemetry events is not delayed. Is set to `true` by default.
     */
    public var delaysEventFlushing = true
    
    // MARK: Storing Data and Datasources
    
    private var sessionState = SessionState()

    /**
     The unique identifier of the navigation session used for events.
     */
    public var sessionId: String {
        sessionState.identifier.uuidString
    }
    
    var outstandingFeedbackEvents = [CoreFeedbackEvent]()
    
    func withBackupDataSource(active forcedActiveDataSource: ActiveNavigationEventsManagerDataSource?,
                              passive forcedPassiveDataSource: PassiveNavigationEventsManagerDataSource?,
                              action: () -> Void) {
        backupActiveDataSource = forcedActiveDataSource
        backupPassiveDataSource = forcedPassiveDataSource
        action()
        backupActiveDataSource = nil
        backupPassiveDataSource = nil
    }

    private var backupPassiveDataSource: PassiveNavigationEventsManagerDataSource?
    private weak var _passiveNavigationDataSource: PassiveNavigationEventsManagerDataSource?
    private var passiveNavigationDataSource: PassiveNavigationEventsManagerDataSource? {
        get {
            return _passiveNavigationDataSource ?? backupPassiveDataSource
        }
        set {
            _passiveNavigationDataSource = newValue
        }
    }

    private var backupActiveDataSource: ActiveNavigationEventsManagerDataSource?
    private weak var _activeNavigationDataSource: ActiveNavigationEventsManagerDataSource?
    var activeNavigationDataSource: ActiveNavigationEventsManagerDataSource? {
        get {
            return _activeNavigationDataSource ?? backupActiveDataSource
        }
        set {
            _activeNavigationDataSource = newValue
        }
    }

    private let eventsAPI: EventsAPI
    private let telemetryService: TelemetryService

    private let accessToken: String

    @available(*, deprecated, renamed: "init(activeNavigationDataSource:passiveNavigationDataSource:accessToken:)")
    public convenience init(activeNavigationDataSource: ActiveNavigationEventsManagerDataSource? = nil,
                         passiveNavigationDataSource: PassiveNavigationEventsManagerDataSource? = nil,
                         accessToken possibleToken: String? = nil,
                         mobileEventsManager: MMEEventsManager = .shared()) {
        mobileEventsManager.disableLocationMetrics()
        self.init(activeNavigationDataSource: activeNavigationDataSource, passiveNavigationDataSource: passiveNavigationDataSource, accessToken: possibleToken)
    }

    public required init(activeNavigationDataSource: ActiveNavigationEventsManagerDataSource? = nil,
                         passiveNavigationDataSource: PassiveNavigationEventsManagerDataSource? = nil,
                         accessToken possibleToken: String? = nil) {
        accessToken = possibleToken ?? NavigationEventsManager.obtainAccessToken()

        let options = NavigationEventsManager.createEventsServerOptions(accessToken: accessToken)
        self.eventsAPI = EventsService.getOrCreate(for: options)
        self.telemetryService = TelemetryService.getOrCreate(for: options)

        commonInit(activeNavigationDataSource: activeNavigationDataSource,
                   passiveNavigationDataSource: passiveNavigationDataSource)
    }

    init(activeNavigationDataSource: ActiveNavigationEventsManagerDataSource? = nil,
         passiveNavigationDataSource: PassiveNavigationEventsManagerDataSource? = nil,
         accessToken possibleToken: String? = nil,
         eventsAPI: EventsAPI) {
        accessToken = possibleToken ?? NavigationEventsManager.obtainAccessToken()

        let options = NavigationEventsManager.createEventsServerOptions(accessToken: accessToken)
        self.eventsAPI = eventsAPI
        self.telemetryService = TelemetryService.getOrCreate(for: options)

        commonInit(activeNavigationDataSource: activeNavigationDataSource,
                   passiveNavigationDataSource: passiveNavigationDataSource)
    }

    private func commonInit(activeNavigationDataSource: ActiveNavigationEventsManagerDataSource?,
                            passiveNavigationDataSource: PassiveNavigationEventsManagerDataSource?) {
        self.activeNavigationDataSource = activeNavigationDataSource
        self.passiveNavigationDataSource = passiveNavigationDataSource

        start()
        resumeNotifications()
    }

    private static func obtainAccessToken() -> String {
        guard let token = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String ??
                Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAccessToken") as? String
        else {
            //we can assert here because if the token was passed in, it would of overriden this closure.
            //we return an empty string so we don't crash in production (in keeping with behavior of `assert`)
            assertionFailure("`accessToken` must be set in the Info.plist as `MBXAccessToken` or the `Route` passed into the `NavigationService` must have the `accessToken` property set.")
            return ""
        }
        return token
    }

    private static func createEventsServerOptions(accessToken: String) -> EventsServerOptions {
        EventsServerOptions(token: accessToken, userAgentFragment: NavigationEventsManager.userAgent, deferredDeliveryServiceOptions: nil)
    }

    private static var userAgent: String = {
        Bundle.usesDefaultUserInterface ? "mapbox-navigation-ui-ios" : "mapbox-navigation-ios"
    }()
    
    deinit {
        suspendNotifications()
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

    private func eventAttributes(type: EventType, date: Date = Date()) -> [String : Any] {
        return [EventKey.event.rawValue: type.rawValue, EventKey.created.rawValue: date.ISO8601]
    }

    func start() {
        let shortVersion = Bundle.navigationSDKVersion
        eventsAPI.sendTurnstileEvent(sdkIdentifier: NavigationEventsManager.userAgent, sdkVersion: shortVersion)
    }
    
    // MARK: Sending Feedback Events
    
    /**
     Create feedback about the current road segment/maneuver to be sent to the Mapbox data team.
     
     You can pair this with a custom feedback UI in your app to flag problems during navigation such as road closures, incorrect instructions, etc.
     
     - returns: Returns a feedback event.
     
     If you provide a custom feedback UI that lets users elaborate on an issue, you should call this before you show the custom UI so the location and timestamp are more accurate.
     Alternatively, you can use `FeedbackViewContoller` which handles feedback lifecycle internally.
     
     - Postcondition:
     Call `sendFeedback(_:type:source:description:)` with the returned feedback to attach additional metadata to the feedback and send it.
     */
    public func createFeedback(screenshotOption: FeedbackScreenshotOption = .automatic) -> FeedbackEvent? {
        guard let eventDetails = navigationFeedbackEvent(screenshotOption: screenshotOption) else { return nil }
        return FeedbackEvent(eventDetails: eventDetails)
    }
    
    /**
     Send active navigation feedback to the Mapbox data team.
     
     You can pair this with a custom feedback UI in your app to flag problems during navigation such as road closures, incorrect instructions, etc.
     
     - parameter feedback: A `FeedbackEvent` created with `createFeedback()` method.
     - parameter type: A `ActiveNavigationFeedbackType` used to specify the type of feedback.
     - parameter description: A custom string used to describe the problem in detail.
     */
    public func sendActiveNavigationFeedback(_ feedback: FeedbackEvent, type: ActiveNavigationFeedbackType, description: String? = nil) {
        feedback.update(with: type, description: description)
        sendFeedbackEvents([feedback.coreEvent])
    }
    
    /**
     Send passive navigation feedback to the Mapbox data team.
     
     You can pair this with a custom feedback UI in your app to flag problems during navigation such as road closures, incorrect instructions, etc.
     
     - parameter feedback: A `FeedbackEvent` created with `createFeedback()` method.
     - parameter type: A `PassiveNavigationFeedbackType` used to specify the type of feedback.
     - parameter description: A custom string used to describe the problem in detail.
     */
    public func sendPassiveNavigationFeedback(_ feedback: FeedbackEvent,
                                              type: PassiveNavigationFeedbackType,
                                              description: String? = nil) {
        feedback.update(with: type, description: description)
        sendFeedbackEvents([feedback.coreEvent])
    }
    
    func navigationCancelEvent(rating potentialRating: Int? = nil, comment: String? = nil) -> ActiveNavigationEventDetails? {
        guard let dataSource = activeNavigationDataSource else { return nil }
        
        let rating = potentialRating ?? EventRating.unrated
        var event = ActiveNavigationEventDetails(dataSource: dataSource, session: sessionState, defaultInterface: Bundle.usesDefaultUserInterface, appMetadata: userInfo)
        event.event = EventType.cancel.rawValue
        event.arrivalTimestamp = sessionState.arrivalTimestamp
        
        let validRating: Bool = (rating >= EventRating.unrated && rating <= EventRating.topRated)
        assert(validRating, "MMEEventsManager: Invalid Rating. Values should be between \(EventRating.unrated) (none) and 100.")
        guard validRating else { return event }
        
        event.rating = rating
        event.comment = comment
        
        return event
    }
    
    func navigationRouteRetrievalEvent() -> PerformanceEventDetails? {
        guard let responseEndDate = sessionState.currentRoute?.responseEndDate,
            let fetchStartDate = sessionState.currentRoute?.fetchStartDate else {
            return nil
        }

        var event = PerformanceEventDetails(event: EventType.routeRetrieval.rawValue, session: sessionState, createdOn: sessionState.currentRoute?.responseEndDate, appMetadata: userInfo)
        event.counters.append(PerformanceEventDetails.Counter(name: "elapsed_time",
                                                              value: responseEndDate.timeIntervalSince(fetchStartDate)))

        if let routeIdentifier = sessionState.routeIdentifier {
            event.attributes.append(PerformanceEventDetails.Attribute(name: "route_uuid", value: routeIdentifier))
        }
        return event
    }
    
    func navigationDepartEvent() -> ActiveNavigationEventDetails? {
        guard let dataSource = activeNavigationDataSource else { return nil }

        var event = ActiveNavigationEventDetails(dataSource: dataSource, session: sessionState, defaultInterface: Bundle.usesDefaultUserInterface, appMetadata: userInfo)
        event.event = EventType.depart.rawValue
        return event
    }
    
    func navigationArriveEvent() -> ActiveNavigationEventDetails? {
        guard let dataSource = activeNavigationDataSource else { return nil }

        var event = ActiveNavigationEventDetails(dataSource: dataSource, session: sessionState, defaultInterface: Bundle.usesDefaultUserInterface, appMetadata: userInfo)
        event.event = EventType.arrive.rawValue
        event.arrivalTimestamp = dataSource.router.rawLocation?.timestamp ?? Date()

        return event
    }

    func passiveNavigationEvent(type: FreeDriveEventDetails.EventType) -> FreeDriveEventDetails? {
        guard let dataSource = passiveNavigationDataSource else { return nil }

        var event = FreeDriveEventDetails(type: type, dataSource: dataSource, sessionState: sessionState, appMetadata: userInfo)
        event.event = EventType.freeDrive.rawValue

        return event
    }
    
    func navigationFeedbackEventWithLocationsAdded(event: CoreFeedbackEvent) -> [String: Any] {
        var eventDictionary = event.eventDictionary
        eventDictionary[EventKey.feedbackId.rawValue] = event.identifier.uuidString
        eventDictionary[EventKey.locationsBefore.rawValue] = sessionState.pastLocations.allObjects
            .filter { $0.timestamp <= event.timestamp }
            .map { EventLocation($0).dictionaryRepresentation }
        eventDictionary[EventKey.locationsAfter.rawValue] = sessionState.pastLocations.allObjects
            .filter { $0.timestamp > event.timestamp }
            .map { EventLocation($0).dictionaryRepresentation }
        return eventDictionary
    }
    
    func navigationFeedbackEvent(screenshotOption: FeedbackScreenshotOption) -> NavigationEventDetails? {
        var event: NavigationEventDetails
    
        if let activeNavigationDataSource = activeNavigationDataSource {
            event = ActiveNavigationEventDetails(dataSource: activeNavigationDataSource, session: sessionState, defaultInterface: Bundle.usesDefaultUserInterface, appMetadata: userInfo)
        } else if let passiveNavigationDataSource = passiveNavigationDataSource {
            event = PassiveNavigationEventDetails(dataSource: passiveNavigationDataSource, sessionState: sessionState, appMetadata: userInfo)
        } else {
            assertionFailure("NavigationEventsManager is unable to create feedbacks without a datasource.")
            return nil
        }
        
        event.userIdentifier = UIDevice.current.identifierForVendor?.uuidString
        event.event = EventType.feedback.rawValue
        
        let screenshot: UIImage?
        switch screenshotOption {
        case .automatic:
            screenshot = captureScreen(scaledToFit: 250)
        case .custom(let customScreenshot):
            screenshot = customScreenshot
        }
        event.screenshot = screenshot?.jpegData(compressionQuality: 0.2)?.base64EncodedString()
        
        return event
    }
    
    func navigationRerouteEvent(eventType: String = EventType.reroute.rawValue) -> ActiveNavigationEventDetails? {
        guard let dataSource = activeNavigationDataSource else { return nil }

        let timestamp = dataSource.router.rawLocation?.timestamp ?? Date()
        
        var event = ActiveNavigationEventDetails(dataSource: dataSource, session: sessionState, defaultInterface: Bundle.usesDefaultUserInterface, appMetadata: userInfo)
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
        event.screenshot = captureScreen(scaledToFit: 250)?.jpegData(compressionQuality: 0.2)?.base64EncodedString()
        
        return event
    }

    public func sendCarPlayConnectEvent() {
        let attributes = eventAttributes(type: .carplayConnect)
        sendEvent(with: attributes)
    }

    public func sendCarPlayDisconnectEvent() {
        let attributes = eventAttributes(type: .carplayDisconnect)
        sendEvent(with: attributes)
    }
    
    func sendRouteRetrievalEvent() {
        guard let attributes = try? navigationRouteRetrievalEvent()?.asDictionary() else { return }
        sendEvent(with: attributes)
    }

    func sendDepartEvent() {
        guard let attributes = try? navigationDepartEvent()?.asDictionary() else { return }
        sendEvent(with: attributes)
    }
    
    func sendArriveEvent() {
        guard let attributes = try? navigationArriveEvent()?.asDictionary() else { return }
        sendEvent(with: attributes)
    }
    
    func sendCancelEvent(rating: Int? = nil, comment: String? = nil) {
        guard let attributes = try? navigationCancelEvent(rating: rating, comment: comment)?.asDictionary() else { return }
        sendEvent(with: attributes)
    }

    func sendPassiveNavigationStart() {
        guard let dataSource = passiveNavigationDataSource else { return }
        if sessionState.departureTimestamp == nil {
            sessionState.departureTimestamp = dataSource.rawLocation?.timestamp ?? Date()
        }

        guard let attributes = try? passiveNavigationEvent(type: .start)?.asDictionary() else { return }
        sendEvent(with: attributes)
    }

    func sendPassiveNavigationStop() {
        guard let attributes = try? passiveNavigationEvent(type: .stop)?.asDictionary() else { return }
        sendEvent(with: attributes)
    }
    
    func sendFeedbackEvents(_ events: [CoreFeedbackEvent]) {
        events.forEach { event in
            // remove from outstanding event queue
            if let index = outstandingFeedbackEvents.firstIndex(of: event) {
                outstandingFeedbackEvents.remove(at: index)
            }
            
            let eventDictionary = navigationFeedbackEventWithLocationsAdded(event: event)
            sendEvent(with: eventDictionary)
        }
    }

    func enqueueRerouteEvent() {
        guard let eventDictionary = try? navigationRerouteEvent()?.asDictionary() else { return }
        let timestamp = activeNavigationDataSource?.router.location?.timestamp ?? Date()
        
        sessionState.lastRerouteDate = timestamp
        sessionState.numberOfReroutes += 1
        
        let event = RerouteEvent(timestamp: timestamp, eventDictionary: eventDictionary)
        
        outstandingFeedbackEvents.append(event)
    }
    
    func resetSession() {
        guard let dataSource = activeNavigationDataSource else { return }

        let route = dataSource.routeProgress.route
        sessionState = SessionState(currentRoute: route, originalRoute: route, routeIdentifier: dataSource.router.indexedRouteResponse.routeResponse.identifier)
    }

    func enqueueFoundFasterRouteEvent() {
        guard let eventDictionary = try? navigationRerouteEvent(eventType: FasterRouteFoundEvent)?.asDictionary() else { return }

        let timestamp = Date()
        sessionState.lastRerouteDate = timestamp
        
        let event = RerouteEvent(timestamp: Date(), eventDictionary: eventDictionary)
        
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
            now.timeIntervalSince($0.timestamp) > secondsBeforeCollectionAfterFeedbackEvent
        }
        return eventsToPush
    }
    
    private func shouldDelayEvents() -> Bool {
        return delaysEventFlushing
    }
    
    //MARK: - Session State Management
    @objc private func didChangeOrientation(_ notification: NSNotification) {
        sessionState.reportChange(to: UIDevice.current.orientation)
    }
    
    @objc private func didChangeApplicationState(_ notification: NSNotification) {
        sessionState.reportChange(to: UIApplication.shared.applicationState)
    }
    
    @objc private func applicationWillTerminate(_ notification: NSNotification) {
        if sessionState.terminated == false {
            sendCancelEvent(rating: nil, comment: nil)
            sessionState.terminated = true
        }
        
        sendOutstandingFeedbackEvents(forceAll: true)
    }
    
    func reportReroute(progress: RouteProgress, proactive: Bool) {
        let route = progress.route
        
        // if the user has already arrived and a new route has been set, restart the navigation session
        if sessionState.arrivalTimestamp != nil {
            resetSession()
        } else {
            sessionState.currentRoute = route
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
        
        if sessionState.arrivalTimestamp == nil,
            progress.currentLegProgress.userHasArrivedAtWaypoint {
            sessionState.arrivalTimestamp = activeNavigationDataSource?.router.location?.timestamp ?? Date()
            sendArriveEvent()
            
            return
        }
        
        if sessionState.departureTimestamp == nil {
            sessionState.departureTimestamp = activeNavigationDataSource?.router.location?.timestamp ?? Date()
            sendDepartEvent()
        }
    }
    
    func incrementDistanceTraveled(by distance: CLLocationDistance) {
        sessionState.totalDistanceCompleted += distance
    }
    
    func arriveAtWaypoint() {
        sessionState.departureTimestamp = nil
        sessionState.arrivalTimestamp = nil
    }
    
    func arriveAtDestination() {
        sessionState.arrivalTimestamp = nil
    }
    
    func record(_ locations: [CLLocation]) {
        locations.forEach(sessionState.pastLocations.push(_:))
    }

    private func sendEvent(with attributes: [String : Any]) {
        if shouldDelayEvents() {
            eventsAPI.sendQueuedEvent(with: attributes)
        } else {
            eventsAPI.sendImmediateEvent(with: attributes)
        }
    }
}
