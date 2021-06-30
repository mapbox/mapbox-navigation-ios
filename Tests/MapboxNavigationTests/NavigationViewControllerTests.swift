import XCTest
import Turf
import MapboxMaps
@testable import MapboxDirections
@testable import TestHelper
@testable import MapboxCoreNavigation
@testable import MapboxNavigation

let otherResponse = Fixture.JSONFromFileNamed(name: "route-for-lane-testing")

private let mockedUNUserNotificationCenter: MockedUNUserNotificationCenter = .init()

/// `UNUserNotificationCenter.current()` crashes when run from SPM tests.
/// In order to fix the crash we mock `UNUserNotificationCenter` but swizzling `UNUserNotificationCenter.current()` and
/// return the instance of this class instead.
/// If you see that tests crash due to the unrecognized selector error to MockedUNUserNotificationCenter,
/// write a mock version of this test and try again.
@objc private final class MockedUNUserNotificationCenter: NSObject {
    fileprivate static var isMocked: Bool = false
    @objc private func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
    @objc private func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
}

extension UNUserNotificationCenter {
    static func mockForTests() {
        guard !MockedUNUserNotificationCenter.isMocked else { return }

        method_exchangeImplementations(
            class_getClassMethod(UNUserNotificationCenter.self,
                                 #selector(UNUserNotificationCenter.current))!,
            class_getClassMethod(UNUserNotificationCenter.self,
                                 #selector(UNUserNotificationCenter.swizzled_current))!
        )

        MockedUNUserNotificationCenter.isMocked = true
    }

    @objc static func swizzled_current() -> AnyObject {
        return mockedUNUserNotificationCenter
    }
}

class NavigationViewControllerTests: XCTestCase {
    var customRoadName = [CLLocationCoordinate2D: String?]()
    
    var updatedStyleNumberOfTimes = 0
    var dependencies: (navigationViewController: NavigationViewController, navigationService: NavigationService, startLocation: CLLocation, poi: [CLLocation], endLocation: CLLocation, voice: RouteVoiceController)!
    
    var initialRoute: Route!
    
    var newRoute: Route!
    
    override func setUp() {
        super.setUp()
        customRoadName.removeAll()
        ResourceOptionsManager.default.resourceOptions.accessToken = .mockedAccessToken
        DirectionsCredentials.injectSharedToken(.mockedAccessToken)
        initialRoute = Fixture.route(from: jsonFileName, options: routeOptions)
        newRoute = Fixture.route(from: jsonFileName, options: routeOptions)
        dependencies = {
            UNUserNotificationCenter.mockForTests()

            let fakeDirections = DirectionsSpy()
            let fakeService = MapboxNavigationService(route: initialRoute, routeIndex: 0, routeOptions: routeOptions, directions: fakeDirections, locationSource: NavigationLocationManagerStub(), simulating: .never)
            let fakeVoice: RouteVoiceController = RouteVoiceControllerStub(navigationService: fakeService)
            let options = NavigationOptions(navigationService: fakeService, voiceController: fakeVoice)
            let navigationViewController = NavigationViewController(for: initialRoute, routeIndex: 0, routeOptions: routeOptions, navigationOptions: options)

            navigationViewController.delegate = self
            _ = navigationViewController.view // trigger view load
            let navigationService = navigationViewController.navigationService!
            let router = navigationService.router!
            let firstCoord      = router.routeProgress.nearbyShape.coordinates.first!
            let firstLocation   = location(at: firstCoord)

            var poi = [CLLocation]()
            let taylorStreetIntersection = router.route.legs.first!.steps.first!.intersections!.first!
            let turkStreetIntersection   = router.route.legs.first!.steps[3].intersections!.first!
            let fultonStreetIntersection = router.route.legs.first!.steps[5].intersections!.first!

            poi.append(location(at: taylorStreetIntersection.location))
            poi.append(location(at: turkStreetIntersection.location))
            poi.append(location(at: fultonStreetIntersection.location))

            let lastCoord    = router.routeProgress.currentLegProgress.remainingSteps.last!.shape!.coordinates.first!
            let lastLocation = location(at: lastCoord)

            return (navigationViewController: navigationViewController, navigationService: navigationService, startLocation: firstLocation, poi: poi, endLocation: lastLocation, voice: fakeVoice)
        }()
    }

    override func tearDown() {
        super.tearDown()
        initialRoute = nil
        dependencies = nil
        Navigator._recreateNavigator()
    }
    
    func testDefaultUserInterfaceUsage() {
        let navigationViewController = dependencies.navigationViewController
        let service = dependencies.navigationService
        XCTAssertTrue(service.eventsManager.usesDefaultUserInterface, "MapboxNavigationTests should run inside the Example application target.")
        _ = navigationViewController
    }
    
    // Brief: navigationViewController(_:roadNameAt:) delegate method is implemented,
    //        with a road name provided and wayNameView label is visible.
    func disabled_testNavigationViewControllerDelegateRoadNameAtLocationImplemented() {
        let navigationViewController = dependencies.navigationViewController
        let service = dependencies.navigationService
        
        // Identify a location to set the custom road name.
        let taylorStreetLocation = dependencies.poi.first!
        let roadName = "Taylor Swift Street"
        customRoadName[taylorStreetLocation.coordinate] = roadName
        
        service.locationManager!(service.locationManager, didUpdateLocations: [taylorStreetLocation])

        let wayNameView = navigationViewController.navigationView.wayNameView
        let currentRoadName = wayNameView.text
        XCTAssertEqual(currentRoadName, roadName, "Expected: \(roadName); Actual: \(String(describing: currentRoadName))")
        XCTAssertFalse(wayNameView.isHidden, "WayNameView should be visible.")
    }
    
    func testNavigationShouldNotCallStyleManagerDidRefreshAppearanceMoreThanOnceWithOneStyle() {
        let options = NavigationOptions(styles: [DayStyle()], navigationService: dependencies.navigationService, voiceController: dependencies.voice)
        let navigationViewController = NavigationViewController(for: initialRoute, routeIndex: 0, routeOptions: routeOptions, navigationOptions: options)
        let service = dependencies.navigationService
        _ = navigationViewController.view // trigger view load
        navigationViewController.styleManager.delegate = self
        
        let someLocation = dependencies.poi.first!
        
        let test: (Any) -> Void = { _ in service.locationManager!(service.locationManager, didUpdateLocations: [someLocation]) }
        
        (0...2).forEach(test)
        
        XCTAssertEqual(updatedStyleNumberOfTimes, 0, "The style should not be updated.")
        updatedStyleNumberOfTimes = 0
    }

    /// Disabled. Looks like status is update asynchorniously or something else. Needs investigation.
    func disabled_testCompleteRoute() {
        let navigationViewController = dependencies.navigationViewController
        let service = dependencies.navigationService
        
        let delegate = NavigationServiceDelegateSpy()
        service.delegate = delegate

        _ = navigationViewController.view
        navigationViewController.viewWillAppear(false)
        navigationViewController.viewDidAppear(false)

        let now = Date()
        let rawLocations = Fixture.generateTrace(for: initialRoute)
        let locations = rawLocations.enumerated().map { $0.element.shifted(to: now + $0.offset) }
        
        for location in locations {
            service.locationManager!(service.locationManager, didUpdateLocations: [location])
        }

        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:willArriveAt:after:distance:)"), "Pre-arrival delegate message not fired.")
        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:didArriveAt:)"))
    }
    
