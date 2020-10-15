import UIKit
import Mapbox
import MapboxDirections
import MapboxCoreNavigation
import MapboxMobileEvents
import Turf

class ArrowFillPolyline: MGLPolylineFeature {}
class ArrowStrokePolyline: ArrowFillPolyline {}

class RouteMapViewController: UIViewController {
    var navigationView: NavigationView { return view as! NavigationView }
    var mapView: NavigationMapView { return navigationView.mapView }
    var reportButton: FloatingButton { return navigationView.reportButton }
    var topBannerContainerView: BannerContainerView { return navigationView.topBannerContainerView }
    var bottomBannerContainerView: BannerContainerView { return navigationView.bottomBannerContainerView }
    
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

    var route: Route { return navService.router.route }
    var previewInstructionsView: StepInstructionsView?
    var lastTimeUserRerouted: Date?
    private lazy var geocoder: CLGeocoder = CLGeocoder()
    var destination: Waypoint?

    var showsEndOfRoute: Bool = true
    var showsSpeedLimits: Bool = true {
        didSet {
            navigationView.speedLimitView.isAlwaysHidden = !showsSpeedLimits
        }
    }

    var detailedFeedbackEnabled: Bool = false

    var pendingCamera: MGLMapCamera? {
        guard let parent = parent as? NavigationViewController else {
            return nil
        }
        return parent.pendingCamera
    }

    var tiltedCamera: MGLMapCamera {
        get {
            let camera = mapView.camera
            camera.altitude = 1000
            camera.pitch = 45
            return camera
        }
    }
    
    var styleObservation: NSKeyValueObservation?
    
