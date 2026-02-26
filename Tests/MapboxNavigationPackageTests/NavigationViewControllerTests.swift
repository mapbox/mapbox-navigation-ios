import Combine
import MapboxMaps
@testable import MapboxNavigationCore
@testable import MapboxNavigationUIKit
@testable import TestHelper
import Turf
import XCTest

private let mockedUNUserNotificationCenter: MockedUNUserNotificationCenter = .init()

/// `UNUserNotificationCenter.current()` crashes when run from SPM tests.
/// In order to fix the crash we mock `UNUserNotificationCenter` by swizzling `UNUserNotificationCenter.current()` and
/// return the instance of this class instead.
/// If you see that tests crash due to the unrecognized selector error to MockedUNUserNotificationCenter,
/// write a mock version of this test and try again.
@objc private final class MockedUNUserNotificationCenter: NSObject {
    /// Indicates if `UNUserNotificationCenter` is swapped with this mock.
    fileprivate static var isMocked: Bool = false
    @objc
    private func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {}
    @objc
    private func removeDeliveredNotifications(withIdentifiers identifiers: [String]) {}
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
            class_getClassMethod(
                UNUserNotificationCenter.self,
                #selector(UNUserNotificationCenter.current)
            )!,
            class_getClassMethod(
                UNUserNotificationCenter.self,
                #selector(UNUserNotificationCenter.swizzled_current)
            )!
        )
    }

    @objc
    static func swizzled_current() -> AnyObject {
        return mockedUNUserNotificationCenter
    }
}

class NavigationViewControllerTests: TestCase {
    class OrnamentsControllerSpy: OrnamentsController {
        var updateRoadNameCalled: ((RoadName?) -> Void)?

        init(_ controller: NavigationViewController) {
            let eventsManagerSpy = NavigationTelemetryManagerSpy()
            let eventsManager = NavigationEventsManager(navNativeEventsManager: eventsManagerSpy)
            super.init(controller, eventsManager: eventsManager)
            controller.ornamentsController = self
        }

        override func updateRoadNameFromStatus(_ roadName: RoadName?) {
            updateRoadNameCalled?(roadName)
        }
    }

    var styleRefreshedAppearanceExpectation: XCTestExpectation!

    var initialRoutes: NavigationRoutes!
    var newRoutes: NavigationRoutes!

    var routeProgressPublisher: CurrentValueSubject<RouteProgress?, Never>!

    var customRoadName: [CLLocationCoordinate2D: String?]!
    var poi: [CLLocation]!
    var subscriptions: Set<AnyCancellable>!
    var tunnelAuthority: TunnelAuthority!
    var isInTunnel: Bool!

    override func setUp() async throws {
        try await super.setUp()

        subscriptions = []
        initialRoutes = await Fixture.navigationRoutes(
            from: "routeWithInstructions",
            options: routeOptions
        )
        newRoutes = await Fixture.navigationRoutes(
            from: "route-with-banner-instructions",
            options: routeOptions
        )

        routeProgressPublisher = .init(nil)
        UNUserNotificationCenter.replaceWithMock()
        customRoadName = [:]
        isInTunnel = false
        tunnelAuthority = TunnelAuthority(isInTunnel: { _, _ in
            self.isInTunnel
        })

        poi = [CLLocation]()

        let currentLocation = locationPublisher.value
        let status = TestNavigationStatusProvider.createNavigationStatus(location: currentLocation)
        await navigationProvider.navigator().updateMapMatching(status: status)

        let route = initialRoutes.mainRoute.route
        guard let taylorStreetIntersection = route.legs.first?.steps.first?.intersections?.first else {
            XCTFail("Taylor Street Intersection is nil"); return
        }
        guard let turkStreetIntersection = route.legs.first?.steps[3].intersections?.first else {
            XCTFail("Turk Street Intersection is nil"); return
        }
        guard let fultonStreetIntersection = route.legs.first?.steps[5].intersections?.first else {
            XCTFail("Fulton Street Intersection is nil"); return
        }

        poi.append(location(at: taylorStreetIntersection.location))
        poi.append(location(at: turkStreetIntersection.location))
        poi.append(location(at: fultonStreetIntersection.location))
    }

