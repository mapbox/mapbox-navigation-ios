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

let sourceIdentifier = "sourceIdentifier"
let layerIdentifier = "layerIdentifier"

class ViewController: UIViewController, MGLMapViewDelegate {

    var destination: CLLocationCoordinate2D?
    let directions = Directions(accessToken: MapboxAccessToken)
    var navigation: RouteController?

    // `identityPoolId` is a required value for using AWS Polly voice instead of iOS's built in AVSpeechSynthesizer
    // You can get a token here: http://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth-aws-identity-for-ios.html
    var routeVoiceController = RouteVoiceController(identityPoolId: "<#Your AWS IdentityPoolId. Remove Argument if you do not want to use AWS Polly#>")
    var isInNavigationMode = false
    var userRoute: Route?
    
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var instructionView: UIView!
    @IBOutlet weak var toggleNavigationButton: UIButton!
    @IBOutlet weak var howToBeginLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.userTrackingMode = .follow
        resumeNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        suspendNotifications()
        navigation?.suspend()
        routeVoiceController.suspendNotifications()
    }
    
    @IBAction func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        
        destination = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
        getRoute()
    }
    
    @IBAction func didToggleNavigation(_ sender: Any) {
        if isInNavigationMode {
            endNavigation()
        } else {
            startNavigation(userRoute!)
        }
        isInNavigationMode = !isInNavigationMode
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
            toggleNavigationButton.setTitle("End Navigation", for: .normal)
        } else {
            toggleNavigationButton.setTitle("Start Navigation", for: .normal)
        }
    }
    
    // When the alert level changes, this signals the user is ready for a voice announcement
    func alertLevelDidChange(_ notification: NSNotification) {
        // Do something when the alert level changes.
        // Internally, we're using this method for voice alerts.
    }
    
    // Notifications sent on all location updates
    func progressDidChange(_ notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress

        if let upComingStep = routeProgress.currentLegProgress.upComingStep {
            instructionView.isHidden = false
            instructionLabel.text = "In \(roundToTens(routeProgress.currentLegProgress.currentStepProgress.distanceRemaining))m \(upComingStep.instructions)"
        } else {
            instructionView.isHidden = true
        }
    }
    
    // Fired when the user is no longer on the route.
    // A new route should be fetched at this time.
    func rerouted(_ notification: NSNotification) {
        getRoute {
            /*
             **IMPORTANT**
             
             When rerouting, you need to give the RouteController a new route.
             Otherwise, it will continue to compare the user to the old route and continually reroute the user.
             */
            self.navigation?.routeProgress = RouteProgress(route: self.userRoute!)
        }
    }
    
    func getRoute(didFinish: (()->())? = nil) {
        let options = RouteOptions(coordinates: [mapView.userLocation!.coordinate, destination!])
        options.includesSteps = true
        options.routeShapeResolution = .full
        options.profileIdentifier = MBDirectionsProfileIdentifierAutomobileAvoidingTraffic
        
        _ = directions.calculate(options) { [weak self] (waypoints, routes, error) in
            guard error == nil else {
                print(error!)
                return
            }
            guard let route = routes?.first else {
                return
            }
            guard let style = self?.mapView.style else {
                return
            }
            
            self?.userRoute = route
            self?.toggleNavigationButton.isHidden = false
            self?.howToBeginLabel.isHidden = true
            
            // Remove old destination marker
            self?.removeRoutesFromMap()
            
            // Add destination marker
            let destinationMarker = MGLPointAnnotation()
            destinationMarker.coordinate = route.coordinates!.last!
            self?.mapView.addAnnotation(destinationMarker)
            
            let polyline = MGLPolylineFeature(coordinates: route.coordinates!, count: route.coordinateCount)
            let geoJSONSource = MGLShapeSource(identifier: sourceIdentifier, shape: polyline, options: nil)
            let line = MGLLineStyleLayer(identifier: layerIdentifier, source: geoJSONSource)
            
            // Style the line
            line.lineColor = MGLStyleValue(rawValue: UIColor(red:0.00, green:0.45, blue:0.74, alpha:0.9))
            line.lineWidth = MGLStyleValue(rawValue: 5)
            line.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
            line.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))

            // Add source and layer
            style.addSource(geoJSONSource)
            for layer in style.layers.reversed() {
                if !(layer is MGLSymbolStyleLayer) {
                    style.insertLayer(line, above: layer)
                    break
                }
            }
            
            didFinish?()
        }
    }
    
    func startNavigation(_ route: Route) {
        let camera = mapView.camera
        camera.pitch = 40
        mapView.setCamera(camera, animated: false)
        mapView.userTrackingMode = .followWithCourse
        navigation = RouteController(route: route)
        navigation?.resume()
    }
    
    func endNavigation() {
        instructionView.isHidden = true
        toggleNavigationButton.isHidden = true
        howToBeginLabel.isHidden = false
        mapView.userTrackingMode = .none
        let camera = mapView.camera
        camera.pitch = 0
        mapView.setCamera(camera, animated: true)
        removeRoutesFromMap()
        
        navigation?.suspend()
        
        routeVoiceController.suspendNotifications()
        routeVoiceController.stopVoice()
    }
    
    func removeRoutesFromMap() {
        guard let style = mapView.style else {
            return
        }
        if let line = style.layer(withIdentifier: layerIdentifier) {
            style.removeLayer(line)
        }
        if let source = style.source(withIdentifier: sourceIdentifier) {
            style.removeSource(source)
        }
        mapView.removeAnnotations(mapView.annotations ?? [])
    }
    
    func roundToTens(_ x: CLLocationDistance) -> Int {
        return 10 * Int(round(x / 10.0))
    }
}

