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

    @IBOutlet weak var overviewButton: Button!
    @IBOutlet weak var recenterButton: Button!
    @IBOutlet weak var overviewButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var wayNameLabel: WayNameLabel!
    @IBOutlet weak var wayNameView: UIView!
    
    var routePageViewController: RoutePageViewController!
    var routeTableViewController: RouteTableViewController!
    let routeStepFormatter = RouteStepFormatter()
    let MBSecondsBeforeResetTrackingMode: TimeInterval = 25.0

    var route: Route { return routeController.routeProgress.route }

    var destination: MGLAnnotation!
    var pendingCamera: MGLMapCamera? {
        guard let parent = parent as? NavigationViewController else {
            return nil
        }
        return parent.pendingCamera
    }
    weak var delegate: RouteMapViewControllerDelegate?

    weak var routeController: RouteController!

    let distanceFormatter = DistanceFormatter(approximate: true)

    var resetTrackingModeTimer: Timer?

    let webImageManager = SDWebImageManager.shared()
    var shieldAPIDataTask: URLSessionDataTask?
    var shieldImageDownloadToken: SDWebImageDownloadToken?
    var arrowCurrentStep: RouteStep?
    var isInOverviewMode = false

    let overviewContentInset = UIEdgeInsets(top: 65, left: 15, bottom: 55, right: 15)

    var simulatesLocationUpdates: Bool {
        guard let parent = parent as? NavigationViewController else { return false }
        return parent.simulatesLocationUpdates
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        
        distanceFormatter.numberFormatter.locale = .nationalizedCurrent
        
        mapView.delegate = self
        mapView.navigationMapDelegate = self
        
        overviewButton.applyDefaultCornerRadiusShadow(cornerRadius: 20)
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
            setDefaultCamera(animated: false)
        }

        UIDevice.current.addObserver(self, forKeyPath: "batteryState", options: .initial, context: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        mapView.setUserLocationVerticalAlignment(.bottom, animated: false)
        mapView.setUserTrackingMode(.followWithCourse, animated: false)

        if simulatesLocationUpdates {
            mapView.locationManager.stopUpdatingLocation()
            mapView.locationManager.stopUpdatingHeading()
        }

        mapView.setContentInset(overviewContentInset, animated: false)
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
        setDefaultCamera(animated: false)
        mapView.userTrackingMode = .followWithCourse

        // Recenter also resets the current page. Same behavior as rerouting.
        routePageViewController.notifyDidReRoute()
    }

    @IBAction func toggleOverview(_ sender: Any) {
        if isInOverviewMode {
            overviewButton.isHidden = false
            setDefaultCamera(animated: false)
            mapView.setUserTrackingMode(.followWithCourse, animated: true)
        } else {
            wayNameView.isHidden = true
            overviewButton.isHidden = true
            updateVisibleBounds(coordinates: routeController.routeProgress.route.coordinates!)
        }
        resetTrackingModeTimer?.invalidate()
        isInOverviewMode = !isInOverviewMode
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

    func setDefaultCamera(animated: Bool) {
        let camera = mapView.camera
        camera.altitude = 600
        camera.pitch = 50
        mapView.setCamera(camera, animated: animated)
    }

    func notifyDidChange(routeProgress: RouteProgress, location: CLLocation, secondsRemaining: TimeInterval) {
        let stepProgress = routeController.routeProgress.currentLegProgress.currentStepProgress
        let distanceRemaining = stepProgress.distanceRemaining
        guard let controller = routePageViewController.currentManeuverPage else { return }
        
        let streetLabelBounds = controller.streetLabel.bounds
        let streetLabelFont = controller.streetLabel.font!

        if routeProgress.currentLegProgress.alertUserLevel == .arrive {
            controller.streetLabel.text = routeStepFormatter.string(for: routeStepFormatter.string(for: routeProgress.currentLegProgress.upComingStep))?.abbreviated(toFit: streetLabelBounds, font: streetLabelFont)
            controller.distance = nil
        } else if let upComingStep = routeProgress.currentLegProgress?.upComingStep {

            if secondsRemaining > 5 {
                
                controller.distance = distanceRemaining
            } else {
                controller.distance = nil
                controller.streetLabel.numberOfLines = 2
            }
            
            if let name = upComingStep.names?.first {
                controller.streetLabel.text = name.abbreviated(toFit: streetLabelBounds, font: streetLabelFont)
            } else if let destinations = upComingStep.destinations?.joined(separator: "\n") {
                controller.streetLabel.text = destinations.abbreviated(toFit: streetLabelBounds, font: streetLabelFont)
            } else {
                controller.streetLabel.text = upComingStep.instructions.abbreviated(toFit: streetLabelBounds, font: streetLabelFont)
                controller.streetLabel.text = routeStepFormatter.string(for: upComingStep)?.abbreviated(toFit: streetLabelBounds, font: streetLabelFont)
            }

            updateShield(for: controller)
            
            controller.showLaneView(step: upComingStep)
            
            if !controller.isPagingThroughStepList {
                let initialPaddingForOverviewButton:CGFloat = controller.stackViewContainer.isHidden ? -30 : -20 + controller.laneViews.first!.frame.maxY
                UIView.animate(withDuration: 0.5, animations: {
                    self.overviewButtonTopConstraint.constant = initialPaddingForOverviewButton + controller.stackViewContainer.frame.maxY
                })
            }
        }

        controller.turnArrowView.step = routeProgress.currentLegProgress.upComingStep

        guard isInOverviewMode else {
            return
        }

        guard let userLocation = mapView.userLocation?.coordinate else {
            return
        }

        let slicedLine = polyline(along: routeProgress.route.coordinates!, from: userLocation, to: routeProgress.route.coordinates!.last)
        updateVisibleBounds(coordinates: slicedLine)
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
        guard let stepCoordinates = routeController.routeProgress.currentLegProgress.currentStep.coordinates else  { return nil }
        
        var possibleClosestCoordinateToRoute = location.coordinate
        if routeController.snapsUserLocationAnnotationToRoute {
            let snappedCoordinate = closestCoordinate(on: stepCoordinates, to: location.coordinate)
            if let coordinate = snappedCoordinate?.coordinate {
                possibleClosestCoordinateToRoute = coordinate
            }
        }

        // Add current way name to UI
        if let style = mapView.style, recenterButton.isHidden {
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
            
            let userPuck = mapView.convert(possibleClosestCoordinateToRoute, toPointTo: mapView)
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
                    let slicedLine = polyline(along: stepCoordinates, from: possibleClosestCoordinateToRoute)
                    
                    let lookAheadDistance:CLLocationDistance = 10
                    guard let pointAheadFeature = coordinate(at: lookAheadDistance, fromStartOf: polyline(along: featureCoordinates, from: possibleClosestCoordinateToRoute)) else { continue }
                    guard let pointAheadUser = coordinate(at: lookAheadDistance, fromStartOf: slicedLine) else { continue }
                    guard let reversedPoint = coordinate(at: lookAheadDistance, fromStartOf: polyline(along: featureCoordinates.reversed(), from: possibleClosestCoordinateToRoute)) else { continue }
                    
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
        
        
        // Snap user and course to route
        let defaultReturn = CLLocation(coordinate: possibleClosestCoordinateToRoute, altitude: location.altitude, horizontalAccuracy: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy, course: location.course, speed: location.speed, timestamp: location.timestamp)
        
        guard location.course != -1 else {
            return defaultReturn
        }
        
        let nearByCoordinates = routeController.routeProgress.currentLegProgress.nearbyCoordinates
        let closest = closestCoordinate(on: nearByCoordinates, to: location.coordinate)!
        let slicedLine = polyline(along: nearByCoordinates, from: closest.coordinate, to: nearByCoordinates.last)
        let userDistanceBuffer = location.speed * RouteControllerDeadReckoningTimeInterval

        // Get closest point infront of user
        let pointOneSliced = coordinate(at: userDistanceBuffer, fromStartOf: slicedLine)!
        let pointOneClosest = closestCoordinate(on: nearByCoordinates, to: pointOneSliced)!
        let pointTwoSliced = coordinate(at: userDistanceBuffer * 2, fromStartOf: slicedLine)!
        let pointTwoClosest = closestCoordinate(on: nearByCoordinates, to: pointTwoSliced)!
        
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
        
        return CLLocation(coordinate: possibleClosestCoordinateToRoute, altitude: location.altitude, horizontalAccuracy: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy, course: course, speed: location.speed, timestamp: location.timestamp)
    }
}

// MARK: MGLMapViewDelegate

extension RouteMapViewController: MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, didChange mode: MGLUserTrackingMode, animated: Bool) {
        if isInOverviewMode && mode != .followWithCourse {
            recenterButton.isHidden = false
            wayNameView.isHidden = true
            startResetTrackingModeTimer()
        } else {
            resetTrackingModeTimer?.invalidate()
            
            if mode != .followWithCourse {
                recenterButton.isHidden = false
                startResetTrackingModeTimer()
            } else {
                recenterButton.isHidden = true
            }
        }
        