    // If tunnel flags are enabled and we need to switch styles, we should not force refresh the map style because we have only 1 style.
    func testNavigationShouldNotCallStyleManagerDidRefreshAppearanceWhenOnlyOneStyle() {
        let options = NavigationOptions(styles:[NightStyle()], navigationService: dependencies.navigationService, voiceController: dependencies.voice)
        let navigationViewController = NavigationViewController(for: initialRoute, routeIndex: 0, routeOptions: routeOptions, navigationOptions: options)
        let service = dependencies.navigationService
        _ = navigationViewController.view // trigger view load

        navigationViewController.styleManager.delegate = self
        
        let someLocation = dependencies.poi.first!
        
        let test: (Any) -> Void = { _ in service.locationManager!(service.locationManager, didUpdateLocations: [someLocation]) }
        
        (0...2).forEach(test)
        
        XCTAssertEqual(updatedStyleNumberOfTimes, 0, "The style should not be updated.")
        updatedStyleNumberOfTimes = 0
    }
    
    func testNavigationShouldNotCallStyleManagerDidRefreshAppearanceMoreThanOnceWithTwoStyles() {
        let options = NavigationOptions(styles: [DayStyle(), NightStyle()], navigationService: dependencies.navigationService, voiceController: dependencies.voice)
        let navigationViewController = NavigationViewController(for: initialRoute, routeIndex: 0, routeOptions: routeOptions, navigationOptions: options)
        let service = dependencies.navigationService
        _ = navigationViewController.view // trigger view load

        navigationViewController.styleManager.delegate = self
        
        let someLocation = dependencies.poi.first!
        
        let test: (Any) -> Void = { _ in service.locationManager!(service.locationManager, didUpdateLocations: [someLocation]) }
        
        (0...2).forEach(test)
        
        XCTAssertEqual(updatedStyleNumberOfTimes, 0, "The style should not be updated.")
        updatedStyleNumberOfTimes = 0
    }
    
