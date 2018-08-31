import XCTest
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections

#if canImport(CarPlay)
import CarPlay
@testable import MapboxMobileEvents

// For some reason XCTest bundles ignore @available annotations, and this gets run on iOS < 12 :(
// This is a bug in XCTest which will hopefully get fixed in an upcoming release.
// My radar/bug report was marked as a duplicate of another issue with a very low issue ID :(

@available(iOS 12.0, *)
class CarPlayManagerTests: XCTestCase {

    var manager: CarPlayManager?
    
    let eventsManagerSpy = MMEEventsManagerSpy()
    
    lazy var eventsManager: EventsManager = {
        return EventsManager(accessToken: "nonsense")
    }()

    override func setUp() {
        manager = CarPlayManager.shared
        manager?.eventsManager = EventsManager(accessToken: "nonsense")
        eventsManagerSpy.reset()
    }

    override func tearDown() {
        manager = nil
        CarPlayManager.resetSharedInstance()
    }

    func simulateCarPlayConnection() {
        let fakeInterfaceController = FakeCPInterfaceController(#function)
        let fakeWindow = CPWindow()
        
        manager?.application(UIApplication.shared, didConnectCarInterfaceController: fakeInterfaceController, to: fakeWindow)
    }
    
    func simulateCarPlayDisconnection() {
        let fakeInterfaceController = FakeCPInterfaceController(#function)
        let fakeWindow = CPWindow()
        
        manager?.application(UIApplication.shared, didDisconnectCarInterfaceController: fakeInterfaceController, from: fakeWindow)
    }
    
    func testCarPlayConnectedToDevice() {
        guard #available(iOS 12, *) else { return }
        
        manager?.eventsManager.manager = eventsManagerSpy
        
        simulateCarPlayConnection()
        
        let expectedEventName = MMEventTypeCarplayConnect
        XCTAssertTrue(eventsManagerSpy.hasEnqueuedEvent(with: expectedEventName))
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: expectedEventName))
        XCTAssertEqual(eventsManagerSpy.enqueuedEventCount(with: expectedEventName), 1)
        XCTAssertEqual(eventsManagerSpy.enqueuedEventCount(with: expectedEventName), 1)
    }
    
    func testCarPlayDisconnectedFromDevice() {
        guard #available(iOS 12, *) else { return }
        
        manager?.eventsManager.manager = eventsManagerSpy
        
        simulateCarPlayDisconnection()
        
        let expectedEventName = MMEventTypeCarplayDisconnect
        XCTAssertTrue(eventsManagerSpy.hasEnqueuedEvent(with: expectedEventName))
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: expectedEventName))
    }

    // MARK: Upon connecting to CarPlay, window and interfaceController should be set up correctly
    // By default we should supply a search template with the Mapbox Geocoder hooked up (?)
    // we should also provide developers the opportunity to supply their own Favorites &/or History list.
    // We may wish to supply example implementations of these once we've rounded out the basic experience.

