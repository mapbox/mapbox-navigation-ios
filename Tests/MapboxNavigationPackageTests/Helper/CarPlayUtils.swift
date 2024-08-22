import CarPlay
import CarPlayTestHelper
import Foundation
@testable import MapboxDirections
import MapboxMaps
@testable import MapboxNavigationCore
@testable import MapboxNavigationUIKit
import TestHelper
import XCTest

@MainActor
func simulateCarPlayConnection(_ carPlayManager: CarPlayManager) {
    let interfaceController = FakeCPInterfaceController(context: #function)
    let window = CPWindow()

    carPlayManager.application(
        UIApplication.shared,
        didConnectCarInterfaceController: interfaceController,
        to: window
    )

    if let mapViewController = carPlayManager.carWindow?.rootViewController?.view {
        carPlayManager.carWindow?.addSubview(mapViewController)
    }
}

@MainActor
func simulateCarPlayDisconnection(_ carPlayManager: CarPlayManager) {
    guard let interfaceController = carPlayManager.interfaceController else {
        preconditionFailure("Instance of CPInterfaceController should be valid.")
    }
    let window = CPWindow()

    carPlayManager.application(
        UIApplication.shared,
        didDisconnectCarInterfaceController: interfaceController,
        from: window
    )
}

func createNavigationRoutes() async -> NavigationRoutes {
    let navigationRouteOptions = NavigationRouteOptions(coordinates: [
        CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
        CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
    ])
    return await Fixture.navigationRoutes(from: "route-with-banner-instructions", options: navigationRouteOptions)
}

func createValidRouteChoice() async -> CPRouteChoice {
    let routeChoice = CPRouteChoice(
        summaryVariants: ["summary"],
        additionalInformationVariants: ["additionalInformation"],
        selectionSummaryVariants: ["selectionSummary"]
    )
    let routes = await createNavigationRoutes()
    let routeResponseUserInfoKey = CPRouteChoice.RouteResponseUserInfo.key
    let routeResponseUserInfo: CPRouteChoice.RouteResponseUserInfo = .init(navigationRoutes: routes)
    let userInfo: CarPlayUserInfo = [
        routeResponseUserInfoKey: routeResponseUserInfo,
    ]
    routeChoice.userInfo = userInfo

    return routeChoice
}

func createInvalidRouteChoice() -> CPRouteChoice {
    let routeChoice = CPRouteChoice(
        summaryVariants: ["summary"],
        additionalInformationVariants: ["additionalInformation"],
        selectionSummaryVariants: ["selectionSummary"]
    )

    return routeChoice
}

func createTrip(_ routeChoice: CPRouteChoice) -> CPTrip {
    let trip = CPTrip(
        origin: MKMapItem(),
        destination: MKMapItem(),
        routeChoices: [routeChoice]
    )

    return trip
}

class CarPlayManagerDelegateSpy: CarPlayManagerDelegate {
    var didBeginNavigationCalled = false
    var didEndNavigationCalled = false
    var legacyDidEndNavigationCalled = false
    var willPresentCalled = false
    var didPresentCalled = false
    var didFailToFetchRouteCalled = false
    var didBeginPanGestureCalled = false
    var didEndPanGestureCalled = false
    var didShowPanningInterfaceCalled = false
    var willDismissPanningInterfaceCalled = false
    var didDismissPanningInterfaceCalled = false

    var passedError: DirectionsError?
    var passedTemplate: CPMapTemplate?
    var passedNavigationEndedByCanceling = false
    var passedWillPresentNavigationViewController: CarPlayNavigationViewController?

    var returnedTripPreviewTextConfiguration: CPTripPreviewTextConfiguration?
    var returnedTrip: CPTrip?
    var returnedLeadingBarButtons: [CPBarButton]?
    var returnedTrailingBarButtons: [CPBarButton]?
    var returnedMapButtons: [CPMapButton]?
    var symbolLayer: SymbolLayer?
    var circleLayer: CircleLayer?

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer? {
        circleLayer
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer? {
        symbolLayer
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        willPreview trip: CPTrip
    ) -> CPTrip {
        return returnedTrip ?? trip
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        willPreview trip: CPTrip,
        with previewTextConfiguration: CPTripPreviewTextConfiguration
    )
    -> CPTripPreviewTextConfiguration {
        return returnedTripPreviewTextConfiguration ?? previewTextConfiguration
    }

    func carPlayManagerDidBeginNavigation(_ carPlayManager: CarPlayManager) {
        didBeginNavigationCalled = true
    }

    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager, byCanceling canceled: Bool) {
        XCTAssertTrue(didBeginNavigationCalled)
        didEndNavigationCalled = true
        passedNavigationEndedByCanceling = canceled
    }

    // TODO: This delegate method should be removed in next major release.
    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
        XCTAssertTrue(didBeginNavigationCalled)
        legacyDidEndNavigationCalled = true
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        willPresent navigationViewController: CarPlayNavigationViewController
    ) {
        willPresentCalled = true
        passedWillPresentNavigationViewController = navigationViewController
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didPresent navigationViewController: CarPlayNavigationViewController
    ) {
        didPresentCalled = true
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        in: CPTemplate,
        for activity: CarPlayActivity
    ) -> [CPBarButton]? {
        returnedLeadingBarButtons
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
        in: CPTemplate,
        for activity: CarPlayActivity
    ) -> [CPBarButton]? {
        returnedTrailingBarButtons
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        mapButtonsCompatibleWith traitCollection: UITraitCollection,
        in template: CPTemplate,
        for activity: CarPlayActivity
    ) -> [CPMapButton]? {
        returnedMapButtons
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didFailToFetchRouteBetween waypoints: [Waypoint]?,
        options: RouteOptions,
        error: Error
    ) -> CPNavigationAlert? {
        didFailToFetchRouteCalled = true
        passedError = error as? DirectionsError
        return nil
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didBeginPanGesture template: CPMapTemplate
    ) {
        didBeginPanGestureCalled = true
        passedTemplate = template
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didEndPanGesture template: CPMapTemplate
    ) {
        didEndPanGestureCalled = true
        passedTemplate = template
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didShowPanningInterface template: CPMapTemplate
    ) {
        didShowPanningInterfaceCalled = true
        passedTemplate = template
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        willDismissPanningInterface template: CPMapTemplate
    ) {
        willDismissPanningInterfaceCalled = true
        passedTemplate = template
    }

    func carPlayManager(
        _ carPlayManager: CarPlayManager,
        didDismissPanningInterface template: CPMapTemplate
    ) {
        didDismissPanningInterfaceCalled = true
        passedTemplate = template
    }
}

