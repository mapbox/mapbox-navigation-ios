import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

private typealias RouteRequestSuccess = ((RouteResponse) -> Void)
private typealias RouteRequestFailure = ((Error) -> Void)

class ViewController: UIViewController {
    // MARK: - IBOutlets
    @IBOutlet weak var longPressHintView: UIView!
    @IBOutlet weak var simulationButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var bottomBar: UIView!
    @IBOutlet weak var clearMap: UIButton!
    @IBOutlet weak var bottomBarBackground: UIView!
    
    var trackPolyline: MGLPolyline?
    var rawTrackPolyline: MGLPolyline?
    let navigationDirections = NavigationDirections()
    
    // MARK: Properties
    var mapView: NavigationMapView? {
        didSet {
            if let mapView = oldValue {
                uninstall(mapView)
            }
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

    var response: RouteResponse? {
        didSet {
            guard let routes = response?.routes, let currentRoute = routes.first else {
                clearMapView()
                return
            }
            
            startButton.isEnabled = true
            mapView?.show(routes)
            mapView?.showWaypoints(on: currentRoute)
        }
    }
    
    weak var activeNavigationViewController: NavigationViewController?

    // MARK: Directions Request Handlers

    fileprivate lazy var defaultSuccess: RouteRequestSuccess = { [weak self] (response) in
        guard let routes = response.routes, !routes.isEmpty, case let .route(options) = response.options else { return }
        self?.mapView?.removeWaypoints()
        self?.response = response
        
        // Waypoints which were placed by the user are rewritten by slightly changed waypoints
        // which are returned in response with routes.
        if let waypoints = response.waypoints {
            self?.waypoints = waypoints
        }
        
        self?.clearMap.isHidden = false
        self?.longPressHintView.isHidden = true
    }

    fileprivate lazy var defaultFailure: RouteRequestFailure = { [weak self] (error) in
        self?.response = nil //clear routes from the map
        print(error.localizedDescription)
        self?.presentAlert(message: error.localizedDescription)
    }
    
    private var foundAllBuildings = false

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
    
    deinit {
        if let mapView = mapView {
            uninstall(mapView)
        }
    }
    
    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "settings"), style: .plain, target: self, action: #selector(openSettings))
        navigationItem.rightBarButtonItem?.isEnabled = true
        
        setupOfflineService()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if mapView == nil {
            mapView = NavigationMapView(frame: view.bounds)
        }
        
        // Reset the navigation styling to the defaults if we are returning from a presentation.
        if (presentedViewController != nil) {
            DayStyle().apply()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { _, _ in
            DispatchQueue.main.async {
                CLLocationManager().requestWhenInUseAuthorization()
            }
        }
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
        
        let destinationCoord = mapView.convert(tap.location(in: mapView), toCoordinateFrom: mapView)
        // Note: The destination name can be modified. The value is used in the top banner when arriving at a destination.
        let waypoint = Waypoint(coordinate: destinationCoord, name: "Dropped Pin #\(waypoints.endIndex + 1)")
        // Example of building highlighting. `targetCoordinate`, in this example, is used implicitly by NavigationViewController to determine which buildings to highlight.
        waypoint.targetCoordinate = destinationCoord
        waypoints.append(waypoint)
    
        // Example of highlighting buildings in 2d and directly using the API on NavigationMapView.
        let buildingHighlightCoordinates = waypoints.compactMap { $0.targetCoordinate }
        foundAllBuildings = mapView.highlightBuildings(at: buildingHighlightCoordinates, in3D: false)

        requestRoute()
    }

    // MARK: - IBActions

    @IBAction func simulateButtonPressed(_ sender: Any) {
        simulationButton.isSelected = !simulationButton.isSelected
    }

    @IBAction func clearMapPressed(_ sender: Any) {
        clearMapView()
    }

    @IBAction func startButtonPressed(_ sender: Any) {
        presentActionsAlertController()
    }
    
    @IBAction func openSettings() {
        let controller = UINavigationController(rootViewController: OfflineServiceViewController())
        present(controller, animated: true, completion: nil)
    }
    
    private func clearMapView() {
        startButton.isEnabled = false
        clearMap.isHidden = true
        longPressHintView.isHidden = false
        
        mapView?.unhighlightBuildings()
        mapView?.removeRoutes()
        mapView?.removeWaypoints()
        waypoints.removeAll()
    }
    
    private func presentActionsAlertController() {
        let alertController = UIAlertController(title: "Start Navigation", message: "Select the navigation type", preferredStyle: .actionSheet)
        
        typealias ActionHandler = (UIAlertAction) -> Void
        
        let basic: ActionHandler = { _ in self.startBasicNavigation() }
        let day: ActionHandler = { _ in self.startNavigation(styles: [DayStyle()]) }
        let night: ActionHandler = { _ in self.startNavigation(styles: [NightStyle()]) }
        let custom: ActionHandler = { _ in self.startCustomNavigation() }
        let styled: ActionHandler = { _ in self.startStyledNavigation() }
        let guidanceCards: ActionHandler = { _ in self.startGuidanceCardsNavigation() }
        
        let actionPayloads: [(String, UIAlertAction.Style, ActionHandler?)] = [
            ("Default UI", .default, basic),
            ("DayStyle UI", .default, day),
            ("NightStyle UI", .default, night),
            ("Custom UI", .default, custom),
            ("Guidance Card UI", .default, guidanceCards),
            ("Styled UI", .default, styled),
            ("Cancel", .cancel, nil)
        ]
        
        actionPayloads
            .map { payload in UIAlertAction(title: payload.0, style: payload.1, handler: payload.2) }
            .forEach(alertController.addAction(_:))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.startButton
            popoverController.sourceRect = self.startButton.bounds
        }
        
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Public Methods
    // MARK: Route Requests
    func requestRoute() {
        guard waypoints.count > 0 else { return }
        guard let mapView = mapView else { return }
        guard let userLocation = mapView.userLocation?.location else {
            print("User location is not valid. Make sure to enable Location Services.")
            return
        }
        
        let userWaypoint = Waypoint(location: userLocation, heading: mapView.userLocation?.heading, name: "User location")
        waypoints.insert(userWaypoint, at: 0)

        let options = NavigationRouteOptions(waypoints: waypoints)
        
        // Get periodic updates regarding changes in estimated arrival time and traffic congestion segments along the route line.
        RouteControllerProactiveReroutingInterval = 30

        requestRoute(with: options, success: defaultSuccess, failure: defaultFailure)
    }

    fileprivate func requestRoute(with options: RouteOptions, success: @escaping RouteRequestSuccess, failure: RouteRequestFailure?) {
        Directions.shared.calculate(options) { (session, result) in
            switch result {
            case let .success(response):
                success(response)
            case let .failure(error):
                print("Error occured while requesting route: \(error)")
                
                // Attempt to load offline Navigation tiles, depending on version of Navigation pack `tilesVersion` property
                // should be changed accordingly.
                self.navigationDirections.configureRouter(tilesVersion: OfflineServiceConstants.tilesVersion)
                self.navigationDirections.calculate(options, offline: true) { (session, result) in
                    switch result {
                    case let .failure(error):
                        failure?(error)
                    case let .success(response):
                        success(response)
                    }
                }
            }
        }
    }

    // MARK: Basic Navigation

    func startBasicNavigation() {
        guard let response = response, let route = response.routes?.first, case let .route(routeOptions) = response.options else { return }
        
        let service = navigationService(route: route, routeIndex: 0, options: routeOptions)
        let navigationViewController = self.navigationViewController(navigationService: service)
        
        // Render part of the route that has been traversed with full transparency, to give the illusion of a disappearing route.
        navigationViewController.routeLineTracksTraversal = true
        
        // Example of building highlighting in 3D.
        navigationViewController.waypointStyle = .extrudedBuilding
        navigationViewController.detailedFeedbackEnabled = true
        
        // Show second level of detail for feedback items.
        navigationViewController.detailedFeedbackEnabled = true
        
        presentAndRemoveMapview(navigationViewController, completion: beginCarPlayNavigation)
    }
    
    func startNavigation(styles: [Style]) {
        guard let response = response, let route = response.routes?.first, case let .route(routeOptions) = response.options else { return }
        
        let options = NavigationOptions(styles: styles, navigationService: navigationService(route: route, routeIndex: 0, options: routeOptions))
        let navigationViewController = NavigationViewController(for: route, routeIndex: 0, routeOptions: routeOptions, navigationOptions: options)
        navigationViewController.delegate = self
        
        // Example of building highlighting in 2D.
        navigationViewController.waypointStyle = .building
        
        presentAndRemoveMapview(navigationViewController, completion: beginCarPlayNavigation)
    }
    
    func navigationViewController(navigationService: NavigationService) -> NavigationViewController {
        let options = NavigationOptions(navigationService: navigationService)
        
        let navigationViewController = NavigationViewController(for: navigationService.route, routeIndex: navigationService.indexedRoute.1, routeOptions: navigationService.routeProgress.routeOptions, navigationOptions: options)
        navigationViewController.delegate = self
        navigationViewController.mapView?.delegate = self
        return navigationViewController
    }
    
    public func beginNavigationWithCarplay(navigationService: NavigationService) {
        let navigationViewController = activeNavigationViewController ?? self.navigationViewController(navigationService: navigationService)
        navigationViewController.didConnectToCarPlay()

        guard activeNavigationViewController == nil else { return }

        presentAndRemoveMapview(navigationViewController, completion: nil)
    }
    
    // MARK: Custom Navigation UI
    func startCustomNavigation() {
        guard let route = response?.routes?.first, let responseOptions = response?.options, case let .route(routeOptions) = responseOptions else { return }

        guard let customViewController = storyboard?.instantiateViewController(withIdentifier: "custom") as? CustomViewController else { return }

        customViewController.userIndexedRoute = (route, 0)
        customViewController.userRouteOptions = routeOptions

        let destination = MGLPointAnnotation()
        destination.coordinate = route.shape!.coordinates.last!
        customViewController.destination = destination
        customViewController.simulateLocation = simulationButton.isSelected

        present(customViewController, animated: true, completion: nil)
    }

    // MARK: Styling the default UI

    func startStyledNavigation() {
        guard let response = response, let route = response.routes?.first, case let .route(routeOptions) = response.options else { return }

        let styles = [CustomDayStyle(), CustomNightStyle()]
        let options = NavigationOptions(styles: styles, navigationService: navigationService(route: route, routeIndex: 0, options: routeOptions))
        let navigationViewController = NavigationViewController(for: route, routeIndex: 0, routeOptions: routeOptions, navigationOptions: options)
        navigationViewController.delegate = self

        presentAndRemoveMapview(navigationViewController, completion: beginCarPlayNavigation)
    }
    
    // MARK: Guidance Cards
    func startGuidanceCardsNavigation() {
        guard let response = response, let route = response.routes?.first, case let .route(routeOptions) = response.options else { return }
        
        let instructionsCardCollection = InstructionsCardViewController()
        instructionsCardCollection.cardCollectionDelegate = self
        
        let options = NavigationOptions(navigationService: navigationService(route: route, routeIndex: 0, options: routeOptions), topBanner: instructionsCardCollection)
        let navigationViewController = NavigationViewController(for: route, routeIndex: 0, routeOptions: routeOptions, navigationOptions: options)
        navigationViewController.delegate = self
        
        presentAndRemoveMapview(navigationViewController, completion: beginCarPlayNavigation)
    }
    
    func navigationService(route: Route, routeIndex: Int, options: RouteOptions) -> NavigationService {
        let simulate = simulationButton.isSelected
        let mode: SimulationMode = simulate ? .always : .onPoorGPS
        return MapboxNavigationService(route: route,
                                       routeIndex: routeIndex,
                                       routeOptions: options,
                                       simulating: mode,
                                       tilesVersion: OfflineServiceConstants.tilesVersion)
    }

    func presentAndRemoveMapview(_ navigationViewController: NavigationViewController, completion: CompletionHandler?) {
        navigationViewController.modalPresentationStyle = .fullScreen
        activeNavigationViewController = navigationViewController
        
        present(navigationViewController, animated: true) { [weak self] in
            completion?()
            
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
        mapView.logoView.isHidden = true

        let singleTap = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(tap:)))
        mapView.gestureRecognizers?.filter({ $0 is UILongPressGestureRecognizer }).forEach(singleTap.require(toFail:))
        mapView.addGestureRecognizer(singleTap)
        
        trackLocations(mapView: mapView)
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.showsUserHeadingIndicator = true
    }
    
