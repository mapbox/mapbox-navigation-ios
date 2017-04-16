import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import Mapbox

let sourceIdentifier = "sourceIdentifier"
let layerIdentifier = "layerIdentifier"

class ViewController: UIViewController, MGLMapViewDelegate, NavigationViewControllerDelegate, NavigationMapViewDelegate {
    
    var destination: MGLPointAnnotation?
    var navigation: RouteController?
    var userRoute: Route?
    
    @IBOutlet weak var mapView: NavigationMapView!
    @IBOutlet weak var toggleNavigationButton: UIButton!
    @IBOutlet weak var howToBeginLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.navigationMapDelegate = self
        
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
            
            self?.userRoute = route
            self?.toggleNavigationButton.isHidden = false
            self?.howToBeginLabel.isHidden = true
            
            
            // Open method for adding and updating the route line
            self?.mapView.showRoute(route)
            
            didFinish?()
        }
    }
    
    func startNavigation(_ route: Route) {
        // Pass through a
        // 1. the route the user will take
        // 2. A `Directions` class, used for rerouting.
        let navigationViewController = NavigationViewController(for: route)
        
        // If you'd like to use AWS Polly, provide your IdentityPoolId below
        // `identityPoolId` is a required value for using AWS Polly voice instead of iOS's built in AVSpeechSynthesizer
        // You can get a token here: http://docs.aws.amazon.com/mobile/sdkforios/developerguide/cognito-auth-aws-identity-for-ios.html
        // viewController.voiceController?.identityPoolId = "<#Your AWS IdentityPoolId. Remove Argument if you do not want to use AWS Polly#>"
        
        navigationViewController.routeController.snapsUserLocationAnnotationToRoute = true
        navigationViewController.voiceController?.volume = 0.5
        navigationViewController.navigationDelegate = self
        navigationViewController.pendingCamera = mapView.camera
        
        present(navigationViewController, animated: true, completion: nil)
    }
    
    /// Delegate method for chaning the route line style
    func navigationMapView(_ mapView: NavigationMapView, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        let lineCasing = MGLLineStyleLayer(identifier: identifier, source: source)
        
        lineCasing.lineColor = MGLStyleValue(rawValue: UIColor(red:0.00, green:0.70, blue:0.99, alpha:1.0))
        lineCasing.lineWidth = MGLStyleValue(rawValue: 6)
        
        lineCasing.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        lineCasing.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        return lineCasing
    }
    
    /// Delegate method for chaning the route line casing style
    func navigationMapView(_ mapView: NavigationMapView, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        let line = MGLLineStyleLayer(identifier: identifier, source: source)
        
        line.lineColor = MGLStyleValue(rawValue: UIColor(red:0.18, green:0.49, blue:0.78, alpha:1.0))
        line.lineWidth = MGLStyleValue(rawValue: 8)
        
        line.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        line.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        return line
    }
}
