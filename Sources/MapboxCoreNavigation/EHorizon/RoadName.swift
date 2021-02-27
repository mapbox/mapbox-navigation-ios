import Foundation
import MapboxNavigationNative

public struct RoadName {

    public let name: String

    public let isShielded: Bool

    init(_ native: MapboxNavigationNative.RoadName) {
        self.name = native.name
        self.isShielded = native.isShielded
    }
}
