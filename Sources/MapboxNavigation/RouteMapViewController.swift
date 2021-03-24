import UIKit
import MapboxDirections
import MapboxCoreNavigation
import MapboxMobileEvents
import Turf
import MapboxMaps
import MapboxCoreMaps

class RouteMapViewController: UIViewController {
    
    var navigationView: NavigationView {
        return view as! NavigationView
    }
    
    var navigationMapView: NavigationMapView {
        return navigationView.navigationMapView
    }
    
    var reportButton: FloatingButton {
        return navigationView.reportButton
    }
    
    var topBannerContainerView: BannerContainerView {
        return navigationView.topBannerContainerView
    }
    
    var bottomBannerContainerView: BannerContainerView {
        return navigationView.bottomBannerContainerView
    }
    
    var floatingButtonsPosition: MapOrnamentPosition {
        get {
            return navigationView.floatingButtonsPosition
        }
        set {
            navigationView.floatingButtonsPosition = newValue
        }
    }
    
    var floatingButtons: [UIButton]? {
        get {
            return navigationView.floatingButtons
        }
        set {
            navigationView.floatingButtons = newValue
        }
    }
    
    lazy var endOfRouteViewController: EndOfRouteViewController = {
        let storyboard = UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
        let viewController = storyboard.instantiateViewController(withIdentifier: "EndOfRouteViewController") as! EndOfRouteViewController
        return viewController
    }()

    private struct Actions {
        static let overview: Selector = #selector(RouteMapViewController.toggleOverview(_:))
        static let mute: Selector = #selector(RouteMapViewController.toggleMute(_:))
        static let feedback: Selector = #selector(RouteMapViewController.feedback(_:))
        static let recenter: Selector = #selector(RouteMapViewController.recenter(_:))
    }

    var route: Route {
        return navigationService.router.route
    }
    
    var destination: Waypoint?

    var showsEndOfRoute: Bool = true
    var showsSpeedLimits: Bool = true {
        didSet {
            navigationView.speedLimitView.isAlwaysHidden = !showsSpeedLimits
        }
    }

    var detailedFeedbackEnabled: Bool = false

    var pendingCamera: CameraOptions? {
        guard let parent = parent as? NavigationViewController else {
            return nil
        }
        return parent.pendingCamera
    }
    
    var tiltedCamera: CameraOptions {
        get {
            let currentCamera = navigationMapView.mapView.cameraView.camera
            let pitch: CGFloat = 45.0
            let zoom = CGFloat(ZoomLevelForAltitude(1000,
                                                    pitch,
                                                    // TODO: Find an alternative way of providing `latitude`.
                                                    router.location?.coordinate.latitude ?? 0.0,
                                                    navigationMapView.mapView.bounds.size))
            
            return CameraOptions(center: currentCamera.center,
                                 padding: currentCamera.padding,
                                 anchor: currentCamera.anchor,
                                 zoom: zoom,
                                 bearing: currentCamera.bearing,
                                 pitch: pitch)
        }
    }
    
    weak var delegate: RouteMapViewControllerDelegate?
    var navigationService: NavigationService! {
        didSet {
            guard let destination = route.legs.last?.destination else { return }
            populateName(for: destination, populated: { self.destination = $0 })
        }
    }
    
    var router: Router {
        return navigationService.router
    }
    
    var isInOverviewMode = false {
        didSet {
            if isInOverviewMode {
                navigationView.overviewButton.isHidden = true
                navigationView.resumeButton.isHidden = false
                navigationView.wayNameView.isHidden = true
            } else {
                navigationView.overviewButton.isHidden = false
                navigationView.resumeButton.isHidden = true
            }
        }
    }
    var currentLegIndexMapped = 0
    var currentStepIndexMapped = 0

    /**
     A Boolean value that determines whether the map annotates the locations at which instructions are spoken for debugging purposes.
     */
    var annotatesSpokenInstructions = false

    var overheadInsets: UIEdgeInsets {
        return UIEdgeInsets(top: topBannerContainerView.bounds.height, left: 20, bottom: bottomBannerContainerView.bounds.height, right: 20)
    }
    
    var routeLineTracksTraversal = false {
        didSet {
            navigationMapView.routeLineTracksTraversal = routeLineTracksTraversal
        }
    }

    typealias LabelRoadNameCompletionHandler = (_ defaultRoadNameAssigned: Bool) -> Void

    var labelRoadNameCompletionHandler: (LabelRoadNameCompletionHandler)?
    
    /**
     A Boolean value that determines whether the map altitude should change based on internal conditions.
     */
    var suppressAutomaticAltitudeChanges: Bool = false

