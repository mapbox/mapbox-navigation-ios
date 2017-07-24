import UIKit
import Pulley
import Mapbox
import MapboxDirections
import MapboxCoreNavigation

class ArrowFillPolyline: MGLPolylineFeature {}
class ArrowStrokePolyline: ArrowFillPolyline {}


class RouteMapViewController: UIViewController {
    @IBOutlet weak var mapView: NavigationMapView!

    @IBOutlet weak var overviewButton: Button!
    @IBOutlet weak var reportButton: Button!
    @IBOutlet weak var recenterButton: Button!
    @IBOutlet weak var overviewButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var wayNameLabel: WayNameLabel!
    @IBOutlet weak var wayNameView: UIView!
    
    /**
     Determines whether the user location annotation is moved from the raw user location reported by the device to the nearest location along the route.
     
     By default, this property is set to `true`, causing the user location annotation to be snapped to the route.
     */
    var snapsUserLocationAnnotationToRoute = true
    
    var routePageViewController: RoutePageViewController!
    var routeTableViewController: RouteTableViewController?
    let routeStepFormatter = RouteStepFormatter()
    let MBSecondsBeforeResetTrackingMode: TimeInterval = 25.0

    var route: Route { return routeController.routeProgress.route }
    var previousStep: RouteStep?
    
    var hasFinishedLoadingMap = false

    var destination: MGLAnnotation!
    var pendingCamera: MGLMapCamera? {
        guard let parent = parent as? NavigationViewController else {
            return nil
        }
        return parent.pendingCamera
    }
    var tiltedCamera: MGLMapCamera {
        get {
            let camera = mapView.camera
            camera.altitude = 600
            camera.pitch = 45
            return camera
        }
    }
    weak var delegate: RouteMapViewControllerDelegate?

    weak var routeController: RouteController!

    let distanceFormatter = DistanceFormatter(approximate: true)

    var resetTrackingModeTimer: Timer?

    var arrowCurrentStep: RouteStep?
    var isInOverviewMode = false

    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        
        distanceFormatter.numberFormatter.locale = .nationalizedCurrent
        
        mapView.delegate = self
        mapView.navigationMapDelegate = self
        mapView.manuallyUpdatesLocation = true
        
        overviewButton.applyDefaultCornerRadiusShadow(cornerRadius: 20)
        reportButton.applyDefaultCornerRadiusShadow(cornerRadius: 20)
        recenterButton.applyDefaultCornerRadiusShadow()
        
        wayNameView.layer.borderWidth = 1
        wayNameView.layer.borderColor = UIColor.lightGray.cgColor
        wayNameView.applyDefaultCornerRadiusShadow()
        wayNameLabel.layer.masksToBounds = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.compassView.isHidden = true
        mapView.addAnnotation(destination)

        if let camera = pendingCamera {
            mapView.camera = camera
        } else {
            let camera = tiltedCamera
            if let coordinates = route.coordinates, coordinates.count > 1 {
                camera.centerCoordinate = coordinates.first!
                camera.heading = coordinates[0].direction(to: coordinates[1])
            }
            mapView.setCamera(camera, animated: false)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        mapView.setUserTrackingMode(.followWithCourse, animated: false)
        mapView.setUserLocationVerticalAlignment(.bottom, animated: false)
        mapView.setContentInset(contentInsets, animated: false)
        
        showRouteIfNeeded()
    }

    @IBAction func recenter(_ sender: AnyObject) {
        mapView.setCamera(tiltedCamera, animated: false)
        mapView.userTrackingMode = .followWithCourse
        mapView.logoView.isHidden = false

        // Recenter also resets the current page. Same behavior as rerouting.
        routePageViewController.notifyDidReRoute()
    }

    @IBAction func toggleOverview(_ sender: Any) {
        if isInOverviewMode {
            overviewButton.isHidden = false
            mapView.logoView.isHidden = false
            mapView.setCamera(tiltedCamera, animated: false)
            mapView.setUserTrackingMode(.followWithCourse, animated: true)
        } else {
            wayNameView.isHidden = true
            overviewButton.isHidden = true
            mapView.logoView.isHidden = true
            updateVisibleBounds(coordinates: routeController.routeProgress.route.coordinates!)
        }
        resetTrackingModeTimer?.invalidate()
        isInOverviewMode = !isInOverviewMode
        
        routePageViewController.notifyDidReRoute()
    }
    
