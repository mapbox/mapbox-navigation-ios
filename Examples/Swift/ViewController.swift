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

class ViewController: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate, VoiceControllerDelegate {

    // MARK: - Class Constants
    static let mapInsets = UIEdgeInsets(top: 25, left: 25, bottom: 25, right: 25)
    
    // MARK: - IBOutlets
    @IBOutlet weak var longPressHintView: UIView!

    @IBOutlet weak var simulationButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var bottomBar: UIView!
    
    @IBOutlet weak var clearMap: UIButton!

    // MARK: Properties
    var mapView: NavigationMapView?
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

            mapView?.showRoutes(routes)
            mapView?.showWaypoints(current)
        }
    }

    // MARK: Directions Request Handlers

    fileprivate lazy var defaultSuccess: RouteRequestSuccess = { [weak self] (routes) in
        guard let current = routes.first else { return }
        self?.mapView?.removeWaypoints()
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

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

        automaticallyAdjustsScrollViewInsets = false

        simulationButton.isSelected = true
        startButton.isEnabled = false
        
        alertController = UIAlertController(title: "Start Navigation", message: "Select the navigation type", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Default UI", style: .default, handler: { (action) in
            self.startBasicNavigation()
        }))
        alertController.addAction(UIAlertAction(title: "DayStyle UI", style: .default, handler: { (action) in
            self.startNavigation(styles: [DayStyle()])
        }))
        alertController.addAction(UIAlertAction(title: "NightStyle UI", style: .default, handler: { (action) in
            self.startNavigation(styles: [NightStyle()])
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

        //Reload the mapView.
        setupMapView()

        // Reset the navigation styling to the defaults if we are returning from a presentation.
        if (presentedViewController != nil) {
            DayStyle().apply()
        }
        
    }

    // MARK: Gesture Recognizer Handlers

    @objc func didLongPress(tap: UILongPressGestureRecognizer) {
        guard tap.state == .began else {
            return
        }

        clearMap.isHidden = false
        longPressHintView.isHidden = true
        
        guard let mapView = mapView else { return }

        if let annotation = mapView.annotations?.last, waypoints.count > 2 {
            mapView.removeAnnotation(annotation)
        }

        if waypoints.count > 1 {
            waypoints = Array(waypoints.suffix(1))
            multipleStopsAction.isEnabled = true
        } else { //single waypoint
            multipleStopsAction.isEnabled = false
        }

        let coordinates = mapView.convert(tap.location(in: mapView), toCoordinateFrom: mapView)
        let waypoint = Waypoint(coordinate: coordinates)
        waypoint.coordinateAccuracy = -1
        waypoints.append(waypoint)

        if waypoints.count >= 2, !alertController.actions.contains(multipleStopsAction) {
            alertController.addAction(multipleStopsAction)
        }

        requestRoute()
    }

    // MARK: - IBActions
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
        mapView?.removeRoutes()
        mapView?.removeWaypoints()
        waypoints.removeAll()
        multipleStopsAction.isEnabled = false
    }

    @IBAction func startButtonPressed(_ sender: Any) {
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Public Methods
    // MARK: Route Requests
    func requestRoute() {
        guard waypoints.count > 0 else { return }
        guard let mapView = mapView else { return }

        let userWaypoint = Waypoint(location: mapView.userLocation!.location!, heading: mapView.userLocation?.heading, name: "user")
        waypoints.insert(userWaypoint, at: 0)

        let options = NavigationRouteOptions(waypoints: waypoints)

        requestRoute(with: options, success: defaultSuccess, failure: defaultFailure)
    }

    fileprivate func requestRoute(with options: RouteOptions, success: @escaping RouteRequestSuccess, failure: RouteRequestFailure?) {

        let handler: Directions.RouteCompletionHandler = {(waypoints, potentialRoutes, potentialError) in
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
        navigationViewController.delegate = self

        presentAndRemoveMapview(navigationViewController)
    }
    
    func startNavigation(styles: [Style]) {
        guard let route = currentRoute else { return }
        
        exampleMode = .default
        
        let navigationViewController = NavigationViewController(for: route, styles: styles, locationManager: navigationLocationManager())
        navigationViewController.delegate = self
        
        presentAndRemoveMapview(navigationViewController)
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

        let styles = [CustomDayStyle(), CustomNightStyle()]

        let navigationViewController = NavigationViewController(for: route, styles: styles, locationManager: navigationLocationManager())
        navigationViewController.delegate = self

        presentAndRemoveMapview(navigationViewController)
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

        presentAndRemoveMapview(navigationViewController)
    }
    
    func presentAndRemoveMapview(_ navigationViewController: NavigationViewController) {
        present(navigationViewController, animated: true) {
            self.mapView?.removeFromSuperview()
            self.mapView = nil
        }
    }
    
    func setupMapView() {
        guard self.mapView == nil else { return }
        let mapView = NavigationMapView(frame: view.bounds)
        self.mapView = mapView
        
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        mapView.navigationMapDelegate = self
        mapView.userTrackingMode = .follow
        let bottomPadding = (view.frame.height + view.frame.origin.y) - bottomBar.frame.origin.y
        
        var topPadding: CGFloat = 0.0
        if #available(iOS 11.0, *) {
            topPadding = view.safeAreaInsets.top
        } else if let navCon = navigationController {
            topPadding = navCon.navigationBar.frame.size.height
        }
        
        let subviewMask = UIEdgeInsets(top: topPadding, left: 0, bottom: bottomPadding, right: 0)
        mapView.contentInset = ViewController.mapInsets + subviewMask
        
        view.insertSubview(mapView, belowSubview: bottomBar)
        
        let singleTap = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(tap:)))
        mapView.gestureRecognizers?.filter({ $0 is UILongPressGestureRecognizer }).forEach(singleTap.require(toFail:))
        mapView.addGestureRecognizer(singleTap)
    
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        self.mapView?.localizeLabels()
        
        if let routes = routes, let coords = currentRoute?.coordinates, let coordCounts = currentRoute?.coordinateCount {
            mapView.setVisibleCoordinateBounds(MGLPolygon(coordinates: coords, count: coordCounts).overlayBounds, animated: false)
            self.mapView?.showRoutes(routes)
            self.mapView?.showWaypoints(currentRoute!)
        }
    }
}

