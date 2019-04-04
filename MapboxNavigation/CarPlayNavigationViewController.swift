import Foundation
import MapboxDirections
import MapboxCoreNavigation
#if canImport(CarPlay)
import CarPlay

/**
 `CarPlayNavigationViewController` is a fully-featured turn-by-turn navigation UI for CarPlay.
 
 - seealso: NavigationViewController
 */
@available(iOS 12.0, *)
@objc(MBCarPlayNavigationViewController)
public class CarPlayNavigationViewController: UIViewController {
    /**
     The view controller’s delegate.
     */
    @objc public weak var carPlayNavigationDelegate: CarPlayNavigationDelegate? {
        didSet {
            if let carPlayNavigationDelegate = carPlayNavigationDelegate as? NSObjectProtocol {
                // This rigamarole avoids a compiler error when using a #selector literal, as well as a compiler warning when calling the Selector(_:) initializer with a string literal.
                let carPlayNavigationViewControllerDidArrive = Selector(("carPlayNavigationViewControllerDidArrive:" as NSString) as String)
                assert(!carPlayNavigationDelegate.responds(to: carPlayNavigationViewControllerDidArrive), "CarPlayNavigationDelegate.carPlayNavigationViewControllerDidArrive(_:) has been removed. Use NavigationViewControllerDelegate.navigationViewController(_:didArriveAt:) or  NavigationServiceDelegate.navigationService(_:didArriveAt:) instead.")
            }
        }
    }
    
    public var carPlayManager: CarPlayManager
    
    @objc public var drivingSide: DrivingSide = .right
    
    
    /**
     Provides all routing logic for the user.
     
     See `NavigationService` for more information.
     */
    @objc public var navigationService: NavigationService
    
    /**
     The map view showing the route and the user’s location.
     */
    @objc public fileprivate(set) var mapView: NavigationMapView?
    
    let shieldHeight: CGFloat = 16
    var mapViewLeftSafeAreaBalancingConstraint: NSLayoutConstraint?
    var mapViewRightSafeAreaBalancingConstraint: NSLayoutConstraint?
    
    var mapViewOverviewRightConstraint: NSLayoutConstraint?
    
    var carSession: CPNavigationSession!
    var mapTemplate: CPMapTemplate
    var carFeedbackTemplate: CPGridTemplate!
    var carInterfaceController: CPInterfaceController
    var styleManager: StyleManager?
    
    /**
     The interface styles available for display.
     
     These are the styles available to the view controller’s internal `StyleManager` object. In CarPlay, `Style` objects primarily affect the appearance of the map, not guidance-related overlay views.
     */
    @objc public var styles: [Style] {
        didSet {
            styleManager?.styles = styles
        }
    }
    
    let distanceFormatter = DistanceFormatter(approximate: true)
    
    var edgePadding: UIEdgeInsets {
        let padding:CGFloat = 15
        return UIEdgeInsets(top: view.safeAreaInsets.top + padding,
                            left: view.safeAreaInsets.left + padding,
                            bottom: view.safeAreaInsets.bottom + padding,
                            right: view.safeAreaInsets.right + padding)
    }
    
    var styleObservation: NSKeyValueObservation?
    
