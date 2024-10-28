import AVFoundation
import MapboxCoreMaps
import MapboxDirections
import MapboxMaps
import MapboxNavigationCore
import MobileCoreServices
import Turf
import UIKit
import UserNotifications

/// A container view controller is a view controller that behaves as a navigation component; that is, it responds as the
/// user progresses along a route according to the ``NavigationComponent`` protocol.
public typealias ContainerViewController = NavigationComponent & UIViewController

/// ``NavigationViewController`` is a fully-featured user interface for turn-by-turn navigation. Do not confuse it with
/// the `NavigationController` class in UIKit.
///
/// You initialize a navigation view controller based on a predefined `NavigationRoutes` and ``NavigationOptions``. As
/// the user progresses along the route, the navigation view controller shows their surroundings and the route line on a
/// map. Banners above and below the map display key information pertaining to the route. A list of steps and a feedback
/// mechanism are accessible via the navigation view controller.
///
/// Route initialization should be configured before view controller's `view` is loaded. Usually, that is automatically
/// done during any of the `init`s, but you may also change this settings via
/// ``prepareViewLoading(navigationRoutes:navigationOptions:)`` methods. For example that could be handy while
/// configuring a ViewController for a `UIStoryboardSegue`.
///
/// To be informed of significant events and decision points as the user progresses along the route, set the
/// ``delegate`` property to the ``NavigationViewControllerDelegate``.
/// ``CarPlayNavigationViewController`` manages the corresponding user interface on a CarPlay screen.
///
/// - important: Creating an instance of this type with will start an Active Guidance session. The trip session is
/// stopped when the instance is deallocated. For more info read the
/// [Pricing Guide](https://docs.mapbox.com/ios/navigation/guides/pricing/).

open class NavigationViewController: UIViewController, NavigationStatusPresenter, NavigationViewData {
    // MARK: Accessing the View Hierarchy

    ///  The `NavigationMapView` displayed inside the view controller.
    ///
    /// - note: Do not change `NavigationMapView.delegate` property; instead, implement the corresponding methods on
    /// ``NavigationViewControllerDelegate``.
    @objc public var navigationMapView: NavigationMapView? {
        get {
            return navigationView.navigationMapView
        }

        set {
            guard let validNavigationMapView = newValue else {
                preconditionFailure("Invalid NavigationMapView instance.")
            }

            validNavigationMapView.delegate = self
            validNavigationMapView.navigationCamera.update(cameraState: .following)

            navigationView.navigationMapView = validNavigationMapView
        }
    }

    func setupNavigationCamera() {
        // By default `NavigationCamera` in active guidance navigation should be set to
        // `NavigationCameraState.following` state.
        navigationMapView?.navigationCamera.update(cameraState: .following)
    }

    /// ``NavigationView``, that is displayed inside the view controller.
    public var navigationView: NavigationView {
        return (view as! NavigationView)
    }

    /// Controls whether the main route style layer and its casing disappears as the user location puck travels over it.
    /// Defaults to `false`.
    ///
    /// If `true`, the part of the route that has been traversed will be rendered with full transparency, to give the
    /// illusion of a disappearing route.
    public var routeLineTracksTraversal: Bool {
        get {
            navigationMapView?.routeLineTracksTraversal ?? false
        }
        set {
            navigationMapView?.routeLineTracksTraversal = newValue
        }
    }

    /// A Boolean value that determines whether the map annotates the intersections on current step during active
    /// navigation.
    ///
    /// If `true`, the map would display an icon of a traffic control device on the intersection, such as traffic
    /// signal, stop sign, yield sign, or railroad crossing.
    /// Defaults to `true`.
    public var annotatesIntersectionsAlongRoute: Bool {
        get {
            navigationMapView?.showsIntersectionAnnotations ?? true
        }
        set {
            navigationMapView?.showsIntersectionAnnotations = newValue
        }
    }

    /// Toggles displaying alternative routes.
    ///
    /// If enabled, view will draw actual alternative route lines on the map.
    /// Default value is `true`.
    public var showsContinuousAlternatives: Bool {
        get { navigationMapView?.showsAlternatives ?? true }
        set { navigationMapView?.showsAlternatives = newValue }
    }

    /// `AlternativeRoute`s user might take during this trip to reach the destination using another road.
    ///
    /// Array contents are updated automatically duting the trip. Alternative routes may be slower or longer then the
    /// main route.
    /// To get updates, subscribe to
    /// ``NavigationViewControllerDelegate/navigationViewController(_:didUpdateAlternatives:removedAlternatives:)``.
    public private(set) var continuousAlternatives: [AlternativeRoute] = []

    // MARK: Configuring Spoken Instructions

