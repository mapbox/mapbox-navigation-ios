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
    var statusView: StatusView { return navigationView.statusView }
    var reportButton: FloatingButton { return navigationView.reportButton }
    var lanesView: LanesView { return navigationView.lanesView }
    var nextBannerView: NextBannerView { return navigationView.nextBannerView }
    var instructionsBannerView: InstructionsBannerView { return navigationView.instructionsBannerView }
    
    lazy var endOfRouteViewController: EndOfRouteViewController = {
        let storyboard = UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
        let viewController = storyboard.instantiateViewController(withIdentifier: "EndOfRouteViewController") as! EndOfRouteViewController
        return viewController
    }()
    
    lazy var feedbackViewController: FeedbackViewController = {
        let controller = FeedbackViewController()
        
        controller.sections = [
            [.turnNotAllowed, .closure, .reportTraffic],
            [.confusingInstructions, .generalMapError, .badRoute]
        ]
        
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = controller
        return controller
    }()
    
    private struct Actions {
        static let overview: Selector = #selector(RouteMapViewController.toggleOverview(_:))
        static let mute: Selector = #selector(RouteMapViewController.toggleMute(_:))
        static let feedback: Selector = #selector(RouteMapViewController.feedback(_:))
        static let rerouteFeedback: Selector = #selector(RouteMapViewController.rerouteFeedback(_:))
        static let recenter: Selector = #selector(RouteMapViewController.recenter(_:))
    }

    var route: Route { return routeController.routeProgress.route }
    var updateETATimer: Timer?
    var previewInstructionsView: StepInstructionsView?
    var lastTimeUserRerouted: Date?
    var stepsViewController: StepsViewController?
    private lazy var geocoder: CLGeocoder = CLGeocoder()
    var destination: Waypoint?
    
    var showsEndOfRoute: Bool = true

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
    
    weak var delegate: RouteMapViewControllerDelegate?
    var routeController: RouteController! {
        didSet {
            navigationView.statusView.canChangeValue = routeController.locationManager is SimulatedLocationManager
            guard let destination = route.legs.last?.destination else { return }
            populateName(for: destination, populated: { self.destination = $0 })
        }
    }
    let distanceFormatter = DistanceFormatter(approximate: true)
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
    
    /**
     A Boolean value that determines whether the map annotates the locations at which instructions are spoken for debugging purposes.
     */
    var annotatesSpokenInstructions = false
    
    var overheadInsets: UIEdgeInsets {
        return UIEdgeInsets(top: navigationView.instructionsBannerView.bounds.height, left: 20, bottom: navigationView.bottomBannerView.bounds.height, right: 20)
    }
    

    convenience init(routeController: RouteController, delegate: RouteMapViewControllerDelegate? = nil) {
        self.init()
        self.routeController = routeController
        self.delegate = delegate
        automaticallyAdjustsScrollViewInsets = false
    }
    
    
    override func loadView() {
        view = NavigationView(delegate: self)
        view.frame = parent?.view.bounds ?? UIScreen.main.bounds
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.contentInset = contentInsets
        view.layoutIfNeeded()
        
        mapView.tracksUserCourse = true
        
        
        distanceFormatter.numberFormatter.locale = .nationalizedCurrent
        
        navigationView.overviewButton.addTarget(self, action: Actions.overview, for: .touchUpInside)
        navigationView.muteButton.addTarget(self, action: Actions.mute, for: .touchUpInside)
        navigationView.reportButton.addTarget(self, action: Actions.feedback, for: .touchUpInside)
        navigationView.rerouteReportButton.addTarget(self, action: Actions.rerouteFeedback, for: .touchUpInside)
        navigationView.resumeButton.addTarget(self, action: Actions.recenter, for: .touchUpInside)
        resumeNotifications()
    }
    
    deinit {
        suspendNotifications()
        removeTimer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        resetETATimer()
        
        navigationView.muteButton.isSelected = NavigationSettings.shared.voiceMuted
        mapView.compassView.isHidden = true
        
        mapView.tracksUserCourse = true
        
        if let camera = pendingCamera {
            mapView.camera = camera
        } else if let location = routeController.location, location.course > 0 {
            mapView.updateCourseTracking(location: location, animated: false)
        } else if let coordinates = routeController.routeProgress.currentLegProgress.currentStep.coordinates, let firstCoordinate = coordinates.first, coordinates.count > 1 {
            let secondCoordinate = coordinates[1]
            let course = firstCoordinate.direction(to: secondCoordinate)
            let newLocation = CLLocation(coordinate: routeController.location?.coordinate ?? firstCoordinate, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: course, speed: 0, timestamp: Date())
            mapView.updateCourseTracking(location: newLocation, animated: false)
        } else {
            mapView.setCamera(tiltedCamera, animated: false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        annotatesSpokenInstructions = delegate?.mapViewControllerShouldAnnotateSpokenInstructions(self) ?? false
        showRouteIfNeeded()
        currentLegIndexMapped = routeController.routeProgress.legIndex
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeTimer()
    }

    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(willReroute(notification:)), name: .routeControllerWillReroute, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReroute(notification:)), name: .routeControllerDidReroute, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(notification:)), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(removeTimer), name: .UIApplicationDidEnterBackground, object: nil)
        subscribeToKeyboardNotifications()
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: .routeControllerWillReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidEnterBackground, object: nil)
        unsubscribeFromKeyboardNotifications()
    }

    @objc func recenter(_ sender: AnyObject) {
        mapView.tracksUserCourse = true
        mapView.enableFrameByFrameCourseViewTracking(for: 3)
        isInOverviewMode = false
        updateCameraAltitude(for: routeController.routeProgress)
        
        mapView.addArrow(route: routeController.routeProgress.route,
                         legIndex: routeController.routeProgress.legIndex,
                         stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
        
        removePreviewInstructions()
    }
    
    @objc func removeTimer() {
        updateETATimer?.invalidate()
        updateETATimer = nil
    }
    
    func removePreviewInstructions() {
        if let view = previewInstructionsView {
            view.removeFromSuperview()
            navigationView.instructionsBannerContentView.backgroundColor = InstructionsBannerView.appearance().backgroundColor
            previewInstructionsView = nil
        }
    }

    @objc func toggleOverview(_ sender: Any) {
        mapView.enableFrameByFrameCourseViewTracking(for: 3)
        if let coordinates = routeController.routeProgress.route.coordinates, let userLocation = routeController.locationManager.location?.coordinate {
            mapView.setOverheadCameraView(from: userLocation, along: coordinates, for: overheadInsets)
        }
        isInOverviewMode = true
    }
    
    @objc func toggleMute(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected

        let muted = sender.isSelected
        NavigationSettings.shared.voiceMuted = muted
    }
    
    @objc func rerouteFeedback(_ sender: Any) {
        showFeedback(source: .reroute)
        navigationView.rerouteReportButton.slideUp(constraint: navigationView.rerouteFeedbackTopConstraint)
        delegate?.mapViewControllerDidOpenFeedback(self)
    }
    
    @objc func feedback(_ sender: Any) {
        showFeedback()
        delegate?.mapViewControllerDidOpenFeedback(self)
    }
    
    func showFeedback(source: FeedbackSource = .user) {
        guard let parent = parent else { return }
    
        let controller = feedbackViewController
        let defaults = defaultFeedbackHandlers() //this is done every time to refresh the feedbackId
        controller.sendFeedbackHandler = defaults.send
        controller.dismissFeedbackHandler = defaults.dismiss
        
        parent.present(controller, animated: true, completion: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        mapView.enableFrameByFrameCourseViewTracking(for: 3)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapView.setContentInset(contentInsets, animated: true)
        mapView.setNeedsUpdateConstraints()
    }

    func notifyDidReroute(route: Route) {
        updateETA()
        
        instructionsBannerView.update(for: routeController.routeProgress.currentLegProgress)
        lanesView.update(for: routeController.routeProgress.currentLegProgress)
        if lanesView.isHidden {
            nextBannerView.update(for: routeController.routeProgress)
        }
        
        mapView.addArrow(route: routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex, stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
        mapView.showRoutes([routeController.routeProgress.route], legIndex: routeController.routeProgress.legIndex)
        
        if annotatesSpokenInstructions {
            mapView.showVoiceInstructionsOnMap(route: routeController.routeProgress.route)
        }

        if isInOverviewMode {
            if let coordinates = routeController.routeProgress.route.coordinates, let userLocation = routeController.locationManager.location?.coordinate {
                mapView.setOverheadCameraView(from: userLocation, along: coordinates, for: overheadInsets)
            }
        } else {
            mapView.tracksUserCourse = true
            navigationView.wayNameView.isHidden = true
        }
        
        stepsViewController?.dismiss {
            self.removePreviewInstructions()
            self.stepsViewController = nil
        }
    }
    
    @objc func applicationWillEnterForeground(notification: NSNotification) {
        mapView.updateCourseTracking(location: routeController.location, animated: false)
        resetETATimer()
    }
    
    @objc func willReroute(notification: NSNotification) {
        let title = NSLocalizedString("REROUTING", bundle: .mapboxNavigation, value: "Rerouting…", comment: "Indicates that rerouting is in progress")
        lanesView.hide()
        statusView.show(title, showSpinner: true)
    }
    
    @objc func didReroute(notification: NSNotification) {
        guard self.isViewLoaded else { return }
        
        if !(routeController.locationManager is SimulatedLocationManager) {
            statusView.hide(delay: 2, animated: true)
            
            if !navigationView.reportButton.isHidden {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                    self.navigationView.rerouteReportButton.slideDown(constraint: self.navigationView.rerouteFeedbackTopConstraint, interval: 5)
                })
            }
        }
        
        if notification.userInfo![RouteControllerNotificationUserInfoKey.isProactiveKey] as! Bool {
            let title = NSLocalizedString("FASTER_ROUTE_FOUND", bundle: .mapboxNavigation, value: "Faster Route Found", comment: "Indicates a faster route was found")
            showStatus(title: title, withSpinner: true, for: 3)
        }
    }

    func updateMapOverlays(for routeProgress: RouteProgress) {
        if routeProgress.currentLegProgress.followOnStep != nil {
            mapView.addArrow(route: routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex, stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
        } else {
            mapView.removeArrow()
        }
    }

    func updateCameraAltitude(for routeProgress: RouteProgress) {
        guard mapView.tracksUserCourse else { return } //only adjust when we are actively tracking user course
        
        let zoomOutAltitude = NavigationMapView.zoomedOutMotorwayAltitude
        let defaultAltitude = NavigationMapView.defaultAltitude
        let isLongRoad = routeProgress.distanceRemaining >= NavigationMapView.longManeuverDistance
        let currentStep = routeProgress.currentLegProgress.currentStep
        let upComingStep = routeProgress.currentLegProgress.upComingStep
        
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
    
    private func showStatus(title: String, withSpinner spin: Bool = false, for time: TimeInterval, animated: Bool = true, interactive: Bool = false) {
        statusView.show(title, showSpinner: spin, interactive: interactive)
        guard time < .infinity else { return }
        statusView.hide(delay: time, animated: animated)
    }
    
    private func setCamera(altitude: Double) {
        guard mapView.altitude != altitude else { return }
        mapView.altitude = altitude
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        return navigationMapView(mapView, imageFor: annotation)
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return navigationMapView(mapView, viewFor: annotation)
    }

    func notifyDidChange(routeProgress: RouteProgress, location: CLLocation, secondsRemaining: TimeInterval) {
        resetETATimer()
        
        updateETA()
        
        lanesView.update(for: routeProgress.currentLegProgress)
        instructionsBannerView.update(for: routeProgress.currentLegProgress)
        if lanesView.isHidden {
            nextBannerView.update(for: routeProgress)
        }
        
        if currentLegIndexMapped != routeProgress.legIndex {
            mapView.showWaypoints(routeProgress.route, legIndex: routeProgress.legIndex)
            mapView.showRoutes([routeProgress.route], legIndex: routeProgress.legIndex)
            
            currentLegIndexMapped = routeProgress.legIndex
        }
        
        if annotatesSpokenInstructions {
            mapView.showVoiceInstructionsOnMap(route: routeController.routeProgress.route)
        }
    }
    
func defaultFeedbackHandlers(source: FeedbackSource = .user) -> (send: FeedbackViewController.SendFeedbackHandler, dismiss: () -> Void) {
        let identifier = routeController.recordFeedback()
        let send = defaultSendFeedbackHandler(feedbackId: identifier)
        let dismiss = defaultDismissFeedbackHandler(feedbackId: identifier)
        
        return (send, dismiss)
    }
    
    func defaultSendFeedbackHandler(source: FeedbackSource = .user, feedbackId identifier: String) -> FeedbackViewController.SendFeedbackHandler {
        return { [weak self] (item) in
            guard let strongSelf = self, let parent = strongSelf.parent else { return }
        
            strongSelf.delegate?.mapViewController(strongSelf, didSend: identifier, feedbackType: item.feedbackType)
            strongSelf.routeController.updateFeedback(feedbackId: identifier, type: item.feedbackType, source: source, description: nil)
            strongSelf.dismiss(animated: true) {
                DialogViewController().present(on: parent)
            }
        }
    }
    
    func defaultDismissFeedbackHandler(feedbackId identifier: String) -> (() -> Void) {
        return { [weak self ] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.mapViewControllerDidCancelFeedback(strongSelf)
            strongSelf.routeController.cancelFeedback(feedbackId: identifier)
            strongSelf.dismiss(animated: true, completion: nil)
        }
    }
    
    var contentInsets: UIEdgeInsets {
        let top = navigationView.instructionsBannerContentView.bounds.height
        let bottom = navigationView.bottomBannerView.bounds.height
        return UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
    }
    
    // MARK: End Of Route
    
    func embedEndOfRoute() {
        let endOfRoute = endOfRouteViewController
        addChildViewController(endOfRoute)
        navigationView.endOfRouteView = endOfRoute.view
        navigationView.constrainEndOfRoute()
        endOfRoute.didMove(toParentViewController: self)
        
        endOfRoute.dismissHandler = { [weak self] (stars, comment) in
            guard let rating = self?.rating(for: stars) else { return }
            self?.routeController.setEndOfRoute(rating: rating, comment: comment)
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    func unembedEndOfRoute() {
        let endOfRoute = endOfRouteViewController
        endOfRoute.willMove(toParentViewController: nil)
        endOfRoute.removeFromParentViewController()
    }
    
    func showEndOfRoute(duration: TimeInterval = 0.3, completion: ((Bool) -> Void)? = nil) {
        embedEndOfRoute()
        endOfRouteViewController.destination = destination
        navigationView.endOfRouteView?.isHidden = false

        view.layoutIfNeeded() //flush layout queue
        NSLayoutConstraint.deactivate(navigationView.bannerShowConstraints)
        NSLayoutConstraint.activate(navigationView.bannerHideConstraints)
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
        UIView.animate(withDuration: duration, delay: 0.0, options: [.curveLinear], animations: animate, completion: completion)
        
        // Prevent the user puck from floating around.
        mapView.updateCourseTracking(location: routeController.location, animated: false)
    }
    
    func hideEndOfRoute(duration: TimeInterval = 0.3, completion: ((Bool) -> Void)? = nil) {
        view.layoutIfNeeded() //flush layout queue
        navigationView.endOfRouteHideConstraint?.isActive = true
        navigationView.endOfRouteShowConstraint?.isActive = false
        view.clipsToBounds = true
        
        mapView.enableFrameByFrameCourseViewTracking(for: duration)
        mapView.setNeedsUpdateConstraints()

        let animate = {
            self.view.layoutIfNeeded()
            self.navigationView.floatingStackView.alpha = 1.0
        }
        
        let complete: (Bool) -> Void = {
            self.navigationView.endOfRouteView?.isHidden = true
            self.unembedEndOfRoute()
            completion?($0)
        }
        
        let noAnimation = {
            animate()
            complete(true)
        }

        guard duration > 0.0 else { return noAnimation() }
        UIView.animate(withDuration: duration, delay: 0.0, options: [.curveLinear], animations: animate, completion: complete)
    }
    
    fileprivate func rating(for stars: Int) -> Int {
        assert(stars >= 0 && stars <= 5)
        guard stars > 0 else { return MMEEventsManager.unrated } //zero stars means this was unrated.
        return (stars - 1) * 25
    }

    fileprivate func populateName(for waypoint: Waypoint, populated: @escaping (Waypoint) -> Void) {
        guard waypoint.name == nil else { return populated(waypoint) }
        CLGeocoder().reverseGeocodeLocation(waypoint.location) { (places, error) in
        guard let place = places?.first, let placeName = place.name, error == nil else { return }
            let named = Waypoint(coordinate: waypoint.coordinate, name: placeName)
            return populated(named)
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
        delegate?.mapViewControllerDidCancelNavigation(self)
    }
    
    // MARK: MGLMapViewDelegate
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        var userTrackingMode = mapView.userTrackingMode
        if let mapView = mapView as? NavigationMapView, mapView.tracksUserCourse {
            userTrackingMode = .followWithCourse
        }
        if userTrackingMode == .none && !isInOverviewMode {
            navigationView.wayNameView.isHidden = true
        }
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        // This method is called before the view is added to a window
        // (if the style is cached) preventing UIAppearance to apply the style.
        showRouteIfNeeded()
        self.mapView.localizeLabels()
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
    
    //MARK: InstructionsBannerViewDelegate
    func didDragInstructionsBanner(_ sender: BaseInstructionsBannerView) {
        displayPreviewInstructions()
    }
    
    func didTapInstructionsBanner(_ sender: BaseInstructionsBannerView) {
        displayPreviewInstructions()
    }
 
    private func displayPreviewInstructions() {
        removePreviewInstructions()
        
        if let controller = stepsViewController {
            stepsViewController = nil
            controller.dismiss()
        } else {
            let controller = StepsViewController(routeProgress: routeController.routeProgress)
            controller.delegate = self
            addChildViewController(controller)
            view.insertSubview(controller.view, belowSubview: navigationView.instructionsBannerContentView)
            
            controller.view.topAnchor.constraint(equalTo: navigationView.instructionsBannerContentView.bottomAnchor).isActive = true
            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            
            controller.didMove(toParentViewController: self)
            controller.dropDownAnimation()
            
            stepsViewController = controller
            return
        }
    }
    
    //MARK: NavigationMapViewDelegate
    func navigationMapView(_ mapView: NavigationMapView, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationMapView?(mapView, routeStyleLayerWithIdentifier: identifier, source: source)
    }

    func navigationMapView(_ mapView: NavigationMapView, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationMapView?(mapView, routeCasingStyleLayerWithIdentifier: identifier, source: source)
    }

    func navigationMapView(_ mapView: NavigationMapView, waypointStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationMapView?(mapView, waypointStyleLayerWithIdentifier: identifier, source: source)
    }
    
    func navigationMapView(_ mapView: NavigationMapView, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationMapView?(mapView, waypointSymbolStyleLayerWithIdentifier: identifier, source: source)
    }
    
    func navigationMapView(_ mapView: NavigationMapView, shapeFor waypoints: [Waypoint]) -> MGLShape? {
        return delegate?.navigationMapView?(mapView, shapeFor: waypoints)
    }

    func navigationMapView(_ mapView: NavigationMapView, shapeDescribing route: Route) -> MGLShape? {
        return delegate?.navigationMapView?(mapView, shapeDescribing: route)
    }
    
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        delegate?.navigationMapView?(mapView, didSelect: route)
    }

    func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeDescribing route: Route) -> MGLShape? {
        return delegate?.navigationMapView?(mapView, simplifiedShapeDescribing: route)
    }
    
    func navigationMapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        return delegate?.navigationMapView?(mapView, imageFor: annotation)
    }
    
    func navigationMapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return delegate?.navigationMapView?(mapView, viewFor: annotation)
    }
    
    func navigationMapViewUserAnchorPoint(_ mapView: NavigationMapView) -> CGPoint {
        //If the end of route component is showing, then put the anchor point slightly above the middle of the map
        if navigationView.endOfRouteView != nil, let show = navigationView.endOfRouteShowConstraint, show.isActive {
            return CGPoint(x: mapView.bounds.midX, y: (mapView.bounds.height * 0.4))
        }
        
        //otherwise, ask the delegate or return .zero
        return delegate?.navigationMapViewUserAnchorPoint?(mapView) ?? .zero
    }
    
    /**
     Updates the current road name label to reflect the road on which the user is currently traveling.
     
     - parameter location: The user’s current location.
     */
    func labelCurrentRoad(at location: CLLocation) {
        guard let style = mapView.style,
            let stepCoordinates = routeController.routeProgress.currentLegProgress.currentStep.coordinates,
            navigationView.resumeButton.isHidden else {
                return
        }
        
        // Avoid aggressively opting the developer into Mapbox services if they
        // haven’t provided an access token.
        guard let _ = MGLAccountManager.accessToken() else {
            navigationView.wayNameView.isHidden = true
            return
        }
        
        let closestCoordinate = location.coordinate
        let roadLabelLayerIdentifier = "roadLabelLayer"
        var streetsSources = style.sources.flatMap {
            $0 as? MGLVectorSource
            }.filter {
                $0.isMapboxStreets
        }
        
        // Add Mapbox Streets if the map does not already have it
        if streetsSources.isEmpty {
            let source = MGLVectorSource(identifier: "mapboxStreetsv7", configurationURL: URL(string: "mapbox://mapbox.mapbox-streets-v7")!)
            style.addSource(source)
            streetsSources.append(source)
        }
        
        if let mapboxSteetsSource = streetsSources.first, style.layer(withIdentifier: roadLabelLayerIdentifier) == nil {
            let streetLabelLayer = MGLLineStyleLayer(identifier: roadLabelLayerIdentifier, source: mapboxSteetsSource)
            streetLabelLayer.sourceLayerIdentifier = "road_label"
            streetLabelLayer.lineOpacity = MGLStyleValue(rawValue: 1)
            streetLabelLayer.lineWidth = MGLStyleValue(rawValue: 20)
            streetLabelLayer.lineColor = MGLStyleValue(rawValue: .white)
            style.insertLayer(streetLabelLayer, at: 0)
        }
        
        let userPuck = mapView.convert(closestCoordinate, toPointTo: mapView)
        let features = mapView.visibleFeatures(at: userPuck, styleLayerIdentifiers: Set([roadLabelLayerIdentifier]))
        var smallestLabelDistance = Double.infinity
        var currentName: String?
        
        for feature in features {
            var allLines: [MGLPolyline] = []
            
            if let line = feature as? MGLPolylineFeature {
                allLines.append(line)
            } else if let lines = feature as? MGLMultiPolylineFeature {
                allLines = lines.polylines
            }
            
            for line in allLines {
                let featureCoordinates =  Array(UnsafeBufferPointer(start: line.coordinates, count: Int(line.pointCount)))
                let featurePolyline = Polyline(featureCoordinates)
                let slicedLine = Polyline(stepCoordinates).sliced(from: closestCoordinate)
                
                let lookAheadDistance: CLLocationDistance = 10
                guard let pointAheadFeature = featurePolyline.sliced(from: closestCoordinate).coordinateFromStart(distance: lookAheadDistance) else { continue }
                guard let pointAheadUser = slicedLine.coordinateFromStart(distance: lookAheadDistance) else { continue }
                guard let reversedPoint = Polyline(featureCoordinates.reversed()).sliced(from: closestCoordinate).coordinateFromStart(distance: lookAheadDistance) else { continue }
                
                let distanceBetweenPointsAhead = pointAheadFeature.distance(to: pointAheadUser)
                let distanceBetweenReversedPoint = reversedPoint.distance(to: pointAheadUser)
                let minDistanceBetweenPoints = min(distanceBetweenPointsAhead, distanceBetweenReversedPoint)
                
                if minDistanceBetweenPoints < smallestLabelDistance {
                    smallestLabelDistance = minDistanceBetweenPoints
                    
                    if let line = feature as? MGLPolylineFeature, let name = line.attribute(forKey: "name") as? String {
                        currentName = name
                    } else if let line = feature as? MGLMultiPolylineFeature, let name = line.attribute(forKey: "name") as? String {
                        currentName = name
                    } else {
                        currentName = nil
                    }
                }
            }
        }
        
        if smallestLabelDistance < 5 && currentName != nil {
            navigationView.wayNameView.text = currentName
            navigationView.wayNameView.isHidden = false
        } else {
            navigationView.wayNameView.isHidden = true
        }
    }
    
    @objc func updateETA() {
        guard isViewLoaded, routeController != nil else { return }
        navigationView.bottomBannerView.updateETA(routeProgress: routeController.routeProgress)
    }
    
    func resetETATimer() {
        removeTimer()
        updateETATimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(updateETA), userInfo: nil, repeats: true)
    }
    
    func showRouteIfNeeded() {
        guard isViewLoaded && view.window != nil else { return }
        guard !mapView.showsRoute else { return }
        mapView.showRoutes([routeController.routeProgress.route], legIndex: routeController.routeProgress.legIndex)
        mapView.showWaypoints(routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex)
        
        if routeController.routeProgress.currentLegProgress.stepIndex + 1 <= routeController.routeProgress.currentLegProgress.leg.steps.count {
            mapView.addArrow(route: routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex, stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
        }
        
        if annotatesSpokenInstructions {
            mapView.showVoiceInstructionsOnMap(route: routeController.routeProgress.route)
        }
    }
}

// MARK: StepsViewControllerDelegate

extension RouteMapViewController: StepsViewControllerDelegate {
    
    func stepsViewController(_ viewController: StepsViewController, didSelect step: RouteStep, cell: StepTableViewCell) {
        
        viewController.dismiss {
            guard let stepBefore = self.routeController.routeProgress.currentLegProgress.stepBefore(step) else { return }
            self.addPreviewInstructions(step: stepBefore, maneuverStep: step, distance: cell.instructionsView.distance)
            self.stepsViewController = nil
        }
        
        mapView.enableFrameByFrameCourseViewTracking(for: 1)
        mapView.tracksUserCourse = false
        mapView.setCenter(step.maneuverLocation, zoomLevel: mapView.zoomLevel, direction: step.initialHeading!, animated: true, completionHandler: nil)
        
        guard isViewLoaded && view.window != nil else { return }
        if let legIndex = routeController.routeProgress.route.legs.index(where: { !$0.steps.filter { $0 == step }.isEmpty }) {
            let leg = routeController.routeProgress.route.legs[legIndex]
            if let stepIndex = leg.steps.index(where: { $0 == step }), leg.steps.last != step {
               mapView.addArrow(route: routeController.routeProgress.route, legIndex: legIndex, stepIndex: stepIndex)
            }
        }
    }
    
    func addPreviewInstructions(step: RouteStep, maneuverStep: RouteStep, distance: CLLocationDistance?) {
        removePreviewInstructions()
        
        guard let instructions = step.instructionsDisplayedAlongStep?.last else { return }
        
        let instructionsView = StepInstructionsView(frame: navigationView.instructionsBannerView.frame)
        instructionsView.backgroundColor = StepInstructionsView.appearance().backgroundColor
        instructionsView.delegate = self
        instructionsView.set(instructions)
        instructionsView.distance = distance
        
        navigationView.instructionsBannerContentView.backgroundColor = instructionsView.backgroundColor
        
        view.addSubview(instructionsView)
        previewInstructionsView = instructionsView
    }
    
    func didDismissStepsViewController(_ viewController: StepsViewController) {
        viewController.dismiss {
            self.stepsViewController = nil
        }
    }
    
    func statusView(_ statusView: StatusView, valueChangedTo value: Double) {
        let displayValue = 1+min(Int(9 * value), 8)
        let title = String.localizedStringWithFormat(NSLocalizedString("USER_IN_SIMULATION_MODE", bundle: .mapboxNavigation, value: "Simulating Navigation at %d×", comment: "The text of a banner that appears during turn-by-turn navigation when route simulation is enabled."), displayValue)
        showStatus(title: title, for: .infinity, interactive: true)
        
        if let locationManager = routeController.locationManager as? SimulatedLocationManager {
            locationManager.speedMultiplier = Double(displayValue)
        }
    }
}

// MARK: BottomBannerViewDelegate

extension RouteMapViewController: BottomBannerViewDelegate {
    func didCancel() {
        delegate?.mapViewControllerDidCancelNavigation(self)
    }
}

// MARK: - Keyboard Handling

extension RouteMapViewController {
    fileprivate func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(RouteMapViewController.keyboardWillShow(notification:)), name:.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(RouteMapViewController.keyboardWillHide(notification:)), name:.UIKeyboardWillHide, object: nil)
        
    }
    fileprivate func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    @objc fileprivate func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        let curve = UIViewAnimationCurve(rawValue: userInfo[UIKeyboardAnimationCurveUserInfoKey] as! Int)
        let options = (duration: userInfo[UIKeyboardAnimationDurationUserInfoKey] as! Double,
                       curve: curve!)
        let keyboardHeight = (userInfo[UIKeyboardFrameEndUserInfoKey] as! CGRect).size.height

        if #available(iOS 11.0, *) {
            navigationView.endOfRouteShowConstraint?.constant = -1 * (keyboardHeight - view.safeAreaInsets.bottom) //subtract the safe area, which is part of the keyboard's frame
        } else {
            navigationView.endOfRouteShowConstraint?.constant = -1 * keyboardHeight
        }
        
        let opts = UIViewAnimationOptions(curve: options.curve)
        UIView.animate(withDuration: options.duration, delay: 0, options: opts, animations: view.layoutIfNeeded, completion: nil)
    }
    
    @objc fileprivate func keyboardWillHide(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        let curve = UIViewAnimationCurve(rawValue: userInfo[UIKeyboardAnimationCurveUserInfoKey] as! Int)
        let options = (duration: userInfo[UIKeyboardAnimationDurationUserInfoKey] as! Double,
                       curve: UIViewAnimationOptions(curve: curve!))
        
        navigationView.endOfRouteShowConstraint?.constant = 0

        UIView.animate(withDuration: options.duration, delay: 0, options: options.curve, animations: view.layoutIfNeeded, completion: nil)
    }
}

fileprivate extension UIViewAnimationOptions {
    init(curve: UIViewAnimationCurve) {
        switch curve {
        case .easeIn:
            self = .curveEaseIn
        case .easeOut:
            self = .curveEaseOut
        case .easeInOut:
            self = .curveEaseInOut
        case .linear:
            self = .curveLinear
        }
    }
}
protocol RouteMapViewControllerDelegate: NavigationMapViewDelegate, MGLMapViewDelegate {

    func mapViewControllerDidOpenFeedback(_ mapViewController: RouteMapViewController)
    func mapViewControllerDidCancelFeedback(_ mapViewController: RouteMapViewController)
    func mapViewControllerDidCancelNavigation(_ mapViewController: RouteMapViewController)
    func mapViewController(_ mapViewController: RouteMapViewController, didSend feedbackId: String, feedbackType: FeedbackType)
    func mapViewControllerShouldAnnotateSpokenInstructions(_ routeMapViewController: RouteMapViewController) -> Bool
}


