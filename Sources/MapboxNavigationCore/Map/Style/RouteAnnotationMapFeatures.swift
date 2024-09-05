import _MapboxNavigationHelpers
import CoreLocation
import MapboxDirections
import MapboxMaps
import Turf
import UIKit

/// Describes the possible annotation types on the route line.
public enum RouteAnnotationKind {
    /// Shows the route duration.
    case routeDurations
    /// Shows the relative diff between the main route and the alternative.
    /// The annotation is displayed in the approximate middle of the alternative steps.
    case relativeDurationsOnAlternative
    /// Shows the relative diff between the main route and the alternative.
    /// The annotation is displayed next to the first different maneuver of the alternative road.
    case relativeDurationsOnAlternativeManuever
}

extension NavigationRoutes {
    func routeDurationMapFeatures(
        annotationKinds: Set<RouteAnnotationKind>,
        config: MapStyleConfig
    ) -> [any MapFeature] {
        var showMainRoute = false
        var showAlternatives = false
        var showAsRelative = false
        var annotateManeuver = false
        for annotationKind in annotationKinds {
            switch annotationKind {
            case .routeDurations:
                showMainRoute = true
                showAlternatives = config.showsAlternatives
            case .relativeDurationsOnAlternative:
                showAsRelative = true
                showAlternatives = config.showsAlternatives
            case .relativeDurationsOnAlternativeManuever:
                showAsRelative = true
                annotateManeuver = true
                showAlternatives = config.showsAlternatives
            }
        }

        return [
            ETAViewsAnnotationFeature(
                for: self,
                showMainRoute: showMainRoute,
                showAlternatives: showAlternatives,
                isRelative: showAsRelative,
                annotateAtManeuver: annotateManeuver,
                mapStyleConfig: config
            ),
        ]
    }
}
