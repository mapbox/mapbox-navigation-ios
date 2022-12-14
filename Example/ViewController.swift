import UIKit
import CoreLocation
import MapboxDirections
import Turf
import MapboxCoreNavigation
import MapboxMaps
import MapboxCoreMaps
import MapboxNavigation

class ViewController: UIViewController {

    @IBOutlet weak var mapHostView: UIView!
    @IBOutlet weak var longPressHintView: UIView!
    @IBOutlet weak var simulationButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var clearMap: UIButton!
    
    let feedbackButton: FloatingButton = {
        let image = UIImage(named: "feedback", in: .mapboxNavigation, compatibleWith: nil)!
        let button = FloatingButton.rounded(image: image.withRenderingMode(.alwaysTemplate))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
        return button
    }()
    
    var trackStyledFeature: StyledFeature!
    var rawTrackStyledFeature: StyledFeature!
    var speedLimitView: SpeedLimitView!
    weak var passiveLocationManager: PassiveLocationManager?
    
    var currentEdgeIdentifier: RoadGraph.Edge.Identifier?
    var nextEdgeIdentifier: RoadGraph.Edge.Identifier?
    
    typealias RouteRequestSuccess = ((IndexedRouteResponse) -> Void)
    typealias RouteRequestFailure = ((Error) -> Void)
    typealias ActionHandler = (UIAlertAction) -> Void

    var navigationMapView: NavigationMapView! {
        didSet {
            if let navigationMapView = oldValue {
                uninstall(navigationMapView)
            }
            
            if let navigationMapView = navigationMapView {
                mapHostView.addSubview(navigationMapView)
                configure(navigationMapView)
            }
        }
    }
    
    var styleManager = MapboxNavigation.StyleManager()
    
    var waypoints: [Waypoint] = [] {
        didSet {
            waypoints.forEach {
                $0.coordinateAccuracy = -1
            }
        }
    }
    
    var currentRouteIndex: Int {
        indexedRouteResponse?.routeIndex ?? 0
    }

    func showCurrentRoute() {
        guard let routeResponse = indexedRouteResponse,
              var prioritizedRoutes = routes else { return }
        
        prioritizedRoutes.insert(prioritizedRoutes.remove(at: currentRouteIndex),
                                 at: 0)
        
        // Show congestion levels on alternative route lines if there're multiple routes in the response.
        navigationMapView.showsCongestionForAlternativeRoutes = true
        navigationMapView.showsRestrictedAreasOnRoute = true
        navigationMapView.show(routeResponse)
        navigationMapView.showWaypoints(on: prioritizedRoutes.first!)
        navigationMapView.showRouteDurations(along: prioritizedRoutes)
    }
    
    var currentRoute: Route? {
        return routes?[currentRouteIndex]
    }
    
    var routes: [Route]? {
        return indexedRouteResponse?.routeResponse.routes
    }
    
    var requestMapMatching = false
    
    var indexedRouteResponse: IndexedRouteResponse? {
        didSet {
            guard let routes = indexedRouteResponse?.routeResponse.routes, !routes.isEmpty else {
                clearNavigationMapView()
                return
            }
            
            startButton.isEnabled = true
            showCurrentRoute()
        }
    }
    
    weak var activeNavigationViewController: NavigationViewController?
    
    var profileIdentifier: ProfileIdentifier = .automobileAvoidingTraffic
    let drivingProfileText = NSLocalizedString("Start Driving", comment: "")
    let drivingAvoidingTrafficProfileText = NSLocalizedString("Start Driving Avoiding Traffic", comment: "")
    let cyclingProfileText = NSLocalizedString("Start Cycling", comment: "")
    let walkingProfileText = NSLocalizedString("Start Walking", comment: "")

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
        setupFeedbackButton()
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
    
