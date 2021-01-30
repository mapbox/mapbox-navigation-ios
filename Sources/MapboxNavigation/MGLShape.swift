import Mapbox
import Turf

extension MGLPointAnnotation {
    /**
     Initializes a map point representation of the given Turf point.
     
     - parameter point: The Turf point to convert to a map point.
     */
    public convenience init(_ point: Point) {
        self.init()
        coordinate = point.coordinates
    }
}

extension MGLPointFeature {
    /**
     Initializes a map point feature representation of the given Turf point feature.
     
     - parameter pointFeature: The Turf `Point` feature to convert to a map point feature. If the Feature passed is not of type `Point` - initialization fails.
     */
    public convenience init?(_ pointFeature: Feature) {
        guard case let .point(pointGeometry) = pointFeature.geometry else {
            return nil
        }
        self.init(pointGeometry)
        identifier = pointFeature.identifier
        attributes = pointFeature.properties?.compactMapValues {
            return $0
        } ?? [:]
    }
}

extension MGLPolyline {
    /**
     Initializes a map polyline representation of the given Turf linestring.
     
     - parameter lineString: The Turf linestring to convert to a map polyline.
     */
    public convenience init(_ lineString: LineString) {
        self.init(coordinates: lineString.coordinates, count: UInt(lineString.coordinates.count))
    }
}

extension MGLPolylineFeature {
    /**
     Initializes a map polyline feature representation of the given Turf linestring feature.
     
     - parameter lineStringFeature: The Turf `LineString` feature to convert to a map polyline feature. If the Feature passed is not of type `LineString` - initialization fails.
     */
    public convenience init?(_ lineStringFeature: Feature) {
        guard case let .lineString(lineStringGeometry) = lineStringFeature.geometry else {
            return nil
        }
        self.init(lineStringGeometry)
        identifier = lineStringFeature.identifier
        attributes = lineStringFeature.properties?.compactMapValues {
            return $0
        } ?? [:]
    }
}

extension MGLMultiPolyline {
    /**
     Initializes a map multipolyline representation of the given Turf multi linestring.
     
     - parameter lineString: The Turf multilinestring to convert to a map multipolyline.
     */
    public convenience init(_ multiLineString: MultiLineString) {
        let polylines = multiLineString.coordinates.map { MGLPolyline(LineString($0)) }
        self.init(polylines: polylines)
    }
}

extension MGLMultiPolylineFeature {
    /**
     Initializes a map multipolyline feature representation of the given Turf multilinestring feature.
     
     - parameter multiLineStringFeature: The Turf `MultiLineString` feature to convert to a map multipolyline feature. If the Feature passed is not of type `MultiLineString` - initialization fails.
     */
    public convenience init?(_ multiLineStringFeature: Feature) {
        guard case let .multiLineString(multiLineStringGeometry) = multiLineStringFeature.geometry else {
            return nil
        }
        self.init(multiLineStringGeometry)
        identifier = multiLineStringFeature.identifier
        attributes = multiLineStringFeature.properties?.compactMapValues {
            return $0
        } ?? [:]
    }
}

extension MGLPolygon {
    /**
     Initializes a map polygon representation of the given Turf ring.
     
     - parameter ring: The Turf ring to convert to a map polygon.
     */
    public convenience init(_ ring: Ring) {
        self.init(coordinates: ring.coordinates, count: UInt(ring.coordinates.count))
    }
    
    /**
     Initializes a map polygon representation of the given Turf polygon.
     
     - parameter ring: The Turf ring to convert to a map polygon.
     */
    public convenience init(_ polygon: Polygon) {
        let outerCoordinates = polygon.outerRing.coordinates
        let interiorPolygons = polygon.innerRings.map { MGLPolygon($0) }
        self.init(coordinates: outerCoordinates, count: UInt(outerCoordinates.count), interiorPolygons: interiorPolygons)
    }
}

extension MGLPolygonFeature {
    /**
     Initializes a map polygon feature representation of the given Turf polygon feature.
     
     - parameter polygonFeature: The Turf `Polygon` feature to convert to a map polygon feature. If the Feature passed is not of type `Polygon` - initialization fails.
     */
    public convenience init?(_ polygonFeature: Feature) {
        guard case let .polygon(polygonGeometry) = polygonFeature.geometry else {
            return nil
        }
        self.init(polygonGeometry)
        identifier = polygonFeature.identifier
        attributes = polygonFeature.properties?.compactMapValues {
            return $0
        } ?? [:]
    }
}

extension MGLMultiPolygon {
    public convenience init(_ multiPolygon: MultiPolygon) {
        let polygons = multiPolygon.coordinates.map { MGLPolygon(Polygon($0)) }
        self.init(polygons: polygons)
    }
}

extension MGLMultiPolygonFeature {
    /**
     Initializes a map multipolygon feature representation of the given Turf multipolygon feature.
     
     - parameter multipolygonFeature: The Turf `MultiPolygon` feature to convert to a map multipolygon feature. If the Feature passed is not of type `MultiPolygon` - initialization fails.
     */
    public convenience init?(_ multiPolygonFeature: Feature) {
        guard case let .multiPolygon(multiPolygonGeometry) = multiPolygonFeature.geometry else {
            return nil
        }
        self.init(multiPolygonGeometry)
        identifier = multiPolygonFeature.identifier
        attributes = multiPolygonFeature.properties?.compactMapValues {
            return $0
        } ?? [:]
    }
}