    convenience init(navigationService: NavigationService, delegate: RouteMapViewControllerDelegate? = nil, topBanner: ContainerViewController, bottomBanner: ContainerViewController) {
        self.init()
        self.navigationService = navigationService
        self.delegate = delegate
        automaticallyAdjustsScrollViewInsets = false
        let topContainer = navigationView.topBannerContainerView
        
        embed(topBanner, in: topContainer) { (parent, banner) -> [NSLayoutConstraint] in
            banner.view.translatesAutoresizingMaskIntoConstraints = false
            return banner.view.constraintsForPinning(to: self.navigationView.topBannerContainerView)
        }
        
        topContainer.backgroundColor = .clear
        
        let bottomContainer = navigationView.bottomBannerContainerView
        embed(bottomBanner, in: bottomContainer) { (parent, banner) -> [NSLayoutConstraint] in
            banner.view.translatesAutoresizingMaskIntoConstraints = false
            return banner.view.constraintsForPinning(to: self.navigationView.bottomBannerContainerView)
        }
        
        bottomContainer.backgroundColor = .clear
        
        view.bringSubviewToFront(topBannerContainerView)
    }

    override func loadView() {
        let frame = parent?.view.bounds ?? UIScreen.main.bounds
        view = NavigationView(delegate: self, frame: frame)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let navigationMapView = self.navigationMapView
        // TODO: Verify whether content insets should be changed on map view.
        view.layoutIfNeeded()

        navigationMapView.tracksUserCourse = true
        
        navigationMapView.mapView.on(.styleLoaded) { _ in
            self.showRouteIfNeeded()
            navigationMapView.localizeLabels()
            navigationMapView.mapView.showsTraffic = false
            
            // FIXME: In case when building highlighting feature is enabled due to style changes and no info currently being stored
            // regarding building identification such highlighted building will disappear.
        }
        
        makeGestureRecognizersResetFrameRate()
        navigationView.overviewButton.addTarget(self, action: Actions.overview, for: .touchUpInside)
        navigationView.muteButton.addTarget(self, action: Actions.mute, for: .touchUpInside)
        navigationView.reportButton.addTarget(self, action: Actions.feedback, for: .touchUpInside)
        navigationView.resumeButton.addTarget(self, action: Actions.recenter, for: .touchUpInside)
        resumeNotifications()
    }

