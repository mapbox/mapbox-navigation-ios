import UIKit
import CoreLocation
import MapboxCoreNavigation
import MapboxMaps
import MapboxDirections

// :nodoc:
open class PreviewViewController: UIViewController, Previewable {
    
    // MARK: - Previewable properties and methods
    
    // :nodoc:
    public private(set) var cameraMode: Preview.CameraMode = .centered {
        didSet {
            navigationView.navigationMapView.navigationCamera.move(to: cameraMode)
        }
    }
    
    // :nodoc:
    public var navigationView: NavigationView {
        view as! NavigationView
    }
    
    var topBanners = Stack<BannerPreviewing>()
    
    // :nodoc:
    public var topmostTopBanner: BannerPreviewing? {
        topBanners.peek()
    }
    
    var bottomBanners = Stack<BannerPreviewing>()
    
    // :nodoc:
    public var topmostBottomBanner: BannerPreviewing? {
        bottomBanners.peek()
    }
    
    // :nodoc:
    @discardableResult public func popBanner(_ position: Banner.Position, animated: Bool = true) -> BannerPreviewing? {
        let banner: BannerPreviewing?
        switch position {
        case .topLeading:
            banner = topmostTopBanner
        case .bottomLeading:
            banner = topmostBottomBanner
        }
        
        if let banner = banner {
            delegate?.bannerWillDisappear(self, banner: banner)
            
            switch position {
            case .topLeading:
                let bannerContainerView = navigationView.topBannerContainerView
                topBanners.pop()
                
                if let topBanner = topmostTopBanner {
                    navigationView.topBannerContainerView.hide(animated: animated,
                                                               completion: { _ in
                        bannerContainerView.subviews.forEach {
                            $0.removeFromSuperview()
                        }
                        
                        self.embed(topBanner, in: bannerContainerView)
                        
                        self.navigationView.topBannerContainerView.show()
                    })
                } else {
                    navigationView.topBannerContainerView.hide(animated: animated,
                                                               completion: { _ in
                        bannerContainerView.subviews.forEach {
                            $0.removeFromSuperview()
                        }
                    })
                }
            case .bottomLeading:
                let bannerContainerView = navigationView.bottomBannerContainerView
                bottomBanners.pop()
                
                if let bottomBanner = topmostBottomBanner {
                    navigationView.bottomBannerContainerView.hide(completion: { _ in
                        bannerContainerView.subviews.forEach {
                            $0.removeFromSuperview()
                        }
                        
                        self.embed(bottomBanner, in: bannerContainerView)
                        
                        self.navigationView.bottomBannerContainerView.show()
                    })
                } else {
                    navigationView.bottomBannerContainerView.hide(completion: { _ in
                        bannerContainerView.subviews.forEach {
                            $0.removeFromSuperview()
                        }
                    })
                    
                    if !prefersBackButtonHidden {
                        backButton.hide()
                    }
                }
            }
            
            if banner is DestinationPreviewViewController {
                pointAnnotationManager?.annotations = []
            } else if banner is RoutesPreviewViewController {
                navigationView.navigationMapView.removeWaypoints()
                navigationView.navigationMapView.removeRoutes()
            }
            
            if topmostBottomBanner == nil {
                navigationView.wayNameView.show()
                navigationView.speedLimitView.show()
                cameraModeFloatingButton.cameraMode = .centered
            }
            
            delegate?.bannerDidDisappear(self, banner: banner)
            
            return banner
        }
        
        return nil
    }
    
    // :nodoc:
    public func pushBanner(_ banner: BannerPreviewing, animated: Bool = true) {
        delegate?.bannerWillAppear(self, banner: banner)
        
        if banner is DestinationPreviewViewController || banner is RoutesPreviewViewController {
            navigationView.wayNameView.hide()
            navigationView.speedLimitView.hide()
            cameraModeFloatingButton.cameraMode = .idle
        }
        
        let bannerContainerView: UIView
        switch banner.configuration.position {
        case .topLeading:
            bannerContainerView = navigationView.topBannerContainerView
            
            let previousTopmostTopBanner = topmostTopBanner
            topBanners.push(banner)
            
            // Update top banner constraints to change its height if needed.
            setupTopBannerContainerViewLayoutConstraints()
            
            // In case if banner is already shown - hide it and then present another one.
            if let _ = previousTopmostTopBanner {
                navigationView.topBannerContainerView.hide(animated: animated,
                                                           completion: { _ in
                    bannerContainerView.subviews.forEach {
                        $0.removeFromSuperview()
                    }
                    
                    self.embed(banner, in: bannerContainerView)
                    self.navigationView.topBannerContainerView.show()
                })
            } else {
                embed(banner, in: bannerContainerView)
                navigationView.topBannerContainerView.show(animated: animated)
            }
        case .bottomLeading:
            bannerContainerView = navigationView.bottomBannerContainerView
            
            let previousTopmostBottomBanner = topmostBottomBanner
            bottomBanners.push(banner)
            
            setupBottomBannerContainerViewLayoutConstraints()
            
            // In case if banner is already shown - hide it and then present another one.
            if let _ = previousTopmostBottomBanner {
                navigationView.bottomBannerContainerView.hide(completion: { _ in
                    bannerContainerView.subviews.forEach {
                        $0.removeFromSuperview()
                    }
                    
                    self.embed(banner, in: bannerContainerView)
                    self.navigationView.bottomBannerContainerView.show()
                })
            } else {
                embed(banner, in: bannerContainerView)
                navigationView.bottomBannerContainerView.show()
            }
            
            if !prefersBackButtonHidden {
                backButton.show()
            }
        }
        
        delegate?.bannerDidAppear(self, banner: banner)
    }
    
