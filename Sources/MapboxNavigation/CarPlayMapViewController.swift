import Foundation
import MapboxMaps
import MapboxCoreNavigation

#if canImport(CarPlay)
import CarPlay

/**
 `CarPlayMapViewController` is responsible for administering the Mapbox map, the interface styles and the map template buttons to display on CarPlay.
 */
@available(iOS 12.0, *)
public class CarPlayMapViewController: UIViewController {
    
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
            self?.navigationMapView.navigationCamera.follow()
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
            guard let self = self,
                  let mapView = self.navigationMapView.mapView else { return }
            
            self.navigationMapView.navigationCamera.stop()
            
            var cameraOptions = CameraOptions(cameraState: mapView.cameraState)
            cameraOptions.zoom = mapView.cameraState.zoom + 1.0
            mapView.mapboxMap.setCamera(to: cameraOptions)
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
            guard let self = self,
                  let mapView = self.navigationMapView.mapView else { return }
            
            self.navigationMapView.navigationCamera.stop()
            
            var cameraOptions = CameraOptions(cameraState: mapView.cameraState)
            cameraOptions.zoom = mapView.cameraState.zoom - 1.0
            mapView.mapboxMap.setCamera(to: cameraOptions)
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
        setupNavigationMapView()
        setupPassiveLocationManager()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        setupStyleManager()
        navigationMapView.navigationCamera.follow()
    }
    
    override public func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        guard let activeRoute = navigationMapView.routes?.first else {
            navigationMapView.navigationCamera.follow()
            return
        }
        
        if navigationMapView.navigationCamera.state == .idle {
            var cameraOptions = CameraOptions(cameraState: navigationMapView.mapView.cameraState)
            cameraOptions.pitch = 0
            navigationMapView.mapView.mapboxMap.setCamera(to: cameraOptions)
            
            navigationMapView.fitCamera(to: activeRoute)
        }
    }
    
    func setupNavigationMapView() {
        let navigationMapView = NavigationMapView(frame: UIScreen.main.bounds, navigationCameraType: .carPlay)
        navigationMapView.mapView.mapboxMap.onNext(.styleLoaded) { _ in
            navigationMapView.localizeLabels()
        }
        
        navigationMapView.userLocationStyle = .puck2D()
        
        navigationMapView.mapView.ornaments.options.logo._visibility = .hidden
        navigationMapView.mapView.ornaments.options.attributionButton._visibility = .hidden
        
        self.view = navigationMapView
    }
    
    func setupStyleManager() {
        styleManager = StyleManager()
        styleManager?.delegate = self
        styleManager?.styles = styles
    }
    
    func setupPassiveLocationManager() {
        let passiveLocationDataSource = PassiveLocationDataSource()
        let passiveLocationManager = PassiveLocationManager(dataSource: passiveLocationDataSource)
        navigationMapView.mapView.location.overrideLocationProvider(with: passiveLocationManager)
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
}

// MARK: - StyleManagerDelegate methods

@available(iOS 12.0, *)
extension CarPlayMapViewController: StyleManagerDelegate {
    
    public func location(for styleManager: StyleManager) -> CLLocation? {
        return navigationMapView.mostRecentUserCourseViewLocation ??
            navigationMapView.mapView.location.latestLocation?.internalLocation ??
            coarseLocationManager.location
    }
    
    public func styleManager(_ styleManager: StyleManager, didApply style: Style) {
        let styleURL = style.previewMapStyleURL
        let mapboxMapStyle = navigationMapView.mapView.mapboxMap.style
        if mapboxMapStyle.uri?.rawValue != style.mapStyleURL.absoluteString {
            mapboxMapStyle.uri = StyleURI(url: styleURL)
        }
    }
    
    public func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) {
        // TODO: Implement the ability to reload style.
    }
}
#endif

