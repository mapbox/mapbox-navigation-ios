import CarPlay
import CarPlayTestHelper
import MapboxDirections
import MapboxMaps
@testable import MapboxNavigationCore
@testable import MapboxNavigationUIKit
@testable import TestHelper
import XCTest

class CarPlayManagerTests: TestCase {
    var carPlayManager: CarPlayManager!

    var carPlaySearchController: CarPlaySearchController!
    var searchDelegate: TestCarPlaySearchControllerDelegate!
    var mapTemplateProvider: MapTemplateSpyProvider!
    var delegate: CarPlayManagerDelegateSpy!
    var routingProvider: RoutingProviderSpy!
    var buttonImage: UIImage!

    var mapTemplateSpy: MapTemplateSpy {
        mapTemplateProvider.returnedMapTemplate
    }

    @MainActor
    override func setUp() {
        super.setUp()

        routingProvider = RoutingProviderSpy()
        coreConfig.__customRoutingProvider = .init(routingProvider)
        navigationProvider.apply(coreConfig: coreConfig)
        CarPlayMapViewController.swizzleMethods()
        carPlayManager = CarPlayManager(
            navigationProvider: navigationProvider,
            carPlayNavigationViewControllerClass: CarPlayNavigationViewControllerTestable.self
        )

        delegate = CarPlayManagerDelegateSpy()
        carPlayManager.delegate = delegate
        mapTemplateProvider = MapTemplateSpyProvider()
        carPlayManager.mapTemplateProvider = mapTemplateProvider

        carPlaySearchController = CarPlaySearchController()
        searchDelegate = TestCarPlaySearchControllerDelegate()
        carPlaySearchController.delegate = searchDelegate

        simulateCarPlayConnection(carPlayManager)
        buttonImage = .debugImage
    }

    override func tearDown() {
        CarPlayMapViewController.unswizzleMethods()

        carPlayManager = nil
        delegate = nil
        searchDelegate = nil
        mapTemplateProvider = nil

        super.tearDown()
    }

    @MainActor
    func testEventsSentWhenCarPlayConnectedAndDisconnected() {
        guard let interfaceController = carPlayManager.interfaceController else {
            XCTFail("CPInterfaceController should be valid.")
            return
        }
        eventsManagerSpy.sendCarPlayConnectExpectation = expectation(description: "did connect")
        eventsManagerSpy.sendCarPlayDisconnectExpectation = expectation(description: "did disconnect")

        carPlayManager.application(
            .shared,
            didConnectCarInterfaceController: interfaceController,
            to: CPWindow()
        )
        wait(for: [eventsManagerSpy.sendCarPlayConnectExpectation!], timeout: 1.0)
        XCTAssertTrue(eventsManagerSpy.sendCarPlayConnectEventCalled)

        simulateCarPlayDisconnection(carPlayManager)
        wait(for: [eventsManagerSpy.sendCarPlayDisconnectExpectation!], timeout: 1.0)
        XCTAssertTrue(eventsManagerSpy.sendCarPlayDisconnectEventCalled)
    }

    func testReturnSourceCircleLayer() {
        let id = "test"
        let source = "test_source"
        let layer = CircleLayer(id: id, source: source)
        delegate.circleLayer = layer
        let actualLayer = delegate.carPlayManager(
            carPlayManager,
            waypointCircleLayerWithIdentifier: id,
            sourceIdentifier: source
        )
        XCTAssertEqual(actualLayer, layer)
    }

    func testReturnSourceSymbolLayer() {
        let id = "test"
        let source = "test_source"
        let layer = SymbolLayer(id: id, source: source)
        delegate.symbolLayer = layer
        let actualLayer = delegate.carPlayManager(
            carPlayManager,
            waypointSymbolLayerWithIdentifier: id,
            sourceIdentifier: source
        )
        XCTAssertEqual(actualLayer, layer)
    }