    deinit {
        suspendNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationView.muteButton.isSelected = NavigationSettings.shared.voiceMuted
        navigationMapView.mapView.update {
            $0.ornaments.showsCompass = false
        }

        navigationMapView.tracksUserCourse = true

        if let camera = pendingCamera {
            navigationMapView.mapView.cameraManager.setCamera(to: camera, completion: nil)
        } else if let location = router.location, location.course > 0 {
            navigationMapView.updateCourseTracking(location: location)
        } else if let coordinates = router.routeProgress.currentLegProgress.currentStep.shape?.coordinates, let firstCoordinate = coordinates.first, coordinates.count > 1 {
            let secondCoordinate = coordinates[1]
            let course = firstCoordinate.direction(to: secondCoordinate)
            let newLocation = CLLocation(coordinate: router.location?.coordinate ?? firstCoordinate, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: course, speed: 0, timestamp: Date())
            navigationMapView.updateCourseTracking(location: newLocation)
        } else {
            navigationMapView.mapView.cameraManager.setCamera(to: tiltedCamera, completion: nil)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        annotatesSpokenInstructions = delegate?.mapViewControllerShouldAnnotateSpokenInstructions(self) ?? false
        showRouteIfNeeded()
        currentLegIndexMapped = router.routeProgress.legIndex
        currentStepIndexMapped = router.routeProgress.currentLegProgress.stepIndex
    }

    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
        subscribeToKeyboardNotifications()
    }

    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        unsubscribeFromKeyboardNotifications()
    }

    func embed(_ child: UIViewController, in container: UIView, constrainedBy constraints: ((RouteMapViewController, UIViewController) -> [NSLayoutConstraint])?) {
        child.willMove(toParent: self)
        addChild(child)
        container.addSubview(child.view)
        if let childConstraints: [NSLayoutConstraint] = constraints?(self, child) {
            view.addConstraints(childConstraints)
        }
        child.didMove(toParent: self)
    }
    
    @objc func recenter(_ sender: AnyObject) {
        navigationMapView.tracksUserCourse = true
        navigationMapView.enableFrameByFrameCourseViewTracking(for: 3)
        isInOverviewMode = false
        
        navigationMapView.updateCourseTracking(location: navigationMapView.userLocationForCourseTracking)
        updateCameraAltitude(for: router.routeProgress)
        
        navigationMapView.addArrow(route: router.route,
                                   legIndex: router.routeProgress.legIndex,
                                   stepIndex: router.routeProgress.currentLegProgress.stepIndex + 1)
        
        delegate?.mapViewController(self, didCenterOn: navigationMapView.userLocationForCourseTracking!)
    }
    
    func center(on step: RouteStep, route: Route, legIndex: Int, stepIndex: Int, animated: Bool = true, completion: CompletionHandler? = nil) {
        navigationMapView.enableFrameByFrameCourseViewTracking(for: 1)
        navigationMapView.tracksUserCourse = false
        
        // TODO: Verify that camera is positioned correctly.
        let camera = CameraOptions(center: step.maneuverLocation,
                                   zoom: navigationMapView.mapView.zoom,
                                   bearing: step.initialHeading ?? CLLocationDirection(navigationMapView.mapView.cameraView.bearing))
        
        navigationMapView.mapView.cameraManager.setCamera(to: camera,
                                                          animated: animated,
                                                          duration: animated ? 1 : 0) { _ in
            completion?()
        }
        
        guard isViewLoaded && view.window != nil else { return }
        navigationMapView.addArrow(route: router.routeProgress.route, legIndex: legIndex, stepIndex: stepIndex)
    }

    @objc func toggleOverview(_ sender: Any) {
        navigationMapView.enableFrameByFrameCourseViewTracking(for: 3)
        if let shape = router.route.shape,
           let userLocation = router.location {
            navigationMapView.setOverheadCameraView(from: userLocation, along: shape, for: contentInset(forOverviewing: true))
        }
        isInOverviewMode = true
        updateMapViewComponents()
    }

    @objc func toggleMute(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected

        let muted = sender.isSelected
        NavigationSettings.shared.voiceMuted = muted
    }

    @objc func feedback(_ sender: Any) {
        showFeedback()
    }

    func showFeedback(source: FeedbackSource = .user) {
        guard let parent = parent else { return }
        let feedbackViewController = FeedbackViewController(eventsManager: navigationService.eventsManager)
        feedbackViewController.detailedFeedbackEnabled = detailedFeedbackEnabled
        parent.present(feedbackViewController, animated: true, completion: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        navigationMapView.enableFrameByFrameCourseViewTracking(for: 3)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // TODO: Provide the ability to check what type of puck is currently shown.
        // if navigationMapView.mapView.locationManager.showUserLocation && !navigationMapView.tracksUserCourse {
        //    // Don't move mapView content on rotation or when e.g. top banner expands.
        //    return
        // }
        
        updateMapViewContentInsets()
    }
    
    func updateMapViewContentInsets() {
        navigationMapView.mapView.cameraView.padding = contentInset(forOverviewing: isInOverviewMode)
        navigationMapView.mapView.setNeedsUpdateConstraints()
        
        updateMapViewComponents()
    }

    @objc func applicationWillEnterForeground(notification: NSNotification) {
        navigationMapView.updateCourseTracking(location: router.location, animated: false)
    }
    
    @objc func orientationDidChange(_ notification: Notification) {
        updateMapViewContentInsets()
    }

    func updateMapOverlays(for routeProgress: RouteProgress) {
        if routeProgress.currentLegProgress.followOnStep != nil {
            navigationMapView.addArrow(route: route, legIndex: router.routeProgress.legIndex, stepIndex: router.routeProgress.currentLegProgress.stepIndex + 1)
        } else {
            navigationMapView.removeArrow()
        }
    }

    func updateCameraAltitude(for routeProgress: RouteProgress, completion: CompletionHandler? = nil) {
        // Adjust altitude only when we user course is being tracked.
        guard navigationMapView.tracksUserCourse else { return }
        
        let zoomOutAltitude = navigationMapView.zoomedOutMotorwayAltitude
        let defaultAltitude = navigationMapView.defaultAltitude
        let isLongRoad = routeProgress.distanceRemaining >= navigationMapView.longManeuverDistance
        let currentStep = routeProgress.currentLegProgress.currentStep
        let upComingStep = routeProgress.currentLegProgress.upcomingStep

        // If the user is at the last turn maneuver, the map should zoom in to the default altitude.
        let currentInstruction = routeProgress.currentLegProgress.currentStepProgress.currentSpokenInstruction

        // If the user is on a motorway, not exiting, and their segment is sufficently long, the map should zoom out to the motorway altitude.
        // otherwise, zoom in if it's the last instruction on the step.
        let currentStepIsMotorway = currentStep.isMotorway
        let nextStepIsMotorway = upComingStep?.isMotorway ?? false
        if currentStepIsMotorway, nextStepIsMotorway, isLongRoad {
            setCamera(altitude: zoomOutAltitude)
        } else if currentInstruction == currentStep.lastInstruction {
            setCamera(altitude: defaultAltitude)
        }
    }

    private func setCamera(altitude: Double) {
        guard navigationMapView.altitude != altitude else { return }
        navigationMapView.altitude = altitude
    }
    
    /**
     Modifies the gesture recognizers to also update the map’s frame rate.
     */
    func makeGestureRecognizersResetFrameRate() {
        for gestureRecognizer in navigationMapView.mapView.gestureRecognizers ?? [] {
            gestureRecognizer.addTarget(self, action: #selector(resetFrameRate(_:)))
        }
    }
    
    @objc func resetFrameRate(_ sender: UIGestureRecognizer) {
        navigationMapView.mapView.update {
            $0.render.preferredFramesPerSecond = NavigationMapView.FrameIntervalOptions.defaultFramesPerSecond
        }
    }
    
    /**
     Method updates `logoView` and `attributionButton` margins to prevent incorrect alignment
     reported in https://github.com/mapbox/mapbox-navigation-ios/issues/2561.
     */
    func updateMapViewComponents() {
        let bottomBannerHeight = bottomBannerContainerView.bounds.height
        let bottomBannerVerticalOffset = UIScreen.main.bounds.height - bottomBannerHeight - bottomBannerContainerView.frame.origin.y
        let defaultOffset: CGFloat = 10.0
        let x: CGFloat = defaultOffset
        let y: CGFloat = bottomBannerHeight + defaultOffset + bottomBannerVerticalOffset
        
        navigationMapView.mapView.update {
            if #available(iOS 11.0, *) {
                $0.ornaments.logoViewMargins = CGPoint(x: x, y: y - view.safeAreaInsets.bottom)
            } else {
                $0.ornaments.logoViewMargins = CGPoint(x: x, y: y)
            }
            
            if #available(iOS 11.0, *) {
                $0.ornaments.attributionButtonMargins = CGPoint(x: x, y: y - view.safeAreaInsets.bottom)
            } else {
                $0.ornaments.attributionButtonMargins = CGPoint(x: x, y: y)
            }
        }
    }
    
    func contentInset(forOverviewing overviewing: Bool) -> UIEdgeInsets {
        let instructionBannerHeight = topBannerContainerView.bounds.height
        let bottomBannerHeight = bottomBannerContainerView.bounds.height
        
        // Inset by the safe area to avoid notches.
        var insets = navigationMapView.mapView.safeArea
        insets.top += instructionBannerHeight
        insets.bottom += bottomBannerHeight
        
        if overviewing {
            insets += NavigationMapView.courseViewMinimumInsets
            
            let routeLineWidths = RouteLineWidthByZoomLevel.map { $0.value }
            insets += UIEdgeInsets(floatLiteral: Double(routeLineWidths.max() ?? 0))
        } else if navigationMapView.tracksUserCourse {
            // Puck position calculation - position it just above the bottom of the content area.
            var contentFrame = navigationMapView.mapView.bounds.inset(by: insets)

            // Avoid letting the puck go partially off-screen, and add a comfortable padding beyond that.
            let courseViewBounds = navigationMapView.userCourseView.bounds
            // If it is not possible to position it right above the content area, center it at the remaining space.
            contentFrame = contentFrame.insetBy(dx: min(NavigationMapView.courseViewMinimumInsets.left + courseViewBounds.width / 2.0, contentFrame.width / 2.0),
                                                dy: min(NavigationMapView.courseViewMinimumInsets.top + courseViewBounds.height / 2.0, contentFrame.height / 2.0))
            assert(!contentFrame.isInfinite)

            let y = contentFrame.maxY
            let height = navigationMapView.mapView.bounds.height
            insets.top = height - insets.bottom - 2 * (height - insets.bottom - y)
        }
        
        return insets
    }

    // MARK: - End of Route methods

    func embedEndOfRoute() {
        let endOfRoute = endOfRouteViewController
        addChild(endOfRoute)
        navigationView.endOfRouteView = endOfRoute.view
        navigationView.constrainEndOfRoute()
        endOfRoute.didMove(toParent: self)

        endOfRoute.dismissHandler = { [weak self] (stars, comment) in
            guard let rating = self?.rating(for: stars) else { return }
            let feedback = EndOfRouteFeedback(rating: rating, comment: comment)
            self?.navigationService.endNavigation(feedback: feedback)
            self?.delegate?.mapViewControllerDidDismiss(self!, byCanceling: false)
        }
    }

    func showEndOfRoute(duration: TimeInterval = 1.0, completion: ((Bool) -> Void)? = nil) {
        embedEndOfRoute()
        endOfRouteViewController.destination = destination
        navigationView.endOfRouteView?.isHidden = false
        
        // flush layout queue
        view.layoutIfNeeded()
        
        navigationView.endOfRouteHideConstraint?.isActive = false
        navigationView.endOfRouteShowConstraint?.isActive = true

        navigationMapView.enableFrameByFrameCourseViewTracking(for: duration)
        navigationMapView.mapView.setNeedsUpdateConstraints()

        let animate = {
            self.view.layoutIfNeeded()
            self.navigationView.floatingStackView.alpha = 0.0
        }

        let noAnimation = {
            animate();
            completion?(true)
        }

        guard duration > 0.0 else { return noAnimation() }

        navigationMapView.tracksUserCourse = false
        UIView.animate(withDuration: duration, delay: 0.0, options: [.curveLinear], animations: animate, completion: completion)

        guard let height = navigationView.endOfRouteHeightConstraint?.constant else { return }
        let insets = UIEdgeInsets(top: topBannerContainerView.bounds.height, left: 20, bottom: height + 20, right: 20)
        
        if let shape = route.shape,
           let userLocation = navigationService.router.location?.coordinate,
           !shape.coordinates.isEmpty,
           let slicedLineString = shape.sliced(from: userLocation) {
            
            let newCamera = navigationMapView.mapView.cameraManager.camera(fitting: .lineString(slicedLineString),
                                                                           edgePadding: insets,
                                                                           bearing: CGFloat(navigationMapView.mapView.bearing),
                                                                           pitch: 0)
            let zoomLevel = CGFloat(ZoomLevelForAltitude(navigationMapView.altitude,
                                                         0,
                                                         userLocation.latitude,
                                                         navigationMapView.mapView.bounds.size))
            newCamera.zoom = zoomLevel

            navigationMapView.mapView.cameraManager.setCamera(to: newCamera, completion: nil)
        }
    }

    fileprivate func rating(for stars: Int) -> Int {
        assert(stars >= 0 && stars <= 5)
        guard stars > 0 else { return MMEEventsManager.unrated } //zero stars means this was unrated.
        return (stars - 1) * 25
    }

    fileprivate func populateName(for waypoint: Waypoint, populated: @escaping (Waypoint) -> Void) {
        guard waypoint.name == nil else { return populated(waypoint) }
        let location = CLLocation(latitude: waypoint.coordinate.latitude, longitude: waypoint.coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(location) { (places, error) in
        guard let place = places?.first, let placeName = place.name, error == nil else { return }
            let named = Waypoint(coordinate: waypoint.coordinate, name: placeName)
            return populated(named)
        }
    }
    
    fileprivate func leg(containing step: RouteStep) -> RouteLeg? {
        return route.legs.first { $0.steps.contains(step) }
    }
}

