import XCTest
import MapboxCoreNavigation
import MapboxDirections
import MapboxMobileEvents
@testable import TestHelper
@testable import MapboxNavigation

#if canImport(CarPlay)
import CarPlay

// For some reason XCTest bundles ignore @available annotations and these tests are run on iOS < 12 :(
// This is a bug in XCTest which will hopefully get fixed in an upcoming release.

@available(iOS 12.0, *)
class CarPlayManagerTests: XCTestCase {
    var manager: CarPlayManager?
    var searchController: CarPlaySearchController?
    var eventsManagerSpy: NavigationEventsManagerSpy?

    override func setUp() {
        super.setUp()
        eventsManagerSpy = NavigationEventsManagerSpy()
        manager = CarPlayManager(eventsManager: eventsManagerSpy, navigationViewControllerClass: CarPlayNavigationViewControllerTestable.self)
        searchController = CarPlaySearchController()
    }

    override func tearDown() {
        manager = nil
        searchController = nil
        super.tearDown()
    }

    func simulateCarPlayDisconnection() {
        let fakeInterfaceController = FakeCPInterfaceController(#function)
        let fakeWindow = CPWindow()

        manager!.application(UIApplication.shared, didDisconnectCarInterfaceController: fakeInterfaceController, from: fakeWindow)
    }

    func testEventsEnqueuedAndFlushedWhenCarPlayConnected() {
        // NOTE: Xcode is going to complain here - ignore. This is a known XCTest bug.
        guard #available(iOS 12, *) else { return }

        simulateCarPlayConnection(manager!)

        let expectedEventName = MMEventTypeNavigationCarplayConnect
        XCTAssertTrue(eventsManagerSpy!.hasEnqueuedEvent(with: expectedEventName))
        XCTAssertTrue(eventsManagerSpy!.hasFlushedEvent(with: expectedEventName))
        XCTAssertEqual(eventsManagerSpy!.enqueuedEventCount(with: expectedEventName), 1)
        XCTAssertEqual(eventsManagerSpy!.enqueuedEventCount(with: expectedEventName), 1)
    }

    func testEventsEnqueuedAndFlushedWhenCarPlayDisconnected() {
        // NOTE: Xcode is going to complain here - ignore. This is a known XCTest bug.
        guard #available(iOS 12, *) else { return }

        simulateCarPlayDisconnection()

        let expectedEventName = MMEventTypeNavigationCarplayDisconnect
        XCTAssertTrue(eventsManagerSpy!.hasEnqueuedEvent(with: expectedEventName))
        XCTAssertTrue(eventsManagerSpy!.hasFlushedEvent(with: expectedEventName))
    }

    // MARK: Upon connecting to CarPlay, window and interfaceController should be set up correctly

    func testWindowAndIntefaceControllerAreSetUpWithSearchWhenConnected() {
        // NOTE: Xcode is going to complain here - ignore. This is a known XCTest bug.
        guard #available(iOS 12, *) else { return }
        
        let exampleDelegate = TestCarPlayManagerDelegate()
        let searchDelegate = TestCarPlaySearchControllerDelegate()
        let searchButtonHandler: ((CPBarButton) -> Void) = { _ in self.manager!.interfaceController!.pushTemplate(CPSearchTemplate(), animated: true)}
        exampleDelegate.leadingBarButtons = [CPBarButton(type: .image, handler: searchButtonHandler)]
        
        manager?.delegate = exampleDelegate
        searchController?.delegate = searchDelegate
        
        simulateCarPlayConnection(manager!)

        guard let fakeWindow = manager?.carWindow, let fakeInterfaceController = manager?.interfaceController else {
            XCTFail("Dependencies not met! Bailing...")
            return
        }

        searchDelegate.carPlaySearchController(searchController!, carPlayManager: manager!, interfaceController: fakeInterfaceController)

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
        // NOTE: Xcode is going to complain here - ignore. This is a known XCTest bug.
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
    
    func testManagerAsksDelegateForLeadingAndTrailingBarButtonsIfNotAvailable() {
        // NOTE: Xcode is going to complain here - ignore. This is a known XCTest bug.
        guard #available(iOS 12, *) else { return }
        
        simulateCarPlayConnection(manager!)
        
        guard let fakeInterfaceController = manager?.interfaceController else {
            XCTFail("Dependencies not met! Bailing...")
            return
        }
        
        let mapTemplate: CPMapTemplate = fakeInterfaceController.rootTemplate as! CPMapTemplate
        XCTAssertEqual(0, mapTemplate.leadingNavigationBarButtons.count)
        XCTAssertEqual(0, mapTemplate.trailingNavigationBarButtons.count)
    }

    func testManagerAsksDelegateForMapButtonsIfAvailable() {
        // NOTE: Xcode is going to complain here - ignore. This is a known XCTest bug.
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
    
    func testManagerAsksDelegateForMapButtonsIfNotAvailable() {
        // NOTE: Xcode is going to complain here - ignore. This is a known XCTest bug.
        guard #available(iOS 12, *) else { return }
        
        simulateCarPlayConnection(manager!)
        
        guard let fakeInterfaceController = manager?.interfaceController else {
            XCTFail("Dependencies not met! Bailing...")
            return
        }
        
        let mapTemplate: CPMapTemplate = fakeInterfaceController.rootTemplate as! CPMapTemplate
        XCTAssertEqual(4, mapTemplate.mapButtons.count)
    }

    func testManagerTellsDelegateWhenNavigationStartsAndEndsDueToArrival() {
        // NOTE: Xcode is going to complain here - ignore. This is a known XCTest bug.
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
        let options = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
            CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
        ])
        choice.userInfo = (Fixture.route(from: "route-with-banner-instructions", options: options), 0, options)

        manager.mapTemplate(mapTemplate, startedTrip: CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [choice]), using: choice)

        // trip previews are hidden on the mapTemplate
        // the delegate is given the opportunity to provide a custom route controller
        // a navigation session is started on the mapTemplate
        // a CarPlayNavigationViewController is presented (why?)

        // the CarPlayNavigationDelegate is notified
        XCTAssertTrue(exampleDelegate.navigationInitiated, "The CarPlayManagerDelegate should have been told that navigation was initiated.")

        manager.currentNavigator!.exitNavigation(byCanceling: true)

        XCTAssertTrue(exampleDelegate.navigationEnded, "The CarPlayManagerDelegate should have been told that navigation ended.")
    }
    
