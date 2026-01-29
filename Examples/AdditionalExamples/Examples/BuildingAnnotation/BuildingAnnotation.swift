/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import CoreLocation
import Foundation
@_spi(Experimental) import MapboxMaps
import UIKit

/// An annotation representing a 3D building on the map.
///
/// Building annotations are value types that define the visual appearance of a building.
/// To display them on the map, use a ``BuildingAnnotationManager``.
///
/// ## Example Usage
/// ```swift
/// var annotation = BuildingAnnotation(
///     id: "building-1",
///     coordinates: points
/// )
/// annotation.fillExtrusionColor = .red
/// annotation.fillExtrusionHeight = 50.0
///
/// let manager = BuildingAnnotationManager(mapView: mapView)
/// manager.annotations = [annotation]
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
    ///   - id: Unique identifier for this annotation
    ///   - coordinates: The list of coordinates for the building footprint polygon
    ///   - fillExtrusionColor: The color of the building extrusion (default: red)
    ///   - fillExtrusionOpacity: The opacity of the building extrusion (0.0-1.0, default: 0.8)
    ///   - fillExtrusionHeight: The height of the building extrusion in meters (default: 50.0)
    ///   - fillExtrusionBase: The base elevation of the building extrusion in meters (default: 0.0)
    public init(
        id: String = UUID().uuidString,
        coordinates: [CLLocationCoordinate2D],
        fillExtrusionColor: UIColor = .red,
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
}