    // Brief: navigationViewController(_:roadNameAt:) delegate method is implemented,
    //        with a blank road name (empty string) provided and wayNameView label is hidden.
    // NOTE: disabled due to failing.
    func disabled_testNavigationViewControllerDelegateRoadNameAtLocationEmptyString() {
        let navigationViewController = dependencies.navigationViewController
        let service = dependencies.navigationService

        // Submit nonEmptry road location first to switch wayNameView to visibleState
        customRoadName[dependencies.poi[0].coordinate] = "Taylor Swift Street"
        service.locationManager!(service.locationManager, didUpdateLocations: [dependencies.poi[0]])
        XCTAssertFalse(navigationViewController.navigationView.wayNameView.isHidden)

        // Set empty road to make sure that it becomes hidden
        // Identify a location to set the custom road name.
        let turkStreetLocation = dependencies.poi[1]
        let roadName = ""
        customRoadName[turkStreetLocation.coordinate] = roadName
        
        service.locationManager!(service.locationManager, didUpdateLocations: [turkStreetLocation])

        waitForExpectations(timeout: 10, handler: nil)
        
        let wayNameView = navigationViewController.navigationView.wayNameView
        XCTAssertTrue(wayNameView.isHidden, "WayNameView should be hidden.")
    }
    
    func disabled_testNavigationViewControllerDelegateRoadNameAtLocationUmimplemented() {
        let navigationViewController = dependencies.navigationViewController
        UIApplication.shared.delegate!.window!!.addSubview(navigationViewController.view)
        let service = dependencies.navigationService
        
        // Identify a location without a custom road name.
        let fultonStreetLocation = dependencies.poi[2]

        navigationViewController.ornamentsController!.labelRoadNameCompletionHandler = { (defaultRoadNameAssigned) in
            XCTAssertTrue(defaultRoadNameAssigned, "label road name was not successfully set")
        }
        
        service.locationManager!(service.locationManager, didUpdateLocations: [fultonStreetLocation])
    }
    
    func testDestinationAnnotationUpdatesUponReroute() {
        let service = MapboxNavigationService(route: initialRoute, routeIndex: 0, routeOptions: routeOptions,  directions: DirectionsSpy(), simulating: .never)
        let options = NavigationOptions(styles: [TestableDayStyle()], navigationService: service)
        let navigationViewController = NavigationViewController(for: initialRoute, routeIndex: 0, routeOptions: routeOptions, navigationOptions: options)
        let styleLoadedExpectation = XCTestExpectation(description: "MapView style loading expectation.")
        navigationViewController.navigationMapView?.mapView.mapboxMap.onNext(.styleLoaded) { _ in
            styleLoadedExpectation.fulfill()
        }
        
        // Wait for the style to load - routes won't show without it.
        wait(for: [styleLoadedExpectation], timeout: 5)
        navigationViewController.indexedRoute = (initialRoute, 0)

        runUntil({
            return !navigationViewController.navigationMapView!.pointAnnotationManager!.annotations.isEmpty
        })
        
        let annotations = navigationViewController.navigationMapView!.pointAnnotationManager!.annotations

        guard let firstDestination = initialRoute.legs.last?.destination?.coordinate else {
            return XCTFail("PointAnnotation is not valid.")
        }



        XCTAssert(annotations
                    .compactMap { $0.feature.geometry.value as? Turf.Point }
                    .contains { $0.coordinates.distance(to: firstDestination) < 1 },
                  "Destination annotation does not exist on map")
        
        // Set the second route.
        navigationViewController.indexedRoute = (newRoute, 0)
        
        let newAnnotations = navigationViewController.navigationMapView!.pointAnnotationManager!.annotations
        
        guard let secondDestination = newRoute.legs.last?.destination?.coordinate else {
            return XCTFail("PointAnnotation is not valid.")
        }
        
        // Verify that there is a destination on the second route.
        XCTAssert(newAnnotations
                    .compactMap { $0.feature.geometry.value as? Turf.Point }
                    .contains { $0.coordinates.distance(to: secondDestination) < 1 },
                  "New destination annotation does not exist on map")
    }
    