    /// The voice controller that vocalizes spoken instructions along the route at the appropriate times.
    public var voiceController: RouteVoiceController?

    func setupVoiceController() {
        voiceController = navigationOptions?.voiceController
    }

    /// A Boolean value that determines whether the map annotates the locations at which instructions are spoken for
    /// debugging purposes.
    ///
    /// Defaults to `false`.
    public var annotatesSpokenInstructions: Bool {
        get {
            navigationMapView?.showsVoiceInstructionsOnMap ?? false
        }
        set {
            navigationMapView?.showsVoiceInstructionsOnMap = newValue
        }
    }

    /// Controls whether night style will be used whenever traversing through a tunnel. Defaults to `true`.
    public var usesNightStyleWhileInTunnel: Bool = true

    // MARK: Setting Route and Navigation Experience

    /// The ``NavigationOptions`` object, which is used for the navigation session.
    public var navigationOptions: NavigationOptions?

    /// The route options used to get the route.
    public var routeOptions: RouteOptions? {
        navigationRoutes?.mainRoute.routeOptions
    }

    var _routeOptions: RouteOptions?

    // MARK: Traversing the Route

    var _navigationRoutes: NavigationRoutes?
    /// A `NavigationRoutes` object constructed by `MapboxNavigation`.
    ///
    /// In cases where you need to update the route after navigation has started, you can set a new route using
    /// `MapboxNavigation.tripSession().startActiveGuidance(with:, startLegIndex:)` and ``NavigationViewController``
    /// will update its UI accordingly.
    public var navigationRoutes: NavigationRoutes? {
        mapboxNavigation.tripSession().currentNavigationRoutes
    }

    /// A `Route` object constructed by `MapboxNavigation`.
    public var route: Route? {
        navigationRoutes?.mainRoute.route
    }

    /// Equals to `MapboxNavigation.routingProvider()`.
    public var routingProvider: RoutingProvider {
        mapboxNavigation.routingProvider()
    }

    /// The navigation service that coordinates the view controller’s nonvisual components, tracking the user’s location
    /// as they proceed along the route.
    public var mapboxNavigation: MapboxNavigation {
        guard let options = navigationOptions else {
            preconditionFailure(
                "'NavigationOptions' is nil. Provide the non-nil options using 'prepareViewLoading(navigationRoutes:navigationOptions:)'."
            )
        }

        return options.mapboxNavigation
    }

    private var subscriptions: Set<AnyCancelable> = []

    lazy var overviewButton: FloatingButton = {
        let floatingButton = FloatingButton.rounded(image: .overviewImage)
        floatingButton.borderWidth = Style.defaultBorderWidth

        return floatingButton
    }()

    lazy var muteButton: FloatingButton = {
        let floatingButton = FloatingButton.rounded(
            image: .volumeUpImage,
            selectedImage: .volumeOffImage
        )
        floatingButton.borderWidth = Style.defaultBorderWidth

        return floatingButton
    }()

    lazy var reportButton: FloatingButton = {
        let floatingButton = FloatingButton.rounded(image: .feedbackImage)
        floatingButton.borderWidth = Style.defaultBorderWidth

        return floatingButton
    }()

    func setupNavigation() {
        guard let navigationRoutes = _navigationRoutes
        else {
            fatalError(
                "`navigationRoutes` and `routeOptions` must be valid to create an instance of `NavigationViewController`."
            )
        }

        subscribeMapboxNavigation()

        setupControllers(navigationOptions)
        setupStyleManager(navigationOptions)

        viewObservers.forEach {
            $0?.navigationViewDidLoad(view)
        }

        // Start the navigation service on presentation.
        mapboxNavigation.tripSession().startActiveGuidance(with: navigationRoutes, startLegIndex: 0)
        // TODO: setup simulation here if needed
    }

    /// Toggles sending of UILocalNotification upon upcoming steps when application is in the background.
    /// Defaults to `true`.
    public var sendsNotifications: Bool = true

    var tunnelAuthority: TunnelAuthority = .liveValue
    private var isTraversingTunnel = false

    // MARK: View Lifecycle and Events

    /// The receiver’s delegate.
    public weak var delegate: NavigationViewControllerDelegate?

    /// If `true`, `UIApplication.isIdleTimerDisabled` is set to `true` in `viewWillAppear(_:)` and `false` in
    /// `viewWillDisappear(_:)`. If your application manages the idle timer itself, set this property to `false`.
    public var shouldManageApplicationIdleTimer = true {
        didSet {
            updateIdleTimerIfNeeded()
        }
    }

    private var idleTimerCancellable: IdleTimerManager.Cancellable?
    private var isViewVisible: Bool = false {
        didSet {
            updateIdleTimerIfNeeded()
        }
    }

