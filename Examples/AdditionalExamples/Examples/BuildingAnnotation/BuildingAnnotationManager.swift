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
/// ## Example Usage
/// ```swift
/// let manager = BuildingAnnotationManager(mapView: mapView)
/// var annotation = BuildingAnnotation(
///     id: "building-1",
///     coordinates: points
/// )
/// annotation.fillExtrusionColor = .red
/// manager.annotations = [annotation]
/// ```
@MainActor
public final class BuildingAnnotationManager {
    private let mapView: MapView

    /// Setting this property updates the map by removing old annotations and adding new ones.
    public var annotations: [BuildingAnnotation] = [] {
        didSet {
            syncAnnotations(oldAnnotations: oldValue, newAnnotations: annotations)
        }
    }

    /// Creates a new building annotation manager.
    ///
    /// - Parameter mapView: The map view to add annotations to
    public init(mapView: MapView) {
        self.mapView = mapView
    }

    private func syncAnnotations(oldAnnotations: [BuildingAnnotation], newAnnotations: [BuildingAnnotation]) {
        // Create lookup sets for efficient comparison
        let oldIds = Set(oldAnnotations.map { $0.id })
        let newIds = Set(newAnnotations.map { $0.id })

        // Remove annotations that are no longer in the array
        let idsToRemove = oldIds.subtracting(newIds)
        for annotation in oldAnnotations where idsToRemove.contains(annotation.id) {
            removeAnnotation(annotation)
        }

        // Add or update annotations
        for annotation in newAnnotations {
            if oldIds.contains(annotation.id) {
                let oldAnnotation = oldAnnotations.first { $0.id == annotation.id }
                if oldAnnotation != annotation {
                    removeAnnotation(annotation)
                    addAnnotation(annotation)
                }
            } else {
                // Add new annotation
                addAnnotation(annotation)
            }
        }
    }

    private func addAnnotation(_ annotation: BuildingAnnotation) {
        let polygon = Polygon([annotation.coordinates])

        var source = GeoJSONSource(id: annotation.sourceId)
        source.data = .geometry(.polygon(polygon))

        var layer = FillExtrusionLayer(id: annotation.layerId, source: annotation.sourceId)
        layer.fillExtrusionColor = .constant(StyleColor(annotation.fillExtrusionColor))
        layer.fillExtrusionOpacity = .constant(annotation.fillExtrusionOpacity)
        layer.fillExtrusionHeight = .constant(annotation.fillExtrusionHeight)
        layer.fillExtrusionBase = .constant(annotation.fillExtrusionBase)

        try? mapView.mapboxMap.addSource(source)
        try? mapView.mapboxMap.addLayer(layer)
    }

    private func removeAnnotation(_ annotation: BuildingAnnotation) {
        try? mapView.mapboxMap.removeLayer(withId: annotation.layerId)
        try? mapView.mapboxMap.removeSource(withId: annotation.sourceId)
    }
}

// MARK: - Equatable conformance for BuildingAnnotation

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