// MARK: - NavigationComponent

extension RouteMapViewController: NavigationComponent {
    
    func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        let route = progress.route
        let legIndex = progress.legIndex
        let stepIndex = progress.currentLegProgress.stepIndex

        navigationMapView.updatePreferredFrameRate(for: progress)
        if currentLegIndexMapped != legIndex {
            navigationMapView.showWaypoints(on: route, legIndex: legIndex)
            navigationMapView.show([route], legIndex: legIndex)
            
            currentLegIndexMapped = legIndex
        }
        
        if currentStepIndexMapped != stepIndex {
            updateMapOverlays(for: progress)
            currentStepIndexMapped = stepIndex
        }
        
        if annotatesSpokenInstructions {
            navigationMapView.showVoiceInstructionsOnMap(route: route)
        }
        
        if routeLineTracksTraversal {
            navigationMapView.updateUpcomingRoutePointIndex(routeProgress: progress)
            navigationMapView.updateTraveledRouteLine(location.coordinate)
            navigationMapView.updateRoute(progress)
        }
        
        navigationView.speedLimitView.signStandard = progress.currentLegProgress.currentStep.speedLimitSignStandard
        navigationView.speedLimitView.speedLimit = progress.currentLegProgress.currentSpeedLimit
    }
    
    public func navigationService(_ service: NavigationService, didPassSpokenInstructionPoint instruction: SpokenInstruction, routeProgress: RouteProgress) {
        if !suppressAutomaticAltitudeChanges {
            updateCameraAltitude(for: routeProgress)
        }
    }
    
    func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        currentStepIndexMapped = 0
        let route = router.route
        let stepIndex = router.routeProgress.currentLegProgress.stepIndex
        let legIndex = router.routeProgress.legIndex
        
        navigationMapView.removeWaypoints()
        
        navigationMapView.addArrow(route: route, legIndex: legIndex, stepIndex: stepIndex + 1)
        navigationMapView.show([route], legIndex: legIndex)
        navigationMapView.showWaypoints(on: route)
        
        if annotatesSpokenInstructions {
            navigationMapView.showVoiceInstructionsOnMap(route: route)
        }
        
        if isInOverviewMode {
            if let shape = route.shape, let userLocation = router.location {
                navigationMapView.setOverheadCameraView(from: userLocation, along: shape, for: contentInset(forOverviewing: true))
            }
        } else {
            navigationMapView.tracksUserCourse = true
            navigationView.wayNameView.isHidden = true
        }
    }
    
    func navigationService(_ service: NavigationService, didRefresh routeProgress: RouteProgress) {
        navigationMapView.show([routeProgress.route], legIndex: routeProgress.legIndex)
        if routeLineTracksTraversal {
            navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
            navigationMapView.updateTraveledRouteLine(router.location?.coordinate)
            navigationMapView.updateRoute(routeProgress)
        }
    }
}