    func setupFeedbackButton() {
        view.addSubview(feedbackButton)
        feedbackButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12).isActive = true
        feedbackButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12).isActive = true
        feedbackButton.addTarget(self, action: #selector(feedback(_:)), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if navigationMapView == nil {
            navigationMapView = NavigationMapView(frame: .zero)
            navigationMapView.mapView.mapboxMap.onEvery(event: .styleLoaded) { [weak self] _ in
                self?.navigationMapView.localizeLabels()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        requestNotificationCenterAuthorization()
    }

    private func configure(_ navigationMapView: NavigationMapView) {
        setupPassiveLocationProvider()
        
        navigationMapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navigationMapView.topAnchor.constraint(equalTo: mapHostView.topAnchor),
            navigationMapView.leadingAnchor.constraint(equalTo: mapHostView.leadingAnchor),
            navigationMapView.bottomAnchor.constraint(equalTo: mapHostView.bottomAnchor),
            navigationMapView.trailingAnchor.constraint(equalTo: mapHostView.trailingAnchor),
        ])

        let mapOrnamentsMargin: CGFloat = 55
        navigationMapView.mapView.ornaments.options.logo.margins.y = mapOrnamentsMargin
        navigationMapView.mapView.ornaments.options.attributionButton.margins.y = mapOrnamentsMargin
        navigationMapView.delegate = self
        navigationMapView.userLocationStyle = .puck2D()
        
        setupStyleManager()
        setupGestureRecognizers()
        setupPerformActionBarButtonItem()
        if let cameraState = activeNavigationViewController?.navigationMapView?.mapView.cameraState {
            navigationMapView.mapView.camera.fly(to: .init(center: cameraState.center,
                                                           zoom: cameraState.zoom),
                                                 duration: 0,
                                                 completion: nil)
        }
    }
    
    private func setupStyleManager() {
        styleManager.delegate = self
        styleManager.styles = [DayStyle(), NightStyle()]
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
    
    @objc func feedback(_ sender: Any) {
        guard let passiveNavigationEventsManager = passiveLocationManager?.eventsManager else {
            assertionFailure("Not in Passive Navigation"); return
        }
        let feedbackViewController = FeedbackViewController(eventsManager: passiveNavigationEventsManager, type: .passiveNavigation)
        feedbackViewController.detailedFeedbackEnabled = true
        present(feedbackViewController, animated: true)
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
        
        if let service = activeNavigationViewController?.navigationService,
           let location = service.router.location {
            delegate?.carPlayManager.beginNavigationWithCarPlay(using: location.coordinate, navigationService: service)
        }
    }
    
    private func presentActionsAlertController() {
        var title: String?
        switch profileIdentifier {
        case .automobile:
            title = drivingProfileText
        case .automobileAvoidingTraffic:
            title = drivingAvoidingTrafficProfileText
        case .cycling:
            title = cyclingProfileText
        case .walking:
            title = walkingProfileText
        default:
            title = NSLocalizedString("Start Navigation", comment: "")
        }
        
        let alertController = UIAlertController(title: title, message: "Select the navigation type", preferredStyle: .actionSheet)
        
        let basic: ActionHandler = { _ in self.startBasicNavigation() }
        let day: ActionHandler = { _ in self.startNavigation(styles: [DayStyle()]) }
        let night: ActionHandler = { _ in self.startNavigation(styles: [NightStyle()]) }
        let custom: ActionHandler = { _ in self.startCustomNavigation() }
        let styled: ActionHandler = { _ in self.startStyledNavigation() }
        let instructionsCard: ActionHandler = { _ in self.startInstructionsCardNavigation() }
        
        let actionPayloads: [(String, UIAlertAction.Style, ActionHandler?)] = [
            ("Default UI", .default, basic),
            ("DayStyle UI", .default, day),
            ("NightStyle UI", .default, night),
            ("Custom UI", .default, custom),
            ("Instructions Card UI", .default, instructionsCard),
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
        guard let response = indexedRouteResponse else { return }
        
        let options = NavigationOptions(styles: styles, navigationService: navigationService(indexedRouteResponse: response), predictiveCacheOptions: PredictiveCacheOptions())
        let navigationViewController = NavigationViewController(for: response, navigationOptions: options)
        navigationViewController.delegate = self
        
        // Example of building highlighting in 2D.
        navigationViewController.waypointStyle = .building
        
        presentAndRemoveNavigationMapView(navigationViewController, completion: beginCarPlayNavigation)
    }
    
    func startBasicNavigation() {
        guard let response = indexedRouteResponse else { return }
        
        let service = navigationService(indexedRouteResponse: response)
        let navigationViewController = self.navigationViewController(navigationService: service)
        
        // Render part of the route that has been traversed with full transparency, to give the illusion of a disappearing route.
        navigationViewController.routeLineTracksTraversal = true
        
        // Example of building highlighting in 3D.
        navigationViewController.waypointStyle = .extrudedBuilding
        
        // Show second level of detail for feedback items.
        navigationViewController.detailedFeedbackEnabled = true
        
        // Control floating buttons position in a navigation view.
        navigationViewController.floatingButtonsPosition = .topTrailing

        presentAndRemoveNavigationMapView(navigationViewController,
                                          animated: false,
                                          completion: beginCarPlayNavigation)
    }
    
    func startCustomNavigation() {
        guard let response = indexedRouteResponse,
              let route = response.currentRoute,
              let customViewController = storyboard?.instantiateViewController(withIdentifier: "custom") as? CustomViewController else { return }

        customViewController.indexedUserRouteResponse = response
        customViewController.simulateLocation = simulationButton.isSelected
        
        present(customViewController, animated: true) {
            if let destinationCoordinate = route.shape?.coordinates.last {
                var destinationAnnotation = PointAnnotation(coordinate: destinationCoordinate)
                let markerImage = UIImage(named: "default_marker", in: .mapboxNavigation, compatibleWith: nil)!
                destinationAnnotation.image = .init(image: markerImage, name: "marker")
                customViewController.destinationAnnotation = destinationAnnotation
            }
        }
    }

    func startStyledNavigation() {
        guard let response = indexedRouteResponse else { return }

        let styles = [CustomDayStyle(), CustomNightStyle()]
        let options = NavigationOptions(styles: styles, navigationService: navigationService(indexedRouteResponse: response), predictiveCacheOptions: PredictiveCacheOptions())
        let navigationViewController = NavigationViewController(for: response, navigationOptions: options)
        navigationViewController.delegate = self

        presentAndRemoveNavigationMapView(navigationViewController, completion: beginCarPlayNavigation)
    }
    
    func startInstructionsCardNavigation() {
        guard let response = indexedRouteResponse else { return }
        
        // Styles are passed explicitly to be able to easily test how instructions cards look.
        let styles = [
            DayStyle(),
            NightStyle()
        ]
        let navigationService = self.navigationService(indexedRouteResponse: response)
        
        let instructionsCardCollection = InstructionsCardViewController()
        instructionsCardCollection.cardCollectionDelegate = self
        
        let navigationOptions = NavigationOptions(styles: styles,
                                                  navigationService: navigationService,
                                                  topBanner: instructionsCardCollection,
                                                  predictiveCacheOptions: PredictiveCacheOptions())
        
        let navigationViewController = NavigationViewController(for: response,
                                                                navigationOptions: navigationOptions)
        navigationViewController.delegate = self
        
        // Example of building highlighting in 2D.
        navigationViewController.waypointStyle = .building
        
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
        let requestAutoDirections: ActionHandler = { _ in self.requestAutoDirections() }
        let requestAutoAvoidingTrafficDirections: ActionHandler = { _ in self.requestAutoAvoidingTrafficDirections() }
        let requestCyclingDirections: ActionHandler = { _ in self.requestCyclingDirections() }
        let requestWalkingDirections: ActionHandler = { _ in self.requestWalkingDirections() }
        let turnOnHistoryRecording: ActionHandler = { _ in self.turnOnHistoryRecording() }
        let turnOffHistoryRecording: ActionHandler = { _ in self.turnOffHistoryRecording() }
        let toggleMapMatching: ActionHandler = { _ in self.requestMapMatching.toggle() }
        
        let actions: [(String, UIAlertAction.Style, ActionHandler?)] = [
            ("Toggle Day/Night Style", .default, toggleDayNightStyle),
            ("Request Following Camera", .default, requestFollowCamera),
            ("Request Idle Camera", .default, requestIdleCamera),
            ("Request Auto Directions", .default, requestAutoDirections),
            ("Request Auto Avoiding Traffic Directions", .default, requestAutoAvoidingTrafficDirections),
            ("Request Cycling Directions", .default, requestCyclingDirections),
            ("Request Walking Directions", .default, requestWalkingDirections),
            ("Turn On History Recording", .default, turnOnHistoryRecording),
            ("Turn Off History Recording", .default, turnOffHistoryRecording),
            ( requestMapMatching ? "Enable Routing Requesting": "Enable Map Match Requesting", .default, toggleMapMatching),
            ("Cancel", .cancel, nil),
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
        if styleManager.currentStyleType == .day {
            styleManager.applyStyle(type: .night)
        } else {
            styleManager.applyStyle(type: .day)
        }
    }
    
    func requestFollowCamera() {
        navigationMapView.navigationCamera.follow()
    }
    
    func requestIdleCamera() {
        navigationMapView.navigationCamera.stop()
    }
    
    func requestAutoDirections() {
        profileIdentifier = .automobile
        startButton.setTitle(drivingProfileText, for: .normal)
        requestRoute()
    }
    
    func requestAutoAvoidingTrafficDirections() {
        profileIdentifier = .automobileAvoidingTraffic
        startButton.setTitle(drivingAvoidingTrafficProfileText, for: .normal)
        requestRoute()
    }
    
    func requestCyclingDirections() {
        profileIdentifier = .cycling
        startButton.setTitle(cyclingProfileText, for: .normal)
        requestRoute()
    }

    func requestWalkingDirections() {
        profileIdentifier = .walking
        startButton.setTitle(walkingProfileText, for: .normal)
        requestRoute()
    }
    
    func turnOnHistoryRecording() {
        PassiveLocationManager.startRecordingHistory()
    }

    func turnOffHistoryRecording() {
        PassiveLocationManager.stopRecordingHistory { historyFileUrl in
            guard let historyFileUrl = historyFileUrl else { return }
            DispatchQueue.main.async {
                #if targetEnvironment(simulator)
                print("History file saved at path: \(historyFileUrl.path)")
                #else
                let shareVC = UIActivityViewController(activityItems: [historyFileUrl], applicationActivities: nil)
                self.present(shareVC, animated: true, completion: nil)
                #endif
            }
        }
    }
    
    func requestRoute() {
        guard waypoints.count > 0 else { return }
        guard let currentLocation = passiveLocationManager?.location else {
            print("User location is not valid. Make sure to enable Location Services.")
            return
        }

        let userWaypoint = Waypoint(location: currentLocation)
        if currentLocation.course >= 0 {
            userWaypoint.heading = currentLocation.course
            userWaypoint.headingAccuracy = 90
        }
        waypoints.insert(userWaypoint, at: 0)
        
        // Get periodic updates regarding changes in estimated arrival time and traffic congestion segments along the route line.
        RouteControllerProactiveReroutingInterval = 30

        if requestMapMatching {
            waypoints.forEach { $0.heading = nil }
            let mapMatchingOptions = NavigationMatchOptions(waypoints: waypoints, profileIdentifier: profileIdentifier)
            requestRoute(with: mapMatchingOptions, success: defaultSuccess, failure: defaultFailure)
        } else {
            let navigationRouteOptions = NavigationRouteOptions(waypoints: waypoints, profileIdentifier: profileIdentifier)
            requestRoute(with: navigationRouteOptions, success: defaultSuccess, failure: defaultFailure)
        }
        
    }
        
    fileprivate lazy var defaultSuccess: RouteRequestSuccess = { [weak self] (response) in
        guard let self = self,
              // In some rare cases this callback can be called when `NavigationMapView` object is no
              // longer available. This check prevents access to invalid object.
              self.navigationMapView != nil,
              let routes = response.routeResponse.routes,
              !routes.isEmpty else { return }
        self.navigationMapView.removeWaypoints()
        self.indexedRouteResponse = response
        
        // Waypoints which were placed by the user are rewritten by slightly changed waypoints
        // which are returned in response with routes.
        if let waypoints = response.routeResponse.waypoints {
            self.waypoints = waypoints
        }
        
        self.clearMap.isHidden = false
        self.longPressHintView.isHidden = true
    }

    fileprivate lazy var defaultFailure: RouteRequestFailure = { [weak self] (error) in
        // Clear routes from the map
        self?.indexedRouteResponse = nil
        self?.presentAlert(message: error.localizedDescription)
    }

    func requestRoute(with options: RouteOptions, success: @escaping RouteRequestSuccess, failure: RouteRequestFailure?) {
        MapboxRoutingProvider().calculateRoutes(options: options) { (result) in
            switch result {
            case let .success(response):
                success(response)
            case let .failure(error):
                failure?(error)
            }
        }
    }
    
    func requestRoute(with options: MatchOptions, success: @escaping RouteRequestSuccess, failure: RouteRequestFailure?) {
        MapboxRoutingProvider().calculateRoutes(options: options) { (_, result) in
            switch result {
            case let .success(response):
                do {
                    success(.init(routeResponse: try RouteResponse(matching: response,
                                                                   options: options,
                                                                   credentials: response.credentials),
                                  routeIndex: 0))
                } catch {
                    failure?(DirectionsError.noMatches)
                }
            case let .failure(error):
                failure?(error)
            }
        }
    }
    
    func navigationViewController(navigationService: NavigationService) -> NavigationViewController {
        let navigationOptions = NavigationOptions(navigationService: navigationService, predictiveCacheOptions: PredictiveCacheOptions())
        
        let navigationViewController = NavigationViewController(for: navigationService.indexedRouteResponse,
                                                                navigationOptions: navigationOptions)
        navigationViewController.delegate = self
        
        return navigationViewController
    }
    
    func presentAndRemoveNavigationMapView(_ navigationViewController: NavigationViewController,
                                           animated: Bool = true,
                                           completion: CompletionHandler? = nil) {
        navigationViewController.modalPresentationStyle = .fullScreen
        activeNavigationViewController = navigationViewController
        
        // Hide top and bottom container views before animating their presentation.
        navigationViewController.navigationView.bottomBannerContainerView.hide(animated: false)
        navigationViewController.navigationView.topBannerContainerView.hide(animated: false)
        
        // Hide `WayNameView` and `FloatingStackView` to smoothly present them.
        navigationViewController.navigationView.wayNameView.alpha = 0.0
        navigationViewController.navigationView.floatingStackView.alpha = 0.0
        navigationViewController.navigationView.speedLimitView.alpha = 0.0
        
        present(navigationViewController, animated: animated) {
            completion?()
            // Cleaning up the `PassiveLocationManager`. The `PassiveLocationManager` during active navigation may lead to location jump.
            self.navigationMapView = nil
            self.passiveLocationManager = nil
            navigationViewController.navigationMapView?.showsRestrictedAreasOnRoute = true
            
            // Animate top and bottom banner views presentation.
            navigationViewController.navigationView.bottomBannerContainerView.show(duration: 1.0,
                                                                                   animations: {
                navigationViewController.navigationView.wayNameView.alpha = 1.0
                navigationViewController.navigationView.floatingStackView.alpha = 1.0
                navigationViewController.navigationView.speedLimitView.alpha = 1.0
            })
            navigationViewController.navigationView.topBannerContainerView.show(duration: 1.0)
        }
    }
    
    func endCarPlayNavigation(canceled: Bool) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.carPlayManager.carPlayNavigationViewController?.exitNavigation(byCanceling: canceled)
        }
    }
    
    func dismissActiveNavigationViewController(animated: Bool = false) {
        guard let activeNavigationViewController = activeNavigationViewController else { return }
        
        activeNavigationViewController.navigationView.bottomBannerContainerView.hide(duration: 1.0)
        activeNavigationViewController.navigationView.topBannerContainerView.hide(duration: 1.0,
                                                                                  animations: {
            activeNavigationViewController.navigationView.wayNameView.alpha = 0.0
            activeNavigationViewController.navigationView.floatingStackView.alpha = 0.0
            activeNavigationViewController.navigationView.speedLimitView.alpha = 0.0
        },
                                                                                  completion: { _ in
            activeNavigationViewController.dismiss(animated: animated) {
                self.activeNavigationViewController = nil
            }
        })
    }

    func navigationService(indexedRouteResponse: IndexedRouteResponse) -> NavigationService {
        let mode: SimulationMode = simulationButton.isSelected ? .always : .inTunnels
        
        return MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                       customRoutingProvider: nil,
                                       credentials: NavigationSettings.shared.directions.credentials,
                                       simulating: mode)
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
        guard let responseOptions = indexedRouteResponse?.routeResponse.options else { return }
        
        switch responseOptions {
        case .route(let routeOptions):
            let modifiedOptions: RouteOptions = routeOptions.without(waypoint) as! RouteOptions
            presentWaypointRemovalAlert { _ in
                self.requestRoute(with:modifiedOptions, success: self.defaultSuccess, failure: self.defaultFailure)
            }
        case .match(let matchOptions):
            let modifiedOptions: MatchOptions = matchOptions.without(waypoint) as! MatchOptions
            presentWaypointRemovalAlert { _ in
                self.requestRoute(with:modifiedOptions, success: self.defaultSuccess, failure: self.defaultFailure)
            }
        }
    }
    
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect continuousAlternative: AlternativeRoute) {
        indexedRouteResponse?.routeIndex = continuousAlternative.indexedRouteResponse.routeIndex
    }

    private func presentWaypointRemovalAlert(completionHandler approve: @escaping ((UIAlertAction) -> Void)) {
        let title = NSLocalizedString("REMOVE_WAYPOINT_CONFIRM_TITLE",
                                      value: "Remove Waypoint?",
                                      comment: "Title of alert confirming waypoint removal")
        
        let message = NSLocalizedString("REMOVE_WAYPOINT_CONFIRM_MSG",
                                        value: "Do you want to remove this waypoint?",
                                        comment: "Message of alert confirming waypoint removal")
        
        let removeTitle = NSLocalizedString("REMOVE_WAYPOINT_CONFIRM_REMOVE",
                                            value: "Remove Waypoint",
                                            comment: "Title of alert action for removing a waypoint")
        
        let cancelTitle = NSLocalizedString("REMOVE_WAYPOINT_CONFIRM_CANCEL",
                                            value: "Cancel",
                                            comment: "Title of action for dismissing waypoint removal confirmation sheet")
        
        let waypointRemovalAlertController = UIAlertController(title: title,
                                                               message: message,
                                                               preferredStyle: .alert)
        
        let removeAction = UIAlertAction(title: removeTitle,
                                         style: .destructive,
                                         handler: approve)
        
        let cancelAction = UIAlertAction(title: cancelTitle,
                                         style: .cancel,
                                         handler: nil)
        
        [removeAction, cancelAction].forEach(waypointRemovalAlertController.addAction(_:))
        
        self.present(waypointRemovalAlertController, animated: true, completion: nil)
    }
}

// MARK: - NavigationViewControllerDelegate methods

extension ViewController: NavigationViewControllerDelegate {
    
    // To modify the width of the alternative route line layer through delegate methods.
    func navigationViewController(_ navigationViewController: NavigationViewController, willAdd layer: Layer) -> Layer? {
        guard var lineLayer = layer as? LineLayer else { return nil }
        if lineLayer.id.contains("alternative.route_line") {
            lineLayer.lineWidth = .expression(
                Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.zoom)
                    RouteLineWidthByZoomLevel.multiplied(by: 0.7)
                }
            )
        }
        if lineLayer.id.contains("alternative.route_line_casing") {
            lineLayer.lineWidth = .expression(
                Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.zoom)
                    RouteLineWidthByZoomLevel
                }
            )
        }
        return lineLayer
    }

    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        if let delegate = UIApplication.shared.delegate as? AppDelegate,
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
