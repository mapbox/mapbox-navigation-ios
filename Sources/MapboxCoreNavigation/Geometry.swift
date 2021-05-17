import Foundation
import MapboxNavigationNative
import Turf

extension Geometry {
    init(_ native: MBXGeometry) {
        switch native.geometryType {
        case MBXGeometryType_Point:
            if let point = native.extractLocations()?.locationValue {
                self = .point(Point(point))
            } else {
                preconditionFailure("Point can't be constructed. Geometry wasn't extracted.")
            }
        case MBXGeometryType_Line:
            if let coordinates = native.extractLocationsArray()?.map({ $0.locationValue }) {
                self = .lineString(LineString(coordinates))
            } else {
                preconditionFailure("LineString can't be constructed. Geometry wasn't extracted.")
            }
        case MBXGeometryType_Polygon:
            if let coordinates = native.extractLocations2DArray()?.map({ $0.map({ $0.locationValue }) }) {
                self = .polygon(Polygon(coordinates))
            } else {
                preconditionFailure("Polygon can't be constructed. Geometry wasn't extracted.")
            }
        case MBXGeometryType_MultiPoint:
            if let coordinates = native.extractLocationsArray()?.map({ $0.locationValue }) {
                self = .multiPoint(MultiPoint(coordinates))
            } else {
                preconditionFailure("MultiPoint can't be constructed. Geometry wasn't extracted.")
            }
        case MBXGeometryType_MultiLine:
            if let coordinates = native.extractLocations2DArray()?.map({ $0.map({ $0.locationValue }) }) {
                self = .multiLineString(MultiLineString(coordinates))
            } else {
                preconditionFailure("MultiLineString can't be constructed. Geometry wasn't extracted.")
            }
        case MBXGeometryType_MultiPolygon:
            if let coordinates = native.extractLocations3DArray()?.map({ $0.map({ $0.map({ $0.locationValue }) }) }) {
                self = .multiPolygon(MultiPolygon(coordinates))
            } else {
                preconditionFailure("MultiPolygon can't be constructed. Geometry wasn't extracted.")
            }
        case MBXGeometryType_GeometryCollection:
            if let geometries = native.extractGeometriesArray()?.compactMap(Geometry.init) {
                self = .geometryCollection(GeometryCollection(geometries: geometries))
            } else {
                preconditionFailure("GeometryCollection can't be constructed. Geometry wasn't extracted.")
            }
        case MBXGeometryType_Empty: fallthrough
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
