import Foundation
import MapboxDirections
import MapboxCoreNavigation
#if canImport(CarPlay)
import CarPlay

@available(iOS 12.0, *)
protocol NavigationMapTemplateControllerDelegate: class {
    func navigationMapTemplateController(_ navigationMapTemplateController: NavigationMapTemplateController, willHandle mapButton: CPMapButton)
    func navigationMapTemplateController(_ navigationMapTemplateController: NavigationMapTemplateController, willHandle barButton: CPBarButton)
}

@available(iOS 12.0, *)
public class NavigationMapTemplateController {
    var mapTemplate: CPMapTemplate
    weak var delegate: NavigationMapTemplateControllerDelegate?
    weak var mapDelegate: CPMapTemplateDelegate? {
        get {
            return mapTemplate.mapDelegate
        }
        set {
            mapTemplate.mapDelegate = mapDelegate
        }
    }
    
    var previousMapButtons: [CPMapButton]
    var previousLeadingNavigationBarButtons: [CPBarButton]
    var previousTrailingNavigationBarButtons: [CPBarButton]
    
    var showFeedbackButton: CPMapButton!
    var overviewButton: CPMapButton!
    var recenterButton: CPMapButton!
    
    var exitButton: CPBarButton!
    var muteButton: CPBarButton!
    
    init(mapTemplate: CPMapTemplate) {
        self.mapTemplate = mapTemplate
        previousMapButtons = mapTemplate.mapButtons
        previousLeadingNavigationBarButtons = mapTemplate.leadingNavigationBarButtons
        previousTrailingNavigationBarButtons = mapTemplate.trailingNavigationBarButtons
        createNavigationButtons()
    }
    
    func createNavigationButtons() {
        let mapButtonHandler = { [weak self] (button: CPMapButton) in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.navigationMapTemplateController(strongSelf, willHandle: button)
        }
        showFeedbackButton = CPMapButton(handler: mapButtonHandler)
        showFeedbackButton.image = UIImage(named: "feedback", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate).roundedWithBorder(width: 6, color: .white)
        
        overviewButton = CPMapButton(handler: mapButtonHandler)
        overviewButton.image = UIImage(named: "overview", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate).roundedWithBorder(width: 6, color: .white)
        
        recenterButton = CPMapButton(handler: mapButtonHandler)
        recenterButton.image = UIImage(named: "location", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate).roundedWithBorder(width: 6, color: .white)
        
        let barButtonHandler = { [weak self] (button: CPBarButton) in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.navigationMapTemplateController(strongSelf, willHandle: button)
        }
        
        exitButton = CPBarButton(type: .text, handler: barButtonHandler)
        exitButton.title = "End"
        
        muteButton = CPBarButton(type: .text, handler: barButtonHandler)
    }
    
    func startNavigationSession(for trip: CPTrip) -> CPNavigationSession {
        mapTemplate.mapButtons = [overviewButton, recenterButton, showFeedbackButton]
        
        mapTemplate.leadingNavigationBarButtons = [muteButton]
        mapTemplate.trailingNavigationBarButtons = [exitButton]
        
        recenterButton.isHidden = true
        muteButton.title = NavigationSettings.shared.voiceMuted ? "Enable Voice" : "Disable Voice"
        
        return mapTemplate.startNavigationSession(for: trip)
    }
    
    func update(_ estimates: CPTravelEstimates, for trip: CPTrip, with timeRemainingColor: CPTimeRemainingColor) {
        mapTemplate.update(estimates, for: trip, with: timeRemainingColor)
    }
    
    func present(navigationAlert: CPNavigationAlert, animated: Bool) {
        mapTemplate.present(navigationAlert: navigationAlert, animated: animated)
    }
    
    func stopNavigationSession() {
        mapTemplate.mapButtons = previousMapButtons
        mapTemplate.leadingNavigationBarButtons = previousLeadingNavigationBarButtons
        mapTemplate.trailingNavigationBarButtons = previousTrailingNavigationBarButtons
    }
}

@available(iOS 12.0, *)
public class CarPlayNavigationViewController: UIViewController, MGLMapViewDelegate {
    
    public weak var carPlayNavigationDelegate: CarPlayNavigationDelegate?
    
    public var drivingSide: DrivingSide = .right
    
    var routeController: RouteController
    var mapView: NavigationMapView?
    let decelerationRate:CGFloat = 0.9
    let shieldHeight: CGFloat = 16
    
    var carSession: CPNavigationSession
    var mapTemplateController: NavigationMapTemplateController
    var carFeedbackTemplate: CPGridTemplate!
    var carInterfaceController: CPInterfaceController
    
    var styleManager: StyleManager!
    
