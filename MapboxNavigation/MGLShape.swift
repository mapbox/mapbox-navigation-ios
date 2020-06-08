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

extension MGLPolyline {
    /**
     Initializes a map polyline representation of the given Turf linestring.
     
     - parameter lineString: The Turf linestring to convert to a map polyline.
     */
    public convenience init(_ lineString: LineString) {
        self.init(coordinates: lineString.coordinates, count: UInt(lineString.coordinates.count))
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

extension MGLMultiPolygon {
    public convenience init(_ multiPolygon: MultiPolygon) {
        let polygons = multiPolygon.coordinates.map { MGLPolygon(Polygon($0)) }
        self.init(polygons: polygons)
    }
}