    private func updateIdleTimerIfNeeded() {
        if !isViewVisible {
            idleTimerCancellable = nil
        } else if shouldManageApplicationIdleTimer {
            idleTimerCancellable = IdleTimerManager.shared.disableIdleTimer()
        }
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// Initializes a ``NavigationViewController`` with the given route and navigation options.
    /// - Parameters:
    ///   - navigationRoutes: `NavigationRoutes` object, containing selection of routes to follow.
    ///   - navigationOptions: The navigation options to use for the navigation session.
    public required init(navigationRoutes: NavigationRoutes, navigationOptions: NavigationOptions) {
        super.init(nibName: nil, bundle: nil)

        _ = prepareViewLoading(
            navigationRoutes: navigationRoutes,
            navigationOptions: navigationOptions
        )
    }

    deinit {
        guard let mapboxNavigation = navigationOptions?.mapboxNavigation else { return }
        Task { @MainActor in
            Self.setToIdle(with: mapboxNavigation)
        }
    }

    @MainActor
    override open func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        Self.setToIdle(with: navigationOptions?.mapboxNavigation)
        super.dismiss(animated: flag, completion: completion)
    }

    @MainActor
    private static func setToIdle(with mapboxNavigation: MapboxNavigation?) {
        guard let mapboxNavigation,
              case .activeGuidance = mapboxNavigation.tripSession().currentSession.state else { return }
        mapboxNavigation.tripSession().setToIdle()
    }

    override open func loadView() {
        let frame = parent?.view.bounds ?? UIScreen.main.bounds
        let mapViewConfiguration: NavigationView.MapViewConfiguration = switch navigationOptions?.navigationMapView {
        case .none:
            .createNew(
                location: mapboxNavigation.navigation()
                    .locationMatching.map(\.enhancedLocation)
                    .eraseToAnyPublisher(),
                routeProgress: mapboxNavigation.navigation()
                    .routeProgress.map(\.?.routeProgress)
                    .eraseToAnyPublisher(),
                heading: isWalkingProfile ? mapboxNavigation.navigation().heading.eraseToAnyPublisher() : nil,
                predictiveCacheManager: navigationOptions?.predictiveCacheManager
            )
        case .some(let navigationMapView):
            .existing(navigationMapView)
        }
        let navigationView = NavigationView(delegate: self, frame: frame, mapViewConfiguration: mapViewConfiguration)
        navigationView.delegate = self
        navigationView.navigationMapView.delegate = self
        navigationView.navigationMapView.puckBearing = isWalkingProfile ? .heading : .course
        view = navigationView

        navigationView.floatingButtons = [
            overviewButton,
            muteButton,
            reportButton,
        ]
    }

    private var isWalkingProfile: Bool {
        _navigationRoutes?.mainRoute.routeOptions?.profileIdentifier == .walking
    }

    // Array of initialization hooks to be called at `NavigationViewController.viewDidLoad`.
    //
    // Once main view is loaded, an active guidance session starts, and each UI component should be ready to accept
    // navigation events and updates. At the same time, various components require embedding, which triggers main view
    // initialization, which triggers session start. To break this cycle, wrap any custom subview configuration here, to
    // avoid triggering main view initialization before it is required.
    private var subviewInits: [() -> Void] = []

    override open func viewDidLoad() {
        super.viewDidLoad()

        view.clipsToBounds = true

        setupNavigation()
        setupVoiceController()
        setupNavigationCamera()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewObservers.forEach {
            $0?.navigationViewWillAppear(animated)
        }
    }

    override open func willTransition(
        to newCollection: UITraitCollection,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        if usesNightStyleInDarkMode {
            transitionStyle(to: newCollection)
        }
    }

    /// Shows a Status for a specified amount of time.
    public func show(_ status: StatusView.Status) {
        navigationComponents.compactMap { $0 as? NavigationStatusPresenter }.forEach {
            $0.show(status)
        }
    }

