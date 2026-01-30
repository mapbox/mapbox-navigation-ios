/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import CoreLocation
import Foundation
@_spi(Experimental) import MapboxMaps
import UIKit

/// Manages a collection of building annotations on the map.
///
/// **Note:** Due to FillExtrusionLayer limitations, `fillExtrusionOpacity` is applied uniformly
/// to all buildings (default: 0.8). Individual annotation opacity values are ignored.
/// Color, height, and base elevation can be customized per-building.
///
/// ## Example Usage
/// ```swift
/// let manager = BuildingAnnotationManager(mapView: mapView)
/// manager.fillExtrusionOpacity = 0.9  // Optional: adjust opacity for all buildings
///
/// let annotation = BuildingAnnotation(
///     coordinates: points,
///     fillExtrusionHeight: 50.0
/// )
/// manager.annotations = [annotation]
/// ```
@MainActor
public final class BuildingAnnotationManager {
    private let mapView: MapView
    private let sourceId = "building-annotation-source"
    private let layerId = "building-annotation-layer"
    private var isInitialized = false

    /// Setting this property updates the map with the new annotations.
    /// Uses a single source and layer with data-driven styling for efficient batch updates.
    public var annotations: [BuildingAnnotation] = [] {
        didSet {
            updateAnnotations()
        }
    }

    // MARK: - Layer-Level Properties

    /// The opacity at which all building extrusions will be drawn.
    ///
    /// This is a layer-level property that applies to all annotations uniformly.
    /// Individual annotation `fillExtrusionOpacity` values are ignored.
    /// Value range: [0, 1], where 0 is fully transparent and 1 is fully opaque.
    /// Default value: 0.8
    public var fillExtrusionOpacity: Double = 0.8 {
        didSet {
            updateLayerOpacity()
        }
    }

    /// Creates a new building annotation manager.
    ///
    /// - Parameter mapView: The map view to add annotations to
    public init(mapView: MapView) {
        self.mapView = mapView
        setupLayer()
    }

    private func setupLayer() {
        guard !isInitialized else { return }

        // Create source with empty FeatureCollection
        var source = GeoJSONSource(id: sourceId)
        source.data = .featureCollection(FeatureCollection(features: []))

        // Create layer with data-driven styling using expressions
        // Note: fillExtrusionOpacity must be constant (doesn't support data-driven expressions)
        var layer = FillExtrusionLayer(id: layerId, source: sourceId)
        layer.fillExtrusionColor = .expression(Exp(.get) { "color" })
        layer.fillExtrusionHeight = .expression(Exp(.get) { "height" })
        layer.fillExtrusionBase = .expression(Exp(.get) { "base" })
        layer.fillExtrusionOpacity = .constant(fillExtrusionOpacity)

        try? mapView.mapboxMap.addSource(source)
        try? mapView.mapboxMap.addLayer(layer)

        isInitialized = true
    }

    private func updateAnnotations() {
        guard isInitialized else { return }

        // Convert annotations to GeoJSON features with properties
        // Note: opacity is set as constant on the layer, not per-feature
        let features: [Feature] = annotations.map { annotation in
            var feature = Feature(geometry: .polygon(Polygon([annotation.coordinates])))
            feature.properties = [
                "color": .string(StyleColor(annotation.fillExtrusionColor).rawValue),
                "height": .number(annotation.fillExtrusionHeight),
                "base": .number(annotation.fillExtrusionBase)
            ]
            return feature
        }

        // Update source with new FeatureCollection
        let featureCollection = FeatureCollection(features: features)
        mapView.mapboxMap.updateGeoJSONSource(
            withId: sourceId,
            geoJSON: .featureCollection(featureCollection)
        )
    }

    private func updateLayerOpacity() {
        guard isInitialized else { return }

        try? mapView.mapboxMap.setLayerProperty(
            for: layerId,
            property: "fill-extrusion-opacity",
            value: fillExtrusionOpacity
        )
    }
}

extension BuildingAnnotation: Equatable {
    public static func == (lhs: BuildingAnnotation, rhs: BuildingAnnotation) -> Bool {
        lhs.id == rhs.id &&
        lhs.coordinates.count == rhs.coordinates.count &&
        lhs.fillExtrusionColor == rhs.fillExtrusionColor &&
        lhs.fillExtrusionOpacity == rhs.fillExtrusionOpacity &&
        lhs.fillExtrusionHeight == rhs.fillExtrusionHeight &&
        lhs.fillExtrusionBase == rhs.fillExtrusionBase
    }
}
