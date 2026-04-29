import Foundation
import MapboxNavigationNative_Private

extension MapboxNavigator {
    enum SetRouteReason {
        case newRoute
        case reroute(RerouteReason?)
        case alternatives
        case fasterRoute
        case fallbackToOffline
        case restoreToOnline
    }
}

extension MapboxNavigator.SetRouteReason {
    var isReroute: Bool {
        if case .reroute = self { true } else { false }
    }

    var navNativeValue: MapboxNavigationNative_Private.SetRoutesReason {
        switch self {
        case .newRoute:
            return .newRoute
        case .alternatives:
            return .alternative
        case .reroute:
            return .reroute
        case .fallbackToOffline:
            return .fallbackToOffline
        case .restoreToOnline:
            return .restoreToOnline
        case .fasterRoute:
            return .fastestRoute
        }
    }
}
