import CoreLocation
import MapboxDirections
import MapboxMaps
@testable import MapboxNavigationCore
@testable import MapboxNavigationUIKit
import SnapshotTesting
import TestHelper
import XCTest

class ManeuverArrowSnapshotTests: TestCase {
    let waypointRoute = Fixture.route(from: "waypoint-after-turn", options: NavigationRouteOptions(coordinates: [
        CLLocationCoordinate2D(latitude: 37.787358, longitude: -122.408231),
        CLLocationCoordinate2D(latitude: 37.790177, longitude: -122.408687),
        CLLocationCoordinate2D(latitude: 37.788986, longitude: -122.406892),
    ]))

    override func setUp() {
        super.setUp()
        DayStyle().apply()
    }

    @MainActor
    func testManeuverArrowHandlesWaypointsCorrectly() {
        let plotter = NavigationPlotter(frame: CGRect(origin: .zero, size: CGSize(width: 1000, height: 1000)))
        plotter.routePlotters = [RoutePlotter(route: waypointRoute)]
        let polyline = waypointRoute.polylineAroundManeuver(
            legIndex: 0,
            stepIndex: waypointRoute.legs.first!.steps.count - 1,
            distance: 100.0
        )
        let linePlotter = LinePlotter(
            coordinates: polyline.coordinates,
            color: .red,
            lineWidth: 5.0,
            drawIndexesAsText: false
        )
        plotter.linePlotters = [linePlotter]
        print(polyline.coordinates.count)
        assertImageSnapshot(matching: plotter, as: .image(precision: 0.99))
    }
}
