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
/// The manager provides default values for all fill extrusion properties. Individual annotations
/// can override these defaults by specifying their own values.
///
/// **Note:** Due to FillExtrusionLayer limitations, `fillExtrusionOpacity` is applied uniformly
/// to all buildings. Individual annotation opacity values are ignored.
///
/// ## Example Usage
/// ```swift
/// let manager = BuildingAnnotationManager(mapView: mapView)
/// // Set defaults for all annotations
/// manager.fillExtrusionColor = .green
/// manager.fillExtrusionOpacity = 0.9
/// manager.fillExtrusionHeight = 50.0
///
/// manager.annotations = [
///     BuildingAnnotation(coordinates: building1Points),  // Uses manager defaults
///     BuildingAnnotation(coordinates: building2Points, fillExtrusionHeight: 75.0)  // Overrides height
/// ]
/// ```
@MainActor
public final class BuildingAnnotationManager {
    private static var idGenerator: Int = 0

    private let mapView: MapView
    private let sourceId: String
    private let layerId: String
    private var isInitialized = false

    /// Setting this property updates the map with the new annotations.
    /// Uses a single source and layer with data-driven styling for efficient batch updates.
    public var annotations: [BuildingAnnotation] = [] {
        didSet {
            updateAnnotations()
        }
    }

    /// The default fillExtrusionColor for all annotations if not overwritten by individual annotation settings.
    /// Default value: blue (hsl(214, 94%, 59%) = #3489F9)
    public var fillExtrusionColor: UIColor = UIColor(red: 0.204, green: 0.537, blue: 0.976, alpha: 1.0) {
        didSet {
            updateAnnotations()
        }
    }

    /// The default fillExtrusionOpacity for all annotations.
    /// This is a layer-level property that applies uniformly to all annotations.
    /// Individual annotation `fillExtrusionOpacity` values are ignored.
    /// Value range: [0, 1], where 0 is fully transparent and 1 is fully opaque.
    /// Default value: 0.8
    public var fillExtrusionOpacity: Double = 0.8 {
        didSet {
            updateLayerOpacity()
        }
    }

    /// The default fillExtrusionHeight for all annotations if not overwritten by individual annotation settings.
    /// Default value: 50.0 meters
    public var fillExtrusionHeight: Double = 50.0 {
        didSet {
            updateAnnotations()
        }
    }

    /// The default fillExtrusionBase for all annotations if not overwritten by individual annotation settings.
    /// Default value: 0.0 meters
    public var fillExtrusionBase: Double = 0.0 {
        didSet {
            updateAnnotations()
        }
    }

    /// Creates a new building annotation manager.
    ///
    /// - Parameter mapView: The map view to add annotations to
    public init(mapView: MapView) {
        self.mapView = mapView

        // Generate unique IDs for this manager instance
        Self.idGenerator += 1
        let id = Self.idGenerator
        self.sourceId = "building-annotation-source-\(id)"
        self.layerId = "building-annotation-layer-\(id)"

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
        // Use manager defaults for properties not specified by individual annotations
        let features: [Feature] = annotations.map { createFeature(from: $0) }

        // Update source with new FeatureCollection
        let featureCollection = FeatureCollection(features: features)
        mapView.mapboxMap.updateGeoJSONSource(
            withId: sourceId,
            geoJSON: .featureCollection(featureCollection)
        )
    }

    private func createFeature(from annotation: BuildingAnnotation) -> Feature {
        var feature = Feature(geometry: .polygon(Polygon([annotation.coordinates])))
        feature.properties = [
            "color": .string(StyleColor(annotation.fillExtrusionColor ?? fillExtrusionColor).rawValue),
            "height": .number(annotation.fillExtrusionHeight ?? fillExtrusionHeight),
            "base": .number(annotation.fillExtrusionBase ?? fillExtrusionBase)
        ]
        return feature
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
        lhs.id == rhs.id
    }
}