    func testRouteFailure() {
        let manager = CarPlayManager()
        
        let spy = CarPlayManagerFailureDelegateSpy()
        let testError = DirectionsError.requestTooLarge
        let locOne = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let fakeOptions = RouteOptions(coordinates: [locOne])
        manager.delegate = spy
        manager.didCalculate(.failure(testError), in: (options: fakeOptions, credentials: Fixture.credentials), for: fakeOptions, completionHandler: { })
        XCTAssert(spy.recievedError == testError, "Delegate should have receieved error")
    }
    
    func testDirectionsOverride() {
        class DirectionsInvocationSpy: Directions {
            typealias VoidClosure = () -> Void
            var payload: VoidClosure?
            
            override func calculate(_ options: RouteOptions, completionHandler: @escaping Directions.RouteCompletionHandler) -> URLSessionDataTask {
                payload?()
                
                return URLSessionDataTask()
            }
        }
        
        let expectation = XCTestExpectation(description: "Ensuring Spy is called")
        let spy = DirectionsInvocationSpy()
        spy.payload = expectation.fulfill
        
        let subject = CarPlayManager(directions: spy)
      
        let waypoint1 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.795042, longitude: -122.413165))
        let waypoint2 = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 37.7727, longitude: -122.433378))
        let options = RouteOptions(waypoints: [waypoint1, waypoint2])
        subject.calculate(options, completionHandler: { _, _ in })
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssert(subject.directions == spy, "Directions client is not overridden properly.")
    }
    
    func testCustomStyles() {
        class CustomStyle: DayStyle {}
        
        XCTAssertEqual(manager?.styles.count, 2)
        XCTAssertEqual(manager?.styles.first?.styleType, StyleType.day)
        XCTAssertEqual(manager?.styles.last?.styleType, StyleType.night)
        
        let styles = [CustomStyle()]
        XCTAssertEqual(CarPlayManager(styles: styles).styles, styles, "CarPlayManager should persist the initial styles given to it.")
    }
}

//MARK: -

import Quick
import Nimble