    @MainActor
    private func createViewController(
        styles: [Style]? = nil,
        topBanner: ContainerViewController? = nil,
        bottomBanner: ContainerViewController? = nil,
        navigationMapView: NavigationMapView? = nil,
        styleManagerDelegate: StyleManagerDelegate? = nil,
        delegate: NavigationViewControllerDelegate? = nil,
        automaticallyAdjustsStyleForTimeOfDay: Bool = true,
        usesNightStyleInDarkMode: Bool = false,
        usesNightStyleWhileInTunnel: Bool = true
    ) -> NavigationViewController {
        return {
            let options = NavigationOptions(
                mapboxNavigation: navigationProvider.mapboxNavigation,
                voiceController: navigationProvider.routeVoiceController,
                eventsManager: navigationProvider.eventsManager(),
                styles: styles,
                topBanner: topBanner,
                bottomBanner: bottomBanner,
                navigationMapView: navigationMapView
            )
            let navigationViewController = NavigationViewController(
                navigationRoutes: initialRoutes,
                navigationOptions: options
            )

            navigationViewController.automaticallyAdjustsStyleForTimeOfDay = automaticallyAdjustsStyleForTimeOfDay
            navigationViewController.usesNightStyleInDarkMode = usesNightStyleInDarkMode
            navigationViewController.usesNightStyleWhileInTunnel = usesNightStyleWhileInTunnel

            navigationViewController.delegate = delegate ?? self
            _ = navigationViewController.view // trigger view load
            if let styleManagerDelegate {
                navigationViewController.styleManager.delegate = styleManagerDelegate
            }
            navigationViewController.tunnelAuthority = tunnelAuthority
            return navigationViewController
        }()
    }

    override func tearDown() {
        UNUserNotificationCenter.removeMock()
        super.tearDown()
    }

    // Brief: navigationViewController(_:roadNameAt:) delegate method is implemented,
    //        with a road name provided and wayNameView label is visible.
    @MainActor
    func testNavigationViewControllerDelegateRoadNameAtLocationImplemented() async {
        let navigationViewController = createViewController()
        let taylorStreetLocation = poi.first!
        let status = TestNavigationStatusProvider.createNavigationStatus(
            location: taylorStreetLocation
        )
        await navigationProvider.navigator().updateMapMatching(status: status)
        // Identify a location to set the custom road name.
        let roadName = "Taylor Swift Street"
        customRoadName[taylorStreetLocation.coordinate] = roadName

        let activeStatus = TestNavigationStatusProvider.createActiveStatus(
            location: taylorStreetLocation
        )
        let ornamentsControllerSpy = OrnamentsControllerSpy(navigationViewController)
        let expectation = XCTestExpectation(description: "WayNameView updated")
        ornamentsControllerSpy.updateRoadNameCalled = { passedRoadName in
            XCTAssertEqual(passedRoadName, .init(text: roadName, language: ""))
            expectation.fulfill()
        }
        await navigationProvider.navigator().updateMapMatching(status: activeStatus)

        await fulfillment(of: [expectation], timeout: 2)
    }

    @MainActor
    func testNavigationShouldNotCallStyleManagerDidRefreshAppearanceMoreThanOnceWithOneStyle() async {
        let navigationViewController = createViewController(
            styles: [DayStyle()],
            styleManagerDelegate: self
        )
        _ = navigationViewController.view
        let someLocation = poi.first!
        let test: (Any) -> Void = { _ in self.locationPublisher.send(someLocation) }

        styleRefreshedAppearanceExpectation = XCTestExpectation(description: "Navigation style refreshed.")
        styleRefreshedAppearanceExpectation.isInverted = true
        (0...2).forEach(test)

        await fulfillment(of: [styleRefreshedAppearanceExpectation], timeout: 0.5)
    }

