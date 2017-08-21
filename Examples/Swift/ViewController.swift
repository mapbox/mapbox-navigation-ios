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
    
    var waypoints: [Waypoint] = []
    var currentRoute: Route? {
        didSet {
            self.startButton.isEnabled = currentRoute != nil
        }
    }
    
    @IBOutlet weak var mapView: NavigationMapView!
    @IBOutlet weak var longPressHintView: UIView!

    @IBOutlet weak var simulationButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    
    @IBOutlet weak var clearMap: UIButton!

    var exampleMode: ExampleMode?
    
    // In this example, we show you how you can create custom UIView that is used to show the user's location.
    // Set `showCustomUserPuck` to true to view the custom user puck.
    var showCustomUserPuck = false
    
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
        
        clearMap.isHidden = false
        longPressHintView.isHidden = true

        if let annotation = mapView.annotations?.last, waypoints.count > 2 {
            mapView.removeAnnotation(annotation)
        }
        
        if waypoints.count > 1 {
            waypoints = Array(waypoints.suffix(1))
        }
        
        let coordinates = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
        let waypoint = Waypoint(coordinate: coordinates)
        waypoint.coordinateAccuracy = -1
        waypoints.append(waypoint)
        
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
    
    @IBAction func clearMapPressed(_ sender: Any) {
        clearMap.isHidden = true
        mapView.removeRoute()
        mapView.removeWaypoints()
        waypoints.removeAll()
    }
    
    @IBAction func startButtonPressed(_ sender: Any) {
        DispatchQueue.main.async {
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
            
            if self.waypoints.count > 2 {
                alertController.addAction(UIAlertAction(title: "Multiple Stops", style: .default, handler: { (action) in
                    self.startMultipleWaypoints()
                }))
            }
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            if let popoverController = alertController.popoverPresentationController {
                popoverController.sourceView = self.startButton
            }
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // Helper for requesting a route
    func requestRoute() {
        guard waypoints.count > 0 else { return }
        
        let userWaypoint = Waypoint(location: mapView.userLocation!.location!, heading: mapView.userLocation?.heading, name: "user")
        userWaypoint.coordinateAccuracy = -1
        waypoints.insert(userWaypoint, at: 0)
        
        let options = RouteOptions(forNavigationWithWaypoints: waypoints)
        
        _ = Directions.shared.calculate(options) { [weak self] (waypoints, routes, error) in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            guard let route = routes?.first else { return }
            
            self?.currentRoute = route
            
            // Open method for adding and updating the route line
            self?.mapView.showRoute(route)
            self?.mapView.showWaypoints(route, legIndex: 0)
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
        
        present(customViewController, animated: true, completion: nil)
    }

    // MARK: - Styling the default UI
    
    func startStyledNavigation() {
        guard let route = self.currentRoute else { return }

        exampleMode = .styled
        
        let style = DefaultStyle()
        
        // General styling
        style.tintColor = #colorLiteral(red: 0.9418798089, green: 0.3469682932, blue: 0.5911870599, alpha: 1)
        style.statusBarStyle = .lightContent
        style.buttonTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        style.fontFamily = "Georgia"
        style.turnArrowPrimaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        style.turnArrowSecondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
        style.floatingButtonBackgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        style.lanesViewBackgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        style.laneViewPrimaryColor = #colorLiteral(red: 0.9418798089, green: 0.3469682932, blue: 0.5911870599, alpha: 1)
        style.laneViewSecondaryColor = #colorLiteral(red: 0.2974345386, green: 0.4338284135, blue: 0.9865127206, alpha: 1)
        
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

        let navigationViewController = NavigationViewController(for: route, locationManager: locationManager())
        navigationViewController.navigationDelegate = self

        present(navigationViewController, animated: true, completion: nil)
    }
    
    // By default, when the user arrives at a waypoint, the next leg starts immediately.
    // If however you would like to pause and allow the user to provide input, set this delegate method to false.
    // This does however require you to increment the leg count on your own. See the example below in `confirmationControllerDidConfirm()`.
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldIncrementLegWhenArrivingAtWaypoint waypoint: Waypoint) -> Bool {
        return false
    }
}

extension ViewController: WaypointConfirmationViewControllerDelegate {
    func confirmationControllerDidConfirm(_ confirmationController: WaypointConfirmationViewController) {
        confirmationController.dismiss(animated: true, completion: {
            guard let navigationViewController = self.presentedViewController as? NavigationViewController else { return }
            
            guard navigationViewController.routeController.routeProgress.route.legs.count > navigationViewController.routeController.routeProgress.legIndex + 1 else { return }
            navigationViewController.routeController.routeProgress.legIndex += 1
        })
    }
}

extension ViewController: NavigationViewControllerDelegate {
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) {
        // Multiple waypoint demo
        guard exampleMode == .multipleWaypoints else { return }

        // When the user arrives, present a view controller that prompts the user to continue to their next destination
        // This typ of screen could show information about a destination, pickup/dropoff confirmation, instructions upon arrival, etc.
        guard let confirmationController = self.storyboard?.instantiateViewController(withIdentifier: "waypointConfirmation") as? WaypointConfirmationViewController else { return }
        
        confirmationController.delegate = self
        
        navigationViewController.present(confirmationController, animated: true, completion: nil)
    }

    func navigationMapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        guard annotation is MGLUserLocation && showCustomUserPuck else { return nil }
        
        let reuseIdentifier = "userPuck"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        
        if annotationView == nil {
            annotationView = CustomAnnotationView(reuseIdentifier: reuseIdentifier)
            annotationView!.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            annotationView!.backgroundColor = .red
        }
        
        return annotationView
    }
}

class CustomAnnotationView: MGLUserLocationAnnotationView {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Force the annotation view to maintain a constant size when the map is tilted.
        scalesWithViewingDistance = false
        
        // Use CALayer’s corner radius to turn this view into a circle.
        layer.cornerRadius = frame.width / 2
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.cgColor
    }
}