    func uninstall(_ mapView: NavigationMapView) {
        NotificationCenter.default.removeObserver(self, name: .passiveLocationDataSourceDidUpdate, object: nil)
        mapView.removeFromSuperview()
    }
    
    private func setupOfflineService() {
        // Trigger OfflineServiceManager singleton creation to make sure that Maps SDK is notified whenever offline packs are available.
        let _ = OfflineServiceManager.instance
        NSLog("Suggested tiles path for Offline Service: \(Bundle.mapboxCoreNavigation.suggestedTileURL?.path ?? "Not available")")
    }
}

extension ViewController: MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        guard mapView == self.mapView else {
            return
        }
        
        self.mapView?.localizeLabels()
        
        if let routes = response?.routes, let currentRoute = routes.first, let coords = currentRoute.shape?.coordinates {
            mapView.setVisibleCoordinateBounds(MGLPolygon(coordinates: coords, count: UInt(coords.count)).overlayBounds, animated: false)
            self.mapView?.show(routes)
            self.mapView?.showWaypoints(on: currentRoute)
        }
    }
    
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        if annotation == trackPolyline {
            return .darkGray
        }
        if annotation == rawTrackPolyline {
            return .lightGray
        }
        return .black
    }
    
    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        return annotation == trackPolyline || annotation == rawTrackPolyline ? 4 : 1
    }
    
    func mapViewRegionIsChanging(_ mapView: MGLMapView) {
        if activeNavigationViewController == nil, foundAllBuildings == false, let navMapView = mapView as? NavigationMapView {
            let buildingHighlightCoordinates = waypoints.compactMap { $0.targetCoordinate }
            if buildingHighlightCoordinates.count > 0 {
                foundAllBuildings = navMapView.highlightBuildings(at: buildingHighlightCoordinates, in3D: false)
            }
        }
    }
}

