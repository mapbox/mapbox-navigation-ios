import Foundation
import MapboxCommon
import MapboxNavigationNative
import Turf

extension Turf.Geometry {
    
    init(_ native: MapboxCommon.Geometry) {
        switch native.geometryType {
        case GeometryType_Point:
            if let point = native.extractLocations()?.locationValue {
                self = .point(Point(point))
            } else {
                preconditionFailure("Point can't be constructed. Geometry wasn't extracted.")
            }
        case GeometryType_Line:
            if let coordinates = native.extractLocationsArray()?.map({ $0.locationValue }) {
                self = .lineString(LineString(coordinates))
            } else {
                preconditionFailure("LineString can't be constructed. Geometry wasn't extracted.")
            }
        case GeometryType_Polygon:
            if let coordinates = native.extractLocations2DArray()?.map({ $0.map({ $0.locationValue }) }) {
                self = .polygon(Polygon(coordinates))
            } else {
                preconditionFailure("Polygon can't be constructed. Geometry wasn't extracted.")
            }
        case GeometryType_MultiPoint:
            if let coordinates = native.extractLocationsArray()?.map({ $0.locationValue }) {
                self = .multiPoint(MultiPoint(coordinates))
            } else {
                preconditionFailure("MultiPoint can't be constructed. Geometry wasn't extracted.")
            }
        case GeometryType_MultiLine:
            if let coordinates = native.extractLocations2DArray()?.map({ $0.map({ $0.locationValue }) }) {
                self = .multiLineString(MultiLineString(coordinates))
            } else {
                preconditionFailure("MultiLineString can't be constructed. Geometry wasn't extracted.")
            }
        case GeometryType_MultiPolygon:
            if let coordinates = native.extractLocations3DArray()?.map({ $0.map({ $0.map({ $0.locationValue }) }) }) {
                self = .multiPolygon(MultiPolygon(coordinates))
            } else {
                preconditionFailure("MultiPolygon can't be constructed. Geometry wasn't extracted.")
            }
        case GeometryType_GeometryCollection:
            if let geometries = native.extractGeometriesArray()?.compactMap(Geometry.init) {
                self = .geometryCollection(GeometryCollection(geometries: geometries))
            } else {
                preconditionFailure("GeometryCollection can't be constructed. Geometry wasn't extracted.")
            }
        case GeometryType_Empty:
            fallthrough
        default:
            preconditionFailure("Geometry can't be constructed. Unknown type.")
        }
    }

}

extension NSValue {
    var locationValue: CLLocationCoordinate2D {
        let point = cgPointValue
        return CLLocationCoordinate2DMake(Double(point.x), Double(point.y))
    }
}
