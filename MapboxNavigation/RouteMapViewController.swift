import UIKit
import Mapbox
import MapboxDirections
import MapboxCoreNavigation
import Turf

class ArrowFillPolyline: MGLPolylineFeature {}
class ArrowStrokePolyline: ArrowFillPolyline {}


class RouteMapViewController: UIViewController {
    @IBOutlet weak var mapView: NavigationMapView!
    @IBOutlet weak var overviewButton: Button!
    @IBOutlet weak var reportButton: Button!
    @IBOutlet weak var rerouteReportButton: ReportButton!
    @IBOutlet weak var recenterButton: ResumeButton!
    @IBOutlet weak var muteButton: Button!
    @IBOutlet weak var wayNameLabel: WayNameLabel!
    @IBOutlet weak var wayNameView: UIView!
    @IBOutlet weak var instructionsBannerContainerView: InstructionsBannerContentView!
    @IBOutlet weak var instructionsBannerView: InstructionsBannerView!
    @IBOutlet weak var nextBannerView: NextBannerView!
    @IBOutlet weak var bottomBannerView: BottomBannerView!
    @IBOutlet weak var statusView: StatusView!
    @IBOutlet weak var laneViewsContainerView: LanesContainerView!
    @IBOutlet weak var rerouteFeedbackTopConstraint: NSLayoutConstraint!
    
    let visualInstructionFormatter = VisualInstructionFormatter()

    var route: Route { return routeController.routeProgress.route }
    var previousStep: RouteStep?
    var updateETATimer: Timer?
    var previewInstructionsView: StepInstructionsView?
    var lastTimeUserRerouted: Date?
    var stepsViewController: StepsViewController?

    var pendingCamera: MGLMapCamera? {
        guard let parent = parent as? NavigationViewController else {
            return nil
        }
        return parent.pendingCamera
    }
    var tiltedCamera: MGLMapCamera {
        get {
            let camera = mapView.camera
            camera.altitude = 1000
            camera.pitch = 45
            return camera
        }
    }
    
    weak var delegate: RouteMapViewControllerDelegate? {
        didSet {
            mapView.delegate = mapView.delegate
        }
    }
    weak var routeController: RouteController!
    let distanceFormatter = DistanceFormatter(approximate: true)
    var arrowCurrentStep: RouteStep?
    var isInOverviewMode = false {
        didSet {
            if isInOverviewMode {
                overviewButton.isHidden = true
                recenterButton.isHidden = false
                wayNameView.isHidden = true
                mapView.logoView.isHidden = true
            } else {
                overviewButton.isHidden = false
                recenterButton.isHidden = true
                mapView.logoView.isHidden = false
            }
        }
    }
    var currentLegIndexMapped = 0
    
    /**
     A Boolean value that determines whether the map annotates the locations at which instructions are spoken for debugging purposes.
     */
    var annotatesSpokenInstructions = false

    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        
        distanceFormatter.numberFormatter.locale = .nationalizedCurrent
        
        mapView.tracksUserCourse = true
        mapView.delegate = self
        mapView.navigationMapDelegate = self
        mapView.courseTrackingDelegate = self
        mapView.contentInset = contentInsets
        
        rerouteReportButton.slideUp(constraint: rerouteFeedbackTopConstraint)
        rerouteReportButton.applyDefaultCornerRadiusShadow(cornerRadius: 4)
        overviewButton.applyDefaultCornerRadiusShadow(cornerRadius: overviewButton.bounds.midX)
        reportButton.applyDefaultCornerRadiusShadow(cornerRadius: reportButton.bounds.midX)
        muteButton.applyDefaultCornerRadiusShadow(cornerRadius: muteButton.bounds.midX)
        
        wayNameView.layer.borderWidth = 1.0 / UIScreen.main.scale
        wayNameView.applyDefaultCornerRadiusShadow()
        laneViewsContainerView.isHidden = true
        statusView.isHidden = true
        nextBannerView.isHidden = true
        isInOverviewMode = false
        instructionsBannerView.delegate = self
        bottomBannerView.delegate = self
        
