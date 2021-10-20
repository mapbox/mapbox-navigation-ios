import Foundation
@_spi(Restricted) import MapboxMaps
import MapboxCoreNavigation
import MapboxDirections

#if canImport(CarPlay)
import CarPlay

/**
 `CarPlayMapViewController` is responsible for administering the Mapbox map, the interface styles and the map template buttons to display on CarPlay.
 */
@available(iOS 12.0, *)
open class CarPlayMapViewController: UIViewController {
    
    // MARK: UI Elements Configuration
    /**
     The view controller’s delegate.
     */
    public weak var delegate: CarPlayMapViewControllerDelegate?
    
    /**
     Controls the styling of CarPlayMapViewController and its components.

     The style can be modified programmatically by using `StyleManager.applyStyle(type:)`.
     */
    public private(set) var styleManager: StyleManager?
    
    /**
     A very coarse location manager used for distinguishing between daytime and nighttime.
     */
    fileprivate let coarseLocationManager: CLLocationManager = {
        let coarseLocationManager = CLLocationManager()
        coarseLocationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        return coarseLocationManager
    }()
    
    /**
     A view that displays the current speed limit.
     */
    public weak var speedLimitView: SpeedLimitView!
    
    /**
     The interface styles available to `styleManager` for display.
     */
    var styles: [Style] {
        didSet {
            styleManager?.styles = styles
        }
    }
    
    var navigationMapView: NavigationMapView {
        get {
            return self.view as! NavigationMapView
        }
    }
    
    // MARK: Bar Buttons Configuration
    
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
    public internal(set) var panMapButton: CPMapButton?
    
    /**
     The map button property for exiting the pan map mode.
     */
    public internal(set) var dismissPanningButton: CPMapButton?
    
    /**
     Creates a new pan map button for the CarPlay map view controller.
     
     - parameter mapTemplate: The map template available to the pan map button for display.
     - returns: `CPMapButton` instance.
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
     - returns: `CPMapButton` instance.
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
    
    // MARK: Initialization Methods
    
    /**
     Initializes a new CarPlay map view controller.
     
     - parameter styles: The interface styles initially available to the style manager for display.
     */
    public required init(styles: [Style]) {
        self.styles = styles
        
        super.init(nibName: nil, bundle: nil)
    }
    
    /**
     Returns a `CarPlayMapViewController` object initialized from data in a given unarchiver.
     
     - parameter coder: An unarchiver object.
     */
    public required init?(coder decoder: NSCoder) {
        guard let styles = decoder.decodeObject(of: [NSArray.self, Style.self], forKey: "styles") as? [Style] else {
            return nil
        }
        self.styles = styles
        
        super.init(coder: decoder)
    }
    
    override public func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        
        aCoder.encode(styles, forKey: "styles")
    }
    
    deinit {
        unsubscribeFromFreeDriveNotifications()
    }
    
    func setupNavigationMapView() {
        let navigationMapView = NavigationMapView(frame: UIScreen.main.bounds, navigationCameraType: .carPlay)
        navigationMapView.delegate = self
        navigationMapView.mapView.mapboxMap.onEvery(.styleLoaded) { _ in
            navigationMapView.localizeLabels()
        }
        
        navigationMapView.userLocationStyle = .puck2D()
        
        navigationMapView.mapView.ornaments.options.logo.visibility = .hidden
        navigationMapView.mapView.ornaments.options.attributionButton.visibility = .hidden
        
        self.view = navigationMapView
    }
    
    func setupStyleManager() {
        styleManager = StyleManager()
        styleManager?.delegate = self
        styleManager?.styles = styles
    }
    
    func setupSpeedLimitView() {
        let speedLimitView = SpeedLimitView()
        speedLimitView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(speedLimitView)
        
        speedLimitView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8).isActive = true
        speedLimitView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8).isActive = true
        speedLimitView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        speedLimitView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        self.speedLimitView = speedLimitView
    }
    
    func setupPassiveLocationProvider() {
        let passiveLocationManager = PassiveLocationManager()
        let passiveLocationProvider = PassiveLocationProvider(locationManager: passiveLocationManager)
        navigationMapView.mapView.location.overrideLocationProvider(with: passiveLocationProvider)
        
        subscribeForFreeDriveNotifications()
    }
    
    // MARK: Notifications Observer Methods
    
    func subscribeForFreeDriveNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didUpdatePassiveLocation),
                                               name: .passiveLocationManagerDidUpdate,
                                               object: nil)
    }
    
    func unsubscribeFromFreeDriveNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .passiveLocationManagerDidUpdate,
                                                  object: nil)
    }
    
    @objc func didUpdatePassiveLocation(_ notification: Notification) {
        speedLimitView.signStandard = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.signStandardKey] as? SignStandard
        speedLimitView.speedLimit = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.speedLimitKey] as? Measurement<UnitSpeed>
    }
    
    // MARK: UIViewController Lifecycle Methods
    
    override public func loadView() {
        setupNavigationMapView()
        setupPassiveLocationProvider()
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        setupStyleManager()
        setupSpeedLimitView()
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
}

// MARK: StyleManagerDelegate Methods

@available(iOS 12.0, *)
extension CarPlayMapViewController: StyleManagerDelegate {
    
    public func location(for styleManager: StyleManager) -> CLLocation? {
        var latestLocation: CLLocation? = nil
        if let coordinate = navigationMapView.mapView.location.latestLocation?.coordinate {
            latestLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        
        return navigationMapView.mostRecentUserCourseViewLocation ??
            latestLocation ??
            coarseLocationManager.location
    }
    
    public func styleManager(_ styleManager: StyleManager, didApply style: Style) {
        let mapboxMapStyle = navigationMapView.mapView.mapboxMap.style
        if mapboxMapStyle.uri?.rawValue != style.mapStyleURL.absoluteString {
            mapboxMapStyle.uri = StyleURI(url: style.previewMapStyleURL)
        }
    }
    
    public func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) {
        guard let mapboxMap = navigationMapView.mapView.mapboxMap,
              let styleURI = mapboxMap.style.uri else { return }
        
        mapboxMap.loadStyleURI(styleURI)
    }
}

// MARK: NavigationMapViewDelegate Methods

@available(iOS 12.0, *)
extension CarPlayMapViewController: NavigationMapViewDelegate {
    
    public func navigationMapView(_ navigationMapView: NavigationMapView,
                                  didAdd finalDestinationAnnotation: PointAnnotation,
                                  pointAnnotationManager: PointAnnotationManager) {
        delegate?.carPlayMapViewController(self,
                                           didAdd: finalDestinationAnnotation,
                                           pointAnnotationManager: pointAnnotationManager)
    }
}
#endif
