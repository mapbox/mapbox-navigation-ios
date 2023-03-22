import Foundation
@_spi(MapboxInternal) @testable import MapboxCoreNavigation
#if SWIFT_PACKAGE
import CTestHelper
#endif

public class PassiveNavigationDataSourceSpy: PassiveNavigationEventsManagerDataSource {
    public var rawLocation: CLLocation? = nil
    public var locationManagerType: MapboxCoreNavigation.NavigationLocationManager.Type = NavigationLocationManagerSpy.self
}

public class NavigationEventsManagerSpy: NavigationEventsManager {
    private let passiveNavigationDataSource: PassiveNavigationDataSourceSpy
    
    var debuggableEvents = [NavigationEventDetails]()
    var locations = [CLLocation]()
    var totalDistanceCompleted: CLLocationDistance = 0

    var createFeedbackCalled = false
    var sendActiveNavigationFeedbackCalled = false
    var sendPassiveNavigationFeedbackCalled = false
    var sendCarPlayConnectEventCalled = false
    var sendCarPlayDisconnectEventCalled = false
    var sendRouteRetrievalEventCalled = false
    var sendCancelEventCalled = false
    var sendPassiveNavigationStartCalled = false
    var sendPassiveNavigationStopCalled = false
    var resetSessionCalled = false
    var enqueueRerouteEventCalled = false
    var reportRerouteCalled = false
    var updateProgressCalled = false
    var incrementDistanceTraveledCalled = false
    var arriveAtWaypointCalled = false
    var arriveAtDestinationCalled = false

    var passedFeedbackEvent: FeedbackEvent?
    var passedSource: FeedbackSource?
    var passedActiveNavigationType: ActiveNavigationFeedbackType?
    var passedPassiveNavigationType: PassiveNavigationFeedbackType?
    var passedDescription: String?
    var passedCompletionHandler: UserFeedbackCompletionHandler?
    var passedRating: Int?
    var passedComment: String?

    var returnedFeedbackEvent: FeedbackEvent? = Fixture.createFeedbackEvent()

    required public init() {
        passiveNavigationDataSource = PassiveNavigationDataSourceSpy()
        super.init(activeNavigationDataSource: nil,
                   passiveNavigationDataSource: passiveNavigationDataSource,
                   accessToken: "fake token")
    }

    required convenience init(activeNavigationDataSource: ActiveNavigationEventsManagerDataSource? = nil, passiveNavigationDataSource: PassiveNavigationEventsManagerDataSource? = nil, accessToken possibleToken: String? = nil) {
        self.init()
    }

    func reset() {
        createFeedbackCalled = false
        sendActiveNavigationFeedbackCalled = false
        sendPassiveNavigationFeedbackCalled = false
        sendCarPlayConnectEventCalled = false
        sendCarPlayDisconnectEventCalled = false
        sendRouteRetrievalEventCalled = false
        sendCancelEventCalled = false
        sendPassiveNavigationStartCalled = false
        sendPassiveNavigationStopCalled = false
        resetSessionCalled = false
        enqueueRerouteEventCalled = false
        reportRerouteCalled = false
        updateProgressCalled = false
        incrementDistanceTraveledCalled = false
        arriveAtWaypointCalled = false
        arriveAtDestinationCalled = false
        locations.removeAll()
    }

    public override func createFeedback(screenshotOption: FeedbackScreenshotOption) -> FeedbackEvent? {
        createFeedbackCalled = true
        return returnedFeedbackEvent
    }

    public override func sendActiveNavigationFeedback(_ feedback: FeedbackEvent,
                                                      type: MapboxCoreNavigation.ActiveNavigationFeedbackType,
                                                      description: String?) {
        sendActiveNavigationFeedbackCalled = true
        passedFeedbackEvent = feedback
    }

    public override func sendPassiveNavigationFeedback(_ feedback: FeedbackEvent,
                                                       type: MapboxCoreNavigation.PassiveNavigationFeedbackType,
                                                       description: String?) {
        sendPassiveNavigationFeedbackCalled = true
        passedFeedbackEvent = feedback
    }

    @_spi(MapboxInternal)
    public override func sendActiveNavigationFeedback(_ feedback: FeedbackEvent,
                                                      type: ActiveNavigationFeedbackType,
                                                      description: String?,
                                                      source: FeedbackSource,
                                                      completionHandler: UserFeedbackCompletionHandler?) {
        sendActiveNavigationFeedbackCalled = true
        passedFeedbackEvent = feedback
        passedActiveNavigationType = type
        passedDescription = description
        passedSource = source
        passedCompletionHandler = completionHandler
    }

    @_spi(MapboxInternal)
    public override func sendPassiveNavigationFeedback(_ feedback: FeedbackEvent,
                                                       type: PassiveNavigationFeedbackType,
                                                       description: String?,
                                                       source: FeedbackSource,
                                                       completionHandler: UserFeedbackCompletionHandler?) {
        sendPassiveNavigationFeedbackCalled = true
        passedFeedbackEvent = feedback
        passedPassiveNavigationType = type
        passedDescription = description
        passedSource = source
        passedCompletionHandler = completionHandler
    }

    public override func sendCarPlayConnectEvent() {
        sendCarPlayConnectEventCalled = true
    }

    public override func sendCarPlayDisconnectEvent() {
        sendCarPlayDisconnectEventCalled = true
    }

    public override func record(_ locations: [CLLocation]) {
        self.locations.append(contentsOf: locations)
    }

    public override func enqueueRerouteEvent() {
        enqueueRerouteEventCalled = true
    }

    public override func sendRouteRetrievalEvent() {
        sendRouteRetrievalEventCalled = true
    }

    public override func sendCancelEvent(rating: Int?, comment: String?) {
        sendCancelEventCalled = true
        passedRating = rating
        passedComment = comment
    }

    public override func sendPassiveNavigationStart() {
        sendPassiveNavigationStartCalled = true
    }

    public override func sendPassiveNavigationStop() {
        sendPassiveNavigationStopCalled = true
    }

    public override func resetSession() {
        resetSessionCalled = true
    }

    public override func reportReroute(progress: RouteProgress, proactive: Bool) {
        reportRerouteCalled = true
    }

    public override func update(progress: RouteProgress) {
        updateProgressCalled = true
    }

    public override func incrementDistanceTraveled(by distance: CLLocationDistance) {
        incrementDistanceTraveledCalled = true
        totalDistanceCompleted += distance
    }

    public override func arriveAtWaypoint() {
        arriveAtWaypointCalled = true
    }

    public override func arriveAtDestination() {
        arriveAtDestinationCalled = true
    }

}
