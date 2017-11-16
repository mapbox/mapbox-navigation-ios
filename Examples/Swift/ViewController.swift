import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import Mapbox

let sourceIdentifier = "sourceIdentifier"
let layerIdentifier = "layerIdentifier"
private typealias RouteRequestSuccess = (([Route]) -> Void)
private typealias RouteRequestFailure = ((NSError) -> Void)

enum ExampleMode {
    case `default`
    case custom
    case styled
    case multipleWaypoints
}

class ViewController: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate {
    
    //MARK: - IBOutlets
    @IBOutlet weak var mapView: NavigationMapView!
    @IBOutlet weak var longPressHintView: UIView!
    
    @IBOutlet weak var simulationButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    
    @IBOutlet weak var clearMap: UIButton!
    
    //MARK: Properties
    var waypoints: [Waypoint] = []
    var currentRoute: Route? {
        get {
            return routes?.first
        }
        set {
            guard let selected = newValue else { routes?.remove(at: 0); return }
            guard let routes = routes else { self.routes = [selected]; return }
            self.routes = [selected] + routes.filter { $0 != selected }
        }
    }
    
    var routes: [Route]? {
        didSet {
            startButton.isEnabled = (routes?.count ?? 0 > 0)
            guard let routes = routes,
                  let current = routes.first else { mapView?.removeRoutes(); return }
            
            mapView.showRoutes(routes)
            mapView.showWaypoints(current)
        }
    }
    
    // MARK: Directions Request Handlers
    
    fileprivate lazy var defaultSuccess: RouteRequestSuccess = { [weak self] (routes) in
        guard let current = routes.first else { return }
        self?.mapView.removeWaypoints()
        self?.routes = routes
        self?.waypoints = current.routeOptions.waypoints
    }
    
    fileprivate lazy var defaultFailure: RouteRequestFailure = { [weak self] (error) in
        self?.routes = nil //clear routes from the map
        print(error.localizedDescription)
    }
    

    var exampleMode: ExampleMode?
    
    var locationManager = CLLocationManager()
    
    var alertController: UIAlertController!
    
    lazy var multipleStopsAction: UIAlertAction = {
        return UIAlertAction(title: "Multiple Stops", style: .default, handler: { (action) in
            self.startMultipleWaypoints()
        })
    }()
    
    //MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        automaticallyAdjustsScrollViewInsets = false
        mapView.delegate = self
        mapView.navigationMapDelegate = self

        mapView.userTrackingMode = .follow

        simulationButton.isSelected = true
        startButton.isEnabled = false
        
