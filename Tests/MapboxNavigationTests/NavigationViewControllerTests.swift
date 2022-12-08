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
/// In order to fix the crash we mock `UNUserNotificationCenter` by swizzling `UNUserNotificationCenter.current()` and
/// return the instance of this class instead.
/// If you see that tests crash due to the unrecognized selector error to MockedUNUserNotificationCenter,
/// write a mock version of this test and try again.
@objc private final class MockedUNUserNotificationCenter: NSObject {
    /// Indicates if `UNUserNotificationCenter` is swapped with this mock.
    fileprivate static var isMocked: Bool = false
    @objc private func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
    @objc private func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
}

extension UNUserNotificationCenter {
    static func replaceWithMock() {
        guard !MockedUNUserNotificationCenter.isMocked else { return }
        MockedUNUserNotificationCenter.isMocked = true
        swapMethodsForMock()
    }

    static func removeMock() {
        guard MockedUNUserNotificationCenter.isMocked else { return }
        MockedUNUserNotificationCenter.isMocked = false
        swapMethodsForMock()
    }

    private static func swapMethodsForMock() {
        method_exchangeImplementations(
            class_getClassMethod(UNUserNotificationCenter.self,
                                 #selector(UNUserNotificationCenter.current))!,
            class_getClassMethod(UNUserNotificationCenter.self,
                                 #selector(UNUserNotificationCenter.swizzled_current))!
        )
    }

    @objc static func swizzled_current() -> AnyObject {
        return mockedUNUserNotificationCenter
    }
}

class NavigationViewControllerTests: TestCase {
    var customRoadName = [CLLocationCoordinate2D: String?]()
    
    var updatedStyleNumberOfTimes = 0
    var initialRoute: Route!
    var initialRouteResponse: IndexedRouteResponse!
    
    var newRoute: Route!
    var newRouteResponse: RouteResponse!
    
    override func setUp() {
        super.setUp()
        UNUserNotificationCenter.replaceWithMock()
        customRoadName.removeAll()
        initialRoute = Fixture.route(from: jsonFileName, options: routeOptions)
        initialRouteResponse = IndexedRouteResponse(routeResponse: Fixture.routeResponse(from: jsonFileName, options: routeOptions),
                                                    routeIndex: 0)
        newRoute = Fixture.route(from: "route-with-banner-instructions", options: routeOptions)
        newRouteResponse = Fixture.routeResponse(from: "route-with-banner-instructions", options: routeOptions)
    }

    private func createDependencies() -> (navigationViewController: NavigationViewController, navigationService: NavigationService, startLocation: CLLocation, poi: [CLLocation], endLocation: CLLocation, voice: RouteVoiceController)? {
        return {
            let fakeService = MapboxNavigationService(indexedRouteResponse: initialRouteResponse,
                                                      customRoutingProvider: MapboxRoutingProvider(.offline),
                                                      credentials: Fixture.credentials,
                                                      locationSource: NavigationLocationManagerStub(),
                                                      simulating: .never)
            let fakeVoice: RouteVoiceController = RouteVoiceControllerStub(navigationService: fakeService)
            let options = NavigationOptions(navigationService: fakeService, voiceController: fakeVoice)
            let navigationViewController = NavigationViewController(for: initialRouteResponse, navigationOptions: options)

            navigationViewController.delegate = self
            _ = navigationViewController.view // trigger view load
            guard let navigationService = navigationViewController.navigationService else {
                XCTFail("Navigation Service is nil"); return nil
            }
            let router = navigationService.router
            router.reroutesProactively = false
            guard let firstCoord = router.routeProgress.nearbyShape.coordinates.first else {
                XCTFail("First Coordinate is nil"); return nil
            }
            let firstLocation = location(at: firstCoord)

            var poi = [CLLocation]()
            guard let taylorStreetIntersection = router.route.legs.first?.steps.first?.intersections?.first else {
                XCTFail("Taylor Street Intersection is nil"); return nil
            }
            guard let turkStreetIntersection = router.route.legs.first?.steps[3].intersections?.first else {
                XCTFail("Turk Street Intersection is nil"); return nil
            }
            guard let fultonStreetIntersection = router.route.legs.first?.steps[5].intersections?.first else {
                XCTFail("Fulton Street Intersection is nil"); return nil
            }

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
        initialRouteResponse = nil
        newRoute = nil
        newRouteResponse = nil
        UNUserNotificationCenter.removeMock()
    }
    
    func testDefaultUserInterfaceUsage() {
        guard let dependencies = createDependencies() else { XCTFail("Dependencies are nil"); return }
        let navigationViewController = dependencies.navigationViewController
        XCTAssertTrue(Bundle.usesDefaultUserInterface, "MapboxNavigationTests should run inside the Example application target.")
        _ = navigationViewController
    }
    
    // Brief: navigationViewController(_:roadNameAt:) delegate method is implemented,
    //        with a road name provided and wayNameView label is visible.
    func testNavigationViewControllerDelegateRoadNameAtLocationImplemented() {
        guard let dependencies = createDependencies() else { XCTFail("Dependencies are nil"); return }
        let navigationViewController = dependencies.navigationViewController
        let service = dependencies.navigationService
        
        // Identify a location to set the custom road name.
        let taylorStreetLocation = dependencies.poi.first!
        let roadName = "Taylor Swift Street"
        customRoadName[taylorStreetLocation.coordinate] = roadName
        
        service.locationManager!(service.locationManager, didUpdateLocations: [taylorStreetLocation])
        expectation(description: "Road name is \(roadName)") {
            navigationViewController.navigationView.wayNameView.text == roadName
        }
        expectation(description: "WayNameView is visible") {
            navigationViewController.navigationView.wayNameView.containerView.isHidden == false
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testNavigationShouldNotCallStyleManagerDidRefreshAppearanceMoreThanOnceWithOneStyle() {
        guard let dependencies = createDependencies() else { XCTFail("Dependencies are nil"); return }
        let options = NavigationOptions(styles: [DayStyle()], navigationService: dependencies.navigationService, voiceController: dependencies.voice)
        let navigationViewController = NavigationViewController(for: initialRouteResponse, navigationOptions: options)
        let service = dependencies.navigationService
        _ = navigationViewController.view // trigger view load
        navigationViewController.styleManager.delegate = self
        
        let someLocation = dependencies.poi.first!
        
        let test: (Any) -> Void = { _ in service.locationManager!(service.locationManager, didUpdateLocations: [someLocation]) }
        
        (0...2).forEach(test)
        
        XCTAssertEqual(updatedStyleNumberOfTimes, 0, "The style should not be updated.")
        updatedStyleNumberOfTimes = 0
    }

    func testCompleteRoute() {
        guard let dependencies = createDependencies() else { XCTFail("Dependencies are nil"); return }
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
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))
        }

        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:willArriveAt:after:distance:)"), "Pre-arrival delegate message not fired.")
        XCTAssertTrue(delegate.recentMessages.contains("navigationService(_:didArriveAt:)"))
    }
    
    // If tunnel flags are enabled and we need to switch styles, we should not force refresh the map style because we have only 1 style.
    func testNavigationShouldNotCallStyleManagerDidRefreshAppearanceWhenOnlyOneStyle() {
        guard let dependencies = createDependencies() else { XCTFail("Dependencies are nil"); return }
        let options = NavigationOptions(styles:[NightStyle()], navigationService: dependencies.navigationService, voiceController: dependencies.voice)
        let navigationViewController = NavigationViewController(for: initialRouteResponse, navigationOptions: options)
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
        guard let dependencies = createDependencies() else { XCTFail("Dependencies are nil"); return }
        let options = NavigationOptions(styles: [DayStyle(), NightStyle()], navigationService: dependencies.navigationService, voiceController: dependencies.voice)
        let navigationViewController = NavigationViewController(for: initialRouteResponse, navigationOptions: options)
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
    func testNavigationViewControllerDelegateRoadNameAtLocationEmptyString() {
        guard let dependencies = createDependencies() else { XCTFail("Dependencies are nil"); return }
        let navigationViewController = dependencies.navigationViewController
        let service = dependencies.navigationService

        // Submit non-empty road location first to switch wayNameView to visible state
        customRoadName[dependencies.poi[0].coordinate] = "Taylor Swift Street"
        service.locationManager!(service.locationManager, didUpdateLocations: [dependencies.poi[0]])
        expectation {
            !navigationViewController.navigationView.wayNameView.containerView.isHidden
        }
        waitForExpectations(timeout: 3, handler: nil)

        // Set empty road to make sure that it becomes hidden
        // Identify a location to set the custom road name.
        let turkStreetLocation = dependencies.poi[1]
        let roadName = ""
        customRoadName[turkStreetLocation.coordinate] = roadName
        
        service.locationManager!(service.locationManager, didUpdateLocations: [turkStreetLocation])
        expectation {
            navigationViewController.navigationView.wayNameView.containerView.isHidden
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
    
    func testNavigationViewControllerDelegateRoadNameAtLocationUmimplemented() {
        guard let dependencies = createDependencies() else { XCTFail("Dependencies are nil"); return }
        let navigationViewController = dependencies.navigationViewController
        _ = navigationViewController.view // trigger view load
        let service = dependencies.navigationService
        
        // Identify a location without a custom road name.
        let fultonStreetLocation = dependencies.poi[2]

        navigationViewController.ornamentsController!.labelRoadNameCompletionHandler = { (defaultRoadNameAssigned) in
            XCTAssertTrue(defaultRoadNameAssigned, "label road name was not successfully set")
        }
        
        service.locationManager!(service.locationManager, didUpdateLocations: [fultonStreetLocation])
    }
    
    func testDestinationAnnotationUpdatesUponReroute() {
        let service = MapboxNavigationService(indexedRouteResponse: initialRouteResponse,
                                              customRoutingProvider: MapboxRoutingProvider(.offline),
                                              credentials: Fixture.credentials,
                                              simulating: .never)
        let options = NavigationOptions(styles: [TestableDayStyle()], navigationService: service)
        let navigationViewController = NavigationViewController(for: initialRouteResponse, navigationOptions: options)
        expectation(description: "Style Loaded") {
            navigationViewController.navigationMapView?.pointAnnotationManager != nil
        }
        waitForExpectations(timeout: 5, handler: nil)
        navigationViewController.navigationService.router
            .updateRoute(with: initialRouteResponse, routeOptions: nil) {
                success in
                XCTAssertTrue(success)
                XCTAssertFalse(navigationViewController.navigationMapView!.pointAnnotationManager!.annotations.isEmpty)
            }
        XCTAssertEqual(navigationViewController.routeResponse.identifier, initialRouteResponse.routeResponse.identifier)

        let annotations = navigationViewController.navigationMapView!.pointAnnotationManager!.annotations

        guard let firstDestination = initialRoute.legs.last?.destination?.coordinate else {
            return XCTFail("PointAnnotation is not valid.")
        }

        XCTAssert(annotations.contains { $0.point.coordinates.distance(to: firstDestination) < 1 },
                  "Destination annotation does not exist on map")

        let routeUpdated = expectation(description: "Route updated")
        // Set the second route.
        navigationViewController.navigationService.router
            .updateRoute(with: .init(routeResponse: newRouteResponse, routeIndex: 0), routeOptions: nil) { success in
                XCTAssertTrue(success)
                routeUpdated.fulfill()
            }
        wait(for: [routeUpdated], timeout: 5)
        let newAnnotations = navigationViewController.navigationMapView!.pointAnnotationManager!.annotations
        
        guard let secondDestination = newRoute.legs.last?.destination?.coordinate else {
            return XCTFail("PointAnnotation is not valid.")
        }
        
        // Verify that there is a destination on the second route.
        XCTAssert(newAnnotations.contains { $0.point.coordinates.distance(to: secondDestination) < 1 },
                  "New destination annotation does not exist on map")
        XCTAssertEqual(navigationViewController.routeResponse.identifier,
                       newRouteResponse.identifier)
    }
    
    func testBlankBanner() {
        let options = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 38.853108, longitude: -77.043331),
            CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906),
        ])
        
        let routeResponse = IndexedRouteResponse(routeResponse:  Fixture.routeResponse(from: "DCA-Arboretum", options: options),
                                                 routeIndex: 0)
        let navigationViewController = NavigationViewController(for: routeResponse)
        
        _ = navigationViewController.view
        
        let firstInstruction = navigationViewController.route!.legs[0].steps[0].instructionsDisplayedAlongStep!.first
        let topViewController = navigationViewController.topViewController as! TopBannerViewController
        let instructionsBannerView = topViewController.instructionsBannerView
        
        XCTAssertNotNil(instructionsBannerView.primaryLabel.text)
        XCTAssertEqual(instructionsBannerView.primaryLabel.text, firstInstruction?.primaryInstruction.text)
    }
    
