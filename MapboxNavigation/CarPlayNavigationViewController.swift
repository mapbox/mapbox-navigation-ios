import Foundation
import MapboxDirections
import MapboxCoreNavigation
import CarPlay

@available(iOS 12.0, *)
public class CarPlayNavigationViewController: UIViewController, MGLMapViewDelegate {
    
    public weak var carPlayNavigationDelegate: CarPlayNavigationDelegate?
    
    public var drivingSide: DrivingSide = .right
    
    var routeController: RouteController
    var mapView: NavigationMapView?
    var voiceController: MapboxVoiceController?
    var currentStepIndex: Int?
    let decelerationRate:CGFloat = 0.9
    
    var carSession: CPNavigationSession
    var carMaptemplate: CPMapTemplate
    var carFeedbackTemplate: CPGridTemplate!
    var carInterfaceController: CPInterfaceController
    var overviewButton: CPMapButton!
    var recenterButton: CPMapButton!
    
    var edgePadding: UIEdgeInsets {
        let padding:CGFloat = 15
        return UIEdgeInsets(top: view.safeAreaInsets.top + padding,
                            left: view.safeAreaInsets.left + padding,
                            bottom: view.safeAreaInsets.bottom + padding,
                            right: view.safeAreaInsets.right + padding)
    }
    
