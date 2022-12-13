import Foundation
import XCTest
import CarPlay
@testable import MapboxNavigation
@testable import MapboxCoreNavigation
@testable import MapboxDirections
import CarPlayTestHelper
import TestHelper

func simulateCarPlayConnection(_ carPlayManager: CarPlayManager) {
    let interfaceController = FakeCPInterfaceController(context: #function)
    let window = CPWindow()
    
    carPlayManager.application(UIApplication.shared,
                               didConnectCarInterfaceController: interfaceController,
                               to: window)
    
    if let mapViewController = carPlayManager.carWindow?.rootViewController?.view {
        carPlayManager.carWindow?.addSubview(mapViewController)
    }
}

func simulateCarPlayDisconnection(_ carPlayManager: CarPlayManager) {
    guard let interfaceController = carPlayManager.interfaceController else {
        preconditionFailure("Instance of CPInterfaceController should be valid.")
    }
    let window = CPWindow()
    
    carPlayManager.application(UIApplication.shared,
                               didDisconnectCarInterfaceController: interfaceController,
                               from: window)
}

func createValidRouteChoice() -> CPRouteChoice {
    let routeChoice = CPRouteChoice(summaryVariants: ["summary"],
                                    additionalInformationVariants: ["additionalInformation"],
                                    selectionSummaryVariants: ["selectionSummary"])
    let navigationRouteOptions = NavigationRouteOptions(coordinates: [
        CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
        CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
    ])
    let routeResponseUserInfoKey = CPRouteChoice.IndexedRouteResponseUserInfo.key
    let routeResponse = Fixture.routeResponse(from: "route-with-banner-instructions",
                                              options: navigationRouteOptions)
    let routeResponseUserInfo: CPRouteChoice.IndexedRouteResponseUserInfo = .init(indexedRouteResponse: .init(routeResponse: routeResponse,
                                                                                                              routeIndex: 0))
    let userInfo: CarPlayUserInfo = [
        routeResponseUserInfoKey: routeResponseUserInfo
    ]
    routeChoice.userInfo = userInfo
    
    return routeChoice
}

func createInvalidRouteChoice() -> CPRouteChoice {
    let routeChoice = CPRouteChoice(summaryVariants: ["summary"],
                                    additionalInformationVariants: ["additionalInformation"],
                                    selectionSummaryVariants: ["selectionSummary"])
    
    return routeChoice
}

func createTrip(_ routeChoice: CPRouteChoice) -> CPTrip {
    let trip = CPTrip(origin: MKMapItem(),
                      destination: MKMapItem(),
                      routeChoices: [routeChoice])
    
    return trip
}

class CarPlayManagerDelegateSpy: CarPlayManagerDelegate {
    var didBeginNavigationCalled = false
    var didEndNavigationCalled = false
    var legacyDidEndNavigationCalled = false
    var didPresentCalled = false
    var didFailToFetchRouteCalled = false

    var passedService: NavigationService?
    var passedError: DirectionsError?
    var passedNavigationEndedByCanceling = false

    var returnedTripPreviewTextConfiguration: CPTripPreviewTextConfiguration?
    var returnedTrip: CPTrip?
    var returnedLeadingBarButtons: [CPBarButton]?
    var returnedTrailingBarButtons: [CPBarButton]?
    var returnedMapButtons: [CPMapButton]?

    func carPlayManager(_ carPlayManager: CarPlayManager,
                        willPreview trip: CPTrip) -> CPTrip {
        return returnedTrip ?? trip
    }

    func carPlayManager(_ carPlayManager: CarPlayManager,
                        willPreview trip: CPTrip,
                        with previewTextConfiguration: CPTripPreviewTextConfiguration) -> CPTripPreviewTextConfiguration {
        return returnedTripPreviewTextConfiguration ?? previewTextConfiguration
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith service: NavigationService) {
        didBeginNavigationCalled = true
        passedService = service
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

    func carPlayManager(_ carPlayManager: CarPlayManager, didPresent navigationViewController: CarPlayNavigationViewController) {
        didPresentCalled = true
    }

    func carPlayManager(_ carPlayManager: CarPlayManager,
                        leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
                        in: CPTemplate,
                        for activity: CarPlayActivity) -> [CPBarButton]? {
        return returnedLeadingBarButtons
    }

    func carPlayManager(_ carPlayManager: CarPlayManager,
                        trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection,
                        in: CPTemplate,
                        for activity: CarPlayActivity) -> [CPBarButton]? {
        return returnedTrailingBarButtons
    }

    func carPlayManager(_ carPlayManager: CarPlayManager,
                        mapButtonsCompatibleWith traitCollection: UITraitCollection,
                        in template: CPTemplate,
                        for activity: CarPlayActivity) -> [CPMapButton]? {
        return returnedMapButtons
    }

    func carPlayManager(_ carPlayManager: CarPlayManager,
                        didFailToFetchRouteBetween waypoints: [Waypoint]?,
                        options: RouteOptions,
                        error: DirectionsError) -> CPNavigationAlert? {
        didFailToFetchRouteCalled = true
        passedError = error
        return nil
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

    func carPlaySearchController(_ searchController: CarPlaySearchController,
                                 carPlayManager: CarPlayManager,
                                 interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
    }

    func previewRoutes(to waypoint: Waypoint, completionHandler: @escaping () -> Void) {
        carPlayManager?.previewRoutes(to: waypoint, completionHandler: completionHandler)
    }

    func resetPanButtons(_ mapTemplate: CPMapTemplate) {
        carPlayManager?.resetPanButtons(mapTemplate)
    }

    func pushTemplate(_ template: CPTemplate, animated: Bool) {
        interfaceController?.pushTemplate(template, animated: animated)
    }

    func popTemplate(animated: Bool) {
        interfaceController?.popTemplate(animated: animated)
    }
    
    var recentSearchItems: [CPListItem]?
    
    var recentSearchText: String?
    
    func searchTemplate(_ searchTemplate: CPSearchTemplate,
                        updatedSearchText searchText: String,
                        completionHandler: @escaping ([CPListItem]) -> Void) {
        completionHandler([])
    }
    
    func searchTemplate(_ searchTemplate: CPSearchTemplate,
                        selectedResult item: CPListItem,
                        completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    func searchResults(with items: [CPListItem], limit: UInt?) -> [CPListItem] {
        return []
    }
}

class MapTemplateSpy: CPMapTemplate {
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
