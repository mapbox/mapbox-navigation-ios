import Combine
import CoreLocation
import MapboxDirections
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

class ViewController: UIViewController {
    @IBOutlet var mapHostView: UIView!
    @IBOutlet var longPressHintView: UIView!
    @IBOutlet var simulationButton: UIButton!
    @IBOutlet var startButton: UIButton!
    @IBOutlet var clearMap: UIButton!

    let feedbackButton: FloatingButton = {
        let image = UIImage(named: "feedback", in: .mapboxNavigation, compatibleWith: nil)!
        let button = FloatingButton.rounded(image: image.withRenderingMode(.alwaysTemplate))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
        return button
    }()

    var speedLimitView: SpeedLimitView!

    var currentEdgeIdentifier: RoadGraph.Edge.Identifier?
    var nextEdgeIdentifier: RoadGraph.Edge.Identifier?

    typealias ActionHandler = (UIAlertAction) -> Void

    var navigationMapView: NavigationMapView! {
        didSet {
            if let navigationMapView = oldValue {
                uninstall(navigationMapView)
            }

            if let navigationMapView {
                mapHostView.addSubview(navigationMapView)
                configure(navigationMapView)
            }
        }
    }

    private var lifetimeSubscriptions: Set<AnyCancellable> = []
    private var currentLocation: CLLocation? {
        navigationProvider.navigation().currentLocationMatching?.location
    }

    var styleManager = StyleManager()

    var waypoints: [Waypoint] = []

    var currentRoute: Route? {
        routes?.mainRoute.route
    }

    var requestMapMatching = false

    var routes: NavigationRoutes? {
        didSet {
            guard let routes else {
                clearNavigationMapView(endNavigation: false)
                return ()
            }
            waypoints = routes.mainRoute.route.legs.compactMap { $0.destination }
            showCurrentRoute(routes)
        }
    }

    func showCurrentRoute(_ routes: NavigationRoutes) {
        guard let navigationMapView else { return }

        longPressHintView.isHidden = true
        navigationMapView.showsRestrictedAreasOnRoute = true
        navigationMapView.showcase(routes)

        startButton.isEnabled = true
        clearMap.isHidden = false

        updateCarPlayRoutesPreview()
    }

    weak var activeNavigationViewController: NavigationViewController?

    var profileIdentifier: ProfileIdentifier = .automobileAvoidingTraffic {
        didSet {
            navigationMapView.puckBearing = puckBearing
        }
    }

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

    // MARK: - UIViewController lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSpeedLimitView()
        view.addSubview(speedLimitView)
        setupFeedbackButton()

