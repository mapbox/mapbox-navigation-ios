import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps

class CustomViewController: UIViewController {
    
    var destinationAnnotation: PointAnnotation! {
        didSet {
            pointAnnotationManager?.annotations = [destinationAnnotation]
        }
    }
    
    var navigationService: NavigationService!
    
    var simulateLocation = false
    
    var currentLegIndex: Int = 0

    var indexedUserRouteResponse: IndexedRouteResponse?
    
    var stepsViewController: StepsViewController?

    // Preview index of step, this will be nil if we are not previewing an instruction
    var previewStepIndex: Int?
    
    // View that is placed over the instructions banner while we are previewing
    var previewBannerView: InstructionsBannerView?
    
    @IBOutlet var navigationMapView: NavigationMapView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var instructionsBannerView: InstructionsBannerView!
    
    lazy var feedbackViewController: FeedbackViewController = {
        return FeedbackViewController(eventsManager: navigationService.eventsManager)
    }()
    
    var pointAnnotationManager: PointAnnotationManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationMapView.mapView.mapboxMap.style.uri = StyleURI(rawValue: "mapbox://styles/mapbox-map-design/ckd6dqf981hi71iqlyn3e896y")
        navigationMapView.userLocationStyle = .courseView()
        
        let locationManager = simulateLocation ? SimulatedLocationManager(route: indexedUserRouteResponse!.routeResponse.routes!.first!) : NavigationLocationManager()
        navigationService = MapboxNavigationService(indexedRouteResponse: indexedUserRouteResponse!,
                                                    customRoutingProvider: nil,
                                                    credentials: NavigationSettings.shared.directions.credentials,
                                                    locationSource: locationManager,
                                                    simulating: simulateLocation ? .always : .inTunnels)
        
        navigationMapView.mapView.ornaments.options.compass.visibility = .hidden
        
        instructionsBannerView.delegate = self
        instructionsBannerView.swipeable = true

        // Add listeners for progress updates
        resumeNotifications()

        // Start navigation
        navigationService.start()
        
        navigationMapView.mapView.mapboxMap.onNext(event: .styleLoaded, handler: { [weak self] _ in
            guard let self = self else { return }
            // By setting the `NavigationMapView.routeLineTracksTraversal` to `true`, it would allow the main route shown with
            // traversed part disappearing effect in a standalone `NavigationMapView` during active navigation.
            self.navigationMapView.routeLineTracksTraversal = true
            if self.navigationMapView.mapView.mapboxMap.style.layerExists(withId: "road-intersection") {
                // Provide the custom layer position for route line in active navigation.
                self.navigationMapView.show([self.navigationService.route], layerPosition: .below("road-intersection") ,legIndex: 0)
            } else {
                self.navigationMapView.show([self.navigationService.route], legIndex: 0)
            }
        })
        
        // By default `NavigationViewportDataSource` tracks location changes from `PassiveLocationManager`, to consume
        // locations in active guidance navigation `ViewportDataSourceType` should be set to `.active`.
        let navigationViewportDataSource = NavigationViewportDataSource(navigationMapView.mapView, viewportDataSourceType: .active)
        
        // Disable any updates to `CameraOptions.padding` in `NavigationCameraState.following` state
        // to prevent overlapping.
        navigationViewportDataSource.options.followingCameraOptions.paddingUpdatesAllowed = false
        navigationViewportDataSource.followingMobileCamera.padding = UIEdgeInsets(top: 200.0,
                                                                                  left: 10.0,
                                                                                  bottom: 100.0,
                                                                                  right: 10.0)
        
        navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
        
