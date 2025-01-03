import _MapboxNavigationHelpers
import MapboxDirections
import MapboxMaps
import Turf
import UIKit

struct WaypointFeatureProvider {
    var customFeatures: ([Waypoint], Int) -> FeatureCollection?
    var customCirleLayer: (String, String) -> CircleLayer?
    var customSymbolLayer: (String, String) -> SymbolLayer?
}

@MainActor
extension Route {
    /// Generates a map feature that visually represents waypoints along a route line.
    /// The waypoints include the start, destination, and any intermediate waypoints.
    /// - Important: Only intermediate waypoints are marked with pins. The starting point and destination are excluded
    /// from this.
    func waypointsMapFeature(
        mapView: MapView,
        legIndex: Int,
        config: MapStyleConfig,
        featureProvider: WaypointFeatureProvider,
        customizedLayerProvider: CustomizedLayerProvider
    ) -> MapFeature? {
        guard let startWaypoint = legs.first?.source else { return nil }
        guard let destinationWaypoint = legs.last?.destination else { return nil }

        let intermediateWaypoints = config.showsIntermediateWaypoints
            ? legs.dropLast().compactMap(\.destination)
            : []
        let waypoints = [startWaypoint] + intermediateWaypoints + [destinationWaypoint]
        let customFeatures = featureProvider.customFeatures(waypoints, legIndex)

        return waypointsMapFeature(
            with: customFeatures ?? waypointsFeatures(legIndex: legIndex, waypoints: waypoints),
            config: config,
            featureProvider: featureProvider,
            customizedLayerProvider: customizedLayerProvider
        )
    }

    private func waypointsFeatures(legIndex: Int, waypoints: [Waypoint]) -> FeatureCollection {
        FeatureCollection(
            features: waypoints.enumerated().map { waypointIndex, waypoint in
                var feature = Feature(geometry: .point(Point(waypoint.coordinate)))
                var properties: [String: JSONValue] = [:]
                properties["waypointCompleted"] = .boolean(waypointIndex <= legIndex)
                feature.properties = properties

                return feature
            }
        )
    }

    private func waypointsMapFeature(
        with features: FeatureCollection,
        config: MapStyleConfig,
        featureProvider: WaypointFeatureProvider,
        customizedLayerProvider: CustomizedLayerProvider
    ) -> MapFeature {
        let circleLayer = featureProvider.customCirleLayer(
            FeatureIds.RouteWaypoints.default.innerCircle,
            FeatureIds.RouteWaypoints.default.source
        ) ?? customizedLayerProvider.customizedLayer(defaultCircleLayer(config: config))

        let symbolLayer: (any Layer)? = featureProvider.customSymbolLayer(
            FeatureIds.RouteWaypoints.default.markerIcon,
            FeatureIds.RouteWaypoints.default.source
        )

        return GeoJsonMapFeature(
            id: FeatureIds.RouteWaypoints.default.featureId,
            sources: [
                .init(
                    id: FeatureIds.RouteWaypoints.default.source,
                    geoJson: .featureCollection(features)
                ),
            ],
            customizeSource: { _, _ in },
            layers: [circleLayer, symbolLayer].compactMap { $0 },
            onBeforeAdd: { _ in },
            onAfterRemove: { _ in }
        )
    }

    private func defaultCircleLayer(config: MapStyleConfig) -> CircleLayer {
        with(
            CircleLayer(
                id: FeatureIds.RouteWaypoints.default.innerCircle,
                source: FeatureIds.RouteWaypoints.default.source
            )
        ) {
            let opacity = Exp(.switchCase) {
                Exp(.any) {
                    Exp(.get) {
                        "waypointCompleted"
                    }
                }
                0
                1
            }

            $0.circleColor = .constant(.init(config.waypointColor))
            $0.circleOpacity = .expression(opacity)
            $0.circleEmissiveStrength = .constant(1)
            $0.circleRadius = .expression(.routeCasingLineWidthExpression(0.5))
            $0.circleStrokeColor = .constant(.init(config.waypointStrokeColor))
            $0.circleStrokeWidth = .expression(.routeCasingLineWidthExpression(0.14))
            $0.circleStrokeOpacity = .expression(opacity)
            $0.circlePitchAlignment = .constant(.map)
        }
    }
}