    var edgePadding: UIEdgeInsets {
        let padding:CGFloat = 15
        return UIEdgeInsets(top: view.safeAreaInsets.top + padding,
                            left: view.safeAreaInsets.left + padding,
                            bottom: view.safeAreaInsets.bottom + padding,
                            right: view.safeAreaInsets.right + padding)
    }
    
    public init(for routeController: RouteController,
                on trip: CPTrip,
                templateController: NavigationMapTemplateController,
                interfaceController: CPInterfaceController) {
        mapTemplateController = templateController
        // TODO: Start navigation session outside of an initializer.
        carSession = mapTemplateController.startNavigationSession(for: trip)
        self.carInterfaceController = interfaceController
        self.routeController = routeController
        
        super.init(nibName: nil, bundle: nil)
        self.carFeedbackTemplate = createFeedbackUI()
        self.routeController.delegate = self
        mapTemplateController.delegate = self
        mapTemplateController.mapDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let mapView = NavigationMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.compassView.isHidden = true
        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true
        mapView.delegate = self

        mapView.defaultAltitude = 500
        mapView.zoomedOutMotorwayAltitude = 1000
        mapView.longManeuverDistance = 500

        self.mapView = mapView
        view.addSubview(mapView)
        
        styleManager = StyleManager(self)
        styleManager.styles = [CarPlayDayStyle(), CarPlayNightStyle()]
        
        resumeNotifications()
        routeController.resume()
        mapView.recenterMap()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        suspendNotifications()
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_:)), name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rerouted(_:)), name: .routeControllerDidReroute, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(visualInstructionDidChange(_:)), name: .routeControllerDidPassVisualInstructionPoint, object: nil)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidPassVisualInstructionPoint, object: nil)
    }
    
    func exitNavigation(canceled: Bool = false) {
        carSession.finishTrip()
        mapTemplateController.stopNavigationSession()
        dismiss(animated: true, completion: nil)
        carPlayNavigationDelegate?.carPlayNavigationViewControllerDidDismiss(self, byCanceling: canceled)
    }
    
    public func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        self.mapView?.addArrow(route: routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex, stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
        self.mapView?.showRoutes([routeController.routeProgress.route])
        self.mapView?.showWaypoints(routeController.routeProgress.route)
        self.mapView?.recenterMap()
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
        let camera = MGLMapCamera(lookingAtCenter: location.coordinate, fromDistance: 120, pitch: 60, heading: location.course)
        mapView?.updateCourseTracking(location: location, camera: camera, animated: true)
        
        let congestionLevel = routeProgress.averageCongestionLevelRemainingOnLeg ?? .unknown
        guard let maneuver = carSession.upcomingManeuvers.first else { return }
        carSession.updateEstimates(routeProgress.currentLegProgress.currentStepProgress.travelEstimates, for: maneuver)
        mapTemplateController.update(routeProgress.currentLegProgress.travelEstimates, for: carSession.trip, with: congestionLevel.asCPTimeRemainingColor)
    }
    
    @objc func rerouted(_ notification: NSNotification) {
        updateRouteOnMap()
        self.mapView?.recenterMap()
    }
    
    func updateRouteOnMap() {
        mapView?.addArrow(route: routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex, stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
        mapView?.showRoutes([routeController.routeProgress.route], legIndex: routeController.routeProgress.legIndex)
        mapView?.showWaypoints(routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex)
    }
    
    func updateManeuvers(for routeProgress: RouteProgress) {
        guard let visualInstruction = routeProgress.currentLegProgress.currentStepProgress.currentVisualInstruction else { return }
        let step = routeController.routeProgress.currentLegProgress.currentStep
        
        let primaryManeuver = CPManeuver()
        
        primaryManeuver.initialTravelEstimates = CPTravelEstimates(distanceRemaining: Measurement(value: step.distance, unit: UnitLength.meters), timeRemaining: step.expectedTravelTime)
        
        // Just incase, set some default text
        let backupText = visualInstruction.primaryInstruction.text ?? step.instructions
        primaryManeuver.instructionVariants = [backupText]
        
        // Add maneuver arrow
        primaryManeuver.symbolSet = visualInstruction.primaryInstruction.maneuverImageSet
        
        // Estimating the width of Apple's maneuver view
        let bounds: () -> (CGRect) = {
            let widthOfManeuverView = min(self.view.bounds.width - self.view.safeArea.left, self.view.bounds.width - self.view.safeArea.right)
            return CGRect(x: 0, y: 0, width: widthOfManeuverView, height: 30)
        }
        
        if let attributedPrimary = visualInstruction.primaryInstruction.maneuverLabelAttributedText(bounds: bounds, shieldHeight: shieldHeight) {
            let instruction = NSMutableAttributedString(attributedString: attributedPrimary)
            
            if let attributedSecondary = visualInstruction.secondaryInstruction?.maneuverLabelAttributedText(bounds: bounds, shieldHeight: shieldHeight) {
                instruction.append(NSAttributedString(string: "\n"))
                instruction.append(attributedSecondary)
            }
            
            primaryManeuver.attributedInstructionVariants = [instruction]
        }
        
        var maneuvers: [CPManeuver] = [primaryManeuver]
        
        // Add tertiary text if available. TODO: handle lanes.
        if let tertiaryInstruction = visualInstruction.tertiaryInstruction, !tertiaryInstruction.containsLaneIndications, let tertiaryText = tertiaryInstruction.maneuverLabelAttributedText(bounds: bounds, shieldHeight: shieldHeight) {
            let tertiaryManeuver = CPManeuver()
            tertiaryManeuver.attributedInstructionVariants = [ tertiaryText ]
            tertiaryManeuver.symbolSet = tertiaryInstruction.maneuverImageSet
            
            if let upcomingStep = routeController.routeProgress.currentLegProgress.upComingStep {
                tertiaryManeuver.initialTravelEstimates = CPTravelEstimates(distanceRemaining: Measurement(value: upcomingStep.distance, unit: UnitLength.meters), timeRemaining: upcomingStep.expectedTravelTime)
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
            guard let uuid = self?.routeController.eventsManager.recordFeedback() else { return }
            let foundItem = feedbackItems.filter { $0.image == button.image }
            guard let feedbackItem = foundItem.first else { return }
            self?.routeController.eventsManager.updateFeedback(uuid: uuid, type: feedbackItem.feedbackType, source: .user, description: nil)
            
            let action = CPAlertAction(title: "Dismiss", style: .default, handler: {_ in })
            let alert = CPNavigationAlert(titleVariants: ["Submitted"], subtitleVariants: nil, imageSet: nil, primaryAction: action, secondaryAction: nil, duration: 2.5)
            self?.mapTemplateController.present(navigationAlert: alert, animated: true)
        }
        
        let buttons: [CPGridButton] = feedbackItems.map {
            return CPGridButton(titleVariants: [$0.title.components(separatedBy: "\n").joined(separator: " ")], image: $0.image, handler: feedbackButtonHandler)
        }
        
        return CPGridTemplate(title: "Feedback", gridButtons: buttons)
    }
    
    func endOfRouteFeedbackTemplate() -> CPGridTemplate {
        let buttonHandler: (_: CPGridButton) -> Void = { [weak self] (button) in
            //TODO: no such method exists, and the replacement candidate ignores the feedback sent, so ... ?
//            self?.routeController.setEndOfRoute(rating: Int(button.titleVariants.first!.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())!, comment: nil)
            self?.carInterfaceController.popTemplate(animated: true)
            self?.exitNavigation()
        }
        
        var buttons: [CPGridButton] = []
        let starImage = UIImage(named: "star", in: .mapboxNavigation, compatibleWith: nil)!
        for i in 1...5 {
            let button = CPGridButton(titleVariants: ["\(i) star\(i == 1 ? "" : "s")"], image: starImage, handler: buttonHandler)
            buttons.append(button)
        }
        
        return CPGridTemplate(title: "Rate your ride", gridButtons: buttons)
    }
    
    func presentArrivalUI() {
        let exitAction = CPAlertAction(title: "Exit navigation", style: .cancel) { (action) in
            self.exitNavigation()
            self.dismiss(animated: true, completion: nil)
        }
        let rateAction = CPAlertAction(title: "Rate your trip", style: .default) { (action) in
            self.carInterfaceController.pushTemplate(self.endOfRouteFeedbackTemplate(), animated: true)
        }
        let alert = CPActionSheetTemplate(title: "You have arrived", message: "What would you like to do?", actions: [rateAction, exitAction])
        carInterfaceController.presentTemplate(alert, animated: true)
    }
    
    func presentWayointArrivalUI(for waypoint: Waypoint) {
        var title = "You have arrived"
        if let name = waypoint.name {
            title = name
        }
        
        let continueAlert = CPAlertAction(title: "Continue", style: .default) { (action) in
            self.routeController.routeProgress.legIndex += 1
            self.carInterfaceController.dismissTemplate(animated: true)
            self.updateRouteOnMap()
        }
        
        let waypointArrival = CPAlertTemplate(titleVariants: [title], actions: [continueAlert])
        carInterfaceController.presentTemplate(waypointArrival, animated: true)
    }
}

@available(iOS 12.0, *)
extension CarPlayNavigationViewController: StyleManagerDelegate {
    public func locationFor(styleManager: StyleManager) -> CLLocation? {
        return routeController.location
    }
    
    public func styleManager(_ styleManager: StyleManager, didApply style: Style) {
        if mapView?.styleURL != style.mapStyleURL {
            mapView?.style?.transition = MGLTransition(duration: 0.5, delay: 0)
            mapView?.styleURL = style.mapStyleURL
        }
    }
    
    public func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) {
        mapView?.reloadStyle(self)
    }
}

