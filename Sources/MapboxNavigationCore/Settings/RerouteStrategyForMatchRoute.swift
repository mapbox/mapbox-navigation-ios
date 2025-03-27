import MapboxNavigationNative

/// Reroute strategy for Map Matching API routes.
public struct RerouteStrategyForMatchRoute: Hashable, Sendable {
    enum Kind {
        case rerouteDisabled
        case navigateToFinalDestination
    }

    let kind: Kind

    init(kind: Kind) {
        self.kind = kind
    }

    /// Do nothing and skip reroute. Show the initial Map Matching API route
    /// and allow the user to return to it.
    public static let rerouteDisabled = Self(kind: .rerouteDisabled)

    /// Reroute by creating a Directions API route from the current position
    /// to the final destination of the original Map Matching API route.
    public static let navigateToFinalDestination = Self(kind: .navigateToFinalDestination)
}

extension RerouteStrategyForMatchRoute {
    var nativeValue: MapboxNavigationNative.RerouteStrategyForMatchRoute {
        switch kind {
        case .rerouteDisabled: .rerouteDisabled
        case .navigateToFinalDestination: .navigateToFinalDestination
        }
    }
}