        core.tripSession().startFreeDrive()
    }

    func setupSpeedLimitView() {
        let speedLimitView = SpeedLimitView()
        speedLimitView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(speedLimitView)
        speedLimitView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        speedLimitView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        speedLimitView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        speedLimitView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10)
            .isActive = true

        self.speedLimitView = speedLimitView
    }

    func setupFeedbackButton() {
        view.addSubview(feedbackButton)
        feedbackButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 62).isActive = true
        feedbackButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12)
            .isActive = true
        feedbackButton.addTarget(self, action: #selector(feedback(_:)), for: .touchUpInside)
    }

    var navigation: NavigationController {
        core.navigation()
    }

    var core: MapboxNavigation {
        navigationProvider.mapboxNavigation
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if navigationMapView == nil {
            navigationMapView = NavigationMapView(
                location: navigation.locationMatching.map(\.enhancedLocation).eraseToAnyPublisher(),
                routeProgress: navigation.routeProgress.map(\.?.routeProgress).eraseToAnyPublisher(),
                heading: navigation.heading.eraseToAnyPublisher(),
                predictiveCacheManager: navigationProvider.predictiveCacheManager
            )
            navigationMapView.mapView.mapboxMap.onStyleLoaded
                .sink { [weak self] _ in
                    self?.navigationMapView.localizeLabels()
                }
                .store(in: &lifetimeSubscriptions)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        requestNotificationCenterAuthorization()
    }

    private func configure(_ navigationMapView: NavigationMapView) {
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
        navigationMapView.puckType = .puck3D(.navigationDefault)
        navigationMapView.puckBearing = puckBearing

        setupStyleManager()
        setupPerformActionBarButtonItem()
        if let cameraState = activeNavigationViewController?.navigationMapView?.mapView.mapboxMap.cameraState {
            navigationMapView.mapView.camera.fly(
                to: .init(
                    center: cameraState.center,
                    zoom: cameraState.zoom
                ),
                duration: 0,
                completion: nil
            )
        }
    }

    private func setupStyleManager() {
        styleManager.delegate = self
        styleManager.styles = [StandardDayStyle(), StandardNightStyle()]
        let styleType: StyleType = traitCollection.userInterfaceStyle == .dark ? .night : .day
        styleManager.applyStyle(type: styleType)
    }

    override open func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        if newCollection.userInterfaceStyle == .dark {
            styleManager.applyStyle(type: .night)
        } else {
            styleManager.applyStyle(type: .day)
        }
    }

    private func uninstall(_ navigationMapView: NavigationMapView) {
        navigationMapView.removeFromSuperview()
    }

    private func clearNavigationMapView(endNavigation: Bool) {
        Task { @MainActor in
            startButton.isEnabled = false
            clearMap.isHidden = true
            longPressHintView.isHidden = false

            navigationMapView?.removeRoutes()

            waypoints.removeAll()
            navigationMapView?.navigationCamera.update(cameraState: .following)
            if !endNavigation {
                updateCarPlayRoutesPreview()
            }

            core.tripSession().startFreeDrive()
            navigationProvider.apply(coreConfig: .init(
                locationSource: .live
            ))
        }
    }

    private func updateCarPlayRoutesPreview() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }
        Task {
            if let routes {
                await delegate.carPlayManager.previewRoutes(for: routes)
            } else {
                await delegate.carPlayManager.cancelRoutesPreview()
            }
        }
    }

    func requestNotificationCenterAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { _, _ in
            DispatchQueue.main.async {
                CLLocationManager().requestWhenInUseAuthorization()
            }
        }
    }

    @IBAction
    func simulateButtonPressed(_: Any) {
        simulationButton.isSelected = !simulationButton.isSelected
    }

    @IBAction
    func clearMapPressed(_: Any) {
        routes = nil
    }

    @IBAction
    func startButtonPressed(_: Any) {
        presentActionsAlertController()
    }

    @objc
    func feedback(_: Any) {
        let eventsManager = navigationProvider.eventsManager()
        let feedbackViewController = FeedbackViewController(eventsManager: eventsManager, type: .passiveNavigation)
        present(feedbackViewController, animated: true)
    }

    // MARK: - CarPlay navigation methods

    public func beginNavigationWithCarPlay(navigationRoutes: NavigationRoutes) {
        let navigationViewController = activeNavigationViewController ??
            navigationViewController(with: navigationRoutes)

        guard activeNavigationViewController == nil else {
            activeNavigationViewController?.didConnectToCarPlay()
            return
        }

        presentAndRemoveNavigationMapView(navigationViewController) {
            navigationViewController.didConnectToCarPlay()
        }
    }

    func beginCarPlayNavigation() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return }

        if let currentLocation, delegate.carPlayManager.currentActivity != .navigating {
            delegate.carPlayManager.beginNavigationWithCarPlay(using: currentLocation.coordinate)
        }
    }

    private var puckBearing: PuckBearing {
        switch profileIdentifier {
        case .automobile, .automobileAvoidingTraffic, .cycling:
            .course
        case .walking:
            .heading
        default:
            .course
        }
    }

    private func presentActionsAlertController() {
        let title: String? = switch profileIdentifier {
        case .automobile:
            drivingProfileText
        case .automobileAvoidingTraffic:
            drivingAvoidingTrafficProfileText
        case .cycling:
            cyclingProfileText
        case .walking:
            walkingProfileText
        default:
            NSLocalizedString("Start Navigation", comment: "")
        }

        let alertController = UIAlertController(
            title: title,
            message: "Select the navigation type",
            preferredStyle: .actionSheet
        )

        let basic: ActionHandler = { _ in self.startBasicNavigation() }
        let day: ActionHandler = { _ in self.startNavigation(styles: [StandardDayStyle()]) }
        let night: ActionHandler = { _ in self.startNavigation(styles: [StandardNightStyle()]) }
        let styled: ActionHandler = { _ in self.startStyledNavigation() }

        let actionPayloads: [(String, UIAlertAction.Style, ActionHandler?)] = [
            ("Default UI", .default, basic),
            ("DayStyle UI", .default, day),
            ("NightStyle UI", .default, night),
            ("Styled UI", .default, styled),
            ("Cancel", .cancel, nil),
        ]

        actionPayloads
            .map { payload in UIAlertAction(title: payload.0, style: payload.1, handler: payload.2) }
            .forEach(alertController.addAction(_:))

        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = startButton
            popoverController.sourceRect = startButton.bounds
        }

        present(alertController, animated: true, completion: nil)
    }

    // MARK: - Active guidance navigation methods.

    func startNavigation(styles: [Style]) {
        guard let routes else { return }

        let navigationViewController = navigationViewController(with: routes, styles: styles)
        presentAndRemoveNavigationMapView(navigationViewController, completion: beginCarPlayNavigation)
    }

    func navigationViewController(
        with routes: NavigationRoutes,
        styles: [Style]? = nil,
        topBanner: ContainerViewController? = nil,
        bottomBanner: ContainerViewController? = nil
    ) -> NavigationViewController {
        let locationSource: LocationSource = simulationButton.isSelected ?
            .simulation(initialLocation: currentLocation) : .live
        navigationProvider.apply(coreConfig: .init(
            locationSource: locationSource
        ))
        let navigationOptions = NavigationOptions(
            mapboxNavigation: navigationProvider.mapboxNavigation,
            voiceController: navigationProvider.routeVoiceController,
            eventsManager: navigationProvider.eventsManager(),
            styles: styles,
            topBanner: topBanner,
            bottomBanner: bottomBanner
        )
        let navigationViewController = NavigationViewController(
            navigationRoutes: routes,
            navigationOptions: navigationOptions
        )
        navigationViewController.delegate = self
        navigationViewController.usesNightStyleInDarkMode = true
        return navigationViewController
    }

    func startBasicNavigation() {
        guard let routes else { return }

        let navigationViewController = navigationViewController(with: routes)

        // Render part of the route that has been traversed with full transparency, to give the illusion of a
        // disappearing route.
        navigationViewController.routeLineTracksTraversal = true

        // Control floating buttons position in a navigation view.
        navigationViewController.floatingButtonsPosition = .topTrailing

        presentAndRemoveNavigationMapView(
            navigationViewController,
            animated: false,
            completion: beginCarPlayNavigation
        )
    }

    func startStyledNavigation() {
        guard let routes else { return }

        let styles = [CustomDayStyle(), CustomNightStyle()]
        let navigationViewController = navigationViewController(with: routes, styles: styles)
        navigationViewController.delegate = self

        presentAndRemoveNavigationMapView(navigationViewController, completion: beginCarPlayNavigation)
    }

    func setupPerformActionBarButtonItem() {
        let settingsBarButtonItem = UIBarButtonItem(
            title: NSString(string: "\u{2699}\u{0000FE0E}") as String,
            style: .plain,
            target: self,
            action: #selector(performAction)
        )
        settingsBarButtonItem.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 30)], for: .normal)
        settingsBarButtonItem.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 30)], for: .highlighted)
        navigationItem.rightBarButtonItem = settingsBarButtonItem
    }

    @objc
    func performAction(_: Any) {
        let alertController = UIAlertController(
            title: "Perform action",
            message: "Select specific action to perform it",
            preferredStyle: .actionSheet
        )

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
            (
                requestMapMatching ? "Enable Routing Requesting" : "Enable Map Match Requesting",
                .default,
                toggleMapMatching
            ),
            ("Cancel", .cancel, nil),
        ]

        actions
            .map { payload in UIAlertAction(title: payload.0, style: payload.1, handler: payload.2) }
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
        navigationMapView.navigationCamera.update(cameraState: .following)
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
        navigationProvider.mapboxNavigation.historyRecorder()?.startRecordingHistory()
    }

    func turnOffHistoryRecording() {
        navigationProvider.mapboxNavigation.historyRecorder()?.stopRecordingHistory { historyFileUrl in
            guard let historyFileUrl else { return }
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
        guard let currentLocation else {
            print("User location is not valid. Make sure to enable Location Services.")
            return
        }

        var userWaypoint = Waypoint(location: currentLocation)
        if currentLocation.course >= 0 {
            userWaypoint.heading = currentLocation.course
            userWaypoint.headingAccuracy = 90
        }
        asyncRequestRoute(with: [userWaypoint] + waypoints)
    }

    func asyncRequestRoute(with waypoints: [Waypoint]) {
        Task {
            let provider = core.routingProvider()
            do {
                if requestMapMatching {
                    let optionWaypoints = waypoints.map {
                        var waypoint = $0
                        waypoint.heading = nil
                        return waypoint
                    }
                    let mapMatchingOptions = NavigationMatchOptions(
                        waypoints: optionWaypoints,
                        profileIdentifier: profileIdentifier
                    )
                    let navigationRoutes = try await provider.calculateRoutes(options: mapMatchingOptions).value
                    routes = navigationRoutes
                } else {
                    let routeOptions = NavigationRouteOptions(
                        waypoints: waypoints,
                        profileIdentifier: profileIdentifier
                    )
                    let navigationRoutes = try await provider.calculateRoutes(options: routeOptions).value
                    routes = navigationRoutes
                }
            } catch {
                routes = nil
                presentAlert(message: error.localizedDescription)
            }
        }
    }

    func presentAndRemoveNavigationMapView(
        _ navigationViewController: NavigationViewController,
        animated: Bool = true,
        completion: CompletionHandler? = nil
    ) {
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
            self.navigationMapView = nil
            navigationViewController.navigationMapView?.showsRestrictedAreasOnRoute = true

            // Animate top and bottom banner views presentation.
            navigationViewController.navigationView.bottomBannerContainerView.show(
                duration: 1.0,
                animations: {
                    navigationViewController
                        .navigationView.wayNameView
                        .alpha = 1.0
                    navigationViewController
                        .navigationView
                        .floatingStackView
                        .alpha =
                        1.0
                    navigationViewController
                        .navigationView
                        .speedLimitView.alpha = 1.0
                }
            )
            navigationViewController.navigationView.topBannerContainerView.show(duration: 1.0)
        }
    }

    func endCarPlayNavigation(canceled: Bool) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.carPlayManager.carPlayNavigationViewController?.exitNavigation(byCanceling: canceled)
        }
    }

    func dismissActiveNavigationViewController(animated: Bool = false) {
        guard let activeNavigationViewController else { return }

        activeNavigationViewController.navigationView.bottomBannerContainerView.hide(duration: 1.0)
        activeNavigationViewController.navigationView.topBannerContainerView.hide(
            duration: 1.0,
            animations: {
                activeNavigationViewController
                    .navigationView.wayNameView
                    .alpha = 0.0
                activeNavigationViewController
                    .navigationView
                    .floatingStackView
                    .alpha =
                    0.0
                activeNavigationViewController
                    .navigationView.speedLimitView
                    .alpha = 0.0
            },
            completion: { _ in
                activeNavigationViewController
                    .dismiss(animated: animated) {
                        self
                            .activeNavigationViewController =
                            nil
                    }
            }
        )
    }

    // MARK: - Utility methods

    func presentAlert(_ title: String? = nil, message: String? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            alertController.dismiss(animated: true, completion: nil)
        }))

        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - NavigationMapViewDelegate methods

