import Foundation
import MapboxDirections
import MapboxNavigationNative
import Turf

/// Additional reasonable routes besides the main roure that visit waypoints.
public struct AlternativeRoute: @unchecked Sendable {
    let nativeRoute: RouteInterface
    var isForkPointPassed: Bool = false

    /// A `Route` object that the current alternative route represents.
    public let route: Route

    /// Alternative route identifier type
    public typealias ID = UInt32
    /// Brief statistics of a route for traveling
    public struct RouteInfo {
        /// Expected travel distance
        public let distance: LocationDistance
        /// Expected travel duration
        public let duration: TimeInterval

        public init(distance: LocationDistance, duration: TimeInterval) {
            self.distance = distance
            self.duration = duration
        }
    }

    /// Holds related indices values of an intersection.
    public struct IntersectionGeometryIndices {
        /// The leg index within a route
        public let legIndex: Int
        /// The geometry index of an intersection within leg geometry
        public let legGeometryIndex: Int
        /// The geometry index of an intersection within route geometry
        public let routeGeometryIndex: Int
    }

    /// Alternative route identificator.
    ///
    /// It is unique within the same navigation session.
    public let id: ID
    /// Unique route id.
    public let routeId: RouteId
    /// Intersection on the main route, where alternative route branches.
    public let mainRouteIntersection: Intersection
    /// Indices values of an intersection on the main route
    public let mainRouteIntersectionIndices: IntersectionGeometryIndices
    /// Intersection on the alternative route, where it splits from the main route.
    public let alternativeRouteIntersection: Intersection
    /// Indices values of an intersection on the alternative route
    public let alternativeRouteIntersectionIndices: IntersectionGeometryIndices
    /// Alternative route statistics, counting from the split point.
    public let infoFromDeviationPoint: RouteInfo
    /// Alternative route statistics, counting from it's origin.
    public let infoFromOrigin: RouteInfo
    /// The difference of distances between alternative and the main routes
    public let distanceDelta: LocationDistance
    /// The difference of expected travel time between alternative and the main routes
    public let expectedTravelTimeDelta: TimeInterval

    public init?(mainRoute: Route, alternativeRoute nativeRouteAlternative: RouteAlternative) async {
        guard let route = try? await nativeRouteAlternative.route.convertToDirectionsRoute() else {
            return nil
        }

        self.init(mainRoute: mainRoute, alternativeRoute: route, nativeRouteAlternative: nativeRouteAlternative)
    }

    init?(mainRoute: Route, alternativeRoute: Route, nativeRouteAlternative: RouteAlternative) {
        self.nativeRoute = nativeRouteAlternative.route
        self.route = alternativeRoute

        self.id = nativeRouteAlternative.id
        self.routeId = .init(rawValue: nativeRouteAlternative.route.getRouteId())

        var legIndex = Int(nativeRouteAlternative.mainRouteFork.legIndex)
        var segmentIndex = Int(nativeRouteAlternative.mainRouteFork.segmentIndex)

        self.mainRouteIntersectionIndices = .init(
            legIndex: legIndex,
            legGeometryIndex: segmentIndex,
            routeGeometryIndex: Int(nativeRouteAlternative.mainRouteFork.geometryIndex)
        )

        guard let mainIntersection = mainRoute.findIntersection(on: legIndex, by: segmentIndex) else {
            return nil
        }
        self.mainRouteIntersection = mainIntersection

        legIndex = Int(nativeRouteAlternative.alternativeRouteFork.legIndex)
        segmentIndex = Int(nativeRouteAlternative.alternativeRouteFork.segmentIndex)
        self.alternativeRouteIntersectionIndices = .init(
            legIndex: legIndex,
            legGeometryIndex: segmentIndex,
            routeGeometryIndex: Int(nativeRouteAlternative.alternativeRouteFork.geometryIndex)
        )

        guard let alternativeIntersection = alternativeRoute.findIntersection(on: legIndex, by: segmentIndex) else {
            return nil
        }
        self.alternativeRouteIntersection = alternativeIntersection

        self.infoFromDeviationPoint = .init(
            distance: nativeRouteAlternative.infoFromFork.distance,
            duration: nativeRouteAlternative.infoFromFork.duration
        )
        self.infoFromOrigin = .init(
            distance: nativeRouteAlternative.infoFromStart.distance,
            duration: nativeRouteAlternative.infoFromStart.duration
        )

        self.distanceDelta = infoFromOrigin.distance - mainRoute.distance
        self.expectedTravelTimeDelta = infoFromOrigin.duration - mainRoute.expectedTravelTime
    }

    static func fromNative(
        alternativeRoutes: [RouteAlternative],
        relateveTo mainRoute: NavigationRoute
    ) async -> [AlternativeRoute] {
        var converted = [AlternativeRoute?](repeating: nil, count: alternativeRoutes.count)
        await withTaskGroup(of: (Int, AlternativeRoute?).self) { group in
            for (index, alternativeRoute) in alternativeRoutes.enumerated() {
                group.addTask {
                    let alternativeRoute = await AlternativeRoute(
                        mainRoute: mainRoute.route,
                        alternativeRoute: alternativeRoute
                    )
                    return (index, alternativeRoute)
                }
            }

            for await (index, alternativeRoute) in group {
                guard let alternativeRoute else {
                    Log.error(
                        "Alternative routes parsing lost route with id: \(alternativeRoutes[index].route.getRouteId())",
                        category: .navigation
                    )
                    continue
                }
                converted[index] = alternativeRoute
            }
        }

        return converted.compactMap { $0 }
    }
}

extension AlternativeRoute: Equatable {
    public static func == (lhs: AlternativeRoute, rhs: AlternativeRoute) -> Bool {
        return lhs.routeId == rhs.routeId &&
            lhs.route == rhs.route
    }
}

extension Route {
    fileprivate func findIntersection(on legIndex: Int, by segmentIndex: Int) -> Intersection? {
        guard legs.count > legIndex else {
            return nil
        }

        var leg = legs[legIndex]
        guard let stepindex = leg.segmentRangesByStep.firstIndex(where: { $0.contains(segmentIndex) }) else {
            return nil
        }

        guard let intersectionIndex = leg.steps[stepindex].segmentIndicesByIntersection?
            .firstIndex(where: { $0 == segmentIndex })
        else {
            return nil
        }

        return leg.steps[stepindex].intersections?[intersectionIndex]
    }
}
