import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import UserNotifications


private typealias RouteRequestSuccess = (([Route]) -> Void)
private typealias RouteRequestFailure = ((NSError) -> Void)

class ViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var longPressHintView: UIView!
    @IBOutlet weak var simulationButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var clearMap: UIButton!
    @IBOutlet weak var bottomBarBackground: UIView!
    
    // MARK: Properties
    var mapView: NavigationMapView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let mapView = mapView {
                configureMapView(mapView)
                view.insertSubview(mapView, belowSubview: longPressHintView)
            }
        }
    }
    var waypoints: [Waypoint] = [] {
        didSet {
            waypoints.forEach {
                $0.coordinateAccuracy = -1
            }
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
    
    weak var activeNavigationViewController: NavigationViewController?

    // MARK: Directions Request Handlers

    fileprivate lazy var defaultSuccess: RouteRequestSuccess = { [weak self] (routes) in
        guard let current = routes.first else { return }
        self?.mapView?.removeWaypoints()
        self?.routes = routes
        self?.waypoints = current.routeOptions.waypoints
        self?.clearMap.isHidden = false
        self?.longPressHintView.isHidden = true
    }

    fileprivate lazy var defaultFailure: RouteRequestFailure = { [weak self] (error) in
        self?.routes = nil //clear routes from the map
        print(error.localizedDescription)
        self?.presentAlert(message: error.localizedDescription)
    }

    var alertController: UIAlertController!
    // MARK: - Init
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.currentAppRootViewController = self
        }
    }
    
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        alertController = UIAlertController(title: "Start Navigation", message: "Select the navigation type", preferredStyle: .actionSheet)
        
        typealias ActionHandler = (UIAlertAction) -> Void
        
        let basic: ActionHandler = {_ in self.startBasicNavigation() }
        let day: ActionHandler = {_ in self.startNavigation(styles: [DayStyle()]) }
        let night: ActionHandler = {_ in self.startNavigation(styles: [NightStyle()]) }
        let custom: ActionHandler = {_ in self.startCustomNavigation() }
        let styled: ActionHandler = {_ in self.startStyledNavigation() }
        
        let actionPayloads: [(String, UIAlertAction.Style, ActionHandler?)] = [
            ("Default UI", .default, basic),
            ("DayStyle UI", .default, day),
            ("NightStyle UI", .default, night),
            ("Custom UI", .default, custom),
            ("Styled UI", .default, styled),
            ("Cancel", .cancel, nil)
        ]
        
        actionPayloads
            .map { payload in UIAlertAction(title: payload.0, style: payload.1, handler: payload.2)}
            .forEach(alertController.addAction(_:))

        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.startButton
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "settings"), style: .plain, target: self, action: #selector(openSettings))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.mapView = NavigationMapView(frame: view.bounds)

        // Reset the navigation styling to the defaults if we are returning from a presentation.
        if (presentedViewController != nil) {
            DayStyle().apply()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { _,_ in
                DispatchQueue.main.async {
                    CLLocationManager().requestWhenInUseAuthorization()
                }
            }
        }
    }
    
    @IBAction func openSettings() {
        let controller = UINavigationController(rootViewController: SettingsViewController())
        present(controller, animated: true, completion: nil)
    }

    // MARK: Gesture Recognizer Handlers

    @objc func didLongPress(tap: UILongPressGestureRecognizer) {
        guard let mapView = mapView, tap.state == .began else { return }

        if let annotation = mapView.annotations?.last, waypoints.count > 2 {
            mapView.removeAnnotation(annotation)
        }

        if waypoints.count > 1 {
            waypoints = Array(waypoints.dropFirst())
        }
        
        let coordinates = mapView.convert(tap.location(in: mapView), toCoordinateFrom: mapView)
        // Note: The destination name can be modified. The value is used in the top banner when arriving at a destination.
        let waypoint = Waypoint(coordinate: coordinates, name: "Dropped Pin #\(waypoints.endIndex + 1)")
        waypoints.append(waypoint)

        requestRoute()
    }


    // MARK: - IBActions

    @IBAction func simulateButtonPressed(_ sender: Any) {
        simulationButton.isSelected = !simulationButton.isSelected
    }

    @IBAction func clearMapPressed(_ sender: Any) {
        clearMap.isHidden = true
        mapView?.removeRoutes()
        mapView?.removeWaypoints()
        waypoints.removeAll()
        longPressHintView.isHidden = false
    }

    @IBAction func startButtonPressed(_ sender: Any) {
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Public Methods
    // MARK: Route Requests
    func requestRoute() {
        guard waypoints.count > 0 else { return }
        guard let mapView = mapView else { return }

        let userWaypoint = Waypoint(location: mapView.userLocation!.location!, heading: mapView.userLocation?.heading, name: "User location")
        waypoints.insert(userWaypoint, at: 0)

        let options = NavigationRouteOptions(waypoints: waypoints)

        requestRoute(with: options, success: defaultSuccess, failure: defaultFailure)
    }

    fileprivate func requestRoute(with options: RouteOptions, success: @escaping RouteRequestSuccess, failure: RouteRequestFailure?) {

        let handler: Directions.RouteCompletionHandler = { (waypoints, routes, error) in
            if let error = error { failure?(error) }
            guard let routes = routes else { return }
            return success(routes)
        }

        // Calculate route offline if an offline version is selected
        let shouldUseOfflineRouting = Settings.selectedOfflineVersion != nil
        Settings.directions.calculate(options, offline: shouldUseOfflineRouting, completionHandler: handler)
    }

    // MARK: Basic Navigation

    func startBasicNavigation() {
        guard let route = routes?.first else { return }
        
        let service = navigationService(route: route)
        let navigationViewController = self.navigationViewController(navigationService: service)
        
        presentAndRemoveMapview(navigationViewController, completion: beginCarPlayNavigation)
    }
    
    func startNavigation(styles: [Style]) {
        guard let route = routes?.first else { return }
        
        let options = NavigationOptions(styles: styles, navigationService: navigationService(route: route))
        let navigationViewController = NavigationViewController(for: route, options: options)
        navigationViewController.delegate = self
        
        presentAndRemoveMapview(navigationViewController, completion: beginCarPlayNavigation)
    }
    
    func navigationViewController(navigationService: NavigationService) -> NavigationViewController {
        let route = navigationService.route
        let options = NavigationOptions( navigationService: navigationService)
        
        let navigationViewController = NavigationViewController(for: route, options: options)
        navigationViewController.delegate = self
        navigationViewController.mapView?.delegate = self
        return navigationViewController
    }
    
    public func beginNavigationWithCarplay(navigationService: NavigationService) {
        self.routes = [navigationService.route]
        
        let navigationViewController = activeNavigationViewController ?? self.navigationViewController(navigationService: navigationService)
        navigationViewController.isUsedInConjunctionWithCarPlayWindow = true
        
        guard activeNavigationViewController == nil else { return }
        
        presentAndRemoveMapview(navigationViewController, completion: nil)
    }
    
    // MARK: Custom Navigation UI
    func startCustomNavigation() {
        guard let route = routes?.first else { return }

        guard let customViewController = storyboard?.instantiateViewController(withIdentifier: "custom") as? CustomViewController else { return }

        customViewController.userRoute = route

        let destination = MGLPointAnnotation()
        destination.coordinate = route.coordinates!.last!
        customViewController.destination = destination
        customViewController.simulateLocation = simulationButton.isSelected

        present(customViewController, animated: true, completion: nil)
    }

    // MARK: Styling the default UI

    func startStyledNavigation() {
        guard let route = routes?.first else { return }

        let styles = [CustomDayStyle(), CustomNightStyle()]
        let options = NavigationOptions(styles:styles, navigationService: navigationService(route: route))
        let navigationViewController = NavigationViewController(for: route, options: options)
        navigationViewController.delegate = self

        presentAndRemoveMapview(navigationViewController, completion: beginCarPlayNavigation)
    }

    func navigationService(route: Route) -> NavigationService {
        let simulate = simulationButton.isSelected
        let mode: SimulationMode = simulate ? .always : .onPoorGPS
        return MapboxNavigationService(route: route, directions: Settings.directions, simulating: mode)
    }

    func presentAndRemoveMapview(_ navigationViewController: NavigationViewController, completion: CompletionHandler?) {
        activeNavigationViewController = navigationViewController
        
        present(navigationViewController, animated: true) { [weak self] in
            completion?()
            
            self?.mapView?.removeFromSuperview()
            self?.mapView = nil
        }
    }
    
    func beginCarPlayNavigation() {
        let delegate = UIApplication.shared.delegate as? AppDelegate
        
        if #available(iOS 12.0, *),
            let service = activeNavigationViewController?.navigationService,
            let location = service.router.location {
            delegate?.carPlayManager.beginNavigationWithCarPlay(using: location.coordinate,
                                                                navigationService: service)
        }
    }
    
    func endCarPlayNavigation(canceled: Bool) {
        if #available(iOS 12.0, *), let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.carPlayManager.currentNavigator?.exitNavigation(byCanceling: canceled)
        }
    }
    
    func dismissActiveNavigationViewController() {
        activeNavigationViewController?.dismiss(animated: true) {
            self.activeNavigationViewController = nil
        }
    }

    func configureMapView(_ mapView: NavigationMapView) {
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        mapView.navigationMapViewDelegate = self
        mapView.userTrackingMode = .follow
        mapView.logoView.isHidden = true

        let singleTap = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(tap:)))
        mapView.gestureRecognizers?.filter({ $0 is UILongPressGestureRecognizer }).forEach(singleTap.require(toFail:))
        mapView.addGestureRecognizer(singleTap)
    }
}

