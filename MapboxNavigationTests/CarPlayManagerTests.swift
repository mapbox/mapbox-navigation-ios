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

    var eventsManagerSpy: MMEEventsManagerSpy {
        get {
            return manager!.eventsManager.manager as! MMEEventsManagerSpy
        }
    }

    override func setUp() {
        manager = CarPlayManager.shared
        manager!.eventsManager = TestNavigationEventsManager()
    }

    override func tearDown() {
        manager = nil
        CarPlayManager.resetSharedInstance()
    }

    func simulateCarPlayDisconnection() {
        let fakeInterfaceController = FakeCPInterfaceController(#function)
        let fakeWindow = CPWindow()

        manager!.application(UIApplication.shared, didDisconnectCarInterfaceController: fakeInterfaceController, from: fakeWindow)
    }

    func testEventsEnqueuedAndFlushedWhenCarPlayConnected() {
        guard #available(iOS 12, *) else { return }

        simulateCarPlayConnection(manager!)

        let expectedEventName = MMEventTypeCarplayConnect
        XCTAssertTrue(eventsManagerSpy.hasEnqueuedEvent(with: expectedEventName))
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: expectedEventName))
        XCTAssertEqual(eventsManagerSpy.enqueuedEventCount(with: expectedEventName), 1)
        XCTAssertEqual(eventsManagerSpy.enqueuedEventCount(with: expectedEventName), 1)
    }

    func testEventsEnqueuedAndFlushedWhenCarPlayDisconnected() {
        guard #available(iOS 12, *) else { return }

        simulateCarPlayDisconnection()

        let expectedEventName = MMEventTypeCarplayDisconnect
        XCTAssertTrue(eventsManagerSpy.hasEnqueuedEvent(with: expectedEventName))
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: expectedEventName))
    }

    // MARK: Upon connecting to CarPlay, window and interfaceController should be set up correctly
    // By default we should supply a search template with the Mapbox Geocoder hooked up (?)

//    @available(iOS 12.0, *)
    func testWindowAndIntefaceControllerAreSetUpWithSearchWhenConnected() {
        // This line results in a warning, but is necessary as XCTest ignores the enclosing @available directive.
        // Not sure how to suppress the generated warning here, but this is currently needed for backwards compatibility
        guard #available(iOS 12, *) else { return }

        simulateCarPlayConnection(manager!)

        guard let fakeWindow = manager?.carWindow, let fakeInterfaceController = manager?.interfaceController else {
            XCTFail("Dependencies not met! Bailing...")
            return
        }

        let view = fakeWindow.rootViewController?.view
        XCTAssert((view?.isKind(of: NavigationMapView.self))!, "CarPlay window's root view should be a map view")

        let template: CPMapTemplate = fakeInterfaceController.rootTemplate as! CPMapTemplate
        XCTAssertEqual(1, template.leadingNavigationBarButtons.count)
        XCTAssertEqual(0, template.trailingNavigationBarButtons.count)

        // simulate tap by invoking stored copy of handler
        let searchButton = template.leadingNavigationBarButtons.first!
        searchButton.handler!(searchButton)

        XCTAssert(fakeInterfaceController.topTemplate?.isKind(of: CPSearchTemplate.self) ?? false, "Expecting a search template to be on top")
    }

    func testManagerAsksDelegateForLeadingAndTrailingBarButtonsIfAvailable() {
        guard #available(iOS 12, *) else { return }

        let exampleDelegate = TestCarPlayManagerDelegate()
        exampleDelegate.leadingBarButtons = [CPBarButton(type: .text), CPBarButton(type: .text)]
        exampleDelegate.trailingBarButtons = [CPBarButton(type: .image), CPBarButton(type: .image)]

        manager?.delegate = exampleDelegate

        simulateCarPlayConnection(manager!)

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

        simulateCarPlayConnection(manager!)

        guard let fakeInterfaceController = manager?.interfaceController else {
            XCTFail("Dependencies not met! Bailing...")
            return
        }

        let mapTemplate: CPMapTemplate = fakeInterfaceController.rootTemplate as! CPMapTemplate
        XCTAssertEqual(1, mapTemplate.mapButtons.count)
    }

    func testManagerTellsDelegateWhenNavigationStartsAndEndsDueToArrival() {
        guard #available(iOS 12, *) else { return }

        guard let manager = manager else {
            XCTFail("Won't continue without a test subject...")
            return
        }

        let exampleDelegate = TestCarPlayManagerDelegate()
        manager.delegate = exampleDelegate

        simulateCarPlayConnection(manager)

        guard let fakeInterfaceController = manager.interfaceController else {
            XCTFail("Dependencies not met! Bailing...")
            return
        }

        let mapTemplate: CPMapTemplate = fakeInterfaceController.rootTemplate as! CPMapTemplate

        // given the user is previewing route choices
        // when a trip is started using one of the route choices
        let choice = CPRouteChoice(summaryVariants: ["summary1"], additionalInformationVariants: ["addl1"], selectionSummaryVariants: ["selection1"])
        choice.userInfo = Fixture.routeWithBannerInstructions()

        manager.mapTemplate(mapTemplate, startedTrip: CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [choice]), using: choice)

        // trip previews are hidden on the mapTemplate
        // the delegate is given the opportunity to provide a custom route controller
        // a navigation session is started on the mapTemplate
        // a CarPlayNavigationViewController is presented (why?)

        // the CarPlayNavigationDelegate is notified
        XCTAssertTrue(exampleDelegate.navigationInitiated, "The CarPlayManagerDelegate should have been told that navigation was initiated.")

        manager.carPlayNavigationViewControllerDidArrive(manager.currentNavigator!)

        XCTAssertTrue(exampleDelegate.navigationEnded, "The CarPlayManagerDelegate should have been told that navigation ended.")
    }

    //TODO: -mapTemplateDidCancelNavigation:

    //MARK: Upon disconnecting CarPlay, cleanup happens

    // when a list item that corresponds to a waypoint/location is tapped
    // route options are constructed from the user's location to the final waypoint
    // a route is requested
    // an error is displayed if encountered
    // route choices / trip previews displayed
    // await user input

    // CarPlay handles switching between route choices automatically?

}