    // :nodoc:
    public weak var delegate: PreviewViewControllerDelegate?
    
    var backButton: BackButton!
    
    var prefersBackButtonHidden: Bool = false
    
    var finalDestinationAnnotation: PointAnnotation? = nil
    
    var pointAnnotationManager: PointAnnotationManager?
    
    var cameraModeFloatingButton: CameraModeFloatingButton!
    
    var styleManager: StyleManager!
    
    let previewOptions: PreviewOptions
    
    var topBannerContainerViewLayoutConstraints: [NSLayoutConstraint] = []
    
    var bottomBannerContainerViewLayoutConstraints: [NSLayoutConstraint] = []
    
    // MARK: - Initialization methods
    
    public init(_ previewOptions: PreviewOptions = PreviewOptions()) {
        self.previewOptions = previewOptions
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    // MARK: - UIViewController lifecycle methods
    
    open override func loadView() {
        view = setupNavigationView()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackButton()
        setupFloatingButtons()
        setupTopBannerContainerView()
        setupBottomBannerContainerView()
        setupConstraints()
        setupStyleManager()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Apply style each time `PreviewViewController` appears on screen
        // (e.g. after active navigation).
        styleManager.applyStyle()
        setupPassiveLocationManager()
        setupNavigationViewportDataSource()
        subscribeForNotifications()
        setupGestureRecognizers()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupOrnaments()
        setupBottomBannerContainerViewLayoutConstraints()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        unsubscribeFromNotifications()
        resetGestureRecognizers()
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
            setupBottomBannerContainerViewLayoutConstraints()
        }
    }
    