    @MainActor
    func testWindowAndIntefaceControllerAreSetUpWithSearchWhenConnected() {
        let searchDelegate = TestCarPlaySearchControllerDelegate()
        let searchButtonHandler: ((CPBarButton) -> Void) = { [weak self] _ in
            guard let self else { return }
            carPlayManager.interfaceController?.pushTemplate(CPSearchTemplate(), animated: true, completion: nil)
        }
        delegate.returnedLeadingBarButtons = [
            CPBarButton(image: buttonImage, handler: searchButtonHandler),
        ]

        simulateCarPlayConnection(carPlayManager)

        guard let interfaceController = carPlayManager.interfaceController else {
            XCTFail("CPInterfaceController should be valid.")
            return
        }

        searchDelegate.carPlaySearchController(
            carPlaySearchController,
            carPlayManager: carPlayManager,
            interfaceController: interfaceController
        )

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
        searchButtonHandler(searchButton)

        XCTAssertTrue(
            interfaceController.topTemplate?.isKind(of: CPSearchTemplate.self) ?? false,
            "CPSearchTemplate should be the top template in the navigation hierarchy."
        )
    }

    @MainActor
    func testManagerAsksDelegateForLeadingAndTrailingBarButtonsIfAvailable() {
        delegate.returnedLeadingBarButtons = [
            CPBarButton(title: "button 1"),
            CPBarButton(title: "button 2"),
        ]

        delegate.returnedTrailingBarButtons = [
            CPBarButton(image: buttonImage),
            CPBarButton(image: buttonImage),
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

    @MainActor
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

    @MainActor
    func testNavigationStartAndEnd() async {
        await startNavigation()

        XCTAssertTrue(
            delegate.didBeginNavigationCalled,
            "The CarPlayManagerDelegate should have been told that navigation was initiated."
        )

        carPlayManager.carPlayNavigationViewController?.exitNavigation(byCanceling: true)

        XCTAssertTrue(
            delegate.legacyDidEndNavigationCalled,
            "The CarPlayManagerDelegate should have been told that navigation ended."
        )

        XCTAssertTrue(
            delegate.didEndNavigationCalled,
            "The CarPlayManagerDelegate should have been told that navigation ended."
        )

        XCTAssertTrue(
            delegate.passedNavigationEndedByCanceling,
            "The CarPlayManagerDelegate should have been told that navigation ended by canceling."
        )
    }

    func testRouteRequestFailure() async {
        let routeOptions = RouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
        ])

        let testError = DirectionsError.requestTooLarge
        let task: Task<NavigationRoutes, Error> = Task {
            throw testError
        }
        await carPlayManager.didCalculate(task, for: routeOptions)
        XCTAssertTrue(delegate.didFailToFetchRouteCalled)
        XCTAssertEqual(delegate.passedError, testError, "Delegate should have receieved error.")
    }

    @MainActor
    func testCustomStyles() {
        class CustomStyle: DayStyle {}

        XCTAssertEqual(carPlayManager.styles.count, 2)
        XCTAssertEqual(carPlayManager.styles.first?.styleType, StyleType.day)
        XCTAssertEqual(carPlayManager.styles.last?.styleType, StyleType.night)

        let styles = [CustomStyle()]
        let carPlayManagerWithModifiedStyles = CarPlayManager(
            navigationProvider: navigationProvider,
            styles: styles,
            carPlayNavigationViewControllerClass: CarPlayNavigationViewControllerTestable.self
        )
        XCTAssertEqual(
            carPlayManagerWithModifiedStyles.styles,
            styles,
            "CarPlayManager should persist the initial styles given to it."
        )
    }

    func testPreviewRouteWithDefault() async {
        let navigationRouteOptions = await previewRoutesOptions()
        let previewExpectation = XCTestExpectation(description: "preview expectation")
        carPlayManager.previewRoutes(for: navigationRouteOptions) {
            previewExpectation.fulfill()
        }
        await fulfillment(of: [previewExpectation], timeout: 1)

        XCTAssertEqual(mapTemplateSpy.passedTripPreviews?.count, 1)

        let expectedStartButtonTitle = NSLocalizedString(
            "CARPLAY_GO",
            bundle: .mapboxNavigation,
            value: "Go",
            comment: "Title for start button in CPTripPreviewTextConfiguration"
        )
        XCTAssertEqual(mapTemplateSpy.passedPreviewTextConfiguration?.startButtonTitle, expectedStartButtonTitle)
    }

