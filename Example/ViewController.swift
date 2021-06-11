import UIKit
import CoreLocation
import MapboxDirections
import Turf
import MapboxCoreNavigation
import MapboxMaps
import MapboxCoreMaps
import MapboxNavigation

class ViewController: UIViewController {
    
    @IBOutlet weak var longPressHintView: UIView!
    @IBOutlet weak var simulationButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var clearMap: UIButton!
    
    var trackStyledFeature: StyledFeature!
    var rawTrackStyledFeature: StyledFeature!
    var speedLimitView: SpeedLimitView!
    
    var currentEdgeIdentifier: RoadGraph.Edge.Identifier?
    var nextEdgeIdentifier: RoadGraph.Edge.Identifier?
    
    typealias RouteRequestSuccess = ((RouteResponse) -> Void)
    typealias RouteRequestFailure = ((Error) -> Void)
    typealias ActionHandler = (UIAlertAction) -> Void

    var navigationMapView: NavigationMapView! {
        didSet {
            if let navigationMapView = oldValue {
                uninstall(navigationMapView)
            }
            
            if let navigationMapView = navigationMapView {
                configure(navigationMapView)
                view.insertSubview(navigationMapView, belowSubview: longPressHintView)
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
                clearNavigationMapView()
                return
            }
            
            startButton.isEnabled = true
            // Show congestion levels on alternative route lines if there're multiple routes in the response.
            navigationMapView.showsCongestionForAlternativeRoutes = true
            navigationMapView.show(routes)
            navigationMapView.showWaypoints(on: currentRoute)
            navigationMapView.showRouteDurations(along: routes)
        }
    }
    
    weak var activeNavigationViewController: NavigationViewController?
    