    @MainActor
    func testCompleteRoute() async {
        let navigationProvider = navigationProvider!

        final class NavigationViewControllerDelegateMock: NavigationViewControllerDelegate {
            let didArriveExpectation = XCTestExpectation(description: "Navigation finished expectation.")

            func navigationViewController(
                _ navigationViewController: NavigationViewController,
                didArriveAt waypoint: Waypoint
            ) {
                didArriveExpectation.fulfill()
            }
        }
        let navigationViewController = createViewController()
        let delegate = NavigationViewControllerDelegateMock()
        navigationViewController.delegate = delegate

        _ = navigationViewController.view
        navigationViewController.viewWillAppear(false)
        navigationViewController.viewDidAppear(false)

        await completeLeg(in: initialRoutes, legIndex: 0)
        await fulfillment(of: [delegate.didArriveExpectation], timeout: 2)
    }

    @MainActor
    func testCompleteMultilegRoute() async {
        initialRoutes = await Fixture.navigationRoutes(from: "multileg-route", options: routeOptions3Waypoints)

        final class NavigationViewControllerDelegateMock: NavigationViewControllerDelegate {
            let didArriveToStopExpectation = XCTestExpectation(description: "Did arrive to the waypoint.")

            let didArriveToDestinationExpectation =
                XCTestExpectation(description: "Did arrive to the final destination.")

            let routes: NavigationRoutes
            init(routes: NavigationRoutes) {
                self.routes = routes
            }

            func navigationViewController(
                _ navigationViewController: NavigationViewController,
                didArriveAt waypoint: Waypoint
            ) {
                let route = routes.mainRoute.route
                if waypoint == route.legs[0].destination {
                    didArriveToStopExpectation.fulfill()
                } else if waypoint == route.legs[1].destination {
                    didArriveToDestinationExpectation.fulfill()
                }
            }
        }
        let navigationViewController = createViewController()
        let delegate = NavigationViewControllerDelegateMock(routes: initialRoutes)
        navigationViewController.delegate = delegate

        _ = navigationViewController.view
        navigationViewController.viewWillAppear(false)
        navigationViewController.viewDidAppear(false)

        await completeLeg(in: initialRoutes, legIndex: 0)
        await fulfillment(of: [delegate.didArriveToStopExpectation], timeout: 5)

        await completeLeg(in: initialRoutes, legIndex: 1)
        await fulfillment(of: [delegate.didArriveToDestinationExpectation], timeout: 5)
    }

    private func completeLeg(in routes: NavigationRoutes, legIndex: Int) async {
        let leg = routes.mainRoute.route.legs[legIndex]
        let locations = Fixture.generateTrace(for: leg.shape)
        for location in locations {
            let status = TestNavigationStatusProvider.createNavigationStatus(
                routeState: .tracking,
                location: location,
                routeIndex: 0,
                legIndex: UInt32(legIndex)
            )
            locationPublisher.send(location)
            await navigationProvider.navigator().updateMapMatching(status: status)
        }
        let finalStatus = TestNavigationStatusProvider.createActiveStatus(
            routeState: .complete,
            location: locations.last!,
            routeIndex: 0,
            legIndex: UInt32(legIndex),
            stepIndex: UInt32(leg.steps.count - 1)
        )
        await navigationProvider.navigator().updateIndices(status: finalStatus)
        var routeProgress = RouteProgress(
            navigationRoutes: initialRoutes,
            waypoints: routeOptions.waypoints,
            congestionConfiguration: .default
        )
        routeProgress.update(using: finalStatus)

        await navigationProvider.navigator().handleRouteProgressUpdates(
            status: finalStatus,
            routeProgress: routeProgress
        )
    }