    open override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        setupTopBannerContainerViewLayoutConstraints()
    }
    
    // MARK: - UIViewController setting-up methods
    
    func setupNavigationView() -> NavigationView {
        let frame = parent?.view.bounds ?? UIScreen.main.bounds
        let navigationView = NavigationView(frame: frame)
        navigationView.navigationMapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationView.navigationMapView.delegate = self
        // TODO: Move final destination annotation placement logic to `MapView` or `NavigationMapView`.
        navigationView.navigationMapView.mapView.mapboxMap.onNext(event: .styleLoaded) { [weak self] _ in
            guard let self = self else { return }
            self.pointAnnotationManager = self.navigationView.navigationMapView.mapView.annotations.makePointAnnotationManager()
            
            if let finalDestinationAnnotation = self.finalDestinationAnnotation,
               let pointAnnotationManager = self.pointAnnotationManager {
                pointAnnotationManager.annotations = [finalDestinationAnnotation]
                
                self.finalDestinationAnnotation = nil
            }
        }
        
        return navigationView
    }
    
    func setupBackButton() {
        let backButton = BackButton(type: .system)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        // TODO: Add localization.
        backButton.setTitle("Back", for: .normal)
        backButton.clipsToBounds = true
        backButton.isHidden = true
        backButton.addTarget(self, action: #selector(didPressBackButton), for: .touchUpInside)
        backButton.setImage(.backImage, for: .normal)
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.imageEdgeInsets = UIEdgeInsets(top: 10,
                                                  left: 0,
                                                  bottom: 10,
                                                  right: 15)
        navigationView.addSubview(backButton)
        
        self.backButton = backButton
    }
    
    func setupFloatingButtons() {
        cameraModeFloatingButton = FloatingButton.rounded(imageEdgeInsets: UIEdgeInsets(floatLiteral: 12.0)) as CameraModeFloatingButton
        cameraModeFloatingButton.delegate = self
        
        navigationView.floatingButtons = [
            cameraModeFloatingButton
        ]
        
#if DEBUG
        let debugFloatingButton = FloatingButton.rounded(image: .debugImage,
                                                         imageEdgeInsets: UIEdgeInsets(floatLiteral: 12.0))
        debugFloatingButton.addTarget(self,
                                      action: #selector(didPressDebugButton),
                                      for: .touchUpInside)
        
        navigationView.floatingButtons?.append(debugFloatingButton)
#endif
    }
    
    func setupTopBannerContainerView() {
        navigationView.topBannerContainerView.isHidden = true
        navigationView.topBannerContainerView.backgroundColor = .clear
    }
    
    func setupBottomBannerContainerView() {
        navigationView.bottomBannerContainerView.isHidden = true
        navigationView.bottomBannerContainerView.backgroundColor = .defaultBackgroundColor
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
    
    func setupGestureRecognizers() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGestureRecognizer.name = "preview_long_press_gesture_recognizer"
        navigationView.navigationMapView.addGestureRecognizer(longPressGestureRecognizer)
        
        // In case if map view is panned, rotated or pinched, camera state should be reset.
        for gestureRecognizer in navigationView.navigationMapView.mapView.gestureRecognizers ?? []
        where gestureRecognizer is UIPanGestureRecognizer
        || gestureRecognizer is UIRotationGestureRecognizer
        || gestureRecognizer is UIPinchGestureRecognizer {
            gestureRecognizer.addTarget(self, action: #selector(resetCameraState))
        }
    }
    
    func resetGestureRecognizers() {
        navigationView.navigationMapView.gestureRecognizers?.filter({ $0.name == "preview_long_press_gesture_recognizer" }).forEach {
            navigationView.navigationMapView.removeGestureRecognizer($0)
        }
        
        for gestureRecognizer in navigationView.navigationMapView.mapView.gestureRecognizers ?? []
        where gestureRecognizer is UIPanGestureRecognizer
        || gestureRecognizer is UIRotationGestureRecognizer
        || gestureRecognizer is UIPinchGestureRecognizer {
            gestureRecognizer.removeTarget(self, action: #selector(resetCameraState))
        }
    }
    
    // MARK: - Notifications observer methods
    
    func subscribeForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didUpdatePassiveLocation(_:)),
                                               name: .passiveLocationManagerDidUpdate,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange(_:)),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .passiveLocationManagerDidUpdate,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: UIDevice.orientationDidChangeNotification,
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
        
        // Update camera options based on current location and camera mode.
        navigationView.navigationMapView.navigationCamera.update(to: cameraModeFloatingButton.cameraMode)
    }
    
    @objc func orientationDidChange(_ notification: Notification) {
        navigationView.navigationMapView.navigationCamera.update(to: cameraModeFloatingButton.cameraMode)
        
        // TODO: In case if routes are already shown and orientation changes - fit camera so that all
        // routes fit into available space.
    }
    
    func addDestinationAnnotation(_ coordinate: CLLocationCoordinate2D) {
        let destinationIdentifier = NavigationMapView.AnnotationIdentifier.finalDestinationAnnotation
        var destinationAnnotation = PointAnnotation(id: destinationIdentifier,
                                                    coordinate: coordinate)
        destinationAnnotation.image = .init(image: .defaultMarkerImage,
                                            name: "default_marker")
        
        // If `PointAnnotationManager` is available - add `PointAnnotation`, if not - remember it
        // and add it only after fully loading `MapView` style.
        if let pointAnnotationManager = self.pointAnnotationManager {
            pointAnnotationManager.annotations = [destinationAnnotation]
        } else {
            finalDestinationAnnotation = destinationAnnotation
        }
    }
    
    // :nodoc:
    public func preview(_ coordinate: CLLocationCoordinate2D, animated: Bool) {
        preview(Waypoint(coordinate: coordinate),
                animated: animated)
    }
    
    // :nodoc:
    public func preview(_ waypoint: Waypoint, animated: Bool = true) {
        let destinationOptions = DestinationOptions(waypoint: waypoint)
        
        // If `DestinationPreviewViewController` is already the topmost preview banner - update its
        // `DestinationOptions` only. If not - push banner to the top of the stack.
        let destinationPreviewViewController: DestinationPreviewViewController
        if let currentDestinationPreviewViewController = topmostBottomBanner as? DestinationPreviewViewController {
            destinationPreviewViewController = currentDestinationPreviewViewController
            destinationPreviewViewController.destinationOptions = destinationOptions
        } else {
            destinationPreviewViewController = DestinationPreviewViewController(destinationOptions)
            destinationPreviewViewController.delegate = self
            pushBanner(destinationPreviewViewController, animated: animated)
        }
        
        addDestinationAnnotation(waypoint.coordinate)
        
        if let primaryText = destinationPreviewViewController.destinationOptions.primaryText {
            let primaryAttributedString = NSAttributedString(string: primaryText)
            destinationPreviewViewController.destinationLabel.attributedText =
            delegate?.previewViewController(self,
                                            willPresent: primaryAttributedString,
                                            in: destinationPreviewViewController) ?? primaryAttributedString
        }
    }
    
    // :nodoc:
    public func preview(_ routeResponse: RouteResponse,
                        routeIndex: Int = 0,
                        animated: Bool = false,
                        duration: TimeInterval = 1.0,
                        completion: NavigationMapView.AnimationCompletionHandler? = nil) {
        let routesPreviewOptions = RoutesPreviewOptions(routeResponse: routeResponse, routeIndex: routeIndex)
        
        // If `RoutesPreviewViewController` is already the topmost preview banner - update its
        // `RoutesPreviewOptions` only. If not - push banner to the top of the banners stack.
        let routesPreviewViewController: RoutesPreviewViewController
        if let currentRoutesPreviewViewController = topmostBottomBanner as? RoutesPreviewViewController {
            routesPreviewViewController = currentRoutesPreviewViewController
            routesPreviewViewController.routesPreviewOptions = routesPreviewOptions
        } else {
            routesPreviewViewController = RoutesPreviewViewController(routesPreviewOptions)
            routesPreviewViewController.delegate = self
            pushBanner(routesPreviewViewController, animated: animated)
        }
        
        showcase(routeResponse: routeResponse,
                 routeIndex: routeIndex,
                 animated: animated,
                 duration: duration,
                 completion: completion)
    }
    
    // :nodoc:
    public func showcase(routeResponse: RouteResponse,
                         routeIndex: Int = 0,
                         animated: Bool = false,
                         duration: TimeInterval = 1.0,
                         completion: NavigationMapView.AnimationCompletionHandler? = nil) {
        guard var routes = routeResponse.routes else { return }
        
        routes.insert(routes.remove(at: routeIndex), at: 0)
        
        let cameraOptions = navigationView.defaultRoutesPreviewCameraOptions()
        let routesPresentationStyle: RoutesPresentationStyle = .all(shouldFit: true,
                                                                    cameraOptions: cameraOptions)
        
        navigationView.navigationMapView.showcase(routes,
                                                  routesPresentationStyle: routesPresentationStyle,
                                                  animated: animated,
                                                  duration: duration,
                                                  completion: completion)
    }
    
    func fitCamera(to routeResponse: RouteResponse) {
        guard let routes = routeResponse.routes else { return }
        
        navigationView.navigationMapView.navigationCamera.stop()
        let cameraOptions = navigationView.defaultRoutesPreviewCameraOptions()
        navigationView.navigationMapView.fitCamera(to: routes,
                                                   routesPresentationStyle: .all(shouldFit: true,
                                                                                 cameraOptions: cameraOptions),
                                                   animated: true)
    }
    
    // MARK: - Gesture recognizers
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let passiveLocationProvider = navigationView.navigationMapView.mapView.location.locationProvider as? PassiveLocationProvider,
              let originCoordinate = passiveLocationProvider.locationManager.location?.coordinate else { return }
        
        let destinationCoordinate = navigationView.navigationMapView.mapView.mapboxMap.coordinate(for: gesture.location(in: navigationView.navigationMapView.mapView))
        let coordinates = [
            originCoordinate,
            destinationCoordinate,
        ]
        
        delegate?.previewViewController(self, didAddDestinationBetween: coordinates)
    }
    
    // MARK: - Event handlers
    
    @objc func didPressBackButton() {
        popBanner(.bottomLeading)
    }
    
    @objc func didPressDebugButton() {
        // TODO: Implement debug view presentation.
    }
    
    @objc func resetCameraState() {
        if case .idle = cameraModeFloatingButton.cameraMode { return }
        cameraModeFloatingButton.cameraMode = .idle
    }
}

