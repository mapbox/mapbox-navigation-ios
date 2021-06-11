import XCTest
import MapboxDirections
import Turf
import MapboxMaps
@testable import TestHelper
@testable import MapboxCoreNavigation
@testable import MapboxNavigation

let otherResponse = Fixture.JSONFromFileNamed(name: "route-for-lane-testing")

class NavigationViewControllerTests: XCTestCase {
    var customRoadName = [CLLocationCoordinate2D: String?]()
    
    var updatedStyleNumberOfTimes = 0
    lazy var dependencies: (navigationViewController: NavigationViewController, navigationService: NavigationService, startLocation: CLLocation, poi: [CLLocation], endLocation: CLLocation, voice: RouteVoiceController) = {
        let fakeDirections = DirectionsSpy()
        let fakeService = MapboxNavigationService(route: initialRoute, routeIndex: 0, routeOptions: routeOptions, directions: fakeDirections, locationSource: NavigationLocationManagerStub(), simulating: .never)
        let fakeVoice: RouteVoiceController = RouteVoiceControllerStub(navigationService: fakeService)
        let options = NavigationOptions(navigationService: fakeService, voiceController: fakeVoice)
        let navigationViewController = NavigationViewController(for: initialRoute, routeIndex: 0, routeOptions: routeOptions, navigationOptions: options)
        
        navigationViewController.delegate = self
        
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
    
    lazy var initialRoute: Route = {
        return Fixture.route(from: jsonFileName, options: routeOptions)
    }()
    
    lazy var newRoute: Route = {
        return Fixture.route(from: jsonFileName, options: routeOptions)
    }()
    
    override func setUp() {
        super.setUp()
        customRoadName.removeAll()
        ResourceOptionsManager.default.resourceOptions.accessToken = .mocked
    }
    
    func testDefaultUserInterfaceUsage() {
        let navigationViewController = dependencies.navigationViewController
        let service = dependencies.navigationService
        XCTAssertTrue(service.eventsManager.usesDefaultUserInterface, "MapboxNavigationTests should run inside the Example application target.")
    }
    
    // Brief: navigationViewController(_:roadNameAt:) delegate method is implemented,
    //        with a road name provided and wayNameView label is visible.
    func testNavigationViewControllerDelegateRoadNameAtLocationImplemented() {
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
        navigationViewController.styleManager.delegate = self
        
        let someLocation = dependencies.poi.first!
        
        let test: (Any) -> Void = { _ in service.locationManager!(service.locationManager, didUpdateLocations: [someLocation]) }
        
        (0...2).forEach(test)
        
        XCTAssertEqual(updatedStyleNumberOfTimes, 0, "The style should not be updated.")
        updatedStyleNumberOfTimes = 0
    }
    
    func testCompleteRoute() {
        let deps = dependencies
        let navigationViewController = deps.navigationViewController
        let service = deps.navigationService
        
        let delegate = NavigationServiceDelegateSpy()
        service.delegate = delegate
        
        let rootViewController = UIApplication.shared.delegate!.window!!.rootViewController!
        rootViewController.present(navigationViewController, animated: false, completion: nil)
        
        let now = Date()
        let rawLocations = Fixture.generateTrace(for: initialRoute)
        let locations = rawLocations.enumerated().map { $0.element.shifted(to: now + $0.offset) }
        
        for location in locations {
            service.locationManager!(service.locationManager, didUpdateLocations: [location])
        }
        
        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:willArriveAt:after:distance:)"), "Pre-arrival delegate message not fired.")
        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:didArriveAt:)"))
        
        let dismissExpectation = XCTestExpectation(description: "VC should be dismissed")
        navigationViewController.dismiss(animated: false) {
            dismissExpectation.fulfill()
        }
        
        wait(for: [dismissExpectation], timeout: 3)
    }
    
    // If tunnel flags are enabled and we need to switch styles, we should not force refresh the map style because we have only 1 style.
    func testNavigationShouldNotCallStyleManagerDidRefreshAppearanceWhenOnlyOneStyle() {
        let options = NavigationOptions(styles:[NightStyle()], navigationService: dependencies.navigationService, voiceController: dependencies.voice)
        let navigationViewController = NavigationViewController(for: initialRoute, routeIndex: 0, routeOptions: routeOptions, navigationOptions: options)
        let service = dependencies.navigationService
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
        navigationViewController.styleManager.delegate = self
        
        let someLocation = dependencies.poi.first!
        
        let test: (Any) -> Void = { _ in service.locationManager!(service.locationManager, didUpdateLocations: [someLocation]) }
        
        (0...2).forEach(test)
        
        XCTAssertEqual(updatedStyleNumberOfTimes, 0, "The style should not be updated.")
        updatedStyleNumberOfTimes = 0
    }
    
    // Brief: navigationViewController(_:roadNameAt:) delegate method is implemented,
    //        with a blank road name (empty string) provided and wayNameView label is hidden.
    func testNavigationViewControllerDelegateRoadNameAtLocationEmptyString() {
        let navigationViewController = dependencies.navigationViewController
        let service = dependencies.navigationService
        
        // Identify a location to set the custom road name.
        let turkStreetLocation = dependencies.poi[1]
        let roadName = ""
        customRoadName[turkStreetLocation.coordinate] = roadName
        
        service.locationManager!(service.locationManager, didUpdateLocations: [turkStreetLocation])
        
        let wayNameView = navigationViewController.navigationView.wayNameView
        guard let currentRoadName = wayNameView.text else {
            XCTFail("UI Failed to consume progress update. The chain from location update -> progress update generation -> progress update consumption is broken somewhere.")
            return
        }
        XCTAssertEqual(currentRoadName, roadName, "Expected: \(roadName); Actual: \(String(describing:currentRoadName))")
        XCTAssertTrue(wayNameView.isHidden, "WayNameView should be hidden.")
    }
    
    func testNavigationViewControllerDelegateRoadNameAtLocationUmimplemented() {
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
            return !navigationViewController.navigationMapView!.pointAnnotationManager.annotations.annotations.isEmpty
        })
        
        let annotations = navigationViewController.navigationMapView!.pointAnnotationManager.annotations.compactMap({ $0.value as? PointAnnotation })

        guard let firstDestination = initialRoute.legs.last?.destination?.coordinate else {
            return XCTFail("PointAnnotation is not valid.")
        }
        
        XCTAssert(annotations.contains { $0.coordinate.distance(to: firstDestination) < 1 }, "Destination annotation does not exist on map")
        
        // Set the second route.
        navigationViewController.indexedRoute = (newRoute, 0)
        
        let newAnnotations = navigationViewController.navigationMapView!.pointAnnotationManager.annotations.compactMap({ $0.value as? PointAnnotation })
        
        guard let secondDestination = newRoute.legs.last?.destination?.coordinate else {
            return XCTFail("PointAnnotation is not valid.")
        }
        
        // Verify that there is a destination on the second route.
        XCTAssert(newAnnotations.contains { $0.coordinate.distance(to: secondDestination) < 1 }, "New destination annotation does not exist on map")
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
