import UIKit
import Pulley
import Mapbox
import MapboxDirections
import MapboxCoreNavigation
import SDWebImage


class ArrowFillPolyline: MGLPolylineFeature {}
class ArrowStrokePolyline: ArrowFillPolyline {}


class RouteMapViewController: UIViewController, PulleyPrimaryContentControllerDelegate {
    @IBOutlet weak var mapView: NavigationMapView!
    @IBOutlet weak var recenterButton: UIButton!
    
    var routePageViewController: RoutePageViewController!
    var routeTableViewController: RouteTableViewController!
    let routeStepFormatter = RouteStepFormatter()
    
    var route: Route { return routeController.routeProgress.route }
    
    var destination: MGLAnnotation!
    var pendingCamera: MGLMapCamera?
    weak var delegate: RouteMapViewControllerDelegate?
    
    weak var routeController: RouteController!
    
    let distanceFormatter = DistanceFormatter(approximate: true)
    
    var resetTrackingModeTimer: Timer!
    
    let webImageManager = SDWebImageManager.shared()
    var shieldAPIDataTask: URLSessionDataTask?
    var shieldImageDownloadToken: SDWebImageDownloadToken?
    var arrowCurrentStep: RouteStep?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        
        mapView.delegate = self
        mapView.navigationMapDelegate = self
        mapView.tintColor = NavigationUI.shared.tintColor
        recenterButton.tintColor = NavigationUI.shared.tintColor
        recenterButton.applyDefaultCornerRadiusShadow(cornerRadius: 22)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.compassView.isHidden = true
        mapView.addAnnotation(destination)
        
        if let camera = pendingCamera {
            mapView.camera = camera
        } else {
            let camera = mapView.camera
            camera.altitude = 1_000
            camera.pitch = 45
            mapView.camera = camera
        }
        