        resumeNotifications()
    }
    
    deinit {
        suspendNotifications()
        removeTimer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        resetETATimer()
        
        muteButton.isSelected = NavigationSettings.shared.muted
        mapView.compassView.isHidden = true
        
        mapView.tracksUserCourse = true
        mapView.enableFrameByFrameCourseViewTracking(for: 3)

        if let camera = pendingCamera {
            mapView.camera = camera
        } else if let location = routeController.location, location.course > 0 {
            mapView.updateCourseTracking(location: location, animated: false)
        } else if let coordinates = routeController.routeProgress.currentLegProgress.currentStep.coordinates, let firstCoordinate = coordinates.first, coordinates.count > 1 {
            let secondCoordinate = coordinates[1]
            let course = firstCoordinate.direction(to: secondCoordinate)
            let newLocation = CLLocation(coordinate: routeController.location?.coordinate ?? firstCoordinate, altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: course, speed: 0, timestamp: Date())
            mapView.updateCourseTracking(location: newLocation, animated: false)
        } else {
            mapView.setCamera(tiltedCamera, animated: false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showRouteIfNeeded()
        currentLegIndexMapped = routeController.routeProgress.legIndex
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeTimer()
    }

    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(willReroute(notification:)), name: RouteControllerWillReroute, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReroute(notification:)), name: RouteControllerDidReroute, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground(notification:)), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(removeTimer), name: .UIApplicationDidEnterBackground, object: nil)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: RouteControllerWillReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: RouteControllerDidReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationDidEnterBackground, object: nil)
    }

    @IBAction func recenter(_ sender: AnyObject) {
        mapView.tracksUserCourse = true
        mapView.enableFrameByFrameCourseViewTracking(for: 3)
        isInOverviewMode = false
        updateCameraAltitude(for: routeController.routeProgress)
        
        mapView.addArrow(route: routeController.routeProgress.route,
                         legIndex: routeController.routeProgress.legIndex,
                         stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
        
        removePreviewInstructions()
    }
    
    @objc func removeTimer() {
        updateETATimer?.invalidate()
        updateETATimer = nil
    }
    
    func removePreviewInstructions() {
        if let view = previewInstructionsView {
            view.removeFromSuperview()
            instructionsBannerContainerView.backgroundColor = InstructionsBannerView.appearance().backgroundColor
            previewInstructionsView = nil
        }
    }

    @IBAction func toggleOverview(_ sender: Any) {
        mapView.enableFrameByFrameCourseViewTracking(for: 3)
        updateVisibleBounds()
        isInOverviewMode = true
    }
    
    @IBAction func toggleMute(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected

        let muted = sender.isSelected
        NavigationSettings.shared.muted = muted
    }
    
    @IBAction func rerouteFeedback(_ sender: Any) {
        showFeedback(source: .reroute)
        rerouteReportButton.slideUp(constraint: rerouteFeedbackTopConstraint)
        delegate?.mapViewControllerDidOpenFeedback(self)
    }
    
    @IBAction func feedback(_ sender: Any) {
        showFeedback()
        delegate?.mapViewControllerDidOpenFeedback(self)
    }
    
    func showFeedback(source: FeedbackSource = .user) {
        guard let parent = parent else { return }
    
        let controller = FeedbackViewController.loadFromStoryboard()
        let sections: [FeedbackSection] = [[.turnNotAllowed, .closure, .reportTraffic], [.confusingInstructions, .generalMapError, .badRoute]]
        controller.sections = sections
        let feedbackId = routeController.recordFeedback()
        
        controller.sendFeedbackHandler = { [weak self] (item) in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.mapViewController(strongSelf, didSend: feedbackId, feedbackType: item.feedbackType)
            strongSelf.routeController.updateFeedback(feedbackId: feedbackId, type: item.feedbackType, source: source, description: nil)
            strongSelf.dismiss(animated: true) {
                DialogViewController.present(on: parent)
            }
        }
        
        controller.dismissFeedbackHandler = { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.mapViewControllerDidCancelFeedback(strongSelf)
            strongSelf.routeController.cancelFeedback(feedbackId: feedbackId)
            strongSelf.dismiss(animated: true, completion: nil)
        }
        
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = controller
        parent.present(controller, animated: true, completion: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        mapView.enableFrameByFrameCourseViewTracking(for: 3)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapView.setContentInset(contentInsets, animated: true)
        mapView.setNeedsUpdateConstraints()
    }
    
    func updateVisibleBounds() {
        guard let userLocation = routeController.locationManager.location?.coordinate else { return }
        
        let overviewContentInset = UIEdgeInsets(top: instructionsBannerView.bounds.height, left: 20, bottom: bottomBannerView.bounds.height, right: 20)
        let slicedLine = Polyline(routeController.routeProgress.route.coordinates!).sliced(from: userLocation, to: routeController.routeProgress.route.coordinates!.last).coordinates
        let line = MGLPolyline(coordinates: slicedLine, count: UInt(slicedLine.count))
        
        mapView.tracksUserCourse = false
        let camera = mapView.camera
        camera.pitch = 0
        camera.heading = 0
        mapView.camera = camera
        
        // Don't keep zooming in
        guard line.overlayBounds.ne.distance(to: line.overlayBounds.sw) > 200 else { return }
        
        mapView.setVisibleCoordinateBounds(line.overlayBounds, edgePadding: overviewContentInset, animated: true)
    }

    func notifyDidReroute(route: Route) {
        updateETA()
        
        if let location = routeController.location {
            updateInstructions(routeProgress: routeController.routeProgress, location: location, secondsRemaining: 0)
        }
        
        mapView.addArrow(route: routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex, stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
        mapView.showRoutes([routeController.routeProgress.route], legIndex: routeController.routeProgress.legIndex)
        
        if annotatesSpokenInstructions {
            mapView.showVoiceInstructionsOnMap(route: routeController.routeProgress.route)
        }

        if isInOverviewMode {
            updateVisibleBounds()
        } else {
            mapView.tracksUserCourse = true
            wayNameView.isHidden = true
        }
        
        stepsViewController?.dismiss {
            self.removePreviewInstructions()
            self.stepsViewController = nil
        }
    }
    
    @objc func applicationWillEnterForeground(notification: NSNotification) {
        mapView.updateCourseTracking(location: routeController.location, animated: false)
        resetETATimer()
    }
    
    @objc func willReroute(notification: NSNotification) {
        let title = NSLocalizedString("REROUTING", bundle: .mapboxNavigation, value: "Rerouting…", comment: "Indicates that rerouting is in progress")
        hideLaneViews()
        statusView.show(title, showSpinner: true)
        statusView.hide(delay: 3, animated: true)
    }
    
    @objc func didReroute(notification: NSNotification) {
        if !(routeController.locationManager is SimulatedLocationManager) {
            statusView.hide(delay: 0.5, animated: true)
            
            if !reportButton.isHidden {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
                    self.rerouteReportButton.slideDown(constraint: self.rerouteFeedbackTopConstraint, interval: 5)
                })
            }
        }
        
        if notification.userInfo![RouteControllerDidFindFasterRouteKey] as! Bool {
            let title = NSLocalizedString("FASTER_ROUTE_FOUND", bundle: .mapboxNavigation, value: "Faster Route Found", comment: "Indicates a faster route was found")
            statusView.show(title, showSpinner: true)
            statusView.hide(delay: 5, animated: true)
        }
    }

    func updateMapOverlays(for routeProgress: RouteProgress) {
        if routeProgress.currentLegProgress.followOnStep != nil {
            mapView.addArrow(route: routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex, stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
        } else {
            mapView.removeArrow()
        }
    }

    func updateCameraAltitude(for routeProgress: RouteProgress) {
        guard mapView.tracksUserCourse else { return } //only adjust when we are actively tracking user course
        
        let zoomOutAltitude = NavigationMapView.zoomedOutMotorwayAltitude
        let defaultAltitude = NavigationMapView.defaultAltitude
        let isLongRoad = routeProgress.distanceRemaining >= NavigationMapView.longManeuverDistance
        let currentStep = routeProgress.currentLegProgress.currentStep
        let upComingStep = routeProgress.currentLegProgress.upComingStep
        
        //If the user is at the last turn maneuver, the map should zoom in to the default altitude.
        let currentInstruction = routeProgress.currentLegProgress.currentStepProgress.currentSpokenInstruction
        
        
        //If the user is on a motorway, not exiting, and their segment is sufficently long, the map should zoom out to the motorway altitude.
        //otherwise, zoom in if it's the last instruction on the step.
        let currentStepIsMotorway = currentStep.isMotorway
        let nextStepIsMotorway = upComingStep?.isMotorway ?? false
        if currentStepIsMotorway, nextStepIsMotorway, isLongRoad {
            setCamera(altitude: zoomOutAltitude)
        } else if currentInstruction == currentStep.lastInstruction {
            setCamera(altitude: defaultAltitude)
        }
    }
    
    private func setCamera(altitude: Double) {
        guard mapView.altitude != altitude else { return }
        mapView.altitude = altitude
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        return navigationMapView(mapView, imageFor: annotation)
    }
    
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return navigationMapView(mapView, viewFor: annotation)
    }

    func notifyDidChange(routeProgress: RouteProgress, location: CLLocation, secondsRemaining: TimeInterval) {
        resetETATimer()
        
        updateETA()
        
        let step = routeProgress.currentLegProgress.upComingStep ?? routeProgress.currentLegProgress.currentStep
        
        if let upComingStep = routeProgress.currentLegProgress?.upComingStep, !routeProgress.currentLegProgress.userHasArrivedAtWaypoint {
            updateLaneViews(step: upComingStep, durationRemaining: routeProgress.currentLegProgress.currentStepProgress.durationRemaining)
        }
        
        previousStep = step
        updateInstructions(routeProgress: routeProgress, location: location, secondsRemaining: secondsRemaining)
        updateNextBanner(routeProgress: routeProgress)
        
        if currentLegIndexMapped != routeProgress.legIndex {
            mapView.showWaypoints(routeProgress.route, legIndex: routeProgress.legIndex)
            mapView.showRoutes([routeProgress.route], legIndex: routeProgress.legIndex)
            
            currentLegIndexMapped = routeProgress.legIndex
        }
        
        if annotatesSpokenInstructions {
            mapView.showVoiceInstructionsOnMap(route: routeController.routeProgress.route)
        }

        guard isInOverviewMode else {
            return
        }

        updateVisibleBounds()
    }
    
    func updateInstructions(routeProgress: RouteProgress, location: CLLocation, secondsRemaining: TimeInterval) {
        let stepProgress = routeProgress.currentLegProgress.currentStepProgress
        let distanceRemaining = stepProgress.distanceRemaining
        let step = routeProgress.currentLegProgress.upComingStep ?? routeProgress.currentLegProgress.currentStep
        let instructions = visualInstructionFormatter.instructions(leg: routeProgress.currentLeg, step: step)
        
        instructionsBannerView.set(instructions.0, secondaryInstruction: instructions.1)
        instructionsBannerView.distance = distanceRemaining > 5 ? distanceRemaining : 0
        instructionsBannerView.maneuverView.step = routeProgress.currentLegProgress.upComingStep
    }
    
    func updateNextBanner(routeProgress: RouteProgress) {
    
        guard let upcomingStep = routeProgress.currentLegProgress.upComingStep,
            let nextStep = routeProgress.currentLegProgress.stepAfter(upcomingStep),
            laneViewsContainerView.isHidden
            else {
                hideNextBanner()
                return
        }
    
        // If the followon step is short and the user is near the end of the current step, show the nextBanner.
        guard nextStep.expectedTravelTime <= RouteControllerHighAlertInterval * RouteControllerLinkedInstructionBufferMultiplier,
            routeProgress.currentLegProgress.durationRemaining <= RouteControllerHighAlertInterval * RouteControllerLinkedInstructionBufferMultiplier else {
            hideNextBanner()
            return
        }

        let instructions = visualInstructionFormatter.instructions(leg: routeProgress.currentLeg, step: nextStep)
        let instruction = instructions.0
        
        guard let components = instruction?.components, var firstComponent = components.first else {
            hideNextBanner()
            return
        }
        
        firstComponent.prefix = NSLocalizedString("THEN", bundle: .mapboxNavigation, value: "Then: ", comment: "Then")
        nextBannerView.maneuverView.step = nextStep
        nextBannerView.instructionLabel.instruction = instruction
        showNextBanner()
    }
    
    func showNextBanner() {
        guard nextBannerView.isHidden else { return }
        UIView.defaultAnimation(0.3, animations: {
            self.nextBannerView.isHidden = false
        }, completion: nil)
    }
    
    func hideNextBanner() {
        guard !nextBannerView.isHidden else { return }
        UIView.defaultAnimation(0.3, animations: {
            self.nextBannerView.isHidden = true
        }, completion: nil)
    }
    
    var contentInsets: UIEdgeInsets {
        return UIEdgeInsets(top: instructionsBannerContainerView.bounds.height, left: 0, bottom: bottomBannerView.bounds.height, right: 0)
    }
    
    func updateLaneViews(step: RouteStep, durationRemaining: TimeInterval) {
        laneViewsContainerView.updateLaneViews(step: step, durationRemaining: durationRemaining)
        
        if laneViewsContainerView.stackView.arrangedSubviews.count > 0 {
            showLaneViews()
        } else {
            hideLaneViews()
        }
    }
    
    func showLaneViews(animated: Bool = true) {
        hideNextBanner()
        guard laneViewsContainerView.isHidden == true else { return }
        if animated {
            UIView.defaultAnimation(0.3, animations: {
                self.laneViewsContainerView.isHidden = false
            }, completion: nil)
        } else {
            self.laneViewsContainerView.isHidden = false
        }
    }
    
    func hideLaneViews() {
        guard laneViewsContainerView.isHidden == false else { return }
        UIView.defaultAnimation(0.3, animations: {
            self.laneViewsContainerView.isHidden = true
        }, completion: nil)
    }
}

