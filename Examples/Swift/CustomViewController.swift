import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import Mapbox
import CoreLocation
import AVFoundation
import MapboxDirections
import Turf

class CustomViewController: UIViewController, MGLMapViewDelegate {

    var destination: MGLPointAnnotation!
    let directions = Directions.shared
    var navigationService: NavigationService!
    var simulateLocation = false

    var userRoute: Route?

    // Start voice instructions
    let voiceController = MapboxVoiceController()
    
    var stepsViewController: StepsViewController?

    @IBOutlet var mapView: NavigationMapView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var instructionsBannerView: InstructionsBannerView!
    
    lazy var feedbackViewController: FeedbackViewController = {
        return FeedbackViewController(eventsManager: navigationService.eventsManager)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let locationManager = simulateLocation ? SimulatedLocationManager(route: userRoute!) : NavigationLocationManager()
        navigationService = MapboxNavigationService(route: userRoute!, locationSource: locationManager)

        
        mapView.delegate = self
        mapView.compassView.isHidden = true
        
        instructionsBannerView.delegate = self

        // Add listeners for progress updates
        resumeNotifications()

        // Start navigation
        navigationService.start()
        
        // Center map on user
        mapView.recenterMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // This applies a default style to the top banner.
        DayStyle().apply()
    }

    deinit {
        suspendNotifications()
    }

    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_ :)), name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rerouted(_:)), name: .routeControllerDidReroute, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateInstructionsBanner(notification:)), name: .routeControllerDidPassVisualInstructionPoint, object: navigationService.router)
    }

    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerWillReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidPassVisualInstructionPoint, object: nil)
    }

    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        self.mapView.showRoutes([navigationService.route])
    }

    // Notifications sent on all location updates
    @objc func progressDidChange(_ notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as! RouteProgress
        let location = notification.userInfo![RouteControllerNotificationUserInfoKey.locationKey] as! CLLocation
        
        // Add maneuver arrow
        if routeProgress.currentLegProgress.followOnStep != nil {
            mapView.addArrow(route: routeProgress.route, legIndex: routeProgress.legIndex, stepIndex: routeProgress.currentLegProgress.stepIndex + 1)
        } else {
            mapView.removeArrow()
        }
        
        // Update the top banner with progress updates
        instructionsBannerView.updateDistance(for: routeProgress.currentLegProgress.currentStepProgress)
        instructionsBannerView.isHidden = false
        
        // Update the user puck
        mapView.updateCourseTracking(location: location, animated: true)
    }
    
    @objc func updateInstructionsBanner(notification: NSNotification) {
        guard let routeProgress = notification.userInfo?[RouteControllerNotificationUserInfoKey.routeProgressKey] as? RouteProgress else { return }
        instructionsBannerView.update(for: routeProgress.currentLegProgress.currentStepProgress.currentVisualInstruction)
    }

    // Fired when the user is no longer on the route.
    // Update the route on the map.
    @objc func rerouted(_ notification: NSNotification) {
        self.mapView.showRoutes([navigationService.route])
    }

    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func recenterMap(_ sender: Any) {
        mapView.recenterMap()
    }
    
    @IBAction func showFeedback(_ sender: Any) {
        present(feedbackViewController, animated: true, completion: nil)
    }
    
    func toggleStepsList() {
        if let controller = stepsViewController {
            controller.dismiss()
            stepsViewController = nil
        } else {
            guard let service = navigationService else { return }
            
            let controller = StepsViewController(routeProgress: service.routeProgress)
            controller.delegate = self
            addChildViewController(controller)
            view.addSubview(controller.view)
            
            controller.view.topAnchor.constraint(equalTo: instructionsBannerView.bottomAnchor).isActive = true
            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            
            controller.didMove(toParentViewController: self)
            controller.dropDownAnimation()
            
            stepsViewController = controller
            return
        }
    }
}

extension CustomViewController: InstructionsBannerViewDelegate {
    func didTapInstructionsBanner(_ sender: BaseInstructionsBannerView) {
        toggleStepsList()
    }
    
    func didDragInstructionsBanner(_ sender: BaseInstructionsBannerView) {
        toggleStepsList()
    }
}

extension CustomViewController: StepsViewControllerDelegate {
    func didDismissStepsViewController(_ viewController: StepsViewController) {
        viewController.dismiss { [weak self] in
            self?.stepsViewController = nil
        }
    }
    
    func stepsViewController(_ viewController: StepsViewController, didSelect legIndex: Int, stepIndex: Int, cell: StepTableViewCell) {
        viewController.dismiss { [weak self] in
            self?.stepsViewController = nil
        }
    }
}