@available(iOS 12.0, *)
extension CarPlayNavigationViewController: RouteControllerDelegate {
    public func routeController(_ routeController: RouteController, didArriveAt waypoint: Waypoint) -> Bool {
        if routeController.routeProgress.isFinalLeg {
            presentArrivalUI()
            carPlayNavigationDelegate?.carPlayNavigationViewControllerDidArrive(self)
        } else {
            presentWayointArrivalUI(for: waypoint)
        }
        return false
    }
}

@available(iOS 12.0, *)
@objc(MBNavigationCarPlayDelegate)
public protocol CarPlayNavigationDelegate {
    /**
     Called when the CarPlay navigation view controller is dismissed, such as when the user ends a trip.
     
     - parameter carPlayNavigationViewController: The CarPlay navigation view controller that was dismissed.
     - parameter canceled: True if the user dismissed the CarPlay navigation view controller by tapping the Cancel button; false if the navigation view controller dismissed by some other means.
     */
    @objc func carPlayNavigationViewControllerDidDismiss(_ carPlayNavigationViewController: CarPlayNavigationViewController, byCanceling canceled: Bool)

    /**
     Called when the CarPlay navigation view controller detects an arrival.

     - parameter carPlayNavigationViewController: The CarPlay navigation view controller that was dismissed.
     */
    @objc func carPlayNavigationViewControllerDidArrive(_ carPlayNavigationViewController: CarPlayNavigationViewController)
}