// MARK: NavigationMapViewCourseTrackingDelegate

extension RouteMapViewController: NavigationMapViewCourseTrackingDelegate {
    func navigationMapViewDidStartTrackingCourse(_ mapView: NavigationMapView) {
        recenterButton.isHidden = true
        mapView.logoView.isHidden = false
    }
    
    func navigationMapViewDidStopTrackingCourse(_ mapView: NavigationMapView) {
        recenterButton.isHidden = false
        mapView.logoView.isHidden = true
    }
}

// MARK: NavigationMapViewDelegate

extension RouteMapViewController: NavigationMapViewDelegate {
    
    func navigationMapView(_ mapView: NavigationMapView, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationMapView(mapView, routeStyleLayerWithIdentifier: identifier, source: source)
    }

    func navigationMapView(_ mapView: NavigationMapView, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationMapView(mapView, routeCasingStyleLayerWithIdentifier: identifier, source: source)
    }

    func navigationMapView(_ mapView: NavigationMapView, waypointStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationMapView(mapView, waypointStyleLayerWithIdentifier: identifier, source: source)
    }
    
    func navigationMapView(_ mapView: NavigationMapView, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationMapView(mapView, waypointSymbolStyleLayerWithIdentifier: identifier, source: source)
    }
    