    /// Hides a given Status without hiding the status view.
    public func hide(_ status: StatusView.Status) {
        navigationComponents.compactMap { $0 as? NavigationStatusPresenter }.forEach {
            $0.hide(status)
        }
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        isViewVisible = true
        viewObservers.forEach {
            $0?.navigationViewDidAppear(animated)
        }

        let padding = UIEdgeInsets(
            top: topViewController?.view.bounds.height ?? 0.0,
            left: 0.0,
            bottom: bottomViewController?.view.bounds.height ?? 0.0 + navigationView.wayNameView.bounds.height,
            right: floatingButtons?.max {
                $0.bounds.width < $1.bounds.width
            }?.bounds.width ?? 0.0
        )
        navigationMapView?.navigationCamera.viewportPadding += padding
    }

    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewObservers.forEach {
            $0?.navigationViewWillDisappear(animated)
        }
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        isViewVisible = false
        viewObservers.forEach {
            $0?.navigationViewDidDisappear(animated)
        }
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        viewObservers.forEach {
            $0?.navigationViewDidLayoutSubviews()
        }
    }

    override open func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        arrivalController?.updatePreferredContentSize(container.preferredContentSize)
    }

    /// Updates key settings before loading the view.
    ///
    /// This method basically re-runs the setup which takes place in `init`. It could be useful if some of the
    /// attributes have changed before ``NavigationViewController`` did load it's view, or if you did not have access to
    /// initializing logic. For example, as a part of `UIStoryboardSegue` configuration.
    ///
    /// - Parameters:
    ///   - navigationRoutes: `NavigationRoutes` object, containing selection of routes to follow.
    ///   - navigationOptions: The navigation options to use for the navigation session.
    /// - Returns: `true` if setup was successful, `false` if `view` is already loaded and settings did not apply.
    public func prepareViewLoading(
        navigationRoutes: NavigationRoutes?,
        navigationOptions: NavigationOptions? = nil
    ) -> Bool {
        guard !isViewLoaded else {
            return false
        }

        _navigationRoutes = navigationRoutes

        if let navigationOptions {
            self.navigationOptions = navigationOptions
        }

        return true
    }

    fileprivate func handleCancelAction() {
        if delegate?.navigationViewControllerDidDismiss(self, byCanceling: true) != nil {
            // The receiver should handle dismissal of the NavigationViewController
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    // MARK: Customizing Views and Child View Controllers

    /// Shows a button that allows drivers to report feedback such as accidents, closed roads, poor instructions, etc.
    /// Defaults to `true`.
    public var showsReportFeedback: Bool = true {
        didSet {
            loadViewIfNeeded()
            reportButton.isHidden = !showsReportFeedback
            showsEndOfRouteFeedback = showsReportFeedback
        }
    }

    /// Shows End of route Feedback UI when the route controller arrives at the final destination.
    ///
    /// Defaults to `true`.
    public var showsEndOfRouteFeedback: Bool {
        get {
            loadViewIfNeeded()
            return arrivalController?.showsEndOfRoute ?? false
        }
        set {
            loadViewIfNeeded()
            arrivalController?.showsEndOfRoute = newValue
        }
    }

    /// Shows the current speed limit on the map view.
    ///
    /// The default value of this property is `true`.
    public var showsSpeedLimits: Bool {
        get {
            loadViewIfNeeded()
            return ornamentsController?.showsSpeedLimits ?? false
        }
        set {
            loadViewIfNeeded()
            ornamentsController?.showsSpeedLimits = newValue
        }
    }

    var containerViewController: UIViewController {
        return self
    }

    var topViewController: ContainerViewController?

    var bottomViewController: ContainerViewController?

    var arrivalController: ArrivalController?
    var ornamentsController: OrnamentsController?
    var viewObservers: [NavigationComponentDelegate?] = []

    func setupControllers(_ navigationOptions: NavigationOptions?) {
        arrivalController = ArrivalController(self, eventsManager: navigationOptions?.eventsManager)
        ornamentsController = navigationOptions.map { OrnamentsController(self, eventsManager: $0.eventsManager) }

        viewObservers = [
            ornamentsController,
            arrivalController,
        ]

        subviewInits.append { [weak self] in
            if let topBannerViewController = self?.addTopBanner(navigationOptions),
               let bottomBannerViewController = self?.addBottomBanner(navigationOptions)
            {
                self?.ornamentsController?.embedBanners(
                    topBannerViewController: topBannerViewController,
                    bottomBannerViewController: bottomBannerViewController
                )
            }
        }

        subviewInits.forEach {
            $0()
        }
        subviewInits.removeAll()

        arrivalController?.destination = route?.legs.last?.destination
        reportButton.isHidden = !showsReportFeedback
    }

    func addTopBanner(_ navigationOptions: NavigationOptions?) -> ContainerViewController {
        let topBanner = navigationOptions?.topBanner ?? {
            let viewController: TopBannerViewController = .init()
            viewController.delegate = self
            viewController.statusView.addTarget(
                self,
                action: #selector(NavigationViewController.didChangeSpeed(_:)),
                for: .valueChanged
            )

            return viewController
        }()

        topViewController = topBanner

        return topBanner
    }

    func addBottomBanner(_ navigationOptions: NavigationOptions?) -> ContainerViewController {
        let bottomBanner = navigationOptions?.bottomBanner ?? {
            let viewController: BottomBannerViewController = .init()
            viewController.delegate = self

            return viewController
        }()

        bottomViewController = bottomBanner

        return bottomBanner
    }

    /// The position of floating buttons in a navigation view. The default value is ``MapOrnamentPosition/topTrailing``.
    open var floatingButtonsPosition: MapOrnamentPosition? {
        get {
            // Force `NavigationViewController` to call `viewDidLoad()` method, which will in turn
            // create other controllers (including `OrnamentsController`).
            loadViewIfNeeded()
            return ornamentsController?.floatingButtonsPosition
        }
        set {
            ornamentsController?.floatingButtonsPosition = newValue
        }
    }

    /// The floating buttons in an array of UIButton in navigation view. The default floating buttons include the
    /// overview, mute and feedback report button. The default type of the floatingButtons is ``FloatingButton``, which
    /// is declared with ``FloatingButton/rounded(image:selectedImage:size:type:imageEdgeInsets:cornerRadius:)`` to be
    /// consistent.
    open var floatingButtons: [UIButton]? {
        get {
            loadViewIfNeeded()
            return ornamentsController?.floatingButtons
        }
        set {
            loadViewIfNeeded()
            ornamentsController?.floatingButtons = newValue
        }
    }

    var navigationComponents: [NavigationComponent] {
        var components: [NavigationComponent] = []

        if let topViewController {
            components.append(topViewController)
        }

        if let bottomViewController {
            components.append(bottomViewController)
        }

        return components
    }

    // MARK: Styling the Layout

    /// If true, the map style and UI will automatically be updated given the time of day.
    public var automaticallyAdjustsStyleForTimeOfDay = true {
        didSet {
            styleManager?.automaticallyAdjustsStyleForTimeOfDay = automaticallyAdjustsStyleForTimeOfDay
        }
    }

    /// Controls whether night style will be used whenever dark mode is enabled. Defaults to `false`.
    public var usesNightStyleInDarkMode: Bool = false

    /// Controls the styling of NavigationViewController and its components.
    ///
    /// The style can be modified programmatically by using ``StyleManager/applyStyle(type:)``.
    public private(set) var styleManager: StyleManager!

    func setupStyleManager(_ navigationOptions: NavigationOptions?) {
        styleManager = StyleManager()
        styleManager.automaticallyAdjustsStyleForTimeOfDay = automaticallyAdjustsStyleForTimeOfDay
        styleManager.delegate = self
        styleManager.styles = navigationOptions?.styles ?? [StandardDayStyle(), StandardNightStyle()]

        if let currentStyle = styleManager.currentStyle {
            updateMapStyle(currentStyle)
        }
        if usesNightStyleInDarkMode, traitCollection.userInterfaceStyle == .dark {
            styleManager.applyStyle(type: .night)
        } else {
            styleManager.applyStyle(type: .day)
        }
    }

    var currentStatusBarStyle: UIStatusBarStyle = .default

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return currentStatusBarStyle
    }

    func transitionStyle(to newCollection: UITraitCollection) {
        guard let styleManager else { return }
        if newCollection.userInterfaceStyle == .dark {
            styleManager.applyStyle(type: .night)
        } else {
            styleManager.applyStyle(type: .day)
        }
    }
}