@available(iOS 12.0, *)
extension CarPlayNavigationViewController: CPMapTemplateDelegate {
    public func mapTemplateDidBeginPanGesture(_ mapTemplateController: CPMapTemplate) {
        self.mapTemplateController.overviewButton.isHidden = true
        self.mapTemplateController.recenterButton.isHidden = false
        mapView?.tracksUserCourse = false
        mapView?.enableFrameByFrameCourseViewTracking(for: 1)
    }
    
    public func mapTemplate(_ mapTemplateController: CPMapTemplate, didEndPanGestureWithVelocity velocity: CGPoint) {
        // Not enough velocity to overcome friction
        guard sqrtf(Float(velocity.x * velocity.x + velocity.y * velocity.y)) > 100 else { return }
        
        let offset = CGPoint(x: velocity.x * decelerationRate / 4, y: velocity.y * decelerationRate / 4)
        guard let toCamera = camera(whenPanningTo: offset) else { return }
        mapView?.tracksUserCourse = false
        mapView?.setCamera(toCamera, animated: true)
    }
    
    func camera(whenPanningTo endPoint: CGPoint) -> MGLMapCamera? {
        guard let mapView = mapView else { return nil }
        let camera = mapView.camera
        let centerPoint = CGPoint(x: mapView.bounds.midX, y: mapView.bounds.midY)
        let endCameraPoint = CGPoint(x: centerPoint.x - endPoint.x, y: centerPoint.y - endPoint.y)
        camera.centerCoordinate = mapView.convert(endCameraPoint, toCoordinateFrom: mapView)
        
        return camera
    }
}

@available(iOS 12.0, *)
extension CarPlayNavigationViewController: NavigationMapTemplateControllerDelegate {
    func navigationMapTemplateController(_ navigationMapTemplateController: NavigationMapTemplateController, willHandle mapButton: CPMapButton) {
        if mapButton == navigationMapTemplateController.showFeedbackButton {
            carInterfaceController.pushTemplate(carFeedbackTemplate, animated: true)
        } else if mapButton == navigationMapTemplateController.overviewButton {
            guard let userLocation = routeController.location?.coordinate else { return }
            mapView?.enableFrameByFrameCourseViewTracking(for: 3)
            mapView?.setOverheadCameraView(from: userLocation, along: routeController.routeProgress.route.coordinates!, for: edgePadding)
            mapButton.isHidden = true
            navigationMapTemplateController.recenterButton.isHidden = false
        } else if mapButton == navigationMapTemplateController.recenterButton {
            mapButton.isHidden = true
            navigationMapTemplateController.overviewButton.isHidden = false
            mapView?.recenterMap()
        } else {
            assert(false, "Unrecognized map button \(mapButton)")
        }
    }
    
    func navigationMapTemplateController(_ navigationMapTemplateController: NavigationMapTemplateController, willHandle barButton: CPBarButton) {
        if barButton == navigationMapTemplateController.exitButton {
            exitNavigation(canceled: true)
        } else if barButton == navigationMapTemplateController.muteButton {
            NavigationSettings.shared.voiceMuted = !NavigationSettings.shared.voiceMuted
            barButton.title = NavigationSettings.shared.voiceMuted ? "Enable Voice" : "Disable Voice"
        } else {
            assert(false, "Unrecognized bar button \(barButton)")
        }
    }
}
#endif

