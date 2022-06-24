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
                infoFromOrigin: RouteInfo) {
        self.id = id
        self.indexedRouteResponse = indexedRouteResponse
        self.mainRouteIntersection = mainRouteIntersection
        self.alternativeRouteIntersection = alternativeRouteIntersection
        self.infoFromDeviationPoint = infoFromDeviationPoint
        self.infoFromOrigin = infoFromOrigin
    }
}

fileprivate func findIntersectionIndices(for intersection: Intersection, in route: Route) -> (legIndex: UInt32, segmentIndex: UInt32)? {
    for (legIndex, leg) in route.legs.enumerated() {
        for step in leg.steps {
            if let index = step.intersections?.firstIndex(of: intersection),
               let segmentIndex = step.segmentIndicesByIntersection?[index] {
                return (UInt32(legIndex), UInt32(segmentIndex))
            }
        }
    }
    return nil
}

extension RouteAlternative {

    /// Creates a fake `RouteAlternative` repeating the given route. For test purposes only.
    convenience init?(repeating indexedRouteResponse: IndexedRouteResponse, id: UInt32) {
        guard case let .route(routeOptions) = indexedRouteResponse.routeResponse.options,
            let mainRoute = indexedRouteResponse.currentRoute else {
            return nil
        }
        let encoder = JSONEncoder()
        encoder.userInfo[.options] = routeOptions
        guard let routeData = try? encoder.encode(indexedRouteResponse.routeResponse),
              let routeJSONString = String(data: routeData, encoding: .utf8) else {
                  return nil
        }

        let routeRequest = Directions(credentials: indexedRouteResponse.routeResponse.credentials)
                                .url(forCalculating: routeOptions).absoluteString

        let parsedRoutes = RouteParser.parseDirectionsResponse(forResponse: routeJSONString,
                                                               request: routeRequest,
                                                               routeOrigin: .online)

        guard let routeInterface = (parsedRoutes.value as? [RouteInterface])?.first else {
            return nil
        }
        guard let lastIntersection = mainRoute.legs.last?.steps.last?.intersections?.last,
              let intersectionData = findIntersectionIndices(for: lastIntersection,
                                                             in: mainRoute) else {
            return nil
        }
        
        self.init(id: id,
                  route: routeInterface,
                  mainRouteFork: .init(location: lastIntersection.location,
                                       geometryIndex: intersectionData.segmentIndex,
                                       segmentIndex: intersectionData.segmentIndex,
                                       legIndex: intersectionData.legIndex),
                  alternativeRouteFork: .init(location: lastIntersection.location,
                                              geometryIndex: intersectionData.segmentIndex,
                                              segmentIndex: intersectionData.segmentIndex,
                                              legIndex: intersectionData.legIndex),
                  infoFromFork: .init(distance: 0,
                                      duration: 0),
                  infoFromStart: .init(distance: mainRoute.distance,
                                       duration: mainRoute.expectedTravelTime),
                  isNew: true)
    }
}

extension Route {
    fileprivate func findIntersection(on legIndex: Int, by segmentIndex: Int) -> Intersection? {
        guard legs.count > legIndex else {
            return nil
        }
        
        let leg = legs[legIndex]
        var stepindex = leg.segmentRangesByStep.firstIndex(where: { $0.contains(segmentIndex) })
        // last segment range (arrival) is empty, but it may still contain an intersection
        if stepindex == nil &&
            leg.segmentRangesByStep.last?.isEmpty ?? false &&
            leg.segmentRangesByStep.dropLast().last?.last == segmentIndex - 1 {
            stepindex = leg.segmentRangesByStep.endIndex - 1
        }
        guard let stepindex = stepindex else {
            return nil
        }
        
        guard let intersectionIndex = leg.steps[stepindex].segmentIndicesByIntersection?.firstIndex(where: { $0 == segmentIndex }) else {
            return nil
        }
        
        return leg.steps[stepindex].intersections?[intersectionIndex]
    }
}