    func navigationMapView(_ mapView: NavigationMapView, shapeFor waypoints: [Waypoint]) -> MGLShape? {
        return delegate?.navigationMapView(mapView, shapeFor: waypoints)
    }

    func navigationMapView(_ mapView: NavigationMapView, shapeDescribing route: Route) -> MGLShape? {
        return delegate?.navigationMapView(mapView, shapeDescribing: route)
    }
    
    func navigationMapView(_ mapView: NavigationMapView, didTap: Route) {
        delegate?.navigationMapView(mapView, didTap: route)
    }

    func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeDescribing route: Route) -> MGLShape? {
        return delegate?.navigationMapView(mapView, simplifiedShapeDescribing: route)
    }
    
    func navigationMapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        return delegate?.navigationMapView(mapView, imageFor :annotation)
    }
    
    func navigationMapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return delegate?.navigationMapView(mapView, viewFor: annotation)
    }
    
    func navigationMapViewUserAnchorPoint(_ mapView: NavigationMapView) -> CGPoint {
        return delegate?.mapViewController(self, mapViewUserAnchorPoint: mapView) ?? .zero
    }
    
    /**
     Updates the current road name label to reflect the road on which the user is currently traveling.
     
     - parameter location: The user’s current location.
     */
    func labelCurrentRoad(at location: CLLocation) {
        guard let style = mapView.style,
            let stepCoordinates = routeController.routeProgress.currentLegProgress.currentStep.coordinates,
            recenterButton.isHidden else {
            return
        }
        
        let closestCoordinate = location.coordinate
        let roadLabelLayerIdentifier = "roadLabelLayer"
        var streetsSources = style.sources.flatMap {
            $0 as? MGLVectorSource
            }.filter {
                $0.isMapboxStreets
        }
        
        // Add Mapbox Streets if the map does not already have it
        if streetsSources.isEmpty {
            let source = MGLVectorSource(identifier: "mapboxStreetsv7", configurationURL: URL(string: "mapbox://mapbox.mapbox-streets-v7")!)
            style.addSource(source)
            streetsSources.append(source)
        }
        
        if let mapboxSteetsSource = streetsSources.first, style.layer(withIdentifier: roadLabelLayerIdentifier) == nil {
            let streetLabelLayer = MGLLineStyleLayer(identifier: roadLabelLayerIdentifier, source: mapboxSteetsSource)
            streetLabelLayer.sourceLayerIdentifier = "road_label"
            streetLabelLayer.lineOpacity = MGLStyleValue(rawValue: 1)
            streetLabelLayer.lineWidth = MGLStyleValue(rawValue: 20)
            streetLabelLayer.lineColor = MGLStyleValue(rawValue: .white)
            style.insertLayer(streetLabelLayer, at: 0)
        }
        
        let userPuck = mapView.convert(closestCoordinate, toPointTo: mapView)
        let features = mapView.visibleFeatures(at: userPuck, styleLayerIdentifiers: Set([roadLabelLayerIdentifier]))
        var smallestLabelDistance = Double.infinity
        var currentName: String?
        
        for feature in features {
            var allLines: [MGLPolyline] = []
            
            if let line = feature as? MGLPolylineFeature {
                allLines.append(line)
            } else if let lines = feature as? MGLMultiPolylineFeature {
                allLines = lines.polylines
            }
            
            for line in allLines {
                let featureCoordinates =  Array(UnsafeBufferPointer(start: line.coordinates, count: Int(line.pointCount)))
                let featurePolyline = Polyline(featureCoordinates)
                let slicedLine = Polyline(stepCoordinates).sliced(from: closestCoordinate)
                
                let lookAheadDistance:CLLocationDistance = 10
                guard let pointAheadFeature = featurePolyline.sliced(from: closestCoordinate).coordinateFromStart(distance: lookAheadDistance) else { continue }
                guard let pointAheadUser = slicedLine.coordinateFromStart(distance: lookAheadDistance) else { continue }
                guard let reversedPoint = Polyline(featureCoordinates.reversed()).sliced(from: closestCoordinate).coordinateFromStart(distance: lookAheadDistance) else { continue }
                
                let distanceBetweenPointsAhead = pointAheadFeature.distance(to: pointAheadUser)
                let distanceBetweenReversedPoint = reversedPoint.distance(to: pointAheadUser)
                let minDistanceBetweenPoints = min(distanceBetweenPointsAhead, distanceBetweenReversedPoint)
                
                if minDistanceBetweenPoints < smallestLabelDistance {
                    smallestLabelDistance = minDistanceBetweenPoints
                    
                    if let line = feature as? MGLPolylineFeature, let name = line.attribute(forKey: "name") as? String {
                        currentName = name
                    } else if let line = feature as? MGLMultiPolylineFeature, let name = line.attribute(forKey: "name") as? String {
                        currentName = name
                    } else {
                        currentName = nil
                    }
                }
            }
        }
        
        if smallestLabelDistance < 5 && currentName != nil {
            wayNameLabel.text = currentName
            wayNameView.isHidden = false
        } else {
            wayNameView.isHidden = true
        }
    }
    
    @objc func updateETA() {
        bottomBannerView.updateETA(routeProgress: routeController.routeProgress)
    }
    
    func resetETATimer() {
        updateETATimer?.invalidate()
        updateETATimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(updateETA), userInfo: nil, repeats: true)
    }
}

