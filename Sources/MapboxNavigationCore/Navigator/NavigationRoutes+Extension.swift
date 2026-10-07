import Foundation
import MapboxDirections
@preconcurrency import MapboxNavigationNative_Private

extension NavigationRoutes {
    /// Builds routes from a primary-first list of native route interfaces.
    init(routeInterfaces routes: [any RouteInterface]) async throws {
        guard let primary = routes.first else {
            throw NavigationRoutesError.emptyRoutes
        }

        let alternatives = Array(routes.dropFirst())
        let routesData = Environment.shared.routeParserClient.createRoutesData(primary, alternatives)

        let requestOptions: ResponseOptions
        switch primary.getMapboxAPI() {
        case .directions:
            guard let options = primary.getResponseOptions(RouteOptions.self) else {
                throw NavigationRoutesError.noRequestData
            }
            requestOptions = options
        case .mapMatching:
            guard let options = primary.getResponseOptions(MatchOptions.self) else {
                throw NavigationRoutesError.noRequestData
            }
            requestOptions = options
        @unknown default:
            throw NavigationRoutesError.noRequestData
        }

        try await self.init(routesData: routesData, options: requestOptions)
    }

    /// Identifiers of the main route followed by the alternatives that are currently offered.
    var routeIds: [String] {
        [mainRoute.routeId.rawValue] + alternativeRoutes.map(\.routeId.rawValue)
    }

    func areRefreshed(comparedTo other: NavigationRoutes) -> Bool {
        if mainRoute.isRefreshed(comparedTo: other.mainRoute) { return true }

        return allAlternativeRoutesWithIgnored.contains { alternative in
            guard let match = other.allAlternativeRoutesWithIgnored.first(where: { $0.routeId == alternative.routeId })
            else { return true }
            return NavigationRoute.routeHasRefreshableChanges(alternative.route, comparedTo: match.route)
        }
    }
}

extension NavigationRoute {
    func isRefreshed(comparedTo other: NavigationRoute) -> Bool {
        guard routeId == other.routeId else { return false }
        return Self.routeHasRefreshableChanges(route, comparedTo: other.route)
    }

    fileprivate static func routeHasRefreshableChanges(_ lhs: Route, comparedTo rhs: Route) -> Bool {
        if lhs.expectedTravelTime != rhs.expectedTravelTime {
            return true
        }
        for (lhsLeg, rhsLeg) in zip(lhs.legs, rhs.legs) {
            if hasRefreshableChange(lhsLeg.segmentCongestionLevels, rhsLeg.segmentCongestionLevels) ||
                hasRefreshableChange(lhsLeg.segmentNumericCongestionLevels, rhsLeg.segmentNumericCongestionLevels) ||
                hasRefreshableChange(lhsLeg.incidents, rhsLeg.incidents) ||
                hasRefreshableChange(lhsLeg.closures, rhsLeg.closures)
            {
                return true
            }
        }
        return false
    }

    private static func hasRefreshableChange<T: Equatable>(_ lhs: [T]?, _ rhs: [T]?) -> Bool {
        let normalizedLhs = lhs.flatMap { $0.isEmpty ? nil : $0 }
        let normalizedRhs = rhs.flatMap { $0.isEmpty ? nil : $0 }
        return normalizedLhs != normalizedRhs
    }
}
