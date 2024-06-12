import _MapboxNavigationHelpers
import MapboxDirections
import MapboxMaps
import Turf
import UIKit

struct IntermediateWaypointFeatureProvider {
    var customShape: ([Waypoint], Int) -> FeatureCollection?
    var customCirleLayer: (String, String) -> CircleLayer?
    var customSymbolLayer: (String, String) -> SymbolLayer?
}

@MainActor
extension Route {
    /// Generates a list of map features visualizing intermediate waypoints on a route line.
    /// - Note: The final destination pin is added with ``NavigationMapView/pointAnnotationManager`` instead.
    func intermediateWaypointsMapFeatures(
        mapView: MapView,
        legIndex: Int,
        config: MapStyleConfig,
        featureProvider: IntermediateWaypointFeatureProvider,
        customizedLayerProvider: CustomizedLayerProvider
    ) -> [MapFeature] {
        let intermediateWaypoints: [Waypoint] = Array(legs.dropLast().compactMap(\.destination))
        guard intermediateWaypoints.count >= 1 else { return [] }

        registerIntermediateWaypointImage(in: mapView)
        let customShape = featureProvider.customShape(intermediateWaypoints, legIndex)
        let shape = customShape ?? intermediateWaypointsShape(
            mapView: mapView,
            legIndex: legIndex,
            config: config,
            intermediateWaypoints: intermediateWaypoints
        )
        return [mapFeaturesForIntermediateWaypoints(
            with: shape,
            config: config,
            featureProvider: featureProvider,
            customizedLayerProvider: customizedLayerProvider
        )]
    }

    private func intermediateWaypointsShape(
        mapView: MapView,
        legIndex: Int,
        config: MapStyleConfig,
        intermediateWaypoints: [Waypoint]
    ) -> FeatureCollection {
        let features = intermediateWaypoints.enumerated().map { waypointIndex, waypoint in
            var feature = Feature(geometry: .point(Point(waypoint.coordinate)))
            feature.properties = [
                "waypointCompleted": .boolean(waypointIndex < legIndex),
            ]
            return feature
        }
        return FeatureCollection(features: features)
    }

    private func registerIntermediateWaypointImage(in mapView: MapView) {
        let intermediateWaypointImageId = NavigationMapView.ImageIdentifier.midpointMarkerImage
        mapView.mapboxMap.provisionImage(id: intermediateWaypointImageId) {
            try $0.addImage(
                UIImage.midpointMarkerImage,
                id: intermediateWaypointImageId,
                stretchX: [],
                stretchY: []
            )
        }
    }

    private func mapFeaturesForIntermediateWaypoints(
        with shape: FeatureCollection,
        config: MapStyleConfig,
        featureProvider: IntermediateWaypointFeatureProvider,
        customizedLayerProvider: CustomizedLayerProvider
    ) -> MapFeature {
        let customCircleLayer = featureProvider.customCirleLayer(
            FeatureIds.RouteWaypoints.default.innerCircle,
            FeatureIds.RouteWaypoints.default.source
        )
        var layers: [any Layer] = if let customCircleLayer {
            [customCircleLayer]
        } else {
            [defaultBaseCircleLayer(with: config), defaultCircleLayer(with: config)]
                .map { customizedLayerProvider.customizedLayer($0) }
        }
        let symbolLayer = featureProvider.customSymbolLayer(
            FeatureIds.RouteWaypoints.default.markerIcon,
            FeatureIds.RouteWaypoints.default.source
        ) ?? customizedLayerProvider.customizedLayer(defaultSymbolLayer(with: config))
        layers.append(symbolLayer)
        return GeoJsonMapFeature(
            id: FeatureIds.RouteWaypoints.default.featureId,
            sources: [
                .init(
                    id: FeatureIds.RouteWaypoints.default.source,
                    geoJson: .featureCollection(shape)
                ),
            ],
            customizeSource: { _, _ in },
            layers: layers,
            onBeforeAdd: { _ in },
            onAfterRemove: { _ in }
        )
    }

    private func defaultBaseCircleLayer(with config: MapStyleConfig) -> CircleLayer {
        let routeLineColor = config.congestionConfiguration.colors.mainRouteColors.unknown
        return with(
            CircleLayer(
                id: FeatureIds.RouteWaypoints.default.baseCircle,
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
            $0.circleColor = .constant(.init(routeLineColor))
            $0.circleOpacity = .expression(opacity)
            $0.circleEmissiveStrength = .constant(1)
            $0.circleRadius = .expression(.routeLineWidthExpression(1.25))
            $0.circleStrokeColor = .constant(.init(config.routeCasingColor))
            $0.circleStrokeWidth = .expression(.routeLineWidthExpression(0.25))
            $0.circleStrokeOpacity = .expression(opacity)
            $0.circlePitchAlignment = .constant(.map)
        }
    }

    private func defaultCircleLayer(with config: MapStyleConfig) -> CircleLayer {
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
            $0.circleColor = .constant(.init(config.routeCasingColor))
            $0.circleOpacity = .expression(opacity)
            $0.circleEmissiveStrength = .constant(1)
            $0.circleRadius = .expression(.routeLineWidthExpression(0.8))
            $0.circlePitchAlignment = .constant(.map)
        }
    }

    private func defaultSymbolLayer(with config: MapStyleConfig) -> SymbolLayer {
        with(
            SymbolLayer(
                id: FeatureIds.RouteWaypoints.default.markerIcon,
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
            $0.iconOpacity = .expression(opacity)
            $0.iconImage = .constant(.name(NavigationMapView.ImageIdentifier.midpointMarkerImage))
            $0.iconAnchor = .constant(.bottom)
            $0.iconAllowOverlap = .constant(true)
        }
    }
}