    public init(for routeController: RouteController,
                session: CPNavigationSession,
                template: CPMapTemplate,
                interfaceController: CPInterfaceController) {
        self.carSession = session
        self.carMaptemplate = template
        self.voiceController = MapboxVoiceController()
        self.carInterfaceController = interfaceController
        self.routeController = routeController
        super.init(nibName: nil, bundle: nil)
        self.carFeedbackTemplate = createFeedbackUI()
        self.routeController.delegate = self
        self.carMaptemplate.mapDelegate = self
        
        createMapTemplateUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = NavigationMapView(frame: view.bounds)
        mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView?.compassView.isHidden = true
        mapView?.logoView.isHidden = true
        mapView?.delegate = self
        view.addSubview(mapView!)
        
        resumeNotifications()
        routeController.resume()
        mapView?.recenterMap()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        suspendNotifications()
        //Todo: For some reason, when deiniting this view controller, the voice controller sticks around.
        voiceController = nil
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_:)), name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rerouted(_:)), name: .routeControllerDidReroute, object: nil)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidReroute, object: nil)
    }
    
    func exitNavigation() {
        carSession.finishTrip()
        dismiss(animated: true, completion: nil)
        carPlayNavigationDelegate?.carPlaynavigationViewControllerDidDismiss(self, byCanceling: true)
    }
    
    public func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        self.mapView?.addArrow(route: routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex, stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
        self.mapView?.showRoutes([routeController.routeProgress.route])
        self.mapView?.showWaypoints(routeController.routeProgress.route)
        self.mapView?.recenterMap()
    }
    
    @objc func progressDidChange(_ notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as! RouteProgress
        let location = notification.userInfo![RouteControllerNotificationUserInfoKey.locationKey] as! CLLocation
        
        // Update the user puck
        mapView?.updateCourseTracking(location: location, animated: true)
        
        let index = routeProgress.currentLegProgress.stepIndex
        
        if index != currentStepIndex {
            updateManeuvers()
            mapView?.showWaypoints(routeProgress.route)
            currentStepIndex = index
            mapView?.addArrow(route: routeProgress.route, legIndex: routeProgress.legIndex, stepIndex: routeProgress.currentLegProgress.stepIndex + 1)
        }
        
        let congestionLevel = routeProgress.averageCongestionLevelRemainingOnLeg ?? .unknown
        guard let maneuver = carSession.upcomingManeuvers.first else { return }
        carSession.updateEstimates(routeProgress.currentLegProgress.currentStepProgress.travelEstimates, for: maneuver)
        carMaptemplate.update(routeProgress.currentLegProgress.travelEstimates, for: carSession.trip, with: congestionLevel.asCPTimeRemainingColor)
    }
    
    @objc func rerouted(_ notification: NSNotification) {
        updateManeuvers()
        updateRouteOnMap()
        self.mapView?.recenterMap()
    }
    
    func updateRouteOnMap() {
        mapView?.addArrow(route: routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex, stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
        mapView?.showRoutes([routeController.routeProgress.route], legIndex: routeController.routeProgress.legIndex)
        mapView?.showWaypoints(routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex)
    }
    
    func updateManeuvers() {
        guard let visualInstructions = routeController.routeProgress.currentLegProgress.currentStep.instructionsDisplayedAlongStep else { return }
        let step = routeController.routeProgress.currentLegProgress.currentStep
        
        let maneuvers: [CPManeuver] = visualInstructions.map { visualInstruction in
            let maneuver = CPManeuver()
            let backupText = visualInstructions.first?.primaryInstruction.text ?? step.instructions
            
            maneuver.instructionVariants = [backupText]
            
            let instructionLabel = InstructionLabel()
            instructionLabel.availableBounds = {
                // Estimating the width of Apple's maneuver view
                let widthOfManeuverView = max(self.view.safeArea.left, self.view.safeArea.right)
                return CGRect(x: 0, y: 0, width: widthOfManeuverView, height: 30)
            }
            instructionLabel.instruction = visualInstruction.primaryInstruction
            if let attributed = instructionLabel.attributedText {
                maneuver.attributedInstructionVariants = [attributed]
            }
            
            maneuver.initialTravelEstimates = CPTravelEstimates(distanceRemaining: Measurement(value: step.distance, unit: UnitLength.meters), timeRemaining: step.expectedTravelTime)
            
            let primaryColors: [UIColor] = [.black, .white]
            
            if let visual = step.instructionsDisplayedAlongStep?.last {
                let blackAndWhiteManeuverIcons: [UIImage] = primaryColors.compactMap { (color) in
                    let mv = ManeuverView()
                    mv.frame = CGRect(x: 0, y: 0, width: 38, height: 38)
                    mv.primaryColor = color
                    mv.backgroundColor = .clear
                    mv.visualInstruction = visual
                    return mv.imageRepresentation
                }
                if blackAndWhiteManeuverIcons.count == 2 {
                    maneuver.symbolSet = CPImageSet(lightContentImage: blackAndWhiteManeuverIcons[1], darkContentImage: blackAndWhiteManeuverIcons[0])
                }
            }
            return maneuver
        }
        
        carSession.upcomingManeuvers = maneuvers
    }
    
    func createMapTemplateUI() {
        let showFeedbackButton = CPMapButton { [weak self] (button) in
            guard let strongSelf = self else { return }
            strongSelf.carInterfaceController.pushTemplate(strongSelf.carFeedbackTemplate, animated: true)
        }
        showFeedbackButton.image = UIImage(named: "feedback", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate).roundedWithBorder(width: 6, color: .white)
        
        overviewButton = CPMapButton {  [weak self] (button) in
            guard let strongSelf = self else { return }
            guard let userLocation = self?.routeController.location?.coordinate else { return }
            strongSelf.mapView?.enableFrameByFrameCourseViewTracking(for: 3)
            strongSelf.mapView?.setOverheadCameraView(from: userLocation, along: strongSelf.routeController.routeProgress.route.coordinates!, for: strongSelf.edgePadding)
            button.isHidden = true
            strongSelf.recenterButton.isHidden = false
        }
        overviewButton.image = UIImage(named: "overview", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate).roundedWithBorder(width: 6, color: .white)
        
        recenterButton = CPMapButton { [weak self] (button) in
            button.isHidden = true
            self?.overviewButton.isHidden = false
            self?.mapView?.recenterMap()
        }
        recenterButton.isHidden = true
        recenterButton.image = UIImage(named: "location", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate).roundedWithBorder(width: 6, color: .white)
        
        let exitButton = CPBarButton(type: .text) { [weak self] (button) in
            guard let strongSelf = self else { return }
            strongSelf.exitNavigation()
        }
        exitButton.title = "End"
        
        let muteButton = CPBarButton(type: .text) { (button) in
            NavigationSettings.shared.voiceMuted = !NavigationSettings.shared.voiceMuted
            button.title = NavigationSettings.shared.voiceMuted ? "Enable Voice" : "Disable Voice"
        }
        muteButton.title = NavigationSettings.shared.voiceMuted ? "Enable Voice" : "Disable Voice"
        
        carMaptemplate.mapButtons = [overviewButton, recenterButton, showFeedbackButton]
        carMaptemplate.trailingNavigationBarButtons = [exitButton]
        carMaptemplate.leadingNavigationBarButtons = [muteButton]
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
            guard let uuid = self?.routeController.recordFeedback() else { return }
            let foundItem = feedbackItems.filter { $0.image == button.image }
            guard let feedbackItem = foundItem.first else { return }
            self?.routeController.updateFeedback(uuid: uuid, type: feedbackItem.feedbackType, source: .user, description: nil)
            
            let action = CPAlertAction(title: "Dismiss", style: .default, handler: {_ in })
            let alert = CPNavigationAlert(titleVariants: ["Submitted"], subtitleVariants: nil, imageSet: nil, primaryAction: action, secondaryAction: nil, duration: 2.5)
            self?.carMaptemplate.present(navigationAlert: alert, animated: true)
        }
        
        let buttons: [CPGridButton] = feedbackItems.map {
            return CPGridButton(titleVariants: [$0.title.components(separatedBy: "\n").joined(separator: " ")], image: $0.image, handler: feedbackButtonHandler)
        }
        
        return CPGridTemplate(title: "Feedback", gridButtons: buttons)
    }
    
    func createEndOfRouteFeedbackUI() -> CPGridTemplate {
        let buttonHandler: (_: CPGridButton) -> Void = { [weak self] (button) in
            self?.routeController.setEndOfRoute(rating: Int(button.titleVariants.first!.components(separatedBy: CharacterSet.decimalDigits.inverted).joined())!, comment: nil)
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
            self.dismiss(animated: true, completion: nil)
        }
        let rateAction = CPAlertAction(title: "Rate your trip", style: .default) { (action) in
            self.carInterfaceController.pushTemplate(self.createEndOfRouteFeedbackUI(), animated: true)
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
    @objc func carPlaynavigationViewControllerDidDismiss(_ carPlayNavigationViewController: CarPlayNavigationViewController, byCanceling canceled: Bool)
}

@available(iOS 12.0, *)
extension CarPlayNavigationViewController: CPMapTemplateDelegate {
    public func mapTemplateDidBeginPanGesture(_ mapTemplate: CPMapTemplate) {
        overviewButton.isHidden = true
        recenterButton.isHidden = false
        mapView?.tracksUserCourse = false
        mapView?.enableFrameByFrameCourseViewTracking(for: 1)
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate, didEndPanGestureWithVelocity velocity: CGPoint) {
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
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate, displayStyleFor maneuver: CPManeuver) -> CPManeuverDisplayStyle {
        // Unsure what this does right now
        return [.instructionOnly, .symbolOnly, .trailingSymbol, .leadingSymbol]
    }

}