    // If tunnel flags are enabled and we need to switch styles, we should not force refresh the map style because we
    // have only 1 style.
    @MainActor
    func testNavigationShouldNotCallStyleManagerDidRefreshAppearanceWhenOnlyOneStyle() async {
        isInTunnel = true
        let navigationViewController = createViewController(
            styles: [StandardNightStyle()],
            styleManagerDelegate: self
        )
        _ = navigationViewController.view

        let someLocation = poi.first!

        let test: (Any) -> Void = { _ in
            self.locationPublisher.send(someLocation)
            let status = TestNavigationStatusProvider.createNavigationStatus(
                location: someLocation
            )
            let userInfo = [NativeNavigator.NotificationUserInfoKey.statusKey: status]
            NotificationCenter.default.post(
                name: Notification.Name.navigationStatusDidChange,
                object: nil,
                userInfo: userInfo
            )
        }
        let navigationStartedExpectation = XCTestExpectation(description: "Navigation started expectation.")

        navigationProvider.tripSession().session
            .filter { $0.state != .idle }
            .first()
            .sink { _ in
                navigationStartedExpectation.fulfill()
            }
            .store(in: &subscriptions)
        await fulfillment(of: [navigationStartedExpectation], timeout: 1)
        styleRefreshedAppearanceExpectation = XCTestExpectation(description: "Navigation style refreshed.")
        styleRefreshedAppearanceExpectation.isInverted = true

        (0...2).forEach(test)
        await fulfillment(of: [styleRefreshedAppearanceExpectation], timeout: 0.5)
    }

    @MainActor
    func testNavigationShouldNotCallStyleManagerDidRefreshAppearanceMoreThanOnceWithTwoStyles() async {
        isInTunnel = true
        let navigationViewController = createViewController(
            styles: [DayStyle(), NightStyle()],
            styleManagerDelegate: self,
            automaticallyAdjustsStyleForTimeOfDay: false,
            usesNightStyleInDarkMode: false,
            usesNightStyleWhileInTunnel: true
        )

        _ = navigationViewController

        let someLocation = poi.first!

        let test: () -> Void = {
            self.locationPublisher.send(someLocation)
            let status = TestNavigationStatusProvider.createNavigationStatus(
                location: someLocation
            )
            let userInfo = [NativeNavigator.NotificationUserInfoKey.statusKey: status]
            NotificationCenter.default.post(
                name: Notification.Name.navigationStatusDidChange,
                object: nil,
                userInfo: userInfo
            )
        }
        let navigationStartedExpectation = XCTestExpectation(description: "Navigation started expectation.")

        navigationProvider.tripSession().session
            .filter { $0.state != .idle }
            .first()
            .sink { _ in
                navigationStartedExpectation.fulfill()
            }
            .store(in: &subscriptions)
        await fulfillment(of: [navigationStartedExpectation], timeout: 0.5)

        styleRefreshedAppearanceExpectation = XCTestExpectation(description: "Navigation style refreshed.")
        (0...2).forEach { _ in test() }

        await fulfillment(of: [styleRefreshedAppearanceExpectation], timeout: 0.5)
    }

