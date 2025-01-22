import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative
import XCTest

public enum TestNavigationStatusProvider {
    public static func createActiveStatus(
        routeState: RouteState = .tracking,
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
        upcomingRouteAlertUpdates: [UpcomingRouteAlertUpdate] = []
    ) -> NavigationStatus {
        let activeInfo = ActiveGuidanceInfo(
            routeProgress: .init(
                distanceTraveled: 0,
                fractionTraveled: 0,
                remainingDistance: 0,
                remainingDuration: 0
            ),
            legProgress: .init(
                distanceTraveled: 0,
                fractionTraveled: 0,
                remainingDistance: 0,
                remainingDuration: 0
            ),
            step: .init(
                distanceTraveled: 0,
                fractionTraveled: 0,
                remainingDistance: 0,
                remainingDuration: 0
            )
        )
        return Self.createNavigationStatus(
            routeState: routeState,
            location: location,
            routeIndex: routeIndex,
            legIndex: legIndex,
            stepIndex: stepIndex,
            geometryIndex: geometryIndex,
            shapeIndex: shapeIndex,
            intersectionIndex: intersectionIndex,
            roads: roads,
            voiceInstruction: voiceInstruction,
            bannerInstruction: bannerInstruction,
            activeGuidanceInfo: activeInfo,
            upcomingRouteAlertUpdates: upcomingRouteAlertUpdates
        )
    }

    public static func createNavigationStatus(
        routeState: RouteState = .tracking,
        location: CLLocation? = nil,
        routeIndex: UInt32 = 0,
        legIndex: UInt32 = 0,
        stepIndex: UInt32 = 0,
        geometryIndex: UInt32 = 0,
        shapeIndex: UInt32 = 0,
        intersectionIndex: UInt32 = 0,
        turnLanes: [TurnLane] = [],
        roads: [MapboxNavigationNative.RoadName]? = nil,
        voiceInstruction: VoiceInstruction? = nil,
        bannerInstruction: BannerInstruction? = nil,
        activeGuidanceInfo: ActiveGuidanceInfo? = nil,
        upcomingRouteAlertUpdates: [UpcomingRouteAlertUpdate] = []
    )
    -> NavigationStatus {
        let fixLocation = FixLocation(location ?? CLLocation(latitude: 37.788443, longitude: -122.4020258))
        let shield = Shield(baseUrl: "shield_url", displayRef: "ref", name: "shield", textColor: "")
        let road = MapboxNavigationNative.RoadName(
            text: "name",
            language: "lang",
            imageBaseUrl: "base_image_url",
            shield: shield
        )
        let roadNames = roads ?? [road]
        let mapMatch = MapMatch(position: .init(edgeId: 0, percentAlong: 0), proba: 42, fetchedCandidateIndex: 0)
        let mapMatcherOutput = MapMatcherOutput(matches: [mapMatch], isTeleport: false, totalCandidatesCount: 1)
        return .init(
            routeState: routeState,
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
            inRoundabout: false,
            predicted: 10,
            geometryIndex: geometryIndex,
            shapeIndex: shapeIndex,
            intersectionIndex: intersectionIndex,
            turnLanes: turnLanes,
            alternativeRouteIndices: [],
            roads: roadNames,
            voiceInstruction: voiceInstruction,
            bannerInstruction: bannerInstruction,
            speedLimit: .init(speed: nil, localeUnit: .kilometresPerHour, localeSign: .vienna),
            keyPoints: [],
            mapMatcherOutput: mapMatcherOutput,
            offRoadProba: 0,
            offRoadStateProvider: .unknown,
            activeGuidanceInfo: activeGuidanceInfo,
            upcomingRouteAlertUpdates: upcomingRouteAlertUpdates,
            nextWaypointIndex: 0,
            layer: nil,
            isSyntheticLocation: false,
            correctedLocationData: nil,
            hdMatchingResult: nil,
            mapMatchedSystemTime: date
        )
    }

    static let date: Date = "2024-01-01T15:00:00.000Z".ISO8601Date!
}