        navigationMapView.mapView.mapboxMap.onNext(event: .styleLoaded) { [weak self] _ in
            guard let self = self else { return }
            self.pointAnnotationManager = self.navigationMapView.mapView.annotations.makePointAnnotationManager()
        }
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
        // Add observers for the route refresh, rerouting and route progress update events to update the main route line
        // when `NavigationMapView.routeLineTracksTraversal` set to `true`.
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_ :)), name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rerouted(_:)), name: .routeControllerDidReroute, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refresh(_:)), name: .routeControllerDidRefreshRoute, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateInstructionsBanner(notification:)), name: .routeControllerDidPassVisualInstructionPoint, object: navigationService.router)
    }

    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidRefreshRoute, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidPassVisualInstructionPoint, object: nil)
    }

    // Notifications sent on all location updates
    @objc func progressDidChange(_ notification: NSNotification) {
        // do not update if we are previewing instruction steps
        guard previewBannerView == nil,
              let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress,
              let location = notification.userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation else { return }
        
        // Add maneuver arrow
        if routeProgress.currentLegProgress.followOnStep != nil {
            navigationMapView.addArrow(route: routeProgress.route, legIndex: routeProgress.legIndex, stepIndex: routeProgress.currentLegProgress.stepIndex + 1)
        } else {
            navigationMapView.removeArrow()
        }
        
        if routeProgress.legIndex != currentLegIndex {
            navigationMapView.showWaypoints(on: routeProgress.route, legIndex: routeProgress.legIndex)
        }
        
        // Update the top banner with progress updates
        instructionsBannerView.updateDistance(for: routeProgress.currentLegProgress.currentStepProgress)
        instructionsBannerView.isHidden = false
        
        // Update `UserCourseView` to be placed on the most recent location.
        navigationMapView.moveUserLocation(to: location, animated: true)
        
        // Update the main route line during active navigation when `NavigationMapView.routeLineTracksTraversal` set to `true`
        // and route progress change, by calling `NavigationMapView.updateRouteLine(routeProgress:coordinate:shouldRedraw:)`
        // without redrawing the main route.
        navigationMapView.updateRouteLine(routeProgress: routeProgress, coordinate: location.coordinate, shouldRedraw: routeProgress.legIndex != currentLegIndex)
        currentLegIndex = routeProgress.legIndex
    }
    
    @objc func updateInstructionsBanner(notification: NSNotification) {
        guard let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress else {
            assertionFailure("RouteProgress should be available.")
            return
        }
        
        instructionsBannerView.update(for: routeProgress.currentLegProgress.currentStepProgress.currentVisualInstruction)
    }

    // Fired when the user is no longer on the route.
    // Update the route on the map.
    @objc func rerouted(_ notification: NSNotification) {
        navigationMapView.removeWaypoints()
        
        // Update the main route line during active navigation when `NavigationMapView.routeLineTracksTraversal` set to `true`
        // and rerouting happens, by calling `NavigationMapView.updateRouteLine(routeProgress:coordinate:shouldRedraw:)`
        // with `shouldRedraw` as `true`.
        navigationMapView.updateRouteLine(routeProgress: navigationService.routeProgress,
                                          coordinate: navigationService.router.location?.coordinate,
                                          shouldRedraw: true)
    }
    
    @objc func refresh(_ notification: NSNotification) {
        // Update the main route line during active navigation when `NavigationMapView.routeLineTracksTraversal` set to `true`
        // and route refresh happens, by calling `NavigationMapView.updateRouteLine(routeProgress:coordinate:shouldRedraw:)`
        // with `shouldRedraw` as `true`.
        navigationMapView.updateRouteLine(routeProgress: navigationService.routeProgress,
                                          coordinate: navigationService.router.location?.coordinate,
                                          shouldRedraw: true)
    }

    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func recenterMap(_ sender: Any) {
        navigationMapView.navigationCamera.follow()
    }
    
    @IBAction func showFeedback(_ sender: Any) {
        present(feedbackViewController, animated: true, completion: nil)
    }
    
    func toggleStepsList() {
        // remove the preview banner while viewing the steps list
        removePreviewInstruction()

        if let controller = stepsViewController {
            controller.dismiss()
            stepsViewController = nil
        } else {
            guard let service = navigationService else { return }
            
            let controller = StepsViewController(routeProgress: service.routeProgress)
            controller.delegate = self
            addChild(controller)
            view.addSubview(controller.view)
            
            controller.view.topAnchor.constraint(equalTo: instructionsBannerView.bottomAnchor).isActive = true
            controller.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            controller.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
            
            controller.didMove(toParent: self)
            view.layoutIfNeeded()
            stepsViewController = controller
            return
        }
    }
    
    func addPreviewInstructions(step: RouteStep) {
        let route = navigationService.route
        // find the leg that contains the step, legIndex, and stepIndex
        guard let leg = route.legs.first(where: { $0.steps.contains(step) }),
              let legIndex = route.legs.firstIndex(of: leg),
              let stepIndex = leg.steps.firstIndex(of: step) else {
            return
        }
        
        // find the upcoming manuever step, and update instructions banner to show preview
        guard stepIndex + 1 < leg.steps.endIndex else { return }
        let maneuverStep = leg.steps[stepIndex + 1]
        updatePreviewBannerWith(step: step, maneuverStep: maneuverStep)
        
        // stop tracking user, and move camera to step location
        navigationMapView.navigationCamera.stop()
        
        if let bearing = maneuverStep.initialHeading {
            let cameraOptions = CameraOptions(center: maneuverStep.maneuverLocation, bearing: bearing)
            navigationMapView.mapView.camera.ease(to: cameraOptions, duration: 1.0)
        }
        
        // add arrow to map for preview instruction
        navigationMapView.addArrow(route: route, legIndex: legIndex, stepIndex: stepIndex + 1)
    }
    
    func updatePreviewBannerWith(step: RouteStep, maneuverStep: RouteStep) {
        // remove preview banner if it exists
        removePreviewInstruction()
        
        // grab the last instruction for step
        guard let instructions = step.instructionsDisplayedAlongStep?.last else { return }
        
        // create a StepInstructionsView and display that over the current instructions banner
        let previewBannerView = InstructionsBannerView(frame: instructionsBannerView.frame)
        previewBannerView.delegate = self
        previewBannerView.swipeable = true
        view.addSubview(previewBannerView)
        
        // update instructions banner to show all information about this step
        previewBannerView.updateDistance(for: RouteStepProgress(step: step))
        previewBannerView.update(for: instructions)
        
        self.previewBannerView = previewBannerView
    }
    
    func removePreviewInstruction() {
        guard let view = previewBannerView else { return }
        view.removeFromSuperview()
        
        // reclaim the delegate, from the preview banner
        instructionsBannerView.delegate = self
        
        // nil out both the view and index
        previewBannerView = nil
        previewStepIndex = nil
    }
}

