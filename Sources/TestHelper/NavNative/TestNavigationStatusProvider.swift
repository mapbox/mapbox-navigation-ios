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
                                              roads: [MapboxNavigationNative.RoadName]? = nil,
                                              voiceInstruction: VoiceInstruction? = nil,
                                              bannerInstruction: BannerInstruction? = nil,
                                              speedLimit: SpeedLimit? = nil,
                                              activeGuidanceInfo: ActiveGuidanceInfo? = nil,
                                              upcomingRouteAlertUpdates: [UpcomingRouteAlertUpdate] = []) -> NavigationStatus {
        let fixLocation = FixLocation(location ?? CLLocation(latitude: 37.788443, longitude: -122.4020258))
        let shield = Shield(baseUrl: "shield_url", displayRef: "ref", name: "shield", textColor: "")
        let road = MapboxNavigationNative.RoadName(text: "name", language: "lang", imageBaseUrl: "base_image_url", shield: shield)
        let roadNames = roads ?? [road]
        let mapMatch = MapMatch(position: .init(edgeId: 0, percentAlong: 0), proba: 42)
        let mapMatcherOutput = MapMatcherOutput(matches: [mapMatch], isTeleport: false)
        return .init(routeState: routeState,
                     locatedAlternativeRouteId: nil,
                     primaryRouteId: nil,
                     stale: false,
                     location: fixLocation,
                     routeIndex: routeIndex,
                     legIndex: legIndex,
                     step: stepIndex,
                     isFallback: false,
                     inTunnel: false,
                     inParkingAisle: false,
                     predicted: 10,
                     geometryIndex: geometryIndex,
                     shapeIndex: shapeIndex,
                     intersectionIndex: intersectionIndex,
                     alternativeRouteIndices: [],
                     roads: roadNames,
                     voiceInstruction: voiceInstruction,
                     bannerInstruction: bannerInstruction,
                     speedLimit: speedLimit ?? .init(speed: nil, localeUnit: .kilometresPerHour, localeSign: .vienna),
                     keyPoints: [],
                     mapMatcherOutput: mapMatcherOutput,
                     offRoadProba: 0,
                     offRoadStateProvider: .unknown,
                     activeGuidanceInfo: activeGuidanceInfo,
                     upcomingRouteAlertUpdates: upcomingRouteAlertUpdates,
                     nextWaypointIndex: 0,
                     layer: nil,
                     isSyntheticLocation: false,
                     correctedLocationData: nil)
    }
}
