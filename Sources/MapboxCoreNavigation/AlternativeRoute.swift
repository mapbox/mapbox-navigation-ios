import Foundation
import MapboxDirections
import MapboxNavigationNative
import Turf

/**
 Representation of an alternative route with relation to the original.
 
 This struct contains main and alternative routes which are sharing same origin and destination points, but differ at some point.
 */
public struct AlternativeRoute: Identifiable {
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
    public let infoFromDeviationPoint: RouteInfo
    /// Alternative route statistics, counting from it's origin.
    public let infoFromOrigin: RouteInfo
    /// The difference of distances between alternative and the main routes
    public let distanceDelta: LocationDistance
    /// The difference of expected travel time between alternative and the main routes
    public let expectedTravelTimeDelta: TimeInterval
    
    init?(mainRoute: Route, alternativeRoute nativeRouteAlternative: RouteAlternative) {
        self.id = nativeRouteAlternative.id
        guard let decoded = RerouteController.decode(routeRequest: nativeRouteAlternative.route.getRequestUri(),
                                                     routeResponse: nativeRouteAlternative.route.getResponseJson()) else {
            return nil
        }

        self.indexedRouteResponse = .init(routeResponse: decoded.routeResponse,
                                          routeIndex: Int(nativeRouteAlternative.route.getRouteIndex()),
                                          responseOrigin: nativeRouteAlternative.route.getRouterOrigin())
        
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

        self.infoFromDeviationPoint = .init(distance: nativeRouteAlternative.infoFromFork.distance,
                                            duration: nativeRouteAlternative.infoFromFork.duration)
        self.infoFromOrigin = .init(distance: nativeRouteAlternative.infoFromStart.distance,
                                    duration: nativeRouteAlternative.infoFromStart.duration)
        
        self.distanceDelta = infoFromOrigin.distance - mainRoute.distance
        self.expectedTravelTimeDelta = infoFromOrigin.duration - mainRoute.expectedTravelTime
    }
    
    /**
     :nodoc:
     Creates new `AlternativeRoute` instance.
     
     For test purposes only. SDK does not support custom `AlternativeRoute`s.
     */
    public init(id: ID,
                indexedRouteResponse: IndexedRouteResponse,
                mainRouteIntersection: Intersection,
                alternativeRouteIntersection: Intersection,
                infoFromDeviationPoint: RouteInfo,
                infoFromOrigin: RouteInfo,
                distanceDelta: LocationDistance,
                expectedTravelTimeDelta: TimeInterval) {
        self.id = id
        self.indexedRouteResponse = indexedRouteResponse
        self.mainRouteIntersection = mainRouteIntersection
        self.alternativeRouteIntersection = alternativeRouteIntersection
        self.infoFromDeviationPoint = infoFromDeviationPoint
        self.infoFromOrigin = infoFromOrigin
        self.distanceDelta = distanceDelta
        self.expectedTravelTimeDelta = expectedTravelTimeDelta
    }
}

extension Route {
    fileprivate func findIntersection(on legIndex: Int, by segmentIndex: Int) -> Intersection? {
        guard legs.count > legIndex else {
            return nil
        }
        
        let leg = legs[legIndex]
        guard let stepindex = leg.segmentRangesByStep.firstIndex(where: { $0.contains(segmentIndex) }) else {
            return nil
        }
        
        guard let intersectionIndex = leg.steps[stepindex].segmentIndicesByIntersection?.firstIndex(where: { $0 == segmentIndex }) else {
            return nil
        }
        
        return leg.steps[stepindex].intersections?[intersectionIndex]
    }
}