        alertController = UIAlertController(title: "Start Navigation", message: "Select the navigation type", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Default UI", style: .default, handler: { (action) in
            self.startBasicNavigation()
        }))
        alertController.addAction(UIAlertAction(title: "Custom UI", style: .default, handler: { (action) in
            self.startCustomNavigation()
        }))
        alertController.addAction(UIAlertAction(title: "Styled UI", style: .default, handler: { (action) in
            self.startStyledNavigation()
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.startButton
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Reset the navigation styling to the defaults
        DayStyle().apply()
    }
    
    //MARK: Gesture Recognizer Handlers
    
    @IBAction func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        
        clearMap.isHidden = false
        longPressHintView.isHidden = true

        if let annotation = mapView.annotations?.last, waypoints.count > 2 {
            mapView.removeAnnotation(annotation)
        }
        
        if waypoints.count > 1 {
            waypoints = Array(waypoints.suffix(1))
            multipleStopsAction.isEnabled = true
        } else { //single waypoint
            multipleStopsAction.isEnabled = false
        }
        
        let coordinates = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
        let waypoint = Waypoint(coordinate: coordinates)
        waypoint.coordinateAccuracy = -1
        waypoints.append(waypoint)
        
        if waypoints.count >= 2, !alertController.actions.contains(multipleStopsAction) {
            alertController.addAction(multipleStopsAction)
        }
        
        requestRoute()
    }
    
    //MARK: - IBActions
    @IBAction func replay(_ sender: Any) {
        let bundle = Bundle(for: ViewController.self)
        let filePath = bundle.path(forResource: "tunnel", ofType: "json")!
        let routeFilePath = bundle.path(forResource: "tunnel", ofType: "route")!
        let route = NSKeyedUnarchiver.unarchiveObject(withFile: routeFilePath) as! Route
        
        let locationManager = ReplayLocationManager(locations: Array<CLLocation>.locations(from: filePath))
        
        let navigationViewController = NavigationViewController(for: route, locationManager: locationManager)
        
        present(navigationViewController, animated: true, completion: nil)
    }
    
    @IBAction func simulateButtonPressed(_ sender: Any) {
        simulationButton.isSelected = !simulationButton.isSelected
    }
    
    @IBAction func clearMapPressed(_ sender: Any) {
        clearMap.isHidden = true
        mapView.removeRoutes()
        mapView.removeWaypoints()
        waypoints.removeAll()
        multipleStopsAction.isEnabled = false
    }
    
    @IBAction func startButtonPressed(_ sender: Any) {
        present(alertController, animated: true, completion: nil)
    }
    

    //MARK: - Public Methods
    //MARK: Route Requests
    func requestRoute() {
        guard waypoints.count > 0 else { return }
        
        let userWaypoint = Waypoint(location: mapView.userLocation!.location!, heading: mapView.userLocation?.heading, name: "user")
        waypoints.insert(userWaypoint, at: 0)
        
        let options = NavigationRouteOptions(waypoints: waypoints)
        
        requestRoute(with: options, success: defaultSuccess, failure: defaultFailure)
    }
    
    fileprivate func requestRoute(with options: RouteOptions, success: @escaping RouteRequestSuccess, failure: RouteRequestFailure?) {
        
        let handler: Directions.CompletionHandler = {(waypoints, potentialRoutes, potentialError) in
            if let error = potentialError, let fail = failure { return fail(error) }
            guard let routes = potentialRoutes else { return }
            return success(routes)
        }
        
        _ = Directions.shared.calculate(options, completionHandler: handler)
    }

    // MARK: Basic Navigation

    func startBasicNavigation() {
        guard let route = currentRoute else { return }
        
        exampleMode = .default
        
        let navigationViewController = NavigationViewController(for: route, locationManager: navigationLocationManager())
        navigationViewController.recordsAudioFeedback = true
        navigationViewController.delegate = self
        
        present(navigationViewController, animated: true, completion: nil)
    }

    // MARK: Custom Navigation UI

    func startCustomNavigation() {
        guard let route = self.currentRoute else { return }

        guard let customViewController = storyboard?.instantiateViewController(withIdentifier: "custom") as? CustomViewController else { return }
        
        exampleMode = .custom

        customViewController.simulateLocation = simulationButton.isSelected
        customViewController.userRoute = route
        
        let destination = MGLPointAnnotation()
        destination.coordinate = route.coordinates!.last!
        customViewController.destination = destination
        
        present(customViewController, animated: true, completion: nil)
    }

    // MARK: Styling the default UI
    
    func startStyledNavigation() {
        guard let route = self.currentRoute else { return }

        exampleMode = .styled
        
        let styles = [DayStyle(), CustomNightStyle()]

        let navigationViewController = NavigationViewController(for: route, styles: styles, locationManager: navigationLocationManager())
        navigationViewController.delegate = self

        present(navigationViewController, animated: true, completion: nil)
    }
    
    func navigationLocationManager() -> NavigationLocationManager {
        guard let route = currentRoute else { return NavigationLocationManager() }
        return simulationButton.isSelected ? SimulatedLocationManager(route: route) : NavigationLocationManager()
    }
    
    // MARK: Navigation with multiple waypoints

    func startMultipleWaypoints() {
        guard let route = self.currentRoute else { return }

        exampleMode = .multipleWaypoints


        let navigationViewController = NavigationViewController(for: route, locationManager: navigationLocationManager())
        navigationViewController.delegate = self

        present(navigationViewController, animated: true, completion: nil)
    }
}

