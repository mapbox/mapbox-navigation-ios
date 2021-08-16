import XCTest
@testable import MapboxCoreNavigation
import MapboxDirections
import MapboxMobileEvents
import CarPlay
import MapboxMaps
import CarPlayTestHelper
@testable import TestHelper
@testable import MapboxNavigation

// For some reason XCTest bundles ignore @available annotations and these tests are run on iOS < 12 :(
// This is a bug in XCTest which will hopefully get fixed in an upcoming release.

@available(iOS 12.0, *)
class CarPlayManagerTests: TestCase {
    var manager: CarPlayManager?
    var searchController: CarPlaySearchController?
    var eventsManagerSpy: NavigationEventsManagerSpy?

    override func setUp() {
        super.setUp()
        eventsManagerSpy = NavigationEventsManagerSpy()
        manager = CarPlayManager(eventsManager: eventsManagerSpy, carPlayNavigationViewControllerClass: CarPlayNavigationViewControllerTestable.self)
        searchController = CarPlaySearchController()
    }

    override func tearDown() {
        manager = nil
        searchController = nil
        super.tearDown()
    }

    func simulateCarPlayDisconnection() {
        let fakeInterfaceController = FakeCPInterfaceController(context: #function)
        let fakeWindow = CPWindow()

        manager!.application(UIApplication.shared, didDisconnectCarInterfaceController: fakeInterfaceController, from: fakeWindow)
    }

    func testEventsEnqueuedAndFlushedWhenCarPlayConnected() {
        simulateCarPlayConnection(manager!)

        let expectedEventName = MMEventTypeNavigationCarplayConnect
        XCTAssertTrue(eventsManagerSpy!.hasFlushedEvent(with: expectedEventName))
    }

    func testEventsEnqueuedAndFlushedWhenCarPlayDisconnected() {
        simulateCarPlayDisconnection()

        let expectedEventName = MMEventTypeNavigationCarplayDisconnect
        XCTAssertTrue(eventsManagerSpy!.hasFlushedEvent(with: expectedEventName))
    }

    // MARK: Upon connecting to CarPlay, window and interfaceController should be set up correctly

    func testWindowAndIntefaceControllerAreSetUpWithSearchWhenConnected() {
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
        simulateCarPlayConnection(manager!)
        
        guard let fakeInterfaceController = manager?.interfaceController else {
            XCTFail("Dependencies not met! Bailing...")
            return
        }
        
        let mapTemplate: CPMapTemplate = fakeInterfaceController.rootTemplate as! CPMapTemplate
        XCTAssertEqual(4, mapTemplate.mapButtons.count)
    }

    func testManagerTellsDelegateWhenNavigationStartsAndEndsDueToArrival() {
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
        choice.userInfo = (Fixture.routeResponse(from: "route-with-banner-instructions", options: options), 0, options)
        CarPlayMapViewController.swizzleMethods()
        manager.mapTemplate(mapTemplate, startedTrip: CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [choice]), using: choice)

        // trip previews are hidden on the mapTemplate
        // the delegate is given the opportunity to provide a custom route controller
        // a navigation session is started on the mapTemplate
        // a CarPlayNavigationViewController is presented (why?)

        // the CarPlayNavigationViewControllerDelegate is notified
        XCTAssertTrue(exampleDelegate.navigationInitiated, "The CarPlayManagerDelegate should have been told that navigation was initiated.")

        manager.carPlayNavigationViewController!.exitNavigation(byCanceling: true)

        XCTAssertTrue(exampleDelegate.navigationEnded, "The CarPlayManagerDelegate should have been told that navigation ended.")
        CarPlayMapViewController.unswizzleMethods()
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
        var manager: CarPlayManager?
        var delegate: TestCarPlayManagerDelegate?

        beforeEach {
            NavigationSettings.shared.initialize(directions: .mocked,
                                                 tileStoreConfiguration: .default)
            let mockedHandler = BillingHandler.__createMockedHandler(with: BillingServiceMock())
            BillingHandler.__replaceSharedInstance(with: mockedHandler)
            Navigator.shared.navigator.resetRideSession()
            Navigator._recreateNavigator()
            
            CarPlayMapViewController.swizzleMethods()
            manager = CarPlayManager(styles: nil, eventsManager: nil)
            delegate = TestCarPlayManagerDelegate()
            manager!.delegate = delegate

            simulateCarPlayConnection(manager!)
        }

        afterEach {
            CarPlayMapViewController.unswizzleMethods()
        }

        //MARK: Previewing Routes
        describe("Previewing routes") {
            // Fails on older iOS versions with "Unsupported object MapTemplateSpy"
            guard #available(iOS 14, *) else { return }
            beforeEach {
                manager!.mapTemplateProvider = MapTemplateSpyProvider()
            }
            
            afterEach {
                NavigationRouter.__testRoutesStub = nil
            }

            let previewRoutesAction = {
                let options = NavigationRouteOptions(coordinates: [
                    CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
                    CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
                ])
                let route = Fixture.route(from: "route-with-banner-instructions", options: options)
                let waypoints = options.waypoints

                let fasterResponse = RouteResponse(httpResponse: nil,
                                                   identifier: nil,
                                                   routes: [route],
                                                   waypoints: waypoints,
                                                   options: .route(options),
                                                   credentials: Fixture.credentials)
                NavigationRouter.__testRoutesStub = { (options, completionHandler) in
                    completionHandler(Directions.Session(options, Fixture.credentials),
                                      .success(fasterResponse))
                    return 0
                }
                
                manager!.previewRoutes(for: options, completionHandler: {})
            }

            context("when the trip is not customized by the developer") {
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
            }
            
            context("when the delegate provides a custom trip") {
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
            }
            
            context("when the delegate provides a custom trip preview text") {
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
            }
        }
        
        //MARK: Starting a Trip
        describe("Starting a trip") {
            let action = {
                let fakeTemplate = CPMapTemplate()
                let fakeRouteChoice = CPRouteChoice(summaryVariants: ["summary1"], additionalInformationVariants: ["addl1"], selectionSummaryVariants: ["selection1"])
                let options = NavigationRouteOptions(coordinates: [
                    CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
                    CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
                ])
                fakeRouteChoice.userInfo = (Fixture.routeResponse(from: "route-with-banner-instructions", options: options), 0, options)
                let fakeTrip = CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [fakeRouteChoice])

                //simulate starting a fake trip
                manager!.mapTemplate(fakeTemplate, startedTrip: fakeTrip, using: fakeRouteChoice)
                _ = manager!.carPlayNavigationViewController!.view
                let service = delegate!.currentService! as! MapboxNavigationService
                service.start()
            }

            context("When configured to simulate") {
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
            }

            context("When configured not to simulate") {
                beforeEach {
                    manager!.simulatesLocations = false
                }

                it("starts navigation with a navigation service with simulation set to inTunnels by default") {
                    action()

                    expect(delegate!.navigationInitiated).to(beTrue())
                    let service: MapboxNavigationService = delegate!.currentService! as! MapboxNavigationService

                    expect(service.simulationMode).to(equal(.inTunnels))
                }
            }
        }
    }

    private class CustomTripPreviewDelegate: CarPlayManagerDelegate {
        var customTripPreviewTextConfiguration: CPTripPreviewTextConfiguration?
        var customTrip: CPTrip?

        func carPlayManager(_ carPlayManager: CarPlayManager, willPreview trip: CPTrip) -> CPTrip {
            return customTrip ?? trip
        }

        func carPlayManager(_ carPlayManager: CarPlayManager, willPreview trip: CPTrip, with previewTextConfiguration: CPTripPreviewTextConfiguration) -> CPTripPreviewTextConfiguration {
            return customTripPreviewTextConfiguration ?? previewTextConfiguration
        }

        func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith service: NavigationService) {
            //no-op
        }

        func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
            //no-op
        }
        
        //TODO: ADD OPTIONS TO THIS DELEGATE METHOD
        func carPlayManager(_ carPlayManager: CarPlayManager, navigationServiceFor routeResponse: RouteResponse, routeIndex: Int, routeOptions: RouteOptions, desiredSimulationMode: SimulationMode) -> NavigationService? {
            return MapboxNavigationService(routeResponse: routeResponse, routeIndex: routeIndex, routeOptions: routeOptions, simulating: desiredSimulationMode)
        }

        func carPlayManager(_ carPlayManager: CarPlayManager, didPresent navigationViewController: CarPlayNavigationViewController) {
            //no-op
        }

        func carPlayManager(_ carPlayManager: CarPlayManager, shouldPresentArrivalUIFor waypoint: Waypoint) -> Bool {
            true
        }
    }
}

@available(iOS 12.0, *)
extension CarPlayMapViewController {
    private static var presentedViewControllers: [UIViewController] = []
    private static var swizzled: Bool = false

    static func swizzleMethods() {
        guard !swizzled else { return }
        swizzled = true
        swapMethodsForSwizzling()
    }

    static func unswizzleMethods() {
        guard swizzled else { return }
        swizzled = false
        swapMethodsForSwizzling()
    }

    private static func swapMethodsForSwizzling() {
        method_exchangeImplementations(
            class_getInstanceMethod(CarPlayMapViewController.self,
                                    #selector(CarPlayMapViewController.present(_:animated:completion:)))!,
            class_getInstanceMethod(CarPlayMapViewController.self,
                                    #selector(CarPlayMapViewController.swizzled_present(_:animated:completion:)))!
        )
    }

    @objc private func swizzled_present(_ viewControllerToPresent: UIViewController,
                                animated flag: Bool,
                                completion: (() -> Void)? = nil) {
        /// We need to keep strong reference to `viewControllerToPresent` so that it won't be deallocated in some cases.
        /// This aligns with 
        Self.presentedViewControllers.append(viewControllerToPresent)
        completion?()
    }
}