// MARK: - UIContentContainer

extension RouteMapViewController {
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        navigationView.endOfRouteHeightConstraint?.constant = container.preferredContentSize.height

        UIView.animate(withDuration: 0.3, animations: view.layoutIfNeeded)
    }
}

// MARK: - NavigationViewDelegate methods

extension RouteMapViewController: NavigationViewDelegate {
    
    func navigationView(_ view: NavigationView, didTapCancelButton: CancelButton) {
        delegate?.mapViewControllerDidDismiss(self, byCanceling: true)
    }
    
    // MARK: - VisualInstructionDelegate methods
    
    func label(_ label: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString? {
        return delegate?.label(label, willPresent: instruction, as: presented)
    }

    // MARK: - NavigationMapViewCourseTrackingDelegate methods
    
    func navigationMapViewDidStartTrackingCourse(_ mapView: NavigationMapView) {
        navigationView.resumeButton.isHidden = true
    }

    func navigationMapViewDidStopTrackingCourse(_ mapView: NavigationMapView) {
        navigationView.resumeButton.isHidden = false
        navigationView.wayNameView.isHidden = true
    }

    // MARK: - NavigationMapViewDelegate methods
    func navigationMapView(_ navigationMapView: NavigationMapView, waypointCircleLayerWithIdentifier identifier: String, sourceIdentifier: String) -> CircleLayer? {
        delegate?.navigationMapView(navigationMapView, waypointCircleLayerWithIdentifier: identifier, sourceIdentifier: sourceIdentifier)
    }
    
    func navigationMapView(_ navigationMapView: NavigationMapView, waypointSymbolLayerWithIdentifier identifier: String, sourceIdentifier: String) -> SymbolLayer? {
        delegate?.navigationMapView(navigationMapView, waypointSymbolLayerWithIdentifier: identifier, sourceIdentifier: sourceIdentifier)
    }
    
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect route: Route) {
        delegate?.navigationMapView(navigationMapView, didSelect: route)
    }

    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect waypoint: Waypoint) {
        delegate?.navigationMapView(navigationMapView, didSelect: waypoint)
    }
    
    func navigationMapView(_ navigationMapView: NavigationMapView, shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection? {
        delegate?.navigationMapView(navigationMapView, shapeFor: waypoints, legIndex: legIndex)
    }

    func navigationMapViewUserAnchorPoint(_ navigationMapView: NavigationMapView) -> CGPoint {
        // If the end of route component is showing, then put the anchor point slightly above the middle of the map.
        if navigationView.endOfRouteView != nil, let show = navigationView.endOfRouteShowConstraint, show.isActive {
            return CGPoint(x: navigationMapView.bounds.midX, y: (navigationMapView.bounds.height * 0.4))
        }

        // Otherwise, ask the delegate or return .zero.
        return delegate?.navigationMapViewUserAnchorPoint(navigationMapView) ?? .zero
    }

    // TODO: Improve documentation.
    /**
     Updates the current road name label to reflect the road on which the user is currently traveling.

     - parameter location: The user’s current location.
     */
    func labelCurrentRoad(at rawLocation: CLLocation, for snappedLocation: CLLocation? = nil) {
        guard navigationView.resumeButton.isHidden else { return }
        
        if let roadName = delegate?.mapViewController(self, roadNameAt: rawLocation) {
            navigationView.wayNameView.text = roadName
            navigationView.wayNameView.isHidden = roadName.isEmpty
            
            return
        }
        
        // Avoid aggressively opting the developer into Mapbox services if they haven’t provided an access token.
        guard let _ = AccountManager.shared.accessToken else {
            navigationView.wayNameView.isHidden = true
            return
        }
        
        labelCurrentRoadFeature(at: snappedLocation ?? rawLocation)
        
        if let labelRoadNameCompletionHandler = labelRoadNameCompletionHandler {
            labelRoadNameCompletionHandler(true)
        }
    }
    
    func labelCurrentRoadFeature(at location: CLLocation) {
        guard let stepShape = router.routeProgress.currentLegProgress.currentStep.shape,
              !stepShape.coordinates.isEmpty,
              let mapView = navigationMapView.mapView else {
            return
        }
        
        // Add Mapbox Streets if the map does not already have it
        if streetsSources().isEmpty {
            var streetsSource = VectorSource()
            streetsSource.url = "mapbox://mapbox.mapbox-streets-v8"
            mapView.style.addSource(source: streetsSource, identifier: "com.mapbox.MapboxStreets")
        }
        
        guard let mapboxStreetsSource = streetsSources().first else { return }
        
        let identifierNamespace = Bundle.mapboxNavigation.bundleIdentifier ?? ""
        let roadLabelStyleLayerIdentifier = "\(identifierNamespace).roadLabels"
        let roadLabelLayer = try? mapView.style.getLayer(with: roadLabelStyleLayerIdentifier, type: LineLayer.self).get()
        
        if roadLabelLayer == nil {
            var streetLabelLayer = LineLayer(id: roadLabelStyleLayerIdentifier)
            streetLabelLayer.source = mapboxStreetsSource.id
            
            var sourceLayerIdentifier: String? {
                let identifiers = tileSetIdentifiers(mapboxStreetsSource.id, sourceType: mapboxStreetsSource.type)
                if isMapboxStreets(identifiers) {
                    let roadLabelLayerIdentifiersByTileSetIdentifier = [
                        "mapbox.mapbox-streets-v8": "road",
                        "mapbox.mapbox-streets-v7": "road_label",
                    ]
                    
                    return identifiers.compactMap({ roadLabelLayerIdentifiersByTileSetIdentifier[$0] }).first
                }
                
                return nil
            }
            
            streetLabelLayer.sourceLayer = sourceLayerIdentifier
            streetLabelLayer.paint?.lineOpacity = .constant(1.0)
            streetLabelLayer.paint?.lineWidth = .constant(20.0)
            streetLabelLayer.paint?.lineColor = .constant(.init(color: .white))
            
            if ![DirectionsProfileIdentifier.walking, DirectionsProfileIdentifier.cycling].contains(router.routeProgress.routeOptions.profileIdentifier) {
                // Filter out to road classes valid only for motor transport.
                let filter = Exp(.inExpression) {
                    "class"
                    "motorway"
                    "motorway_link"
                    "trunk"
                    "trunk_link"
                    "primary"
                    "primary_link"
                    "secondary"
                    "secondary_link"
                    "tertiary"
                    "tertiary_link"
                    "street"
                    "street_limited"
                    "roundabout"
                }
                
                streetLabelLayer.filter = filter
            }
            
            let firstLayerIdentifier = try? mapView.__map.getStyleLayers().first?.id
            mapView.style.addLayer(layer: streetLabelLayer, layerPosition: .init(below: firstLayerIdentifier))
        }
        
        let closestCoordinate = location.coordinate
        let position = mapView.point(for: closestCoordinate)
        mapView.visibleFeatures(at: position, styleLayers: Set([roadLabelStyleLayerIdentifier]), completion: { result in
            switch result {
            case .success(let features):
                var smallestLabelDistance = Double.infinity
                var currentName: String?
                var currentShieldName: NSAttributedString?
                let slicedLine = stepShape.sliced(from: closestCoordinate)!
                
                for feature in features {
                    var lineStrings: [LineString] = []
                    
                    if let line = feature.geometry.value as? LineString {
                        lineStrings.append(line)
                    } else if let multiLine = feature.geometry.value as? MultiLineString {
                        for coordinates in multiLine.coordinates {
                            lineStrings.append(LineString(coordinates))
                        }
                    }
                    
                    for lineString in lineStrings {
                        let lookAheadDistance: CLLocationDistance = 10
                        guard let pointAheadFeature = lineString.sliced(from: closestCoordinate)!.coordinateFromStart(distance: lookAheadDistance) else { continue }
                        guard let pointAheadUser = slicedLine.coordinateFromStart(distance: lookAheadDistance) else { continue }
                        guard let reversedPoint = LineString(lineString.coordinates.reversed()).sliced(from: closestCoordinate)!.coordinateFromStart(distance: lookAheadDistance) else { continue }
                        
                        let distanceBetweenPointsAhead = pointAheadFeature.distance(to: pointAheadUser)
                        let distanceBetweenReversedPoint = reversedPoint.distance(to: pointAheadUser)
                        let minDistanceBetweenPoints = min(distanceBetweenPointsAhead, distanceBetweenReversedPoint)
                        
                        if minDistanceBetweenPoints < smallestLabelDistance {
                            smallestLabelDistance = minDistanceBetweenPoints
                            
                            let roadNameRecord = self.roadFeature(for: feature)
                            currentShieldName = roadNameRecord.shieldName
                            currentName = roadNameRecord.roadName
                        }
                    }
                }
                
                let hasWayName = currentName != nil || currentShieldName != nil
                if smallestLabelDistance < 5 && hasWayName {
                    if let currentShieldName = currentShieldName {
                        self.navigationView.wayNameView.attributedText = currentShieldName
                    } else if let currentName = currentName {
                        self.navigationView.wayNameView.text = currentName
                    }
                    self.navigationView.wayNameView.isHidden = false
                } else {
                    self.navigationView.wayNameView.isHidden = true
                }
            case .failure:
                NSLog("Failed to find visible features.")
            }
        })
    }

    func roadFeature(for line: Feature) -> (roadName: String?, shieldName: NSAttributedString?) {
        var currentShieldName: NSAttributedString?, currentRoadName: String?
        
        if let ref = line.properties?["ref"] as? String,
           let shield = line.properties?["shield"] as? String,
           let reflen = line.properties?["reflen"] as? Int {
            let textColor = roadShieldTextColor(line: line) ?? .black
            let imageName = "\(shield)-\(reflen)"
            currentShieldName = roadShieldAttributedText(for: ref, textColor: textColor, imageName: imageName)
        }
        
        if let roadName = line.properties?["name"] as? String {
            currentRoadName = roadName
        }
        
        if let compositeShieldImage = currentShieldName, let roadName = currentRoadName {
            let compositeShield = NSMutableAttributedString(string: " \(roadName)")
            compositeShield.insert(compositeShieldImage, at: 0)
            currentShieldName = compositeShield
        }
        
        return (roadName: currentRoadName, shieldName: currentShieldName)
    }
    
    func roadShieldTextColor(line: Feature) -> UIColor? {
        guard let shield = line.properties?["shield"] as? String else {
            return nil
        }
        
        // shield_text_color is present in Mapbox Streets source v8 but not v7.
        guard let shieldTextColor = line.properties?["shield_text_color"] as? String else {
            let currentShield = HighwayShield.RoadType(rawValue: shield)
            return currentShield?.textColor
        }
        
        switch shieldTextColor {
        case "black":
            return .black
        case "blue":
            return .blue
        case "white":
            return .white
        case "yellow":
            return .yellow
        case "orange":
            return .orange
        default:
            return .black
        }
    }

    func roadShieldAttributedText(for text: String, textColor: UIColor, imageName: String) -> NSAttributedString? {
        guard let image = navigationMapView.mapView.style.getStyleImage(with: imageName)?.cgImage() else { return nil }
        let attachment = ShieldAttachment()
        attachment.image = UIImage(cgImage: image.takeRetainedValue()).withCenteredText(text,
                                                                                        color: textColor,
                                                                                        font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize),
                                                                                        scale: UIScreen.main.scale)
        return NSAttributedString(attachment: attachment)
    }
    
    // MARK: - Current road feature labeling utility methods
    
    /**
     Method, which returns a boolean value indicating whether the tile source is a supported version of the Mapbox Streets source.
     */
    func isMapboxStreets(_ identifiers: [String]) -> Bool {
        return identifiers.contains("mapbox.mapbox-streets-v8") || identifiers.contains("mapbox.mapbox-streets-v7")
    }
    
    /**
     Method, which returns identifiers of the tile sets that make up specific source.
     
     This array contains multiple entries for a composited source. This property is empty for non-Mapbox-hosted tile sets and sources with type other than `vector`.
     */
    func tileSetIdentifiers(_ sourceIdentifier: String, sourceType: String) -> [String] {
        do {
            if sourceType == "vector",
               let properties = try navigationMapView.mapView.__map.getStyleSourceProperties(forSourceId: sourceIdentifier).value as? Dictionary<String, Any>,
               let url = properties["url"] as? String,
               let configurationURL = URL(string: url),
               configurationURL.scheme == "mapbox",
               let tileSetIdentifiers = configurationURL.host?.components(separatedBy: ",") {
                return tileSetIdentifiers
            }
        } catch {
            NSLog("Failed to get source properties with error: \(error.localizedDescription).")
        }
        
        return []
    }
    
    /**
     Method, which returns list of source identifiers, which contain streets tile set.
     */
    func streetsSources() -> [StyleObjectInfo] {
        let streetsSources = (try? navigationMapView.mapView.__map.getStyleSources().compactMap {
            $0
        }.filter {
            let identifiers = tileSetIdentifiers($0.id, sourceType: $0.type)
            return isMapboxStreets(identifiers)
        }) ?? []
        
        return streetsSources
    }

    func showRouteIfNeeded() {
        guard isViewLoaded && view.window != nil else { return }
        guard !navigationMapView.showsRoute else { return }
        navigationMapView.show([router.route], legIndex: router.routeProgress.legIndex)
        navigationMapView.showWaypoints(on: router.route, legIndex: router.routeProgress.legIndex)
        
        let currentLegProgress = router.routeProgress.currentLegProgress
        let nextStepIndex = currentLegProgress.stepIndex + 1
        
        if nextStepIndex <= currentLegProgress.leg.steps.count {
            navigationMapView.addArrow(route: router.route, legIndex: router.routeProgress.legIndex, stepIndex: nextStepIndex)
        }

        if annotatesSpokenInstructions {
            navigationMapView.showVoiceInstructionsOnMap(route: router.route)
        }
    }
}