    // Brief: navigationViewController(_:roadNameAt:) delegate method is implemented,
    //        with a blank road name (empty string) provided and wayNameView label is hidden.
    @MainActor
    func testNavigationViewControllerDelegateRoadNameAtLocationEmptyString() async {
        let navigationViewController = createViewController()
        let taylorStreetLocation = poi.first!
        let status = TestNavigationStatusProvider.createNavigationStatus(
            location: taylorStreetLocation
        )
        await navigationProvider.navigator().updateMapMatching(status: status)
        // Identify a location to set the custom road name.
        customRoadName[taylorStreetLocation.coordinate] = "Taylor Swift Street"

        let activeStatus = TestNavigationStatusProvider.createActiveStatus(
            location: taylorStreetLocation
        )
        let ornamentsControllerSpy = OrnamentsControllerSpy(navigationViewController)
        let expectation = XCTestExpectation(description: "WayNameView updated")
        ornamentsControllerSpy.updateRoadNameCalled = { passedRoadName in
            XCTAssertNotNil(passedRoadName)
            expectation.fulfill()
        }
        await navigationProvider.navigator().updateMapMatching(status: activeStatus)
        await fulfillment(of: [expectation], timeout: 2)

        // Set empty road to make sure that it becomes hidden
        // Identify a location to set the custom road name.
        let turkStreetLocation = poi[1]
        customRoadName[turkStreetLocation.coordinate] = ""

        let newActiveStatus = TestNavigationStatusProvider.createActiveStatus(
            location: turkStreetLocation
        )

        let roadNameIsNilExpectation = XCTestExpectation(description: "road name is nil")
        ornamentsControllerSpy.updateRoadNameCalled = { passedRoadName in
            XCTAssertNil(passedRoadName)
            roadNameIsNilExpectation.fulfill()
        }

        await navigationProvider.navigator().updateMapMatching(status: newActiveStatus)
        await fulfillment(of: [roadNameIsNilExpectation], timeout: 2)
    }

    @MainActor
    func testNavigationViewControllerDelegateRoadNameAtLocationUnimplemented() async {
        let navigationViewController = createViewController()
        _ = navigationViewController.view // trigger view load

        // Identify a location without a custom road name.
        let fultonStreetLocation = poi[2]
        let status = TestNavigationStatusProvider.createActiveStatus(location: fultonStreetLocation)

        let expectation = XCTestExpectation(description: "Road name is nil")
        let ornamentsControllerSpy = OrnamentsControllerSpy(navigationViewController)
        ornamentsControllerSpy.updateRoadNameCalled = { passedRoadName in
            XCTAssertNil(passedRoadName)
            expectation.fulfill()
        }
        await navigationProvider.navigator().updateMapMatching(status: status)
        await fulfillment(of: [expectation], timeout: 2)

        let roadName = "New street"
        let newStatus = TestNavigationStatusProvider.createActiveStatus(
            location: fultonStreetLocation,
            roads: [
                .init(text: roadName, language: "en", imageBaseUrl: nil, shield: nil),
            ]
        )
        let notNilxpectation = XCTestExpectation(description: "Road name is not nil")
        ornamentsControllerSpy.updateRoadNameCalled = { passedRoadName in
            XCTAssertEqual(passedRoadName, .init(text: roadName, language: "en"))
            notNilxpectation.fulfill()
        }
        await navigationProvider.navigator().updateMapMatching(status: newStatus)
        await fulfillment(of: [notNilxpectation], timeout: 2)
    }

    // TODO:
//    @MainActor
//    func disabled_testBlankBanner() async {
//        let coordinate = initialRoutes.mainRoute.route.shape!.coordinates.first!
//        let status = TestNavigationStatusProvider.createNavigationStatus(
//            location: .init(coordinate: coordinate)
//        )
//        await navigationProvider.navigator().updateMapMatching(status: status)
//        let options = NavigationRouteOptions(coordinates: [
//            CLLocationCoordinate2D(latitude: 38.853108, longitude: -77.043331),
//            CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906),
//        ])
//
//        let routes = await Fixture.navigationRoutes(from: "DCA-Arboretum", options: options)
//        let navigationOptions = NavigationOptions(
//            mapboxNavigation: navigationProvider.mapboxNavigation,
//            voiceController: navigationProvider.routeVoiceController,
//            eventsManager: navigationProvider.eventsManager()
//        )
//        let navigationViewController = NavigationViewController(
//            navigationRoutes: routes,
//            navigationOptions: navigationOptions
//        )
//        _ = navigationViewController.view
//
//        let activeStatus = TestNavigationStatusProvider.createNavigationStatus(
//            location: .init(coordinate: coordinate),
//            routeIndex: 0,
//            legIndex: 0,
//            stepIndex: 0
//        )
//        await navigationProvider.navigator().updateMapMatching(status: activeStatus)
//
//        let firstInstruction = navigationViewController.route!.legs[0].steps[0].instructionsDisplayedAlongStep!.first
//        let topViewController = navigationViewController.topViewController as! TopBannerViewController
//        let instructionsBannerView = topViewController.instructionsBannerView
//
//        XCTAssertNotNil(instructionsBannerView.primaryLabel.text)
//        XCTAssertEqual(instructionsBannerView.primaryLabel.text, firstInstruction?.primaryInstruction.text)
//    }