// MARK: - NavigationMapViewDelegate methods

extension PreviewViewController: NavigationMapViewDelegate {
    
    public func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        delegate?.previewViewController(self, didSelect: route)
    }
}

// MARK: - DestinationPreviewViewControllerDelegate and RoutesPreviewViewControllerDelegate methods

extension PreviewViewController: DestinationPreviewViewControllerDelegate, RoutesPreviewViewControllerDelegate {
    
    func willPreviewRoutes(_ destinationPreviewViewController: DestinationPreviewViewController) {
        delegate?.willPreviewRoutes(self)
    }
    
    func willStartNavigation(_ destinationPreviewViewController: DestinationPreviewViewController) {
        delegate?.willBeginActiveNavigation(self)
    }
    
    func willStartNavigation(_ routesPreviewViewController: RoutesPreviewViewController) {
        delegate?.willBeginActiveNavigation(self)
    }
}

// MARK: - CameraModeFloatingButtonDelegate methods

extension PreviewViewController: CameraModeFloatingButtonDelegate {
    
    func cameraModeFloatingButton(_ cameraModeFloatingButton: CameraModeFloatingButton,
                                  cameraModeDidChangeTo cameraMode: Preview.CameraMode) {
        navigationView.navigationMapView.navigationCamera.move(to: cameraMode)
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
