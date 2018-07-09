import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import Mapbox
import CoreLocation
import AVFoundation
import MapboxDirections
import Turf

class CustomViewController: UIViewController, MGLMapViewDelegate {

    var destination: MGLPointAnnotation!
    let directions = Directions.shared
    var routeController: RouteController!
    var simulateLocation = false

    var userRoute: Route?

    // Start voice instructions
    let voiceController = MapboxVoiceController()

    @IBOutlet var mapView: NavigationMapView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var instructionsBannerView: InstructionsBannerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let locationManager = simulateLocation ? SimulatedLocationManager(route: userRoute!) : NavigationLocationManager()
        routeController = RouteController(along: userRoute!, locationManager: locationManager)
        
        mapView.delegate = self
        mapView.compassView.isHidden = true
        mapView.routeController = routeController

        // Add listeners for progress updates
        resumeNotifications()

        // Start navigation
        routeController.resume()
        
        // Center map on user
        mapView.recenterMap()
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
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_ :)), name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rerouted(_:)), name: .routeControllerDidReroute, object: nil)
    }

    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerWillReroute, object: nil)
    }

    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        self.mapView.showRoutes([routeController.routeProgress.route])
    }

    // Notifications sent on all location updates
    @objc func progressDidChange(_ notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as! RouteProgress
        
        // Add maneuver arrow
        if routeProgress.currentLegProgress.followOnStep != nil {
            mapView.addArrow(route: routeProgress.route, legIndex: routeProgress.legIndex, stepIndex: routeProgress.currentLegProgress.stepIndex + 1)
        } else {
            mapView.removeArrow()
        }
        
        // Update the top banner with progress updates
        instructionsBannerView.update(for: routeProgress.currentLegProgress)
        instructionsBannerView.isHidden = false
    }

    // Fired when the user is no longer on the route.
    // Update the route on the map.
    @objc func rerouted(_ notification: NSNotification) {
        self.mapView.showRoutes([routeController.routeProgress.route])
    }

    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func recenterMap(_ sender: Any) {
        mapView.recenterMap()
    }
}