// MARK: - NavigationViewDelegate methods

extension NavigationViewController: NavigationViewDelegate {
    func navigationView(_ view: NavigationView, didTap cancelButton: CancelButton) {
        handleCancelAction()
    }

    func navigationView(_ navigationView: NavigationView, didReplace navigationMapView: NavigationMapView) {
        // do nothing?
    }
}

// MARK: - NavigationServiceDelegate methods

extension NavigationViewController {
    private func subscribeMapboxNavigation() {
        mapboxNavigation.navigation().rerouting
            .sink { [weak self] status in
                guard let self else { return }
                switch status.event {
                case is ReroutingStatus.Events.FetchingRoute:
                    navigationComponents.forEach {
                        $0.onWillReroute()
                    }
                    delegate?.navigationViewController(
                        self,
                        willRerouteFrom: mapboxNavigation.navigation().currentLocationMatching?.mapMatchingResult
                            .enhancedLocation
                    )
                case let failed as ReroutingStatus.Events.Failed:
                    navigationComponents.forEach {
                        $0.onDidReroute()
                    }
                    delegate?.navigationViewController(self, didFailToRerouteWith: failed.error)
                default:
                    navigationComponents.forEach {
                        $0.onDidReroute()
                    }
                    if let route = mapboxNavigation.tripSession().currentNavigationRoutes?.mainRoute.route {
                        delegate?.navigationViewController(self, didRerouteAlong: route)
                    }
                }
            }
            .store(in: &subscriptions)

        mapboxNavigation.navigation().bannerInstructions
            .sink { [weak self] status in
                guard let self else { return }
                navigationComponents.forEach {
                    $0.onDidPassVisualInstructionPoint(status.visualInstruction)
                }
            }
            .store(in: &subscriptions)

        mapboxNavigation.navigation().locationMatching
            .sink { [weak self] status in
                var statusRoadName = status.roadName
                if let text = self?.roadName(at: status.enhancedLocation), !text.isEmpty {
                    statusRoadName = RoadName(
                        text: text,
                        language: statusRoadName?.language ?? "",
                        shield: statusRoadName?.shield
                    )
                }
                self?.ornamentsController?.updateRoadNameFromStatus(statusRoadName)
            }
            .store(in: &subscriptions)

        mapboxNavigation.navigation().routeProgress
            .sink { [weak self] status in
                guard let self,
                      let status,
                      let locationMatching = mapboxNavigation.navigation().currentLocationMatching else { return }

                let location = locationMatching.enhancedLocation
                navigationComponents.forEach {
                    $0.onRouteProgressUpdated(status.routeProgress)
                }

                checkTunnelState(at: location, along: status.routeProgress)

                delegate?.navigationViewController(
                    self,
                    didUpdate: status.routeProgress,
                    with: location,
                    rawLocation: locationMatching.location
                )
            }
            .store(in: &subscriptions)

        mapboxNavigation.navigation().waypointsArrival
            .compactMap {
                $0.event as? WaypointArrivalStatus.Events.ToFinalDestination
            }
            .sink { [weak self] status in
                guard let self else { return }

                delegate?.navigationViewController(self, didArriveAt: status.destination)
                if showsEndOfRouteFeedback {
                    arrivalController?.showEndOfRouteIfNeeded(self, advancesToNextLeg: true) {
                        [weak self] in
                        self?.dismiss()
                    }
                } else {
                    dismiss()
                }
            }
            .store(in: &subscriptions)

        mapboxNavigation.navigation().fasterRoutes
            .filter {
                $0.event is FasterRoutesStatus.Events.Applied
            }
            .sink { [weak self] _ in
                guard let self else { return }

                navigationComponents.forEach {
                    $0.onFasterRoute()
                }
            }
            .store(in: &subscriptions)

        mapboxNavigation.navigation().offlineFallbacks
            .filter {
                $0.usingLatestTiles
            }
            .sink { [weak self] _ in
                guard let self else { return }

                navigationComponents.forEach {
                    $0.onSwitchingToOnline()
                }

                guard let route = mapboxNavigation.tripSession().currentNavigationRoutes?.mainRoute.route
                else { return }
                delegate?.navigationViewController(self, didSwitchToCoincidentOnlineRoute: route)
            }
            .store(in: &subscriptions)

        mapboxNavigation.navigation().routeRefreshing
            .filter {
                $0.event is RefreshingStatus.Events.Refreshed
            }
            .sink { [weak self] _ in
                guard let self,
                      let routeProgress = mapboxNavigation.navigation().currentRouteProgress?.routeProgress
                else { return }
                delegate?.navigationViewController(self, didRefresh: routeProgress)
            }
            .store(in: &subscriptions)

        mapboxNavigation.navigation().voiceInstructions
            .sink { [weak self] _ in
                guard let self,
                      let routeProgress = mapboxNavigation.navigation().currentRouteProgress?.routeProgress
                else { return }

                scheduleLocalNotification(routeProgress)
            }
            .store(in: &subscriptions)

        mapboxNavigation.navigation().continuousAlternatives
            .sink { [weak self] status in
                guard let self else { return }

                switch status.event {
                case let updated as AlternativesStatus.Events.Updated:
                    let removedAlternatives = Array(
                        Set(continuousAlternatives)
                            .subtracting(Set(updated.actualAlternativeRoutes))
                    )
                    continuousAlternatives = updated.actualAlternativeRoutes
                    delegate?.navigationViewController(
                        self,
                        didUpdateAlternatives: updated.actualAlternativeRoutes,
                        removedAlternatives: removedAlternatives
                    )
                default:
                    break // do nothing
                }
            }
            .store(in: &subscriptions)
    }

