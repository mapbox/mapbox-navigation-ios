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

class ViewController: UIViewController, MGLMapViewDelegate, AVSpeechSynthesizerDelegate {

    var destination: CLLocationCoordinate2D?
    let directions = Directions.shared
    var navigation: RouteController?
    
    let lengthFormatter = LengthFormatter()
    lazy var speechSynth = AVSpeechSynthesizer()
    
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var instructionView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lengthFormatter.unitStyle = .short
        mapView.userTrackingMode = .follow
        resumeNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        suspendNotifications()
        navigation?.suspend()
    }
    
    @IBAction func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        
        destination = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
        getRoute()
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
        getRoute()
    }
    
    func getRoute() {
        let options = RouteOptions(coordinates: [mapView.userLocation!.coordinate, destination!])
        options.includesSteps = true
        options.routeShapeResolution = .full
        options.profileIdentifier = MBDirectionsProfileIdentifierAutomobileAvoidingTraffic
        
        _ = directions.calculate(options) { [weak self] (waypoints, routes, error) in
            guard let route = routes?.first else {
                return
            }
            self?.mapView.removeAnnotations(self?.mapView.annotations ?? [])
            var routeCoordinates = route.coordinates!
            let line = MGLPolyline(coordinates: &routeCoordinates, count: route.coordinateCount)
            self?.mapView.addAnnotation(line)
            
            self?.startNavigation(route)
        }
    }
    
    func startNavigation(_ route: Route) {
        mapView.userTrackingMode = .followWithCourse
        navigation = RouteController(route: route)
        navigation?.resume()
    }
}

