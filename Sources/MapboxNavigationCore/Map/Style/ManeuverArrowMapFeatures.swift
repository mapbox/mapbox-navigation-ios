import _MapboxNavigationHelpers
import Foundation
import MapboxDirections
@_spi(Experimental) import MapboxMaps

extension Route {
    func maneuverArrowMapFeatures(
        ids: FeatureIds.ManeuverArrow,
        cameraZoom: CGFloat,
        legIndex: Int, stepIndex: Int,
        config: MapStyleConfig,
        customizedLayerProvider: CustomizedLayerProvider
    ) -> [any MapFeature] {
        guard containsStep(at: legIndex, stepIndex: stepIndex)
        else { return [] }

        let triangleImage = Bundle.module.image(named: "triangle")!.withRenderingMode(.alwaysTemplate)

        var mapFeatures: [any MapFeature] = []

        let step = legs[legIndex].steps[stepIndex]
        let maneuverCoordinate = step.maneuverLocation
        guard step.maneuverType != .arrive else { return [] }

        let metersPerPoint = Projection.metersPerPoint(
            for: maneuverCoordinate.latitude,
            zoom: cameraZoom
        )

        // TODO: Implement ability to change `shaftLength` depending on zoom level.
        let shaftLength = max(min(50 * metersPerPoint, 50), 30)
        let shaftPolyline = polylineAroundManeuver(legIndex: legIndex, stepIndex: stepIndex, distance: shaftLength)

        if shaftPolyline.coordinates.count > 1 {
            let minimumZoomLevel = 14.5
            let shaftStrokeCoordinates = shaftPolyline.coordinates
            let shaftDirection = shaftStrokeCoordinates[shaftStrokeCoordinates.count - 2]
                .direction(to: shaftStrokeCoordinates.last!)
            let point = Point(shaftStrokeCoordinates.last!)

            let layers: [any Layer] = [
                with(LineLayer(id: ids.arrow, source: ids.arrowSource)) {
                    $0.minZoom = Double(minimumZoomLevel)
                    $0.lineCap = .constant(.butt)
                    $0.lineJoin = .constant(.round)
                    $0.lineWidth = .expression(Expression.routeLineWidthExpression(0.70))
                    $0.lineColor = .constant(.init(config.maneuverArrowColor))
                    $0.lineEmissiveStrength = .constant(1)
                },
                with(LineLayer(id: ids.arrowStroke, source: ids.arrowSource)) {
                    $0.minZoom = Double(minimumZoomLevel)
                    $0.lineCap = .constant(.butt)
                    $0.lineJoin = .constant(.round)
                    $0.lineWidth = .expression(Expression.routeLineWidthExpression(0.80))
                    $0.lineColor = .constant(.init(config.maneuverArrowStrokeColor))
                    $0.lineEmissiveStrength = .constant(1)
                },
                with(SymbolLayer(id: ids.arrowSymbol, source: ids.arrowSymbolSource)) {
                    $0.minZoom = Double(minimumZoomLevel)
                    $0.iconImage = .constant(.name(ids.triangleTipImage))
                    $0.iconColor = .constant(.init(config.maneuverArrowColor))
                    $0.iconRotationAlignment = .constant(.map)
                    $0.iconRotate = .constant(.init(shaftDirection))
                    $0.iconSize = .expression(Expression.routeLineWidthExpression(0.12))
                    $0.iconAllowOverlap = .constant(true)
                    $0.iconEmissiveStrength = .constant(1)
                },
                with(SymbolLayer(id: ids.arrowSymbolCasing, source: ids.arrowSymbolSource)) {
                    $0.minZoom = Double(minimumZoomLevel)
                    $0.iconImage = .constant(.name(ids.triangleTipImage))
                    $0.iconColor = .constant(.init(config.maneuverArrowStrokeColor))
                    $0.iconRotationAlignment = .constant(.map)
                    $0.iconRotate = .constant(.init(shaftDirection))
                    $0.iconSize = .expression(Expression.routeLineWidthExpression(0.14))
                    $0.iconAllowOverlap = .constant(true)
                },
            ]

            mapFeatures.append(
                GeoJsonMapFeature(
                    id: ids.id,
                    sources: [
                        .init(
                            id: ids.arrowSource,
                            geoJson: .feature(Feature(geometry: .lineString(shaftPolyline)))
                        ),
                        .init(
                            id: ids.arrowSymbolSource,
                            geoJson: .feature(Feature(geometry: .point(point)))
                        ),
                    ],
                    customizeSource: { source, _ in
                        source.tolerance = 0.375
                    },
                    layers: layers.map { customizedLayerProvider.customizedLayer($0) },
                    onBeforeAdd: { mapView in
                        mapView.mapboxMap.provisionImage(id: ids.triangleTipImage) {
                            try $0.addImage(
                                triangleImage,
                                id: ids.triangleTipImage,
                                sdf: true,
                                stretchX: [],
                                stretchY: []
                            )
                        }
                    },
                    onUpdate: { mapView in
                        try with(mapView.mapboxMap) {
                            try $0.setLayerProperty(
                                for: ids.arrowSymbol,
                                property: "icon-rotate",
                                value: shaftDirection
                            )
                            try $0.setLayerProperty(
                                for: ids.arrowSymbolCasing,
                                property: "icon-rotate",
                                value: shaftDirection
                            )
                        }
                    },
                    onAfterRemove: { mapView in
                        if mapView.mapboxMap.imageExists(withId: ids.triangleTipImage) {
                            try? mapView.mapboxMap.removeImage(withId: ids.triangleTipImage)
                        }
                    }
                )
            )
        }
        return mapFeatures
    }
}