extension CustomViewController: InstructionsBannerViewDelegate {
    
    func didTapInstructionsBanner(_ sender: BaseInstructionsBannerView) {
        toggleStepsList()
    }
    
    func didSwipeInstructionsBanner(_ sender: BaseInstructionsBannerView, swipeDirection direction: UISwipeGestureRecognizer.Direction) {
        if direction == .down {
            toggleStepsList()
            return
        }
        
        // preventing swiping if the steps list is visible
        guard stepsViewController == nil else { return }
        
        // Make sure that we actually have remaining steps left
        guard let remainingSteps = navigationService?.routeProgress.remainingSteps else { return }
        
        var previewIndex = -1
        var previewStep: RouteStep?
        
        if direction == .left {
            // get the next step from our current preview step index
            if let currentPreviewIndex = previewStepIndex {
                previewIndex = currentPreviewIndex + 1
            } else {
                previewIndex = 0
            }
            
            // index is out of bounds, we have no step to show
            guard previewIndex < remainingSteps.count else { return }
            previewStep = remainingSteps[previewIndex]
        } else {
            // we are already at step 0, no need to show anything
            guard let currentPreviewIndex = previewStepIndex else { return }
            
            if currentPreviewIndex > 0 {
                previewIndex = currentPreviewIndex - 1
                previewStep = remainingSteps[previewIndex]
            } else {
                previewStep = navigationService.routeProgress.currentLegProgress.currentStep
                previewIndex = -1
            }
        }
        
        if let step = previewStep {
            addPreviewInstructions(step: step)
            previewStepIndex = previewIndex
        }
    }
}

extension CustomViewController: StepsViewControllerDelegate {
    
    func didDismissStepsViewController(_ viewController: StepsViewController) {
        viewController.dismiss { [weak self] in
            self?.stepsViewController = nil
        }
    }
    
    func stepsViewController(_ viewController: StepsViewController,
                             didSelect legIndex: Int,
                             stepIndex: Int,
                             cell: StepTableViewCell) {
        viewController.dismiss { [weak self] in
            self?.stepsViewController = nil
        }
    }
}
