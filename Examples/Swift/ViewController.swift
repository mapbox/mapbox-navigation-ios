import UIKit
import MapboxNavigation
import MapboxNavigationUI
import MapboxDirections
import Mapbox
import CoreLocation
import AVFoundation

let sourceIdentifier = "sourceIdentifier"
let layerIdentifier = "layerIdentifier"

class ViewController: UIViewController, MGLMapViewDelegate, AVSpeechSynthesizerDelegate {
    
    var destination: MGLPointAnnotation?
    var navigation: RouteController?
    var routeViewController: RouteViewController?
    lazy var speechSynth = AVSpeechSynthesizer()
    var userRoute: Route?
    
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var toggleNavigationButton: UIButton!
    @IBOutlet weak var howToBeginLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        mapView.userTrackingMode = .follow
        resumeNotifications()
    }
    
    deinit {
        suspendNotifications()
        navigation?.suspend()
    }
    
    @IBAction func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        
        if let destination = destination {
            mapView.removeAnnotation(destination)
        }
        
        destination = MGLPointAnnotation()
        destination?.coordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
        mapView.addAnnotation(destination!)
        
        getRoute()
    }
    
    @IBAction func didToggleNavigation(_ sender: Any) {
        startNavigation(userRoute!)
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
    
    // Notification sent when the alert level changes. This signals the user is ready for a new voice announcement.
    func alertLevelDidChange(_ notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
        let alertLevel = routeProgress.currentLegProgress.alertUserLevel
        var text: String
        
        let distance = roundToTens(routeProgress.currentLegProgress.currentStepProgress.distanceRemaining)
        if let upComingStep = routeProgress.currentLegProgress.upComingStep {
            // Don't give full instruction with distance if the alert type is high
            if alertLevel == .high {
                text = upComingStep.instructions
            } else {
                text = "In \(distance) meters \(upComingStep.instructions)"
            }
        } else {
            text = "In \(distance) meters \(routeProgress.currentLegProgress.currentStep.instructions)"
        }
        
        let utterance = AVSpeechUtterance(string: text)
        speechSynth.delegate = self
        speechSynth.speak(utterance)
    }
    
    // Notifications sent on all location updates
    func progressDidChange(_ notification: NSNotification) {
        // If you are not using MapboxNavigationUI,
        // this would be a good time to update UI elements.
        // You can grab the current routeProgress like:
        // let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
    }
    
    // Notification sent when the user is determined to be off the current route
    func rerouted(_ notification: NSNotification) {
        
        // Interrupt the current instruction
        speechSynth.stopSpeaking(at: .word)
        
        //
        // If you're not using MapboxNavigationUI,
        // this is how you'd handle fetching a new route and setting it as the active route
        /*
         getRoute {
         /*
         **IMPORTANT**
         
         When rerouting, you need to give the RouteController a new route.
         Otherwise, it will continue to compare the user to the old route and continually reroute the user.
         */
         self.navigation?.routeProgress = RouteProgress(route: self.userRoute!)
         }
         */
    }
    
    func getRoute(didFinish: (()->())? = nil) {
        guard let destination = destination else { return }
        
        let options = RouteOptions(coordinates: [mapView.userLocation!.coordinate, destination.coordinate])
        options.includesSteps = true
        options.routeShapeResolution = .full
        options.profileIdentifier = .automobileAvoidingTraffic
        
        _ = Directions.shared.calculate(options) { [weak self] (waypoints, routes, error) in
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
            
            self?.removeRoutesFromMap()
            
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
        // Pass through a
        // 1. the route the user will take
        // 2. A `Directions` class, used for rerouting.
        let viewController = NavigationUI.routeViewController(for: route)
        present(viewController, animated: true, completion: nil)
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
    }
    
    func roundToTens(_ x: CLLocationDistance) -> Int {
        return 10 * Int(round(x / 10.0))
    }
}

