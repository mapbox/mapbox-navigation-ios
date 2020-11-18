import Foundation
import Mapbox
import Turf

extension MGLStyle {
    // The Mapbox China Day Style URL.
    static let mapboxChinaDayStyleURL = URL(string:"mapbox://styles/mapbox/streets-zh-v1")!
    
    // The Mapbox China Night Style URL.
    static let mapboxChinaNightStyleURL = URL(string:"mapbox://styles/mapbox/dark-zh-v1")!
    
    /**
     Returns the URL to the current version of the Mapbox Navigation Day style.
     */
    public class var navigationDayStyleURL: URL {
        get {
            if MGLAccountManager.hasChinaBaseURL {
                return mapboxChinaDayStyleURL
            }
            
            return URL(string:"mapbox://styles/mapbox/navigation-day-v1")!
        }
    }
    
    /**
     Returns the URL to the current version of the Mapbox Navigation Night style.
     */
    public class var navigationNightStyleURL: URL {
        get {
            if MGLAccountManager.hasChinaBaseURL {
                return mapboxChinaNightStyleURL
            }
            
            return URL(string:"mapbox://styles/mapbox/navigation-night-v1")!
        }
    }
    
    /**
     Returns the URL to the given version of the Mapbox Navigation Day style. Available versions are: 1.
     
     To use the Navigation Guidance Day or Navigation Preview Day style, which predates the Navigation Day style, create a mapbox: URL directly. For example:
     - Navigation Guidance Day: mapbox://styles/mapbox/navigation-guidance-day-v1 (available versions are: 1, 2, 3, and 4)
     - Navigation Preview Day: mapbox://styles/mapbox/navigation-preview-day-v1 (available versions are: 1, 2, 3, and 4)
     
     We only have one version of Mapbox Navigation Day style in China, so if you switch your endpoint to .cn, it will return the default day style.
     */
    public class func navigationDayStyleURL(version: Int) -> URL {
        if MGLAccountManager.hasChinaBaseURL {
            return mapboxChinaDayStyleURL
        }
        
        return URL(string:"mapbox://styles/mapbox/navigation-day-v\(version)")!
    }
    
    /**
     Returns the URL to the given version of the Mapbox Navigation Night style. Available versions are: 1.
     
     To use the Navigation Guidance Night or Navigation Preview Night style, which predates the Navigation Night style, create a mapbox: URL directly. For example:
     - Navigation Guidance Night: mapbox://styles/mapbox/navigation-guidance-night-v2 (available versions are: 2, 3, and 4)
     - Navigation Preview Night: mapbox://styles/mapbox/navigation-preview-night-v2 (available versions are: 2, 3, and 4)
     
     We only have one version of Mapbox Navigation Night style in China, so if you switch your endpoint to .cn, it will return the default night style.
     */
    public class func navigationNightStyleURL(version: Int) -> URL {
        if MGLAccountManager.hasChinaBaseURL {
            return mapboxChinaNightStyleURL
        }
        
        return URL(string:"mapbox://styles/mapbox/navigation-night-v\(version)")!
    }
    
    /**
     Remove the given style layers from the style in order.
     */
    func remove(_ layers: [MGLStyleLayer]) {
        for layer in layers {
            removeLayer(layer)
        }
    }
    
    /**
     Remove the given sources from the style.
     
     Only remove a source after removing all the style layers that use it.
     */
    func remove(_ sources: Set<MGLSource>) {
        for source in sources {
            removeSource(source)
        }
    }

    /**
     Convenience method for adding a circle at a given coordinate.

     Useful for debugging or visualizing data.
     */
    public func addDebugCircleLayer(identifier: String, coordinate: CLLocationCoordinate2D, color: UIColor = UIColor.purple) {
        let point = MGLPointFeature()
        point.coordinate = coordinate

        let dataSource = MGLShapeSource(identifier: "debugCircleLayer" + identifier, features: [point], options: nil)
        addSource(dataSource)

        let circle = MGLCircleStyleLayer(identifier: "debugCircleLayer" + identifier, source: dataSource)
        circle.circleRadius = NSExpression(forConstantValue: 10)
        circle.circleOpacity = NSExpression(forConstantValue: 0.75)
        circle.circleColor = NSExpression(forConstantValue: color)
        circle.circleStrokeWidth = NSExpression(forConstantValue: NSNumber(4))
        circle.circleStrokeColor = NSExpression(forConstantValue: UIColor.white)

        addLayer(circle)
    }