        UIDevice.current.addObserver(self, forKeyPath: "batteryState", options: .initial, context: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        mapView.setUserLocationVerticalAlignment(.bottom, animated: false)
        mapView.setUserTrackingMode(.followWithCourse, animated: false)
        
        let topPadding: CGFloat = 30
        let bottomPadding: CGFloat = 50
        let contentInset = UIEdgeInsets(top: routePageViewController.view.frame.maxY+topPadding, left: 0, bottom: bottomPadding, right: 0)
        mapView.setContentInset(contentInset, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        webImageManager.cancelAll()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "batteryState" {
            let batteryState = UIDevice.current.batteryState
            let pluggedIn = batteryState == .charging || batteryState == .full
            routeController.locationManager.desiredAccuracy = pluggedIn ? kCLLocationAccuracyBestForNavigation : kCLLocationAccuracyBest
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func recenter(_ sender: AnyObject) {
        mapView.userTrackingMode = .followWithCourse
        
        // Recenter also resets the current page. Same behavior as rerouting.
        routePageViewController.notifyDidReRoute()
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
        mapView.userTrackingMode = .followWithCourse
    }
    
    func notifyAlertLevelDidChange(routeProgress: RouteProgress) {
        if routeProgress.currentLegProgress.followOnStep != nil {
            mapView.addArrow(routeProgress)
        }
    }
    
    func notifyDidChange(routeProgress: RouteProgress, location: CLLocation, secondsRemaining: TimeInterval) {
        let stepProgress = routeController.routeProgress.currentLegProgress.currentStepProgress
        let distanceRemaining = stepProgress.distanceRemaining
        guard let controller = routePageViewController.currentManeuverPage else { return }
        
        controller.distanceLabel.isHidden = false
        
        if routeProgress.currentLegProgress.alertUserLevel == .arrive {
            controller.streetLabel.text = routeStepFormatter.string(for: routeProgress.currentLegProgress.upComingStep)
            controller.distanceLabel.isHidden = true
        } else if let upComingStep = routeProgress.currentLegProgress?.upComingStep {
            
            if secondsRemaining > 5 {
                controller.distanceLabel.text = distanceFormatter.string(from: distanceRemaining)
            } else {
                controller.distanceLabel.isHidden = true
            }
            
            if let name = upComingStep.names?.first {
                controller.streetLabel.text = name
            } else if let destinations = upComingStep.destinations?.joined(separator: "\n") {
                controller.streetLabel.text = destinations
            } else {
                controller.streetLabel.text = upComingStep.instructions
            }
            
            updateShield(for: controller)
        }
        
        controller.turnArrowView.step = routeProgress.currentLegProgress.upComingStep
    }
    
    func dataTaskForShieldImage(network: String, number: String, height: CGFloat, completion: @escaping (UIImage?) -> Void) -> URLSessionDataTask? {
        guard let imageNamePattern = ShieldImageNamesByPrefix[network] else {
            return nil
        }
        
        let imageName = imageNamePattern.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "{ref}", with: number)
        let apiURL = URL(string: "https://commons.wikimedia.org/w/api.php?action=query&format=json&maxage=86400&prop=imageinfo&titles=File%3A\(imageName)&iiprop=url%7Csize&iiurlheight=\(Int(round(height)))")!
        
        guard shieldAPIDataTask?.originalRequest?.url != apiURL else {
            return nil
        }
        
        shieldAPIDataTask?.cancel()
        return URLSession.shared.dataTask(with: apiURL) { [weak self] (data, response, error) in
            var json: [String: Any] = [:]
            if let data = data, response?.mimeType == "application/json" {
                do {
                    json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                } catch {
                    assert(false, "Invalid data")
                }
            }
            
            guard data != nil && error == nil else {
                return
            }
            
            guard let query = json["query"] as? [String: Any],
                let pages = query["pages"] as? [String: Any], let page = pages.first?.1 as? [String: Any],
                let imageInfos = page["imageinfo"] as? [[String: Any]], let imageInfo = imageInfos.first,
                let thumbURLString = imageInfo["thumburl"] as? String, let thumbURL = URL(string: thumbURLString) else {
                    return
            }
            
            if thumbURL != self?.shieldImageDownloadToken?.url {
                self?.webImageManager.imageDownloader?.cancel(self?.shieldImageDownloadToken)
            }
            self?.shieldImageDownloadToken = self?.webImageManager.imageDownloader?.downloadImage(with: thumbURL, options: .scaleDownLargeImages, progress: nil) { (image, data, error, isFinished) in
                completion(image)
            }
        }
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
    
    @objc(navigationMapView:shouldUpdateTo:)
    func navigationMapView(_ mapView: NavigationMapView, shouldUpdateTo location: CLLocation) -> CLLocation? {

        guard routeController.userIsOnRoute(location) else { return nil }
        
        let route = routeController.routeProgress.route
        guard let coordinates = route.coordinates else  { return nil }
        
        var newCoordinate = location.coordinate
        if routeController.snapsUserLocationAnnotationToRoute {
            // Snap to route
            let snappedCoordinate = closestCoordinate(on: coordinates, to: location.coordinate)
            if let coordinate = snappedCoordinate?.coordinate {
                newCoordinate = coordinate
            }
        }
        
        let defaultReturn = CLLocation(coordinate: newCoordinate, altitude: location.altitude, horizontalAccuracy: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy, course: location.course, speed: location.speed, timestamp: location.timestamp)
        
        guard location.course != -1 else {
            return defaultReturn
        }
        
        let coords = routeController.routeProgress.currentLegProgress.nearbyCoordinates
        
        let closest = closestCoordinate(on: coords, to: location.coordinate)!
        let slicedLine = polyline(along: coords, from: closest.coordinate, to: coords.last)
        
        
        let userDistanceBuffer = location.speed * RouteControllerDeadReckoningTimeInterval
        
        // Get closest point infront of user
        let pointOneSliced = coordinate(at: userDistanceBuffer, fromStartOf: slicedLine)!
        let pointOneClosest = closestCoordinate(on: coords, to: pointOneSliced)!
        
        let pointTwoSliced = coordinate(at: userDistanceBuffer * 2, fromStartOf: slicedLine)!
        let pointTwoClosest = closestCoordinate(on: coords, to: pointTwoSliced)!
        
        // Get direction of these points
        let pointOneDirection = closest.coordinate.direction(to: pointOneClosest.coordinate)
        let pointTwoDirection = closest.coordinate.direction(to: pointTwoClosest.coordinate)
        
        let wrappedPointOne = wrap(pointOneDirection, min: -180, max: 180)
        let wrappedPointTwo = wrap(pointTwoDirection, min: -180, max: 180)
        let wrappedCourse = wrap(location.course, min: -180, max: 180)
        
        let relativeAnglepointOne = wrap(wrappedPointOne - wrappedCourse, min: -180, max: 180)
        let relativeAnglepointTwo = wrap(wrappedPointTwo - wrappedCourse, min: -180, max: 180)
        
        let averageRelativeAngle = (relativeAnglepointOne + relativeAnglepointTwo) / 2

        let absoluteDirection = wrap(wrappedCourse + averageRelativeAngle, min: 0 , max: 360)
        
        guard differenceBetweenAngles(absoluteDirection, location.course) < RouteControllerMaxManipulatedCourseAngle else {
            return defaultReturn
        }
        
        let course = averageRelativeAngle <= RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion ? absoluteDirection : location.course
        
        return CLLocation(coordinate: newCoordinate, altitude: location.altitude, horizontalAccuracy: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy, course: course, speed: location.speed, timestamp: location.timestamp)
    }
}

// MARK: MGLMapViewDelegate

extension RouteMapViewController: MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        if annotation is ArrowStrokePolyline {
            return NavigationUI.shared.tintStrokeColor
        } else if annotation is ArrowFillPolyline {
            return .white
        } else {
            return NavigationUI.shared.tintColor
        }
    }
    
    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        if annotation is ArrowStrokePolyline {
            return 7
        } else if annotation is ArrowFillPolyline {
            return 6
        } else {
            return 8
        }
    }
    