    @IBAction func report(_ sender: Any) {
        guard let parent = parent else { return }
        
        let controller = FeedbackViewController.loadFromStoryboard()

        let feedbackId = routeController.recordFeedback()
        
        controller.sendFeedbackHandler = { [weak self] (item) in
            self?.routeController.updateFeedback(feedbackId: feedbackId, type: item.feedbackType, description: nil)
            self?.dismiss(animated: true) {
                DialogViewController.present(on: parent)
            }
        }
        
        controller.dismissFeedbackHandler = { [weak self] in
            self?.routeController.cancelFeedback(feedbackId: feedbackId)
            self?.dismiss(animated: true, completion: nil)
        }
        
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

    func updateVisibleBounds(coordinates: [CLLocationCoordinate2D]) {
        let camera = mapView.camera
        camera.pitch = 0
        camera.heading = 0
        mapView.camera = camera

        let polyline = MGLPolyline(coordinates: coordinates, count: UInt(coordinates.count))
        // Don't keep zooming in
        guard polyline.overlayBounds.ne - polyline.overlayBounds.sw > 200 else {
            return
        }
        
        let overviewContentInset = UIEdgeInsets(top: 65, left: 15, bottom: 55, right: 15)
        mapView.setVisibleCoordinateBounds(polyline.overlayBounds, edgePadding: overviewContentInset, animated: true)
    }

    func startResetTrackingModeTimer() {
        resetTrackingModeTimer = Timer.scheduledTimer(timeInterval: MBSecondsBeforeResetTrackingMode, target: self, selector: #selector(trackingModeTimerDone), userInfo: nil, repeats: false)
    }

    func trackingModeTimerDone() {
        mapView.userTrackingMode = .followWithCourse
    }

    func notifyDidReroute(route: Route) {
        routePageViewController.notifyDidReRoute()
        mapView.addArrow(routeController.routeProgress)
        mapView.showRoute(route)

        if isInOverviewMode {
            updateVisibleBounds(coordinates: routeController.routeProgress.route.coordinates!)
        } else {
            mapView.userTrackingMode = .followWithCourse
            wayNameView.isHidden = true
        }
    }

    func notifyAlertLevelDidChange(routeProgress: RouteProgress) {
        if routeProgress.currentLegProgress.followOnStep != nil {
            mapView.addArrow(routeProgress)
        }
    }
    
    func mapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        return navigationMapView(mapView, imageFor: annotation)
    }

    func notifyDidChange(routeProgress: RouteProgress, location: CLLocation, secondsRemaining: TimeInterval) {
        guard var controller = routePageViewController.currentManeuverPage else { return }
        
        let step = upComingStep ?? currentStep
        
        // Clear the page view controller’s cached pages (before & after) if the step has been changed
        // to avoid going back to an already completed step and avoid duplicated future steps
        if let previousStep = previousStep {
            if previousStep != step {
                controller = routePageViewController.routeManeuverViewController(with: step)!
                routePageViewController.setViewControllers([controller], direction: .forward, animated: false, completion: nil)
                routePageViewController.currentManeuverPage = controller
            }
        }
        
        previousStep = step
        
        // Do not update if the current page doesn't represent the current step
        guard step == controller.step else { return }
        
        controller.notifyDidChange(routeProgress: routeProgress, secondsRemaining: secondsRemaining)
        controller.roadCode = step.codes?.first ?? step.destinationCodes?.first ?? step.destinations?.first
        
        // Move the overview button if the lane views become visible
        if !controller.isPagingThroughStepList {
            let initialPaddingForOverviewButton:CGFloat = controller.stackViewContainer.isHidden ? -30 : -20 + controller.laneViews.first!.frame.maxY
            UIView.animate(withDuration: 0.5, animations: {
                self.overviewButtonTopConstraint.constant = initialPaddingForOverviewButton + controller.stackViewContainer.frame.maxY
            })
        }

        guard isInOverviewMode else {
            return
        }

        guard let userLocation = mapView.userLocation?.coordinate else {
            return
        }

        let slicedLine = polyline(along: routeProgress.route.coordinates!, from: userLocation, to: routeProgress.route.coordinates!.last)
        updateVisibleBounds(coordinates: slicedLine)
    }
    
    var contentInsets: UIEdgeInsets {
        guard let tableViewController = routeTableViewController else { return .zero }
        guard let drawer = parent as? NavigationViewController else { return .zero }
        
        return UIEdgeInsets(top: routePageViewController.view.bounds.height,
                            left: 0,
                            bottom: drawer.drawerPosition == .partiallyRevealed ? tableViewController.partialRevealDrawerHeight() : tableViewController.collapsedDrawerHeight(),
                            right: 0)
    }
}

// MARK: PulleyPrimaryContentControllerDelegate

extension RouteMapViewController: PulleyPrimaryContentControllerDelegate {
    func drawerPositionDidChange(drawer: PulleyViewController) {
        mapView.setContentInset(contentInsets, animated: true)
    }
}

// MARK: NavigationMapViewDelegate

extension RouteMapViewController: NavigationMapViewDelegate {

    func navigationMapView(_ mapView: NavigationMapView, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationMapView(mapView, routeCasingStyleLayerWithIdentifier: identifier, source: source)
    }

    func navigationMapView(_ mapView: NavigationMapView, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationMapView(mapView, routeStyleLayerWithIdentifier: identifier, source: source)
    }

    func navigationMapView(_ mapView: NavigationMapView, shapeDescribing route: Route) -> MGLShape? {
        return delegate?.navigationMapView(mapView, shapeDescribing: route)
    }