    /**
     Convenience method for adding a line connecting a given set of coordinates.

     Useful for debugging or visualizing data.
     */
    public func addDebugLineLayer(identifier: String, coordinates: [CLLocationCoordinate2D], color: UIColor = UIColor.purple) {
        let lineString = LineString(coordinates)
        let lineFeature = MGLPolylineFeature(lineString)
        let shapeSource = MGLShapeSource(identifier: "debugLineLayer" + identifier, features: [lineFeature], options: nil)
        addSource(shapeSource)

        let lineLayer = MGLLineStyleLayer(identifier: "debugLineLayer" + identifier, source: shapeSource)
        lineLayer.lineColor = NSExpression(forConstantValue: color)
        lineLayer.lineWidth = NSExpression(forConstantValue: 8)
        lineLayer.lineCap = NSExpression(forConstantValue: "round")
        addLayer(lineLayer)
    }

    /**
     Convenience method for adding a polygon shape.

     Useful for debugging or visualizing data.
     */
    public func addDebugPolygonLayer(identifier: String, coordinates: [CLLocationCoordinate2D], color: UIColor = UIColor.purple) {
        removeDebugPolygonLayers()

        let fillFeature = MGLPolygonFeature(coordinates: coordinates, count: UInt(coordinates.count))
        let shapeSource = MGLShapeSource(identifier: "debugPolygonLayer" + identifier, features: [fillFeature], options: nil)
        addSource(shapeSource)

        let fillLayer = MGLFillStyleLayer(identifier: "debugPolygonLayer" + identifier, source: shapeSource)
        fillLayer.fillColor = NSExpression(forConstantValue: color)
        fillLayer.fillOpacity = NSExpression(forConstantValue: NSNumber(0.25))
        fillLayer.fillOutlineColor = NSExpression(forConstantValue: color)
        fillLayer.fillOpacity = NSExpression(forConstantValue: NSNumber(0.75))
        addLayer(fillLayer)
    }

    /**
     Method to remove any debug line style layers.

     Call to clean up when you no longer need any debug layers added with addDebugLineLayer(identifier:, coordinates:, color:)
     */
    public func removeDebugLineLayers() {
        // remove any old layers
        let styleLayers = layers.filter({ layer -> Bool in
            guard let layer = layer as? MGLLineStyleLayer else { return false }
            return layer.identifier.contains("debugLineLayer")
        })

        remove(styleLayers)

        // remove any old sources
        let dataSources = sources.filter({ source -> Bool in
            return source.identifier.contains("debugLineLayer")
        })

        remove(dataSources)
    }

    /**
     Method to remove any debug fill style layers.

     Call to clean up when you no longer need any debug layers added with addDebugPolygonLayer(identifier:, coordinates:, color:)
     */
    public func removeDebugPolygonLayers() {
        let styleLayers = layers.filter({ layer -> Bool in
            guard let layer = layer as? MGLFillStyleLayer else { return false }
            return layer.identifier.contains("debugPolygonLayer")
        })

        remove(styleLayers)

        // remove any old sources
        let dataSources = sources.filter({ source -> Bool in
            return source.identifier.contains("debugPolygonLayer")
        })

        remove(dataSources)
    }

    /**
     Method to remove any debug circle style layers.

     Call to clean up when you no longer need any debug layers added with addDebugCircleLayer(identifier:, coordinate:, color:)
     */
    public func removeDebugCircleLayers() {
        // remove any old layers
        let styleLayers = layers.filter({ layer -> Bool in
            guard let layer = layer as? MGLCircleStyleLayer else { return false }
            return layer.identifier.contains("debugCircleLayer")
        })

        remove(styleLayers)

        // remove any old sources
        let dataSources = sources.filter({ source -> Bool in
            return source.identifier.contains("debugCircleLayer")
        })

        remove(dataSources)
    }
}
