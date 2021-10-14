import Foundation
import MapboxCoreNavigation

extension ReplayLocationManager {
    public var expectedReplayTime: TimeInterval {
        TimeInterval(locations.count) / speedMultiplier + Double(locations.count) * 0.01
    }
}
