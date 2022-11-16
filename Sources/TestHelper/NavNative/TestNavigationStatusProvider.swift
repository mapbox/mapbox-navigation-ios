import MapboxDirections
import CoreLocation
import XCTest
import MapboxNavigationNative
@testable import MapboxCoreNavigation

public final class TestNavigationStatusProvider {
    public static func createNavigationStatus(routeState: RouteState = .tracking,
                                              location: CLLocation? = nil,
                                              routeIndex: UInt32 = 0,
                                              legIndex: UInt32 = 0,
                                              stepIndex: UInt32 = 0,
                                              geometryIndex: UInt32 = 0,
                                              shapeIndex: UInt32 = 0,
                                              intersectionIndex: UInt32 = 0,
                                              voiceInstruction: VoiceInstruction? = nil,
                                              bannerInstruction: BannerInstruction? = nil,
                                              speedLimit: SpeedLimit? = nil,
                                              activeGuidanceInfo: ActiveGuidanceInfo? = nil) -> NavigationStatus {
        let fixLocation = FixLocation(location ?? CLLocation(latitude: 37.788443, longitude: -122.4020258))
        let shield = Shield(baseUrl: "shield_url", displayRef: "ref", name: "shield", textColor: "")
        let road = MapboxNavigationNative.Road(text: "name", imageBaseUrl: "base_image_url", shield: shield)
        let mapMatch = MapMatch(position: .init(edgeId: 0, percentAlong: 0), proba: 42)
        let mapMatcherOutput = MapMatcherOutput(matches: [mapMatch], isTeleport: false)
        return .init(routeState: routeState,
                     locatedAlternativeRouteId: nil,
                     stale: false,
                     location: fixLocation,
                     routeIndex: routeIndex,
                     legIndex: legIndex,
                     step: stepIndex,
                     isFallback: false,
                     inTunnel: false,
                     predicted: 10,
                     geometryIndex: geometryIndex,
                     shapeIndex: shapeIndex,
                     intersectionIndex: intersectionIndex,
                     roads: [road],
                     voiceInstruction: voiceInstruction,
                     bannerInstruction: bannerInstruction,
                     speedLimit: speedLimit,
                     keyPoints: [],
                     mapMatcherOutput: mapMatcherOutput,
                     offRoadProba: 0,
                     activeGuidanceInfo: activeGuidanceInfo,
                     upcomingRouteAlerts: [],
                     nextWaypointIndex: 0,
                     layer: nil)
    }
}
