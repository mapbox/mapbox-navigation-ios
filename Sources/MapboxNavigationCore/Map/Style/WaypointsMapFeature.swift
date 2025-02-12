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

struct WaypointsLineStyleContent: MapStyleContent {
    let featureIds: FeatureIds.RouteWaypoints

    let source: GeoJSONSource

    let circleLayer: CircleLayer?
    let symbolLayer: SymbolLayer?

    var body: some MapStyleContent {
        source
        if let circleLayer {
            circleLayer
        }
        if let symbolLayer {
            symbolLayer
        }
    }
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
        customizedCircleLayerProvider: CustomizedTypeLayerProvider<CircleLayer>,
        customizedSymbolLayerProvider: CustomizedTypeLayerProvider<SymbolLayer>
    ) -> (WaypointsLineStyleContent, MapFeature)? {
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
            customizedCircleLayerProvider: customizedCircleLayerProvider,
            customizedSymbolLayerProvider: customizedSymbolLayerProvider
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
        customizedCircleLayerProvider: CustomizedTypeLayerProvider<CircleLayer>,
        customizedSymbolLayerProvider: CustomizedTypeLayerProvider<SymbolLayer>
    ) -> (WaypointsLineStyleContent, MapFeature)? {
        let circleLayer = featureProvider.customCirleLayer(
            FeatureIds.RouteWaypoints.default.innerCircle,
            FeatureIds.RouteWaypoints.default.source
        ) ?? customizedCircleLayerProvider.customizedLayer(defaultCircleLayer(config: config))

        let defaultSymbolLayer = featureProvider.customSymbolLayer(
            FeatureIds.RouteWaypoints.default.markerIcon,
            FeatureIds.RouteWaypoints.default.source
        )
        let symbolLayer: SymbolLayer? = if let defaultSymbolLayer {
            customizedSymbolLayerProvider.customizedLayer(defaultSymbolLayer)
        } else { nil }
        let source = GeoJsonMapFeature.Source(
            id: FeatureIds.RouteWaypoints.default.source,
            geoJson: .featureCollection(features)
        )
        guard let waypointSource = source.data() else { return nil }

        let content = WaypointsLineStyleContent(
            featureIds: FeatureIds.RouteWaypoints.default,
            source: waypointSource,
            circleLayer: circleLayer,
            symbolLayer: symbolLayer
        )
        let layers: [(any Layer)?] = [circleLayer, symbolLayer]

        let mapFeature = GeoJsonMapFeature(
            id: FeatureIds.RouteWaypoints.default.featureId,
            sources: [source],
            customizeSource: { _, _ in },
            layers: layers.compactMap { $0 },
            onBeforeAdd: { _ in },
            onAfterRemove: { _ in }
        )
        return (content, mapFeature)
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
