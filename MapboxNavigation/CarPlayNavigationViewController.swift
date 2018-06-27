import Foundation
import MapboxDirections
import MapboxCoreNavigation
import CarPlay

public class CarPlayNavigationViewController: UIViewController, MGLMapViewDelegate {
    
    public weak var navigationCarPlayDelegate: NavigationCarPlayDelegate?
    
    public var drivingSide: DrivingSide = .right
    
    var route: Route
    var routeController: RouteController!
    var styleManager: StyleManager!
    var mapView: NavigationMapView?
    var styles: [Style]
    var voiceController: MapboxVoiceController?
    var currentStepIndex: Int?
    
    var carSession: CPNavigationSession
    var carMaptemplate: CPMapTemplate
    var carFeedbackTemplate: CPGridTemplate!
    var carInterfaceController: CPInterfaceController
    
    public init(for route: Route, session: CPNavigationSession, template: CPMapTemplate, interfaceController: CPInterfaceController, styles: [Style]?, locationManager: NavigationLocationManager? = NavigationLocationManager()) {
        self.route = route
        self.carSession = session
        self.carMaptemplate = template
        self.voiceController = MapboxVoiceController()
        self.carInterfaceController = interfaceController
        self.styles = styles ?? [DayStyle(), NightStyle()]
        self.routeController = RouteController(along: route, locationManager: locationManager ?? NavigationLocationManager())
        super.init(nibName: nil, bundle: nil)
        self.styleManager = StyleManager(self)
        self.carFeedbackTemplate = self.createFeedbackUI()
        
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
        var recenter: CPMapButton!
        
        let showFeedbackButton = CPMapButton { [weak self] (button) in
            guard let strongSelf = self else { return }
            strongSelf.carInterfaceController.pushTemplate(strongSelf.carFeedbackTemplate, animated: true)
        }
        showFeedbackButton.image = UIImage(named: "feedback", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate).roundedWithBorder(width: 6, color: .white)
        
        let overviewButton = CPMapButton {  [weak self] (button) in
            guard let strongSelf = self else { return }
            guard let userLocation = self?.routeController.location?.coordinate else { return }
            strongSelf.mapView?.setOverheadCameraView(from: userLocation, along: strongSelf.routeController.routeProgress.route.coordinates!, for: UIEdgeInsets().carPlayInsets(for: .right))
            button.isHidden = true
            recenter.isHidden = false
        }
        overviewButton.image = UIImage(named: "overview", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate).roundedWithBorder(width: 6, color: .white)
        
        recenter = CPMapButton { [weak self] (button) in
            button.isHidden = true
            overviewButton.isHidden = false
            self?.mapView?.recenterMap()
        }
        recenter.isHidden = true
        recenter.image = UIImage(named: "location", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate).roundedWithBorder(width: 6, color: .white)
        
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
        
        carMaptemplate.mapButtons = [overviewButton, recenter, showFeedbackButton]
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
            self.carInterfaceController.pushTemplate(self.carFeedbackTemplate, animated: true)
        }
        let alert = CPAlert(titleVariants: ["You have arrived"], message: nil, style: .actionSheet, actions: [rateAction, exitAction])
        carInterfaceController.present(alert)
    }
    
    public func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        self.mapView?.showRoutes([routeController.routeProgress.route])
        self.mapView?.showWaypoints(route)
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
            mapView?.showWaypoints(route)
            currentStepIndex = index
        }
        
        let congestionLevel = routeProgress.averageCongestionLevelRemainingOnLeg ?? .unknown
        guard let maneuver = carSession.upcomingManeuvers.first else { return }
        carSession.updateEstimates(routeProgress.currentLegProgress.currentStepProgress.travelEstimates, for: maneuver)
        carMaptemplate.update(routeProgress.currentLegProgress.travelEstimates, for: carSession.trip, with: congestionLevel.asCPTimeRemainingColor)
        
        if routeProgress.currentLegProgress.userHasArrivedAtWaypoint {
            presentArrivalUI()
        }
    }
    
    @objc func rerouted(_ notification: NSNotification) {
        updateManeuvers()
        self.mapView?.recenterMap()
        self.mapView?.showRoutes([routeController.routeProgress.route])
        self.mapView?.showWaypoints(route)
    }
    
    func updateManeuvers() {
        let step = routeController.routeProgress.currentLegProgress.currentStep
        
        let maneuver = CPManeuver()
        let backupText = step.instructionsDisplayedAlongStep?.first?.primaryInstruction.text ?? step.instructions
        
        maneuver.instructionVariants = [backupText]

        // todo get this to work and not crash
        //if let visual = step.instructionsDisplayedAlongStep?.last {
        //    let instructionLabel = InstructionLabel()
        //    instructionLabel.availableBounds = {
        //        return CGRect(x: 0, y: 0, width: 70, height: 30)
        //    }
        //    instructionLabel.instruction = visual.primaryInstruction
        //    if let attributed = instructionLabel.attributedText {
        //        maneuver.attributedInstructionVariants = [attributed]
        //    } else {
        //        maneuver.instructionVariants = [backupText]
        //    }
        //} else {
        //    maneuver.instructionVariants = [backupText]
        //}
        
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


@objc(MBNavigationCarPlayDelegate)
public protocol NavigationCarPlayDelegate {
    @objc(carPlayNavigationViewControllerDidExit:)
    optional func carPlayNavigationViewControllerDidExit(_ carPlayNavigationViewController: CarPlayNavigationViewController)
}