// MARK: MGLMapViewDelegate

extension RouteMapViewController: MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        var userTrackingMode = mapView.userTrackingMode
        if let mapView = mapView as? NavigationMapView, mapView.tracksUserCourse {
            userTrackingMode = .followWithCourse
        }
        if userTrackingMode == .none && !isInOverviewMode {
            wayNameView.isHidden = true
        }
    }

    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        style.setImage(Bundle.mapboxNavigation.image(named: "triangle")!.withRenderingMode(.alwaysTemplate), forName: "triangle-tip-navigation")
        // This method is called before the view is added to a window
        // (if the style is cached) preventing UIAppearance to apply the style.
        showRouteIfNeeded()
    }
    
    func showRouteIfNeeded() {
        guard isViewLoaded && view.window != nil else { return }
        let map = mapView as NavigationMapView
        guard !map.showsRoute else { return }
        map.showRoutes([routeController.routeProgress.route], legIndex: routeController.routeProgress.legIndex)
        map.showWaypoints(routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex)
        
        if routeController.routeProgress.currentLegProgress.stepIndex + 1 <= routeController.routeProgress.currentLegProgress.leg.steps.count {
            map.addArrow(route: routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex, stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
        }
        
        if annotatesSpokenInstructions {
            mapView.showVoiceInstructionsOnMap(route: routeController.routeProgress.route)
        }
    }
}

