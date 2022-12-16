import XCTest
import CarPlay
import MapboxDirections
import CarPlayTestHelper
import CwlPreconditionTesting
@testable import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class CarPlayManagerTests: TestCase {
    var carPlayManager: CarPlayManager!

    var carPlaySearchController: CarPlaySearchController!
    var searchDelegate: TestCarPlaySearchControllerDelegate!
    var eventsManagerSpy: NavigationEventsManagerSpy!
    var mapTemplateProvider: MapTemplateSpyProvider!
    var delegate: CarPlayManagerDelegateSpy!

    var mapTemplateSpy: MapTemplateSpy {
        return carPlayManager.interfaceController?.topTemplate as! MapTemplateSpy
    }
    
    override func setUp() {
        super.setUp()

        CarPlayMapViewController.swizzleMethods()
        eventsManagerSpy = NavigationEventsManagerSpy()
        carPlayManager = CarPlayManager(customRoutingProvider: MapboxRoutingProvider(.offline),
                                        eventsManager: eventsManagerSpy,
                                        carPlayNavigationViewControllerClass: CarPlayNavigationViewControllerTestable.self)
        delegate = CarPlayManagerDelegateSpy()
        carPlayManager.delegate = delegate
        mapTemplateProvider = MapTemplateSpyProvider()
        carPlayManager.mapTemplateProvider = mapTemplateProvider

        carPlaySearchController = CarPlaySearchController()
        searchDelegate = TestCarPlaySearchControllerDelegate()
        carPlaySearchController.delegate = searchDelegate

        simulateCarPlayConnection(carPlayManager)
    }

    override func tearDown() {
        CarPlayMapViewController.unswizzleMethods()
        MapboxRoutingProvider.__testRoutesStub = nil
        delegate.passedService?.stop()

        carPlayManager = nil
        delegate = nil
        searchDelegate = nil
        mapTemplateProvider = nil

        super.tearDown()
    }
    
    func testEventsSentWhenCarPlayConnectedAndDisconnected() {
        XCTAssertTrue(eventsManagerSpy.hasImmediateEvent(with: EventType.carplayConnect.rawValue))
        
        simulateCarPlayDisconnection(carPlayManager)
        XCTAssertTrue(eventsManagerSpy.hasImmediateEvent(with: EventType.carplayDisconnect.rawValue))
    }
    
    func testWindowAndIntefaceControllerAreSetUpWithSearchWhenConnected() {
        let searchDelegate = TestCarPlaySearchControllerDelegate()
        let searchButtonHandler: ((CPBarButton) -> Void) = { [weak self] _ in
            guard let self = self else { return }
            self.carPlayManager.interfaceController?.pushTemplate(CPSearchTemplate(), animated: true)
        }
        delegate.returnedLeadingBarButtons = [
            CPBarButton(type: .image, handler: searchButtonHandler)
        ]
        
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
        delegate.returnedLeadingBarButtons = [
            CPBarButton(type: .text),
            CPBarButton(type: .text)
        ]
        
        delegate.returnedTrailingBarButtons = [
            CPBarButton(type: .image),
            CPBarButton(type: .image)
        ]
        
        simulateCarPlayConnection(carPlayManager)
        
        let mapTemplate = carPlayManager.interfaceController?.rootTemplate as? CPMapTemplate
        XCTAssertEqual(2, mapTemplate?.leadingNavigationBarButtons.count)
        XCTAssertEqual(2, mapTemplate?.trailingNavigationBarButtons.count)
    }
    
    func testManagerAsksDelegateForLeadingAndTrailingBarButtonsIfNotAvailable() {
        let mapTemplate = carPlayManager.interfaceController?.rootTemplate as? CPMapTemplate
        XCTAssertEqual(0, mapTemplate?.leadingNavigationBarButtons.count)
        XCTAssertEqual(0, mapTemplate?.trailingNavigationBarButtons.count)
    }
    
    func testManagerAsksDelegateForMapButtonsIfAvailable() {
        delegate.returnedMapButtons = [CPMapButton()]
        
        simulateCarPlayConnection(carPlayManager)
        
        let mapTemplate = carPlayManager.interfaceController?.rootTemplate as? CPMapTemplate
        XCTAssertEqual(1, mapTemplate?.mapButtons.count)
    }
    
    func testManagerAsksDelegateForMapButtonsIfNotAvailable() {
        let mapTemplate = carPlayManager.interfaceController?.rootTemplate as? CPMapTemplate
        // By default there are four map buttons in preview mode: recenter, pan, zoom-in, zoom-out.
        XCTAssertEqual(4, mapTemplate?.mapButtons.count)
    }
    
    func testNavigationStartAndEnd() {
        startNavigation()

        XCTAssertTrue(delegate.didBeginNavigationCalled,
                      "The CarPlayManagerDelegate should have been told that navigation was initiated.")
        
        carPlayManager.carPlayNavigationViewController?.exitNavigation(byCanceling: true)
        XCTAssertTrue(delegate.legacyDidEndNavigationCalled,
                      "The CarPlayManagerDelegate should have been told that navigation ended.")
        
        XCTAssertTrue(delegate.didEndNavigationCalled,
                      "The CarPlayManagerDelegate should have been told that navigation ended.")
        
        XCTAssertTrue(delegate.passedNavigationEndedByCanceling,
                      "The CarPlayManagerDelegate should have been told that navigation ended by canceling.")
    }
    
    func testRouteRequestFailure() {
        let routeOptions = RouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 0, longitude: 0)
        ])
        let testError = DirectionsError.requestTooLarge
        carPlayManager.didCalculate(.failure(testError), for: routeOptions, completionHandler: {})
        XCTAssertTrue(delegate.didFailToFetchRouteCalled)
        XCTAssertEqual(delegate.passedError, testError, "Delegate should have receieved error.")
    }
    
    func testCustomStyles() {
        class CustomStyle: DayStyle {}
        
        XCTAssertEqual(carPlayManager.styles.count, 2)
        XCTAssertEqual(carPlayManager.styles.first?.styleType, StyleType.day)
        XCTAssertEqual(carPlayManager.styles.last?.styleType, StyleType.night)
        
        let styles = [CustomStyle()]
        let carPlayManagerWithModifiedStyles = CarPlayManager(styles: styles,
                                                              customRoutingProvider: MapboxRoutingProvider(.offline))
        XCTAssertEqual(carPlayManagerWithModifiedStyles.styles,
                       styles,
                       "CarPlayManager should persist the initial styles given to it.")
    }

    func testPreviewRouteWithDefault() {
        // Fails on older iOS versions with "Unsupported object MapTemplateSpy"
        guard #available(iOS 14, *) else { return }

        previewRoutes()

        XCTAssertEqual(mapTemplateSpy.passedTripPreviews?.count, 1)

        let expectedStartButtonTitle = NSLocalizedString("CARPLAY_GO",
                                                         bundle: .mapboxNavigation,
                                                         value: "Go",
                                                         comment: "Title for start button in CPTripPreviewTextConfiguration")
        XCTAssertEqual(mapTemplateSpy.passedPreviewTextConfiguration?.startButtonTitle, expectedStartButtonTitle)
    }

    func testPreviewRouteWithCustomTrip() {
        // Fails on older iOS versions with "Unsupported object MapTemplateSpy"
        guard #available(iOS 14, *) else { return }
        
        let customTrip = CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [])
        delegate.returnedTrip = customTrip

        previewRoutes()

        XCTAssertEqual(mapTemplateSpy.passedTripPreviews?.first, customTrip)
        XCTAssertNotNil(mapTemplateSpy.passedPreviewTextConfiguration)
    }

    func testPreviewRouteWithCustomPreviewText() {
        // Fails on older iOS versions with "Unsupported object MapTemplateSpy"
        guard #available(iOS 14, *) else { return }

        let customTrip = CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [])
        delegate.returnedTrip = customTrip
        let startButtonTitle = "Let's roll"
        let tripPreviewTextConfiguration = CPTripPreviewTextConfiguration(startButtonTitle: startButtonTitle,
                                                                          additionalRoutesButtonTitle: nil,
                                                                          overviewButtonTitle: nil)
        delegate.returnedTripPreviewTextConfiguration = tripPreviewTextConfiguration
        previewRoutes()

        XCTAssertEqual(mapTemplateSpy.passedTripPreviews?.first, customTrip)
        XCTAssertEqual(mapTemplateSpy.passedPreviewTextConfiguration?.startButtonTitle, startButtonTitle)
    }

    func testStartWhenConfiguredToSimulate() {
        carPlayManager.simulatesLocations = true
        carPlayManager.simulatedSpeedMultiplier = 5.0
        startNavigation()

        XCTAssertTrue(delegate.didPresentCalled)

        XCTAssertEqual(delegate.passedService?.simulationMode, .always)
        XCTAssertEqual(delegate.passedService?.simulationSpeedMultiplier, 5.0)
    }

    func testStartWhenConfiguredNotToSimulate() {
        carPlayManager.simulatesLocations = false
        startNavigation()

        XCTAssertTrue(delegate.didPresentCalled)
        let navigationService = delegate.passedService as? MapboxNavigationService
        XCTAssertEqual(navigationService?.simulationMode, .inTunnels)
    }