// MARK: - NavigationMapViewDelegate
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

    // To use these delegate methods, set the `VoiceControllerDelegate` on your `VoiceController`.
    //
    // Called when there is an error with speaking a voice instruction.
    func voiceController(_ voiceController: RouteVoiceController, spokenInstructionsDidFailWith error: Error) {
        print(error.localizedDescription)
    }
    // Called when an instruction is interrupted by a new voice instruction.
    func voiceController(_ voiceController: RouteVoiceController, didInterrupt interruptedInstruction: SpokenInstruction, with interruptingInstruction: SpokenInstruction) {
        print(interruptedInstruction.text, interruptingInstruction.text)
    }
    
    func voiceController(_ voiceController: RouteVoiceController, willSpeak instruction: SpokenInstruction, routeProgress: RouteProgress) -> SpokenInstruction? {
        return SpokenInstruction(distanceAlongStep: instruction.distanceAlongStep, text: "New Instruction!", ssmlText: "<speak>New Instruction!</speak>")
    }
    
    // By default, the routeController will attempt to filter out bad locations.
    // If however you would like to filter these locations in,
    // you can conditionally return a Bool here according to your own heuristics.
    // See CLLocation.swift `isQualified` for what makes a location update unqualified.
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldDiscard location: CLLocation) -> Bool {
        return true
    }
}

// MARK: WaypointConfirmationViewControllerDelegate
extension ViewController: WaypointConfirmationViewControllerDelegate {
    func confirmationControllerDidConfirm(_ confirmationController: WaypointConfirmationViewController) {
        confirmationController.dismiss(animated: true, completion: {
            guard let navigationViewController = self.presentedViewController as? NavigationViewController else { return }

            guard navigationViewController.routeController.routeProgress.route.legs.count > navigationViewController.routeController.routeProgress.legIndex + 1 else { return }
            navigationViewController.routeController.routeProgress.legIndex += 1
        })
    }
}

// MARK: NavigationViewControllerDelegate
extension ViewController: NavigationViewControllerDelegate {
    // By default, when the user arrives at a waypoint, the next leg starts immediately.
    // If you implement this method, return true to preserve this behavior.
    // Return false to remain on the current leg, for example to allow the user to provide input.
    // If you return false, you must manually advance to the next leg. See the example above in `confirmationControllerDidConfirm(_:)`.
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        // Multiple waypoint demo
        guard exampleMode == .multipleWaypoints else { return true }

        // When the user arrives, present a view controller that prompts the user to continue to their next destination
        // This type of screen could show information about a destination, pickup/dropoff confirmation, instructions upon arrival, etc.
        guard let confirmationController = self.storyboard?.instantiateViewController(withIdentifier: "waypointConfirmation") as? WaypointConfirmationViewController else { return true }

        confirmationController.delegate = self

        navigationViewController.present(confirmationController, animated: true, completion: nil)
        return false
    }
    
    // Called when the user hits the exit button.
    // If implemented, you are responsible for also dismissing the UI.
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        navigationViewController.dismiss(animated: true, completion: nil)
    }
}

/**
 To find more pieces of the UI to customize, checkout DayStyle.swift.
 */
// MARK: CustomDayStyle
class CustomDayStyle: DayStyle {
    
    required init() {
        super.init()
        mapStyleURL = URL(string: "mapbox://styles/mapbox/satellite-streets-v9")!
        styleType = .day
    }
    
    override func apply() {
        super.apply()
        BottomBannerView.appearance().backgroundColor = .orange
    }
}

// MARK: CustomNightStyle
class CustomNightStyle: NightStyle {

    required init() {
        super.init()
        mapStyleURL = URL(string: "mapbox://styles/mapbox/satellite-streets-v9")!
        styleType = .night
    }

    override func apply() {
        super.apply()
        BottomBannerView.appearance().backgroundColor = .purple
    }
}
