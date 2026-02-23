import Foundation

enum UpdateRouteReason: Equatable, Sendable {
    case undefined
    case alternative
    case fastestRoute
    case reroute

    var shouldPlayRerouteSound: Bool {
        switch self {
        case .fastestRoute, .reroute:
            return true
        case .undefined, .alternative:
            return false
        }
    }

    var isProactive: Bool {
        return self == .fastestRoute
    }
}