    private func dismiss() {
        dismiss(animated: true) { [weak self] in
            guard let self else { return }
            delegate?.navigationViewControllerDidDismiss(self, byCanceling: false)
        }
    }

    private func checkTunnelState(at location: CLLocation, along progress: RouteProgress) {
        guard let styleManager else { return }
        let inTunnel = tunnelAuthority.isInTunnel(location, progress)

        // Entering tunnel
        if !isTraversingTunnel, inTunnel {
            isTraversingTunnel = true

            if usesNightStyleWhileInTunnel,
               styleManager.currentStyle?.styleType != .night
            {
                styleManager.applyStyle(type: .night)
            }
        }

        // Exiting tunnel
        if isTraversingTunnel, !inTunnel {
            isTraversingTunnel = false
            styleManager.timeOfDayChanged()
        }
    }

    func scheduleLocalNotification(_ routeProgress: RouteProgress) {
        // Remove any notification about an already completed maneuver, even if there isn’t another notification to
        // replace it with yet.
        let identifier = "com.mapbox.route_progress_instruction"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])

        guard sendsNotifications, UIApplication.shared.applicationState == .background else { return }

        let currentLegProgress = routeProgress.currentLegProgress
        let spokenInstructionsCount = currentLegProgress.currentStep.instructionsSpokenAlongStep?.count ?? 0
        if currentLegProgress.currentStepProgress.spokenInstructionIndex != spokenInstructionsCount - 1 {
            return
        }
        guard let instruction = currentLegProgress.currentStep.instructionsDisplayedAlongStep?.last else { return }

        let content = UNMutableNotificationContent()
        if let primaryText = instruction.primaryInstruction.text {
            content.title = primaryText
        }
        if let secondaryText = instruction.secondaryInstruction?.text {
            content.subtitle = secondaryText
        }

        let imageColor: UIColor = switch traitCollection.userInterfaceStyle {
        case .dark:
            .white
        case .light, .unspecified:
            .black
        @unknown default:
            .black
        }

        if let image = instruction.primaryInstruction.maneuverViewImage(
            drivingSide: instruction.drivingSide,
            visualInstruction: instruction.primaryInstruction,
            color: imageColor,
            size: CGSize(width: 72, height: 72)
        ) {
            // Bake in any transform required for left turn arrows etc.
            let imageData = UIGraphicsImageRenderer(size: image.size).pngData { _ in
                image.draw(at: .zero)
            }
            let temporaryURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("com.mapbox.navigation.notification-icon.png")
            do {
                try imageData.write(to: temporaryURL)
                let iconAttachment = try UNNotificationAttachment(
                    identifier: "maneuver",
                    url: temporaryURL,
                    options: [UNNotificationAttachmentOptionsTypeHintKey: kUTTypePNG]
                )
                content.attachments = [iconAttachment]
            } catch {
                Log.error(
                    "Failed to create UNNotificationAttachment with error: \(error.localizedDescription).",
                    category: .navigationUI
                )
            }
        }

        let notificationRequest = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: nil)
    }
}

