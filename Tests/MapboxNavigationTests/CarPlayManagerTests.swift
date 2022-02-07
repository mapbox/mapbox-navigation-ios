import XCTest
import CarPlay
import MapboxDirections
import MapboxMobileEvents
import MapboxMaps
import CarPlayTestHelper
@testable import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

@available(iOS 12.0, *)
class CarPlayManagerTests: TestCase {
    
    var carPlayManager: CarPlayManager!
    var carPlaySearchController: CarPlaySearchController!
    var eventsManagerSpy: NavigationEventsManagerSpy!
    
    override func setUp() {
        super.setUp()
        
        eventsManagerSpy = NavigationEventsManagerSpy()
        carPlayManager = CarPlayManager(routingProvider: MapboxRoutingProvider(.offline),
                                        eventsManager: eventsManagerSpy,
                                        carPlayNavigationViewControllerClass: CarPlayNavigationViewControllerTestable.self)
        carPlaySearchController = CarPlaySearchController()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testEventsEnqueuedAndFlushedWhenCarPlayConnectedAndDisconnected() {
        simulateCarPlayConnection(carPlayManager)
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: MMEventTypeNavigationCarplayConnect))
        
        simulateCarPlayDisconnection(carPlayManager)
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: MMEventTypeNavigationCarplayDisconnect))
    }
    
    func testWindowAndIntefaceControllerAreSetUpWithSearchWhenConnected() {
        
        class CarPlayManagerDelegateMock: CarPlayManagerDelegate {
            
            var leadingBarButtons: [CPBarButton]?
            
            func carPlayManager(_ carPlayManager: CarPlayManager,
                                leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
                                in: CPTemplate,
                                for activity: CarPlayActivity) -> [CPBarButton]? {
                return leadingBarButtons
            }
        }
        
        let carPlayManagerDelegateMock = CarPlayManagerDelegateMock()
        let searchDelegate = TestCarPlaySearchControllerDelegate()
        let searchButtonHandler: ((CPBarButton) -> Void) = { [weak self] _ in
            guard let self = self else { return }
            self.carPlayManager.interfaceController?.pushTemplate(CPSearchTemplate(), animated: true)
        }
        carPlayManagerDelegateMock.leadingBarButtons = [
            CPBarButton(type: .image, handler: searchButtonHandler)
        ]
        
        carPlayManager.delegate = carPlayManagerDelegateMock
        carPlaySearchController.delegate = searchDelegate
        
        simulateCarPlayConnection(carPlayManager)
        
        guard let interfaceController = carPlayManager.interfaceController else {
            XCTFail("CPInterfaceController should be valid.")
            return
        }
        
        searchDelegate.carPlaySearchController(carPlaySearchController,
                                               carPlayManager: carPlayManager,
                                               interfaceController: interfaceController)
        
        let view = carPlayManager.carWindow?.rootViewController?.view
        XCTAssertTrue(view is NavigationMapView, "NavigationMapView should be a root view.")
        
        let mapTemplate = interfaceController.rootTemplate as? CPMapTemplate
        XCTAssertEqual(1, mapTemplate?.leadingNavigationBarButtons.count)
        XCTAssertEqual(0, mapTemplate?.trailingNavigationBarButtons.count)
        
        // Simulate tap by invoking stored copy of handler.
        guard let searchButton = mapTemplate?.leadingNavigationBarButtons.first else {
            XCTFail("Search button should be valid.")
            return
        }
        searchButton.handler?(searchButton)
        
        XCTAssertTrue(interfaceController.topTemplate?.isKind(of: CPSearchTemplate.self) ?? false,
                      "CPSearchTemplate should be the top template in the navigation hierarchy.")
    }
    
    func testManagerAsksDelegateForLeadingAndTrailingBarButtonsIfAvailable() {
        
        class CarPlayManagerDelegateMock: CarPlayManagerDelegate {
            
            var leadingBarButtons: [CPBarButton]?
            var trailingBarButtons: [CPBarButton]?
            
            func carPlayManager(_ carPlayManager: CarPlayManager,
                                leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
                                in: CPTemplate,
                                for activity: CarPlayActivity) -> [CPBarButton]? {
                return leadingBarButtons
            }
            
            func carPlayManager(_ carPlayManager: CarPlayManager,
                                trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
                                in: CPTemplate,
                                for activity: CarPlayActivity) -> [CPBarButton]? {
                return trailingBarButtons
            }
        }
        
        let carPlayManagerDelegateMock = CarPlayManagerDelegateMock()
        carPlayManagerDelegateMock.leadingBarButtons = [
            CPBarButton(type: .text),
            CPBarButton(type: .text)
        ]
        
        carPlayManagerDelegateMock.trailingBarButtons = [
            CPBarButton(type: .image),
            CPBarButton(type: .image)
        ]
        
        carPlayManager.delegate = carPlayManagerDelegateMock
        
        simulateCarPlayConnection(carPlayManager)
        
        let mapTemplate = carPlayManager.interfaceController?.rootTemplate as? CPMapTemplate
        XCTAssertEqual(2, mapTemplate?.leadingNavigationBarButtons.count)
        XCTAssertEqual(2, mapTemplate?.trailingNavigationBarButtons.count)
    }
    
    func testManagerAsksDelegateForLeadingAndTrailingBarButtonsIfNotAvailable() {
        simulateCarPlayConnection(carPlayManager)
        
        let mapTemplate = carPlayManager.interfaceController?.rootTemplate as? CPMapTemplate
        XCTAssertEqual(0, mapTemplate?.leadingNavigationBarButtons.count)
        XCTAssertEqual(0, mapTemplate?.trailingNavigationBarButtons.count)
    }
    
    func testManagerAsksDelegateForMapButtonsIfAvailable() {
        
        class CarPlayManagerDelegateMock: CarPlayManagerDelegate {
            
            var mapButtons: [CPMapButton]?
            
            func carPlayManager(_ carPlayManager: CarPlayManager,
                                mapButtonsCompatibleWith traitCollection: UITraitCollection,
                                in template: CPTemplate,
                                for activity: CarPlayActivity) -> [CPMapButton]? {
                return mapButtons
            }
        }
        
        let carPlayManagerDelegateMock = CarPlayManagerDelegateMock()
        carPlayManagerDelegateMock.mapButtons = [CPMapButton()]
        
        carPlayManager.delegate = carPlayManagerDelegateMock
        
        simulateCarPlayConnection(carPlayManager)
        
        let mapTemplate = carPlayManager.interfaceController?.rootTemplate as? CPMapTemplate
        XCTAssertEqual(1, mapTemplate?.mapButtons.count)
    }
    
    func testManagerAsksDelegateForMapButtonsIfNotAvailable() {
        simulateCarPlayConnection(carPlayManager)
        
        let mapTemplate = carPlayManager.interfaceController?.rootTemplate as? CPMapTemplate
        // By default there are four map buttons in preview mode: recenter, pan, zoom-in, zoom-out.
        XCTAssertEqual(4, mapTemplate?.mapButtons.count)
    }
    
    func testNavigationStartAndEnd() {
        
        class CarPlayManagerDelegateMock: CarPlayManagerDelegate {
            
            var navigationStarted = false
            var navigationEnded = false
            
            func carPlayManager(_ carPlayManager: CarPlayManager,
                                didPresent navigationViewController: CarPlayNavigationViewController) {
                XCTAssertFalse(navigationStarted)
                navigationStarted = true
            }
            
            func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
                XCTAssertTrue(navigationStarted)
                navigationEnded = true
            }
        }
        
        let carPlayManagerDelegateMock = CarPlayManagerDelegateMock()
        carPlayManager.delegate = carPlayManagerDelegateMock
        
        simulateCarPlayConnection(carPlayManager)
        
        guard let mapTemplate = carPlayManager.interfaceController?.rootTemplate as? CPMapTemplate else {
            XCTFail("CPMapTemplate should be available.")
            return
        }
        
        let routeChoice = createValidRouteChoice()
        let trip = createTrip(routeChoice)
        
        CarPlayMapViewController.swizzleMethods()
        
        carPlayManager.mapTemplate(mapTemplate, startedTrip: trip, using: routeChoice)
        XCTAssertTrue(carPlayManagerDelegateMock.navigationStarted,
                      "The CarPlayManagerDelegate should have been told that navigation was initiated.")
        
        carPlayManager.carPlayNavigationViewController?.exitNavigation(byCanceling: true)
        XCTAssertTrue(carPlayManagerDelegateMock.navigationEnded,
                      "The CarPlayManagerDelegate should have been told that navigation ended.")
        
        CarPlayMapViewController.unswizzleMethods()
    }
    
    func testRouteRequestFailure() {
        
        class CarPlayManagerDelegateMock: CarPlayManagerDelegate {
            
            var routeCalculationError: DirectionsError?
            
            func carPlayManager(_ carPlayManager: CarPlayManager,
                                didFailToFetchRouteBetween waypoints: [Waypoint]?,
                                options: RouteOptions,
                                error: DirectionsError) -> CPNavigationAlert? {
                routeCalculationError = error
                return nil
            }
        }
        
        let carPlayManagerDelegateMock = CarPlayManagerDelegateMock()
        let routeOptions = RouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 0, longitude: 0)
        ])
        let carPlayManager = CarPlayManager(routingProvider: MapboxRoutingProvider(.offline))
        carPlayManager.delegate = carPlayManagerDelegateMock
        let testError = DirectionsError.requestTooLarge
        carPlayManager.didCalculate(.failure(testError),
                                    in: (options: routeOptions, credentials: Fixture.credentials),
                                    for: routeOptions,
                                    completionHandler: {})
        XCTAssertEqual(carPlayManagerDelegateMock.routeCalculationError,
                       testError,
                       "Delegate should have receieved error.")
    }
    
    func testCustomStyles() {
        class CustomStyle: DayStyle {}
        
        XCTAssertEqual(carPlayManager.styles.count, 2)
        XCTAssertEqual(carPlayManager.styles.first?.styleType, StyleType.day)
        XCTAssertEqual(carPlayManager.styles.last?.styleType, StyleType.night)
        
        let styles = [CustomStyle()]
<<<<<<< HEAD
        let carPlayManagerWithModifiedStyles = CarPlayManager(styles: styles,
                                                              routingProvider: MapboxRoutingProvider(.offline))
        XCTAssertEqual(carPlayManagerWithModifiedStyles.styles,
                       styles,
                       "CarPlayManager should persist the initial styles given to it.")
=======
        XCTAssertEqual(CarPlayManager(styles: styles, routingProvider: MapboxRoutingProvider(.offline)).styles, styles, "CarPlayManager should persist the initial styles given to it.")
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
            
            CarPlayMapViewController.swizzleMethods()
            manager = CarPlayManager(styles: nil, routingProvider: MapboxRoutingProvider(.offline), eventsManager: nil)
            delegate = TestCarPlayManagerDelegate()
            manager!.delegate = delegate

            simulateCarPlayConnection(manager!)
        }

        afterEach {
            CarPlayMapViewController.unswizzleMethods()
            manager = nil
            delegate = nil
        }

        //MARK: Previewing Routes
        describe("Previewing routes") {
            // Fails on older iOS versions with "Unsupported object MapTemplateSpy"
            guard #available(iOS 14, *) else { return }
            beforeEach {
                manager!.mapTemplateProvider = MapTemplateSpyProvider()
            }
            
            afterEach {
                MapboxRoutingProvider.__testRoutesStub = nil
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
                MapboxRoutingProvider.__testRoutesStub = { (options, completionHandler) in
                    completionHandler(Directions.Session(options, Fixture.credentials),
                                      .success(fasterResponse))
                    return nil
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
            return MapboxNavigationService(routeResponse: routeResponse,
                                           routeIndex: routeIndex,
                                           routeOptions: routeOptions,
                                           routingProvider: MapboxRoutingProvider(.offline),
                                           credentials: Fixture.credentials,
                                           simulating: desiredSimulationMode)
        }

        func carPlayManager(_ carPlayManager: CarPlayManager, didPresent navigationViewController: CarPlayNavigationViewController) {
            //no-op
        }

        func carPlayManager(_ carPlayManager: CarPlayManager, shouldPresentArrivalUIFor waypoint: Waypoint) -> Bool {
            true
        }
>>>>>>> main
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
        presentedViewControllers.removeAll()
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
        // We need to keep strong reference to `viewControllerToPresent` so that it won't be
        // deallocated in some cases.
        Self.presentedViewControllers.append(viewControllerToPresent)
        completion?()
    }
}
