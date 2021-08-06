import XCTest
import SnapshotTesting
import MapboxDirections
import TestHelper
import CoreLocation
import MapboxMaps
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class ManeuverArrowSnapshotTests: TestCase {
    let waypointRoute = Fixture.route(from: "waypoint-after-turn", options: NavigationRouteOptions(coordinates: [
        CLLocationCoordinate2D(latitude: 37.787358, longitude: -122.408231),
        CLLocationCoordinate2D(latitude: 37.790177, longitude: -122.408687),
        CLLocationCoordinate2D(latitude: 37.788986, longitude: -122.406892),
    ]))

    override func setUp() {
        super.setUp()
        isRecording = false
        DayStyle().apply()
    }
    
    func testManeuverArrowHandlesWaypointsCorrectly() {
        let plotter = NavigationPlotter(frame: CGRect(origin: .zero, size: CGSize(width: 1000, height: 1000)))
        plotter.routePlotters = [RoutePlotter(route: waypointRoute)]
        let polyline = waypointRoute.polylineAroundManeuver(legIndex: 0, stepIndex: waypointRoute.legs.first!.steps.count - 1, distance: 100.0)
        let linePlotter = LinePlotter.init(coordinates: polyline.coordinates, color: .red, lineWidth: 5.0, drawIndexesAsText: false)
        plotter.linePlotters = [linePlotter]
        print(polyline.coordinates.count)
        assertImageSnapshot(matching: plotter, as: .image(precision: 0.95))
    }
}