    func testBannerInjection() {
        class BottomBannerFake: ContainerViewController { }
        class TopBannerFake: ContainerViewController { }
        
        let top = TopBannerFake(nibName: nil, bundle: nil)
        let bottom = BottomBannerFake(nibName: nil, bundle: nil)

        let navService = MapboxNavigationService(indexedRouteResponse: initialRouteResponse,
                                                 customRoutingProvider: nil,
                                                 credentials: Fixture.credentials)
        let navOptions = NavigationOptions(navigationService: navService, topBanner: top, bottomBanner: bottom)

        let subject = NavigationViewController(for: initialRouteResponse, navigationOptions: navOptions)
        _ = subject.view // trigger view load
        XCTAssert(subject.topViewController == top, "Top banner not injected properly into NVC")
        XCTAssert(subject.bottomViewController == bottom, "Bottom banner not injected properly into NVC")
        XCTAssert(subject.children.contains(top), "Top banner not found in child VC heirarchy")
        XCTAssert(subject.children.contains(bottom), "Bottom banner not found in child VC heirarchy")
    }
    
    func testNavigationMapViewInjection() {
        class CustomNavigationMapView: NavigationMapView { }
        
        let injected = CustomNavigationMapView()
        
        let navService = MapboxNavigationService(indexedRouteResponse: initialRouteResponse,
                                                 customRoutingProvider: nil,
                                                 credentials: Fixture.credentials)
        let navOptions = NavigationOptions(navigationService: navService, navigationMapView: injected)

        let subject = NavigationViewController(for: initialRouteResponse, navigationOptions: navOptions)
        _ = subject.view // trigger view load
        
        XCTAssert(subject.navigationMapView == injected, "NavigtionMapView not injected properly.")
        XCTAssert(subject.view.subviews.contains(injected), "NavigtionMapView not injected in view hierarchy.")
    }
    
