import XCTest
import CoreLocation
@testable import TestHelper
import MapboxCoreNavigation
@testable @_spi(MapboxInternal) import MapboxCoreNavigation

final class NavigationCommonEventsManagerSpy: NavigationCommonEventsManager {
    var createFeedbackCalled = false
    var sendActiveNavigationFeedbackCalled = false
    var sendPassiveNavigationFeedbackCalled = false
    var sendCarPlayConnectEventCalled = false
    var sendCarPlayDisconnectEventCalled = false

    var passedFeedbackEvent: FeedbackEvent?
    var passedSource: FeedbackSource?
    var passedActiveNavigationType: ActiveNavigationFeedbackType?
    var passedPassiveNavigationType: PassiveNavigationFeedbackType?
    var passedDescription: String?
    var passedCompletionHandler: UserFeedbackCompletionHandler?

    var returnedFeedbackEvent: FeedbackEvent? = Fixture.createFeedbackEvent()

    override func createFeedback(screenshotOption: FeedbackScreenshotOption) -> FeedbackEvent? {
        createFeedbackCalled = true
        return returnedFeedbackEvent
    }

    override func sendActiveNavigationFeedback(_ feedback: FeedbackEvent,
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

    override func sendPassiveNavigationFeedback(_ feedback: FeedbackEvent,
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

    override func sendCarPlayConnectEvent() {
        sendCarPlayConnectEventCalled = true
    }

    override func sendCarPlayDisconnectEvent() {
        sendCarPlayDisconnectEventCalled = true
    }
}

final class NavigationNativeEventsManagerSpy: NavigationNativeEventsManager {
    var createFeedbackCalled = false
    var sendActiveNavigationFeedbackCalled = false
    var sendPassiveNavigationFeedbackCalled = false
    var sendCarPlayConnectEventCalled = false
    var sendCarPlayDisconnectEventCalled = false

    var passedFeedback: FeedbackEvent?
    var passedSource: FeedbackSource?
    var passedActiveNavigationType: ActiveNavigationFeedbackType?
    var passedPassiveNavigationType: PassiveNavigationFeedbackType?
    var passedDescription: String?
    var passedCompletionHandler: UserFeedbackCompletionHandler?
    
    var returnedFeedback: FeedbackEvent? = FeedbackEvent(metadata: .init(userFeedbackHandle: nil, screenshot: nil))

    override func createFeedback(screenshotOption: FeedbackScreenshotOption) -> FeedbackEvent? {
        createFeedbackCalled = true
        return returnedFeedback
    }

    override func sendActiveNavigationFeedback(_ feedback: FeedbackEvent,
                                               type: ActiveNavigationFeedbackType,
                                               description: String?,
                                               source: FeedbackSource,
                                               completionHandler: UserFeedbackCompletionHandler?) {
        sendActiveNavigationFeedbackCalled = true
        passedFeedback = feedback
        passedActiveNavigationType = type
        passedDescription = description
        passedSource = source
        passedCompletionHandler = completionHandler
    }

    override func sendPassiveNavigationFeedback(_ feedback: FeedbackEvent,
                                                type: PassiveNavigationFeedbackType,
                                                description: String?,
                                                source: FeedbackSource,
                                                completionHandler: UserFeedbackCompletionHandler?) {
        sendPassiveNavigationFeedbackCalled = true
        passedFeedback = feedback
        passedPassiveNavigationType = type
        passedDescription = description
        passedSource = source
        passedCompletionHandler = completionHandler
    }

    override func sendCarPlayConnectEvent() {
        sendCarPlayConnectEventCalled = true
    }

    override func sendCarPlayDisconnectEvent() {
        sendCarPlayDisconnectEventCalled = true
    }
}

class NavigationEventsManagerTests: TestCase {
    private var eventManager: NavigationEventsManager!
    private var activeNavigationDataSource: ActiveNavigationEventsManagerDataSourceSpy!
    private var passiveNavigationDataSource: PassiveNavigationEventsManagerDataSourceSpy!
    private var feedbackEvent: FeedbackEvent!

    private var navNativeEventsManager: NavigationNativeEventsManagerSpy? {
        eventManager.navNativeEventsManager as? NavigationNativeEventsManagerSpy
    }
    
    private var commonEventsManager: NavigationCommonEventsManagerSpy? {
        eventManager.commonEventsManager as? NavigationCommonEventsManagerSpy
    }

    override func setUp() {
        super.setUp()

        feedbackEvent = Fixture.createFeedbackEvent()
        activeNavigationDataSource = ActiveNavigationEventsManagerDataSourceSpy()
        passiveNavigationDataSource = PassiveNavigationEventsManagerDataSourceSpy()
    }

    override func tearDown() {
        super.tearDown()
        eventManager = nil
        NavigationTelemetryConfiguration.useNavNativeTelemetryEvents = false
    }

    func configureEventsManager(useNavNative: Bool) {
        NavigationTelemetryConfiguration.useNavNativeTelemetryEvents = useNavNative
        eventManager = NavigationEventsManager(activeNavigationDataSource: activeNavigationDataSource,
                                               passiveNavigationDataSource: passiveNavigationDataSource,
                                               accessToken: "fake",
                                               commonEventsManagerType: NavigationCommonEventsManagerSpy.self,
                                               navNativeEventsManagerType: NavigationNativeEventsManagerSpy.self)
    }

    func testCreateCommonManager() {
        configureEventsManager(useNavNative: false)
        XCTAssertNotNil(commonEventsManager)
        XCTAssertNil(navNativeEventsManager)
    }

    func testCreateNavNativeManager() {
        configureEventsManager(useNavNative: true)
        XCTAssertNil(commonEventsManager)
        XCTAssertNotNil(navNativeEventsManager)
    }

    func testSendCarPlayConnectEventIfDefault() {
        configureEventsManager(useNavNative: false)
        eventManager.sendCarPlayConnectEvent()
        XCTAssertEqual(commonEventsManager?.sendCarPlayConnectEventCalled, true)
    }

    func testSendCarPlayConnectEventIfNavNative() {
        configureEventsManager(useNavNative: true)
        eventManager.sendCarPlayConnectEvent()
        XCTAssertEqual(navNativeEventsManager?.sendCarPlayConnectEventCalled, true)
    }

    func testSendCarPlayDisconnectEventIfDefault() {
        configureEventsManager(useNavNative: false)
        eventManager.sendCarPlayDisconnectEvent()
        XCTAssertEqual(commonEventsManager?.sendCarPlayDisconnectEventCalled, true)
    }

    func testSendCarPlayDisconnectEventIfNavNative() {
        configureEventsManager(useNavNative: true)
        eventManager.sendCarPlayDisconnectEvent()
        XCTAssertEqual(navNativeEventsManager?.sendCarPlayDisconnectEventCalled, true)
    }

    func testSendActiveNavigationFeedbackIfDefault() {
        configureEventsManager(useNavNative: false)
        eventManager.sendActiveNavigationFeedback(feedbackEvent, type: .positioning, description: "description")
        XCTAssertEqual(commonEventsManager?.sendActiveNavigationFeedbackCalled, true)
    }

    func testSendActiveNavigationFeedbackIfNavNative() {
        configureEventsManager(useNavNative: true)
        eventManager.sendActiveNavigationFeedback(feedbackEvent, type: .positioning, description: "description")
        XCTAssertEqual(navNativeEventsManager?.sendActiveNavigationFeedbackCalled, true)
    }

    func testSendPassiveNavigationFeedbackIfDefault() {
        configureEventsManager(useNavNative: false)
        eventManager.sendPassiveNavigationFeedback(feedbackEvent, type: .badGPS, description: "description")
        XCTAssertEqual(commonEventsManager?.sendPassiveNavigationFeedbackCalled, true)
    }

    func testSendPassiveNavigationFeedbackIfNavNative() {
        configureEventsManager(useNavNative: true)
        eventManager.sendPassiveNavigationFeedback(feedbackEvent, type: .badGPS, description: "description")
        XCTAssertEqual(navNativeEventsManager?.sendPassiveNavigationFeedbackCalled, true)
    }

    func testCreateFeedbackIfCommon() {
        configureEventsManager(useNavNative: false)
        let event = eventManager.createFeedback()
        XCTAssertEqual(commonEventsManager?.createFeedbackCalled, true)
        XCTAssertNotNil(event)
    }

    func testCreateFeedbackIfNavNative() {
        configureEventsManager(useNavNative: true)
        let event = eventManager.createFeedback()
        XCTAssertEqual(navNativeEventsManager?.createFeedbackCalled, true)
        XCTAssertNotNil(event)
    }
}
