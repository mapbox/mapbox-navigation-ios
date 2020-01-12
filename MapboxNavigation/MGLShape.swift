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
     
     - parameter pointFeature: The Turf point feature to convert to a map point feature.
     */
    public convenience init(_ pointFeature: PointFeature) {
        self.init(pointFeature.geometry)
        identifier = pointFeature.identifier
        attributes = pointFeature.properties ?? [:]
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
     
     - parameter lineStringFeature: The Turf linestring feature to convert to a map polyline feature.
     */
    public convenience init(_ lineStringFeature: LineStringFeature) {
        self.init(lineStringFeature.geometry)
        identifier = lineStringFeature.identifier
        attributes = lineStringFeature.properties ?? [:]
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
     
     - parameter multiLineStringFeature: The Turf multilinestring feature to convert to a map multipolyline feature.
     */
    public convenience init(_ multiLineStringFeature: MultiLineStringFeature) {
        self.init(multiLineStringFeature.geometry)
        identifier = multiLineStringFeature.identifier
        attributes = multiLineStringFeature.properties ?? [:]
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
        let interiorPolygons = polygon.innerRings?.map { MGLPolygon($0) }
        self.init(coordinates: outerCoordinates, count: UInt(outerCoordinates.count), interiorPolygons: interiorPolygons)
    }
}

extension MGLPolygonFeature {
    /**
     Initializes a map polygon feature representation of the given Turf polygon feature.
     
     - parameter polygonFeature: The Turf polygon feature to convert to a map polygon feature.
     */
    public convenience init(_ polygonFeature: PolygonFeature) {
        self.init(polygonFeature.geometry)
        identifier = polygonFeature.identifier
        attributes = polygonFeature.properties ?? [:]
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
     
     - parameter multipolygonFeature: The Turf multipolygon feature to convert to a map multipolygon feature.
     */
    public convenience init(_ multiPolygonFeature: MultiPolygonFeature) {
        self.init(multiPolygonFeature.geometry)
        identifier = multiPolygonFeature.identifier
        attributes = multiPolygonFeature.properties ?? [:]
    }
}