    func navigationViewControllerMock() -> NavigationViewController {
        let navigationService = MapboxNavigationService(indexedRouteResponse: initialRouteResponse,
                                                        customRoutingProvider: nil,
                                                        credentials: Fixture.credentials)
        
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        
        let navigationViewController = NavigationViewController(for: initialRouteResponse,
                                                                navigationOptions: navigationOptions)
        
        return navigationViewController
    }
    
    func testShowsReportFeedback() {
        let navigationViewController = navigationViewControllerMock()
        
        XCTAssertEqual(navigationViewController.showsReportFeedback,
                       true,
                       "Button that allows drivers to report feedback should be shown by default.")
        
        navigationViewController.showsReportFeedback = false
        
        XCTAssertEqual(navigationViewController.showsReportFeedback,
                       false,
                       "Button that allows drivers to report feedback should not be shown.")
    }
    
    func testShowsSpeedLimits() {
        let navigationViewController = navigationViewControllerMock()
        
        XCTAssertEqual(navigationViewController.showsSpeedLimits,
                       true,
                       "Speed limit should be shown by default.")
        
        navigationViewController.showsSpeedLimits = false
        
        XCTAssertEqual(navigationViewController.showsSpeedLimits,
                       false,
                       "Speed limit should not be shown.")
    }
    
