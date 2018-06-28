import Foundation
import MapboxDirections
import MapboxCoreNavigation
import CarPlay

@available(iOS 12.0, *)
public class CarPlayNavigationViewController: UIViewController, MGLMapViewDelegate {
    
    public weak var navigationCarPlayDelegate: NavigationCarPlayDelegate?
    
    public var drivingSide: DrivingSide = .right
    
    var routeController: RouteController!
    var styleManager: StyleManager!
    var mapView: NavigationMapView?
    var styles: [Style]
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
    
    public init(for route: Route, session: CPNavigationSession, template: CPMapTemplate, interfaceController: CPInterfaceController, styles: [Style]?, locationManager: NavigationLocationManager? = NavigationLocationManager()) {
        self.carSession = session
        self.carMaptemplate = template
        self.voiceController = MapboxVoiceController()
        self.carInterfaceController = interfaceController
        var carStyles = styles ?? [DayStyle(), NightStyle()]
        carStyles = carStyles.map {
            $0.overrideStyleForCarPlay = true
            return $0
        }
        self.styles = carStyles
        if let locationManager = locationManager as? SimulatedLocationManager {
            locationManager.speedMultiplier = 10.0
        }
        self.routeController = RouteController(along: route, locationManager: locationManager ?? NavigationLocationManager())
        super.init(nibName: nil, bundle: nil)
        self.carMaptemplate.mapDelegate = self
        self.styleManager = StyleManager(self)
        self.carFeedbackTemplate = createFeedbackUI()
        
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
        mapView?.attributionButton.isHidden = true
        mapView?.logoView.isHidden = true
        mapView?.delegate = self
        self.styleManager.styles = self.styles
        
        view.addSubview(mapView!)
        
        resumeNotifications()
        routeController.resume()
        mapView?.recenterMap()
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // For some reason, these objects are not getting released when this view is dismissed.
        voiceController = nil
        routeController = nil
        suspendNotifications()
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
        dismiss(animated: true, completion: {
            self.carSession.finishTrip()
            self.navigationCarPlayDelegate?.carPlayNavigationViewControllerDidExit?(self)
        })
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
        exitButton.title = "Exit"
        
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
            .badRoute,
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
            self?.exitNavigation()
            self?.carInterfaceController.popTemplate(animated: true)
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
        let alert = CPAlert(titleVariants: ["You have arrived"], message: nil, style: .actionSheet, actions: [rateAction, exitAction])
        carInterfaceController.present(alert)
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
        
        let index = routeController.routeProgress.currentLegProgress.stepIndex
        
        if index != currentStepIndex {
            updateManeuvers()
            mapView?.showWaypoints(routeController.routeProgress.route)
            currentStepIndex = index
        }
        
        mapView?.addArrow(route: routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex, stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
        
        let congestionLevel = routeProgress.averageCongestionLevelRemainingOnLeg ?? .unknown
        guard let maneuver = carSession.upcomingManeuvers.first else { return }
        carSession.updateEstimates(routeProgress.currentLegProgress.currentStepProgress.travelEstimates, for: maneuver)
        carMaptemplate.update(routeProgress.currentLegProgress.travelEstimates, for: carSession.trip, with: congestionLevel.asCPTimeRemainingColor)
    }
    
    @objc func rerouted(_ notification: NSNotification) {
        updateManeuvers()
        self.mapView?.recenterMap()
        self.mapView?.addArrow(route: routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex, stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
        self.mapView?.showRoutes([routeController.routeProgress.route])
        self.mapView?.showWaypoints(routeController.routeProgress.route)
    }
    
    func updateManeuvers() {
        let step = routeController.routeProgress.currentLegProgress.currentStep
        
        let maneuver = CPManeuver()
        let backupText = step.instructionsDisplayedAlongStep?.first?.primaryInstruction.text ?? step.instructions
        
        maneuver.instructionVariants = [backupText]

        // todo get this to work and not crash
        if let visual = step.instructionsDisplayedAlongStep?.last {
            let instructionLabel = InstructionLabel()
            instructionLabel.availableBounds = {
                // Estimating the width of Apple's maneuver view
                let widthOfManeuverView = max(self.view.safeArea.left, self.view.safeArea.right)
                return CGRect(x: 0, y: 0, width: widthOfManeuverView, height: 30)
            }
            instructionLabel.instruction = visual.primaryInstruction
            if let attributed = instructionLabel.attributedText {
                maneuver.attributedInstructionVariants = [attributed]
            }
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
        
        carSession.upcomingManeuvers = [maneuver]
    }
}

@available(iOS 12.0, *)
extension CarPlayNavigationViewController: StyleManagerDelegate {
    public func locationFor(styleManager: StyleManager) -> CLLocation? {
        if routeController != nil {
            return routeController.location
        } else {
            return nil
        }
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
        }
        
        return true
    }
}

@available(iOS 12.0, *)
extension CarPlayNavigationViewController: CPMapTemplateDelegate {
    
    public func mapTemplateDidBeginPanGesture(_ mapTemplate: CPMapTemplate) {
        mapView?.tracksUserCourse = false
        overviewButton.isHidden = true
        recenterButton.isHidden = false
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate, didUpdatePanGestureWithDelta delta: CGPoint, velocity: CGPoint) {
    }
    
    public func mapTemplate(_ mapTemplate: CPMapTemplate, didEndPanGestureWithVelocity velocity: CGPoint) {
        // Not enough velocity to overcome friction
        guard sqrtf(Float(velocity.x * velocity.x + velocity.y * velocity.y)) > 100 else { return }
        
        let offset = CGPoint(x: velocity.x * decelerationRate / 4, y: velocity.y * decelerationRate / 4)
        guard let toCamera = camera(whenPanningTo: offset) else { return }
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
@objc(MBNavigationCarPlayDelegate)
public protocol NavigationCarPlayDelegate {
    @objc(carPlayNavigationViewControllerDidExit:)
    optional func carPlayNavigationViewControllerDidExit(_ carPlayNavigationViewController: CarPlayNavigationViewController)
}