//MARK: - NavigationMapViewDelegate
extension ViewController: NavigationMapViewDelegate {
    func navigationMapView(_ mapView: NavigationMapView, didSelect waypoint: Waypoint) {
        guard let routeOptions = currentRoute?.routeOptions else { return }
        let modifiedOptions = routeOptions.without(waypoint: waypoint)
        
        let destroyWaypoint: (UIAlertAction) -> Void = {_ in self.requestRoute(with:modifiedOptions, success: self.defaultSuccess, failure: self.defaultFailure) }
        
        presentWaypointRemovalActionSheet(callback: destroyWaypoint)
    }
    
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        currentRoute = route
    }
    
    private func presentWaypointRemovalActionSheet(callback approve: @escaping ((UIAlertAction) -> Void)) {
        let title = NSLocalizedString("Remove Waypoint?", comment: "Waypoint Removal Action Sheet Title")
        let message = NSLocalizedString("Would you like to remove this waypoint?", comment: "Waypoint Removal Action Sheet Message")
        let removeTitle = NSLocalizedString("Remove Waypoint", comment: "Waypoint Removal Action Item Title")
        let cancelTitle = NSLocalizedString("Cancel", comment: "Waypoint Removal Action Sheet Cancel Item Title")
        
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let remove = UIAlertAction(title: removeTitle, style: .destructive, handler: approve)
        let cancel = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        [remove, cancel].forEach(actionSheet.addAction(_:))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
}

//MARK: WaypointConfirmationViewControllerDelegate
extension ViewController: WaypointConfirmationViewControllerDelegate {
    func confirmationControllerDidConfirm(_ confirmationController: WaypointConfirmationViewController) {
        confirmationController.dismiss(animated: true, completion: {
            guard let navigationViewController = self.presentedViewController as? NavigationViewController else { return }
            
            guard navigationViewController.routeController.routeProgress.route.legs.count > navigationViewController.routeController.routeProgress.legIndex + 1 else { return }
            navigationViewController.routeController.routeProgress.legIndex += 1
        })
    }
}

//MARK: NavigationViewControllerDelegate
extension ViewController: NavigationViewControllerDelegate {
    // By default, when the user arrives at a waypoint, the next leg starts immediately.
    // If however you would like to pause and allow the user to provide input, set this delegate method to false.
    // This does however require you to increment the leg count on your own. See the example below in `confirmationControllerDidConfirm()`.
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldIncrementLegWhenArrivingAtWaypoint waypoint: Waypoint) -> Bool {
        return false
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) {
        // Multiple waypoint demo
        guard exampleMode == .multipleWaypoints else { return }

        // When the user arrives, present a view controller that prompts the user to continue to their next destination
        // This typ of screen could show information about a destination, pickup/dropoff confirmation, instructions upon arrival, etc.
        guard let confirmationController = self.storyboard?.instantiateViewController(withIdentifier: "waypointConfirmation") as? WaypointConfirmationViewController else { return }
        
        confirmationController.delegate = self
        
        navigationViewController.present(confirmationController, animated: true, completion: nil)
    }
}

//MARK: CustomNightStyle
class CustomNightStyle: DayStyle {
    
    required init() {
        super.init()
        mapStyleURL = URL(string: "mapbox://styles/mapbox/satellite-streets-v9")!
        styleType = .nightStyle
    }
    
    override func apply() {
        super.apply()
        ManeuverView.appearance().backgroundColor = #colorLiteral(red: 0.2974345386, green: 0.4338284135, blue: 0.9865127206, alpha: 1)
        BottomBannerView.appearance().backgroundColor = #colorLiteral(red: 0.2974345386, green: 0.4338284135, blue: 0.9865127206, alpha: 1)
        
        DistanceLabel.appearance().textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        TimeRemainingLabel.appearance().textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        ArrivalTimeLabel.appearance().textColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    }
}
