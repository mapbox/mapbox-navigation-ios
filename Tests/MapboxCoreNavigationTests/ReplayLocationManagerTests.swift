import Foundation
@testable import MapboxCoreNavigation
import XCTest
import CoreLocation
import TestHelper

final class ReplayLocationManagerTests: TestCase {
    func testOneLocationReplay() {
        let manager = ReplayLocationManager(locations: [.init(latitude: 0, longitude: 0)])
        manager.speedMultiplier = 100
        var ticksCount: Int = 0

        var previousLocation: CLLocation?
        manager.onTick = { (_, location) in
            if let previousLocation = previousLocation {
                XCTAssertGreaterThan(location.timestamp.timeIntervalSince(previousLocation.timestamp), 0)
            }
            previousLocation = location
            ticksCount += 1
        }
        manager.replayCompletionHandler = { _ in true }
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
        manager.replayCompletionHandler = { _ in return false }
        manager.startUpdatingLocation()
        RunLoop.current.run(until: Date().addingTimeInterval(2))
        XCTAssertEqual(ticksCount, 1)
    }

    func testInitializationUpdatesRecordedTimestamps() {
        let deltaBetweenLocations: TimeInterval = 2
        let firstLocationTimestamp = Date(timeIntervalSinceNow: -1000)
        let secondLocationTimestamp = firstLocationTimestamp.addingTimeInterval(deltaBetweenLocations)
        let firstLocation = CLLocation(coordinate: .init(latitude: 0, longitude: 0),
                                       altitude: 0,
                                       horizontalAccuracy: 0,
                                       verticalAccuracy: 0,
                                       timestamp: firstLocationTimestamp)
        let secondLocation = CLLocation(coordinate: .init(latitude: 1, longitude: 1),
                                        altitude: 0,
                                        horizontalAccuracy: 0,
                                        verticalAccuracy: 0,
                                        timestamp: secondLocationTimestamp)
        var manager = ReplayLocationManager(locations: [
            firstLocation,
            secondLocation,
        ])
        
        XCTAssertTrue(abs((manager.locations.first?.timestamp.timeIntervalSince1970 ?? 0) - Date().timeIntervalSince1970) < 1, "Locations should have timestamps shifted to present time.")
        XCTAssertEqual(manager.locations.first?.timestamp.timeIntervalSince1970,
                       (manager.locations.last?.timestamp.timeIntervalSince1970 ?? 0) - deltaBetweenLocations,
                       "Locations where not shifted proportionally")
        
        manager = ReplayLocationManager(history: History(events: [
            LocationUpdateHistoryEvent(timestamp: firstLocationTimestamp.timeIntervalSince1970,
                                       location: firstLocation),
            LocationUpdateHistoryEvent(timestamp: secondLocationTimestamp.timeIntervalSince1970,
                                       location: secondLocation)
        ]))
        
        XCTAssertTrue(abs((manager.locations.first?.timestamp.timeIntervalSince1970 ?? 0) - Date().timeIntervalSince1970) < 1, "History locations should have timestamps shifted to present time.")
        XCTAssertEqual(manager.locations.first?.timestamp.timeIntervalSince1970,
                       (manager.locations.last?.timestamp.timeIntervalSince1970 ?? 0) - deltaBetweenLocations,
                       "History locations where not shifted proportionally")
        
        XCTAssertTrue(abs((manager.events.first?.date.timeIntervalSince1970 ?? 0) - Date().timeIntervalSince1970) < 1, "History events should have timestamps shifted to present time.")
        XCTAssertEqual(manager.events.first?.date.timeIntervalSince1970,
                       (manager.events.last?.date.timeIntervalSince1970 ?? 0) - deltaBetweenLocations,
                       "History events where not shifted proportionally")
        
    }
    
    func testReplayLoopAlwaysAdvanceTimestamps() {
        let deltaBetweenLocations: TimeInterval = 2
        let firstLocationTimestamp = Date()
        let secondLocationTimestamp = firstLocationTimestamp.addingTimeInterval(deltaBetweenLocations)
        let manager = ReplayLocationManager(locations: [
            .init(coordinate: .init(latitude: 0, longitude: 0),
                  altitude: 0,
                  horizontalAccuracy: 0,
                  verticalAccuracy: 0,
                  timestamp: firstLocationTimestamp),
            .init(coordinate: .init(latitude: 1, longitude: 1),
                  altitude: 0,
                  horizontalAccuracy: 0,
                  verticalAccuracy: 0,
                  timestamp: secondLocationTimestamp),
        ])
        manager.speedMultiplier = 1000
        var ticksCount: Int = 0

        var previousLocation: CLLocation?
        manager.onTick = { (idx, location) in
            if let previousLocation = previousLocation {
                if idx > 0 {
                    XCTAssertEqual(location.timestamp.timeIntervalSince(previousLocation.timestamp), deltaBetweenLocations)
                }
                else {
                    XCTAssertEqual(location.timestamp.timeIntervalSince(previousLocation.timestamp), 1)
                }
            }
            previousLocation = location
            ticksCount += 1
        }
        manager.replayCompletionHandler = { _ in true }
        manager.startUpdatingLocation()
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        XCTAssertGreaterThan(ticksCount, 1)
    }
    
    func testHistoryInitializationDoesNotLooseCustomEvents() {
        let firstLocation = CLLocation(coordinate: .init(latitude: 0, longitude: 0),
                                       altitude: 0,
                                       horizontalAccuracy: 0,
                                       verticalAccuracy: 0,
                                       timestamp: Date())
        let secondLocation = CLLocation(coordinate: .init(latitude: 1, longitude: 1),
                                        altitude: 0,
                                        horizontalAccuracy: 0,
                                        verticalAccuracy: 0,
                                        timestamp: Date())
        
        let manager = ReplayLocationManager(history: History(events: [
            LocationUpdateHistoryEvent(timestamp: Date().timeIntervalSince1970,
                                       location: firstLocation),
            UserPushedHistoryEvent(timestamp: Date().timeIntervalSince1970,
                                   type: "test",
                                   properties: "properties"),
            LocationUpdateHistoryEvent(timestamp: Date().timeIntervalSince1970,
                                       location: secondLocation)
        ]))
        
        XCTAssert(manager.events.contains {
            guard case let .historyEvent(event) = $0.kind else { return false }
            
            return event is UserPushedHistoryEvent
        })
    }
}