// MARK: - NavigationMapViewDelegate
extension ViewController: NavigationMapViewDelegate {
    func navigationMapView(_ mapView: NavigationMapView, didSelect waypoint: Waypoint) {
        guard let responseOptions = response?.options, case let .route(routeOptions) = responseOptions else { return }
        let modifiedOptions = routeOptions.without(waypoint: waypoint)

        presentWaypointRemovalAlert { _ in
            self.requestRoute(with:modifiedOptions, success: self.defaultSuccess, failure: self.defaultFailure)
        }
    }

    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        guard let routes = response?.routes else { return }
        guard let index = routes.firstIndex(where: { $0 === route }) else { return }
        self.response!.routes!.remove(at: index)
        self.response!.routes!.insert(route, at: 0)
    }

    private func presentWaypointRemovalAlert(completionHandler approve: @escaping ((UIAlertAction) -> Void)) {
        let title = NSLocalizedString("REMOVE_WAYPOINT_CONFIRM_TITLE", value: "Remove Waypoint?", comment: "Title of alert confirming waypoint removal")
        let message = NSLocalizedString("REMOVE_WAYPOINT_CONFIRM_MSG", value: "Do you want to remove this waypoint?", comment: "Message of alert confirming waypoint removal")
        let removeTitle = NSLocalizedString("REMOVE_WAYPOINT_CONFIRM_REMOVE", value: "Remove Waypoint", comment: "Title of alert action for removing a waypoint")
        let cancelTitle = NSLocalizedString("CANCEL_TITLE", value: "Cancel", comment: "Title of action for dismissing waypoint removal confirmation sheet")
        
        let waypointRemovalAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let removeAction = UIAlertAction(title: removeTitle, style: .destructive, handler: approve)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        [removeAction, cancelAction].forEach(waypointRemovalAlertController.addAction(_:))
        
        self.present(waypointRemovalAlertController, animated: true, completion: nil)
    }
}

