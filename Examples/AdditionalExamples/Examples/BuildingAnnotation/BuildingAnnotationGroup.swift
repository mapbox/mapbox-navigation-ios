/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

#if canImport(SwiftUI)
import CoreLocation
import Foundation
@_spi(Experimental) import MapboxMaps
import SwiftUI
import Turf

/// Displays a group of building annotations.
///
/// When displaying multiple annotations, `BuildingAnnotationGroup` is more performant than
/// individual annotations since only one underlying source and layer is used.
///
/// **Note:** Due to FillExtrusionLayer limitations, `fillExtrusionOpacity` is applied uniformly
/// to all buildings in the group. Individual annotation opacity values are ignored.
///
/// ## Example Usage
/// ```swift
/// Map {
///     BuildingAnnotationGroup(buildings, id: \.id) { building in
///         BuildingAnnotation(coordinates: building.coordinates)
///             .fillExtrusionHeight(building.height)
///             .fillExtrusionColor(building.color)
///     }
///     .fillExtrusionOpacity(0.9)  // Optional: group-level opacity
/// }
/// ```
@available(iOS 14.0, *)
public struct BuildingAnnotationGroup<Data: RandomAccessCollection, ID: Hashable> {
    let annotations: [(ID, BuildingAnnotation)]

    // Group-level property overrides
    private var fillExtrusionColor: UIColor?
    private var fillExtrusionOpacity: Double?
    private var fillExtrusionHeight: Double?
    private var fillExtrusionBase: Double?
    private var layerId: String?

    /// Creates a group of building annotations from a data collection.
    ///
    /// - Parameters:
    ///   - data: Collection of data to create annotations from
    ///   - id: Key path to the identifier for each element
    ///   - content: Closure that creates a `BuildingAnnotation` from each element
    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        content: @escaping (Data.Element) -> BuildingAnnotation
    ) {
        self.annotations = data.map { element in
            (element[keyPath: id], content(element))
        }
    }

    /// Creates a group of building annotations from identifiable data.
    ///
    /// - Parameters:
    ///   - data: Collection of identifiable data
    ///   - content: Closure that creates a `BuildingAnnotation` from each element
    public init(
        _ data: Data,
        content: @escaping (Data.Element) -> BuildingAnnotation
    ) where Data.Element: Identifiable, Data.Element.ID == ID {
        self.init(data, id: \.id, content: content)
    }

    /// Creates a group with a static list of building annotations.
    ///
    /// - Parameter content: Array builder providing the annotations
    public init(
        @ArrayBuilder<BuildingAnnotation> content: () -> [BuildingAnnotation]
    ) where ID == Int {
        self.annotations = Array(content().enumerated())
    }

    /// Sets the fill extrusion color for all annotations in the group.
    public func fillExtrusionColor(_ color: UIColor) -> Self {
        var copy = self
        copy.fillExtrusionColor = color
        return copy
    }

    /// Sets the fill extrusion opacity for all annotations in the group.
    ///
    /// This is a layer-level property due to FillExtrusionLayer limitations.
    public func fillExtrusionOpacity(_ opacity: Double) -> Self {
        var copy = self
        copy.fillExtrusionOpacity = opacity
        return copy
    }

    /// Sets the fill extrusion height for all annotations in the group.
    public func fillExtrusionHeight(_ height: Double) -> Self {
        var copy = self
        copy.fillExtrusionHeight = height
        return copy
    }

    /// Sets the fill extrusion base for all annotations in the group.
    public func fillExtrusionBase(_ base: Double) -> Self {
        var copy = self
        copy.fillExtrusionBase = base
        return copy
    }

    /// Sets the layer ID for the annotation group.
    public func layerId(_ id: String) -> Self {
        var copy = self
        copy.layerId = id
        return copy
    }

    private func buildFeatureCollection() -> FeatureCollection {
        let features: [Feature] = annotations.map { (_, annotation) in
            var annotation = annotation

            // Apply group-level property overrides
            if let color = fillExtrusionColor {
                annotation = annotation.fillExtrusionColor(color)
            }
            if let height = fillExtrusionHeight {
                annotation = annotation.fillExtrusionHeight(height)
            }
            if let base = fillExtrusionBase {
                annotation = annotation.fillExtrusionBase(base)
            }

            // Create feature with polygon geometry
            var feature = Feature(geometry: .polygon(Polygon([annotation.coordinates])))
            feature.properties = [
                "color": .string(StyleColor(annotation.fillExtrusionColor).rawValue),
                "height": .number(annotation.fillExtrusionHeight),
                "base": .number(annotation.fillExtrusionBase)
            ]
            return feature
        }

        return FeatureCollection(features: features)
    }
}

@available(iOS 14.0, *)
extension BuildingAnnotationGroup: MapStyleContent {
    public var body: some MapStyleContent {
        let sourceId = layerId ?? "building-annotation-group-source"
        let layerId = self.layerId ?? "building-annotation-group-layer"
        let featureCollection = buildFeatureCollection()

        // Create source with feature collection
        GeoJSONSource(id: sourceId)
            .data(.featureCollection(featureCollection))

        // Create fill extrusion layer with data-driven styling
        FillExtrusionLayer(id: layerId, source: sourceId)
            .fillExtrusionColor(Exp(.get) { "color" })
            .fillExtrusionHeight(Exp(.get) { "height" })
            .fillExtrusionBase(Exp(.get) { "base" })
            .fillExtrusionOpacity(fillExtrusionOpacity ?? 0.8)
    }
}

#endif
