/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import CoreLocation
import Foundation
@_spi(Experimental) import MapboxMaps
#if canImport(SwiftUI)
import SwiftUI
#endif
import Turf
import UIKit

/// An annotation representing a 3D building on the map.
///
/// Building annotations are value types that define the visual appearance of a building.
///
/// ## UIKit Usage
/// ```swift
/// let annotation = BuildingAnnotation(
///     coordinates: points,
///     fillExtrusionHeight: 50.0
/// )
///
/// let manager = BuildingAnnotationManager(mapView: mapView)
/// manager.annotations = [annotation]
/// ```
///
/// ## SwiftUI Usage
/// ```swift
/// Map {
///     BuildingAnnotation(coordinates: points)
///         .fillExtrusionHeight(50.0)
///         .fillExtrusionColor(.blue)
/// }
/// ```
public struct BuildingAnnotation {
    public let id: String

    public var coordinates: [CLLocationCoordinate2D]
    public var fillExtrusionColor: UIColor
    public var fillExtrusionOpacity: Double
    public var fillExtrusionHeight: Double
    public var fillExtrusionBase: Double

    /// Creates a new building annotation.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for this annotation (default: auto-generated UUID)
    ///   - coordinates: The list of coordinates for the building footprint polygon
    ///   - fillExtrusionColor: The color of the building extrusion (default: blue hsl(214, 94%, 59%) = #3489F9)
    ///   - fillExtrusionOpacity: The opacity of the building extrusion (0.0-1.0, default: 0.8)
    ///   - fillExtrusionHeight: The height of the building extrusion in meters (default: 50.0)
    ///   - fillExtrusionBase: The base elevation of the building extrusion in meters (default: 0.0)
    public init(
        id: String = UUID().uuidString,
        coordinates: [CLLocationCoordinate2D],
        fillExtrusionColor: UIColor = UIColor(red: 0.204, green: 0.537, blue: 0.976, alpha: 1.0),
        fillExtrusionOpacity: Double = 0.8,
        fillExtrusionHeight: Double = 50.0,
        fillExtrusionBase: Double = 0.0
    ) {
        self.id = id
        self.coordinates = coordinates
        self.fillExtrusionColor = fillExtrusionColor
        self.fillExtrusionOpacity = fillExtrusionOpacity
        self.fillExtrusionHeight = fillExtrusionHeight
        self.fillExtrusionBase = fillExtrusionBase
    }

    internal var sourceId: String { "building-annotation-source-\(id)" }
    internal var layerId: String { "building-annotation-layer-\(id)" }

    /// Sets the fill extrusion color.
    /// - Parameter color: The color to use for the building extrusion
    /// - Returns: A new annotation with the updated color
    public func fillExtrusionColor(_ color: UIColor) -> Self {
        var copy = self
        copy.fillExtrusionColor = color
        return copy
    }

    /// Sets the fill extrusion opacity.
    /// - Parameter opacity: The opacity value (0.0 to 1.0)
    /// - Returns: A new annotation with the updated opacity
    public func fillExtrusionOpacity(_ opacity: Double) -> Self {
        var copy = self
        copy.fillExtrusionOpacity = opacity
        return copy
    }

    /// Sets the fill extrusion height.
    /// - Parameter height: The height in meters
    /// - Returns: A new annotation with the updated height
    public func fillExtrusionHeight(_ height: Double) -> Self {
        var copy = self
        copy.fillExtrusionHeight = height
        return copy
    }

    /// Sets the fill extrusion base.
    /// - Parameter base: The base elevation in meters
    /// - Returns: A new annotation with the updated base
    public func fillExtrusionBase(_ base: Double) -> Self {
        var copy = self
        copy.fillExtrusionBase = base
        return copy
    }
}

#if canImport(SwiftUI)
@available(iOS 14.0, *)
extension BuildingAnnotation: MapStyleContent {
    public var body: some MapStyleContent {
        GeoJSONSource(id: sourceId)
            .data(.geometry(.polygon(Polygon([coordinates]))))

        FillExtrusionLayer(id: layerId, source: sourceId)
            .fillExtrusionColor(fillExtrusionColor)
            .fillExtrusionHeight(fillExtrusionHeight)
            .fillExtrusionBase(fillExtrusionBase)
            .fillExtrusionOpacity(fillExtrusionOpacity)
    }
}
#endif