    func testDetailedFeedbackEnabled() {
        let navigationViewController = navigationViewControllerMock()
        
        XCTAssertEqual(navigationViewController.detailedFeedbackEnabled,
                       false,
                       "Second level of detail for feedback items should not be enabled by default.")
        
        navigationViewController.showsSpeedLimits = true
        
        XCTAssertEqual(navigationViewController.showsSpeedLimits,
                       true,
                       "Second level of detail for feedback items should be enabled.")
    }
    
    func testFloatingButtonsPosition() {
        let navigationViewController = navigationViewControllerMock()
        
        XCTAssertEqual(navigationViewController.floatingButtonsPosition,
                       .topTrailing,
                       "The position of the floating buttons should be topTrailing by default.")
        
        navigationViewController.floatingButtonsPosition = .topLeading
        
        XCTAssertEqual(navigationViewController.floatingButtonsPosition,
                       .topLeading,
                       "The position of the floating buttons should be topLeading.")
    }
    
    func testFloatingButtons() {
        let navigationViewController = navigationViewControllerMock()
        
        XCTAssertEqual(navigationViewController.floatingButtons?.count,
                       3,
                       "There should be three floating buttons by default.")
        XCTAssertEqual(navigationViewController.floatingButtons?[0],
                       navigationViewController.overviewButton,
                       "Unexpected floating button.")
        XCTAssertEqual(navigationViewController.floatingButtons?[1],
                       navigationViewController.muteButton,
                       "Unexpected floating button.")
        XCTAssertEqual(navigationViewController.floatingButtons?[2],
                       navigationViewController.reportButton,
                       "Unexpected floating button.")
        
        navigationViewController.floatingButtons = []
        XCTAssertEqual(navigationViewController.floatingButtons?.count,
                       0,
                       "There should be zero floating buttons after modification.")
        
        let floatingButton = UIButton()
        navigationViewController.floatingButtons = [floatingButton]
        XCTAssertEqual(navigationViewController.floatingButtons?.count,
                       1,
                       "There should be one floating button after modification.")
        XCTAssertEqual(navigationViewController.floatingButtons?.first,
                       floatingButton,
                       "Unexpected floating button.")
    }
    
