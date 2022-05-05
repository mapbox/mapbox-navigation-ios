import Foundation
import XCTest
import CarPlay
@testable import MapboxNavigation
@testable import MapboxCoreNavigation
@testable import MapboxDirections
import CarPlayTestHelper
import TestHelper

@available(iOS 12.0, *)
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

@available(iOS 12.0, *)
func simulateCarPlayDisconnection(_ carPlayManager: CarPlayManager) {
    guard let interfaceController = carPlayManager.interfaceController else {
        preconditionFailure("Instance of CPInterfaceController should be valid.")
    }
    let window = CPWindow()
    
    carPlayManager.application(UIApplication.shared,
                               didDisconnectCarInterfaceController: interfaceController,
                               from: window)
}

@available(iOS 12.0, *)
func createValidRouteChoice() -> CPRouteChoice {
    let routeChoice = CPRouteChoice(summaryVariants: ["summary"],
                                    additionalInformationVariants: ["additionalInformation"],
                                    selectionSummaryVariants: ["selectionSummary"])
    let navigationRouteOptions = NavigationRouteOptions(coordinates: [
        CLLocationCoordinate2D(latitude: 37.764793, longitude: -122.463161),
        CLLocationCoordinate2D(latitude: 34.054081, longitude: -118.243412),
    ])
    let routeResponseUserInfoKey = CPRouteChoice.RouteResponseUserInfo.key
    let routeResponse = Fixture.routeResponse(from: "route-with-banner-instructions",
                                              options: navigationRouteOptions)
    let routeResponseUserInfo: CPRouteChoice.RouteResponseUserInfo = .init(response: routeResponse,
                                                                           routeIndex: 0,
                                                                           options: navigationRouteOptions)
    let userInfo: CarPlayUserInfo = [
        routeResponseUserInfoKey: routeResponseUserInfo
    ]
    routeChoice.userInfo = userInfo
    
    return routeChoice
}

@available(iOS 12.0, *)
func createInvalidRouteChoice() -> CPRouteChoice {
    let routeChoice = CPRouteChoice(summaryVariants: ["summary"],
                                    additionalInformationVariants: ["additionalInformation"],
                                    selectionSummaryVariants: ["selectionSummary"])
    
    return routeChoice
}

@available(iOS 12.0, *)
func createTrip(_ routeChoice: CPRouteChoice) -> CPTrip {
    let trip = CPTrip(origin: MKMapItem(),
                      destination: MKMapItem(),
                      routeChoices: [routeChoice])
    
    return trip
}

@available(iOS 12.0, *)
class TestCarPlayManagerDelegate: CarPlayManagerDelegate {
    
    public fileprivate(set) var navigationInitiated = false
    public fileprivate(set) var currentService: NavigationService?

    func carPlayManager(_ carPlayManager: CarPlayManager,
                        navigationServiceFor routeResponse: RouteResponse,
                        routeIndex: Int,
                        routeOptions: RouteOptions,
                        desiredSimulationMode: SimulationMode) -> NavigationService? {
        let routeResponse = Fixture.routeResponse(from: jsonFileName, options: routeOptions)
        let navigationService = MapboxNavigationService(routeResponse: routeResponse,
                                                        routeIndex: routeIndex,
                                                        routeOptions: routeOptions,
                                                        customRoutingProvider: MapboxRoutingProvider(.offline),
                                                        credentials: Fixture.credentials,
                                                        locationSource: NavigationLocationManager(),
                                                        eventsManagerType: NavigationEventsManagerSpy.self,
                                                        simulating: desiredSimulationMode)
        return navigationService
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        didBeginNavigationWith service: NavigationService) {
        currentService = service
    }
    
    func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager,
                                        byCanceling canceled: Bool) {
        currentService = nil
    }
    
    func carPlayManager(_ carPlayManager: CarPlayManager,
                        didPresent navigationViewController: CarPlayNavigationViewController) {
        navigationInitiated = true
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
    
    var fakeSession: CPNavigationSession!

    override func showTripPreviews(_ tripPreviews: [CPTrip], textConfiguration: CPTripPreviewTextConfiguration?) {
        currentTripPreviews = tripPreviews
        currentPreviewTextConfiguration = textConfiguration
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