    /**
     Creates a new CarPlay navigation view controller for the given route controller and user interface.
     
     - parameter navigationService: The navigation service managing location updates for the navigation session.
     - parameter mapTemplate: The map template visible during the navigation session.
     - parameter interfaceController: The interface controller for CarPlay.
     - parameter manager: The manager for CarPlay.
     - parameter styles: The interface styles that the view controller’s internal `StyleManager` object can select from for display.
     
     - postcondition: Call `startNavigationSession(for:)` after initializing this object to begin navigation.
     */
    @objc required public init(navigationService: NavigationService,
                      mapTemplate: CPMapTemplate,
                      interfaceController: CPInterfaceController,
                      manager: CarPlayManager,
                      styles: [Style]? = nil) {
        self.navigationService = navigationService
        self.mapTemplate = mapTemplate
        self.carInterfaceController = interfaceController
        self.carPlayManager = manager
        self.styles = styles ?? [DayStyle(), NightStyle()]
        
        super.init(nibName: nil, bundle: nil)
        carFeedbackTemplate = createFeedbackUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let mapView = NavigationMapView(frame: view.bounds)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.compassView.isHidden = true
        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true

        mapView.defaultAltitude = 500
        mapView.zoomedOutMotorwayAltitude = 1000
        mapView.longManeuverDistance = 500
        
        mapView.navigationMapViewDelegate = self

        self.mapView = mapView
        view.addSubview(mapView)
        
        // These constraints don’t account for language direction, because the
        // safe area insets are nondirectional and may be affected by the side
        // on which the driver is sitting.
        mapViewRightSafeAreaBalancingConstraint = NSLayoutConstraint(item: mapView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: -mapView.safeArea.right)
        view.addConstraint(mapViewRightSafeAreaBalancingConstraint!)
        mapViewLeftSafeAreaBalancingConstraint = NSLayoutConstraint(item: mapView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: mapView.safeArea.left)
        view.addConstraint(mapViewLeftSafeAreaBalancingConstraint!)
        view.addConstraint(NSLayoutConstraint(item: mapView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: mapView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0))
        
        mapViewOverviewRightConstraint = view.rightAnchor.constraint(equalTo: mapView.rightAnchor)
        
        styleObservation = mapView.observe(\.style, options: .new) { [weak self] (mapView, change) in
            guard change.newValue != nil else {
                return
            }
            self?.mapView?.localizeLabels()
            self?.updateRouteOnMap()
            self?.mapView?.recenterMap()
        }
        
        styleManager = StyleManager()
        styleManager!.delegate = self
        styleManager!.styles = self.styles
        
        makeGestureRecognizersResetFrameRate()
        observeNotifications(by: navigationService)
        updateManeuvers(for: navigationService.routeProgress)
        navigationService.start()
        mapView.recenterMap()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        styleObservation = nil
        suspendNotifications()
    }
    
