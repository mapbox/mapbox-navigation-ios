import _MapboxNavigationHelpers
import Foundation
import MapboxDirections
@_spi(Experimental) import MapboxMaps
import UIKit

struct ManeuverArrowStyleContent: MapStyleContent {
    let arrowSource: GeoJSONSource
    let arrowSymbolSource: GeoJSONSource

    let arrowLineLayer: LineLayer
    let arrowStrokeLineLayer: LineLayer
    let arrowSymbolLayer: SymbolLayer
    let arrowSymbolCasingLayer: SymbolLayer

    var body: some MapStyleContent {
        arrowSource
        arrowSymbolSource

        arrowStrokeLineLayer
            .slot(.middle)
        arrowLineLayer
            .slot(.middle)
        arrowSymbolCasingLayer
            .slot(.middle)
        arrowSymbolLayer
            .slot(.middle)
    }
}

extension Route {
    func maneuverArrowMapFeatures(
        ids: FeatureIds.ManeuverArrow,
        cameraZoom: CGFloat,
        mapboxMap: MapboxMap,
        legIndex: Int, stepIndex: Int,
        config: MapStyleConfig,
        customizedLineLayerProvider: CustomizedTypeLayerProvider<LineLayer>,
        customizedSymbolLayerProvider: CustomizedTypeLayerProvider<SymbolLayer>
    ) -> (ManeuverArrowStyleContent, MapFeature)? {
        guard containsStep(at: legIndex, stepIndex: stepIndex) else { return nil }

        let triangleImage = Bundle.mapboxNavigationUXCore.image(named: "triangle")!
            .withRenderingMode(.alwaysTemplate)

        let step = legs[legIndex].steps[stepIndex]
        let maneuverCoordinate = step.maneuverLocation
        guard step.maneuverType != .arrive else { return nil }

        let metersPerPoint = Projection.metersPerPoint(
            for: maneuverCoordinate.latitude,
            zoom: cameraZoom
        )

        // TODO: Implement ability to change `shaftLength` depending on zoom level.
        let shaftLength = max(min(50 * metersPerPoint, 50), 30)
        let shaftPolyline = polylineAroundManeuver(legIndex: legIndex, stepIndex: stepIndex, distance: shaftLength)

        guard shaftPolyline.coordinates.count > 1 else { return nil }

        let minimumZoomLevel = 14.5
        let shaftStrokeCoordinates = shaftPolyline.coordinates
        let shaftDirection = shaftStrokeCoordinates[shaftStrokeCoordinates.count - 2]
            .direction(to: shaftStrokeCoordinates.last!)
        let point = Point(shaftStrokeCoordinates.last!)

        let lineLayers = [
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
        ].map { customizedLineLayerProvider.customizedLayer($0) }

        let symbolLayers = [
            with(SymbolLayer(id: ids.arrowSymbol, source: ids.arrowSymbolSource)) {
                $0.minZoom = Double(minimumZoomLevel)
                $0.iconImage = .constant(.name(ids.triangleTipImage))
                $0.iconColor = .constant(.init(config.maneuverArrowColor))
                $0.iconRotationAlignment = .constant(.map)
                $0.iconRotate = .constant(.init(shaftDirection))
                $0.iconSize = .expression(Expression.routeLineWidthExpression(0.12))
                $0.iconAllowOverlap = .constant(true)
                $0.iconEmissiveStrength = .constant(1)
                $0.iconRotate = .constant(.init(shaftDirection))
            },
            with(SymbolLayer(id: ids.arrowSymbolCasing, source: ids.arrowSymbolSource)) {
                $0.minZoom = Double(minimumZoomLevel)
                $0.iconImage = .constant(.name(ids.triangleTipImage))
                $0.iconColor = .constant(.init(config.maneuverArrowStrokeColor))
                $0.iconRotationAlignment = .constant(.map)
                $0.iconRotate = .constant(.init(shaftDirection))
                $0.iconSize = .expression(Expression.routeLineWidthExpression(0.14))
                $0.iconAllowOverlap = .constant(true)
                $0.iconRotate = .constant(.init(shaftDirection))
            },
        ].map { customizedSymbolLayerProvider.customizedLayer($0) }

        let arrowSource = GeoJsonMapFeature.Source(
            id: ids.arrowSource,
            geoJson: .feature(Feature(geometry: .lineString(shaftPolyline)))
        )
        let arrowSymbolSource = GeoJsonMapFeature.Source(
            id: ids.arrowSymbolSource,
            geoJson: .feature(Feature(geometry: .point(point)))
        )

        guard let arrowSourceData = arrowSource.data(tolerance: GeoJsonMapFeature.Source.defaultTolerance),
              let arrowSymbolSourceData = arrowSymbolSource.data(tolerance: GeoJsonMapFeature.Source.defaultTolerance)
        else {
            return nil
        }

        add(triangleImage: triangleImage, to: mapboxMap, ids: ids)

        let styleContent = ManeuverArrowStyleContent(
            arrowSource: arrowSourceData,
            arrowSymbolSource: arrowSymbolSourceData,
            arrowLineLayer: lineLayers[0],
            arrowStrokeLineLayer: lineLayers[1],
            arrowSymbolLayer: symbolLayers[0],
            arrowSymbolCasingLayer: symbolLayers[1]
        )

        let layers: [any Layer] = lineLayers + symbolLayers
        let mapFeature = GeoJsonMapFeature(
            id: ids.id,
            sources: [arrowSource, arrowSymbolSource],
            customizeSource: { source, _ in
                source.tolerance = GeoJsonMapFeature.Source.defaultTolerance
            },
            layers: layers,
            onBeforeAdd: { mapView in
                add(triangleImage: triangleImage, to: mapView.mapboxMap, ids: ids)
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
        return (styleContent, mapFeature)
    }

    private func add(
        triangleImage: UIImage,
        to mapboxMap: MapboxMap,
        ids: FeatureIds.ManeuverArrow
    ) {
        mapboxMap.provisionImage(id: ids.triangleTipImage) {
            try $0.addImage(
                triangleImage,
                id: ids.triangleTipImage,
                sdf: true,
                stretchX: [],
                stretchY: []
            )
        }
    }
}
