let accessToken = "<# Mapbox Access Token #>"

/**
 All frameworks except Mapbox iOS SDK will build automatically.
 Download the latest Mapbox iOS SDK with symbols from https://github.com/mapbox/mapbox-gl-native/releases
 Unzip and put Mapbox.framework in /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/Frameworks/
 */

import UIKit
import Mapbox
import MapboxDirections
import PlaygroundSupport


class DebugPointFeature: MGLPointFeature {
    var location: CLLocation!
}

let mapSize = CGSize(width: 700, height: 800)

MGLAccountManager.setAccessToken(accessToken)
let mapView = MGLMapView(frame: CGRect(origin: .zero, size: mapSize))

func draw(simulatedRoute: SimulatedRoute) {
    
    guard let locations = simulatedRoute.processedLocations else { return }
    
    // Draw simulated route
    let coordinates = locations.map({ $0.coordinate })
    
    let simulatedFeature = MGLPolylineFeature(coordinates: coordinates, count: UInt(coordinates.count))
    let simulatedSource = MGLShapeSource(identifier: "simulatedSource", features: [simulatedFeature], options: nil)
    mapView.style?.addSource(simulatedSource)
    
    let simulatedLayer = MGLLineStyleLayer(identifier: "simulatedLayer", source: simulatedSource)
    simulatedLayer.lineColor = MGLStyleValue(rawValue: #colorLiteral(red: 1, green: 0.2461264729, blue: 0.3175281286, alpha: 1))
    simulatedLayer.lineWidth = MGLStyleValue(rawValue: 2)
    mapView.style?.addLayer(simulatedLayer)
    
    // Add symbol layers for each simulated location
    for location in locations {
        let pointFeature = DebugPointFeature()
        pointFeature.location = location
        pointFeature.coordinate = location.coordinate
        let index = locations.index(of: location)!
        
        let symbolSource = MGLShapeSource(identifier: "symbolSource\(index)", features: [pointFeature], options: nil)
        mapView.style?.addSource(symbolSource)
        
        let symbolLayer = MGLSymbolStyleLayer(identifier: "symbolLayer\(index)", source: symbolSource)
        let debugLocation = location
        let timestamp = debugLocation.timestamp.timeIntervalSinceNow
        symbolLayer.text = MGLStyleValue(rawValue: "\(floor(debugLocation.speed*3.6))" as NSString)
//        symbolLayer.text = MGLStyleValue(rawValue: "\(timestamp)" as NSString)
//        symbolLayer.text = MGLStyleValue(rawValue: "\(debugLocation.turnPenalty)" as NSString)
//        symbolLayer.text = MGLStyleValue(rawValue: "\(debugLocation.coefficient)" as NSString)
        symbolLayer.textHaloColor = MGLStyleValue(rawValue: UIColor.white)
        symbolLayer.textHaloWidth = MGLStyleValue(rawValue: 1)
        mapView.style?.addLayer(symbolLayer)
    }
}


let origin = CLLocationCoordinate2D(latitude: 56.2064, longitude: 15.2734)
let destination = CLLocationCoordinate2D(latitude: 56.213204, longitude: 15.262874)

let centerCoordinate = CLLocationCoordinate2D(latitude: 56.2064, longitude: 15.2735)
let directions = Directions(accessToken: accessToken)

let options = RouteOptions(coordinates: [origin, destination], profileIdentifier: .automobile)
options.includesSteps = true
options.routeShapeResolution = .full
options.profileIdentifier = .automobileAvoidingTraffic

_ = directions.calculate(options) { (waypoints, routes, error) in
    if let route = routes?.first {
        // Draw route
        let coordinates = route.coordinates!
        let routeFeature = MGLPolylineFeature(coordinates: coordinates, count: UInt(coordinates.count))
        let source = MGLShapeSource(identifier: "routeSource", features: [routeFeature], options: nil)
        mapView.style?.addSource(source)
        
        let routeLayer = MGLLineStyleLayer(identifier: "routeLayer", source: source)
        routeLayer.lineColor = MGLStyleValue(rawValue: #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1))
        routeLayer.lineWidth = MGLStyleValue(rawValue: 5)
        mapView.style?.addLayer(routeLayer)
        
        // Draw simulated route
        if let simulatedRoute = SimulatedRoute(along: coordinates) {
            draw(simulatedRoute: simulatedRoute)
        }
        
        // Set visible bounds
        let padding = UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100)
        mapView.setVisibleCoordinates(coordinates, count: UInt(coordinates.count), edgePadding: padding, animated: false)
    }
}

PlaygroundPage.current.liveView = mapView