    func testShieldStyleWithNavigationMapViewInjection() {
        let nightStyleURI: StyleURI = .navigationNight
        let dayStyleURI: StyleURI = .navigationDay
        
        let spriteRepository = SpriteRepository.shared
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 1.0
        spriteRepository.sessionConfiguration = config
        
        let styleLoadedExpectation = XCTestExpectation(description: "Style updated expectation.")
        spriteRepository.updateStyle(styleURI: nightStyleURI) { _ in
            styleLoadedExpectation.fulfill()
        }
        wait(for: [styleLoadedExpectation], timeout: 2.0)
        XCTAssertEqual(spriteRepository.userInterfaceIdiomStyles[.phone],
                       nightStyleURI,
                       "Failed to update the style of SpriteRepository singleton to Night style.")
        
        class CustomNavigationMapView: NavigationMapView { }
        let injected = CustomNavigationMapView()
        injected.mapView.mapboxMap.style.uri = dayStyleURI
        
        let navService = MapboxNavigationService(indexedRouteResponse: initialRouteResponse,
                                                 customRoutingProvider: nil,
                                                 credentials: Fixture.credentials)
        let navOptions = NavigationOptions(styles: [DayStyle()],
                                           navigationService: navService,
                                           navigationMapView: injected)
        let subject = NavigationViewController(for: initialRouteResponse, navigationOptions: navOptions)
        _ = subject.view // trigger view load
        
        XCTAssert(subject.navigationMapView == injected, "NavigtionMapView not injected properly.")
        XCTAssertEqual(injected.mapView.mapboxMap.style.uri?.rawValue,
                       subject.styleManager.currentStyle?.mapStyleURL.absoluteString,
                       "Failed to apply the style to NavigationViewController.")
        XCTAssertEqual(spriteRepository.userInterfaceIdiomStyles[.phone],
                       dayStyleURI,
                       "Failed to update the style of SpriteRepository singleton with the injected NavigationMapView.")
    }
    
    func testAnnotatesIntersectionsAlongRoute() {
        let navigationViewController = navigationViewControllerMock()
        let imageIdentifier = NavigationMapView.ImageIdentifier.trafficSignal
        let layerIdentifier = NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer
        let sourceIdentifier = NavigationMapView.SourceIdentifier.intersectionAnnotationsSource
        
        guard let style = navigationViewController.navigationMapView?.mapView.mapboxMap.style else {
            XCTFail("Failed to get the MapView style object.")
            return
        }
        
        XCTAssertTrue(navigationViewController.annotatesIntersectionsAlongRoute)
        XCTAssertTrue(style.imageExists(withId: imageIdentifier))
        XCTAssertTrue(style.layerExists(withId: layerIdentifier))
        XCTAssertTrue(style.sourceExists(withId: sourceIdentifier))
        
        navigationViewController.annotatesIntersectionsAlongRoute = false
        XCTAssertTrue(style.imageExists(withId: imageIdentifier))
        XCTAssertFalse(style.layerExists(withId: layerIdentifier))
        XCTAssertFalse(style.sourceExists(withId: sourceIdentifier))
    }
    
