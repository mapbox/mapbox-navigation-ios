import MapboxDirections
import CoreLocation
import XCTest
import MapboxNavigationNative
@testable import MapboxCoreNavigation

public final class TestNavigationStatusProvider {
    public static func createNavigationStatus(with speedLimit: SpeedLimit? = nil) -> NavigationStatus {
        let location = FixLocation(CLLocation(latitude: 37.788443, longitude: -122.4020258))
        let road = MapboxNavigationNative.Road(text: "name", imageBaseUrl: "base image url", shield: nil)
        let mapMatch = MapMatch(position: .init(edgeId: 0, percentAlong: 0), proba: 42)
        let mapMatcherOutput = MapMatcherOutput(matches: [mapMatch], isTeleport: false)
        return .init(routeState: .tracking,
                     locatedAlternativeRouteId: nil,
                     stale: false,
                     location: location,
                     routeIndex: 0,
                     legIndex: 0,
                     step: 0,
                     isFallback: false,
                     inTunnel: false,
                     predicted: 10,
                     geometryIndex: 0,
                     shapeIndex: 0,
                     intersectionIndex: 0,
                     roads: [road],
                     voiceInstruction: nil,
                     bannerInstruction: nil,
                     speedLimit: speedLimit,
                     keyPoints: [],
                     mapMatcherOutput: mapMatcherOutput,
                     offRoadProba: 0,
                     activeGuidanceInfo: nil,
                     upcomingRouteAlerts: [],
                     nextWaypointIndex: 0,
                     layer: nil)
    }
}