    weak var delegate: RouteMapViewControllerDelegate?
    var navService: NavigationService! {
        didSet {
            guard let destination = route.legs.last?.destination else { return }
            populateName(for: destination, populated: { self.destination = $0 })
        }
    }
    var router: Router { return navService.router }
    let distanceFormatter = DistanceFormatter()
    var arrowCurrentStep: RouteStep?
    var isInOverviewMode = false {
        didSet {
            if isInOverviewMode {
                navigationView.overviewButton.isHidden = true
                navigationView.resumeButton.isHidden = false
                navigationView.wayNameView.isHidden = true
                mapView.logoView.isHidden = true
            } else {
                navigationView.overviewButton.isHidden = false
                navigationView.resumeButton.isHidden = true
                mapView.logoView.isHidden = false
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
    
    var routeLineTracksTraversal = false

    typealias LabelRoadNameCompletionHandler = (_ defaultRaodNameAssigned: Bool) -> Void

    var labelRoadNameCompletionHandler: (LabelRoadNameCompletionHandler)?
    
    /**
     A Boolean value that determines whether the map altitude should change based on internal conditions.
    */
    var suppressAutomaticAltitudeChanges: Bool = false

    convenience init(navigationService: NavigationService, delegate: RouteMapViewControllerDelegate? = nil, topBanner: ContainerViewController, bottomBanner: ContainerViewController) {
        self.init()
        self.navService = navigationService
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
        view = NavigationView(delegate: self)
        view.frame = parent?.view.bounds ?? UIScreen.main.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mapView = self.mapView
        mapView.contentInset = contentInset(forOverviewing: false)
        view.layoutIfNeeded()

        mapView.tracksUserCourse = true
        
        styleObservation = mapView.observe(\.style, options: .new) { [weak self] (mapView, change) in
            guard change.newValue != nil else {
                return
            }
            self?.showRouteIfNeeded()
            mapView.localizeLabels()
            mapView.showsTraffic = false
                        
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
        mapView.compassView.isHidden = true

        mapView.tracksUserCourse = true

        if let camera = pendingCamera {
            mapView.camera = camera
        } else if let location = router.location, location.course > 0 {
            mapView.updateCourseTracking(location: location, animated: false)
        } else if let coordinates = router.routeProgress.currentLegProgress.currentStep.shape?.coordinates, let firstCoordinate = coordinates.first, coordinates.count > 1 {
            let secondCoordinate = coordinates[1]
            let course = firstCoordinate.direction(to: secondCoordinate)
            let newLocation = CLLocation(coordinate: router.location?.coordinate ?? firstCoordinate, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: course, speed: 0, timestamp: Date())
            mapView.updateCourseTracking(location: newLocation, animated: false)
        } else {
            mapView.setCamera(tiltedCamera, animated: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        annotatesSpokenInstructions = delegate?.mapViewControllerShouldAnnotateSpokenInstructions(self) ?? false
        showRouteIfNeeded()
        currentLegIndexMapped = router.routeProgress.legIndex
        currentStepIndexMapped = router.routeProgress.currentLegProgress.stepIndex
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        styleObservation = nil
    }

    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        subscribeToKeyboardNotifications()
    }

    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
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
        mapView.tracksUserCourse = true
        mapView.enableFrameByFrameCourseViewTracking(for: 3)
        isInOverviewMode = false

        
        mapView.updateCourseTracking(location: mapView.userLocationForCourseTracking)
        updateCameraAltitude(for: router.routeProgress)
        
        mapView.addArrow(route: router.route,
                         legIndex: router.routeProgress.legIndex,
                         stepIndex: router.routeProgress.currentLegProgress.stepIndex + 1)
        
        delegate?.mapViewController(self, didCenterOn: mapView.userLocationForCourseTracking!)
    }
    
    func center(on step: RouteStep, route: Route, legIndex: Int, stepIndex: Int, animated: Bool = true, completion: CompletionHandler? = nil) {
        mapView.enableFrameByFrameCourseViewTracking(for: 1)
        mapView.tracksUserCourse = false
        mapView.setCenter(step.maneuverLocation, zoomLevel: mapView.zoomLevel, direction: step.initialHeading!, animated: animated, completionHandler: completion)
        
        guard isViewLoaded && view.window != nil else { return }
        mapView.addArrow(route: router.routeProgress.route, legIndex: legIndex, stepIndex: stepIndex)
    }

    @objc func toggleOverview(_ sender: Any) {
        mapView.enableFrameByFrameCourseViewTracking(for: 3)
        if let shape = router.route.shape,
            let userLocation = router.location {
            mapView.setOverheadCameraView(from: userLocation, along: shape, for: contentInset(forOverviewing: true))
        }
        isInOverviewMode = true
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
        let feedbackViewController = FeedbackViewController(eventsManager: navService.eventsManager)
        feedbackViewController.detailedFeedbackEnabled = detailedFeedbackEnabled
        parent.present(feedbackViewController, animated: true, completion: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        mapView.enableFrameByFrameCourseViewTracking(for: 3)
        navigationView.reinstallRequiredConstraints()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if (mapView.showsUserLocation && !mapView.tracksUserCourse) {
            // Don't move mapView content on rotation or when e.g. top banner expands.
            return
        }
        
        updateMapViewContentInsets()
    }
    
    func updateMapViewContentInsets(animated: Bool = false, completion: CompletionHandler? = nil) {
        mapView.setContentInset(contentInset(forOverviewing: isInOverviewMode), animated: animated, completionHandler: completion)
        mapView.setNeedsUpdateConstraints()
    }

    @objc func applicationWillEnterForeground(notification: NSNotification) {
        mapView.updateCourseTracking(location: router.location, animated: false)
    }

    func updateMapOverlays(for routeProgress: RouteProgress) {
        if routeProgress.currentLegProgress.followOnStep != nil {
            mapView.addArrow(route: route, legIndex: router.routeProgress.legIndex, stepIndex: router.routeProgress.currentLegProgress.stepIndex + 1)
        } else {
            mapView.removeArrow()
        }
    }

    func updateCameraAltitude(for routeProgress: RouteProgress, completion: CompletionHandler? = nil) {
        guard mapView.tracksUserCourse else { return } //only adjust when we are actively tracking user course

        let zoomOutAltitude = mapView.zoomedOutMotorwayAltitude
        let defaultAltitude = mapView.defaultAltitude
        let isLongRoad = routeProgress.distanceRemaining >= mapView.longManeuverDistance
        let currentStep = routeProgress.currentLegProgress.currentStep
        let upComingStep = routeProgress.currentLegProgress.upcomingStep

        //If the user is at the last turn maneuver, the map should zoom in to the default altitude.
        let currentInstruction = routeProgress.currentLegProgress.currentStepProgress.currentSpokenInstruction

        //If the user is on a motorway, not exiting, and their segment is sufficently long, the map should zoom out to the motorway altitude.
        //otherwise, zoom in if it's the last instruction on the step.
        let currentStepIsMotorway = currentStep.isMotorway
        let nextStepIsMotorway = upComingStep?.isMotorway ?? false
        if currentStepIsMotorway, nextStepIsMotorway, isLongRoad {
            setCamera(altitude: zoomOutAltitude)
        } else if currentInstruction == currentStep.lastInstruction {
            setCamera(altitude: defaultAltitude)
        }
    }

    private func setCamera(altitude: Double) {
        guard mapView.altitude != altitude else { return }
        mapView.altitude = altitude
    }
    
    /** Modifies the gesture recognizers to also update the map’s frame rate. */
    func makeGestureRecognizersResetFrameRate() {
        for gestureRecognizer in mapView.gestureRecognizers ?? [] {
            gestureRecognizer.addTarget(self, action: #selector(resetFrameRate(_:)))
        }
    }
    
    @objc func resetFrameRate(_ sender: UIGestureRecognizer) {
        mapView.preferredFramesPerSecond = NavigationMapView.FrameIntervalOptions.defaultFramesPerSecond
    }
    
    func contentInset(forOverviewing overviewing: Bool) -> UIEdgeInsets {
        let instructionBannerHeight = topBannerContainerView.bounds.height
        let bottomBannerHeight = bottomBannerContainerView.bounds.height
        
        // Inset by the safe area to avoid notches.
        var insets = mapView.safeArea
        insets.top += instructionBannerHeight
        insets.bottom += bottomBannerHeight
        
        if overviewing {
            insets += NavigationMapView.courseViewMinimumInsets
            
            let routeLineWidths = MBRouteLineWidthByZoomLevel.compactMap { $0.value.constantValue as? Int }
            insets += UIEdgeInsets(floatLiteral: Double(routeLineWidths.max() ?? 0))
        } else if mapView.tracksUserCourse {
            // Puck position calculation - position it just above the bottom of the content area.
            var contentFrame = mapView.bounds.inset(by: insets)

            // Avoid letting the puck go partially off-screen, and add a comfortable padding beyond that.
            let courseViewBounds = mapView.userCourseView.bounds
            // If it is not possible to position it right above the content area, center it at the remaining space.
            contentFrame = contentFrame.insetBy(dx: min(NavigationMapView.courseViewMinimumInsets.left + courseViewBounds.width / 2.0, contentFrame.width / 2.0),
                                                dy: min(NavigationMapView.courseViewMinimumInsets.top + courseViewBounds.height / 2.0, contentFrame.height / 2.0))
            assert(!contentFrame.isInfinite)

            let y = contentFrame.maxY
            let height = mapView.bounds.height
            insets.top = height - insets.bottom - 2 * (height - insets.bottom - y)
        }
        
        return insets
    }

    // MARK: End Of Route

    func embedEndOfRoute() {
        let endOfRoute = endOfRouteViewController
        addChild(endOfRoute)
        navigationView.endOfRouteView = endOfRoute.view
        navigationView.constrainEndOfRoute()
        endOfRoute.didMove(toParent: self)

        endOfRoute.dismissHandler = { [weak self] (stars, comment) in
            guard let rating = self?.rating(for: stars) else { return }
            let feedback = EndOfRouteFeedback(rating: rating, comment: comment)
            self?.navService.endNavigation(feedback: feedback)
            self?.delegate?.mapViewControllerDidDismiss(self!, byCanceling: false)
        }
    }

    func unembedEndOfRoute() {
        let endOfRoute = endOfRouteViewController
        endOfRoute.willMove(toParent: nil)
        endOfRoute.removeFromParent()
    }

    func showEndOfRoute(duration: TimeInterval = 1.0, completion: ((Bool) -> Void)? = nil) {
        embedEndOfRoute()
        endOfRouteViewController.destination = destination
        navigationView.endOfRouteView?.isHidden = false

        view.layoutIfNeeded() //flush layout queue
        navigationView.endOfRouteHideConstraint?.isActive = false
        navigationView.endOfRouteShowConstraint?.isActive = true

        mapView.enableFrameByFrameCourseViewTracking(for: duration)
        mapView.setNeedsUpdateConstraints()

        let animate = {
            self.view.layoutIfNeeded()
            self.navigationView.floatingStackView.alpha = 0.0
        }

        let noAnimation = { animate(); completion?(true) }

        guard duration > 0.0 else { return noAnimation() }

        navigationView.mapView.tracksUserCourse = false
        UIView.animate(withDuration: duration, delay: 0.0, options: [.curveLinear], animations: animate, completion: completion)

        guard let height = navigationView.endOfRouteHeightConstraint?.constant else { return }
        let insets = UIEdgeInsets(top: topBannerContainerView.bounds.height, left: 20, bottom: height + 20, right: 20)
        
        if let shape = route.shape, let userLocation = navService.router.location?.coordinate, !shape.coordinates.isEmpty {
            let slicedLineString = shape.sliced(from: userLocation)!
            let line = MGLPolyline(slicedLineString)

            let camera = navigationView.mapView.cameraThatFitsShape(line, direction: navigationView.mapView.camera.heading, edgePadding: insets)
            camera.pitch = 0
            camera.altitude = navigationView.mapView.camera.altitude
            navigationView.mapView.setCamera(camera, animated: true)
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

        mapView.updatePreferredFrameRate(for: progress)
        if currentLegIndexMapped != legIndex {
            mapView.showWaypoints(on: route, legIndex: legIndex)
            mapView.show([route], legIndex: legIndex)
            
            currentLegIndexMapped = legIndex
        }
        
        if currentStepIndexMapped != stepIndex {
            updateMapOverlays(for: progress)
            currentStepIndexMapped = stepIndex
        }
        
        if annotatesSpokenInstructions {
            mapView.showVoiceInstructionsOnMap(route: route)
        }
        
        if routeLineTracksTraversal {
            mapView.updateRoute(progress)
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
        
        mapView.removeWaypoints()
        
        mapView.addArrow(route: route, legIndex: legIndex, stepIndex: stepIndex + 1)
        mapView.show([route], legIndex: legIndex)
        mapView.showWaypoints(on: route)
        
        if annotatesSpokenInstructions {
            mapView.showVoiceInstructionsOnMap(route: route)
        }
        
        if isInOverviewMode {
            if let shape = route.shape, let userLocation = router.location {
                mapView.setOverheadCameraView(from: userLocation, along: shape, for: contentInset(forOverviewing: true))
            }
        } else {
            mapView.tracksUserCourse = true
            navigationView.wayNameView.isHidden = true
        }
    }
    
    func navigationService(_ service: NavigationService, didRefresh routeProgress: RouteProgress) {
        mapView.show([routeProgress.route], legIndex: routeProgress.legIndex)
        if routeLineTracksTraversal {
            mapView.updateRoute(routeProgress)
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

// MARK: - NavigationViewDelegate

extension RouteMapViewController: NavigationViewDelegate {
    // MARK: NavigationViewDelegate
    func navigationView(_ view: NavigationView, didTapCancelButton: CancelButton) {
        delegate?.mapViewControllerDidDismiss(self, byCanceling: true)
    }
    
    // MARK: VisualInstructionDelegate
    
    func label(_ label: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString? {
        return delegate?.label(label, willPresent: instruction, as: presented)
    }

    // MARK: NavigationMapViewCourseTrackingDelegate
    func navigationMapViewDidStartTrackingCourse(_ mapView: NavigationMapView) {
        navigationView.resumeButton.isHidden = true
        mapView.logoView.isHidden = false
    }

    func navigationMapViewDidStopTrackingCourse(_ mapView: NavigationMapView) {
        navigationView.resumeButton.isHidden = false
        navigationView.wayNameView.isHidden = true
        mapView.logoView.isHidden = true
    }

    //MARK: NavigationMapViewDelegate

    func navigationMapView(_ mapView: NavigationMapView, mainRouteStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationMapView(mapView, mainRouteStyleLayerWithIdentifier: identifier, source: source)
    }

    func navigationMapView(_ mapView: NavigationMapView, mainRouteCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationMapView(mapView, mainRouteCasingStyleLayerWithIdentifier: identifier, source: source)
    }

    func navigationMapView(_ mapView: NavigationMapView, alternativeRouteStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationMapView(mapView, alternativeRouteStyleLayerWithIdentifier: identifier, source: source)
    }

    func navigationMapView(_ mapView: NavigationMapView, alternativeRouteCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationMapView(mapView, alternativeRouteCasingStyleLayerWithIdentifier: identifier, source: source)
    }

    func navigationMapView(_ mapView: NavigationMapView, waypointStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationMapView(mapView, waypointStyleLayerWithIdentifier: identifier, source: source)
    }

    func navigationMapView(_ mapView: NavigationMapView, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationMapView(mapView, waypointSymbolStyleLayerWithIdentifier: identifier, source: source)
    }

    func navigationMapView(_ mapView: NavigationMapView, shapeFor waypoints: [Waypoint], legIndex: Int) -> MGLShape? {
        return delegate?.navigationMapView(mapView, shapeFor: waypoints, legIndex: legIndex)
    }

    func navigationMapView(_ mapView: NavigationMapView, shapeFor routes: [Route]) -> MGLShape? {
        return delegate?.navigationMapView(mapView, shapeFor: routes)
    }

    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        delegate?.navigationMapView(mapView, didSelect: route)
    }

    func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeFor route: Route) -> MGLShape? {
        return delegate?.navigationMapView(mapView, simplifiedShapeFor: route)
    }

    func navigationMapViewUserAnchorPoint(_ mapView: NavigationMapView) -> CGPoint {
        //If the end of route component is showing, then put the anchor point slightly above the middle of the map
        if navigationView.endOfRouteView != nil, let show = navigationView.endOfRouteShowConstraint, show.isActive {
            return CGPoint(x: mapView.bounds.midX, y: (mapView.bounds.height * 0.4))
        }

        //otherwise, ask the delegate or return .zero
        return delegate?.navigationMapViewUserAnchorPoint(mapView) ?? .zero
    }

    /**
     Updates the current road name label to reflect the road on which the user is currently traveling.

     - parameter location: The user’s current location.
     */
    func labelCurrentRoad(at rawLocation: CLLocation, for snappedLocation: CLLocation? = nil) {
        guard navigationView.resumeButton.isHidden else {
            return
        }

        let roadName = delegate?.mapViewController(self, roadNameAt: rawLocation)
        guard roadName == nil else {
            if let roadName = roadName {
                navigationView.wayNameView.text = roadName
                navigationView.wayNameView.isHidden = roadName.isEmpty
            }
            return
        }

        // Avoid aggressively opting the developer into Mapbox services if they
        // haven’t provided an access token.
        guard let _ = MGLAccountManager.accessToken else {
            navigationView.wayNameView.isHidden = true
            return
        }

        let location = snappedLocation ?? rawLocation

        labelCurrentRoadFeature(at: location)

        if let labelRoadNameCompletionHandler = labelRoadNameCompletionHandler {
            labelRoadNameCompletionHandler(true)
        }
    }

    func labelCurrentRoadFeature(at location: CLLocation) {
        guard let style = mapView.style, let stepShape = router.routeProgress.currentLegProgress.currentStep.shape, !stepShape.coordinates.isEmpty else {
                return
        }

        let closestCoordinate = location.coordinate
        let roadLabelStyleLayerIdentifier = "\(identifierNamespace).roadLabels"
        var streetsSources: [MGLVectorTileSource] = style.sources.compactMap {
            $0 as? MGLVectorTileSource
            }.filter {
                $0.isMapboxStreets
        }

        // Add Mapbox Streets if the map does not already have it
        if streetsSources.isEmpty {
            let source = MGLVectorTileSource(identifier: "com.mapbox.MapboxStreets", configurationURL: URL(string: "mapbox://mapbox.mapbox-streets-v8")!)
            style.addSource(source)
            streetsSources.append(source)
        }

        if let mapboxStreetsSource = streetsSources.first, style.layer(withIdentifier: roadLabelStyleLayerIdentifier) == nil {
            let streetLabelLayer = MGLLineStyleLayer(identifier: roadLabelStyleLayerIdentifier, source: mapboxStreetsSource)
            streetLabelLayer.sourceLayerIdentifier = mapboxStreetsSource.roadLabelLayerIdentifier
            streetLabelLayer.lineOpacity = NSExpression(forConstantValue: 1)
            streetLabelLayer.lineWidth = NSExpression(forConstantValue: 20)
            streetLabelLayer.lineColor = NSExpression(forConstantValue: UIColor.white)

            if ![DirectionsProfileIdentifier.walking, DirectionsProfileIdentifier.cycling].contains( router.routeProgress.routeOptions.profileIdentifier) {
                // filter out to road classes valid for motor transport
                let roadPredicates = ["motorway", "motorway_link", "trunk", "trunk_link", "primary", "primary_link", "secondary", "secondary_link", "tertiary", "tertiary_link", "street", "street_limited", "roundabout"]

                let compoundPredicate = NSPredicate(format: "class IN %@", roadPredicates)
                streetLabelLayer.predicate = compoundPredicate
            }
            style.insertLayer(streetLabelLayer, at: 0)
        }

        let userPuck = mapView.convert(closestCoordinate, toPointTo: mapView)
        let features = mapView.visibleFeatures(at: userPuck, styleLayerIdentifiers: Set([roadLabelStyleLayerIdentifier]))
        var smallestLabelDistance = Double.infinity
        var currentName: String?
        var currentShieldName: NSAttributedString?
        let slicedLine = stepShape.sliced(from: closestCoordinate)!

        for feature in features {
            var allLines: [MGLPolyline] = []

            if let line = feature as? MGLPolylineFeature {
                allLines.append(line)
            } else if let lines = feature as? MGLMultiPolylineFeature {
                allLines = lines.polylines
            }

            for line in allLines {
                guard line.pointCount > 0 else { continue }
                let featureCoordinates =  Array(UnsafeBufferPointer(start: line.coordinates, count: Int(line.pointCount)))
                let featurePolyline = LineString(featureCoordinates)

                let lookAheadDistance: CLLocationDistance = 10
                guard let pointAheadFeature = featurePolyline.sliced(from: closestCoordinate)!.coordinateFromStart(distance: lookAheadDistance) else { continue }
                guard let pointAheadUser = slicedLine.coordinateFromStart(distance: lookAheadDistance) else { continue }
                guard let reversedPoint = LineString(featureCoordinates.reversed()).sliced(from: closestCoordinate)!.coordinateFromStart(distance: lookAheadDistance) else { continue }

                let distanceBetweenPointsAhead = pointAheadFeature.distance(to: pointAheadUser)
                let distanceBetweenReversedPoint = reversedPoint.distance(to: pointAheadUser)
                let minDistanceBetweenPoints = min(distanceBetweenPointsAhead, distanceBetweenReversedPoint)

                if minDistanceBetweenPoints < smallestLabelDistance {
                    smallestLabelDistance = minDistanceBetweenPoints

                    if let line = feature as? MGLPolylineFeature {
                        let roadNameRecord = roadFeature(for: line)
                        currentShieldName = roadNameRecord.shieldName
                        currentName = roadNameRecord.roadName
                    } else if let line = feature as? MGLMultiPolylineFeature {
                        let roadNameRecord = roadFeature(for: line)
                        currentShieldName = roadNameRecord.shieldName
                        currentName = roadNameRecord.roadName
                    }
                }
            }
        }

        let hasWayName = currentName != nil || currentShieldName != nil
        if smallestLabelDistance < 5 && hasWayName  {
            if let currentShieldName = currentShieldName {
                navigationView.wayNameView.attributedText = currentShieldName
            } else if let currentName = currentName {
                navigationView.wayNameView.text = currentName
            }
            navigationView.wayNameView.isHidden = false
        } else {
            navigationView.wayNameView.isHidden = true
        }
    }

    private func roadFeature(for line: MGLFeature) -> (roadName: String?, shieldName: NSAttributedString?) {
        var currentShieldName: NSAttributedString?, currentRoadName: String?

        if let ref = line.attribute(forKey: "ref") as? String,
            let shield = line.attribute(forKey: "shield") as? String,
            let reflen = line.attribute(forKey: "reflen") as? Int {
            let textColor = roadShieldTextColor(line: line) ?? .black
            let imageName = "\(shield)-\(reflen)"
            currentShieldName = roadShieldAttributedText(for: ref, textColor: textColor, imageName: imageName)
        }

        if let roadName = line.attribute(forKey: "name") as? String {
            currentRoadName = roadName
        }

        if let compositeShieldImage = currentShieldName, let roadName = currentRoadName {
            let compositeShield = NSMutableAttributedString(string: " \(roadName)")
            compositeShield.insert(compositeShieldImage, at: 0)
            currentShieldName = compositeShield
        }

        return (roadName: currentRoadName, shieldName: currentShieldName)
    }
    
    func roadShieldTextColor(line: MGLFeature) -> UIColor? {
        guard let shield = line.attribute(forKey: "shield") as? String else {
            return nil
        }
        
        // shield_text_color is present in Mapbox Streets source v8 but not v7.
        guard let shieldTextColor = line.attribute(forKey: "shield_text_color") as? String else {
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

    private func roadShieldAttributedText(for text: String, textColor: UIColor, imageName: String) -> NSAttributedString? {
        guard let image = mapView.style?.image(forName: imageName) else {
            return nil
        }

        let attachment = ShieldAttachment()
        attachment.image = image.withCenteredText(text, color: textColor, font: UIFont.boldSystemFont(ofSize: UIFont.systemFontSize), scale: UIScreen.main.scale)
        return NSAttributedString(attachment: attachment)
    }

    func showRouteIfNeeded() {
        guard isViewLoaded && view.window != nil else { return }
        guard !mapView.showsRoute else { return }
        mapView.show([router.route], legIndex: router.routeProgress.legIndex)
        mapView.showWaypoints(on: router.route, legIndex: router.routeProgress.legIndex)
        
        let currentLegProgress = router.routeProgress.currentLegProgress
        let nextStepIndex = currentLegProgress.stepIndex + 1
        
        if nextStepIndex <= currentLegProgress.leg.steps.count {
            mapView.addArrow(route: router.route, legIndex: router.routeProgress.legIndex, stepIndex: nextStepIndex)
        }

        if annotatesSpokenInstructions {
            mapView.showVoiceInstructionsOnMap(route: router.route)
        }
    }
}

// MARK: - Keyboard Handling

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
