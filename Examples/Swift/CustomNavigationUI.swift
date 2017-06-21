import UIKit
import MapboxCoreNavigation
import Mapbox
import CoreLocation
import AVFoundation
import MapboxDirections

class CustomNavigationUI: UIViewController, MGLMapViewDelegate, AVSpeechSynthesizerDelegate {

    var destination: MGLPointAnnotation!
    let directions = Directions.shared
    var routeController: RouteController!

    let lengthFormatter = LengthFormatter()
    lazy var speechSynth = AVSpeechSynthesizer()
    var isInNavigationMode = false
    var userRoute: Route?
    var pendingCamera: MGLMapCamera!

    @IBOutlet var mapView: MGLMapView!
    @IBOutlet weak var navigationBar: UINavigationBar!

    override func viewDidLoad() {
	super.viewDidLoad()

	mapView.delegate = self
	routeController = RouteController(along: userRoute!, directions: directions)

	mapView.setCamera(pendingCamera, animated: false)
	mapView.userLocationVerticalAlignment = .bottom

	lengthFormatter.unitStyle = .short
	mapView.userTrackingMode = .followWithCourse
	resumeNotifications()

	// Start navigation
	routeController.resume()
    }

    override func viewDidDisappear(_ animated: Bool) {
	suspendNotifications()
	routeController.suspendLocationUpdates()
    }

    func resumeNotifications() {
	NotificationCenter.default.addObserver(self, selector: #selector(alertLevelDidChange(_ :)), name: RouteControllerAlertLevelDidChange, object: nil)
	NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_ :)), name: RouteControllerProgressDidChange, object: nil)
	NotificationCenter.default.addObserver(self, selector: #selector(rerouted(_:)), name: RouteControllerWillReroute, object: nil)
    }

    func suspendNotifications() {
	NotificationCenter.default.removeObserver(self, name: RouteControllerAlertLevelDidChange, object: nil)
	NotificationCenter.default.removeObserver(self, name: RouteControllerProgressDidChange, object: nil)
	NotificationCenter.default.removeObserver(self, name: RouteControllerWillReroute, object: nil)
    }

    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
	addRouteToMap()
    }

    // When the alert level changes, this signals the user is ready for a voice announcement
    func alertLevelDidChange(_ notification: NSNotification) {
	let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
	let alertLevel = routeProgress.currentLegProgress.alertUserLevel
	var text: String

	let distance = routeProgress.currentLegProgress.currentStepProgress.distanceRemaining
	if let upComingStep = routeProgress.currentLegProgress.upComingStep {
	    // Don't give full instruction with distance if the alert type is high
	    if alertLevel == .high {
		text = upComingStep.instructions
	    } else {
		text = "In \(distance) meters \(upComingStep.instructions)"
	    }
	} else {
	    text = "In \(distance) meters \(routeProgress.currentLegProgress.currentStep.instructions)"
	}

	speak(text)
    }

    // Notifications sent on all location updates
    func progressDidChange(_ notification: NSNotification) {
	let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress

	if let upComingStep = routeProgress.currentLegProgress.upComingStep {
	    navigationController?.navigationBar.isHidden = false

	    navigationController?.navigationBar.topItem?.title =  "In \(routeProgress.currentLegProgress.currentStepProgress.distanceRemaining)m \(upComingStep.instructions)"
	} else {
	    navigationController?.navigationBar.isHidden = true
	}
    }

    // Fired when the user is no longer on the route.
    // A new route should be fetched at this time.
    func rerouted(_ notification: NSNotification) {
	speechSynth.stopSpeaking(at: .word)

	getRoute {
	    /*
	     **IMPORTANT**

	     When rerouting, you need to give the RouteController a new route.
	     Otherwise, it will continue to compare the user to the old route and continually reroute the user.
	     */
	    self.routeController.routeProgress = RouteProgress(route: self.userRoute!)
	}
    }

    func getRoute(didFinish: (()->())? = nil) {
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

	    didFinish?()
	    self?.addRouteToMap()
	}
    }

    func addRouteToMap() {
	guard let style = mapView.style else { return }
	guard let userRoute = userRoute else { return }

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

    func speak(_ text: String) {
	let utterance = AVSpeechUtterance(string: text)
	speechSynth.delegate = self
	speechSynth.speak(utterance)
    }
}
