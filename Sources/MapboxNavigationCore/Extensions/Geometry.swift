import Foundation
import MapboxCommon
import MapboxNavigationNative_Private
import Turf

extension Turf.Geometry {
    init?(_ native: MapboxCommon.Geometry) {
        switch native.geometryType {
        case GeometryType_Point:
            if let point = native.extractLocations()?.locationValue {
                self = .point(Point(point))
            } else {
                Self.logInconsistentValue(for: "Point")
                return nil
            }
        case GeometryType_Line:
            if let coordinates = native.extractLocationsArray()?.map(\.locationValue) {
                self = .lineString(LineString(coordinates))
            } else {
                Self.logInconsistentValue(for: "LineString")
                return nil
            }
        case GeometryType_Polygon:
            if let coordinates = native.extractLocations2DArray()?.map({ $0.map(\.locationValue) }) {
                self = .polygon(Polygon(coordinates))
            } else {
                Self.logInconsistentValue(for: "Polygon")
                return nil
            }
        case GeometryType_MultiPoint:
            if let coordinates = native.extractLocationsArray()?.map(\.locationValue) {
                self = .multiPoint(MultiPoint(coordinates))
            } else {
                Self.logInconsistentValue(for: "MultiPoint")
                return nil
            }
        case GeometryType_MultiLine:
            if let coordinates = native.extractLocations2DArray()?.map({ $0.map(\.locationValue) }) {
                self = .multiLineString(MultiLineString(coordinates))
            } else {
                Self.logInconsistentValue(for: "MultiLineString")
                return nil
            }
        case GeometryType_MultiPolygon:
            if let coordinates = native.extractLocations3DArray()?.map({ $0.map { $0.map(\.locationValue) } }) {
                self = .multiPolygon(MultiPolygon(coordinates))
            } else {
                Self.logInconsistentValue(for: "MultiPolygon")
                return nil
            }
        case GeometryType_GeometryCollection:
            if let geometries = native.extractGeometriesArray()?.compactMap(Geometry.init) {
                self = .geometryCollection(GeometryCollection(geometries: geometries))
            } else {
                Self.logInconsistentValue(for: "GeometryCollection")
                return nil
            }
        case GeometryType_Empty:
            fallthrough
        default:
            Log.info("Geometry can't be constructed. Unknown type.", category: .parsing)
            return nil
        }
    }

    private static func logInconsistentValue(for type: String) {
        Log.info("\(type) can't be constructed. Geometry wasn't extracted.", category: .parsing)
    }
}

extension NSValue {
    var locationValue: CLLocationCoordinate2D {
        let point = cgPointValue
        return CLLocationCoordinate2DMake(Double(point.x), Double(point.y))
    }
}
