import MapboxMaps
@testable import MapboxNavigationCore
import UIKit

extension MapStyleConfig {
    public static func mock(
        routeLineTracksTraversal: Bool = true,
        isRestrictedAreaEnabled: Bool = true,
        showsTrafficOnRouteLine: Bool = true,
        showsAlternatives: Bool = true,
        showsIntermediateWaypoints: Bool = true,
        traversedRouteColor: UIColor = .clear,
        showsVoiceInstructionsOnMap: Bool = false,
        showsIntersectionAnnotations: Bool = true,
        congestionConfiguration: CongestionConfiguration = .default,
        excludedRouteAlertTypes: RoadAlertType = [],
        waypointColor: UIColor = .white,
        waypointStrokeColor: UIColor = .darkGray,
        routeCalloutAnchors: [ViewAnnotationAnchor] = [.bottomLeft],
        fixedRouteCalloutPosition: NavigationMapView.FixedRouteCalloutPosition = .fixed(1.0 / 3.0),
        useLegacyEtaRouteAnnotations: Bool = false,
        apiRouteCalloutViewProviderEnabled: Bool = false
    ) -> Self {
        MapStyleConfig(
            routeCasingColor: .blue,
            routeAlternateCasingColor: .cyan,
            routeRestrictedAreaColor: .yellow,
            traversedRouteColor: traversedRouteColor,
            maneuverArrowColor: .gray,
            maneuverArrowStrokeColor: .red,
            routeAnnotationSelectedColor: .lightGray,
            routeAnnotationColor: .white,
            routeAnnotationSelectedTextColor: .lightText,
            routeAnnotationTextColor: .darkText,
            routeAnnotationSelectedCaptionTextColor: .lightText,
            routeAnnotationCaptionTextColor: .darkText,
            routeAnnotationMoreTimeTextColor: .systemRed,
            routeAnnotationLessTimeTextColor: .systemGreen,
            routeAnnotationTextFont: .systemFont(ofSize: 18, weight: .semibold),
            routeAnnnotationCaptionTextFont: .systemFont(ofSize: 16, weight: .regular),
            routeLineTracksTraversal: routeLineTracksTraversal,
            isRestrictedAreaEnabled: isRestrictedAreaEnabled,
            showsTrafficOnRouteLine: showsTrafficOnRouteLine,
            showsAlternatives: showsAlternatives,
            showsIntermediateWaypoints: showsIntermediateWaypoints,
            showsVoiceInstructionsOnMap: showsVoiceInstructionsOnMap,
            showsIntersectionAnnotations: showsIntersectionAnnotations,
            congestionConfiguration: congestionConfiguration,
            excludedRouteAlertTypes: excludedRouteAlertTypes,
            waypointColor: waypointColor,
            waypointStrokeColor: waypointStrokeColor,
            routeCalloutAnchors: routeCalloutAnchors,
            fixedRouteCalloutPosition: fixedRouteCalloutPosition,
            useLegacyEtaRouteAnnotations: useLegacyEtaRouteAnnotations,
            apiRouteCalloutViewProviderEnabled: apiRouteCalloutViewProviderEnabled
        )
    }
}
