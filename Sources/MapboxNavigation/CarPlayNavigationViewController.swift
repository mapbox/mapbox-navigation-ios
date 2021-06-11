import Foundation
import MapboxDirections
import MapboxCoreNavigation
import MapboxMaps

#if canImport(CarPlay)
import CarPlay

/**
 `CarPlayNavigationViewController` is a fully-featured turn-by-turn navigation UI for CarPlay.
 
 - seealso: NavigationViewController
 */
@available(iOS 12.0, *)
public class CarPlayNavigationViewController: UIViewController {
    
    /**
     The view controller’s delegate.
     */
    public weak var delegate: CarPlayNavigationViewControllerDelegate?
    
    public var carPlayManager: CarPlayManager
    
    /**
     Provides all routing logic for the user.
     
     See `NavigationService` for more information.
     */
    public var navigationService: NavigationService
    
    /**
     The map view showing the route and the user’s location.
     */
    public fileprivate(set) var navigationMapView: NavigationMapView?
    
    /**
     A view indicating what direction the vehicle is traveling towards, snapped
     to eight cardinal directions in steps of 45°.
     
     This view is hidden by default.
     */
    public weak var compassView: CarPlayCompassView!
    
    /**
     A view that displays the current speed limit.
     */
    public weak var speedLimitView: SpeedLimitView!
    
    /**
     The interface styles available for display.
     
     These are the styles available to the view controller’s internal `StyleManager` object. In CarPlay, `Style` objects primarily affect the appearance of the map, not guidance-related overlay views.
     */
    public var styles: [Style] {
        didSet {
            styleManager?.styles = styles
        }
    }
    
    /**
     Controls whether the main route style layer and its casing disappears
     as the user location puck travels over it. Defaults to `false`.
     
     If `true`, the part of the route that has been traversed will be
     rendered with full transparency, to give the illusion of a
     disappearing route. To customize the color that appears on the
     traversed section of a route, override the `traversedRouteColor` property
     for the `NavigationMapView.appearance()`.
     */
    public var routeLineTracksTraversal: Bool = false {
        didSet {
            navigationMapView?.routeLineTracksTraversal = routeLineTracksTraversal
        }
    }
    
    var carSession: CPNavigationSession!
    var mapTemplate: CPMapTemplate
    var carFeedbackTemplate: CPGridTemplate!
    var carInterfaceController: CPInterfaceController
    var styleManager: StyleManager?
    
    // MARK: - Initialization methods
    
    /**
     Creates a new CarPlay navigation view controller for the given route controller and user interface.
     
     - parameter navigationService: The navigation service managing location updates for the navigation session.
     - parameter mapTemplate: The map template visible during the navigation session.
     - parameter interfaceController: The interface controller for CarPlay.
     - parameter manager: The manager for CarPlay.
     - parameter styles: The interface styles that the view controller’s internal `StyleManager` object can select from for display.
     
     - postcondition: Call `startNavigationSession(for:)` after initializing this object to begin navigation.
     */
    required public init(navigationService: NavigationService,
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
    
    // MARK: - UIViewController lifecycle methods
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationMapView()
        setupOrnaments()
        setupStyleManager()
        
        observeNotifications(navigationService)
        updateManeuvers(navigationService.routeProgress)
        navigationService.start()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        suspendNotifications()
    }
    
    // MARK: - Setting-up methods
    
    func setupNavigationMapView() {
        let navigationMapView = NavigationMapView(frame: view.bounds, navigationCameraType: .carPlay)
        navigationMapView.navigationCamera.viewportDataSource = NavigationViewportDataSource(navigationMapView.mapView,
                                                                                             viewportDataSourceType: .active)
        navigationMapView.translatesAutoresizingMaskIntoConstraints = false
        
        navigationMapView.mapView.mapboxMap.onNext(.styleLoaded) { [weak self] _ in
            self?.navigationMapView?.localizeLabels()
            self?.updateRouteOnMap()
            self?.navigationMapView?.mapView.showsTraffic = false
        }
        
        navigationMapView.mapView.ornaments.options.compass.visibility = .hidden
        navigationMapView.mapView.ornaments.options.logo._visibility = .hidden
        navigationMapView.mapView.ornaments.options.attributionButton._visibility = .hidden
        
        navigationMapView.navigationCamera.follow()
        
        view.addSubview(navigationMapView)
        navigationMapView.pinInSuperview()
        
        self.navigationMapView = navigationMapView
        
        if let coordinate = navigationService.routeProgress.route.shape?.coordinates.first {
            navigationMapView.setInitialCamera(coordinate)
        }
    }
    