class CarPlayNavigationViewControllerTestable: CarPlayNavigationViewController {
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        completion?()
    }
}

class TestCarPlaySearchControllerDelegate: NSObject, CarPlaySearchControllerDelegate {
    public fileprivate(set) var interfaceController: CPInterfaceController?
    public fileprivate(set) var carPlayManager: CarPlayManager?

    func carPlaySearchController(
        _ searchController: CarPlaySearchController,
        carPlayManager: CarPlayManager,
        interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
    }

    func previewRoutes(to waypoint: Waypoint, completionHandler: @escaping () -> Void) {
        carPlayManager?.previewRoutes(to: waypoint, completionHandler: completionHandler)
    }

    @MainActor
    func resetPanButtons(_ mapTemplate: CPMapTemplate) {
        carPlayManager?.resetPanButtons(mapTemplate)
    }

    func pushTemplate(_ template: CPTemplate, animated: Bool) {
        pushTemplate(template, animated: animated, completion: nil)
    }

    func popTemplate(animated: Bool) {
        popTemplate(animated: animated, completion: nil)
    }

    func pushTemplate(_ template: CPTemplate, animated: Bool, completion: ((Bool, (any Error)?) -> Void)?) {
        interfaceController?.pushTemplate(template, animated: animated, completion: completion)
    }

    func popTemplate(animated: Bool, completion: ((Bool, (any Error)?) -> Void)?) {
        interfaceController?.popTemplate(animated: animated, completion: completion)
    }

    var recentSearchItems: [CPListItem]?

    var recentSearchText: String?

    func searchTemplate(
        _ searchTemplate: CPSearchTemplate,
        updatedSearchText searchText: String,
        completionHandler: @escaping ([CPListItem]) -> Void
    ) {
        completionHandler([])
    }

    func searchTemplate(
        _ searchTemplate: CPSearchTemplate,
        selectedResult item: CPListItem,
        completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }

    func searchResults(with items: [CPListItem], limit: UInt?) -> [CPListItem] {
        return []
    }
}

final class MapTemplateSpy: CPMapTemplate, @unchecked Sendable {
    private(set) var passedTripPreviews: [CPTrip]?
    private(set) var passedPreviewTextConfiguration: CPTripPreviewTextConfiguration?

    var showTripPreviewsCalled = false
    var hideTripPreviewsCalled = false
    var startNavigationSessionCalled = false

    var returnedSession: CPNavigationSession!

    override func showTripPreviews(_ tripPreviews: [CPTrip], textConfiguration: CPTripPreviewTextConfiguration?) {
        showTripPreviewsCalled = true
        passedTripPreviews = tripPreviews
        passedPreviewTextConfiguration = textConfiguration
    }

    override func hideTripPreviews() {
        hideTripPreviewsCalled = true
    }

    override func startNavigationSession(for trip: CPTrip) -> CPNavigationSession {
        startNavigationSessionCalled = true
        return returnedSession
    }
}

public class MapTemplateSpyProvider: MapTemplateProvider {
    var returnedMapTemplate = MapTemplateSpy()

    override public func createMapTemplate() -> CPMapTemplate {
        return returnedMapTemplate
    }
}