@available(iOS 12.0, *)
func simulateCarPlayConnection(_ manager: CarPlayManager) {
    let fakeInterfaceController = FakeCPInterfaceController(#function)
    let fakeWindow = CPWindow()

    manager.application(UIApplication.shared, didConnectCarInterfaceController: fakeInterfaceController, to: fakeWindow)
}

import Quick
import Nimble

@available(iOS 12.0, *)
class CarPlayManagerSpec: QuickSpec {
    override func spec() {
        guard #available(iOS 12, *) else { return }

        var manager: CarPlayManager?
        var delegate: TestCarPlayManagerDelegate?

        beforeEach {
            manager = CarPlayManager()
            delegate = TestCarPlayManagerDelegate()
            manager!.delegate = delegate

            simulateCarPlayConnection(manager!)
        }

        describe("Starting a trip", {

            let action = {
                let fakeTemplate = CPMapTemplate()
                let fakeRouteChoice = CPRouteChoice(summaryVariants: ["summary1"], additionalInformationVariants: ["addl1"], selectionSummaryVariants: ["selection1"])
                fakeRouteChoice.userInfo = Fixture.routeWithBannerInstructions()
                let fakeTrip = CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [fakeRouteChoice])

                manager!.mapTemplate(fakeTemplate, startedTrip: fakeTrip, using: fakeRouteChoice)
            }

            context("When configured to simulate", {
                beforeEach {
                    manager!.simulatesLocations = true
                    manager!.simulatedSpeedMultiplier = 5.0
                }

                it("starts navigation with a route controller with a simulated location manager") {
                    action()

                    expect(delegate!.navigationInitiated).to(beTrue())
                    expect(delegate!.currentRouteController?.locationManager).to(beAnInstanceOf(SimulatedLocationManager.self))
                    expect((delegate!.currentRouteController?.locationManager as! SimulatedLocationManager).speedMultiplier).to(equal(5.0))
                }
            })

            context("When configured not to simulate", {
                beforeEach {
                    manager!.simulatesLocations = false
                }

                it("starts navigation with a route controller with a normal location manager") {
                    action()

                    expect(delegate!.navigationInitiated).to(beTrue())
                    expect(delegate!.currentRouteController?.locationManager).to(beAnInstanceOf(NavigationLocationManager.self))
                }
            })
        })
    }
}



//MARK: Test Objects / Classes.
//TODO: Extract into separate file at some point.

@available(iOS 12.0, *)
class TestCarPlayManagerDelegate: CarPlayManagerDelegate {

    public fileprivate(set) var navigationInitiated = false
    public fileprivate(set) var currentRouteController: RouteController?
    public fileprivate(set) var navigationEnded = false

    public var leadingBarButtons: [CPBarButton]?
    public var trailingBarButtons: [CPBarButton]?
    public var mapButtons: [CPMapButton]?

    func carPlayManager(_ carPlayManager: CarPlayManager, leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]? {
        return leadingBarButtons
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]? {
        return trailingBarButtons
    }

    func carPlayManager(_ carplayManager: CarPlayManager, mapButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate, for activity: CarPlayActivity) -> [CPMapButton]? {
        return mapButtons
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith routeController: RouteController) {
        XCTAssertFalse(navigationInitiated)
        navigationInitiated = true
        currentRouteController = routeController
    }

    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
        XCTAssertTrue(navigationInitiated)
        navigationEnded = true
        currentRouteController = nil
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
