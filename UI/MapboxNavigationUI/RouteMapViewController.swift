import UIKit
import Mapbox
import MapboxDirections
import Pulley
import MapboxNavigation
import SDWebImage


class ArrowFillPolyline: MGLPolylineFeature {}
class ArrowStrokePolyline: ArrowFillPolyline {}


class RouteMapViewController: UIViewController, PulleyPrimaryContentControllerDelegate {
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var recenterButton: UIButton!
    
    var routePageViewController: RoutePageViewController!
    var routeTableViewController: RouteTableViewController!
    let routeStepFormatter = RouteStepFormatter()
    
    var route: Route { return routeController.routeProgress.route }
    
    var directions: Directions!
    var destination: MGLAnnotation!
    var pendingCamera: MGLMapCamera?
    
    weak var routeController: RouteController!
    
    var currentManeuverArrowPolylines: [ArrowFillPolyline] = []
    var currentManeuverArrowStrokePolylines: [ArrowFillPolyline] = []
    let distanceFormatter = DistanceFormatter(approximate: true)
    
    var resetTrackingModeTimer: Timer!
    
    let webImageManager = SDWebImageManager.shared()
    var shieldAPIDataTask: URLSessionDataTask?
    var shieldImageDownloadToken: SDWebImageDownloadToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        automaticallyAdjustsScrollViewInsets = false
        
        mapView.delegate = self
        mapView.tintColor = NavigationUI.shared.tintColor
        recenterButton.applyDefaultCornerRadiusShadow(cornerRadius: 22)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.compassView.isHidden = true
        
        mapView.addAnnotation(destination)
        
        if let camera = pendingCamera {
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
        if let viewController = routePageViewController.routeManeuverViewController(with: currentStep()) {
            routePageViewController.setViewControllers([viewController], direction: .reverse, animated: true, completion: nil)
            routePageViewController(routePageViewController, willTransitionTo: viewController)
            routePageViewController.currentManeuverPage = viewController
        }
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
        mapView.annotate([route], clearMap: true)
        mapView.userTrackingMode = .followWithCourse
    }
    
    func notifyAlertLevelDidChange(routeProgress: RouteProgress) {
        if routeProgress.currentLegProgress.followOnStep != nil {
            updateArrowAnnotations(nextStep: routeProgress)
        } else {
            ArrowStyleLayer.remove(from: mapView)
        }
    }
    
    func notifyDidChange(routeProgress: RouteProgress, location: CLLocation, secondsRemaining: TimeInterval) {
        let stepProgress = routeController.routeProgress.currentLegProgress.currentStepProgress
        let distanceRemaining = stepProgress.distanceRemaining
        let controller = routePageViewController.currentManeuverPage
        
        if routeProgress.currentLegProgress.alertUserLevel == .arrive {
            controller?.streetLabel.text = routeStepFormatter.string(for: routeProgress.currentLegProgress.upComingStep)
            controller?.distanceLabel.text = nil
        } else if let upComingStep = routeProgress.currentLegProgress?.upComingStep {
            let destinations = upComingStep.destinations?.joined(separator: "\n")
            
            if secondsRemaining < 5 {
                controller?.distanceLabel.text = nil
                controller?.streetLabel.text = upComingStep.instructions
            } else {
                controller?.distanceLabel.text = distanceFormatter.string(from: distanceRemaining)
                
                if let name = upComingStep.names?.first ?? destinations, let ref = upComingStep.codes?.first {
                    let foregroundColor = NavigationUI.shared.secondaryTextColor
                    let attributes = [
                        NSForegroundColorAttributeName: foregroundColor,
                        NSFontAttributeName: controller?.streetLabel.font,
                        ]
                    let attributedString = NSMutableAttributedString(string: "\(name) ", attributes: attributes)
                    let attachment = NSTextAttachment()
                    attributedString.append(NSAttributedString(attachment: attachment))
                    
                    if controller?.streetLabel.attributedText?.string != attributedString.string {
                        controller?.streetLabel.attributedText = attributedString
                        
                        let components = ref.components(separatedBy: " ")
                        if components.count > 1 {
                            shieldAPIDataTask = dataTaskForShieldImage(network: components[0], number: components[1], height: 32 * UIScreen.main.scale) { (image) in
                                controller?.streetLabel.attributedText = nil
                                if let image = image {
                                    attachment.bounds = CGRect(x: 0, y: 0, width: image.size.width / UIScreen.main.scale, height: image.size.height / UIScreen.main.scale)
                                    attachment.image = image
                                }
                                controller?.streetLabel.attributedText = attributedString
                            }
                            shieldAPIDataTask?.resume()
                        }
                    }
                } else {
                    controller?.streetLabel.text = upComingStep.names?.first ?? destinations
                }
            }
        }
        
        controller?.turnArrowView.step = routeProgress.currentLegProgress.upComingStep
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
    
    func updateArrowAnnotations(nextStep: RouteProgress) {
        guard nextStep.currentLegProgress.upComingStep != nil else {
            return
        }
        
        ArrowStyleLayer.remove(from: mapView)
        ArrowStyleLayer.add(to: mapView,
                            nextStep: nextStep,
                            currentManeuverArrowStrokePolylines: &currentManeuverArrowStrokePolylines,
                            currentManeuverArrowPolylines: &currentManeuverArrowPolylines)
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
        mapView.annotate([route], clearMap: false)
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
}

// MARK: RouteManeuverPageViewControllerDelegate

extension RouteMapViewController: RoutePageViewControllerDelegate {
    internal func routePageViewController(_ controller: RoutePageViewController, willTransitionTo maneuverViewController: RouteManeuverViewController) {
        let step = maneuverViewController.step
        
        let destinations = step?.destinations?.joined(separator: "\n")
        
        maneuverViewController.streetLabel.text = step?.names?.first ?? destinations
        maneuverViewController.distanceLabel.text = distanceFormatter.string(from: step!.distance)
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