// MARK: StyleManagerDelegate

extension NavigationViewController: StyleManagerDelegate {
    func roadName(at location: CLLocation) -> String? {
        guard let roadName = delegate?.navigationViewController(self, roadNameAt: location) else {
            return nil
        }
        return roadName
    }

    public func location(for styleManager: StyleManager) -> CLLocation? {
        if let location = mapboxNavigation.navigation().currentLocationMatching?.mapMatchingResult.enhancedLocation {
            return location
        } else if let firstCoord = route?.shape?.coordinates.first {
            return CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
        } else {
            return nil
        }
    }

    public func styleManager(_ styleManager: StyleManager, didApply style: Style) {
        updateMapStyle(style)
    }

    private func updateMapStyle(_ style: Style) {
        if let navigationMapView {
            style.applyMapStyle(to: navigationMapView)
        }

        let styleURI = StyleURI(url: style.mapStyleURL)
        ornamentsController?.updateStyle(styleURI: styleURI)
        currentStatusBarStyle = style.statusBarStyle ?? .default
        setNeedsStatusBarAppearanceUpdate()
    }

    public func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) {
        guard let mapboxMap = navigationMapView?.mapView.mapboxMap,
              let styleURI = mapboxMap.styleURI else { return }

        mapboxMap.loadStyle(styleURI) { error in
            if let error {
                Log.error(
                    "Failed to load \(styleURI) with error: \(error.localizedDescription).",
                    category: .navigationUI
                )
            }
        }
    }
}

// MARK: TopBannerViewController methods

extension NavigationViewController {
    // MARK: StatusView action related methods

    @objc
    func didChangeSpeed(_ statusView: StatusView) {
        // not supported ATM
    }
}

// MARK: TopBannerViewControllerDelegate methods