// MARK: InstructionsBannerViewDelegate

extension RouteMapViewController: InstructionsBannerViewDelegate {
    func didTapInstructionsBanner(_ sender: BaseInstructionsBannerView) {
        
        removePreviewInstructions()
        
        guard let controller = stepsViewController else {
            let controller = StepsViewController(routeProgress: routeController.routeProgress)
            controller.delegate = self
            addChildViewController(controller)
            view.insertSubview(controller.view, belowSubview: instructionsBannerContainerView)
            
            controller.view.topAnchor.constraint(equalTo: instructionsBannerView.bottomAnchor).isActive = true
            controller.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            controller.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
            
            controller.didMove(toParentViewController: self)
            controller.dropDownAnimation()
            
            stepsViewController = controller
            return
        }
        
        stepsViewController = nil
        controller.dismiss {}
    }
}

// MARK: StepsViewControllerDelegate

extension RouteMapViewController: StepsViewControllerDelegate {
    
    func stepsViewController(_ viewController: StepsViewController, didSelect step: RouteStep, cell: StepTableViewCell) {
        viewController.dismiss {
            self.addPreviewInstructions(step: step, distance: cell.instructionsView.distance)
            self.stepsViewController = nil
        }
        
        mapView.enableFrameByFrameCourseViewTracking(for: 1)
        mapView.tracksUserCourse = false
        mapView.setCenter(step.maneuverLocation, zoomLevel: mapView.zoomLevel, direction: step.initialHeading!, animated: true, completionHandler: nil)
        
        guard isViewLoaded && view.window != nil else { return }
        if let legIndex = routeController.routeProgress.route.legs.index(where: { !$0.steps.filter { $0 == step }.isEmpty }) {
            let leg = routeController.routeProgress.route.legs[legIndex]
            if let stepIndex = leg.steps.index(where: { $0 == step }), leg.steps.last != step {
                mapView.addArrow(route: routeController.routeProgress.route, legIndex: legIndex, stepIndex: stepIndex)
            }
        }
    }
    