extension ViewController: NavigationMapViewDelegate {
    func navigationMapView(_: NavigationMapView, didSelect alternativeRoute: AlternativeRoute) {
        Task {
            routes = await routes?.selecting(alternativeRoute: alternativeRoute)
        }
    }

    func navigationMapView(_: NavigationMapView, didSelect waypoint: Waypoint) {
        let waypointsWithoutSpecified = waypoints.filter { $0 != waypoint }
        presentWaypointRemovalAlert { [weak self] _ in
            self?.waypoints = waypointsWithoutSpecified
            self?.requestRoute()
        }
    }

    func navigationMapView(_: NavigationMapView, userDidTap mapPoint: MapPoint) {
        requestRoute(to: mapPoint)
    }

    func navigationMapView(_: NavigationMapView, userDidLongTap mapPoint: MapPoint) {
        requestRoute(to: mapPoint)
    }

    private func requestRoute(to mapPoint: MapPoint) {
        waypoints.append(Waypoint(coordinate: mapPoint.coordinate, name: mapPoint.name))
        requestRoute()
    }

    private func presentWaypointRemovalAlert(completionHandler approve: @escaping ((UIAlertAction) -> Void)) {
        let title = NSLocalizedString(
            "REMOVE_WAYPOINT_CONFIRM_TITLE",
            value: "Remove Waypoint?",
            comment: "Title of alert confirming waypoint removal"
        )

        let message = NSLocalizedString(
            "REMOVE_WAYPOINT_CONFIRM_MSG",
            value: "Do you want to remove this waypoint?",
            comment: "Message of alert confirming waypoint removal"
        )

        let removeTitle = NSLocalizedString(
            "REMOVE_WAYPOINT_CONFIRM_REMOVE",
            value: "Remove Waypoint",
            comment: "Title of alert action for removing a waypoint"
        )

        let cancelTitle = NSLocalizedString(
            "REMOVE_WAYPOINT_CONFIRM_CANCEL",
            value: "Cancel",
            comment: "Title of action for dismissing waypoint removal confirmation sheet"
        )

        let waypointRemovalAlertController = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )

