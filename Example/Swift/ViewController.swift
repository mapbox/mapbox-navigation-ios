//
//  ViewController.swift
//  Example
//
//  Created by Bobby Sudekum on 11/16/16.
//  Copyright © 2016 Mapbox. All rights reserved.
//
import UIKit
import MapboxNavigation
import MapboxDirections
import Mapbox
import CoreLocation
import AVFoundation

// A Mapbox access token is required to use the Directions API.
// https://www.mapbox.com/help/create-api-access-token/
let MapboxAccessToken = "<#Your Mapbox access token#>"
let lineSourceIdentifier = "lineSource"
let lineIdentifier = "line"
let edgePadding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

class ViewController: UIViewController, MGLMapViewDelegate, AVSpeechSynthesizerDelegate {
    
    var destination: CLLocationCoordinate2D?
    let directions = Directions(accessToken: MapboxAccessToken)
    var navigation: RouteController?
    
    let lengthFormatter = LengthFormatter()
    lazy var speechSynth = AVSpeechSynthesizer()
    var userRoute:Route? = nil
    
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var instructionView: UIView!
    @IBOutlet weak var startNavigationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MGLAccountManager.setAccessToken(MapboxAccessToken)
        
        lengthFormatter.unitStyle = .short
        mapView.userTrackingMode = .follow
        resumeNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        suspendNotifications()
        navigation?.suspend()
    }

    @IBAction func startNavigation(_ sender: Any) {
        if mapView.userTrackingMode == .followWithCourse {
            endNavigation()
        } else {
            startNavigation(route: userRoute!)
        }
    }
    
    @IBAction func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        
        destination = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
        getRoute(isReroute: false)
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.alertLevelDidChange(_ :)), name: RouteControllerAlertLevelDidChange, object: navigation)
        NotificationCenter.default.addObserver(self, selector: #selector(self.progressDidChange(_ :)), name: RouteControllerProgressDidChange, object: navigation)
        NotificationCenter.default.addObserver(self, selector: #selector(self.rerouted(_:)), name: RouteControllerShouldReroute, object: navigation)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: RouteControllerAlertLevelDidChange, object: navigation)
        NotificationCenter.default.removeObserver(self, name: RouteControllerProgressDidChange, object: navigation)
        NotificationCenter.default.removeObserver(self, name: RouteControllerShouldReroute, object: navigation)
    }
    
    func mapView(_ mapView: MGLMapView, didChange mode: MGLUserTrackingMode, animated: Bool) {
        if mode == .followWithCourse {
            startNavigationButton.titleLabel?.text = "End Navigation"
        } else {
            startNavigationButton.titleLabel?.text = "Start Navigation"
        }
    }
    
    // When the alert level changes, this signals the user is ready for a voice announcement
    func alertLevelDidChange(_ notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
        let alertLevel = routeProgress.currentLegProgress.alertUserLevel
        var text: String
        
        if let upComingStep = routeProgress.currentLegProgress.upComingStep {
            // Don't give full instruction with distance if the alert type is high
            if alertLevel == .high {
                text = upComingStep.instructions
            } else {
                text = "In \(lengthFormatter.string(fromMeters: routeProgress.currentLegProgress.currentStepProgress.distanceRemaining)) \(upComingStep.instructions)"
            }
        } else {
            text = "In \(lengthFormatter.string(fromMeters: routeProgress.currentLegProgress.currentStepProgress.distanceRemaining)) \(routeProgress.currentLegProgress.currentStep.instructions)"
        }
        
        let utterance = AVSpeechUtterance(string: text)
        speechSynth.delegate = self
        speechSynth.speak(utterance)
    }
    
    // Notifications sent on all location updates
    func progressDidChange(_ notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
        
        if let upComingStep = routeProgress.currentLegProgress.upComingStep {
            instructionView.isHidden = false
            instructionLabel.text = "In \(lengthFormatter.string(fromMeters: routeProgress.currentLegProgress.currentStepProgress.distanceRemaining)) \(upComingStep.instructions)"
        } else {
            instructionView.isHidden = true
        }
    }
    
    // Fired when the user is no longer on the route.
    // A new route should be fetched at this time.
    func rerouted(_ notification: NSNotification) {
        getRoute(isReroute: true)
    }
    
    func getRoute(isReroute: Bool) {
        let options = RouteOptions(coordinates: [mapView.userLocation!.coordinate, destination!])
        options.includesSteps = true
        options.routeShapeResolution = .full
        options.profileIdentifier = MBDirectionsProfileIdentifierAutomobileAvoidingTraffic
        
        // Setup destination marker
        let destinationMarker = MGLPointAnnotation()
        destinationMarker.title = "Destination"
        
        // Remove previous markers
        mapView.removeAnnotations(mapView.annotations ?? [])
        
        _ = directions.calculate(options) { [weak self] (waypoints, routes, error) in
            guard let route = routes?.first else {
                return
            }
            guard let style = self?.mapView.style else {
                return
            }
            self?.userRoute = route
            var coordinates = route.coordinates!
            
            // Add destination marker to map
            destinationMarker.coordinate = coordinates.last!
            self?.mapView.addAnnotation(destinationMarker)
            
            
            // Don't fit bounds and show button if rerouting
            if !isReroute {
                self?.mapView.setVisibleCoordinateBounds(MGLPolyline(coordinates: &coordinates, count: UInt(coordinates.count)).overlayBounds, edgePadding: edgePadding, animated: true)
                self?.startNavigationButton.isHidden = false
            }
            
            // Remove layer and source if they are already on the map
            if let line = style.layer(withIdentifier: lineIdentifier) {
                style.removeLayer(line)
            }
            if let source = style.source(withIdentifier: lineSourceIdentifier) {
                style.removeSource(source)
            }
            
            let polyline = MGLPolylineFeature(coordinates: &coordinates, count: route.coordinateCount)
            let geoJSONSource = MGLShapeSource(identifier: lineSourceIdentifier, shape: polyline, options: nil)
            let line = MGLLineStyleLayer(identifier: lineIdentifier, source: geoJSONSource)
            
            
            // Style the line
            line.lineWidth = MGLStyleValue(rawValue: 5)
            line.lineColor = MGLStyleValue(rawValue: UIColor(red:0.22, green:0.53, blue:0.75, alpha:0.9))
            line.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
            line.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
            
            style.addSource(geoJSONSource)
            
            // Insert the roads below the lowest text layer
            for layer in style.layers.reversed() {
                if !(layer is MGLSymbolStyleLayer) {
                    style.insertLayer(line, above: layer)
                    return
                }
            }
        }
    }
    
    func startNavigation(route: Route) {
        mapView.camera = MGLMapCamera(lookingAtCenter: mapView.userLocation!.coordinate, fromDistance: 1000, pitch: 40, heading: mapView.userLocation!.location!.course)
        mapView.userTrackingMode = .followWithCourse
        navigation = RouteController(route: route)
        navigation?.resume()
    }
    
    func endNavigation() {
        mapView.userTrackingMode = .none
        startNavigationButton.isHidden = true
        instructionView.isHidden = true
        let camera = mapView.camera
        camera.pitch = 0
        mapView.setCamera(camera, animated: true)
    }
}