@available(iOS 12.0, *)
class CarPlayManagerSpec: QuickSpec {
    override func spec() {
        // NOTE: Xcode is going to complain here - ignore. This is a known XCTest bug.
        guard #available(iOS 12, *) else { return }
        var manager: CarPlayManager?
        var delegate: TestCarPlayManagerDelegate?

        beforeEach {
            let directionsSpy = DirectionsSpy()
            manager = CarPlayManager(styles: nil, directions: directionsSpy, eventsManager: nil)
            delegate = TestCarPlayManagerDelegate()
            manager!.delegate = delegate

            simulateCarPlayConnection(manager!)
        }

        //MARK: Previewing Routes
        describe("Previewing routes", {
            beforeEach {
                manager!.mapTemplateProvider = MapTemplateSpyProvider()
            }

            let previewRoutesAction = {
                let options = NavigationRouteOptions(coordinates: [
                    CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
                    CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
                ])
                let route = Fixture.route(from: "route-with-banner-instructions", options: options)
                let waypoints = options.waypoints

                let directionsSpy = manager!.directions as! DirectionsSpy

                manager!.previewRoutes(for: options, completionHandler: {})
                directionsSpy.fireLastCalculateCompletion(with: waypoints, routes: [route], error: nil)
            }

            context("when the trip is not customized by the developer", {
                beforeEach {
                    previewRoutesAction()
                }
                
                it("previews a route/options with the default configuration") {
                    let interfaceController = manager!.interfaceController as! FakeCPInterfaceController
                    let mapTemplateSpy: MapTemplateSpy =  interfaceController.topTemplate as! MapTemplateSpy
                    
                    expect(mapTemplateSpy.currentTripPreviews).toNot(beEmpty())
                    let expectedStartButtonTitle = NSLocalizedString("CARPLAY_GO", bundle: .mapboxNavigation, value: "Go", comment: "Title for start button in CPTripPreviewTextConfiguration")
                    expect(mapTemplateSpy.currentPreviewTextConfiguration?.startButtonTitle).to(equal(expectedStartButtonTitle))
                }
            })
            
            context("when the delegate provides a custom trip", {
                var customTrip: CPTrip!

                beforeEach {
                    let customTripDelegate = CustomTripPreviewDelegate()
                    customTrip = CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [])
                    customTripDelegate.customTrip = customTrip
                    manager!.delegate = customTripDelegate

                    previewRoutesAction()
                }

                it("shows trip previews for the custom trip") {
                    let interfaceController = manager!.interfaceController as! FakeCPInterfaceController
                    let mapTemplateSpy: MapTemplateSpy =  interfaceController.topTemplate as! MapTemplateSpy

                    expect(mapTemplateSpy.currentTripPreviews).to(contain(customTrip))
                    expect(mapTemplateSpy.currentPreviewTextConfiguration).toNot(beNil())
                }
            })
            
            context("when the delegate provides a custom trip preview text", {
                var customTripPreviewTextConfiguration: CPTripPreviewTextConfiguration!
                let customStartButtonTitleText = "Let's roll"
                
                beforeEach {
                    let customTripDelegate = CustomTripPreviewDelegate()
                    customTripPreviewTextConfiguration = CPTripPreviewTextConfiguration(startButtonTitle: customStartButtonTitleText, additionalRoutesButtonTitle: nil, overviewButtonTitle: nil)
                    customTripDelegate.customTripPreviewTextConfiguration = customTripPreviewTextConfiguration
                    manager!.delegate = customTripDelegate

                    previewRoutesAction()
                }
                
                it("previews a route/options with the custom trip configuration") {
                    let interfaceController = manager!.interfaceController as! FakeCPInterfaceController
                    let mapTemplateSpy: MapTemplateSpy =  interfaceController.topTemplate as! MapTemplateSpy
                    
                    expect(mapTemplateSpy.currentTripPreviews).toNot(beEmpty())
                    expect(mapTemplateSpy.currentPreviewTextConfiguration?.startButtonTitle).to(equal(customStartButtonTitleText))
                }
            })
        })
        
