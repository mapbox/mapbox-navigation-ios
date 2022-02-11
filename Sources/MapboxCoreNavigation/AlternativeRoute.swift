import Foundation
import MapboxDirections
import MapboxNavigationNative
import Turf

public class AlternativeRoute: Identifiable {
    public typealias ID = UInt32
    public typealias Stats = (distance: LocationDistance, duration: TimeInterval)
    
    public let id: ID
    
    public let indexedRouteResponse: IndexedRouteResponse
    public let mainRouteIntersection: Intersection
    public let alternativeRouteIntersection: Intersection
    public let statsFromFork: Stats
    public let statsFromOrigin: Stats
    
    init?(mainRoute: Route, alternativeRoute nativeRouteAlternative: RouteAlternative) {
        self.id = nativeRouteAlternative.id
        guard let decoded = Navigator.decode(routeRequest: nativeRouteAlternative.route.request,
                                             routeResponse: nativeRouteAlternative.route.response) else {
            return nil
        }

        self.indexedRouteResponse = .init(routeResponse: decoded.routeResponse,
                                          routeIndex: Int(nativeRouteAlternative.route.index))
        
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
