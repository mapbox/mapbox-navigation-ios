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
        routeLayer.lineColor = MGLStyleValue(rawValue: UIColor.red)
        routeLayer.lineWidth = MGLStyleValue(rawValue: 3)
        mapView.style?.addLayer(routeLayer)
        
        // Draw simulated route
        let simulatedRoute = SimulatedRoute(along: coordinates)
        let simulatedFeature = MGLPolylineFeature(coordinates: simulatedRoute.coordinates, count: UInt(simulatedRoute.coordinates.count))
        let simulatedSource = MGLShapeSource(identifier: "simulatedSource", features: [simulatedFeature], options: nil)
        mapView.style?.addSource(simulatedSource)
        
        let simulatedLayer = MGLLineStyleLayer(identifier: "simulatedLayer", source: simulatedSource)
        simulatedLayer.lineColor = MGLStyleValue(rawValue: UIColor.blue)
        simulatedLayer.lineWidth = MGLStyleValue(rawValue: 3)
        mapView.style?.addLayer(simulatedLayer)
        
        // Add symbol layers for each simulated location
        for location in simulatedRoute.locations {
            let pointFeature = DebugPointFeature()
            pointFeature.location = location
            pointFeature.coordinate = location.coordinate
            let index = simulatedRoute.locations.index(of: location)!
            
            let symbolSource = MGLShapeSource(identifier: "symbolSource\(index)", features: [pointFeature], options: nil)
            mapView.style?.addSource(symbolSource)

            let symbolLayer = MGLSymbolStyleLayer(identifier: "symbolLayer\(index)", source: symbolSource)
            symbolLayer.text = MGLStyleValue(rawValue: "\(location.speed)" as NSString)
            symbolLayer.textHaloColor = MGLStyleValue(rawValue: UIColor.white)
            symbolLayer.textHaloWidth = MGLStyleValue(rawValue: 1)
            mapView.style?.addLayer(symbolLayer)
        }
        
        // Set visible bounds
        let padding = UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100)
        mapView.setVisibleCoordinates(coordinates, count: UInt(coordinates.count), edgePadding: padding, animated: false)
    }
}

PlaygroundPage.current.liveView = mapView