    @MainActor
    func testBannerInjection() {
        class BottomBannerFake: ContainerViewController {}
        class TopBannerFake: ContainerViewController {}

        let top = TopBannerFake(nibName: nil, bundle: nil)
        let bottom = BottomBannerFake(nibName: nil, bundle: nil)
        let subject = createViewController(topBanner: top, bottomBanner: bottom)
        _ = subject.view // trigger view load
        XCTAssert(subject.topViewController == top, "Top banner not injected properly into NVC")
        XCTAssert(subject.bottomViewController == bottom, "Bottom banner not injected properly into NVC")
        XCTAssert(subject.children.contains(top), "Top banner not found in child VC heirarchy")
        XCTAssert(subject.children.contains(bottom), "Bottom banner not found in child VC heirarchy")
    }

    @MainActor
    func testNavigationMapViewInjection() {
        let injected = NavigationMapViewSpy(
            location: locationPublisher.eraseToAnyPublisher(),
            routeProgress: routeProgressPublisher.eraseToAnyPublisher()
        )
        let subject = createViewController(navigationMapView: injected)
        _ = subject.view // trigger view load

        XCTAssert(subject.navigationMapView == injected, "NavigtionMapView not injected properly.")
        XCTAssert(subject.view.subviews.contains(injected), "NavigtionMapView not injected in view hierarchy.")
    }

    @MainActor
    func testShowsAlternatives() {
        let navigationViewController = createViewController()

        navigationViewController.showsContinuousAlternatives = false

        XCTAssertFalse(navigationViewController.showsContinuousAlternatives)
        XCTAssertFalse(navigationViewController.navigationMapView!.showsAlternatives)
    }

    @MainActor
    func testShowsReportFeedback() {
        let navigationViewController = createViewController()

        XCTAssertEqual(
            navigationViewController.showsReportFeedback,
            true,
            "Button that allows drivers to report feedback should be shown by default."
        )

        navigationViewController.showsReportFeedback = false

        XCTAssertEqual(
            navigationViewController.showsReportFeedback,
            false,
            "Button that allows drivers to report feedback should not be shown."
        )
    }

    @MainActor
    func testShowsSpeedLimits() {
        let navigationViewController = createViewController()

        XCTAssertEqual(
            navigationViewController.showsSpeedLimits,
            true,
            "Speed limit should be shown by default."
        )

        navigationViewController.showsSpeedLimits = false

        XCTAssertEqual(
            navigationViewController.showsSpeedLimits,
            false,
            "Speed limit should not be shown."
        )
    }

    @MainActor
    func testFloatingButtonsPosition() {
        let navigationViewController = createViewController()

        XCTAssertEqual(
            navigationViewController.floatingButtonsPosition,
            .topTrailing,
            "The position of the floating buttons should be topTrailing by default."
        )

        navigationViewController.floatingButtonsPosition = .topLeading

        XCTAssertEqual(
            navigationViewController.floatingButtonsPosition,
            .topLeading,
            "The position of the floating buttons should be topLeading."
        )
    }

