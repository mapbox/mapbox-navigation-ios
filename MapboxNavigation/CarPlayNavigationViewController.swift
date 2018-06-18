import Foundation
import MapboxDirections
import MapboxCoreNavigation
import CarPlay

public class CarPlayNavigationViewController: UIViewController, MGLMapViewDelegate {
    
    var route: Route
    
    var routeController: RouteController!
    
    var directions: Directions!
    
    var styleManager: StyleManager!
    
    var mapView: NavigationMapView?
    
//    let voiceController = MapboxVoiceController()
    
    var carSession: CPNavigationSession
    
    var carMaptemplate: CPMapTemplate
    
    var mapHasLoaded = false {
        didSet {
//            resumeNotifications()
        }
    }
    
    public init(for route: Route, session: CPNavigationSession, template: CPMapTemplate) {
        self.route = route
        self.carSession = session
        self.carMaptemplate = template
        super.init(nibName: nil, bundle: nil)
        
        createMapTemplateUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = NavigationMapView(frame: view.bounds)
        mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView?.delegate = self
        
        self.routeController = RouteController(along: route, directions: Directions.shared, locationManager: NavigationLocationManager())
        
        view.addSubview(mapView!)
        
        // Add listeners for progress updates
        resumeNotifications()
        
        // Start navigation
        routeController.resume()
        
        // Center map on user
        mapView?.recenterMap()
    }
    
    func createMapTemplateUI() {
        let overviewButton = CPMapButton { (button) in
            guard let userLocation = self.routeController.location?.coordinate else { return }
            self.mapView?.setOverheadCameraView(from: userLocation, along: self.routeController.routeProgress.route.coordinates!, for: UIEdgeInsets(floatLiteral: 0))
            button.isHidden = true
        }
        
        overviewButton.image = UIImage(named: "overview", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
        carMaptemplate.mapButtons = [overviewButton]
//        carMaptemplate.trailingNavigationBarButtons = []
//        carMaptemplate.leadingNavigationBarButtons = []
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_:)), name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rerouted(_:)), name: .routeControllerDidReroute, object: nil)
    }
    
    
    public func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        self.mapView?.showRoutes([routeController.routeProgress.route])
    }
    
    @objc func progressDidChange(_ notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as! RouteProgress
        let location = notification.userInfo![RouteControllerNotificationUserInfoKey.locationKey] as! CLLocation
        
        // Add maneuver arrow
        if routeProgress.currentLegProgress.followOnStep != nil {
            mapView?.addArrow(route: routeProgress.route, legIndex: routeProgress.legIndex, stepIndex: routeProgress.currentLegProgress.stepIndex + 1)
        } else {
            mapView?.removeArrow()
        }
        
        // Update the user puck
        mapView?.updateCourseTracking(location: location, animated: true)
    
        if let instruction = routeProgress.currentLegProgress.upComingStep?.instructions {
            let maneuver = CPManeuver()
            let distanceRemaining = Measurement(value: routeProgress.currentLegProgress.currentStepProgress.distanceRemaining, unit: UnitLength.nauticalMiles)
            let estimates = CPTravelEstimates(distanceRemaining: distanceRemaining, timeRemaining: routeProgress.currentLegProgress.currentStepProgress.durationRemaining)
            
            carSession.updateEstimates(estimates, for: maneuver)
        }
//        session.upcomingManeuvers = [maneuver]
    }
    
    @objc func rerouted(_ notification: NSNotification) {
        self.mapView?.showRoutes([routeController.routeProgress.route])
    }
}