// MARK: - Keyboard handling methods

extension RouteMapViewController {
    
    fileprivate func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(RouteMapViewController.keyboardWillShow(notification:)), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RouteMapViewController.keyboardWillHide(notification:)), name:UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    fileprivate func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc fileprivate func keyboardWillShow(notification: NSNotification) {
        guard navigationView.endOfRouteView != nil else { return }
        guard let userInfo = notification.userInfo else { return }
        guard let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int else { return }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        guard let keyBoardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let keyboardHeight = keyBoardRect.size.height

        if #available(iOS 11.0, *) {
            navigationView.endOfRouteShowConstraint?.constant = -1 * (keyboardHeight - view.safeAreaInsets.bottom) //subtract the safe area, which is part of the keyboard's frame
        } else {
            navigationView.endOfRouteShowConstraint?.constant = -1 * keyboardHeight
        }

        let curve = UIView.AnimationCurve(rawValue: curveValue) ?? .easeIn
        let options = UIView.AnimationOptions(curve: curve) ?? .curveEaseIn
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: view.layoutIfNeeded, completion: nil)
    }

    @objc fileprivate func keyboardWillHide(notification: NSNotification) {
        guard navigationView.endOfRouteView != nil else { return }
        guard let userInfo = notification.userInfo else { return }
        guard let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int else { return }
        guard let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        navigationView.endOfRouteShowConstraint?.constant = 0

        let curve = UIView.AnimationCurve(rawValue: curveValue) ?? .easeOut
        let options = UIView.AnimationOptions(curve: curve) ?? .curveEaseOut
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: view.layoutIfNeeded, completion: nil)
    }
}