    @MainActor
    func testFloatingButtons() {
        let navigationViewController = createViewController()

        XCTAssertEqual(
            navigationViewController.floatingButtons?.count,
            3,
            "There should be three floating buttons by default."
        )
        XCTAssertEqual(
            navigationViewController.floatingButtons?[0],
            navigationViewController.overviewButton,
            "Unexpected floating button."
        )
        XCTAssertEqual(
            navigationViewController.floatingButtons?[1],
            navigationViewController.muteButton,
            "Unexpected floating button."
        )
        XCTAssertEqual(
            navigationViewController.floatingButtons?[2],
            navigationViewController.reportButton,
            "Unexpected floating button."
        )

        navigationViewController.floatingButtons = []
        XCTAssertEqual(
            navigationViewController.floatingButtons?.count,
            0,
            "There should be zero floating buttons after modification."
        )

        let floatingButton = UIButton()
        navigationViewController.floatingButtons = [floatingButton]
        XCTAssertEqual(
            navigationViewController.floatingButtons?.count,
            1,
            "There should be one floating button after modification."
        )
        XCTAssertEqual(
            navigationViewController.floatingButtons?.first,
            floatingButton,
            "Unexpected floating button."
        )
    }

    @MainActor
    func testShieldStyleWithNavigationMapViewInjection() {
        let nightStyleURI: StyleURI = .dark
        let dayStyleURI: StyleURI = .light

        let spriteRepository = SpriteRepository.shared

        let styleLoadedExpectation = XCTestExpectation(description: "Style updated expectation.")
        spriteRepository.updateStyle(styleURI: nightStyleURI) { _ in
            styleLoadedExpectation.fulfill()
        }
        wait(for: [styleLoadedExpectation], timeout: 2.0)
        XCTAssertEqual(
            spriteRepository.userInterfaceIdiomStyles[.phone],
            nightStyleURI,
            "Failed to update the style of SpriteRepository singleton to Night style."
        )

        let injected = NavigationMapViewSpy(
            location: locationPublisher.eraseToAnyPublisher(),
            routeProgress: routeProgressPublisher.eraseToAnyPublisher()
        )
        injected.mapView.mapboxMap.styleURI = dayStyleURI

        let subject = createViewController(styles: [DayStyle()], navigationMapView: injected)
        _ = subject.view // trigger view load

        XCTAssert(subject.navigationMapView == injected, "NavigtionMapView not injected properly.")
        XCTAssertEqual(
            injected.mapView.mapboxMap.styleURI?.rawValue,
            subject.styleManager.currentStyle?.mapStyleURL.absoluteString,
            "Failed to apply the style to NavigationViewController."
        )
        XCTAssertEqual(
            spriteRepository.userInterfaceIdiomStyles[.phone],
            dayStyleURI,
            "Failed to update the style of SpriteRepository singleton with the injected NavigationMapView."
        )
    }