    func testNavigationMapViewWillAddLayerDelegate() {
        guard let dependencies = createDependencies() else { XCTFail("Dependencies are nil"); return }
        
        class NavigationViewControllerDelegateMock: NavigationViewControllerDelegate {
            let expectedRouteLineOpacity: Double = 0.2
            let expectedRouteCasingOpacity: Double = 0.3
            let expectedRouteCasingWidth: Double = 10.0
            let expectedRestrictedLineOpacity: Double = 0.4
            
            func navigationViewController(_ navigationViewController: NavigationViewController, willAdd layer: Layer) -> Layer? {
                guard var lineLayer = layer as? LineLayer else { return nil }
                if lineLayer.id.contains("main.route_line") {
                    lineLayer.lineOpacity = .constant(expectedRouteLineOpacity)
                }
                if lineLayer.id.contains("main.route_line_casing") {
                    lineLayer.lineOpacity = .constant(expectedRouteCasingOpacity)
                    lineLayer.lineWidth = .constant(expectedRouteCasingWidth)
                }
                if lineLayer.id.contains("restricted_area_route_line") {
                    lineLayer.lineOpacity = .constant(expectedRestrictedLineOpacity)
                }
                return lineLayer
            }
        }
        
        let delegateMock = NavigationViewControllerDelegateMock()
        let navigationViewController = dependencies.navigationViewController
        navigationViewController.delegate = delegateMock
        navigationViewController.routeLineTracksTraversal = true // test the traversed route layer
        _ = navigationViewController.view // trigger view load
        
        guard let style = navigationViewController.navigationMapView?.mapView.mapboxMap.style else {
            XCTFail("Failed to get the MapView style object.")
            return
        }
        
        let route = dependencies.navigationService.route
        let routeIdentifier = route.identifier(.route(isMainRoute: true))
        let routeCasingIdentifier = route.identifier(.routeCasing(isMainRoute: true))
        let restrictedIdentifier = route.identifier(.restrictedRouteAreaRoute)
        let traversedIdentifier = route.identifier(.traversedRoute)
        navigationViewController.navigationMapView?.showsRestrictedAreasOnRoute = true
        navigationViewController.navigationMapView?.show([route])
        
        guard let routelineOpacity = style.layerPropertyValue(for: routeIdentifier, property: "line-opacity") as? Double,
              let routeCasingOpacity = style.layerPropertyValue(for: routeCasingIdentifier, property: "line-opacity") as? Double,
              let routeCasingWidth = style.layerPropertyValue(for: routeCasingIdentifier, property: "line-width") as? Double,
              let restrictedOpacity = style.layerPropertyValue(for: restrictedIdentifier, property: "line-opacity") as? Double,
              let traversedWidth = style.layerPropertyValue(for: traversedIdentifier, property: "line-width") as? Double else {
            XCTFail("Route line layers should all be present.")
            return
        }
        
        XCTAssertEqual(delegateMock.expectedRouteLineOpacity, routelineOpacity, accuracy: 1e-3, "Failed to customize route line layer through delegate.")
        XCTAssertEqual(delegateMock.expectedRouteCasingOpacity, routeCasingOpacity, accuracy: 1e-3, "Failed to customize route casing layer through delegate.")
        XCTAssertEqual(delegateMock.expectedRouteCasingWidth, routeCasingWidth, accuracy: 1e-3, "Failed to customize route casing layer through delegate.")
        XCTAssertEqual(delegateMock.expectedRestrictedLineOpacity, restrictedOpacity, accuracy: 1e-3, "Failed to customize route restricted area layer through delegate.")
        XCTAssertEqual(delegateMock.expectedRouteCasingWidth, traversedWidth, accuracy: 1e-3,
                       "The traversed route layer should have the same width as the main route casing layer.")
        XCTAssertNil(style.layerPropertyValue(for: traversedIdentifier, property: "line-opacity") as? Double,
                     "The traversed route layer shouldn't have other properties modified.")
    }
}

extension NavigationViewControllerTests: NavigationViewControllerDelegate, StyleManagerDelegate {
    
    func location(for styleManager: MapboxNavigation.StyleManager) -> CLLocation? {
        guard let dependencies = createDependencies() else { XCTFail("Dependencies are nil"); return nil }
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
