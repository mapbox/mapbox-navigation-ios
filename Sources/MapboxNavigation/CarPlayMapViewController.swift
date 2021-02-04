import Foundation
import MapboxMaps

#if canImport(CarPlay)
import CarPlay

/**
 `CarPlayMapViewController` is responsible for administering the Mapbox map, the interface styles and the map template buttons to display on CarPlay.
 */
@available(iOS 12.0, *)
public class CarPlayMapViewController: UIViewController {
    static let defaultAltitude: CLLocationDistance = 850
    
    var styleManager: StyleManager?
    
    /**
     The interface styles available to `styleManager` for display.
     */
    var styles: [Style] {
        didSet {
            styleManager?.styles = styles
        }
    }
    
    /**
     A very coarse location manager used for distinguishing between daytime and nighttime.
     */
    fileprivate let coarseLocationManager: CLLocationManager = {
        let coarseLocationManager = CLLocationManager()
        coarseLocationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        return coarseLocationManager
    }()
    
    var isOverviewingRoutes: Bool = false {
        didSet {
            // Fix content insets in overview mode.
            automaticallyAdjustsScrollViewInsets = !isOverviewingRoutes
        }
    }
    
    var navigationMapView: NavigationMapView {
        get {
            return self.view as! NavigationMapView
        }
    }
    
    /**
     The map button for recentering the map view if a user action causes it to stop following the user.
     */
    public lazy var recenterButton: CPMapButton = {
        let recenter = CPMapButton { [weak self] button in
            // Since tracking mode is no longer part of `MapView` functionality camera is used directly to
            // zoom-in to most recent location.
            guard let self = self else { return }
            let latestLocation = self.navigationMapView.mapView.locationManager.latestLocation
            self.navigationMapView.mapView.cameraManager.setCamera(centerCoordinate: latestLocation?.coordinate,
                                                                   zoom: 12.0,
                                                                   bearing: latestLocation?.course,
                                                                   pitch: 0,
                                                                   animated: true)
            button.isHidden = true
        }
        
        let bundle = Bundle.mapboxNavigation
        recenter.image = UIImage(named: "carplay_locate", in: bundle, compatibleWith: traitCollection)
        
        return recenter
    }()
    
    /**
     The map button for zooming in the current map view.
     */
    public lazy var zoomInButton: CPMapButton = {
        let zoomInButton = CPMapButton { [weak self] (button) in
            guard let self = self else { return }
            
            let cameraOptions = self.navigationMapView.mapView.cameraView.camera
            cameraOptions.zoom = self.navigationMapView.mapView.zoom + 1.0
            self.navigationMapView.mapView.cameraManager.setCamera(to: cameraOptions, completion: nil)
        }
        
        let bundle = Bundle.mapboxNavigation
        zoomInButton.image = UIImage(named: "carplay_plus", in: bundle, compatibleWith: traitCollection)
        
        return zoomInButton
    }()
    
    /**
     The map button for zooming out the current map view.
     */
    public lazy var zoomOutButton: CPMapButton = {
        let zoomOutButton = CPMapButton { [weak self] button in
            guard let self = self else { return }

            let cameraOptions = self.navigationMapView.mapView.cameraView.camera
            cameraOptions.zoom = self.navigationMapView.mapView.zoom - 1.0
            self.navigationMapView.mapView.cameraManager.setCamera(to: cameraOptions, completion: nil)
        }
        
        let bundle = Bundle.mapboxNavigation
        zoomOutButton.image = UIImage(named: "carplay_minus", in: bundle, compatibleWith: traitCollection)
        
        return zoomOutButton
    }()
    
    /**
     The map button property for hiding or showing the pan map button.
     */
    internal(set) public var panMapButton: CPMapButton?
    
    /**
     The map button property for exiting the pan map mode.
     */
    internal(set) public var dismissPanningButton: CPMapButton?
    
    /**
     Initializes a new CarPlay map view controller.
     
     - parameter styles: The interface styles initially available to the style manager for display.
     */
    required init(styles: [Style]) {
        self.styles = styles
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let styles = aDecoder.decodeObject(of: [NSArray.self, Style.self], forKey: "styles") as? [Style] else {
            return nil
        }
        self.styles = styles
        
        super.init(coder: aDecoder)
    }
    
