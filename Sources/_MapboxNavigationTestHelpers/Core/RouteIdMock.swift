import Foundation
import MapboxNavigationCore

extension RouteId {
    public static func mock(rawValue: String = UUID().uuidString) -> Self {
        RouteId(rawValue: rawValue)
    }
}
