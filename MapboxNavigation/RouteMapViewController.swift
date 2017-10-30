import UIKit
import Pulley
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
    @IBOutlet weak var recenterButton: ResumeButton!
    @IBOutlet weak var muteButton: Button!
    @IBOutlet weak var wayNameLabel: WayNameLabel!
    @IBOutlet weak var wayNameView: UIView!
    @IBOutlet weak var maneuverContainerView: ManeuverContainerView!
    @IBOutlet weak var statusView: StatusView!
    @IBOutlet weak var laneViewsContainerView: LanesContainerView!
    
    var routePageViewController: RoutePageViewController!
    var routeTableViewController: RouteTableViewController?
    let routeStepFormatter = RouteStepFormatter()

    var route: Route { return routeController.routeProgress.route }
    var previousStep: RouteStep?
    
    var lastTimeUserRerouted: Date?
    let rerouteSections: [FeedbackSection] = [[.confusingInstructions, .turnNotAllowed, .reportTraffic]]
    let generalFeedbackSections: [FeedbackSection] = [[.closure, .turnNotAllowed, .reportTraffic], [.confusingInstructions, .generalMapError, .badRoute]]

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
            
            if let controller = routePageViewController.currentManeuverPage {
                controller.step = currentStep
                routePageViewController.updateManeuverViewForStep()
            }
        }
    }
    var currentLegIndexMapped = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        
        distanceFormatter.numberFormatter.locale = .nationalizedCurrent
        
        mapView.tracksUserCourse = true
        mapView.delegate = self
        mapView.navigationMapDelegate = self
        mapView.courseTrackingDelegate = self
        
        overviewButton.applyDefaultCornerRadiusShadow(cornerRadius: overviewButton.bounds.midX)
        reportButton.applyDefaultCornerRadiusShadow(cornerRadius: reportButton.bounds.midX)
        muteButton.applyDefaultCornerRadiusShadow(cornerRadius: muteButton.bounds.midX)
        
        wayNameView.layer.borderWidth = 1.0 / UIScreen.main.scale
        wayNameView.applyDefaultCornerRadiusShadow()
        laneViewsContainerView.isHidden = true
        statusView.isHidden = true
        isInOverviewMode = false
        
        resumeNotifications()
    }
    
    deinit {
        suspendNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        muteButton.isSelected = NavigationSettings.shared.muted
        mapView.compassView.isHidden = true

        if let camera = pendingCamera {
            mapView.camera = camera
        } else if let firstCoordinate = route.coordinates?.first {
            let location = CLLocation(latitude: firstCoordinate.latitude, longitude: firstCoordinate.longitude)
            mapView.updateCourseTracking(location: location, animated: false)
        } else {
            mapView.setCamera(tiltedCamera, animated: false)
        }
        
        mapView.enableFrameByFrameCourseViewTracking(for: 3)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        mapView.tracksUserCourse = true
        
        showRouteIfNeeded()
        currentLegIndexMapped = routeController.routeProgress.legIndex
        mapView.enableFrameByFrameCourseViewTracking(for: 3)
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(willReroute(notification:)), name: RouteControllerWillReroute, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReroute(notification:)), name: RouteControllerDidReroute, object: nil)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: RouteControllerWillReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: RouteControllerDidReroute, object: nil)
    }

    @IBAction func recenter(_ sender: AnyObject) {
        mapView.tracksUserCourse = true
        mapView.enableFrameByFrameCourseViewTracking(for: 3)
        isInOverviewMode = false
        updateCameraAltitude(for: routeController.routeProgress)
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
    
    @IBAction func rerouteFeedback() {
        lastTimeUserRerouted = Date()
    }
    
    @IBAction func feedback(_ sender: Any) {
        showFeedback()
        delegate?.mapViewControllerDidOpenFeedback(self)
    }
    
    func showFeedback() {
        
        var sections = generalFeedbackSections
        if let lastTime = lastTimeUserRerouted, abs(lastTime.timeIntervalSinceNow) < RouteControllerNumberOfSecondsForRerouteFeedback {
            sections = rerouteSections
        }
        
        guard let parent = parent else { return }
    
        
        let controller = FeedbackViewController.loadFromStoryboard()
        controller.allowRecordedAudioFeedback = routeController.allowRecordedAudioFeedback
        controller.sections = sections
        let feedbackId = routeController.recordFeedback()
        
        controller.sendFeedbackHandler = { [weak self] (item) in
            guard let strongSelf = self else { return }
            strongSelf.delegate?.mapViewController(strongSelf, didSend: feedbackId, feedbackType: item.feedbackType)
            strongSelf.routeController.updateFeedback(feedbackId: feedbackId, type: item.feedbackType, description: nil, audio: item.audio)
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier ?? "" {
        case "RoutePageViewController":
            if let controller = segue.destination as? RoutePageViewController {
                routePageViewController = controller
                controller.maneuverDelegate = self
            }
        default:
            break
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        mapView.enableFrameByFrameCourseViewTracking(for: 3)
    }
    
    func updateVisibleBounds() {
        guard let userLocation = routeController.locationManager.location?.coordinate else { return }
        
        let overviewContentInset = UIEdgeInsets(top: 65, left: 20, bottom: 55, right: 20)
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
        routePageViewController.updateManeuverViewForStep()

        mapView.addArrow(route: routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex, stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
        mapView.showRoute(routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex)
        
        if routeController.showDebugSpokenInstructionsOnMap {
            mapView.showVoiceInstructionsOnMap(route: routeController.routeProgress.route)
        }

        if isInOverviewMode {
            updateVisibleBounds()
        } else {
            mapView.tracksUserCourse = true
            wayNameView.isHidden = true
        }
        
        rerouteFeedback()
    }
    
    func willReroute(notification: NSNotification) {
        let title = NSLocalizedString("REROUTING", bundle: .mapboxNavigation, value: "Rerouting…", comment: "Indicates that rerouting is in progress")
        statusView.show(title, showSpinner: true)
        statusView.hide(delay: 3, animated: true)
    }
    
    func didReroute(notification: NSNotification) {
        if !(routeController.locationManager is SimulatedLocationManager) {
            statusView.hide(delay: 0.5, animated: true)
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
        
        let zoomOutAltitude = NavigationMapView.zoomedOutManeuverAltitude
        let defaultAltitude = NavigationMapView.defaultAltitude
        let isLongRoad = routeProgress.distanceRemaining >= NavigationMapView.longManeuverDistance
        
        
        let currentStepIsMotorway = currentStep.isMotorway
        let nextStepIsMotorway = upComingStep?.isMotorway ?? false
        let isExiting = currentStepIsMotorway && !nextStepIsMotorway //are we exiting a motorway?
        let notOnMotorway = !currentStepIsMotorway && !nextStepIsMotorway //are we not on a motorway?
        
        if (notOnMotorway || isExiting) { //if we're exiting or not on a motorway, we should be zoomed in.
            return setCamera(altitude: defaultAltitude)
        }
        if currentStepIsMotorway, isLongRoad { //otherwise, we should be zoomed out if we're on motorway and step distance is long enough
            return setCamera(altitude: zoomOutAltitude)
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
        guard var controller = routePageViewController.currentManeuverPage else { return }
        
        let step = upComingStep ?? currentStep
        
        // Clear the page view controller’s cached pages (before & after) if the step has been changed
        // to avoid going back to an already completed step and avoid duplicated future steps
        if let previousStep = previousStep, previousStep != step {
            controller = routePageViewController.routeManeuverViewController(with: step, leg: routeProgress.currentLeg)!
            routePageViewController.setViewControllers([controller], direction: .forward, animated: false, completion: nil)
            routePageViewController.currentManeuverPage = controller
            routePageViewController(routePageViewController, willTransitionTo: controller, didSwipe: false)
        }
        
        if let upComingStep = routeProgress.currentLegProgress?.upComingStep, !routeProgress.currentLegProgress.userHasArrivedAtWaypoint {
            if routePageViewController.currentManeuverPage.step == upComingStep {
                updateLaneViews(step: upComingStep, durationRemaining: routeProgress.currentLegProgress.currentStepProgress.durationRemaining)
            }
        }
        
        previousStep = step
        
        // Do not update if the current page doesn't represent the current step
        guard step == controller.step else { return }
        
        controller.notifyDidChange(routeProgress: routeProgress, secondsRemaining: secondsRemaining)
        controller.roadCode = step.codes?.first ?? step.destinationCodes?.first ?? step.destinations?.first
        
        if currentLegIndexMapped != routeProgress.legIndex {
            mapView.showWaypoints(routeProgress.route, legIndex: routeProgress.legIndex)
            mapView.showRoute(routeProgress.route, legIndex: routeProgress.legIndex)
            
            currentLegIndexMapped = routeProgress.legIndex
        }
        
        if routeController.showDebugSpokenInstructionsOnMap {
            mapView.showVoiceInstructionsOnMap(route: routeController.routeProgress.route)
        }

        guard isInOverviewMode else {
            return
        }

        updateVisibleBounds()
    }
    
    var contentInsets: UIEdgeInsets {
        guard let tableViewController = routeTableViewController else { return .zero }
        guard let drawer = parent as? NavigationViewController else { return .zero }
        
        return UIEdgeInsets(top: routePageViewController.view.bounds.height,
                            left: 0,
                            bottom: drawer.drawerPosition == .partiallyRevealed ? tableViewController.partialRevealDrawerHeight() : tableViewController.collapsedDrawerHeight(),
                            right: 0)
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

// MARK: PulleyPrimaryContentControllerDelegate

extension RouteMapViewController: PulleyPrimaryContentControllerDelegate {
    func drawerPositionDidChange(drawer: PulleyViewController) {
        mapView.setContentInset(contentInsets, animated: true)
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
        map.showRoute(routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex)
        map.showWaypoints(routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex)
        
        if routeController.routeProgress.currentLegProgress.stepIndex + 1 <= routeController.routeProgress.currentLegProgress.leg.steps.count {
            map.addArrow(route: routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex, stepIndex: routeController.routeProgress.currentLegProgress.stepIndex + 1)
        }
        
        if routeController.showDebugSpokenInstructionsOnMap {
            mapView.showVoiceInstructionsOnMap(route: routeController.routeProgress.route)
        }
    }
}

// MARK: RouteManeuverPageViewControllerDelegate

extension RouteMapViewController: RoutePageViewControllerDelegate {
    internal func routePageViewController(_ controller: RoutePageViewController, willTransitionTo maneuverViewController: RouteManeuverViewController, didSwipe: Bool) {
        let step = maneuverViewController.step!

        maneuverViewController.turnArrowView.step = step
        maneuverViewController.distance = step.distance > 0 ? step.distance : nil
        maneuverViewController.roadCode = step.codes?.first ?? step.destinationCodes?.first ?? step.destinations?.first
        maneuverViewController.updateStreetNameForStep()
        
        updateLaneViews(step: step, durationRemaining: 0)

        if !isInOverviewMode {
            if didSwipe, step != routeController.routeProgress.currentLegProgress.upComingStep {
                mapView.enableFrameByFrameCourseViewTracking(for: 1)
                mapView.tracksUserCourse = false
                mapView.setCenter(step.maneuverLocation, zoomLevel: mapView.zoomLevel, direction: step.initialHeading!, animated: true, completionHandler: nil)
            }
            
            if didSwipe, step == routeController.routeProgress.currentLegProgress.upComingStep {
                mapView.tracksUserCourse = true
            }
        }
        
        if let stepIndex = routeController.routeProgress.currentLeg.steps.index(where: { $0 == step }), stepAfter(step) != nil {
            mapView.addArrow(route: routeController.routeProgress.route, legIndex: routeController.routeProgress.legIndex, stepIndex: stepIndex)
        } else {
            mapView.removeArrow()
        }
    }
    
    var currentLeg: RouteLeg {
        return routeController.routeProgress.currentLeg
    }
    
    var upComingStep: RouteStep? {
        return routeController.routeProgress.currentLegProgress.upComingStep
    }
    
    var currentStep: RouteStep {
        return routeController.routeProgress.currentLegProgress.currentStep
    }

    func stepBefore(_ step: RouteStep) -> RouteStep? {
        guard let legProgress = routeController.routeProgress.currentLegProgress,
            let index = legProgress.leg.steps.index(of: step),
            index - 1 > legProgress.stepIndex,
            !isInOverviewMode else {
            return nil
        }
        return routeController.routeProgress.currentLegProgress.stepBefore(step)
    }

    func stepAfter(_ step: RouteStep) -> RouteStep? {
        guard !isInOverviewMode else {
            return nil
        }
        return routeController.routeProgress.currentLegProgress.stepAfter(step)
    }
}

protocol RouteMapViewControllerDelegate: class {
    func navigationMapView(_ mapView: NavigationMapView, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    func navigationMapView(_ mapView: NavigationMapView, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    func navigationMapView(_ mapView: NavigationMapView, shapeDescribing route: Route) -> MGLShape?
    func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeDescribing route: Route) -> MGLShape?
    func navigationMapView(_ mapView: NavigationMapView, waypointStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    func navigationMapView(_ mapView: NavigationMapView, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    func navigationMapView(_ mapView: NavigationMapView, shapeFor waypoints: [Waypoint]) -> MGLShape?
    func navigationMapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage?
    func navigationMapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView?
    
    func mapViewControllerDidOpenFeedback(_ mapViewController: RouteMapViewController)
    func mapViewControllerDidCancelFeedback(_ mapViewController: RouteMapViewController)
    func mapViewController(_ mapViewController: RouteMapViewController, didSend feedbackId: String, feedbackType: FeedbackType)
    
    func mapViewController(_ mapViewController: RouteMapViewController, mapViewUserAnchorPoint mapView: NavigationMapView) -> CGPoint?
}
