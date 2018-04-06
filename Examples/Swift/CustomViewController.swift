import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import Mapbox
import CoreLocation
import AVFoundation
import MapboxDirections

class CustomViewController: UIViewController, MGLMapViewDelegate, AVSpeechSynthesizerDelegate {

    var destination: MGLPointAnnotation!
    let directions = Directions.shared
    var routeController: RouteController!

    let textDistanceFormatter = DistanceFormatter(approximate: true)
    var userRoute: Route?
    var simulateLocation = false

    // Start voice instructions
    let voiceController = MapboxVoiceController()

    @IBOutlet var mapView: MGLMapView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var instructionsBannerView: InstructionsBannerView!

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
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_ :)), name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rerouted(_:)), name: .routeControllerWillReroute, object: nil)
    }

    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerWillReroute, object: nil)
    }

    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        addRouteToMap()
    }

    // Notifications sent on all location updates
    @objc func progressDidChange(_ notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as! RouteProgress
        let location = notification.userInfo![RouteControllerNotificationUserInfoKey.locationKey] as! CLLocation
        instructionsBannerView.update(for: routeProgress.currentLegProgress)

        mapView.locationManager(routeController.locationManager, didUpdateLocations: [location])
    }

    // Fired when the user is no longer on the route.
    // A new route should be fetched at this time.
    @objc func rerouted(_ notification: NSNotification) {

        getRoute {
            /*
             **IMPORTANT**

             When rerouting, you need to give the RouteController a new route.
             Otherwise, it will continue to compare the user to the old route and continually reroute the user.
             */
            let routeProgress = RouteProgress(route: self.userRoute!)
            self.routeController.routeProgress = routeProgress
        }
    }

    func getRoute(completion: (()->Void)? = nil) {
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
            line.lineColor = NSExpression(forConstantValue: UIColor(red:0.00, green:0.45, blue:0.74, alpha:0.9))
            line.lineWidth = NSExpression(forConstantValue: 5)
            line.lineCap = NSExpression(forConstantValue: NSValue(mglLineCap: .round))
            line.lineJoin = NSExpression(forConstantValue: NSValue(mglLineJoin: .round))

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
