import Foundation
import MapboxDirections
import MapboxCoreNavigation
#if canImport(CarPlay)
import CarPlay

@available(iOS 12.0, *)
public class CarPlayNavigationViewController: UIViewController, MGLMapViewDelegate {
    
    public weak var carPlayNavigationDelegate: CarPlayNavigationDelegate?
    
    public var drivingSide: DrivingSide = .right
    
    var routeController: RouteController
    var mapView: NavigationMapView?
    let shieldHeight: CGFloat = 16
    
    var carSession: CPNavigationSession!
    var mapTemplate: CPMapTemplate
    var carFeedbackTemplate: CPGridTemplate!
    var carInterfaceController: CPInterfaceController
    
    var styleManager: StyleManager!
    
    let distanceFormatter = DistanceFormatter(approximate: true)
    
    var edgePadding: UIEdgeInsets {
        let padding:CGFloat = 15
        return UIEdgeInsets(top: view.safeAreaInsets.top + padding,
                            left: view.safeAreaInsets.left + padding,
                            bottom: view.safeAreaInsets.bottom + padding,
                            right: view.safeAreaInsets.right + padding)
    }
    
    /**
     - postcondition: Call `startNavigationSession(for:)` after initializing this object to begin navigation.
     */
    public init(for routeController: RouteController,
                mapTemplate: CPMapTemplate,
                interfaceController: CPInterfaceController) {
        self.routeController = routeController
        self.mapTemplate = mapTemplate
        self.carInterfaceController = interfaceController
        
        super.init(nibName: nil, bundle: nil)
        carFeedbackTemplate = createFeedbackUI()
        routeController.delegate = self
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
    
    public func startNavigationSession(for trip: CPTrip) {
        carSession = mapTemplate.startNavigationSession(for: trip)
    }
    
    public func exitNavigation(canceled: Bool = false) {
        carSession.finishTrip()
        dismiss(animated: true, completion: nil)
        carPlayNavigationDelegate?.carPlayNavigationViewControllerDidDismiss(self, byCanceling: canceled)
    }
    
    public func showFeedback() {
        carInterfaceController.pushTemplate(self.carFeedbackTemplate, animated: true)
    }
    
    public var tracksUserCourse: Bool {
        get {
            return mapView?.tracksUserCourse ?? false
        }
        set {
            if !tracksUserCourse && newValue {
                mapView?.recenterMap()
                mapView?.addArrow(route: routeController.routeProgress.route,
                                 legIndex: routeController.routeProgress.legIndex,
                                 stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
            } else if tracksUserCourse && !newValue {
                guard let userLocation = self.routeController.locationManager.location?.coordinate else {
                    return
                }
                mapView?.enableFrameByFrameCourseViewTracking(for: 3)
                mapView?.setOverheadCameraView(from: userLocation, along: routeController.routeProgress.route.coordinates!, for: self.edgePadding)
            }
        }
    }
    public func beginPanGesture() {
        mapView?.tracksUserCourse = false
        mapView?.enableFrameByFrameCourseViewTracking(for: 1)
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
        
        let legProgress = routeProgress.currentLegProgress
        let legDistance = distanceFormatter.measurement(of: legProgress.distanceRemaining)
        let legEstimates = CPTravelEstimates(distanceRemaining: legDistance, timeRemaining: legProgress.durationRemaining)
        mapTemplate.update(legEstimates, for: carSession.trip, with: congestionLevel.asCPTimeRemainingColor)
        
        let stepProgress = legProgress.currentStepProgress
        let stepDistance = distanceFormatter.measurement(of: stepProgress.distanceRemaining)
        let stepEstimates = CPTravelEstimates(distanceRemaining: stepDistance, timeRemaining: stepProgress.durationRemaining)
        carSession.updateEstimates(stepEstimates, for: maneuver)
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
        let distance = distanceFormatter.measurement(of: step.distance)
        primaryManeuver.initialTravelEstimates = CPTravelEstimates(distanceRemaining: distance, timeRemaining: step.expectedTravelTime)
        
        // Just incase, set some default text
        var text = visualInstruction.primaryInstruction.text ?? step.instructions
        if let secondaryText = visualInstruction.secondaryInstruction?.text {
            text += "\n\(secondaryText)"
        }
        primaryManeuver.instructionVariants = [text]
        
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
        if let tertiaryInstruction = visualInstruction.tertiaryInstruction, !tertiaryInstruction.containsLaneIndications {
            let tertiaryManeuver = CPManeuver()
            tertiaryManeuver.symbolSet = tertiaryInstruction.maneuverImageSet
            
            if let text = tertiaryInstruction.text {
                tertiaryManeuver.instructionVariants = [text]
            }
            if let attributedTertiary = tertiaryInstruction.maneuverLabelAttributedText(bounds: bounds, shieldHeight: shieldHeight) {
                tertiaryManeuver.attributedInstructionVariants = [attributedTertiary]
            }
            
            if let upcomingStep = routeController.routeProgress.currentLegProgress.upComingStep {
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
            guard let uuid = self?.routeController.eventsManager.recordFeedback() else { return }
            let foundItem = feedbackItems.filter { $0.image == button.image }
            guard let feedbackItem = foundItem.first else { return }
            self?.routeController.eventsManager.updateFeedback(uuid: uuid, type: feedbackItem.feedbackType, source: .user, description: nil)
            
            let action = CPAlertAction(title: "Dismiss", style: .default, handler: {_ in })
            let alert = CPNavigationAlert(titleVariants: ["Submitted"], subtitleVariants: nil, imageSet: nil, primaryAction: action, secondaryAction: nil, duration: 2.5)
            self?.mapTemplate.present(navigationAlert: alert, animated: true)
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
        return routeController.locationManager.location
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
#endif