        let removeAction = UIAlertAction(
            title: removeTitle,
            style: .destructive,
            handler: approve
        )

        let cancelAction = UIAlertAction(
            title: cancelTitle,
            style: .cancel,
            handler: nil
        )

        [removeAction, cancelAction].forEach(waypointRemovalAlertController.addAction(_:))

        present(waypointRemovalAlertController, animated: true, completion: nil)
    }
}

// MARK: - NavigationViewControllerDelegate methods

extension ViewController: NavigationViewControllerDelegate {
    // To modify the width of the alternative route line layer through delegate methods.
    func navigationViewController(
        _ navigationViewController: NavigationViewController,
        willAdd layer: Layer
    ) -> Layer? {
        guard var lineLayer = layer as? LineLayer,
              lineLayer.id.contains("route_line.alternative") else { return nil }
        if lineLayer.id.contains("casing") {
            lineLayer.lineWidth = .expression(
                Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.zoom)
                    RouteLineWidthByZoomLevel
                }
            )
        } else {
            lineLayer.lineWidth = .expression(
                Exp(.interpolate) {
                    Exp(.linear)
                    Exp(.zoom)
                    RouteLineWidthByZoomLevel.multiplied(by: 0.7)
                }
            )
        }
        return lineLayer
    }

    func navigationViewControllerDidDismiss(_: NavigationViewController, byCanceling canceled: Bool) {
        endCarPlayNavigation(canceled: canceled)
        dismissActiveNavigationViewController()
        clearNavigationMapView(endNavigation: true)
    }
}