    func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeDescribing route: Route) -> MGLShape? {
        return delegate?.navigationMapView(mapView, simplifiedShapeDescribing: route)
    }
    
    func navigationMapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        return delegate?.navigationMapView(mapView, imageFor:annotation)
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        hasFinishedLoadingMap = true
    }

    func navigationMapView(_ mapView: NavigationMapView, shouldUpdateTo location: CLLocation) -> CLLocation? {
        let snappedLocation = routeController.location
        labelCurrentRoad(at: snappedLocation ?? location)
        return snapsUserLocationAnnotationToRoute ? snappedLocation : nil
    }
    
    /**
     Updates the current road name label to reflect the road on which the user is currently traveling.
     
     - parameter location: The user’s current location.
     */
    func labelCurrentRoad(at location: CLLocation) {
        guard let style = mapView.style,
            let stepCoordinates = routeController.routeProgress.currentLegProgress.currentStep.coordinates,
            recenterButton.isHidden && hasFinishedLoadingMap else {
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
                let slicedLine = polyline(along: stepCoordinates, from: closestCoordinate)
                
                let lookAheadDistance:CLLocationDistance = 10
                guard let pointAheadFeature = coordinate(at: lookAheadDistance, fromStartOf: polyline(along: featureCoordinates, from: closestCoordinate)) else { continue }
                guard let pointAheadUser = coordinate(at: lookAheadDistance, fromStartOf: slicedLine) else { continue }
                guard let reversedPoint = coordinate(at: lookAheadDistance, fromStartOf: polyline(along: featureCoordinates.reversed(), from: closestCoordinate)) else { continue }
                
                let distanceBetweenPointsAhead = pointAheadFeature - pointAheadUser
                let distanceBetweenReversedPoint = reversedPoint - pointAheadUser
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
    func mapView(_ mapView: MGLMapView, didChange mode: MGLUserTrackingMode, animated: Bool) {
        if isInOverviewMode && mode != .followWithCourse {
            recenterButton.isHidden = false
            mapView.logoView.isHidden = true
            wayNameView.isHidden = true
            startResetTrackingModeTimer()
        } else {
            resetTrackingModeTimer?.invalidate()
            
            if mode != .followWithCourse {
                recenterButton.isHidden = false
                mapView.logoView.isHidden = true
                startResetTrackingModeTimer()
            } else {
                recenterButton.isHidden = true
                mapView.logoView.isHidden = false
            }
        }
        
        if isInOverviewMode {
            overviewButton.isHidden = false
            recenterButton.isHidden = true
            mapView.logoView.isHidden = false
            isInOverviewMode = false
        }
    }

    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        if mapView.userTrackingMode == .none && !isInOverviewMode {
            wayNameView.isHidden = true
            resetTrackingModeTimer?.invalidate()
            startResetTrackingModeTimer()
        }
    }

    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        // This method is called before the view is added to a window
        // (if the style is cached) preventing UIAppearance to apply the style.
        showRouteIfNeeded()
    }
    
    func showRouteIfNeeded() {
        guard isViewLoaded && view.window != nil else { return }
        let map = mapView as NavigationMapView
        guard !map.showsRoute else { return }
        map.showRoute(route)
    }

    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        if !isInOverviewMode {
            resetTrackingModeTimer?.invalidate()
            startResetTrackingModeTimer()
        }
    }

    func mapView(_ mapView: MGLMapView, didDeselect annotation: MGLAnnotation) {
        mapView.userTrackingMode = .followWithCourse
    }
}

// MARK: RouteManeuverPageViewControllerDelegate

extension RouteMapViewController: RoutePageViewControllerDelegate {
    internal func routePageViewController(_ controller: RoutePageViewController, willTransitionTo maneuverViewController: RouteManeuverViewController) {
        let step = maneuverViewController.step!

        maneuverViewController.turnArrowView.step = step
        maneuverViewController.shieldImage = nil
        maneuverViewController.distance = step.distance > 0 ? step.distance : nil
        maneuverViewController.roadCode = step.codes?.first ?? step.destinationCodes?.first ?? step.destinations?.first
        maneuverViewController.updateStreetNameForStep()
        
        maneuverViewController.showLaneView(step: step)
        
        let initialPaddingForOverviewButton:CGFloat = maneuverViewController.stackViewContainer.isHidden ? -30 : -20 + maneuverViewController.laneViews.first!.frame.maxY
        UIView.animate(withDuration: 0.5) {
            self.overviewButtonTopConstraint.constant = initialPaddingForOverviewButton + maneuverViewController.stackViewContainer.frame.maxY
        }
        
        maneuverViewController.isPagingThroughStepList = true

        if !isInOverviewMode {
            if step == routeController.routeProgress.currentLegProgress.upComingStep {
                mapView.userTrackingMode = .followWithCourse
            } else {
                mapView.setCenter(step.maneuverLocation, zoomLevel: mapView.zoomLevel, direction: step.initialHeading!, animated: true, completionHandler: nil)
            }
        }
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
    func navigationMapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage?
}
