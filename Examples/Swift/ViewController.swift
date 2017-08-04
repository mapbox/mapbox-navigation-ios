import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import Mapbox

let sourceIdentifier = "sourceIdentifier"
let layerIdentifier = "layerIdentifier"

enum ExampleMode {
    case `default`
    case custom
    case styled
    case multipleWaypoints
}

class ViewController: UIViewController, MGLMapViewDelegate {
    
    var destination: MGLPointAnnotation?
    var currentRoute: Route? {
        didSet {
            self.startButton.isEnabled = currentRoute != nil
        }
    }
    
    @IBOutlet weak var mapView: NavigationMapView!
    @IBOutlet weak var longPressHintView: UIView!

    @IBOutlet weak var simulationButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    
    var exampleMode: ExampleMode?
    var nextWaypoint: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        mapView.delegate = self
        
        mapView.userTrackingMode = .follow

        simulationButton.isSelected = true
        startButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Reset the navigation styling to the defaults
        DefaultStyle().apply()
    }
    
    @IBAction func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else {
            return
        }
        
        if let destination = destination {
            mapView.removeAnnotation(destination)
        }
        
        longPressHintView.isHidden = true
        
        destination = MGLPointAnnotation()
        destination?.coordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
        mapView.addAnnotation(destination!)
        
        requestRoute()
    }
    
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
    
    @IBAction func startButtonPressed(_ sender: Any) {
        let alertController = UIAlertController(title: "Start Navigation", message: "Select the navigation type", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Default UI", style: .default, handler: { (action) in
            self.startBasicNavigation()
        }))
        alertController.addAction(UIAlertAction(title: "Custom UI", style: .default, handler: { (action) in
            self.startCustomNavigation()
        }))
        alertController.addAction(UIAlertAction(title: "Styled UI", style: .default, handler: { (action) in
            self.startStyledNavigation()
        }))
        alertController.addAction(UIAlertAction(title: "Multiple Stops", style: .default, handler: { (action) in
            self.startMultipleWaypoints()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    // Helper for requesting a route
    func requestRoute() {
        guard let destination = destination else { return }
        
        let options = RouteOptions(coordinates: [
            mapView.userLocation!.coordinate,
            destination.coordinate,
        ])
        options.includesSteps = true
        options.routeShapeResolution = .full
        options.profileIdentifier = .automobileAvoidingTraffic
        
        // Adding the optional attribute `.congestionLevel` ensures the route line will show the congestion along the route line
        options.attributeOptions = [.congestionLevel]
        
        _ = Directions.shared.calculate(options) { [weak self] (waypoints, routes, error) in
            guard error == nil else {
                print(error!)
                return
            }
            guard let route = routes?.first else { return }
            
            self?.currentRoute = route
            
            // Open method for adding and updating the route line
            self?.mapView.showRoute(route)
        }
    }
    
    // MARK: - Basic Navigation
    
    func startBasicNavigation() {
        guard let route = currentRoute else { return }
            
        exampleMode = .default
        
        let navigationViewController = NavigationViewController(for: route, locationManager: locationManager())
        navigationViewController.showsReportFeedback = true
        navigationViewController.navigationDelegate = self
        
        present(navigationViewController, animated: true, completion: nil)
    }

    // MARK: - Custom Navigation UI

    func startCustomNavigation() {
        guard let route = self.currentRoute else { return }

        guard let customViewController = storyboard?.instantiateViewController(withIdentifier: "custom") as? CustomViewController else { return }
            
        exampleMode = .custom

        customViewController.simulateLocation = simulationButton.isSelected
        customViewController.userRoute = route
        customViewController.destination = destination
            
        present(customViewController, animated: true, completion: nil)
    }
    
    // MARK: - Styling the default UI

    func startStyledNavigation() {
        guard let route = self.currentRoute else { return }

        exampleMode = .styled
        
        let style = DefaultStyle()
        
        // General styling
        style.tintColor = #colorLiteral(red: 0.9418798089, green: 0.3469682932, blue: 0.5911870599, alpha: 1)
        style.buttonTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        style.fontFamily = "Georgia"
        style.turnArrowPrimaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        style.turnArrowSecondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
        
        // Maneuver view (Page view)
        style.maneuverViewBackgroundColor = #colorLiteral(red: 0.2974345386, green: 0.4338284135, blue: 0.9865127206, alpha: 1)
        style.distanceLabelTextColor = #colorLiteral(red: 0.9293526786, green: 0.9291852679, blue: 0.9280691964, alpha: 1)
        style.destinationLabelTextColor = #colorLiteral(red: 0.9293526786, green: 0.9291852679, blue: 0.9280691964, alpha: 1)
        style.distanceRemainingLabelTextColor = #colorLiteral(red: 0.9293526786, green: 0.9291852679, blue: 0.9280691964, alpha: 1)
        style.timeRemainingLabelTextColor = #colorLiteral(red: 0.9293526786, green: 0.9291852679, blue: 0.9280691964, alpha: 1)
        style.arrivalTimeLabelTextColor = #colorLiteral(red: 0.9293526786, green: 0.9291852679, blue: 0.9280691964, alpha: 1)

        // Current street name label
        style.wayNameLabelTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        style.wayNameViewBackgroundColor = #colorLiteral(red: 0.2974345386, green: 0.4338284135, blue: 0.9865127206, alpha: 1).withAlphaComponent(0.5)
            
        // Table view (Drawer)
        style.headerBackgroundColor = #colorLiteral(red: 0.2974345386, green: 0.4338284135, blue: 0.9865127206, alpha: 1)
        style.cellTitleLabelTextColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        style.cellSubtitleLabelTextColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        
        // Traffic
        style.routeCasingColor = #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1)
        style.trafficUnknownColor = #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1)
        style.trafficLowColor = #colorLiteral(red: 0.5843137503, green: 0.8235294223, blue: 0.4196078479, alpha: 1)
        style.trafficModerateColor = #colorLiteral(red: 0.8549019694, green: 0.250980407, blue: 0.4784313738, alpha: 1)
        style.trafficHeavyColor = #colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1)
        style.trafficSevereColor = #colorLiteral(red: 0.5725490451, green: 0, blue: 0.2313725501, alpha: 1)
        
        let navigationViewController = NavigationViewController(for: route, styles: [style], locationManager: locationManager())
        navigationViewController.navigationDelegate = self
        
        // Set a custom style URL
        navigationViewController.mapView?.styleURL = URL(string: "mapbox://styles/mapbox/navigation-guidance-day-v2")
        
        present(navigationViewController, animated: true, completion: nil)
    }
    
    func locationManager() -> NavigationLocationManager {
        guard let route = currentRoute else { return NavigationLocationManager() }
        return simulationButton.isSelected ? SimulatedLocationManager(route: route) : NavigationLocationManager()
    }
    
    // MARK: - Navigation with multiple waypoints

    func startMultipleWaypoints() {
        guard let route = self.currentRoute else { return }

        exampleMode = .multipleWaypoints
        
        // When the user arrives at their destination, we'll prompt them to return back to where they started
        nextWaypoint = self.currentRoute?.coordinates?.first
        
        let navigationViewController = NavigationViewController(for: route, locationManager: locationManager())
        navigationViewController.navigationDelegate = self

        present(navigationViewController, animated: true, completion: nil)
    }
    
}

extension ViewController: NavigationViewControllerDelegate {
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt destination: MGLAnnotation) {
        
        // Multiple waypoint demo
        guard exampleMode == .multipleWaypoints, nextWaypoint != nil else { return }

        // When the user arrives, present a view controller that prompts the user to continue to their next destination
        // This typ of screen could show information about a destination, pickup/dropoff confirmation, instructions upon arrival, etc.
        guard let confirmationController = self.storyboard?.instantiateViewController(withIdentifier: "waypointConfirmation") as? WaypointConfirmationViewController else { return }
            
        confirmationController.delegate = self
        
        navigationViewController.present(confirmationController, animated: true, completion: nil)
    }
}

extension ViewController: WaypointConfirmationViewControllerDelegate {
    func confirmationControllerDidConfirm(controller confirmationController: WaypointConfirmationViewController) {
        guard let nextDestination = nextWaypoint else { return }
        guard let navigationViewController = self.presentedViewController as? NavigationViewController else { return }

        // Calculate directions to the next waypoint
        let options = RouteOptions(coordinates: [
            navigationViewController.mapView!.userLocation!.coordinate,
            nextDestination,
        ])
        options.includesSteps = true
        options.routeShapeResolution = .full
        options.profileIdentifier = navigationViewController.route.routeOptions.profileIdentifier
        
        // Adding the optional attribute `.congestionLevel` ensures the route line will show the congestion along the route line
        options.attributeOptions = [.congestionLevel]

        _ = Directions.shared.calculate(options) { [weak self] (waypoints, routes, error) in
            guard error == nil else {
                print(error!)
                return
            }
            guard let route = routes?.first else { return }
            
            // update the navigationViewController with the route to the next waypoint
            navigationViewController.route = route
            
            // Set the next waypoint to our start point
            // We'll continue this waypoint loop until the user exits navigation
            self?.nextWaypoint = route.coordinates?.first
            
            // Dismiss the confirmation screen
            confirmationController.dismiss(animated: true, completion: nil)
        }
    }
}