    override public func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        
        aCoder.encode(styles, forKey: "styles")
    }
    
    override public func loadView() {
        let navigationMapView = NavigationMapView(frame: UIScreen.main.bounds)
        navigationMapView.mapView.on(.styleLoadingFinished) { _ in
            navigationMapView.localizeLabels()
        }
        
        self.view = navigationMapView
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        setupStyleManager()
        resetCamera(animated: false, altitude: CarPlayMapViewController.defaultAltitude)
    }
    
    func setupStyleManager() {
        styleManager = StyleManager()
        styleManager?.delegate = self
        styleManager?.styles = styles
    }
    
    /**
     Creates a new pan map button for the CarPlay map view controller.
     
     - parameter mapTemplate: The map template available to the pan map button for display.
     */
    @discardableResult public func panningInterfaceDisplayButton(for mapTemplate: CPMapTemplate) -> CPMapButton {
        let panButton = CPMapButton { [weak mapTemplate] _ in
            guard let mapTemplate = mapTemplate else { return }
            if !mapTemplate.isPanningInterfaceVisible {
                mapTemplate.showPanningInterface(animated: true)
            }
        }
        
        let bundle = Bundle.mapboxNavigation
        panButton.image = UIImage(named: "carplay_pan", in: bundle, compatibleWith: traitCollection)
        
        return panButton
    }
    
    /**
     Creates a new close button to dismiss the visible panning buttons on the map.
     
     - parameter mapTemplate: The map template available to the pan map button for display.
     */
    @discardableResult public func panningInterfaceDismissalButton(for mapTemplate: CPMapTemplate) -> CPMapButton {
        let defaultButtons = mapTemplate.mapButtons
        let closeButton = CPMapButton { _ in
            mapTemplate.mapButtons = defaultButtons
            mapTemplate.dismissPanningInterface(animated: true)
        }
        
        let bundle = Bundle.mapboxNavigation
        closeButton.image = UIImage(named: "carplay_close", in: bundle, compatibleWith: traitCollection)
        
        return closeButton
    }
    
    func resetCamera(animated: Bool = false, altitude: CLLocationDistance? = nil) {
        let camera = navigationMapView.mapView.cameraView.camera
        let pitch: CGFloat = 60
        if let altitude = altitude,
           let latitude = navigationMapView.mapView.locationManager.latestLocation?.internalLocation.coordinate.latitude {
            camera.zoom = CGFloat(ZoomLevelForAltitude(altitude, pitch, latitude, navigationMapView.mapView.bounds.size))
        }
        
        camera.pitch = pitch
        
        navigationMapView.mapView.cameraManager.setCamera(to: camera, animated: animated, completion: nil)
    }
    
    override public func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // Since tracking mode is no longer part of `MapView` functionality camera is used directly to
        // zoom-in to most recent location.
        guard let activeRoute = navigationMapView.routes?.first else {
            let latestLocation = navigationMapView.mapView.locationManager.latestLocation
            navigationMapView.mapView.cameraManager.setCamera(centerCoordinate: latestLocation?.coordinate,
                                                              zoom: 12.0,
                                                              bearing: latestLocation?.course,
                                                              pitch: 0,
                                                              animated: true)
            
            return
        }
        
        if isOverviewingRoutes {
            // FIXME: Unable to tilt map during route selection -- https://github.com/mapbox/mapbox-gl-native/issues/2259
            let topDownCamera = navigationMapView.mapView.cameraView.camera
            topDownCamera.pitch = 0
            navigationMapView.mapView.cameraManager.setCamera(to: topDownCamera, completion: nil)
            navigationMapView.fit(to: activeRoute, animated: false)
        }
    }
}

@available(iOS 12.0, *)
extension CarPlayMapViewController: StyleManagerDelegate {
    public func location(for styleManager: StyleManager) -> CLLocation? {
        return navigationMapView.userLocationForCourseTracking ?? navigationMapView.mapView.locationManager.latestLocation?.internalLocation ?? coarseLocationManager.location
    }
    
    public func styleManager(_ styleManager: StyleManager, didApply style: Style) {
        let styleURL = style.previewMapStyleURL
        if navigationMapView.mapView.style.styleURL.url != style.mapStyleURL {
            navigationMapView.mapView.style.styleURL = StyleURL.custom(url: styleURL)
        }
    }
    
    public func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) {
        // TODO: Implement the ability to reload style.
    }
}
#endif

