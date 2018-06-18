import Foundation
import MapboxDirections
import MapboxCoreNavigation
import CarPlay

public class CarPlayNavigationViewController: UIViewController, MGLMapViewDelegate {
    
    var route: Route
    
    var routeController: RouteController!
    
    var directions: Directions!
    
    var styleManager: StyleManager!
    
    var mapView: NavigationMapView?
    
    let voiceController: MapboxVoiceController
    
    
    var carSession: CPNavigationSession
    var carMaptemplate: CPMapTemplate
    var carFeedbackTemplate: CPGridTemplate!
    var carInterfaceController: CPInterfaceController
    var carFeedbackUIIsShown = false
    
    public init(for route: Route, session: CPNavigationSession, template: CPMapTemplate, interfaceController: CPInterfaceController) {
        self.route = route
        self.carSession = session
        self.carMaptemplate = template
        self.voiceController = MapboxVoiceController()
        self.carInterfaceController = interfaceController
        super.init(nibName: nil, bundle: nil)
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
        
        self.routeController = RouteController(along: route, directions: Directions.shared, locationManager: NavigationLocationManager())
        
        view.addSubview(mapView!)
        
        resumeNotifications()
        routeController.resume()
        mapView?.recenterMap()
    }
    
    func createMapTemplateUI() {
        var recenter: CPMapButton!
        
        let showFeedbackButton = CPMapButton { (button) in
            guard !self.carFeedbackUIIsShown else { return }
            self.carFeedbackUIIsShown = true
            self.carInterfaceController.pushTemplate(self.carFeedbackTemplate, animated: true)
        }
        
        showFeedbackButton.image = UIImage(named: "feedback", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
        
        let overviewButton = CPMapButton { (button) in
            guard let userLocation = self.routeController.location?.coordinate else { return }
            self.mapView?.setOverheadCameraView(from: userLocation, along: self.routeController.routeProgress.route.coordinates!, for: UIEdgeInsets(floatLiteral: 0))
            button.isHidden = true
            recenter.isHidden = false
        }
        
        recenter = CPMapButton { (button) in
            button.isHidden = true
            overviewButton.isHidden = false
            self.mapView?.recenterMap()
        }
        
        recenter.isHidden = true
        recenter.image = UIImage(named: "volume_up", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
        overviewButton.image = UIImage(named: "overview", in: .mapboxNavigation, compatibleWith: nil)!.withRenderingMode(.alwaysTemplate)
        
        let exitButton = CPBarButton(type: .text) { (button) in
            self.dismiss(animated: true, completion: {
                self.carSession.finishTrip()
            })
        }
        
        let muteButton = CPBarButton(type: .text) { (button) in
            if self.voiceController.volume == 0 {
                self.voiceController.volume = 1
                button.title = "Disable Voice"
            } else {
                self.voiceController.volume = 0
                button.title = "Enable Voice"
            }
        }
        muteButton.title = "Disable Voice"
        
        exitButton.title = "Exit"
        
        carMaptemplate.mapButtons = [overviewButton, recenter, showFeedbackButton]
        carMaptemplate.trailingNavigationBarButtons = [exitButton]
        carMaptemplate.leadingNavigationBarButtons = [muteButton]
    }
    
    func createFeedbackUI() -> CPGridTemplate {
        let buttonHandler: (CPGridButton) -> Void = { _ in
            self.carInterfaceController.popTemplate(animated: true)
            self.carFeedbackUIIsShown = false
        }
        let buttons: [CPGridButton] = [
            CPGridButton(titleVariants: [FeedbackItem.closure.title], image: FeedbackItem.closure.image, handler: buttonHandler),
            CPGridButton(titleVariants: [FeedbackItem.turnNotAllowed.title], image: FeedbackItem.turnNotAllowed.image, handler: buttonHandler),
            CPGridButton(titleVariants: [FeedbackItem.reportTraffic.title], image: FeedbackItem.reportTraffic.image, handler: buttonHandler),
            CPGridButton(titleVariants: [FeedbackItem.confusingInstructions.title], image: FeedbackItem.confusingInstructions.image, handler: buttonHandler),
            CPGridButton(titleVariants: [FeedbackItem.badRoute.title], image: FeedbackItem.badRoute.image, handler: buttonHandler),
            CPGridButton(titleVariants: [FeedbackItem.missingRoad.title], image: FeedbackItem.missingRoad.image, handler: buttonHandler),
            CPGridButton(titleVariants: [FeedbackItem.missingExit.title], image: FeedbackItem.missingExit.image, handler: buttonHandler),
            CPGridButton(titleVariants: [FeedbackItem.generalMapError.title], image: FeedbackItem.generalMapError.image, handler: buttonHandler)
        ]
        
        return CPGridTemplate(title: "Feedback", gridButtons: buttons)
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_:)), name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rerouted(_:)), name: .routeControllerDidReroute, object: nil)
    }
    
    
    public func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        self.mapView?.showRoutes([routeController.routeProgress.route])
        self.mapView?.recenterMap()
    }
    
    @objc func progressDidChange(_ notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as! RouteProgress
        let location = notification.userInfo![RouteControllerNotificationUserInfoKey.locationKey] as! CLLocation
        
        // Add maneuver arrow
        if routeProgress.currentLegProgress.followOnStep != nil {
            mapView?.addArrow(route: routeProgress.route, legIndex: routeProgress.legIndex, stepIndex: routeProgress.currentLegProgress.stepIndex + 1)
        } else {
            mapView?.removeArrow()
        }
        
        // Update the user puck
        mapView?.updateCourseTracking(location: location, animated: true)
        
        if carSession.upcomingManeuvers.isEmpty {
            updateManeuvers()
        }
    
        let distanceRemaining = Measurement(value: routeProgress.currentLegProgress.currentStepProgress.distanceRemaining, unit: UnitLength.meters)
        let estimates = CPTravelEstimates(distanceRemaining: distanceRemaining, timeRemaining: routeProgress.currentLegProgress.currentStepProgress.durationRemaining)
        
        carSession.updateEstimates(estimates, for: carSession.upcomingManeuvers[routeController.routeProgress.currentLegProgress.stepIndex])
        
        if routeProgress.currentLegProgress.userHasArrivedAtWaypoint {
            presentArrivalUI()
        }
    }
    
    func presentArrivalUI() {
        let action = CPAlertAction(title: "You Have Arrived", style: .default, handler: {_ in
            self.dismiss(animated: true, completion: nil)
        })
        let alert = CPNavigationAlert(titleVariants: ["Exit"], subtitleVariants: nil, image: nil, priority: .high, primaryAction: action, secondaryAction: nil, duration: 0)
        carMaptemplate.present(navigationAlert: alert, animated: true)
    }
    
    func updateManeuvers() {
        let index = routeController.routeProgress.currentLegProgress.stepIndex
        let maneuvers = routeController.routeProgress.currentLeg.steps.suffix(from: index).map { (step) -> CPManeuver in
            let maneuver = CPManeuver()
            let visual = step.instructionsDisplayedAlongStep?.first?.primaryInstruction.text ?? step.instructions
            maneuver.instructionVariants = [visual]
            
            let distanceRemaining = Measurement(value: step.distance, unit: UnitLength.meters)
            maneuver.distanceFromPreviousManeuver = distanceRemaining
            
            if let visual = step.instructionsDisplayedAlongStep?.first {
                let mv = ManeuverView()
                mv.frame = CGRect(x: 0, y: 0, width: 38, height: 38)
                mv.primaryColor = .white
                mv.backgroundColor = .clear
                mv.visualInstruction = visual
                let imageView = mv.imageRepresentation
                maneuver.symbol = imageView
            }
            return maneuver
        }
        carSession.upcomingManeuvers = maneuvers
    }
    
    @objc func rerouted(_ notification: NSNotification) {
        updateManeuvers()
        self.mapView?.recenterMap()
        self.mapView?.showRoutes([routeController.routeProgress.route])
    }
}
