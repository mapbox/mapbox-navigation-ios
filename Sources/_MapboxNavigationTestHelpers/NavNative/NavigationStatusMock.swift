import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private

extension NavigationStatus {
    public static func mock(
        routeState: RouteState = .tracking,
        locatedAlternativeRouteId: String? = nil,
        primaryRouteId: String = "",
        stale: Bool = false,
        activeGuidanceInfo: ActiveGuidanceInfo? = .mock(),
        location: CLLocation = CLLocation(latitude: 37.788443, longitude: -122.4020258),
        routeIndex: UInt32 = 0,
        legIndex: UInt32 = 0,
        stepIndex: UInt32 = 0,
        isFallback: Bool = false,
        inTunnel: Bool = false,
        inParkingAisle: Bool = false,
        inRoundabout: Bool = false,
        predicted: TimeInterval = 10,
        geometryIndex: UInt32 = 0,
        shapeIndex: UInt32 = 0,
        intersectionIndex: UInt32 = 0,
        turnLanes: [TurnLane] = [],
        alternativeRouteIndices: [RouteIndices] = [],
        roads: [MapboxNavigationNative_Private.RoadName] = [.mock()],
        voiceInstruction: VoiceInstruction? = nil,
        bannerInstruction: BannerInstruction? = nil,
        speedLimit: MapboxNavigationNative_Private.SpeedLimit = .init(
            speed: nil,
            localeUnit: .milesPerHour,
            localeSign: .mutcd
        ),
        keyPoints: [FixLocation] = [],
        mapMatcherOutput: MapMatcherOutput = .mock(),
        offRoadProba: Float = 0,
        offRoadStateProvider: OffRoadStateProvider = .unknown,
        upcomingRouteAlertUpdates: [UpcomingRouteAlertUpdate] = [],
        nextWaypointIndex: UInt32 = 0,
        layer: NSNumber? = nil,
        isSyntheticLocation: Bool = false,
        correctedLocationData: CorrectedLocationData? = nil,
        hdMatchingResult: HdMatchingResult? = nil,
        mapMatchedSystemTime: Date = NavigationStatus.date,
        isAdasDataAvailable: NSNumber? = nil
    ) -> Self {
        let fixLocation = FixLocation(location)
        let primaryRouteIndices = RouteIndices(
            routeId: RouteIdentifier(uuid: primaryRouteId, index: routeIndex),
            legIndex: legIndex,
            step: stepIndex,
            geometryIndex: geometryIndex,
            legShapeIndex: shapeIndex,
            intersectionIndex: intersectionIndex,
            isForkPointPassed: false
        )
        return .init(
            routeState: routeState,
            stale: stale,
            location: fixLocation,
            isFallback: isFallback,
            inTunnel: inTunnel,
            inParkingAisle: inParkingAisle,
            inRoundabout: inRoundabout,
            predicted: predicted,
            turnLanes: turnLanes,
            roads: roads,
            primaryRouteIndices: primaryRouteIndices,
            alternativeRouteIndices: alternativeRouteIndices,
            locatedAlternativeRouteId: locatedAlternativeRouteId,
            voiceInstruction: voiceInstruction,
            bannerInstruction: bannerInstruction,
            speedLimit: speedLimit,
            keyPoints: keyPoints,
            mapMatcherOutput: mapMatcherOutput,
            offRoadProba: offRoadProba,
            offRoadStateProvider: offRoadStateProvider,
            activeGuidanceInfo: activeGuidanceInfo,
            upcomingRouteAlertUpdates: upcomingRouteAlertUpdates,
            nextWaypointIndex: nextWaypointIndex,
            layer: layer,
            isSyntheticLocation: isSyntheticLocation,
            correctedLocationData: correctedLocationData,
            hdMatchingResult: hdMatchingResult,
            mapMatchedSystemTime: mapMatchedSystemTime,
            isAdasDataAvailable: isAdasDataAvailable
        )
    }

    public static let date: Date = "2024-01-01T15:00:00.000Z".ISO8601Date!
}

extension MapMatcherOutput {
    public static func mock(
        matches: [MapMatch] = [.mock()],
        isTeleport: Bool = false,
        totalCandidatesCount: UInt32 = 1
    ) -> Self {
        self.init(
            matches: matches,
            isTeleport: isTeleport,
            totalCandidatesCount: totalCandidatesCount
        )
    }
}

extension MapMatch {
    public static func mock(
        position: GraphPosition = .init(edgeId: 0, percentAlong: 0),
        proba: Float = 0,
        fetchedCandidateIndex: UInt32 = 0
    ) -> Self {
        self.init(position: position, proba: proba, fetchedCandidateIndex: fetchedCandidateIndex)
    }
}

extension ActiveGuidanceInfo {
    public static func mock(
        routeProgress: ActiveGuidanceProgress = .mock(),
        legProgress: ActiveGuidanceProgress = .mock(),
        stepProgress: ActiveGuidanceProgress = .mock(),
        linkProgress: ActiveGuidanceProgress = .mock()
    ) -> Self {
        self.init(
            routeProgress: routeProgress,
            legProgress: legProgress,
            step: stepProgress,
            linkProgress: linkProgress
        )
    }
}

extension ActiveGuidanceProgress {
    public static func mock(
        distanceTraveled: Double = 0,
        fractionTraveled: Double = 0,
        remainingDistance: Double = 0,
        remainingDuration: TimeInterval = 0
    ) -> Self {
        self.init(
            distanceTraveled: distanceTraveled,
            fractionTraveled: fractionTraveled,
            remainingDistance: remainingDistance,
            remainingDuration: remainingDuration
        )
    }
}

extension MapboxNavigationNative_Private.RoadName {
    public static func mock(
        text: String = "name",
        language: String = "lang",
        imageBaseUrl: String = "base_image_url",
        shield: Shield? = .mock()
    ) -> Self {
        self.init(text: text, language: language, imageBaseUrl: imageBaseUrl, shield: shield)
    }
}

extension Shield {
    public static func mock(
        baseUrl: String = "shield_url",
        displayRef: String = "ref",
        name: String = "shield",
        textColor: String = ""
    ) -> Self {
        self.init(baseUrl: baseUrl, displayRef: displayRef, name: name, textColor: textColor)
    }
}

extension VoiceInstruction {
    public static func mock(
        ssmlAnnouncement: String = "ssmlAnnouncement",
        announcement: String = "announcement",
        remainingStepDistance: Float = 10.0,
        index: Int = 0
    ) -> Self {
        self.init(
            ssmlAnnouncement: ssmlAnnouncement,
            announcement: announcement,
            remainingStepDistance: remainingStepDistance,
            index: UInt32(index)
        )
    }
}

extension BannerInstruction {
    public static func mock(
        primary: BannerSection = .mock(),
        view: BannerSection? = nil,
        secondary: BannerSection? = nil,
        sub: BannerSection? = nil,
        remainingStepDistance: Float = 10.0,
        index: Int = 0
    ) -> Self {
        self.init(
            primary: primary,
            view: view,
            secondary: secondary,
            sub: sub,
            remainingStepDistance: remainingStepDistance,
            index: UInt32(index)
        )
    }
}

extension BannerSection {
    public static func mock(
        text: String = "",
        type: String? = nil,
        modifier: String? = nil,
        degrees: NSNumber? = nil,
        drivingSide: String? = nil,
        components: [BannerComponent]? = nil
    ) -> Self {
        self.init(
            text: text,
            type: type,
            modifier: modifier,
            degrees: degrees,
            drivingSide: drivingSide,
            components: components
        )
    }
}
