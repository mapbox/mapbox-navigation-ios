import XCTest
import FBSnapshotTestCase
import MapboxDirections
import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class ManeuverArrowTests: FBSnapshotTestCase {
    
    let waypointRoute = Fixture.route(from: "waypoint-after-turn")

    
    

    override func setUp() {
        super.setUp()
        recordMode = false
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    
    func testManeuverArrowHandlesWaypointsCorrectly() {
        let plotter = RoutePlotter(frame: CGRect(origin: .zero, size: CGSize(width: 1000, height: 1000)))
        plotter.route = waypointRoute
        let polyline = waypointRoute.polylineAroundManeuver(legIndex: 0, stepIndex: waypointRoute.legs.first!.steps.count - 1, distance: 100.0)
        let coordPlotter = CoordinatePlotter.init(coordinates: polyline.coordinates, color: .red, drawIndexesAsText: false)
        plotter.coordinatePlotters = [coordPlotter]
        print(polyline.coordinates.count)
        
        
        verify(plotter)
    }

}