    func testPuck3DLayerPosition() {
        let service = MapboxNavigationService(route: initialRoute, routeIndex: 0, routeOptions: routeOptions,  directions: DirectionsSpy(), simulating: .never)
        let options = NavigationOptions(styles: [TestableDayStyle()], navigationService: service)
        let navigationViewController = NavigationViewController(for: initialRoute, routeIndex: 0, routeOptions: routeOptions, navigationOptions: options)
        
        let model = MapboxMaps.Model()
        let puck3DConfiguration = Puck3DConfiguration(model: model)
        navigationViewController.navigationMapView?.userLocation = .puck3D(configuration: puck3DConfiguration)
        let styleLoadedExpectation = XCTestExpectation(description: "MapView style loading expectation.")
        navigationViewController.navigationMapView?.mapView.mapboxMap.onNext(.styleLoaded) { _ in
            styleLoadedExpectation.fulfill()
        }
        
        navigationViewController.navigationMapView?.addArrow(route: initialRoute, legIndex: 0, stepIndex: 0)
        let allLayerIds = navigationViewController.navigationMapView?.mapView.mapboxMap.style.allLayerIdentifiers.map{ $0.id }
        let indexOfArrowLayer = allLayerIds.index(of: NavigationMapView.LayerIdentifier.arrowLayer)
        let indexOfArrowStrokeLayer = allLayerIds.index(of: NavigationMapView.LayerIdentifier.arrowStrokeLayer)
        let indexOfArrowSymbolLayer = allLayerIds.index(of: NavigationMapView.LayerIdentifier.arrowSymbolLayer)
        let indexOfPuck3DLayer = allLayerIds.index(of: NavigationMapView.LayerIdentifier.puck3DLayer)
        
        XCTAssertNotNil(indexOfArrowStrokeLayer, "Arrow stroke layer failed to be added")
        XCTAssert(indexOfArrowStrokeLayer < indexOfArrowLayer, "Arrow layer is below arrow stroke layer")
        XCTAssert(indexOfArrowLayer < indexOfArrowSymbolLayer, "Arrow symbol layer is below arrow layer")
        XCTAssert(indexOfArrowSymbolLayer < indexOfPuck3DLayer, "Puck 3D layer is below arrow symbol layer")
    }
    
    func testBlankBanner() {
        let window = UIApplication.shared.keyWindow!
        let viewController = window.rootViewController!
        
        let options = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 38.853108, longitude: -77.043331),
            CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906),
        ])
        
        let route = Fixture.route(from: "DCA-Arboretum", options: options)
        let navigationViewController = NavigationViewController(for: route, routeIndex: 0, routeOptions: options)
        
        viewController.present(navigationViewController, animated: false, completion: nil)
        
        let firstInstruction = route.legs[0].steps[0].instructionsDisplayedAlongStep!.first
        let topViewController = navigationViewController.topViewController as! TopBannerViewController
        let instructionsBannerView = topViewController.instructionsBannerView
        
        XCTAssertNotNil(instructionsBannerView.primaryLabel.text)
        XCTAssertEqual(instructionsBannerView.primaryLabel.text, firstInstruction?.primaryInstruction.text)
        
        let dismissExpectation = XCTestExpectation(description: "VC should be dismissed")
        navigationViewController.dismiss(animated: false) {
            dismissExpectation.fulfill()
        }
        
        wait(for: [dismissExpectation], timeout: 3)
    }
    
    func testBannerInjection() {
        class BottomBannerFake: ContainerViewController { }
        class TopBannerFake: ContainerViewController { }
        
        let top = TopBannerFake(nibName: nil, bundle: nil)
        let bottom = BottomBannerFake(nibName: nil, bundle: nil)

        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 38.853108, longitude: -77.043331),
            CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906),
        ])

        let route = Fixture.route(from: "DCA-Arboretum", options: routeOptions)
        let navService = MapboxNavigationService(route: route, routeIndex: 0, routeOptions: routeOptions, directions: .mocked)
        let navOptions = NavigationOptions(navigationService: navService, topBanner: top, bottomBanner: bottom)

        let subject = NavigationViewController(for: route, routeIndex: 0, routeOptions: routeOptions, navigationOptions: navOptions)
        _ = subject.view // trigger view load
        XCTAssert(subject.topViewController == top, "Top banner not injected properly into NVC")
        XCTAssert(subject.bottomViewController == bottom, "Bottom banner not injected properly into NVC")
        XCTAssert(subject.children.contains(top), "Top banner not found in child VC heirarchy")
        XCTAssert(subject.children.contains(bottom), "Bottom banner not found in child VC heirarchy")
    }
}

extension NavigationViewControllerTests: NavigationViewControllerDelegate, StyleManagerDelegate {
    
    func location(for styleManager: MapboxNavigation.StyleManager) -> CLLocation? {
        return dependencies.poi.first!
    }
    
    func styleManagerDidRefreshAppearance(_ styleManager: MapboxNavigation.StyleManager) {
        updatedStyleNumberOfTimes += 1
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, roadNameAt location: CLLocation) -> String? {
        return customRoadName[location.coordinate] ?? nil
    }
}

extension CLLocationCoordinate2D: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
    
    static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension NavigationViewControllerTests {
    fileprivate func location(at coordinate: CLLocationCoordinate2D) -> CLLocation {
        return CLLocation(coordinate: coordinate,
                          altitude: 5,
                          horizontalAccuracy: 10,
                          verticalAccuracy: 5,
                          course: 20,
                          speed: 15,
                          timestamp: Date())
    }
}