    func addPreviewInstructions(step: RouteStep, distance: CLLocationDistance?) {
        removePreviewInstructions()
        
        let instructions = visualInstructionFormatter.instructions(leg: nil, step: step)
        let instructionsView = StepInstructionsView(frame: instructionsBannerView.frame)
        instructionsView.backgroundColor = StepInstructionsView.appearance().backgroundColor
        instructionsView.delegate = self
        instructionsView.set(instructions.0, secondaryInstruction: instructions.1)
        instructionsView.maneuverView.step = step
        instructionsView.distance = distance
        
        instructionsBannerContainerView.backgroundColor = instructionsView.backgroundColor
        
        view.addSubview(instructionsView)
        previewInstructionsView = instructionsView
    }
    
    func didDismissStepsViewController(_ viewController: StepsViewController) {
        viewController.dismiss {
            self.stepsViewController = nil
        }
    }
}

// MARK: BottomBannerViewDelegate

extension RouteMapViewController: BottomBannerViewDelegate {
    func didCancel() {
        delegate?.mapViewControllerDidCancelNavigation(self)
    }
}

protocol RouteMapViewControllerDelegate: class {
    func navigationMapView(_ mapView: NavigationMapView, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    func navigationMapView(_ mapView: NavigationMapView, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    func navigationMapView(_ mapView: NavigationMapView, shapeDescribing route: Route) -> MGLShape?
    func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeDescribing route: Route) -> MGLShape?
    func navigationMapView(_ mapView: NavigationMapView, waypointStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    func navigationMapView(_ mapView: NavigationMapView, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    func navigationMapView(_ mapView: NavigationMapView, didTap route: Route)
    func navigationMapView(_ mapView: NavigationMapView, shapeFor waypoints: [Waypoint]) -> MGLShape?
    func navigationMapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage?
    func navigationMapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView?
    
    func mapViewControllerDidOpenFeedback(_ mapViewController: RouteMapViewController)
    func mapViewControllerDidCancelFeedback(_ mapViewController: RouteMapViewController)
    func mapViewControllerDidCancelNavigation(_ mapViewController: RouteMapViewController)
    func mapViewController(_ mapViewController: RouteMapViewController, didSend feedbackId: String, feedbackType: FeedbackType)
    
    func mapViewController(_ mapViewController: RouteMapViewController, mapViewUserAnchorPoint mapView: NavigationMapView) -> CGPoint?
    
    func mapViewControllerShouldAnnotateSpokenInstructions(_ routeMapViewController: RouteMapViewController) -> Bool
}
