import Foundation
import MapboxNavigationNative

/// :nodoc:
extension RouteState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalid:
            return "invalid"
        case .initialized:
            return "initialized"
        case .tracking:
            return "tracking"
        case .complete:
            return "complete"
        case .offRoute:
            return "offRoute"
        case .uncertain:
            return "uncertain"
        @unknown default:
            fatalError("Unknown RouteState value.")
        }
    }
}