    func setupOrnaments() {
        let compassView = CarPlayCompassView()
        view.addSubview(compassView)
        compassView.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 8).isActive = true
        compassView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8).isActive = true
        self.compassView = compassView
        
        let speedLimitView = SpeedLimitView()
        speedLimitView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(speedLimitView)
        
        speedLimitView.topAnchor.constraint(equalTo: compassView.bottomAnchor, constant: 8).isActive = true
        speedLimitView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8).isActive = true
        speedLimitView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        speedLimitView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.speedLimitView = speedLimitView
    }
    
    func setupStyleManager() {
        styleManager = StyleManager()
        styleManager?.delegate = self
        styleManager?.styles = self.styles
    }
    
    // MARK: - Notifications observer methods
    
    func observeNotifications(_ service: NavigationService) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(progressDidChange(_:)),
                                               name: .routeControllerProgressDidChange,
                                               object: service.router)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(rerouted(_:)),
                                               name: .routeControllerDidReroute,
                                               object: service.router)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(visualInstructionDidChange(_:)),
                                               name: .routeControllerDidPassVisualInstructionPoint,
                                               object: service.router)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerProgressDidChange,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerDidReroute,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerDidPassVisualInstructionPoint,
                                                  object: nil)
    }
    
    /**
     Begins a navigation session along the given trip.
     
     - parameter trip: The trip to begin navigating along.
     */
    public func startNavigationSession(for trip: CPTrip) {
        carSession = mapTemplate.startNavigationSession(for: trip)
    }
    
    /**
     Ends the current navigation session.
     
     - parameter canceled: A Boolean value indicating whether this method is being called because the user intends to cancel the trip, as opposed to letting it run to completion.
     */
    public func exitNavigation(byCanceling canceled: Bool = false) {
        carSession.finishTrip()
        dismiss(animated: true) {
            self.delegate?.carPlayNavigationViewControllerDidDismiss(self, byCanceling: canceled)
        }
    }
    
    /**
     Shows the interface for providing feedback about the route.
     */
    public func showFeedback() {
        carInterfaceController.pushTemplate(self.carFeedbackTemplate, animated: true)
    }
    
    @objc func visualInstructionDidChange(_ notification: NSNotification) {
        guard let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress else { return }
        
        updateManeuvers(routeProgress)
        navigationMapView?.showWaypoints(on: routeProgress.route)
        navigationMapView?.addArrow(route: routeProgress.route,
                                    legIndex: routeProgress.legIndex,
                                    stepIndex: routeProgress.currentLegProgress.stepIndex + 1)
    }
    
    @objc func progressDidChange(_ notification: NSNotification) {
        guard let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress,
              let location = notification.userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation else { return }
        
        // Update the user puck
        navigationMapView?.updatePreferredFrameRate(for: routeProgress)
        navigationMapView?.moveUserLocation(to: location, animated: true)
        
        let congestionLevel = routeProgress.averageCongestionLevelRemainingOnLeg ?? .unknown
        guard let maneuver = carSession.upcomingManeuvers.first else { return }
        
        let routeDistance = Measurement(distance: routeProgress.distanceRemaining).localized()
        let routeEstimates = CPTravelEstimates(distanceRemaining: routeDistance, timeRemaining: routeProgress.durationRemaining)
        mapTemplate.update(routeEstimates, for: carSession.trip, with: congestionLevel.asCPTimeRemainingColor)
        
        let stepProgress = routeProgress.currentLegProgress.currentStepProgress
        let stepDistance = Measurement(distance: stepProgress.distanceRemaining).localized()
        let stepEstimates = CPTravelEstimates(distanceRemaining: stepDistance, timeRemaining: stepProgress.durationRemaining)
        carSession.updateEstimates(stepEstimates, for: maneuver)
        
        if let compassView = self.compassView, !compassView.isHidden {
            compassView.course = location.course
        }
        
        if let speedLimitView = speedLimitView {
            speedLimitView.signStandard = routeProgress.currentLegProgress.currentStep.speedLimitSignStandard
            speedLimitView.speedLimit = routeProgress.currentLegProgress.currentSpeedLimit
        }
        
        if routeLineTracksTraversal {
            navigationMapView?.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
            navigationMapView?.updateTraveledRouteLine(location.coordinate)
            navigationMapView?.updateRoute(routeProgress)
        }
    }
    
    @objc func rerouted(_ notification: NSNotification) {
        updateRouteOnMap()
    }
    
    func updateRouteOnMap() {
        let progress = navigationService.routeProgress
        let legIndex = progress.legIndex
        let nextStep = progress.currentLegProgress.stepIndex + 1
        
        navigationMapView?.addArrow(route: progress.route, legIndex: legIndex, stepIndex: nextStep)
        navigationMapView?.show([progress.route], legIndex: legIndex)
        navigationMapView?.showWaypoints(on: progress.route, legIndex: legIndex)
    }
    
    func updateManeuvers(_ routeProgress: RouteProgress) {
        guard let visualInstruction = routeProgress.currentLegProgress.currentStepProgress.currentVisualInstruction else { return }
        let step = navigationService.routeProgress.currentLegProgress.currentStep
        let shieldHeight: CGFloat = 16
        let primaryManeuver = CPManeuver()
        let distance = Measurement(distance: step.distance).localized()
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
            let widthOfManeuverView = min(self.view.bounds.width - self.view.safeArea.left,
                                          self.view.bounds.width - self.view.safeArea.right)
            return CGRect(x: 0, y: 0, width: widthOfManeuverView, height: 30)
        }
        
        // Over a certain height, CarPlay devices downsize the image and CarPlay simulators hide the image.
        let maximumImageSize = CGSize(width: .infinity, height: shieldHeight)
        let imageRendererFormat = UIGraphicsImageRendererFormat(for: UITraitCollection(userInterfaceIdiom: .carPlay))
        if let window = carPlayManager.carWindow {
            imageRendererFormat.scale = window.screen.scale
        }
        
        if let attributedPrimary = visualInstruction.primaryInstruction.carPlayManeuverLabelAttributedText(bounds: bounds,
                                                                                                           shieldHeight: shieldHeight,
                                                                                                           window: carPlayManager.carWindow) {
            let instruction = NSMutableAttributedString(attributedString: attributedPrimary)
            
            if let attributedSecondary = visualInstruction.secondaryInstruction?.carPlayManeuverLabelAttributedText(bounds: bounds,
                                                                                                                    shieldHeight: shieldHeight,
                                                                                                                    window: carPlayManager.carWindow) {
                instruction.append(NSAttributedString(string: "\n"))
                instruction.append(attributedSecondary)
            }
            
            instruction.canonicalizeAttachments(maximumImageSize: maximumImageSize, imageRendererFormat: imageRendererFormat)
            primaryManeuver.attributedInstructionVariants = [instruction]
        }
        
        var maneuvers: [CPManeuver] = [primaryManeuver]
        
        // Add tertiary information, if available
        if let tertiaryInstruction = visualInstruction.tertiaryInstruction {
            let tertiaryManeuver = CPManeuver()
            if tertiaryInstruction.containsLaneIndications {
                // add lanes visual banner
                if let imageSet = visualInstruction.tertiaryInstruction?.lanesImageSet(side: visualInstruction.drivingSide,
                                                                                       direction: visualInstruction.primaryInstruction.maneuverDirection,
                                                                                       scale: (carPlayManager.carWindow?.screen ?? UIScreen.main).scale) {
                    tertiaryManeuver.symbolSet = imageSet
                }

                tertiaryManeuver.userInfo = tertiaryInstruction
            } else {
                // add tertiary maneuver text
                tertiaryManeuver.symbolSet = tertiaryInstruction.maneuverImageSet(side: visualInstruction.drivingSide)

                if let text = tertiaryInstruction.text {
                    tertiaryManeuver.instructionVariants = [text]
                }
                if let attributedTertiary = tertiaryInstruction.carPlayManeuverLabelAttributedText(bounds: bounds,
                                                                                                   shieldHeight: shieldHeight,
                                                                                                   window: carPlayManager.carWindow) {
                    let attributedTertiary = NSMutableAttributedString(attributedString: attributedTertiary)
                    attributedTertiary.canonicalizeAttachments(maximumImageSize: maximumImageSize, imageRendererFormat: imageRendererFormat)
                    tertiaryManeuver.attributedInstructionVariants = [attributedTertiary]
                }
            }

            if let upcomingStep = navigationService.routeProgress.currentLegProgress.upcomingStep {
                let distance = Measurement(distance: upcomingStep.distance).localized()
                tertiaryManeuver.initialTravelEstimates = CPTravelEstimates(distanceRemaining: distance,
                                                                            timeRemaining: upcomingStep.expectedTravelTime)
            }

            maneuvers.append(tertiaryManeuver)
        }
        
        carSession.upcomingManeuvers = maneuvers
    }
    
    func createFeedbackUI() -> CPGridTemplate {
        let feedbackItems: [FeedbackItem] = [
            FeedbackType.incorrectVisual(subtype: nil),
            FeedbackType.confusingAudio(subtype: nil),
            FeedbackType.illegalRoute(subtype: nil),
            FeedbackType.roadClosure(subtype: nil),
            FeedbackType.routeQuality(subtype: nil),
            FeedbackType.positioning(subtype: nil)
        ].map { $0.generateFeedbackItem() }
        
        let feedbackButtonHandler: (_ : CPGridButton) -> Void = { [weak self] (button) in
            self?.carInterfaceController.popTemplate(animated: true)
            
            // TODO: Fix this Demeter violation with proper encapsulation
            guard let uuid = self?.navigationService.eventsManager.recordFeedback() else { return }
            let foundItem = feedbackItems.filter { $0.image == button.image }
            guard let feedbackItem = foundItem.first else { return }
            self?.navigationService.eventsManager.updateFeedback(uuid: uuid,
                                                                 type: feedbackItem.feedbackType,
                                                                 source: .user,
                                                                 description: nil)
            
            let dismissTitle = NSLocalizedString("CARPLAY_DISMISS",
                                                 bundle: .mapboxNavigation,
                                                 value: "Dismiss",
                                                 comment: "Title for dismiss button")
            
            let submittedTitle = NSLocalizedString("CARPLAY_SUBMITTED_FEEDBACK",
                                                   bundle: .mapboxNavigation,
                                                   value: "Submitted",
                                                   comment: "Alert title that shows when feedback has been submitted")
            
            let action = CPAlertAction(title: dismissTitle,
                                       style: .default,
                                       handler: { _ in })
            
            let alert = CPNavigationAlert(titleVariants: [submittedTitle],
                                          subtitleVariants: nil,
                                          imageSet: nil,
                                          primaryAction: action,
                                          secondaryAction: nil,
                                          duration: 2.5)
            
            self?.mapTemplate.present(navigationAlert: alert, animated: true)
        }
        
        let buttons: [CPGridButton] = feedbackItems.map {
            return CPGridButton(titleVariants: [$0.title.components(separatedBy: "\n").joined(separator: " ")],
                                image: $0.image,
                                handler: feedbackButtonHandler)
        }
        
        let gridTitle = NSLocalizedString("CARPLAY_FEEDBACK",
                                          bundle: .mapboxNavigation,
                                          value: "Feedback",
                                          comment: "Title for feedback template in CarPlay")
        
        return CPGridTemplate(title: gridTitle, gridButtons: buttons)
    }
    
    func endOfRouteFeedbackTemplate() -> CPGridTemplate {
        let buttonHandler: (_: CPGridButton) -> Void = { [weak self] (button) in
            if let title = button.titleVariants.first {
                let rating = Int(title.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())
                let endOfRouteFeedback = EndOfRouteFeedback(rating: rating, comment: nil)
                self?.navigationService.endNavigation(feedback: endOfRouteFeedback)
            }
            
            self?.carInterfaceController.popTemplate(animated: true)
            self?.exitNavigation()
        }
        
        var buttons: [CPGridButton] = []
        let starImage = UIImage(named: "star", in: .mapboxNavigation, compatibleWith: nil)!
        for i in 1...5 {
            let button = CPGridButton(titleVariants: ["\(i) star\(i == 1 ? "" : "s")"],
                                      image: starImage,
                                      handler: buttonHandler)
            buttons.append(button)
        }
        
        let gridTitle = NSLocalizedString("CARPLAY_RATE_RIDE",
                                          bundle: .mapboxNavigation,
                                          value: "Rate your ride",
                                          comment: "Title for rating template in CarPlay")
        
        return CPGridTemplate(title: gridTitle, gridButtons: buttons)
    }
    
    func presentArrivalUI() {
        let arrivalTitle = NSLocalizedString("CARPLAY_ARRIVED",
                                             bundle: .mapboxNavigation,
                                             value: "You have arrived",
                                             comment: "Title on arrival action sheet")
        
        let arrivalMessage = NSLocalizedString("CARPLAY_ARRIVED_MESSAGE",
                                               bundle: .mapboxNavigation,
                                               value: "What would you like to do?",
                                               comment: "Message on arrival action sheet")
        
        let exitTitle = NSLocalizedString("CARPLAY_EXIT_NAVIGATION",
                                          bundle: .mapboxNavigation,
                                          value: "Exit navigation",
                                          comment: "Title on the exit button in the arrival form")
        
        let exitAction = CPAlertAction(title: exitTitle, style: .cancel) { (action) in
            self.exitNavigation()
            self.dismiss(animated: true)
        }
        
        let rateTitle = NSLocalizedString("CARPLAY_RATE_TRIP",
                                          bundle: .mapboxNavigation,
                                          value: "Rate your trip",
                                          comment: "Title on rate button in CarPlay")
        
        let rateAction = CPAlertAction(title: rateTitle, style: .default) { (action) in
            self.carInterfaceController.pushTemplate(self.endOfRouteFeedbackTemplate(), animated: true)
        }
        
        let alert = CPActionSheetTemplate(title: arrivalTitle,
                                          message: arrivalMessage,
                                          actions: [rateAction, exitAction])
        
        carInterfaceController.dismissTemplate(animated: true)
        carInterfaceController.presentTemplate(alert, animated: true)
    }
    
    func presentWaypointArrivalUI(for waypoint: Waypoint) {
        var title = NSLocalizedString("CARPLAY_ARRIVED", bundle: .mapboxNavigation, value: "You have arrived", comment: "Title on arrival action sheet")
        if let name = waypoint.name {
            title = name
        }
        
        let continueTitle = NSLocalizedString("CARPLAY_CONTINUE", bundle: .mapboxNavigation, value: "Continue", comment: "Title on continue button in CarPlay")
        let continueAlert = CPAlertAction(title: continueTitle, style: .default) { (action) in
            self.navigationService.router?.advanceLegIndex()
            self.carInterfaceController.dismissTemplate(animated: true)
            self.updateRouteOnMap()
        }
        
        let waypointArrival = CPAlertTemplate(titleVariants: [title], actions: [continueAlert])
        carInterfaceController.dismissTemplate(animated: true)
        carInterfaceController.presentTemplate(waypointArrival, animated: true)
    }
}