    func observeNotifications(by service: NavigationService) {
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_:)), name: .routeControllerProgressDidChange, object: service.router)
        NotificationCenter.default.addObserver(self, selector: #selector(rerouted(_:)), name: .routeControllerDidReroute, object: service.router)
        NotificationCenter.default.addObserver(self, selector: #selector(visualInstructionDidChange(_:)), name: .routeControllerDidPassVisualInstructionPoint, object: service.router)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidPassVisualInstructionPoint, object: nil)
    }
    
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        // Adjust the map’s vanishing point to counterbalance the side maneuver panels by extending the view off beyond the other side of the screen.
        guard let mapView = mapView else { return }
        
        mapViewRightSafeAreaBalancingConstraint?.constant = -mapView.safeArea.right
        mapViewLeftSafeAreaBalancingConstraint?.constant = mapView.safeArea.left
        view.setNeedsUpdateConstraints()
        
        mapView.enableFrameByFrameCourseViewTracking(for: 1)
        
        if !tracksUserCourse {
            mapView.setContentInset(overviewContentInsets(), animated: false)
            mapView.fit(to: navigationService.route, facing: 0, padding: .zero, animated: false)
        }
    }
    
    func overviewContentInsets() -> UIEdgeInsets {
        guard let mapView = mapView else { return .zero }
        var edgePadding = view.safeArea
        
        if let userCourseView = mapView.userCourseView {
            let midX = userCourseView.bounds.midX
            let midY = userCourseView.bounds.midY
            edgePadding += UIEdgeInsets(top: midY, left: midX, bottom: midY, right: midX)
        }
        
        return edgePadding
    }
    
    /**
     Begins a navigation session along the given trip.
     
     - parameter trip: The trip to begin navigating along.
     */
    @objc(startNavigationSessionForTrip:)
    public func startNavigationSession(for trip: CPTrip) {
        carSession = mapTemplate.startNavigationSession(for: trip)
    }
    
    /**
     Ends the current navigation session.
     
     - parameter canceled: A Boolean value indicating whether this method is being called because the user intends to cancel the trip, as opposed to letting it run to completion.
     */
    @objc(exitNavigationByCanceling:)
    public func exitNavigation(byCanceling canceled: Bool = false) {
        carSession.finishTrip()
        dismiss(animated: true) {
            self.carPlayNavigationDelegate?.carPlayNavigationViewControllerDidDismiss?(self, byCanceling: canceled)
        }
    }
    
    /**
     Shows the interface for providing feedback about the route.
     */
    @objc public func showFeedback() {
        carInterfaceController.pushTemplate(self.carFeedbackTemplate, animated: true)
    }
    
    /**
     A Boolean value indicating whether the map should follow the user’s location and rotate when the course changes.
     
     When this property is true, the map follows the user’s location and rotates when their course changes. Otherwise, the map shows an overview of the route.
     */
    @objc public var tracksUserCourse: Bool {
        get {
            return mapView?.tracksUserCourse ?? false
        }
        set {
            let progress = navigationService.routeProgress
            if !tracksUserCourse && newValue {
                
                adjustMapViewVanishingPoint(forOverview: false)
                
                mapView?.recenterMap()
                mapView?.addArrow(route: progress.route,
                                 legIndex: progress.legIndex,
                                 stepIndex: progress.currentLegProgress.stepIndex + 1)
            } else if tracksUserCourse && !newValue {
                
                adjustMapViewVanishingPoint(forOverview: true)
                
                guard let userLocation = self.navigationService.router.location?.coordinate,
                let coordinates = navigationService.route.coordinates else {
                    return
                }
                mapView?.enableFrameByFrameCourseViewTracking(for: 1)
                mapView?.setOverheadCameraView(from: userLocation, along: coordinates, for: .zero)
            }
        }
    }
    
    func adjustMapViewVanishingPoint(forOverview overviewing: Bool) {
        mapViewLeftSafeAreaBalancingConstraint?.isActive = !overviewing
        mapViewOverviewRightConstraint?.isActive = overviewing
        
        view.setNeedsUpdateConstraints()
        mapView?.setNeedsUpdateConstraints()
    }
    
    public func beginPanGesture() {
        mapView?.tracksUserCourse = false
        mapView?.enableFrameByFrameCourseViewTracking(for: 1)
    }
    
    @objc func visualInstructionDidChange(_ notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as! RouteProgress
        updateManeuvers(for: routeProgress)
        mapView?.showWaypoints(routeProgress.route)
        mapView?.addArrow(route: routeProgress.route, legIndex: routeProgress.legIndex, stepIndex: routeProgress.currentLegProgress.stepIndex + 1)
    }
    
    @objc func progressDidChange(_ notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as! RouteProgress
        let location = notification.userInfo![RouteControllerNotificationUserInfoKey.locationKey] as! CLLocation
        
        // Update the user puck
        mapView?.updatePreferredFrameRate(for: routeProgress)
        let camera = MGLMapCamera(lookingAtCenter: location.coordinate, altitude: 120, pitch: 60, heading: location.course)
        mapView?.updateCourseTracking(location: location, camera: camera, animated: true)
        
        let congestionLevel = routeProgress.averageCongestionLevelRemainingOnLeg ?? .unknown
        guard let maneuver = carSession.upcomingManeuvers.first else { return }
        
        let legProgress = routeProgress.currentLegProgress
        let legDistance = distanceFormatter.measurement(of: legProgress.distanceRemaining)
        let legEstimates = CPTravelEstimates(distanceRemaining: legDistance, timeRemaining: legProgress.durationRemaining)
        mapTemplate.update(legEstimates, for: carSession.trip, with: congestionLevel.asCPTimeRemainingColor)
        
        let stepProgress = legProgress.currentStepProgress
        let stepDistance = distanceFormatter.measurement(of: stepProgress.distanceRemaining)
        let stepEstimates = CPTravelEstimates(distanceRemaining: stepDistance, timeRemaining: stepProgress.durationRemaining)
        carSession.updateEstimates(stepEstimates, for: maneuver)
    }
    
    /** Modifies the gesture recognizers to also update the map’s frame rate. */
    func makeGestureRecognizersResetFrameRate() {
        for gestureRecognizer in mapView?.gestureRecognizers ?? [] {
            gestureRecognizer.addTarget(self, action: #selector(resetFrameRate(_:)))
        }
    }
    
    @objc func resetFrameRate(_ sender: UIGestureRecognizer) {
        mapView?.preferredFramesPerSecond = NavigationMapView.FrameIntervalOptions.defaultFramesPerSecond
    }
    
    @objc func rerouted(_ notification: NSNotification) {
        updateRouteOnMap()
        self.mapView?.recenterMap()
    }
    
    func updateRouteOnMap() {
        guard let map = mapView else { return }
        let progress = navigationService.routeProgress
        let legIndex = progress.legIndex
        let nextStep = progress.currentLegProgress.stepIndex + 1 // look forward twoards the next step
        
        map.addArrow(route: progress.route, legIndex: legIndex, stepIndex: nextStep)
        map.showRoutes([progress.route], legIndex: legIndex)
        map.showWaypoints(progress.route, legIndex: legIndex)
    }
    
    func updateManeuvers(for routeProgress: RouteProgress) {
        guard let visualInstruction = routeProgress.currentLegProgress.currentStepProgress.currentVisualInstruction else { return }
        let step = navigationService.routeProgress.currentLegProgress.currentStep
        
        let primaryManeuver = CPManeuver()
        let distance = distanceFormatter.measurement(of: step.distance)
        primaryManeuver.initialTravelEstimates = CPTravelEstimates(distanceRemaining: distance, timeRemaining: step.expectedTravelTime)
        
        // Just incase, set some default text
        var text = visualInstruction.primaryInstruction.text ?? step.instructions
        if let secondaryText = visualInstruction.secondaryInstruction?.text {
            text += "\n\(secondaryText)"
        }
        primaryManeuver.instructionVariants = [text]
        
        // Add maneuver arrow
        primaryManeuver.symbolSet = visualInstruction.primaryInstruction.maneuverImageSet(side: visualInstruction.drivingSide)
        
        // Estimating the width of Apple's maneuver view
        let bounds: () -> (CGRect) = {
            let widthOfManeuverView = min(self.view.bounds.width - self.view.safeArea.left, self.view.bounds.width - self.view.safeArea.right)
            return CGRect(x: 0, y: 0, width: widthOfManeuverView, height: 30)
        }
        
        // Over a certain height, CarPlay devices downsize the image and CarPlay simulators hide the image.
        let maximumImageSize = CGSize(width: .infinity, height: shieldHeight)
        let imageRendererFormat = UIGraphicsImageRendererFormat(for: UITraitCollection(userInterfaceIdiom: .carPlay))
        if let window = carPlayManager.carWindow {
            imageRendererFormat.scale = window.screen.scale
        }
        
        if let attributedPrimary = visualInstruction.primaryInstruction.carPlayManeuverLabelAttributedText(bounds: bounds, shieldHeight: shieldHeight, window: carPlayManager.carWindow) {
            let instruction = NSMutableAttributedString(attributedString: attributedPrimary)
            
            if let attributedSecondary = visualInstruction.secondaryInstruction?.carPlayManeuverLabelAttributedText(bounds: bounds, shieldHeight: shieldHeight, window: carPlayManager.carWindow) {
                instruction.append(NSAttributedString(string: "\n"))
                instruction.append(attributedSecondary)
            }
            
            instruction.canonicalizeAttachments(maximumImageSize: maximumImageSize, imageRendererFormat: imageRendererFormat)
            primaryManeuver.attributedInstructionVariants = [instruction]
        }
        
        var maneuvers: [CPManeuver] = [primaryManeuver]
        
        // Add tertiary text if available. TODO: handle lanes.
        if let tertiaryInstruction = visualInstruction.tertiaryInstruction, !tertiaryInstruction.containsLaneIndications {
            let tertiaryManeuver = CPManeuver()
            tertiaryManeuver.symbolSet = tertiaryInstruction.maneuverImageSet(side: visualInstruction.drivingSide)
            
            if let text = tertiaryInstruction.text {
                tertiaryManeuver.instructionVariants = [text]
            }
            if let attributedTertiary = tertiaryInstruction.carPlayManeuverLabelAttributedText(bounds: bounds, shieldHeight: shieldHeight, window: carPlayManager.carWindow) {
                let attributedTertiary = NSMutableAttributedString(attributedString: attributedTertiary)
                attributedTertiary.canonicalizeAttachments(maximumImageSize: maximumImageSize, imageRendererFormat: imageRendererFormat)
                tertiaryManeuver.attributedInstructionVariants = [attributedTertiary]
            }
            
            if let upcomingStep = navigationService.routeProgress.currentLegProgress.upcomingStep {
                let distance = distanceFormatter.measurement(of: upcomingStep.distance)
                tertiaryManeuver.initialTravelEstimates = CPTravelEstimates(distanceRemaining: distance, timeRemaining: upcomingStep.expectedTravelTime)
            }
            
            maneuvers.append(tertiaryManeuver)
        }
        
        carSession.upcomingManeuvers = maneuvers
    }
    
    func createFeedbackUI() -> CPGridTemplate {
        let feedbackItems: [FeedbackItem] = [
            .turnNotAllowed,
            .closure,
            .reportTraffic,
            .confusingInstructions,
            .generalMapError,
            .badRoute
        ]
        
        let feedbackButtonHandler: (_: CPGridButton) -> Void = { [weak self] (button) in
            self?.carInterfaceController.popTemplate(animated: true)

            //TODO: fix this Demeter violation with proper encapsulation
            guard let uuid = self?.navigationService.eventsManager.recordFeedback() else { return }
            let foundItem = feedbackItems.filter { $0.image == button.image }
            guard let feedbackItem = foundItem.first else { return }
            self?.navigationService.eventsManager.updateFeedback(uuid: uuid, type: feedbackItem.feedbackType, source: .user, description: nil)
            
            let dismissTitle = NSLocalizedString("CARPLAY_DISMISS", bundle: .mapboxNavigation, value: "Dismiss", comment: "Title for dismiss button")
            let submittedTitle = NSLocalizedString("CARPLAY_SUBMITTED_FEEDBACK", bundle: .mapboxNavigation, value: "Submitted", comment: "Alert title that shows when feedback has been submitted")
            let action = CPAlertAction(title: dismissTitle, style: .default, handler: {_ in })
            let alert = CPNavigationAlert(titleVariants: [submittedTitle], subtitleVariants: nil, imageSet: nil, primaryAction: action, secondaryAction: nil, duration: 2.5)
            self?.mapTemplate.present(navigationAlert: alert, animated: true)
        }
        
        let buttons: [CPGridButton] = feedbackItems.map {
            return CPGridButton(titleVariants: [$0.title.components(separatedBy: "\n").joined(separator: " ")], image: $0.image, handler: feedbackButtonHandler)
        }
        let gridTitle = NSLocalizedString("CARPLAY_FEEDBACK", bundle: .mapboxNavigation, value: "Feedback", comment: "Title for feedback template in CarPlay")
        return CPGridTemplate(title: gridTitle, gridButtons: buttons)
    }
    
    func endOfRouteFeedbackTemplate() -> CPGridTemplate {
        let buttonHandler: (_: CPGridButton) -> Void = { [weak self] (button) in
    
            let title: String? = button.titleVariants.first ?? nil
            let rating: Int? = title != nil ? Int(title!.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) : nil
            let feedback: EndOfRouteFeedback? = rating != nil ? EndOfRouteFeedback(rating: rating, comment: nil) : nil
            self?.navigationService.endNavigation(feedback: feedback)
            
            self?.carInterfaceController.popTemplate(animated: true)
            self?.exitNavigation()
        }
        
        var buttons: [CPGridButton] = []
        let starImage = UIImage(named: "star", in: .mapboxNavigation, compatibleWith: nil)!
        for i in 1...5 {
            let button = CPGridButton(titleVariants: ["\(i) star\(i == 1 ? "" : "s")"], image: starImage, handler: buttonHandler)
            buttons.append(button)
        }
        
        let gridTitle = NSLocalizedString("CARPLAY_RATE_RIDE", bundle: .mapboxNavigation, value: "Rate your ride", comment: "Title for rating template in CarPlay")
        return CPGridTemplate(title: gridTitle, gridButtons: buttons)
    }
    
    func presentArrivalUI() {
        let exitTitle = NSLocalizedString("CARPLAY_EXIT_NAVIGATION", bundle: .mapboxNavigation, value: "Exit navigation", comment: "Title on the exit button in the arrival form")
        let exitAction = CPAlertAction(title: exitTitle, style: .cancel) { (action) in
            self.exitNavigation()
            self.dismiss(animated: true, completion: nil)
        }
        let rateTitle = NSLocalizedString("CARPLAY_RATE_TRIP", bundle: .mapboxNavigation, value: "Rate your trip", comment: "Title on rate button in CarPlay")
        let rateAction = CPAlertAction(title: rateTitle, style: .default) { (action) in
            self.carInterfaceController.pushTemplate(self.endOfRouteFeedbackTemplate(), animated: true)
        }
        let arrivalTitle = NSLocalizedString("CARPLAY_ARRIVED", bundle: .mapboxNavigation, value: "You have arrived", comment: "Title on arrival action sheet")
        let arrivalMessage = NSLocalizedString("CARPLAY_ARRIVED_MESSAGE", bundle: .mapboxNavigation, value: "What would you like to do?", comment: "Message on arrival action sheet")
        let alert = CPActionSheetTemplate(title: arrivalTitle, message: arrivalMessage, actions: [rateAction, exitAction])
        carInterfaceController.presentTemplate(alert, animated: true)
    }
}

