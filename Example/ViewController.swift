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

class ViewController: UIViewController, MGLMapViewDelegate {

    var activeRoute: Route?
    var destination: CLLocationCoordinate2D?
    var directions = Directions(accessToken: "pk.eyJ1IjoiYm9iYnlzdWQiLCJhIjoiTi16MElIUSJ9.Clrqck--7WmHeqqvtFdYig")
    var navigation: Navigation?
    let distanceFormatter = DistanceFormatter(approximate: true)
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var instructionView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        distanceFormatter.unitStyle = .medium
        mapView.userTrackingMode = .follow
        resumeNotifications()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        suspendNotifications()
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.alertLevelDidChange(_ :)), name: NavigationControllerNotification.alertLevelDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.progressDidChange(_ :)), name: NavigationControllerNotification.progressDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.rerouted(_:)), name: NavigationControllerNotification.rerouted, object: nil)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: NavigationControllerNotification.alertLevelDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: NavigationControllerNotification.progressDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: NavigationControllerNotification.rerouted, object: nil)
    }
    
    @IBAction func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        
        destination = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
        getRoute()
    }
    
    func alertLevelDidChange(_ notification: NSNotification) {
        
    }
    
    func progressDidChange(_ notification: NSNotification) {
        let routeProgress = notification.userInfo![NavigationControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress

        if let upComingStep = routeProgress.currentLegProgress.upComingStep {
            instructionView.isHidden = false
            instructionLabel.text = "In \(distanceFormatter.string(from: routeProgress.currentLegProgress.currentStepProgress.distanceRemaining)) \(upComingStep.instructions)"
        } else {
            instructionView.isHidden = true
        }
    }
    
    func rerouted(_ notification: NSNotification) {
        getRoute()
    }
    
    func getRoute() {
        let options = RouteOptions(coordinates: [mapView.userLocation!.coordinate, destination!])
        options.includesSteps = true
        options.includesSteps = true
        
        _ = directions.calculate(options) { [weak self] (waypoints, routes, error) in
            if let route = routes?.first {
                self?.mapView.removeAnnotations(self?.mapView.annotations ?? [])
                var routeCoordinates = route.coordinates!
                let line = MGLPolyline(coordinates: &routeCoordinates, count: route.coordinateCount)
                self?.mapView.addAnnotation(line)
                
                self?.startNavigation(route)
                
            }
        }
    }
    
    func startNavigation(_ route: Route) {
        mapView.userTrackingMode = .followWithCourse
        navigation = Navigation(route: route)
        navigation?.resume()
    }
    
}

