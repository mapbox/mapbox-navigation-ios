import Foundation
#if canImport(CarPlay)
import CarPlay

@available(iOS 12.0, *)
class CarPlayMapViewController: UIViewController, MGLMapViewDelegate {
    
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
        recenterButton.image = UIImage(named: "location", in: bundle, compatibleWith: traitCollection)
        return recenterButton
    }()
    
    override func loadView() {
        let mapView = NavigationMapView()
        mapView.delegate = self
//        mapView.navigationMapDelegate = self
        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true
        
        self.view = mapView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        styleManager = StyleManager(self)
        styleManager.styles = [DayStyle(), NightStyle()]
        
        resetCamera(animated: false, altitude: CarPlayMapViewController.defaultAltitude)
        mapView.setUserTrackingMode(.followWithCourse, animated: true)
    }
    
    public func zoomInButton() -> CPMapButton {
        let zoomInButton = CPMapButton { [weak self] (button) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.mapView.setZoomLevel(strongSelf.mapView.zoomLevel + 1, animated: true)
        }
        let bundle = Bundle.mapboxNavigation
        zoomInButton.image = UIImage(named: "plus", in: bundle, compatibleWith: traitCollection)
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
        zoomInOut.image = UIImage(named: "minus", in: bundle, compatibleWith: traitCollection)
        return zoomInOut
    }

    
    // MARK: - MGLMapViewDelegate

    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        if let mapView = mapView as? NavigationMapView {
            mapView.localizeLabels()
        }
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
        
        guard isOverviewingRoutes else {
            super.viewSafeAreaInsetsDidChange()
            return
        }
        
        mapView.contentInset = mapView.safeAreaInsets
        
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
    func locationFor(styleManager: StyleManager) -> CLLocation? {
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