extension ViewController: MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        guard mapView == self.mapView else {
            return
        }
        
        self.mapView?.localizeLabels()
        
        if let routes = routes, let currentRoute = routes.first, let coords = currentRoute.coordinates {
            mapView.setVisibleCoordinateBounds(MGLPolygon(coordinates: coords, count: currentRoute.coordinateCount).overlayBounds, animated: false)
            self.mapView?.showRoutes(routes)
            self.mapView?.showWaypoints(currentRoute)
        }
    }
}

// MARK: - NavigationMapViewDelegate
extension ViewController: NavigationMapViewDelegate {
    func navigationMapView(_ mapView: NavigationMapView, didSelect waypoint: Waypoint) {
        guard let routeOptions = routes?.first?.routeOptions else { return }
        let modifiedOptions = routeOptions.without(waypoint: waypoint)

        presentWaypointRemovalActionSheet { _ in
            self.requestRoute(with:modifiedOptions, success: self.defaultSuccess, failure: self.defaultFailure)
        }
    }

    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        guard let routes = routes else { return }
        guard let index = routes.index(where: { $0 == route }) else { return }
        self.routes!.remove(at: index)
        self.routes!.insert(route, at: 0)
    }

    private func presentWaypointRemovalActionSheet(completionHandler approve: @escaping ((UIAlertAction) -> Void)) {
        let title = NSLocalizedString("REMOVE_WAYPOINT_CONFIRM_TITLE", value: "Remove Waypoint?", comment: "Title of sheet confirming waypoint removal")
        let message = NSLocalizedString("REMOVE_WAYPOINT_CONFIRM_MSG", value: "Do you want to remove this waypoint?", comment: "Message of sheet confirming waypoint removal")
        let removeTitle = NSLocalizedString("REMOVE_WAYPOINT_CONFIRM_REMOVE", value: "Remove Waypoint", comment: "Title of alert sheet action for removing a waypoint")
        let cancelTitle = NSLocalizedString("REMOVE_WAYPOINT_CONFIRM_CANCEL", value: "Cancel", comment: "Title of action for dismissing waypoint removal confirmation sheet")

        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let remove = UIAlertAction(title: removeTitle, style: .destructive, handler: approve)
        let cancel = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        [remove, cancel].forEach(actionSheet.addAction(_:))

        self.present(actionSheet, animated: true, completion: nil)
    }
}

