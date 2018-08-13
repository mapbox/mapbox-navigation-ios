import Foundation
#if canImport(CarPlay)
import CarPlay

@available(iOS 12.0, *)
class CarPlayMapViewController: UIViewController {
    
    static let defaultAltitude: CLLocationDistance = 16000
    
    var styleManager: StyleManager!
    /// A very coarse location manager used for distinguishing between daytime and nighttime.
    fileprivate let coarseLocationManager: CLLocationManager = {
        let coarseLocationManager = CLLocationManager()
        coarseLocationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        return coarseLocationManager
    }()
    
    var isOverviewingRoutes: Bool = false
    
    var mapView: NavigationMapView {
        get {
            return self.view as! NavigationMapView
        }
    }

    lazy var recenterButton: CPMapButton = {
        let recenterButton = CPMapButton { [weak self] button in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.mapView.setUserTrackingMode(.followWithCourse, animated: true)
            button.isHidden = true
        }
        
        let bundle = Bundle.mapboxNavigation
        recenterButton.image = UIImage(named: "carplay_locate", in: bundle, compatibleWith: traitCollection)
        return recenterButton
    }()
    
    var styleObservation: NSKeyValueObservation?
    
    override func loadView() {
        let mapView = NavigationMapView()
//        mapView.navigationMapDelegate = self
        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true
        
        styleObservation = mapView.observe(\.style, options: .new) { (mapView, change) in
            guard change.newValue != nil else {
                return
            }
            mapView.localizeLabels()
        }
        
        self.view = mapView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        styleManager = StyleManager(self)
        styleManager.styles = [DayStyle(), NightStyle()]
        
        resetCamera(animated: false, altitude: CarPlayMapViewController.defaultAltitude)
        mapView.setUserTrackingMode(.followWithCourse, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        styleObservation = nil
    }
    
    public func zoomInButton() -> CPMapButton {
        let zoomInButton = CPMapButton { [weak self] (button) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.mapView.setZoomLevel(strongSelf.mapView.zoomLevel + 1, animated: true)
        }
        let bundle = Bundle.mapboxNavigation
        zoomInButton.image = UIImage(named: "carplay_plus", in: bundle, compatibleWith: traitCollection)
        return zoomInButton
    }
    
    public func zoomOutButton() -> CPMapButton {
        let zoomInOut = CPMapButton { [weak self] (button) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.mapView.setZoomLevel(strongSelf.mapView.zoomLevel - 1, animated: true)
        }
        let bundle = Bundle.mapboxNavigation
        zoomInOut.image = UIImage(named: "carplay_minus", in: bundle, compatibleWith: traitCollection)
        return zoomInOut
    }

    
    func resetCamera(animated: Bool = false, altitude: CLLocationDistance? = nil) {
        let camera = mapView.camera
        if let altitude = altitude {
            camera.altitude = altitude
        }
        camera.pitch = 60
        mapView.setCamera(camera, animated: animated)

    }
    
    override func viewSafeAreaInsetsDidChange() {
        mapView.setContentInset(mapView.safeArea, animated: false)
        
        guard isOverviewingRoutes else {
            super.viewSafeAreaInsetsDidChange()
            return
        }
        
        
        guard let routes = mapView.routes,
            let active = routes.first else {
                super.viewSafeAreaInsetsDidChange()
                return
        }
        
        mapView.fit(to: active, animated: false)
    }
}

@available(iOS 12.0, *)
extension CarPlayMapViewController: StyleManagerDelegate {
    func location(for styleManager: StyleManager) -> CLLocation? {
        return mapView.userLocationForCourseTracking ?? mapView.userLocation?.location ?? coarseLocationManager.location
    }
    
    func styleManager(_ styleManager: StyleManager, didApply style: Style) {
        let styleURL = style.previewMapStyleURL
        if mapView.styleURL != styleURL {
            mapView.style?.transition = MGLTransition(duration: 0.5, delay: 0)
            mapView.styleURL = styleURL
        }
    }
    
    func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) {
        mapView.reloadStyle(self)
    }
}
#endif