@available(iOS 12.0, *)
extension CarPlayNavigationViewController: NavigationMapViewDelegate {
    public func navigationMapViewUserAnchorPoint(_ mapView: NavigationMapView) -> CGPoint {
        // Inset by the content inset to avoid application-defined content.
        var contentFrame = mapView.bounds.inset(by: mapView.contentInset)
        
        // Avoid letting the puck go partially off-screen, and add a comfortable padding beyond that.
        let courseViewBounds = mapView.userCourseView?.bounds ?? .zero
        contentFrame = contentFrame.insetBy(dx: min(NavigationMapView.courseViewMinimumInsets.left + courseViewBounds.width / 2.0, contentFrame.width / 2.0),
                                            dy: min(NavigationMapView.courseViewMinimumInsets.top + courseViewBounds.height / 2.0, contentFrame.height / 2.0))
        
        // Get the bottom-center of the remaining frame.
        assert(!contentFrame.isInfinite)
        return CGPoint(x: contentFrame.midX, y: contentFrame.maxY)
    }
}

@available(iOS 12.0, *)
extension CarPlayNavigationViewController: StyleManagerDelegate {
    @objc(locationForStyleManager:)
    public func location(for styleManager: StyleManager) -> CLLocation? {
        if let location = navigationService.router.location {
            return location
        } else if let origin = navigationService.route.coordinates?.first {
            return CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        } else {
            return nil
        }
    }
    