    func mapView(_ mapView: MGLMapView, didChange mode: MGLUserTrackingMode, animated: Bool) {
        if resetTrackingModeTimer != nil {
            resetTrackingModeTimer.invalidate()
        }
        
        if mode != .followWithCourse {
            recenterButton.isHidden = false
            startResetTrackingModeTimer()
        } else {
            recenterButton.isHidden = true
        }
    }
    
    func mapView(_ mapView: MGLMapView, regionDidChangeAnimated animated: Bool) {
        if resetTrackingModeTimer != nil && mapView.userTrackingMode == .none {
            resetTrackingModeTimer.invalidate()
            startResetTrackingModeTimer()
        }
    }
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        let map = mapView as! NavigationMapView
        map.showRoute(route)
    }
    
    func mapView(_ mapView: MGLMapView, didSelect annotation: MGLAnnotation) {
        if resetTrackingModeTimer != nil {
            resetTrackingModeTimer.invalidate()
            startResetTrackingModeTimer()
        }
    }
    
    func mapView(_ mapView: MGLMapView, didDeselect annotation: MGLAnnotation) {
        mapView.userTrackingMode = .followWithCourse
    }
    
    func updateShield(for controller: RouteManeuverViewController) {
        let currentLegProgress = routeController.routeProgress.currentLegProgress
        
        guard let upComingStep = currentLegProgress?.upComingStep else { return }
        guard let ref = upComingStep.codes?.first else { return }
        guard controller.shieldImage == nil else { return }
        
        let components = ref.components(separatedBy: " ")
        
        if components.count > 1 {
            shieldAPIDataTask = dataTaskForShieldImage(network: components[0], number: components[1], height: 32 * UIScreen.main.scale) { (image) in
                controller.shieldImage = image
            }
            shieldAPIDataTask?.resume()
        }
    }
}

// MARK: RouteManeuverPageViewControllerDelegate

extension RouteMapViewController: RoutePageViewControllerDelegate {
    internal func routePageViewController(_ controller: RoutePageViewController, willTransitionTo maneuverViewController: RouteManeuverViewController) {
        let step = maneuverViewController.step
        
        maneuverViewController.shieldImage = nil
        updateShield(for: maneuverViewController)
        
        if let name = step?.names?.first {
            maneuverViewController.streetLabel.text = name
        } else if let destinations = step?.destinations?.joined(separator: "\n") {
            maneuverViewController.streetLabel.text = destinations
        } else {
            maneuverViewController.streetLabel.text = step?.instructions
        }
        maneuverViewController.distanceLabel.text = step!.distance > 0 ? distanceFormatter.string(from: step!.distance) : ""
        maneuverViewController.turnArrowView.step = step
        
        if let allLanes = step?.intersections?.first?.approachLanes, let usableLanes = step?.intersections?.first?.usableApproachLanes {
            for (i, lane) in allLanes.enumerated() {
                guard i < maneuverViewController.laneViews.count else {
                    return
                }
                let laneView = maneuverViewController.laneViews[i]
                laneView.isHidden = false
                laneView.lane = lane
                laneView.maneuverDirection = step?.maneuverDirection
                laneView.isValid = usableLanes.contains(i as Int)
                laneView.setNeedsDisplay()
            }
        } else {
            maneuverViewController.stackViewContainer.isHidden = true
        }
        
        if routeController.routeProgress.currentLegProgress.isCurrentStep(step!) {
            mapView.userTrackingMode = .followWithCourse
        } else {
            mapView.setCenter(step!.maneuverLocation, zoomLevel: mapView.zoomLevel, direction: step!.initialHeading!, animated: true, completionHandler: nil)
        }
    }

    
    func currentStep() -> RouteStep {
        return routeController.routeProgress.currentLegProgress.currentStep
    }
    
    func stepBefore(_ step: RouteStep) -> RouteStep? {
        return routeController.routeProgress.currentLegProgress.stepBefore(step)
    }
    
    func stepAfter(_ step: RouteStep) -> RouteStep? {
        return routeController.routeProgress.currentLegProgress.stepAfter(step)
    }
}

protocol RouteMapViewControllerDelegate: class {
    func navigationMapView(_ mapView: NavigationMapView, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    func navigationMapView(_ mapView: NavigationMapView, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    func navigationMapView(_ mapView: NavigationMapView, shapeDescribing route: Route) -> MGLShape?
    func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeDescribing route: Route) -> MGLShape?
}
