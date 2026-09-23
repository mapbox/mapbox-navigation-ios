import MapboxDirections
import MapboxMaps
@_spi(MapboxInternal) @testable import MapboxNavigationCore
import SnapshotTesting
import TestHelper
import XCTest

class LaneGuidanceCalloutViewSnapshotTests: TestCase {
    /// Lanes at the same intersection may have differing valid indications (e.g. one lane "straight", another
    /// "slight right"); each lane's callout arrow should reflect its own indication rather than a single value
    /// shared across the whole intersection.
    func testNonUniformLaneIndications() {
        let laneGuidanceData = IntersectionLaneGuidanceData(
            point: Point(LocationCoordinate2D(latitude: 0, longitude: 0)),
            approachLanes: [[.left], [.straightAhead, .left], [.right]],
            usableApproachLanes: IndexSet([0, 1]),
            laneValidIndications: [.left, .straightAhead, nil]
        )

        assertLaneGuidanceCalloutSnapshot(laneGuidanceData: laneGuidanceData)
    }

    /// The arrow drawn for a lane comes from that lane's own valid indication. `usableApproachLanes` does not
    /// take part in choosing it — it only selects the primary or secondary color — so the arrows here are the
    /// same as in ``testNonUniformLaneIndications()``, drawn in the secondary color.
    func testNonUniformLaneIndicationsWithoutUsableLanes() {
        let laneGuidanceData = IntersectionLaneGuidanceData(
            point: Point(LocationCoordinate2D(latitude: 0, longitude: 0)),
            approachLanes: [[.left], [.straightAhead, .left], [.right]],
            usableApproachLanes: nil,
            laneValidIndications: [.left, .straightAhead, nil]
        )

        assertLaneGuidanceCalloutSnapshot(laneGuidanceData: laneGuidanceData)
    }

    /// The common case, where every lane shares the same valid indication, should look the same as before.
    func testUniformLaneIndications() {
        let laneGuidanceData = IntersectionLaneGuidanceData(
            point: Point(LocationCoordinate2D(latitude: 0, longitude: 0)),
            approachLanes: [[.straightAhead], [.straightAhead, .right]],
            usableApproachLanes: IndexSet([0, 1]),
            laneValidIndications: [.straightAhead, .straightAhead]
        )

        assertLaneGuidanceCalloutSnapshot(laneGuidanceData: laneGuidanceData)
    }

    /// When no valid indication is available for a lane, its arrow falls back to the direction implied by its
    /// own indications.
    func testMissingLaneIndications() {
        let laneGuidanceData = IntersectionLaneGuidanceData(
            point: Point(LocationCoordinate2D(latitude: 0, longitude: 0)),
            approachLanes: [[.left], [.straightAhead]],
            usableApproachLanes: IndexSet([0, 1]),
            laneValidIndications: nil
        )

        assertLaneGuidanceCalloutSnapshot(laneGuidanceData: laneGuidanceData)
    }

    private func assertLaneGuidanceCalloutSnapshot(
        laneGuidanceData: IntersectionLaneGuidanceData,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line
    ) {
        let calloutView = LaneGuidanceCalloutView(laneGuidanceData: laneGuidanceData, mapStyleConfig: .testConfig)
        calloutView.backgroundColor = .white
        calloutView.frame = CGRect(origin: .zero, size: calloutView.intrinsicContentSize)
        calloutView.layoutIfNeeded()

        assertImageSnapshot(
            matching: calloutView,
            as: .image(precision: 0.99),
            file: file,
            testName: testName,
            line: line
        )
    }
}

extension MapStyleConfig {
    fileprivate static let testConfig = MapStyleConfig(
        routeCasingColor: .defaultRouteCasing,
        routeAlternateCasingColor: .defaultAlternateLineCasing,
        routeRestrictedAreaColor: .defaultRouteRestrictedAreaColor,
        traversedRouteColor: nil,
        maneuverArrowColor: .defaultManeuverArrow,
        maneuverArrowStrokeColor: .defaultManeuverArrowStroke,
        routeAnnotationSelectedColor: .defaultSelectedRouteAnnotationColor,
        routeAnnotationColor: .defaultRouteAnnotationColor,
        routeAnnotationSelectedTextColor: .defaultSelectedRouteAnnotationTextColor,
        routeAnnotationTextColor: .defaultRouteAnnotationTextColor,
        routeAnnotationSelectedCaptionTextColor: .defaultSelectedRouteAnnotationCaptionTextColor,
        routeAnnotationCaptionTextColor: .defaultRouteAnnotationCaptionTextColor,
        routeAnnotationMoreTimeTextColor: .defaultRouteAnnotationMoreTimeTextColor,
        routeAnnotationLessTimeTextColor: .defaultRouteAnnotationLessTimeTextColor,
        routeAnnotationTextFont: .defaultRouteAnnotationTextFont,
        routeAnnnotationCaptionTextFont: .defaultRouteAnnotationCaptionTextFont,
        routeLineTracksTraversal: true,
        routeLineWidthMultiplier: 1.0,
        isRestrictedAreaEnabled: true,
        showsTrafficOnRouteLine: true,
        showsAlternatives: true,
        showsIntermediateWaypoints: true,
        showsVoiceInstructionsOnMap: false,
        showsIntersectionAnnotations: true,
        showsIntersectionLaneGuidance: false,
        showsDebugIntersectionMarks: false,
        occlusionFactor: .constant(0.85),
        congestionConfiguration: .default,
        excludedRouteAlertTypes: [],
        waypointColor: .defaultWaypointColor,
        waypointStrokeColor: .defaultWaypointStrokeColor,
        routeCalloutAnchors: [.bottomLeft, .bottomRight, .topLeft, .topRight],
        fixedRouteCalloutPosition: .disabled,
        useLegacyEtaRouteAnnotations: false,
        apiRouteCalloutViewProviderEnabled: false
    )
}