extension NavigationViewController: TopBannerViewControllerDelegate {
    public func topBanner(
        _ banner: TopBannerViewController,
        didSwipeInDirection direction: UISwipeGestureRecognizer.Direction
    ) {
        guard let progress = mapboxNavigation.navigation().currentRouteProgress?.routeProgress else { return }
        let route = progress.navigationRoutes.mainRoute.route
        switch direction {
        case .up where banner.isDisplayingSteps:
            banner.dismissStepsTable()

        case .down where !banner.isDisplayingSteps:
            banner.displayStepsTable()

            if banner.isDisplayingPreviewInstructions {
                navigationMapView?.navigationCamera.update(cameraState: .following)
            }

        default:
            break
        }

        if !banner.isDisplayingSteps {
            switch (direction, UIApplication.shared.userInterfaceLayoutDirection) {
            case (.right, .leftToRight), (.left, .rightToLeft):
                guard let currentStepIndex = banner.currentPreviewStep?.1 else { return }
                let remainingSteps = progress.remainingSteps
                let prevStepIndex = currentStepIndex.advanced(by: -1)
                guard prevStepIndex >= 0 else {
                    banner.stopPreviewing()
                    navigationMapView?.navigationCamera.update(cameraState: .following)
                    return
                }

                let prevStep = remainingSteps[prevStepIndex]
                preview(step: prevStep, in: banner, remaining: remainingSteps, route: route)

            case (.left, .leftToRight), (.right, .rightToLeft):
                let remainingSteps = progress.remainingSteps
                let currentStepIndex = banner.currentPreviewStep?.1
                let nextStepIndex = currentStepIndex?.advanced(by: 1) ?? 0
                guard nextStepIndex < remainingSteps.count else { return }

                let nextStep = remainingSteps[nextStepIndex]
                preview(step: nextStep, in: banner, remaining: remainingSteps, route: route)

            default:
                break
            }
        }
    }

    public func preview(
        step: RouteStep,
        in banner: TopBannerViewController,
        remaining: [RouteStep],
        route: Route,
        animated: Bool = true
    ) {
        guard let leg = route.leg(containing: step),
              let legIndex = route.legs.firstIndex(of: leg),
              let stepIndex = leg.steps.firstIndex(of: step) else { return }

        guard route.containsStep(at: legIndex, stepIndex: stepIndex),
              route.containsStep(at: legIndex, stepIndex: stepIndex + 1) else { return }
        let currentStep = route.legs[legIndex].steps[stepIndex]
        let upcomingStep = route.legs[legIndex].steps[stepIndex + 1]

        navigationMapView?.navigationCamera.stop()

        let edgeInsets = navigationMapView?.safeArea ?? .zero + UIEdgeInsets.centerEdgeInsets
        let cameraOptions = CameraOptions(
            center: upcomingStep.maneuverLocation,
            padding: edgeInsets,
            zoom: navigationMapView?.mapView.mapboxMap.cameraState.zoom,
            bearing: upcomingStep.initialHeading ?? navigationMapView?.mapView.mapboxMap
                .cameraState.bearing
        )

        navigationMapView?.mapView.camera.ease(
            to: cameraOptions,
            duration: animated ? 1.0 : 0.0,
            completion: nil
        )

        banner.preview(
            step: currentStep,
            maneuverStep: upcomingStep,
            distance: currentStep.distance,
            steps: remaining
        )
    }

    public func topBanner(
        _ banner: TopBannerViewController,
        didSelect legIndex: Int,
        stepIndex: Int,
        cell: StepTableViewCell
    ) {
        guard let progress = mapboxNavigation.navigation().currentRouteProgress?.routeProgress else { return }
        let route = progress.navigationRoutes.mainRoute.route
        guard route.containsStep(at: legIndex, stepIndex: stepIndex) else { return }
        let step = route.legs[legIndex].steps[stepIndex]
        preview(step: step, in: banner, remaining: progress.remainingSteps, route: route)
        banner.dismissStepsTable()
    }

    public func topBanner(_ banner: TopBannerViewController, didDisplayStepsController: StepsViewController) {
        navigationMapView?.navigationCamera.update(cameraState: .following)
    }

    public func label(
        _ label: InstructionLabel,
        willPresent instruction: VisualInstruction,
        as presented: NSAttributedString
    ) -> NSAttributedString? {
        delegate?.label(label, willPresent: instruction, as: presented)
    }
}

// MARK: BottomBannerViewControllerDelegate methods

extension NavigationViewController: BottomBannerViewControllerDelegate {
    // Handle cancel action in new Bottom Banner container.
    public func didTapCancel(_ sender: Any) {
        handleCancelAction()
    }
}

// MARK: CarPlayConnectionObserver methods

extension NavigationViewController: CarPlayConnectionObserver {
    public func didConnectToCarPlay() {
        navigationComponents.compactMap { $0 as? CarPlayConnectionObserver }.forEach {
            $0.didConnectToCarPlay()
        }
    }

    public func didDisconnectFromCarPlay() {
        navigationComponents.compactMap { $0 as? CarPlayConnectionObserver }.forEach {
            $0.didDisconnectFromCarPlay()
        }
    }
}

extension AlternativeRoute: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id.hashValue)
    }
}