    // MARK: - Initializer methods
    
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
        if let navigationMapView = navigationMapView {
            uninstall(navigationMapView)
        }
    }
    
    // MARK: - UIViewController lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSpeedLimitView()
        view.addSubview(speedLimitView)
    }
    
    func setupSpeedLimitView() {
        let speedLimitView = SpeedLimitView()
        speedLimitView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(speedLimitView)
        speedLimitView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        speedLimitView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        speedLimitView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        speedLimitView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10).isActive = true
        
        self.speedLimitView = speedLimitView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if navigationMapView == nil {
            navigationMapView = NavigationMapView(frame: view.bounds)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        requestNotificationCenterAuthorization()
    }
    
    private func configure(_ navigationMapView: NavigationMapView) {
        setupPassiveLocationManager()
        
        navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        navigationMapView.delegate = self
        navigationMapView.userLocationStyle = .puck2D()
        
        setupGestureRecognizers()
        setupPerformActionBarButtonItem()
    }
    
    private func uninstall(_ navigationMapView: NavigationMapView) {
        unsubscribeFromFreeDriveNotifications()
        navigationMapView.removeFromSuperview()
    }
    
    private func clearNavigationMapView() {
        startButton.isEnabled = false
        clearMap.isHidden = true
        longPressHintView.isHidden = false
        
        navigationMapView?.unhighlightBuildings()
        navigationMapView?.removeRoutes()
        navigationMapView?.removeRouteDurations()
        navigationMapView?.removeWaypoints()

        waypoints.removeAll()
    }
    
    func requestNotificationCenterAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { _, _ in
            DispatchQueue.main.async {
                CLLocationManager().requestWhenInUseAuthorization()
            }
        }
    }
    
    @IBAction func simulateButtonPressed(_ sender: Any) {
        simulationButton.isSelected = !simulationButton.isSelected
    }

    @IBAction func clearMapPressed(_ sender: Any) {
        clearNavigationMapView()
    }

    @IBAction func startButtonPressed(_ sender: Any) {
        presentActionsAlertController()
    }
    
    // MARK: - CarPlay navigation methods
    
    public func beginNavigationWithCarPlay(navigationService: NavigationService) {
        let navigationViewController = activeNavigationViewController ?? self.navigationViewController(navigationService: navigationService)
        navigationViewController.didConnectToCarPlay()

        guard activeNavigationViewController == nil else { return }

        presentAndRemoveNavigationMapView(navigationViewController)
    }
    
    func beginCarPlayNavigation() {
        let delegate = UIApplication.shared.delegate as? AppDelegate
        
        if #available(iOS 12.0, *),
            let service = activeNavigationViewController?.navigationService,
            let location = service.router.location {
            delegate?.carPlayManager.beginNavigationWithCarPlay(using: location.coordinate, navigationService: service)
        }
    }
    
    private func presentActionsAlertController() {
        let alertController = UIAlertController(title: "Start Navigation", message: "Select the navigation type", preferredStyle: .actionSheet)
        
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
    
    // MARK: - Active guidance navigation methods.
    
    func startNavigation(styles: [MapboxNavigation.Style]) {
        guard let response = response, let route = response.routes?.first, case let .route(routeOptions) = response.options else { return }
        
        let options = NavigationOptions(styles: styles, navigationService: navigationService(route: route, routeIndex: 0, options: routeOptions), predictiveCacheOptions: PredictiveCacheOptions())
        let navigationViewController = NavigationViewController(for: route, routeIndex: 0, routeOptions: routeOptions, navigationOptions: options)
        navigationViewController.delegate = self
        
        // Example of building highlighting in 2D.
        navigationViewController.waypointStyle = .building
        
        presentAndRemoveNavigationMapView(navigationViewController, completion: beginCarPlayNavigation)
    }
    
    func startBasicNavigation() {
        guard let response = response, let route = response.routes?.first, case let .route(routeOptions) = response.options else { return }
        
        let service = navigationService(route: route, routeIndex: 0, options: routeOptions)
        let navigationViewController = self.navigationViewController(navigationService: service)
        
        // Render part of the route that has been traversed with full transparency, to give the illusion of a disappearing route.
        navigationViewController.routeLineTracksTraversal = true
        
        // Example of building highlighting in 3D.
        navigationViewController.waypointStyle = .extrudedBuilding
        
        // Show second level of detail for feedback items.
        navigationViewController.detailedFeedbackEnabled = true
        
        // Control floating buttons position in a navigation view.
        navigationViewController.floatingButtonsPosition = .topTrailing
        
        presentAndRemoveNavigationMapView(navigationViewController, completion: beginCarPlayNavigation)
    }
    
    func startCustomNavigation() {
        guard let route = response?.routes?.first,
              let responseOptions = response?.options,
              case let .route(routeOptions) = responseOptions,
              let customViewController = storyboard?.instantiateViewController(withIdentifier: "custom") as? CustomViewController else { return }

        customViewController.userIndexedRoute = (route, 0)
        customViewController.userRouteOptions = routeOptions
        customViewController.simulateLocation = simulationButton.isSelected
        
        present(customViewController, animated: true) {
            if let destinationCoordinate = route.shape?.coordinates.last {
                var destinationAnnotation = PointAnnotation(coordinate: destinationCoordinate)
                destinationAnnotation.image = .default
                customViewController.destinationAnnotation = destinationAnnotation
            }
        }
    }

    func startStyledNavigation() {
        guard let response = response, let route = response.routes?.first, case let .route(routeOptions) = response.options else { return }

        let styles = [CustomDayStyle(), CustomNightStyle()]
        let options = NavigationOptions(styles: styles, navigationService: navigationService(route: route, routeIndex: 0, options: routeOptions), predictiveCacheOptions: PredictiveCacheOptions())
        let navigationViewController = NavigationViewController(for: route, routeIndex: 0, routeOptions: routeOptions, navigationOptions: options)
        navigationViewController.delegate = self

        presentAndRemoveNavigationMapView(navigationViewController, completion: beginCarPlayNavigation)
    }
    
    func startGuidanceCardsNavigation() {
        guard let response = response, let route = response.routes?.first, case let .route(routeOptions) = response.options else { return }
        
        let instructionsCardCollection = InstructionsCardViewController()
        instructionsCardCollection.cardCollectionDelegate = self
        
        let options = NavigationOptions(navigationService: navigationService(route: route, routeIndex: 0, options: routeOptions), topBanner: instructionsCardCollection, predictiveCacheOptions: PredictiveCacheOptions())
        let navigationViewController = NavigationViewController(for: route, routeIndex: 0, routeOptions: routeOptions, navigationOptions: options)
        navigationViewController.delegate = self
        
        presentAndRemoveNavigationMapView(navigationViewController, completion: beginCarPlayNavigation)
    }
    
    // MARK: - UIGestureRecognizer methods
    
    func setupGestureRecognizers() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        navigationMapView.gestureRecognizers?.filter({ $0 is UILongPressGestureRecognizer }).forEach(longPressGestureRecognizer.require(toFail:))
        navigationMapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    func setupPerformActionBarButtonItem() {
        let settingsBarButtonItem = UIBarButtonItem(title: NSString(string: "\u{2699}\u{0000FE0E}") as String, style: .plain, target: self, action: #selector(performAction))
        settingsBarButtonItem.setTitleTextAttributes([.font : UIFont.systemFont(ofSize: 30)], for: .normal)
        settingsBarButtonItem.setTitleTextAttributes([.font : UIFont.systemFont(ofSize: 30)], for: .highlighted)
        navigationItem.rightBarButtonItem = settingsBarButtonItem
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let gestureLocation = gesture.location(in: navigationMapView)
        let destinationCoordinate = navigationMapView.mapView.mapboxMap.coordinate(for: gestureLocation)
        
        if waypoints.count > 1 {
            waypoints = Array(waypoints.dropFirst())
        }
        
        // Note: The destination name can be modified. The value is used in the top banner when arriving at a destination.
        let waypoint = Waypoint(coordinate: destinationCoordinate, name: "Dropped Pin #\(waypoints.endIndex + 1)")
        // Example of building highlighting. `targetCoordinate`, in this example,
        // is used implicitly by NavigationViewController to determine which buildings to highlight.
        waypoint.targetCoordinate = destinationCoordinate
        waypoints.append(waypoint)
        
        // Example of highlighting buildings in 3d and directly using the API on NavigationMapView.
        let buildingHighlightCoordinates = waypoints.compactMap { $0.targetCoordinate }
        navigationMapView.highlightBuildings(at: buildingHighlightCoordinates)

        requestRoute()
    }
    
    @objc func performAction(_ sender: Any) {
        let alertController = UIAlertController(title: "Perform action",
                                                message: "Select specific action to perform it", preferredStyle: .actionSheet)
        
        let toggleDayNightStyle: ActionHandler = { _ in self.toggleDayNightStyle() }
        let requestFollowCamera: ActionHandler = { _ in self.requestFollowCamera() }
        let requestIdleCamera: ActionHandler = { _ in self.requestIdleCamera() }
        
        let actions: [(String, UIAlertAction.Style, ActionHandler?)] = [
            ("Toggle Day/Night Style", .default, toggleDayNightStyle),
            ("Request Following Camera", .default, requestFollowCamera),
            ("Request Idle Camera", .default, requestIdleCamera),
            ("Cancel", .cancel, nil)
        ]
        
        actions
            .map({ payload in UIAlertAction(title: payload.0, style: payload.1, handler: payload.2) })
            .forEach(alertController.addAction(_:))
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        present(alertController, animated: true, completion: nil)
    }
    
    func toggleDayNightStyle() {
        let style = navigationMapView.mapView?.mapboxMap.style
        if style?.uri?.rawValue == MapboxMaps.Style.navigationNightStyleURL.absoluteString {
            style?.uri = StyleURI(url: MapboxMaps.Style.navigationDayStyleURL)
        } else {
            style?.uri = StyleURI(url: MapboxMaps.Style.navigationNightStyleURL)
        }
    }
    
    func requestFollowCamera() {
        navigationMapView.navigationCamera.follow()
    }
    
    func requestIdleCamera() {
        navigationMapView.navigationCamera.stop()
    }
    
    func requestRoute() {
        guard waypoints.count > 0 else { return }
        guard let currentLocation = navigationMapView.mapView.location.latestLocation?.internalLocation else {
            print("User location is not valid. Make sure to enable Location Services.")
            return
        }
        
        let userWaypoint = Waypoint(location: currentLocation)
        waypoints.insert(userWaypoint, at: 0)

        let navigationRouteOptions = NavigationRouteOptions(waypoints: waypoints)
        
        // Get periodic updates regarding changes in estimated arrival time and traffic congestion segments along the route line.
        RouteControllerProactiveReroutingInterval = 30

        requestRoute(with: navigationRouteOptions, success: defaultSuccess, failure: defaultFailure)
    }
        
    fileprivate lazy var defaultSuccess: RouteRequestSuccess = { [weak self] (response) in
        guard let routes = response.routes, !routes.isEmpty, case let .route(options) = response.options else { return }
        self?.navigationMapView.removeWaypoints()
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
        // Clear routes from the map
        self?.response = nil
        self?.presentAlert(message: error.localizedDescription)
    }

    func requestRoute(with options: RouteOptions, success: @escaping RouteRequestSuccess, failure: RouteRequestFailure?) {
        Directions.shared.calculateWithCache(options: options) { (session, result) in
            switch result {
            case let .success(response):
                success(response)
            case let .failure(error):
                failure?(error)
            }
        }
    }
    
    func navigationViewController(navigationService: NavigationService) -> NavigationViewController {
        let navigationOptions = NavigationOptions(navigationService: navigationService, predictiveCacheOptions: PredictiveCacheOptions())
        
        let navigationViewController = NavigationViewController(for: navigationService.route,
                                                                routeIndex: navigationService.indexedRoute.1,
                                                                routeOptions: navigationService.routeProgress.routeOptions,
                                                                navigationOptions: navigationOptions)
        navigationViewController.delegate = self
        
        return navigationViewController
    }
    
    func presentAndRemoveNavigationMapView(_ navigationViewController: NavigationViewController,
                                           completion: CompletionHandler? = nil) {
        navigationViewController.modalPresentationStyle = .fullScreen
        activeNavigationViewController = navigationViewController
        
        present(navigationViewController, animated: true) {
            completion?()
            self.navigationMapView = nil
        }
    }
    
    func endCarPlayNavigation(canceled: Bool) {
        if #available(iOS 12.0, *), let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.carPlayManager.carPlayNavigationViewController?.exitNavigation(byCanceling: canceled)
        }
    }
    
    func dismissActiveNavigationViewController() {
        activeNavigationViewController?.dismiss(animated: true) {
            self.activeNavigationViewController = nil
        }
    }

    func navigationService(route: Route, routeIndex: Int, options: RouteOptions) -> NavigationService {
        let mode: SimulationMode = simulationButton.isSelected ? .always : .onPoorGPS
        
        return MapboxNavigationService(route: route, routeIndex: routeIndex, routeOptions: options, simulating: mode)
    }
    
    // MARK: - Utility methods
    
    func presentAlert(_ title: String? = nil, message: String? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
            alertController.dismiss(animated: true, completion: nil)
        }))
        
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - NavigationMapViewDelegate methods

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
        self.response?.routes?.swapAt(index, 0)
    }

    private func presentWaypointRemovalAlert(completionHandler approve: @escaping ((UIAlertAction) -> Void)) {
        let title = NSLocalizedString("REMOVE_WAYPOINT_CONFIRM_TITLE", value: "Remove Waypoint?", comment: "Title of alert confirming waypoint removal")
        let message = NSLocalizedString("REMOVE_WAYPOINT_CONFIRM_MSG", value: "Do you want to remove this waypoint?", comment: "Message of alert confirming waypoint removal")
        let removeTitle = NSLocalizedString("REMOVE_WAYPOINT_CONFIRM_REMOVE", value: "Remove Waypoint", comment: "Title of alert action for removing a waypoint")
        let cancelTitle = NSLocalizedString("REMOVE_WAYPOINT_CONFIRM_CANCEL", value: "Cancel", comment: "Title of action for dismissing waypoint removal confirmation sheet")
        
        let waypointRemovalAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let removeAction = UIAlertAction(title: removeTitle, style: .destructive, handler: approve)
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: nil)
        [removeAction, cancelAction].forEach(waypointRemovalAlertController.addAction(_:))
        
        self.present(waypointRemovalAlertController, animated: true, completion: nil)
    }
}

// MARK: - RouteVoiceControllerDelegate methods

extension ViewController: RouteVoiceControllerDelegate {

}

// MARK: - NavigationViewControllerDelegate methods

extension ViewController: NavigationViewControllerDelegate {

    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        if #available(iOS 12.0, *),
           let delegate = UIApplication.shared.delegate as? AppDelegate,
           let carPlayNavigationViewController = delegate.carPlayManager.carPlayNavigationViewController {
            return carPlayNavigationViewController.navigationService(navigationViewController.navigationService, didArriveAt: waypoint)
        }
        return true
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        endCarPlayNavigation(canceled: canceled)
        dismissActiveNavigationViewController()
        clearNavigationMapView()
    }
}

// MARK: - VisualInstructionDelegate methods

extension ViewController: VisualInstructionDelegate {

}