    @MainActor
    func testNavigationMapViewWillAddLayerDelegate() {
        final class NavigationViewControllerDelegateMock: NavigationViewControllerDelegate {
            let expectedRouteLineOpacity: Double = 0.2
            let expectedRouteCasingOpacity: Double = 0.3
            let expectedRouteCasingWidth: Double = 10.0
            let expectedRestrictedLineOpacity: Double = 0.4
            let expectedTraversedRouteWidth: Double = 11.0

            func navigationViewController(_ navigationViewController: NavigationViewController, willAdd layer: Layer)
            -> Layer? {
                guard var lineLayer = layer as? LineLayer else { return nil }
                if lineLayer.id == "com.mapbox.navigation.route_line.main" {
                    lineLayer.lineOpacity = .constant(expectedRouteLineOpacity)
                } else if lineLayer.id == "com.mapbox.navigation.route_line.main.casing" {
                    lineLayer.lineOpacity = .constant(expectedRouteCasingOpacity)
                    lineLayer.lineWidth = .constant(expectedRouteCasingWidth)
                } else if lineLayer.id == "com.mapbox.navigation.route_line.main.restricted_area" {
                    lineLayer.lineOpacity = .constant(expectedRestrictedLineOpacity)
                } else if lineLayer.id == "com.mapbox.navigation.route_line.main.traversed_route" {
                    lineLayer.lineWidth = .constant(expectedTraversedRouteWidth)
                }
                return lineLayer
            }
        }

        let delegateMock = NavigationViewControllerDelegateMock()
        let navigationViewController = createViewController(delegate: delegateMock)
        let navigationMapView = navigationViewController.navigationMapView!
        let expectation = expectation(description: "Map loading error expectation")
        let styleJSON = navigationMapView.mapView.mapboxMap.mockJsonStyle()
        navigationMapView.mapView.mapboxMap.loadStyle(styleJSON) { _ in
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        navigationMapView.mapStyleManager.onStyleLoaded()
        navigationViewController.routeLineTracksTraversal = true
        navigationMapView.traversedRouteColor = .gray
        navigationMapView.show(initialRoutes, routeAnnotationKinds: [])

        let mapboxMap = navigationMapView.mapView.mapboxMap!
        let mainRouteIds = FeatureIds.RouteLine.main
        navigationViewController.navigationMapView?.showsRestrictedAreasOnRoute = true

        guard let routelineOpacity = mapboxMap.layerPropertyValue(
            for: mainRouteIds.main,
            property: "line-opacity"
        ) as? Double,
            let routeCasingOpacity = mapboxMap.layerPropertyValue(
                for: mainRouteIds.casing,
                property: "line-opacity"
            ) as? Double,
            let routeCasingWidth = mapboxMap.layerPropertyValue(
                for: mainRouteIds.casing,
                property: "line-width"
            ) as? Double,
            let restrictedOpacity = mapboxMap.layerPropertyValue(
                for: mainRouteIds.restrictedArea,
                property: "line-opacity"
            ) as? Double,
            let traversedWidth = mapboxMap.layerPropertyValue(
                for: mainRouteIds.traversedRoute,
                property: "line-width"
            ) as? Double
        else {
            XCTFail("Route line layers should all be present.")
            return
        }

        XCTAssertEqual(
            routelineOpacity,
            delegateMock.expectedRouteLineOpacity,
            accuracy: 1e-3,
            "Failed to customize route line layer through delegate."
        )
        XCTAssertEqual(
            routeCasingOpacity,
            delegateMock.expectedRouteCasingOpacity,
            accuracy: 1e-3,
            "Failed to customize route casing layer through delegate."
        )
        XCTAssertEqual(
            routeCasingWidth,
            delegateMock.expectedRouteCasingWidth,
            accuracy: 1e-3,
            "Failed to customize route casing layer through delegate."
        )
        XCTAssertEqual(
            restrictedOpacity,
            delegateMock.expectedRestrictedLineOpacity,
            accuracy: 1e-3,
            "Failed to customize route restricted area layer through delegate."
        )
        XCTAssertEqual(
            traversedWidth,
            delegateMock.expectedTraversedRouteWidth,
            accuracy: 1e-3,
            "Failed to customize route traversed route layer through delegate"
        )
        XCTAssertNil(
            mapboxMap.layerPropertyValue(for: mainRouteIds.traversedRoute, property: "line-opacity") as? Double,
            "The traversed route layer shouldn't have other properties modified."
        )
    }
}

extension NavigationViewControllerTests: NavigationViewControllerDelegate, StyleManagerDelegate {
    func location(for styleManager: MapboxNavigationUIKit.StyleManager) -> CLLocation? {
        poi.first
    }

    func styleManagerDidRefreshAppearance(_ styleManager: MapboxNavigationUIKit.StyleManager) {
        styleRefreshedAppearanceExpectation?.fulfill()
    }

    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        roadNameAt location: CLLocation
    ) -> String? {
        customRoadName[location.coordinate] ?? nil
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
    private func location(at coordinate: CLLocationCoordinate2D) -> CLLocation {
        return CLLocation(
            coordinate: coordinate,
            altitude: 5,
            horizontalAccuracy: 10,
            verticalAccuracy: 5,
            course: 20,
            speed: 15,
            timestamp: Date()
        )
    }
}