        if isInOverviewMode {
            overviewButton.isHidden = false
            recenterButton.isHidden = true
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
        let map = mapView as! NavigationMapView
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
        } else {
            controller.shieldImage = nil
        }
    }
}

// MARK: RouteManeuverPageViewControllerDelegate

extension RouteMapViewController: RoutePageViewControllerDelegate {
    internal func routePageViewController(_ controller: RoutePageViewController, willTransitionTo maneuverViewController: RouteManeuverViewController) {
        let step = maneuverViewController.step

        maneuverViewController.shieldImage = nil
        updateShield(for: maneuverViewController)
        
        let streetLabelBounds = maneuverViewController.streetLabel.bounds
        let streetLabelFont = maneuverViewController.streetLabel.font!

        if let name = step?.names?.first {
            maneuverViewController.streetLabel.text = name.abbreviated(toFit: streetLabelBounds, font: streetLabelFont)
        } else if let destinations = step?.destinations?.joined(separator: "\n") {
            maneuverViewController.streetLabel.text = destinations.abbreviated(toFit: streetLabelBounds, font: streetLabelFont)
        } else if let step = step {
            maneuverViewController.streetLabel.text = routeStepFormatter.string(for: step)?.abbreviated(toFit: streetLabelBounds, font: streetLabelFont)
        }
        maneuverViewController.distance = step!.distance > 0 ? step!.distance : nil
        maneuverViewController.turnArrowView.step = step
        
        if let step = step {
            maneuverViewController.showLaneView(step: step)
            
            let initialPaddingForOverviewButton:CGFloat = maneuverViewController.stackViewContainer.isHidden ? -30 : -20 + maneuverViewController.laneViews.first!.frame.maxY
            UIView.animate(withDuration: 0.5, animations: {
                self.overviewButtonTopConstraint.constant = initialPaddingForOverviewButton + maneuverViewController.stackViewContainer.frame.maxY
            })
        }

        if step == routeController.routeProgress.currentLegProgress.upComingStep {
            maneuverViewController.isPagingThroughStepList = false
            mapView.userTrackingMode = .followWithCourse
        } else {
            maneuverViewController.isPagingThroughStepList = true
            mapView.setCenter(step!.maneuverLocation, zoomLevel: mapView.zoomLevel, direction: step!.initialHeading!, animated: true, completionHandler: nil)
        }
    }

    func currentStep() -> RouteStep {
        return routeController.routeProgress.currentLegProgress.currentStep
    }

    func stepBefore(_ step: RouteStep) -> RouteStep? {
        guard let legProgress = routeController.routeProgress.currentLegProgress,
            let index = legProgress.leg.steps.index(of: step),
            index > legProgress.stepIndex else {
            return nil
        }
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