// MARK: RouteVoiceControllerDelegate methods
// To use these delegate methods, set the `routeVoiceControllerDelegate` on your `VoiceController`.
extension ViewController: RouteVoiceControllerDelegate {
    // Called when there is an error with instructions vocalization
    func routeVoiceController(_ routeVoiceController: RouteVoiceController, encountered error: SpeechError) {
        print(error)

    }
    
    // By default, the navigation service will attempt to filter out unqualified locations.
    // If however you would like to filter these locations in,
    // you can conditionally return a Bool here according to your own heuristics.
    // See CLLocation.swift `isQualified` for what makes a location update unqualified.
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldDiscard location: CLLocation) -> Bool {
        return true
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool {
        return true
    }
}

// MARK: WaypointConfirmationViewControllerDelegate
extension ViewController: WaypointConfirmationViewControllerDelegate {
    func confirmationControllerDidConfirm(_ confirmationController: WaypointConfirmationViewController) {
        confirmationController.dismiss(animated: true, completion: {
            guard let navigationViewController = self.presentedViewController as? NavigationViewController,
                let navService = navigationViewController.navigationService else { return }

            navService.router?.advanceLegIndex()
            navService.start()

            navigationViewController.mapView?.unhighlightBuildings()
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
        if mapView == nil {
            mapView = NavigationMapView(frame: view.bounds)
        }
    }
}

// MARK: VisualInstructionDelegate
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

// MARK: Free driving
extension ViewController {
    func trackLocations(mapView: NavigationMapView) {
        let dataSource = PassiveLocationDataSource()
        // In case if there is no internet connection it's possible to create instance of `PassiveLocationDataSource`
        // and point to version of sideloaded routing packs. For example:
        // let dataSource = PassiveLocationDataSource(tilesVersion: OfflineServiceConstants.tilesVersion)
        let locationManager = PassiveLocationManager(dataSource: dataSource)
        mapView.locationManager = locationManager
        
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdatePassiveLocation), name: .passiveLocationDataSourceDidUpdate, object: dataSource)
        
        trackPolyline = nil
        rawTrackPolyline = nil
    }
    
    @objc func didUpdatePassiveLocation(_ notification: Notification) {
        if let roadName = notification.userInfo?[PassiveLocationDataSource.NotificationUserInfoKey.roadNameKey] as? String {
            title = roadName
        }
        
        if let location = notification.userInfo?[PassiveLocationDataSource.NotificationUserInfoKey.locationKey] as? CLLocation {
            if trackPolyline == nil {
                trackPolyline = MGLPolyline()
            }
            
            var coordinates: [CLLocationCoordinate2D] = [location.coordinate]
            trackPolyline?.appendCoordinates(&coordinates, count: UInt(coordinates.count))
        }
        
        if let rawLocation = notification.userInfo?[PassiveLocationDataSource.NotificationUserInfoKey.rawLocationKey] as? CLLocation {
            if rawTrackPolyline == nil {
                rawTrackPolyline = MGLPolyline()
            }
            
            var coordinates: [CLLocationCoordinate2D] = [rawLocation.coordinate]
            rawTrackPolyline?.appendCoordinates(&coordinates, count: UInt(coordinates.count))
        }
        
        mapView?.addAnnotations([rawTrackPolyline!, trackPolyline!])
    }
}
