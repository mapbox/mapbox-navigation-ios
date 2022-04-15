import Foundation
import MapboxDirections
import MapboxNavigationNative
import Turf

/**
 Representation of an alternative route with relation to the original.
 
 This object contains main and alternative routes which are sharing same origin and destination points, but differ at some point.
 */
public class AlternativeRoute: Identifiable {
    /// Alternative route identificator type
    public typealias ID = UInt32
    /// Breif stats of a route for travelling
    public typealias Stats = (distance: LocationDistance, duration: TimeInterval)

    /// Alternative route identificator.
    ///
    /// It is unique withing the same navigation session.
    public let id: ID
    /// Original (main) route data
    public let indexedRouteResponse: IndexedRouteResponse
    /// Intersection on the main route, where alternative route branches.
    public let mainRouteIntersection: Intersection
    /// Intersection on the alternative route, where it splits from the main route.
    public let alternativeRouteIntersection: Intersection
    /// Alternative route statistics, counting from the split point.
    public let statsFromFork: Stats
    /// Alternative route statistics, counting from it's origin.
    public let statsFromOrigin: Stats

    init?(mainRoute: Route, alternativeRoute nativeRouteAlternative: RouteAlternative) {
        self.id = nativeRouteAlternative.id
        guard let decoded = RerouteController.decode(routeRequest: nativeRouteAlternative.route.getRequestUri(),
                                                     routeResponse: nativeRouteAlternative.route.getResponseJson()) else {
            return nil
        }

        self.indexedRouteResponse = .init(routeResponse: decoded.routeResponse,
                                          routeIndex: Int(nativeRouteAlternative.route.getRouteIndex()))

        var legIndex = Int(nativeRouteAlternative.mainRouteFork.legIndex)
        var segmentIndex = Int(nativeRouteAlternative.mainRouteFork.segmentIndex)

        guard let mainIntersection = mainRoute.findIntersection(on: legIndex, by: segmentIndex) else {
            return nil
        }
        self.mainRouteIntersection = mainIntersection

        legIndex = Int(nativeRouteAlternative.alternativeRouteFork.legIndex)
        segmentIndex = Int(nativeRouteAlternative.alternativeRouteFork.segmentIndex)

        guard let alternativeIntersection = indexedRouteResponse.currentRoute?.findIntersection(on: legIndex, by: segmentIndex) else {
            return nil
        }
        self.alternativeRouteIntersection = alternativeIntersection

        self.statsFromFork = (nativeRouteAlternative.infoFromFork.distance,
                              nativeRouteAlternative.infoFromFork.duration)
        self.statsFromOrigin = (nativeRouteAlternative.infoFromStart.distance,
                                nativeRouteAlternative.infoFromStart.duration)
    }
}

extension Route {
    fileprivate func findIntersection(on legIndex: Int, by segmentIndex: Int) -> Intersection? {
        if legs.count > legIndex {
            let leg = legs[legIndex]
            if let stepindex = leg.segmentRangesByStep.firstIndex(where: { $0.contains(segmentIndex) }) {
                if let intersectionIndex = leg.steps[stepindex].segmentIndicesByIntersection?.firstIndex(where: { $0 == segmentIndex }) {
                    return leg.steps[stepindex].intersections?[intersectionIndex]
                }
            }
        }

        return nil
    }
}
