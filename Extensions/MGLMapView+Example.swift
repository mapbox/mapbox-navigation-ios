import Foundation
import Mapbox
import Turf

extension MGLMapView {
    func coordinateBoundsInset(_ inset: CGSize) -> MGLCoordinateBounds {
        return convert(bounds.insetBy(dx: inset.width, dy: inset.height), toCoordinateBoundsFrom: nil)
    }
}


extension MGLStyle {
    func addDebugLineLayer(identifier: String, coordinates: [CLLocationCoordinate2D], color: UIColor = UIColor.purple) {
//        removeDebugLineLayers()

        let lineString = LineString(coordinates)
        let lineFeature = MGLPolylineFeature(lineString)
        let shapeSource = MGLShapeSource(identifier: "addDebugLineLayer" + identifier, features: [lineFeature], options: nil)
        addSource(shapeSource)

        let lineLayer = MGLLineStyleLayer(identifier: "addDebugLineLayer" + identifier, source: shapeSource)
        lineLayer.lineColor = NSExpression(forConstantValue: color)
        lineLayer.lineWidth = NSExpression(forConstantValue: 24)
        lineLayer.lineCap = NSExpression(forConstantValue: "round")
        addLayer(lineLayer)
    }

    func addDebugPolygonLayer(identifier: String, coordinates: [CLLocationCoordinate2D], color: UIColor = UIColor.purple) {
        removeDebugFillLayers()

        let fillFeature = MGLPolygonFeature(coordinates: coordinates, count: UInt(coordinates.count))
        let shapeSource = MGLShapeSource(identifier: "addDebugPolygonLayer" + identifier, features: [fillFeature], options: nil)
        addSource(shapeSource)

        let fillLayer = MGLFillStyleLayer(identifier: "addDebugPolygonLayer" + identifier, source: shapeSource)
        fillLayer.fillColor = NSExpression(forConstantValue: color)
        fillLayer.fillOpacity = NSExpression(forConstantValue: NSNumber(0.25))
        fillLayer.fillOutlineColor = NSExpression(forConstantValue: color)
        fillLayer.fillOpacity = NSExpression(forConstantValue: NSNumber(0.75))
        addLayer(fillLayer)
    }

    func removeDebugLineLayers() {
        // remove any old layers
        for lineLayer in layers.filter({ layer -> Bool in
            guard let layer = layer as? MGLLineStyleLayer else { return false }
            return layer.identifier.contains("addDebugLineLayer")
        }) {
            removeLayer(lineLayer)
        }

        // remove any old sources
        for dataSource in sources.filter({ source -> Bool in
            return source.identifier.contains("addDebugLineLayer")
        }) {
            removeSource(dataSource)
        }
    }

    func removeDebugFillLayers() {
        // remove any old layers
        for lineLayer in layers.filter({ layer -> Bool in
            guard let layer = layer as? MGLFillStyleLayer else { return false }
            return layer.identifier.contains("addDebugPolygonLayer")
        }) {
            removeLayer(lineLayer)
        }

        // remove any old sources
        for dataSource in sources.filter({ source -> Bool in
            return source.identifier.contains("addDebugPolygonLayer")
        }) {
            removeSource(dataSource)
        }
    }
}
