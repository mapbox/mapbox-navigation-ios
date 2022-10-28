import UIKit
import CoreLocation
import MapboxCoreNavigation
import MapboxMaps
import MapboxDirections

// :nodoc:
public class PreviewViewController: UIViewController, BannerPresentation {
    
    // MARK: - BannerPresentation properties and methods
    
    // :nodoc:
    public var navigationView: NavigationView {
        view as! NavigationView
    }
    
    weak var bannerPresentationDelegate: BannerPresentationDelegate? = nil
    
    var topBanners = Stack<Banner>()
    
    var bottomBanners = Stack<Banner>()
    
    // MARK: - PreviewViewController properties
    
    // :nodoc:
    public weak var delegate: PreviewViewControllerDelegate?
    
    var styleManager: StyleManager!
    
    let previewOptions: PreviewOptions
    
    // :nodoc:
    public var navigationMapView: NavigationMapView {
        get {
            navigationView.navigationMapView
        }
        
        set {
            navigationView.navigationMapView = newValue
        }
    }
    
    // MARK: - Initialization methods
    
    // :nodoc:
    public init(_ previewOptions: PreviewOptions = PreviewOptions()) {
        self.previewOptions = previewOptions
        
        super.init(nibName: nil, bundle: nil)
        
        bannerPresentationDelegate = self
        
        setupFloatingButtons()
        setupConstraints()
        setupStyleManager()
        setupNavigationCamera()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    // MARK: - UIViewController lifecycle methods
    
    public override func loadView() {
        view = setupNavigationView()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Apply style each time `PreviewViewController` appears on screen
        // (e.g. after active navigation).
        styleManager.currentStyle?.apply()
        setupPassiveLocationManager()
        setupNavigationViewportDataSource()
        subscribeForNotifications()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupOrnaments()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        unsubscribeFromNotifications()
    }
    
    public override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        navigationView.setupTopBannerContainerViewHeightLayoutConstraints(topmostTopBanner?.bannerConfiguration.height)
        navigationView.setupBottomBannerContainerViewHeightLayoutConstraints(topmostBottomBanner?.bannerConfiguration.height)
    }
    
    // MARK: - UIViewController setting-up methods
    
    func setupNavigationView() -> NavigationView {
        let frame = parent?.view.bounds ?? UIScreen.main.bounds
        let navigationView = NavigationView(frame: frame)
        navigationView.navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        return navigationView
    }
    
    func setupFloatingButtons() {
        let cameraModeFloatingButton = FloatingButton.rounded(imageEdgeInsets: UIEdgeInsets(floatLiteral: 12.0)) as CameraModeFloatingButton
        cameraModeFloatingButton.navigationView = navigationView
        
        navigationView.floatingButtons = [
            cameraModeFloatingButton
        ]
        
#if DEBUG
        let debugFloatingButton = FloatingButton.rounded(image: .debugImage,
                                                         imageEdgeInsets: UIEdgeInsets(floatLiteral: 12.0))
        debugFloatingButton.addTarget(self,
                                      action: #selector(didPressDebugButton(_:)),
                                      for: .touchUpInside)
        
        navigationView.floatingButtons?.append(debugFloatingButton)
#endif
    }
    
    // TODO: Implement the ability to set default positions for logo and attribution button.
    func setupOrnaments() {
        navigationView.navigationMapView.mapView.ornaments.options.compass.visibility = .hidden
    }
    
    func setupPassiveLocationManager() {
        let passiveLocationManager = PassiveLocationManager()
        let passiveLocationProvider = PassiveLocationProvider(locationManager: passiveLocationManager)
        navigationView.navigationMapView.mapView.location.overrideLocationProvider(with: passiveLocationProvider)
    }
    
    func setupNavigationViewportDataSource() {
        let navigationViewportDataSource = NavigationViewportDataSource(navigationView.navigationMapView.mapView,
                                                                        viewportDataSourceType: .passive)
        navigationView.navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
    }
    
    func setupStyleManager() {
        styleManager = StyleManager()
        styleManager.delegate = self
        styleManager.styles = previewOptions.styles ?? [DayStyle(), NightStyle()]
    }
    
    func setupNavigationCamera() {
        navigationView.moveCamera(to: .centered)
    }
    
    // MARK: - Notifications observer methods
    
