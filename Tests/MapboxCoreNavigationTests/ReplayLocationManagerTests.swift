import Foundation
@testable import MapboxCoreNavigation
import XCTest

final class ReplayLocationManagerTests: XCTestCase {
    func testOneLocationReplay() {
        let manager = ReplayLocationManager(locations: [.init(latitude: 0, longitude: 0)])
        var ticksCount: Int = 0
        
        manager.onTick = { _, _ in
            ticksCount += 1
        }
        manager.startUpdatingLocation()
        RunLoop.current.run(until: Date().addingTimeInterval(2))
        XCTAssertGreaterThan(ticksCount, 1)
    }

    func testOneLocationReplayWithoutLoop() {
        let manager = ReplayLocationManager(locations: [.init(latitude: 0, longitude: 0)])
        var ticksCount: Int = 0

        manager.onTick = { _, _ in
            ticksCount += 1
        }
        manager.onReplayLoopCompleted = { _ in return false }
        manager.startUpdatingLocation()
        RunLoop.current.run(until: Date().addingTimeInterval(2))
        XCTAssertEqual(ticksCount, 1)
    }
}