        //MARK: Starting a Trip
        describe("Starting a trip", {
            let action = {
                let fakeTemplate = CPMapTemplate()
                let fakeRouteChoice = CPRouteChoice(summaryVariants: ["summary1"], additionalInformationVariants: ["addl1"], selectionSummaryVariants: ["selection1"])
                let options = NavigationRouteOptions(coordinates: [
                    CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
                    CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
                ])
                fakeRouteChoice.userInfo = (Fixture.route(from: "route-with-banner-instructions", options: options), 0, options)
                let fakeTrip = CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [fakeRouteChoice])

                //simulate starting a fake trip
                manager!.mapTemplate(fakeTemplate, startedTrip: fakeTrip, using: fakeRouteChoice)
                let service = delegate!.currentService! as! MapboxNavigationService
                service.start()
            }

            context("When configured to simulate", {
                beforeEach {
                    manager!.simulatesLocations = true
                    manager!.simulatedSpeedMultiplier = 5.0
                }

                it("starts navigation with a navigation service with simulation enabled") {
                    action()

                    expect(delegate!.navigationInitiated).to(beTrue())
                    let service: MapboxNavigationService = delegate!.currentService! as! MapboxNavigationService

                    expect(service.simulationMode).to(equal(.always))
                    expect(service.simulationSpeedMultiplier).to(equal(5.0))
                }
            })

            context("When configured not to simulate", {
                beforeEach {
                    manager!.simulatesLocations = false
                }

                it("starts navigation with a navigation service with simulation set to onPoorGPS by default") {
                    action()

                    expect(delegate!.navigationInitiated).to(beTrue())
                    let service: MapboxNavigationService = delegate!.currentService! as! MapboxNavigationService

                    expect(service.simulationMode).to(equal(.onPoorGPS))
                }
            })
        })
    }

    private class CustomTripPreviewDelegate: CarPlayManagerDelegate {
        var customTripPreviewTextConfiguration: CPTripPreviewTextConfiguration?
        var customTrip: CPTrip?

        func carPlayManager(_ carPlayManager: CarPlayManager, willPreview trip: CPTrip) -> (CPTrip) {
            return customTrip ?? trip
        }

        func carPlayManager(_ carPlayManager: CarPlayManager, willPreview trip: CPTrip, with previewTextConfiguration: CPTripPreviewTextConfiguration) -> (CPTripPreviewTextConfiguration) {
            return customTripPreviewTextConfiguration ?? previewTextConfiguration
        }

        func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith service: NavigationService) {
            //no-op
        }

        func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
            //no-op
        }
        
        //TODO: ADD OPTIONS TO THIS DELEGATE METHOD
        func carPlayManager(_ carPlayManager: CarPlayManager, navigationServiceAlong route: Route, routeIndex: Int, routeOptions: RouteOptions, desiredSimulationMode: SimulationMode) -> NavigationService {
            let directionsFake = Directions(credentials: Fixture.credentials)
            return MapboxNavigationService(route: route, routeIndex: routeIndex, routeOptions: routeOptions, directions: directionsFake, simulating: desiredSimulationMode)
        }
    }
}

//MARK: -
//MARK: Test Helper Methods

@available(iOS 12.0, *)
func simulateCarPlayConnection(_ manager: CarPlayManager) {
    let fakeInterfaceController = FakeCPInterfaceController(#function)
    let fakeWindow = CPWindow()
    
    manager.application(UIApplication.shared, didConnectCarInterfaceController: fakeInterfaceController, to: fakeWindow)
    if let mapViewController = manager.carWindow?.rootViewController?.view {
        manager.carWindow?.addSubview(mapViewController)
    }
}

@available(iOS 12.0, *)
class CarPlayManagerFailureDelegateSpy: CarPlayManagerDelegate {
    private(set) var recievedError: DirectionsError?
    
    @available(iOS 12.0, *)
    func carPlayManager(_ carPlayManager: CarPlayManager, didFailToFetchRouteBetween waypoints: [Waypoint]?, options: RouteOptions, error: DirectionsError) -> CPNavigationAlert? {
        recievedError = error
        return nil
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager, navigationServiceAlong route: Route, routeIndex: Int, routeOptions: RouteOptions, desiredSimulationMode: SimulationMode) -> NavigationService {
        fatalError("This is an empty stub.")
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith service: NavigationService) {
        fatalError("This is an empty stub.")
    }
    
    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
        fatalError("This is an empty stub.")
    }
}

//MARK: Test Objects / Classes.

@available(iOS 12.0, *)
class TestCarPlayManagerDelegate: CarPlayManagerDelegate {
    public fileprivate(set) var navigationInitiated = false
    public fileprivate(set) var currentService: NavigationService?
    public fileprivate(set) var navigationEnded = false
    
    public var interfaceController: CPInterfaceController?
    public var searchController: CarPlaySearchController?
    public var leadingBarButtons: [CPBarButton]?
    public var trailingBarButtons: [CPBarButton]?
    public var mapButtons: [CPMapButton]?