    func testPreviewRouteWithDefaultAsync() async {
        let navigationRouteOptions = await previewRoutesOptions()
        await carPlayManager.previewRoutes(for: navigationRouteOptions)

        XCTAssertEqual(mapTemplateSpy.passedTripPreviews?.count, 1)

        let expectedStartButtonTitle = NSLocalizedString(
            "CARPLAY_GO",
            bundle: .mapboxNavigation,
            value: "Go",
            comment: "Title for start button in CPTripPreviewTextConfiguration"
        )
        XCTAssertEqual(mapTemplateSpy.passedPreviewTextConfiguration?.startButtonTitle, expectedStartButtonTitle)
    }

    func testPreviewRouteWithCustomTrip() async {
        let customTrip = CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [])
        delegate.returnedTrip = customTrip

        let navigationRouteOptions = await previewRoutesOptions()
        let previewExpectation = XCTestExpectation(description: "preview expectation")
        carPlayManager.previewRoutes(for: navigationRouteOptions) {
            previewExpectation.fulfill()
        }
        await fulfillment(of: [previewExpectation], timeout: 1)
        XCTAssertEqual(mapTemplateSpy.passedTripPreviews?.first, customTrip)
        XCTAssertNotNil(mapTemplateSpy.passedPreviewTextConfiguration)
    }

    func testPreviewRouteWithCustomTripAsync() async {
        let customTrip = CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [])
        delegate.returnedTrip = customTrip

        let navigationRouteOptions = await previewRoutesOptions()
        await carPlayManager.previewRoutes(for: navigationRouteOptions)
        XCTAssertEqual(mapTemplateSpy.passedTripPreviews?.first, customTrip)
        XCTAssertNotNil(mapTemplateSpy.passedPreviewTextConfiguration)
    }

    func testPreviewRouteWithCustomPreviewText() async {
        let customTrip = CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [])
        delegate.returnedTrip = customTrip
        let startButtonTitle = "Let's roll"
        let tripPreviewTextConfiguration = CPTripPreviewTextConfiguration(
            startButtonTitle: startButtonTitle,
            additionalRoutesButtonTitle: nil,
            overviewButtonTitle: nil
        )
        delegate.returnedTripPreviewTextConfiguration = tripPreviewTextConfiguration
        let previewExpectation = XCTestExpectation(description: "preview expectation")

        let navigationRouteOptions = await previewRoutesOptions()
        carPlayManager.previewRoutes(for: navigationRouteOptions) {
            previewExpectation.fulfill()
        }
        await fulfillment(of: [previewExpectation], timeout: 1)

        XCTAssertEqual(mapTemplateSpy.passedTripPreviews?.first, customTrip)
        XCTAssertEqual(mapTemplateSpy.passedPreviewTextConfiguration?.startButtonTitle, startButtonTitle)
    }

    func testPreviewRouteWithCustomPreviewTextAsync() async {
        let customTrip = CPTrip(origin: MKMapItem(), destination: MKMapItem(), routeChoices: [])
        delegate.returnedTrip = customTrip
        let startButtonTitle = "Let's roll"
        let tripPreviewTextConfiguration = CPTripPreviewTextConfiguration(
            startButtonTitle: startButtonTitle,
            additionalRoutesButtonTitle: nil,
            overviewButtonTitle: nil
        )
        delegate.returnedTripPreviewTextConfiguration = tripPreviewTextConfiguration
        let navigationRouteOptions = await previewRoutesOptions()
        await carPlayManager.previewRoutes(for: navigationRouteOptions)

        XCTAssertEqual(mapTemplateSpy.passedTripPreviews?.first, customTrip)
        XCTAssertEqual(mapTemplateSpy.passedPreviewTextConfiguration?.startButtonTitle, startButtonTitle)
    }

    func testWillPresentNavigationViewController() async {
        await startNavigation()

        XCTAssertTrue(delegate.willPresentCalled)
        XCTAssertEqual(
            delegate.passedWillPresentNavigationViewController,
            carPlayManager.carPlayNavigationViewController
        )
    }

    func testStartWhenConfiguredToSimulate() async {
        await startNavigation()

        XCTAssertTrue(delegate.didPresentCalled)
    }

    func testDidBeginPanGesture() async {
        let mapTemplate = CPMapTemplate()
        let task = Task { @MainActor in
            carPlayManager.mapTemplateDidBeginPanGesture(mapTemplate)
        }
        await task.value
        XCTAssertTrue(delegate.didBeginPanGestureCalled)
        XCTAssertEqual(delegate.passedTemplate, mapTemplate)
    }

    func testDidEndPanGesture() {
        let mapTemplate = CPMapTemplate()
        carPlayManager.mapTemplate(mapTemplate, didEndPanGestureWithVelocity: .zero)
        XCTAssertTrue(delegate.didEndPanGestureCalled)
        XCTAssertEqual(delegate.passedTemplate, mapTemplate)
        XCTAssertTrue(mapTemplate.automaticallyHidesNavigationBar)
    }

    @MainActor
    func testDidShowPanningInterface() {
        let mapTemplate = CPMapTemplate()
        carPlayManager.mapTemplateDidShowPanningInterface(mapTemplate)
        XCTAssertTrue(delegate.didShowPanningInterfaceCalled)
        XCTAssertEqual(delegate.passedTemplate, mapTemplate)
    }

    @MainActor
    func testWillDismissPanningInterface() async throws {
        let mapTemplate = CPMapTemplate()

        let task = Task { @MainActor in
            carPlayManager.mapTemplateWillDismissPanningInterface(mapTemplate)
        }
        await task.value
        try await Task.sleep(nanoseconds: NSEC_PER_SEC)
        XCTAssertTrue(delegate.willDismissPanningInterfaceCalled)
        XCTAssertEqual(delegate.passedTemplate, mapTemplate)
    }

    func testDoNotDismissPanningInterfaceIfNoCurrentActivity() {
        let mapTemplate = CPMapTemplate()
        carPlayManager.mapTemplateDidDismissPanningInterface(mapTemplate)
        XCTAssertFalse(delegate.didDismissPanningInterfaceCalled)
    }

    func testDidDismissPanningInterface() async {
        let mapTemplate = CPMapTemplate()
        let task = Task { @MainActor in
            mapTemplate.userInfo = [CarPlayManager.currentActivityKey: CarPlayActivity.browsing]
            carPlayManager.mapTemplateDidDismissPanningInterface(mapTemplate)
        }
        await task.value
        XCTAssertTrue(delegate.didDismissPanningInterfaceCalled)
        XCTAssertEqual(delegate.passedTemplate, mapTemplate)
        XCTAssertEqual(carPlayManager.currentActivity, .browsing)
    }

    @MainActor
    func testConfigureCarPlayMapViewController() {
        let interfaceController = FakeCPInterfaceController(context: #function)
        let window = CPWindow()
        carPlayManager.application(.shared, didConnectCarInterfaceController: interfaceController, to: window)
        let carPlayMapViewController = carPlayManager.carPlayMapViewController
        XCTAssertEqual(carPlayMapViewController?.userInfo, eventsManagerSpy.userInfo)
    }

    private func previewRoutesOptions() async -> NavigationRouteOptions {
        let navigationRouteOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
            CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
        ])
        let routes = await Fixture.navigationRoutes(from: "route-with-banner-instructions", options: routeOptions)
        routingProvider.returnedRoutes = routes

        return navigationRouteOptions
    }

    @MainActor
    private func startNavigation() async {
        let routeChoice = await createValidRouteChoice()
        let trip = createTrip(routeChoice)
        let mapTemplate = CPMapTemplate()

        let task = Task { @MainActor in
            carPlayManager.mapTemplate(mapTemplate, startedTrip: trip, using: routeChoice)
        }
        await task.value
        // TODO: handle async methods properly, remove wait
        wait()

        _ = carPlayManager.carPlayNavigationViewController?.view
        carPlayManager.carPlayNavigationViewController?.loadViewIfNeeded()
    }

    private func wait(timeout: TimeInterval = 1.0) {
        let waitExpectation = expectation(description: "Wait expectation.")
        _ = XCTWaiter.wait(for: [waitExpectation], timeout: timeout)
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
            class_getInstanceMethod(
                CarPlayMapViewController.self,
                #selector(CarPlayMapViewController.present(_:animated:completion:))
            )!,
            class_getInstanceMethod(
                CarPlayMapViewController.self,
                #selector(CarPlayMapViewController.swizzled_present(_:animated:completion:))
            )!
        )
    }

    @objc
    private func swizzled_present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        // We need to keep strong reference to `viewControllerToPresent` so that it won't be
        // deallocated in some cases.
        Self.presentedViewControllers.append(viewControllerToPresent)
        completion?()
    }
}
