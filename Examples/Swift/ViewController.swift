import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import Mapbox
import CoreLocation

let sourceIdentifier = "sourceIdentifier"
let layerIdentifier = "layerIdentifier"

class ViewController: UIViewController, MGLMapViewDelegate {
    
    var destination: MGLPointAnnotation?
    var navigation: RouteController?
    var navigationViewController: NavigationViewController?
    var userRoute: Route?
    
    @IBOutlet weak var mapView: NavigationMapView!
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
        navigation?.suspendLocationUpdates()
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
        NotificationCenter.default.addObserver(self, selector: #selector(alertLevelDidChange(_ :)), name: RouteControllerAlertLevelDidChange, object: navigation)
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_ :)), name: RouteControllerProgressDidChange, object: navigation)
        NotificationCenter.default.addObserver(self, selector: #selector(rerouted(_:)), name: RouteControllerShouldReroute, object: navigation)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: RouteControllerAlertLevelDidChange, object: navigation)
        NotificationCenter.default.removeObserver(self, name: RouteControllerProgressDidChange, object: navigation)
        NotificationCenter.default.removeObserver(self, name: RouteControllerShouldReroute, object: navigation)
    }
    
    // Notification sent when the alert level changes.
    func alertLevelDidChange(_ notification: NSNotification) {
        // Good place to give alerts about maneuver. These announcements are handled by `RouteVoiceController`
    }
    
    // Notifications sent on all location updates
    func progressDidChange(_ notification: NSNotification) {
        // If you are using MapboxCoreNavigation,
        // this would be a good time to update UI elements.
        // You can grab the current routeProgress like:
        // let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
    }
    
    // Notification sent when the user is determined to be off the current route
    func rerouted(_ notification: NSNotification) {
        //
        // If you're using MapboxNavigation,
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
        let viewController = NavigationViewController(for: route)
        
        // If you'd like to use AWS Polly, provide your IdentityPoolId below
        // `identityPoolId` is a required value for using AWS Polly voice instead of iOS's built in AVSpeechSynthesizer
        // You can get a token here: http://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth-aws-identity-for-ios.html
        // viewController.voiceController?.identityPoolId = "<#Your AWS IdentityPoolId. Remove Argument if you do not want to use AWS Polly#>"
        
        viewController.routeController.snapsUserLocationAnnotationToRoute = true
        viewController.voiceController?.volume = 0.5
        
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