    func carPlayManager(_ carPlayManager: CarPlayManager, navigationServiceAlong route: Route, routeIndex: Int, routeOptions: RouteOptions, desiredSimulationMode: SimulationMode) -> NavigationService {
        let response = Fixture.routeResponse(from: jsonFileName, options: routeOptions)
        let initialRoute = response.routes!.first!
        let directionsClientSpy = DirectionsSpy()
        let service = MapboxNavigationService(route: initialRoute, routeIndex: 0, routeOptions: routeOptions, directions: directionsClientSpy, locationSource: NavigationLocationManager(), eventsManagerType: NavigationEventsManagerSpy.self, simulating: desiredSimulationMode)
        return service
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]? {
        return leadingBarButtons
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]? {
        return trailingBarButtons
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, mapButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate, for activity: CarPlayActivity) -> [CPMapButton]? {
        return mapButtons
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith service: NavigationService) {
        XCTAssertFalse(navigationInitiated)
        navigationInitiated = true
        currentService = service
    }

    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
        XCTAssertTrue(navigationInitiated)
        navigationEnded = true
        currentService = nil
    }
}

@available(iOS 12.0, *)
class CarPlayNavigationViewControllerTestable: CarPlayNavigationViewController {
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        completion?()
    }
}

@available(iOS 12.0, *)
class TestCarPlaySearchControllerDelegate: CarPlaySearchControllerDelegate {
    public fileprivate(set) var interfaceController: CPInterfaceController?
    public fileprivate(set) var carPlayManager: CarPlayManager?
    
    func carPlaySearchController(_ searchController: CarPlaySearchController, carPlayManager: CarPlayManager, interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
    }
    
    func previewRoutes(to waypoint: Waypoint, completionHandler: @escaping () -> Void) {
        carPlayManager?.previewRoutes(to: waypoint, completionHandler: completionHandler)
    }
    
    func resetPanButtons(_ mapTemplate: CPMapTemplate) {
        carPlayManager?.resetPanButtons(mapTemplate)
    }
    
    func pushTemplate(_ template: CPTemplate, animated: Bool) {
        interfaceController?.pushTemplate(template, animated: animated)
    }
    
    func popTemplate(animated: Bool) {
        interfaceController?.popTemplate(animated: animated)
    }
}

@available(iOS 12.0, *)
class MapTemplateSpy: CPMapTemplate {
    private(set) var currentTripPreviews: [CPTrip]?
    private(set) var currentPreviewTextConfiguration: CPTripPreviewTextConfiguration?
    
    private(set) var estimatesUpdate: (CPTravelEstimates, CPTrip, CPTimeRemainingColor)?
    
    var fakeSession:  CPNavigationSession!

    override func showTripPreviews(_ tripPreviews: [CPTrip], textConfiguration: CPTripPreviewTextConfiguration?) {
        currentTripPreviews = tripPreviews
        currentPreviewTextConfiguration = textConfiguration
    }
    
    override func update(_ estimates: CPTravelEstimates, for trip: CPTrip, with timeRemainingColor: CPTimeRemainingColor) {
        estimatesUpdate = (estimates, trip, timeRemainingColor)
    }
    
    override func hideTripPreviews() {
        currentTripPreviews = nil
        currentPreviewTextConfiguration = nil
    }
    
    override func startNavigationSession(for trip: CPTrip) -> CPNavigationSession {
        return fakeSession
    }
}

@available(iOS 12.0, *)
public class MapTemplateSpyProvider: MapTemplateProvider {
    override public func createMapTemplate() -> CPMapTemplate {
        return MapTemplateSpy()
    }
}

@available(iOS 12.0, *)
class FakeCPInterfaceController: CPInterfaceController {
    /**
     A simple stub which allows for instantiation of a CPInterfaceController for testing.

     CPInterfaceController cannot be instantiated directly. Properties which don't work in headless testing will need to be overridden with test-specific mock functionality provided.
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

    override open func pushTemplate(_ templateToPush: CPTemplate, animated: Bool) {
        templateStack.append(templateToPush)
    }

    override open func popTemplate(animated: Bool) {
        templateStack.removeLast()
    }

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
    
    var _rootTemplate = CPTemplate()
    override var rootTemplate: CPTemplate {
        if #available(iOS 14.0, *) {
            return _rootTemplate
        } else {
            return super.rootTemplate
        }
    }
    
    override func setRootTemplate(_ rootTemplate: CPTemplate, animated: Bool) {
        if #available(iOS 14.0, *) {
            _rootTemplate = rootTemplate
        } else {
            super.setRootTemplate(rootTemplate, animated: animated)
        }
    }
}
#endif