// MARK: - StyleManagerDelegate methods

@available(iOS 12.0, *)
extension CarPlayNavigationViewController: StyleManagerDelegate {
    
    public func location(for styleManager: StyleManager) -> CLLocation? {
        if let location = navigationService.router.location {
            return location
        } else if let origin = navigationService.route.shape?.coordinates.first {
            return CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        } else {
            return nil
        }
    }
    
    public func styleManager(_ styleManager: StyleManager, didApply style: Style) {
        if navigationMapView?.mapView.mapboxMap.style.uri?.rawValue != style.mapStyleURL.absoluteString {
            navigationMapView?.mapView.mapboxMap.style.uri = StyleURI(url: style.mapStyleURL)
        }
    }
    
    public func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) {
        // TODO: Implement the ability to reload style.
    }
}

@available(iOS 12.0, *)
extension CarPlayNavigationViewController: NavigationServiceDelegate {
    
    public func navigationService(_ service: NavigationService, didArriveAt waypoint: Waypoint) -> Bool {
        let shouldPresentArrivalUI = delegate?.carPlayNavigationViewController(self, shouldPresentArrivalUIFor: waypoint) ?? true
        
        if service.routeProgress.isFinalLeg && shouldPresentArrivalUI {
            presentArrivalUI()
        } else if shouldPresentArrivalUI {
            presentWaypointArrivalUI(for: waypoint)
        }
        return true
    }
}
#endif
