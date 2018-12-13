import XCTest
import FBSnapshotTestCase
import Turf
import TestHelper
import MapboxDirections
@testable import MapboxCoreNavigation
@testable import MapboxNavigation


class HistoricRouteProgressTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        recordMode = false
        agnosticOptions = []
    }

    func testHistoricRouteProgress() {
        // Short initial route
        let route = Fixture.route(from: "historic-route-progress")
        // Trace of a detour from the initial origin to the destination
        let trace = Fixture.locations(from: "historic-route-progress.trace")
        
        let view = NavigationPlotter(frame: CGRect(origin: .zero, size: CGSize(width: 1000, height: 1000)))
        view.routePlotters = [RoutePlotter(route: route, color: .route, lineWidth: 8, drawDotIndicator: false, drawTextIndicator: false)]
        view.linePlotters = [LinePlotter(coordinates: trace.map { $0.coordinate }, color: .gray, lineWidth: 4, drawIndexesAsText: false)]
        
        verify(view)
    }
}
