import CarPlay
import CarPlayTestHelper
@testable import MapboxNavigationCore
import MapboxNavigationNative
@testable import MapboxNavigationUIKit
import TestHelper
import XCTest

class CarPlayNavigationViewControllerTests: TestCase {
    class MapTemplateMock: CPMapTemplate, @unchecked Sendable {
        var travelEstimates: CPTravelEstimates?
        var navigationSession: CPNavigationSession!

        override func update(
            _ estimates: CPTravelEstimates,
            for trip: CPTrip,
            with timeRemainingColor: CPTimeRemainingColor
        ) {
            travelEstimates = estimates
        }

        override func startNavigationSession(for trip: CPTrip) -> CPNavigationSession {
            return navigationSession
        }
    }

    @MainActor
    func testTravelEstimates() async {
        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 9.519172, longitude: 47.210823),
            CLLocationCoordinate2D(latitude: 9.52222, longitude: 47.214268),
            CLLocationCoordinate2D(latitude: 47.212326, longitude: 9.512569),
        ])
        let routes = await Fixture.navigationRoutes(from: "multileg-route", options: routeOptions)

        let mapTemplateMock = MapTemplateMock()
        let navigationSession = CPNavigationSessionFake(maneuvers: [CPManeuver()])
        mapTemplateMock.navigationSession = navigationSession

        let interfaceController = FakeCPInterfaceController(context: #function)

        let carPlayManager = CarPlayManager(
            navigationProvider: navigationProvider,
            carPlayNavigationViewControllerClass: CarPlayNavigationViewControllerTestable.self
        )

        let core = navigationProvider.mapboxNavigation
        let carPlayNavigationViewController = CarPlayNavigationViewController(
            accessToken: .mockedAccessToken,
            core: core,
            mapTemplate: mapTemplateMock,
            interfaceController: interfaceController,
            manager: carPlayManager,
            styles: nil,
            navigationRoutes: routes
        )
        core.tripSession().startActiveGuidance(with: routes, startLegIndex: 0)
        await navigationProvider.navigator().updateMapMatching(status: newNavigationStatus)

        let routeProgress = RouteProgress(
            navigationRoutes: routes,
            waypoints: routeOptions.waypoints,
            congestionConfiguration: .default
        )
        let trip = CPTrip(
            origin: MKMapItem(),
            destination: MKMapItem(),
            routeChoices: []
        )
        carPlayNavigationViewController.startNavigationSession(for: trip)

        carPlayNavigationViewController.progressDidChange(routeProgress)

        let distanceRemaining = Measurement(distance: routeProgress.distanceRemaining).localized()
        let expectedTravelEstimates = CPTravelEstimates(
            distanceRemaining: distanceRemaining,
            timeRemaining: routeProgress.durationRemaining
        )
        let actualTravelEstimates = mapTemplateMock.travelEstimates

        XCTAssertEqual(
            actualTravelEstimates?.distanceRemaining.value,
            expectedTravelEstimates.distanceRemaining.value,
            "Remaining distances should be equal."
        )
        XCTAssertEqual(
            actualTravelEstimates?.timeRemaining,
            expectedTravelEstimates.timeRemaining,
            "Remaining times should be equal."
        )
    }

    var newNavigationStatus: NavigationStatus {
        let location = CLLocation(latitude: 9.519172, longitude: 47.210823)
        return TestNavigationStatusProvider.createNavigationStatus(location: location)
    }
}