// MARK: VoiceControllerDelegate methods
// To use these delegate methods, set the `VoiceControllerDelegate` on your `VoiceController`.
extension ViewController: VoiceControllerDelegate {
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
    
    // By default, the navigation service will attempt to filter out unqualified locations.
    // If however you would like to filter these locations in,
    // you can conditionally return a Bool here according to your own heuristics.
    // See CLLocation.swift `isQualified` for what makes a location update unqualified.
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldDiscard location: CLLocation) -> Bool {
        return true
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool {
        
        let shouldUseOfflineRouting = Settings.selectedOfflineVersion != nil
        
        guard shouldUseOfflineRouting == true else {
            return true
        }
        
        let currentRoute = navigationViewController.route
        let profileIdentifier = currentRoute.routeOptions.profileIdentifier
        
        var waypoints: [Waypoint] = [Waypoint(location: location)]
        var remainingWaypoints = currentRoute.routeOptions.waypoints
        remainingWaypoints.removeFirst()
        waypoints.append(contentsOf: remainingWaypoints)
        
        let options = NavigationRouteOptions(waypoints: waypoints, profileIdentifier: profileIdentifier)
        
        Settings.directions.calculate(options, offline: true) { (waypoints, routes, error) in
            guard let route = routes?.first else { return }
            navigationViewController.navigationService.route = route
        }
        
        return false
    }
}