    @objc(styleManager:didApplyStyle:)
    public func styleManager(_ styleManager: StyleManager, didApply style: Style) {
        if mapView?.styleURL != style.mapStyleURL {
            mapView?.style?.transition = MGLTransition(duration: 0.5, delay: 0)
            mapView?.styleURL = style.mapStyleURL
        }
    }
    
    @objc public func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) {
        mapView?.reloadStyle(self)
    }
}

/**
 The `CarPlayNavigationDelegate` protocol provides methods for reacting to significant events during turn-by-turn navigation with `CarPlayNavigationViewController`.
 */
@available(iOS 12.0, *)
@objc(MBNavigationCarPlayDelegate)
public protocol CarPlayNavigationDelegate {
    /**
     Called when the CarPlay navigation view controller is dismissed, such as when the user ends a trip.
     
     - parameter carPlayNavigationViewController: The CarPlay navigation view controller that was dismissed.
     - parameter canceled: True if the user dismissed the CarPlay navigation view controller by tapping the Cancel button; false if the navigation view controller dismissed by some other means.
     */
    @objc(carPlayNavigationViewControllerDidDismiss:byCanceling:)
    optional func carPlayNavigationViewControllerDidDismiss(_ carPlayNavigationViewController: CarPlayNavigationViewController, byCanceling canceled: Bool)
    
    //MARK: - Deprecated.
    
    @available(*, obsoleted: 0.1, message: "Use NavigationViewControllerDelegate.navigationViewController(_:didArriveAt:) or  NavigationServiceDelegate.navigationService(_:didArriveAt:) instead.")
    @objc optional func carPlayNavigationViewControllerDidArrive(_ carPlayNavigationViewController: CarPlayNavigationViewController)
}
#endif