    func subscribeForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didUpdatePassiveLocation(_:)),
                                               name: .passiveLocationManagerDidUpdate,
                                               object: nil)
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .passiveLocationManagerDidUpdate,
                                                  object: nil)
    }
    
    @objc func didUpdatePassiveLocation(_ notification: Notification) {
        guard let location = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.locationKey] as? CLLocation else {
            return
        }
        
        // Update user puck to the most recent location.
        navigationView.navigationMapView.moveUserLocation(to: location, animated: true)
        
        // Update current speed limit. In case if speed limit is not available `SpeedLimitView` is hidden.
        navigationView.speedLimitView.signStandard = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.signStandardKey] as? SignStandard
        navigationView.speedLimitView.speedLimit = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.speedLimitKey] as? Measurement<UnitSpeed>
        
        // Update current road name. In case if road name is not available `WayNameView` is hidden.
        let roadNameFromStatus = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.roadNameKey] as? String
        if let roadName = roadNameFromStatus?.nonEmptyString {
            let representation = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.routeShieldRepresentationKey] as? VisualInstruction.Component.ImageRepresentation
            navigationView.wayNameView.label.updateRoad(roadName: roadName, representation: representation)
            navigationView.wayNameView.containerView.isHidden = false
        } else {
            navigationView.wayNameView.text = nil
            navigationView.wayNameView.containerView.isHidden = true
        }
    }
    
    // MARK: - Banner presentation and dismissal methods
    
    // :nodoc:
    @discardableResult
    public func dismissBanner(at position: BannerPosition,
                              animated: Bool = true,
                              duration: TimeInterval = 1.0,
                              animations: (() -> Void)? = nil,
                              completion: (() -> Void)? = nil) -> Banner? {
        return popBanner(at: position,
                         animated: animated,
                         duration: duration,
                         animations: animations,
                         completion: completion)
    }
    
    // :nodoc:
    public func dismissAllExceptFirst(at position: BannerPosition,
                                      animated: Bool = true,
                                      duration: TimeInterval = 1.0,
                                      animations: (() -> Void)? = nil,
                                      completion: (() -> Void)? = nil) {
        popBanner(at: position,
                  animated: animated,
                  duration: duration,
                  animations: animations,
                  completion: completion,
                  popAllExceptFirstBanner: true)
    }
    
    // :nodoc:
    public func present(_ banner: Banner,
                        animated: Bool = true,
                        duration: TimeInterval = 1.0,
                        animations: (() -> Void)? = nil,
                        completion: (() -> Void)? = nil) {
        push(banner,
             animated: animated,
             duration: duration,
             animations: animations,
             completion: completion)
    }
    
    // :nodoc:
    public func topBanner(at position: BannerPosition) -> Banner? {
        switch position {
        case .topLeading:
            return topmostTopBanner
        case .bottomLeading:
            return topmostBottomBanner
        }
    }
    
    // MARK: - Event handlers
    
    @objc func didPressDebugButton(_ sender: Any) {
        // TODO: Implement debug view presentation.
    }
}

// MARK: - StyleManagerDelegate methods

extension PreviewViewController: StyleManagerDelegate {
    
    public func location(for styleManager: MapboxNavigation.StyleManager) -> CLLocation? {
        let passiveLocationProvider = navigationView.navigationMapView.mapView.location.locationProvider as? PassiveLocationProvider
        return passiveLocationProvider?.locationManager.location ?? CLLocationManager().location
    }
    
    public func styleManager(_ styleManager: MapboxNavigation.StyleManager,
                             didApply style: MapboxNavigation.Style) {
        if navigationView.navigationMapView.mapView.mapboxMap.style.uri?.rawValue != style.mapStyleURL.absoluteString {
            navigationView.navigationMapView.mapView.mapboxMap.style.uri = StyleURI(url: style.mapStyleURL)
        }
    }
}

// MARK: - BannerPresentationDelegate methods

extension PreviewViewController: BannerPresentationDelegate {
    
    func bannerWillAppear(_ presenter: BannerPresentation,
                          banner: Banner) {
        delegate?.previewViewController(self, willPresent: banner)
    }
    
    func bannerDidAppear(_ presenter: BannerPresentation,
                         banner: Banner) {
        delegate?.previewViewController(self, didPresent: banner)
    }
    
    func bannerWillDisappear(_ presenter: BannerPresentation,
                             banner: Banner) {
        delegate?.previewViewController(self, willDismiss: banner)
    }
    
    func bannerDidDisappear(_ presenter: BannerPresentation,
                            banner: Banner) {
        delegate?.previewViewController(self, didDismiss: banner)
    }
}
