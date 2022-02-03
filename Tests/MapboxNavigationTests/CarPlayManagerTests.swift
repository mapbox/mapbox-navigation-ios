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
    
    func testEventsEnqueuedAndFlushedWhenCarPlayConnected() {
        simulateCarPlayConnection(carPlayManager)
        
        let expectedEventName = MMEventTypeNavigationCarplayConnect
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: expectedEventName))
    }
    
    func testEventsEnqueuedAndFlushedWhenCarPlayDisconnected() {
        simulateCarPlayDisconnection(carPlayManager)
        
        let expectedEventName = MMEventTypeNavigationCarplayDisconnect
        XCTAssertTrue(eventsManagerSpy.hasFlushedEvent(with: expectedEventName))
    }
    
    func testWindowAndIntefaceControllerAreSetUpWithSearchWhenConnected() {
        let exampleDelegate = TestCarPlayManagerDelegate()
        let searchDelegate = TestCarPlaySearchControllerDelegate()
        let searchButtonHandler: ((CPBarButton) -> Void) = { [weak self] _ in
            guard let self = self else { return }
            self.carPlayManager.interfaceController?.pushTemplate(CPSearchTemplate(), animated: true)
        }
        exampleDelegate.leadingBarButtons = [
            CPBarButton(type: .image, handler: searchButtonHandler)
        ]
        
        carPlayManager.delegate = exampleDelegate
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
        let carPlayManagerWithModifiedStyles = CarPlayManager(styles: styles,
                                                              routingProvider: MapboxRoutingProvider(.offline))
        XCTAssertEqual(carPlayManagerWithModifiedStyles.styles,
                       styles,
                       "CarPlayManager should persist the initial styles given to it.")
    }
    
    func testFinalDestinationAnnotationIsPresentInCarPlayMapViewController() {
        
        class CarPlayManagerDelegateMock: CarPlayManagerDelegate {
            
            var parentViewController: UIViewController? = nil
            
            var didAddFinalDestinationAnnotation = false
            
            func carPlayManager(_ carPlayManager: CarPlayManager,
                                didAdd finalDestinationAnnotation: PointAnnotation,
                                to parentViewController: UIViewController,
                                pointAnnotationManager: PointAnnotationManager) {
                didAddFinalDestinationAnnotation = true
                self.parentViewController = parentViewController
            }
        }
        
        let carPlayManagerDelegateMock = CarPlayManagerDelegateMock()
        
        let carPlayManager = CarPlayManager(routingProvider: MapboxRoutingProvider(.offline))
        carPlayManager.delegate = carPlayManagerDelegateMock
        
        simulateCarPlayConnection(carPlayManager)
        
        let navigationRouteOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
            CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
        ])
        
        let route = Fixture.route(from: "route-with-banner-instructions",
                                  options: navigationRouteOptions)
        
        carPlayManager.carPlayMapViewController?.navigationMapView.showWaypoints(on: route)
        
        // Right after calling `NavigationMapView.showWaypoints(on:legIndex:)` and before loading actual
        // `MapView` style it is expected that `NavigationMapView.finalDestinationAnnotation` is assigned
        // to non-nil value.
        XCTAssertNotNil(carPlayManager.carPlayMapViewController?.navigationMapView.finalDestinationAnnotation,
                        "Final destination annotation should not be nil.")
        XCTAssertNil(carPlayManager.carPlayMapViewController?.navigationMapView.pointAnnotationManager,
                     "Point annotation manager should be nil.")
        
        let styleJSONObject: [String: Any] = [
            "version": 1,
            "center": [
                37.763330, -122.385563
            ],
            "zoom": 15,
            "sources": [],
            "layers": []
        ]
        
        let styleJSON: String = ValueConverter.toJson(forValue: styleJSONObject)
        XCTAssertFalse(styleJSON.isEmpty, "ValueConverter should create valid JSON string.")
        
        let didAddFinalDestinationAnnotationExpectation = self.expectation {
            return carPlayManagerDelegateMock.didAddFinalDestinationAnnotation
        }
        
        carPlayManager.carPlayMapViewController?.navigationMapView.mapView.mapboxMap.loadStyleJSON(styleJSON)
        
        wait(for: [didAddFinalDestinationAnnotationExpectation], timeout: 5.0)
        
        let navigationMapView = carPlayManager.carPlayMapViewController?.navigationMapView
        
        // After fully loading style `NavigationMapView.finalDestinationAnnotation` should be assigned to nil and
        // `NavigationMapView.pointAnnotationManager` must become valid.
        XCTAssertNil(navigationMapView?.finalDestinationAnnotation,
                     "Final destination annotation should be nil.")
        XCTAssertNotNil(navigationMapView?.pointAnnotationManager,
                        "Point annotation manager should not be nil.")
        XCTAssertEqual(navigationMapView?.pointAnnotationManager?.annotations.count,
                       1,
                       "Only final destination annotation should be present.")
        XCTAssertEqual(navigationMapView?.pointAnnotationManager?.annotations.first?.id,
                       NavigationMapView.AnnotationIdentifier.finalDestinationAnnotation,
                       "Point annotation identifiers should be equal.")
        // Since `PointAnnotation` was added to the `CarPlayMapViewController`, parent `UIViewController`
        // from the delegate method and `CarPlayManager.carPlayMapViewController` should be the same.
        XCTAssertEqual(carPlayManagerDelegateMock.parentViewController,
                       carPlayManager.carPlayMapViewController,
                       "UIViewControllers should be equal.")
        
        simulateCarPlayDisconnection(carPlayManager)
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