internal extension UIView.AnimationOptions {
    init?(curve: UIView.AnimationCurve) {
        switch curve {
        case .easeIn:
            self = .curveEaseIn
        case .easeOut:
            self = .curveEaseOut
        case .easeInOut:
            self = .curveEaseInOut
        case .linear:
            self = .curveLinear
        default:
            // Some private UIViewAnimationCurve values unknown to the compiler can leak through notifications.
            return nil
        }
    }
}

protocol RouteMapViewControllerDelegate: NavigationMapViewDelegate, VisualInstructionDelegate {
    func mapViewControllerDidDismiss(_ mapViewController: RouteMapViewController, byCanceling canceled: Bool)
    func mapViewControllerShouldAnnotateSpokenInstructions(_ routeMapViewController: RouteMapViewController) -> Bool

    /**
     Called to allow the delegate to customize the contents of the road name label that is displayed towards the bottom of the map view.

     This method is called on each location update. By default, the label displays the name of the road the user is currently traveling on.

     - parameter mapViewController: The route map view controller that will display the road name.
     - parameter location: The user’s current location.
     - return: The road name to display in the label, or the empty string to hide the label, or nil to query the map’s vector tiles for the road name.
     */
    func mapViewController(_ mapViewController: RouteMapViewController, roadNameAt location: CLLocation) -> String?
    
    func mapViewController(_ mapViewController: RouteMapViewController, didCenterOn location: CLLocation)
}
