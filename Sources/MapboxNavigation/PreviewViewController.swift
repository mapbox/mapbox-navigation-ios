import UIKit
import CoreLocation
import MapboxCoreNavigation
import MapboxMaps
import MapboxDirections

// :nodoc:
open class PreviewViewController: UIViewController, BannerPresentation {
    
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
    
    var finalDestinationAnnotation: PointAnnotation? = nil
    
    var pointAnnotationManager: PointAnnotationManager?
    
    var cameraModeFloatingButton: CameraModeFloatingButton!
    
    var styleManager: StyleManager!
    
    let previewOptions: PreviewOptions
    
    // MARK: - Initialization methods
    
    // :nodoc:
    public init(_ previewOptions: PreviewOptions = PreviewOptions()) {
        self.previewOptions = previewOptions
        
        super.init(nibName: nil, bundle: nil)
        
        bannerPresentationDelegate = self
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
        
        setupFloatingButtons()
        setupTopBannerContainerView()
        setupBottomBannerContainerView()
        setupConstraints()
        setupStyleManager()
        setupNavigationCamera()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Apply style each time `PreviewViewController` appears on screen
        // (e.g. after active navigation).
        styleManager.currentStyle?.apply()
        setupPassiveLocationManager()
        setupNavigationViewportDataSource()
        subscribeForNotifications()
        setupGestureRecognizers()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupOrnaments()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        unsubscribeFromNotifications()
        resetGestureRecognizers()
    }
    
    open override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        navigationView.setupTopBannerContainerViewHeightLayoutConstraints(topmostTopBanner?.bannerConfiguration.height)
        navigationView.setupBottomBannerContainerViewHeightLayoutConstraints(topmostBottomBanner?.bannerConfiguration.height)
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
    
    func setupFloatingButtons() {
        cameraModeFloatingButton = FloatingButton.rounded(imageEdgeInsets: UIEdgeInsets(floatLiteral: 12.0)) as CameraModeFloatingButton
        cameraModeFloatingButton.navigationMapView = navigationView.navigationMapView
        
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
    
    func setupNavigationCamera() {
        navigationView.navigationMapView.navigationCamera.move(to: .centered)
    }
    
    func setupGestureRecognizers() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGestureRecognizer.name = "preview_long_press_gesture_recognizer"
        navigationView.navigationMapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    func resetGestureRecognizers() {
        navigationView.navigationMapView.gestureRecognizers?.filter({ $0.name == "preview_long_press_gesture_recognizer" }).forEach {
            navigationView.navigationMapView.removeGestureRecognizer($0)
        }
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
    
    // MARK: - Destination and routes preview methods
    
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
    public func preview(_ coordinate: CLLocationCoordinate2D,
                        animated: Bool = true,
                        duration: TimeInterval = 1.0,
                        animations: (() -> Void)? = nil,
                        completion: (() -> Void)? = nil) {
        preview(Waypoint(coordinate: coordinate),
                animated: animated,
                duration: duration,
                animations: animations,
                completion: completion)
    }
    
    // :nodoc:
    public func preview(_ waypoint: Waypoint,
                        animated: Bool = true,
                        duration: TimeInterval = 1.0,
                        animations: (() -> Void)? = nil,
                        completion: (() -> Void)? = nil) {
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
            push(destinationPreviewViewController,
                 animated: animated,
                 duration: duration,
                 animations: animations,
                 completion: {
                completion?()
            })
            
            let bannerDismissalViewController = BannerDismissalViewController()
            bannerDismissalViewController.delegate = self
            push(bannerDismissalViewController,
                 animated: animated,
                 duration: duration,
                 animations: animations)
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
                        animated: Bool = true,
                        duration: TimeInterval = 1.0,
                        animations: (() -> Void)? = nil,
                        completion: (() -> Void)? = nil) {
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
            push(routesPreviewViewController,
                 animated: animated,
                 duration: duration,
                 animations: animations)
        }
        
        showcase(routeResponse: routeResponse,
                 routeIndex: routeIndex,
                 animated: animated,
                 duration: duration,
                 completion: { _ in
            completion?()
        })
    }
    
    // :nodoc:
    public func showcase(routeResponse: RouteResponse,
                         routeIndex: Int = 0,
                         animated: Bool = true,
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
    
    @objc func didPressDebugButton() {
        // TODO: Implement debug view presentation.
    }
}

// MARK: - NavigationMapViewDelegate methods

extension PreviewViewController: NavigationMapViewDelegate {
    
    public func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        delegate?.previewViewController(self, didSelect: route)
    }
}

// MARK: - DestinationPreviewViewControllerDelegate, RoutesPreviewViewControllerDelegate and BannerDismissalViewControllerDelegate methods

extension PreviewViewController: DestinationPreviewViewControllerDelegate, RoutesPreviewViewControllerDelegate, BannerDismissalViewControllerDelegate {
    
    func didPressPreviewRoutesButton(_ destinationPreviewViewController: DestinationPreviewViewController) {
        delegate?.didPressPreviewRoutesButton(self)
    }
    
    func didPressBeginActiveNavigationButton(_ destinationPreviewViewController: DestinationPreviewViewController) {
        delegate?.didPressBeginActiveNavigationButton(self)
    }
    
    func didPressBeginActiveNavigationButton(_ routesPreviewViewController: RoutesPreviewViewController) {
        delegate?.didPressBeginActiveNavigationButton(self)
    }
    
    func didPressDismissBannerButton(_ bannerDismissalViewController: BannerDismissalViewController) {
        delegate?.didPressDismissBannerButton(self)
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
        if banner is DestinationPreviewViewController || banner is RoutesPreviewViewController {
            navigationView.wayNameView.hide()
            navigationView.speedLimitView.hide()
            navigationView.navigationMapView.navigationCamera.stop()
        }
        
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
        if banner is DestinationPreviewViewController {
            pointAnnotationManager?.annotations = []
        } else if banner is RoutesPreviewViewController {
            navigationView.navigationMapView.removeWaypoints()
            navigationView.navigationMapView.removeRoutes()
        }
        
        if topBanner(at: .bottomLeading) == nil {
            navigationView.wayNameView.show()
            navigationView.speedLimitView.show()
        }
        
        delegate?.previewViewController(self, didDismiss: banner)
    }
}