//    @available(iOS 12.0, *)
    func testWindowAndIntefaceControllerAreSetUpWithSearchAndExampleFavoritesWhenConnected() {
        // This line results in a warning, but is necessary as XCTest ignores the enclosing @available directive.
        // Not sure how to suppress the generated warning here, but this is currently needed for backwards compatibility
        guard #available(iOS 12, *) else { return }

        simulateCarPlayConnection()

        guard let fakeWindow = manager?.carWindow, let fakeInterfaceController = manager?.interfaceController else {
            XCTFail("Dependencies not met! Bailing...")
            return
        }

        let view = fakeWindow.rootViewController?.view
        XCTAssert((view?.isKind(of: NavigationMapView.self))!, "CarPlay window's root view should be a map view")

        let template: CPMapTemplate = fakeInterfaceController.rootTemplate as! CPMapTemplate
        XCTAssertEqual(1, template.leadingNavigationBarButtons.count)
        XCTAssertEqual(1, template.trailingNavigationBarButtons.count)

        // simulate tap by invoking stored copy of handler
        let searchButton = template.leadingNavigationBarButtons.first!
        searchButton.handler!(searchButton)

        XCTAssert(fakeInterfaceController.topTemplate?.isKind(of: CPSearchTemplate.self) ?? false, "Expecting a search template to be on top")

        fakeInterfaceController.popTemplate(animated: false)

        let favoritesListButton = template.trailingNavigationBarButtons.last!
        favoritesListButton.handler!(favoritesListButton)

        XCTAssert(fakeInterfaceController.topTemplate?.isKind(of: CPListTemplate.self) ?? false, "Expecting a list template to be on top")
    }

    func testManagerAsksDelegateForLeadingAndTrailingBarButtonsIfAvailable() {
        guard #available(iOS 12, *) else { return }

        let exampleDelegate = TestCarPlayManagerDelegate()
        exampleDelegate.leadingBarButtons = [CPBarButton(type: .text), CPBarButton(type: .text)]
        exampleDelegate.trailingBarButtons = [CPBarButton(type: .image), CPBarButton(type: .image)]

        manager?.delegate = exampleDelegate

        simulateCarPlayConnection()

        guard let fakeInterfaceController = manager?.interfaceController else {
            XCTFail("Dependencies not met! Bailing...")
            return
        }

        let mapTemplate: CPMapTemplate = fakeInterfaceController.rootTemplate as! CPMapTemplate
        XCTAssertEqual(2, mapTemplate.leadingNavigationBarButtons.count)
        XCTAssertEqual(2, mapTemplate.trailingNavigationBarButtons.count)
    }
    
    func testManagerAsksDelegateForMapButtonsIfAvailable() {
        guard #available(iOS 12, *) else { return }
        
        let exampleDelegate = TestCarPlayManagerDelegate()
        exampleDelegate.mapButtons = [CPMapButton()]
        
        manager?.delegate = exampleDelegate
        
        simulateCarPlayConnection()
        
        guard let fakeInterfaceController = manager?.interfaceController else {
            XCTFail("Dependencies not met! Bailing...")
            return
        }
        
        let mapTemplate: CPMapTemplate = fakeInterfaceController.rootTemplate as! CPMapTemplate
        XCTAssertEqual(1, mapTemplate.mapButtons.count)
    }

    func testManagerTellsDelegateWhenGuidanceIsInitiated() {
        guard #available(iOS 12, *) else { return }

        let exampleDelegate = TestCarPlayManagerDelegate()
        manager?.delegate = exampleDelegate

        simulateCarPlayConnection()

        guard let fakeInterfaceController = manager?.interfaceController else {
            XCTFail("Dependencies not met! Bailing...")
            return
        }

        let mapTemplate: CPMapTemplate = fakeInterfaceController.rootTemplate as! CPMapTemplate

        // given the user is previewing route choices
        // when a trip is started using one of the route choices
        let choice = CPRouteChoice(summaryVariants: ["summary1"], additionalInformationVariants: ["addl1"], selectionSummaryVariants: ["selection1"])
        choice.userInfo = Fixture.routeWithBannerInstructions()

        manager?.mapTemplate(mapTemplate, startedTrip: CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [choice]), using: choice)

        // trip previews are hidden on the mapTemplate
        // the delegate is given the opportunity to provide a custom route controller
        // a navigation session is started on the mapTemplate
        // a CarPlayNavigationViewController is presented (why?)

        // the CarPlayNavigationDelegate is notified
        XCTAssertTrue(exampleDelegate.navigationInitiated, "The CarPlayManagerDelegate should have been told that navigation was initiated.")
    }

    //MARK: Upon disconnecting CarPlay, cleanup happens

    // when a list item that corresponds to a waypoint/location is tapped
    // route options are constructed from the user's location to the final waypoint
    // a route is requested
    // an error is displayed if encountered
    // route choices / trip previews displayed
    // await user input

    // CarPlay handles switching between route choices automatically?

}

//MARK: Test Objects / Classes.
//TODO: Extract into separate file at some point.

@available(iOS 12.0, *)
class TestCarPlayManagerDelegate: CarPlayManagerDelegate {

    var navigationInitiated = false
    var leadingBarButtons: [CPBarButton]?
    var trailingBarButtons: [CPBarButton]?
    var mapButtons: [CPMapButton]?

    func carPlayManager(_ carPlayManager: CarPlayManager, leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate) -> [CPBarButton]? {
        return leadingBarButtons
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate) -> [CPBarButton]? {
        return trailingBarButtons
    }
    
    func carPlayManager(_ carplayManager: CarPlayManager, mapButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate) -> [CPMapButton]? {
        return mapButtons
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith progress: RouteProgress) {
        navigationInitiated = true
    }
    
    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
        
    }
}

@available(iOS 12.0, *)
class FakeCPInterfaceController: CPInterfaceController {

    /**
     * A simple stub which allows for instantiation of a CPInterfaceController for testing.
     * CPInterfaceController cannot be instantiated directly.
     */
    init(_ context: String) {
        self.context = context
    }

    let context: String
    var templateStack: [CPTemplate] = []

    override var debugDescription: String {
        return "CPInterfaceControllerSpy for \(context)"
    }

    // MARK - CPInterfaceController declarations and overrides

    //Uncomment and override as needed, if needed. At first inspection, some of these result in semaphore_wait_trap when invoked on an instance of CPInterfaceControllerSpy, but `rootTemplate` works as expected once set

    //TODO: solve for this duplication with introspection, à la Cedar::Doubles

//    weak open var delegate: CPInterfaceControllerDelegate?
//    open func setRootTemplate(_ rootTemplate: CPTemplate, animated: Bool)

    override open func pushTemplate(_ templateToPush: CPTemplate, animated: Bool) {
        templateStack.append(templateToPush)
    }

    override open func popTemplate(animated: Bool) {
        templateStack.removeLast()
    }

//    open func popToRootTemplate(animated: Bool)
//    open func pop(to targetTemplate: CPTemplate, animated: Bool)
//    open func presentTemplate(_ templateToPresent: CPTemplate, animated: Bool)
//    open func dismissTemplate(animated: Bool)
//    open var presentedTemplate: CPTemplate? { get }
//    open var rootTemplate: CPTemplate { get }

    override open var topTemplate: CPTemplate? {
        get {
            return templateStack.last
        }
    }

    override open var templates: [CPTemplate] {
        get {
            return templateStack
        }
    }
}
#endif
