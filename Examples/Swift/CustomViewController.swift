import UIKit
import MapboxCoreNavigation
import Mapbox
import CoreLocation
import AVFoundation
import MapboxDirections

class CustomViewController: UIViewController, MGLMapViewDelegate, AVSpeechSynthesizerDelegate {

    var destination: MGLPointAnnotation!
    let directions = Directions.shared
    var routeController: RouteController!

    let textDistanceFormatter = DistanceFormatter(approximate: true)
    lazy var speechSynth = AVSpeechSynthesizer()
    var userRoute: Route?
    var simulateLocation = false
    let visualInstructionFormatter = VisualInstructionFormatter()
    
    @IBOutlet var mapView: MGLMapView!
    @IBOutlet weak var arrowView: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self

        textDistanceFormatter.numberFormatter.maximumFractionDigits = 0
        
        let locationManager = simulateLocation ? SimulatedLocationManager(route: userRoute!) : NavigationLocationManager()
        
        routeController = RouteController(along: userRoute!, directions: directions, locationManager: locationManager)
        
        mapView.userLocationVerticalAlignment = .center
        mapView.userTrackingMode = .followWithCourse

        resumeNotifications()

        // Start navigation
        routeController.resume()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Disable the map view's default location manager if we're simulating locations
        if simulateLocation {
            mapView.locationManager.stopUpdatingHeading()
            mapView.locationManager.stopUpdatingLocation()
        }
    }

    deinit {
        suspendNotifications()
        routeController.suspendLocationUpdates()
    }

    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(shouldSpeak(_:)), name: RouteControllerDidPassSpokenInstructionPoint, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_ :)), name: RouteControllerProgressDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rerouted(_:)), name: RouteControllerWillReroute, object: nil)
    }

    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: RouteControllerDidPassSpokenInstructionPoint, object: nil)
        NotificationCenter.default.removeObserver(self, name: RouteControllerProgressDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: RouteControllerWillReroute, object: nil)
    }

    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        addRouteToMap()
    }

    // When an instruction should be given
    @objc func shouldSpeak(_ notification: NSNotification) {
        let routeProgress = notification.userInfo![MBRouteControllerDidPassSpokenInstructionPointRouteProgressKey] as! RouteProgress
        
        guard let text = routeProgress.currentLegProgress.currentStepProgress.currentSpokenInstruction?.text else { return }

        let utterance = AVSpeechUtterance(string: text)
        speechSynth.delegate = self
        speechSynth.speak(utterance)
    }

    // Notifications sent on all location updates
    @objc func progressDidChange(_ notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerProgressDidChangeNotificationProgressKey] as! RouteProgress
        let location = notification.userInfo![RouteControllerProgressDidChangeNotificationLocationKey] as! CLLocation
        updateRouteProgress(routeProgress: routeProgress)
        mapView.locationManager(routeController.locationManager, didUpdateLocations: [location])
    }

    // Updates the turn banner with information about the next turn
    func updateRouteProgress(routeProgress: RouteProgress) {
        guard let step = routeProgress.currentLegProgress.upComingStep else { return }

        if let direction = step.maneuverDirection {
            switch direction {
            case .slightRight:
                self.arrowView.text = "↗️"
            case .sharpRight, .right:
                self.arrowView.text = "➡️"
            case .slightLeft:
                self.arrowView.text = "↖️"
            case .sharpLeft, .left:
                self.arrowView.text = "⬅️"
            case .uTurn:
                self.arrowView.text = "⤵️"
            default:
                self.arrowView.text = "⬆️"
            }
        }
        self.instructionLabel.text = visualInstructionFormatter.string(leg: routeProgress.currentLeg, step: routeProgress.currentLegProgress.upComingStep)
        let distance = routeProgress.currentLegProgress.currentStepProgress.distanceRemaining
        self.distanceLabel.text = textDistanceFormatter.string(fromMeters: distance)
    }

    // Fired when the user is no longer on the route.
    // A new route should be fetched at this time.
    @objc func rerouted(_ notification: NSNotification) {
        speechSynth.stopSpeaking(at: .word)

        getRoute {
            /*
             **IMPORTANT**

             When rerouting, you need to give the RouteController a new route.
             Otherwise, it will continue to compare the user to the old route and continually reroute the user.
             */
            let routeProgress = RouteProgress(route: self.userRoute!)
            self.routeController.routeProgress = routeProgress
            self.updateRouteProgress(routeProgress: routeProgress)
        }
    }

    func getRoute(completion: (()->())? = nil) {
        let options = RouteOptions(coordinates: [mapView.userLocation!.coordinate, destination.coordinate])
        options.includesSteps = true
        options.routeShapeResolution = .full
        options.profileIdentifier = .automobileAvoidingTraffic

        _ = directions.calculate(options) { [weak self] (waypoints, routes, error) in
            guard error == nil else {
                print(error!)
                return
            }

            guard let route = routes?.first else {
                return
            }

            self?.userRoute = route

            completion?()
            self?.addRouteToMap()
        }
    }

    func addRouteToMap() {
        guard let style = mapView.style else { return }
        guard let userRoute = userRoute else { return }

        if let annotations = mapView.annotations {
            mapView.removeAnnotations(annotations)
        }
        mapView.addAnnotation(destination)

        let polyline = MGLPolylineFeature(coordinates: userRoute.coordinates!, count: userRoute.coordinateCount)
        let lineSource = MGLShapeSource(identifier: sourceIdentifier, shape: polyline, options: nil)

        if let source = style.source(withIdentifier: sourceIdentifier) as? MGLShapeSource {
            source.shape = polyline
        } else {
            let line = MGLLineStyleLayer(identifier: layerIdentifier, source: lineSource)

            // Style the line
            line.lineColor = MGLStyleValue(rawValue: UIColor(red:0.00, green:0.45, blue:0.74, alpha:0.9))
            line.lineWidth = MGLStyleValue(rawValue: 5)
            line.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
            line.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))

            // Add source and layer
            style.addSource(lineSource)
            for layer in style.layers.reversed() {
                if !(layer is MGLSymbolStyleLayer) {
                    style.insertLayer(line, above: layer)
                    break
                }
            }
        }
    }

    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