#if arch(x86_64) && canImport(Darwin)
    func testStartingInvalidTrip() {
        let routeChoice = createInvalidRouteChoice()
        let trip = createTrip(routeChoice)
        let mapTemplate = CPMapTemplate()

        let preconditionExpectation = expectation(description: "Precondition failed")
        let caughtException = catchBadInstruction {
            preconditionExpectation.fulfill()
            self.carPlayManager.mapTemplate(mapTemplate, startedTrip: trip, using: routeChoice)
        }

        waitForExpectations(timeout: 1.0)

        XCTAssertNotNil(caughtException)
    }
#endif

    private func previewRoutes() {
        let navigationRouteOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
            CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
        ])
        let route = Fixture.route(from: "route-with-banner-instructions",
                                  options: navigationRouteOptions)
        let waypoints = navigationRouteOptions.waypoints

        let fasterResponse = RouteResponse(httpResponse: nil,
                                           identifier: nil,
                                           routes: [route],
                                           waypoints: waypoints,
                                           options: .route(navigationRouteOptions),
                                           credentials: Fixture.credentials)
        MapboxRoutingProvider.__testRoutesStub = { (options, completionHandler) in
            completionHandler(.success(.init(routeResponse: fasterResponse, routeIndex: 0)))
            return nil
        }

        carPlayManager.previewRoutes(for: navigationRouteOptions, completionHandler: {})
    }

    private func startNavigation() {
        let routeChoice = createValidRouteChoice()
        let trip = createTrip(routeChoice)
        let mapTemplate = CPMapTemplate()

        carPlayManager.mapTemplate(mapTemplate, startedTrip: trip, using: routeChoice)
        carPlayManager.carPlayNavigationViewController?.loadViewIfNeeded()

        let navigationService = delegate.passedService as? MapboxNavigationService
        navigationService?.start()
    }
}

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