// MARK: WaypointConfirmationViewControllerDelegate
extension ViewController: WaypointConfirmationViewControllerDelegate {
    func confirmationControllerDidConfirm(_ confirmationController: WaypointConfirmationViewController) {
        confirmationController.dismiss(animated: true, completion: {
            guard let navigationViewController = self.presentedViewController as? NavigationViewController,
                  let navService = navigationViewController.navigationService else { return }

            let router = navService.router!
            guard router.route.legs.count > router.routeProgress.legIndex + 1 else { return }
            
            router.routeProgress.legIndex += 1
            navService.start()
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
        // When the user arrives, present a view controller that prompts the user to continue to their next destination
        // This type of screen could show information about a destination, pickup/dropoff confirmation, instructions upon arrival, etc.
        
        //If we're not in a "Multiple Stops" demo, show the normal EORVC
        if navigationViewController.navigationService.router.routeProgress.isFinalLeg {
            endCarPlayNavigation(canceled: false)
            return true
        }
        
        guard let confirmationController = self.storyboard?.instantiateViewController(withIdentifier: "waypointConfirmation") as? WaypointConfirmationViewController else {
            return true
        }

        confirmationController.delegate = self

        navigationViewController.present(confirmationController, animated: true, completion: nil)
        return false
    }
    
    // Called when the user hits the exit button.
    // If implemented, you are responsible for also dismissing the UI.
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        endCarPlayNavigation(canceled: canceled)
        dismissActiveNavigationViewController()
    }
}


// Mark: VisualInstructionDelegate
extension ViewController: VisualInstructionDelegate {
    func label(_ label: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString? {
        
        // Uncomment to mutate the instruction shown in the top instruction banner
        // let range = NSRange(location: 0, length: presented.length)
        // let mutable = NSMutableAttributedString(attributedString: presented)
        // mutable.mutableString.applyTransform(.latinToKatakana, reverse: false, range: range, updatedRange: nil)
        // return mutable
        
        return presented
    }
}
