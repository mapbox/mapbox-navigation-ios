import Foundation
import XCTest
import CarPlay
@testable import MapboxNavigation
@testable import MapboxCoreNavigation
@testable import MapboxDirections
import CarPlayTestHelper
import TestHelper

@available(iOS 12.0, *)
func simulateCarPlayConnection(_ manager: CarPlayManager) {
    let fakeInterfaceController = FakeCPInterfaceController(context: #function)
    let fakeWindow = CPWindow()

    manager.application(UIApplication.shared, didConnectCarInterfaceController: fakeInterfaceController, to: fakeWindow)
    if let mapViewController = manager.carWindow?.rootViewController?.view {
        manager.carWindow?.addSubview(mapViewController)
    }
}

@available(iOS 12.0, *)
class CarPlayManagerFailureDelegateSpy: CarPlayManagerDelegate {
    private(set) var recievedError: DirectionsError?

    @available(iOS 12.0, *)
    func carPlayManager(_ carPlayManager: CarPlayManager, didFailToFetchRouteBetween waypoints: [Waypoint]?, options: RouteOptions, error: DirectionsError) -> CPNavigationAlert? {
        recievedError = error
        return nil
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, navigationServiceFor routeResponse: RouteResponse, routeIndex: Int, routeOptions: RouteOptions, desiredSimulationMode: SimulationMode) -> NavigationService {
        fatalError("This is an empty stub.")
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith service: NavigationService) {
        fatalError("This is an empty stub.")
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager, shouldPresentArrivalUIFor waypoint: Waypoint) -> Bool {
        fatalError("This is an empty stub.")
    }

    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
        fatalError("This is an empty stub.")
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, didPresent navigationViewController: CarPlayNavigationViewController) {
        fatalError("This is an empty stub.")
    }
}

// MARK: Test Objects / Classes.

@available(iOS 12.0, *)
class TestCarPlayManagerDelegate: CarPlayManagerDelegate {
    public fileprivate(set) var navigationInitiated = false
    public fileprivate(set) var currentService: NavigationService?
    public fileprivate(set) var navigationEnded = false

    public var interfaceController: CPInterfaceController?
    public var searchController: CarPlaySearchController?
    public var leadingBarButtons: [CPBarButton]?
    public var trailingBarButtons: [CPBarButton]?
    public var mapButtons: [CPMapButton]?

    func carPlayManager(_ carPlayManager: CarPlayManager, navigationServiceFor routeResponse: RouteResponse, routeIndex: Int, routeOptions: RouteOptions, desiredSimulationMode: SimulationMode) -> NavigationService {
        let response = Fixture.routeResponse(from: jsonFileName, options: routeOptions)
        let directionsClientSpy = DirectionsSpy()
        let service = MapboxNavigationService(routeResponse: response, routeIndex: 0, routeOptions: routeOptions, directions: directionsClientSpy, locationSource: NavigationLocationManager(), eventsManagerType: NavigationEventsManagerSpy.self, simulating: desiredSimulationMode)
        return service
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, leadingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]? {
        return leadingBarButtons
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, trailingNavigationBarButtonsCompatibleWith traitCollection: UITraitCollection, in: CPTemplate, for activity: CarPlayActivity) -> [CPBarButton]? {
        return trailingBarButtons
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, mapButtonsCompatibleWith traitCollection: UITraitCollection, in template: CPTemplate, for activity: CarPlayActivity) -> [CPMapButton]? {
        return mapButtons
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith service: NavigationService) {
        XCTAssertFalse(navigationInitiated)
        navigationInitiated = true
        currentService = service
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager, shouldPresentArrivalUIFor waypoint: Waypoint) -> Bool {
        return true
    }

    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager) {
        XCTAssertTrue(navigationInitiated)
        navigationEnded = true
        currentService = nil
    }

    func carPlayManager(_ carPlayManager: CarPlayManager, didPresent navigationViewController: CarPlayNavigationViewController) {
        XCTAssertTrue(navigationInitiated)
    }
}

@available(iOS 12.0, *)
class CarPlayNavigationViewControllerTestable: CarPlayNavigationViewController {
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        completion?()
    }
}

@available(iOS 12.0, *)
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

@available(iOS 12.0, *)
class MapTemplateSpy: CPMapTemplate {
    private(set) var currentTripPreviews: [CPTrip]?
    private(set) var currentPreviewTextConfiguration: CPTripPreviewTextConfiguration?

    private(set) var estimatesUpdate: (CPTravelEstimates, CPTrip, CPTimeRemainingColor)?

    var fakeSession:  CPNavigationSession!

    override func showTripPreviews(_ tripPreviews: [CPTrip], textConfiguration: CPTripPreviewTextConfiguration?) {
        currentTripPreviews = tripPreviews
        currentPreviewTextConfiguration = textConfiguration
    }

    override func update(_ estimates: CPTravelEstimates, for trip: CPTrip, with timeRemainingColor: CPTimeRemainingColor) {
        estimatesUpdate = (estimates, trip, timeRemainingColor)
    }

    override func hideTripPreviews() {
        currentTripPreviews = nil
        currentPreviewTextConfiguration = nil
    }

    override func startNavigationSession(for trip: CPTrip) -> CPNavigationSession {
        return fakeSession
    }
}

@available(iOS 12.0, *)
public class MapTemplateSpyProvider: MapTemplateProvider {
    override public func createMapTemplate() -> CPMapTemplate {
        return MapTemplateSpy()
    }
}


