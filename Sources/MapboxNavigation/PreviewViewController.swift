import UIKit
import CoreLocation
import MapboxCoreNavigation
import MapboxMaps
import MapboxDirections

// :nodoc:
open class PreviewViewController: UIViewController {
    
    var previousState: State? = nil
    
    var state: State = .browsing {
        didSet {
            updateInternalComponents(to: state)
        }
    }
    
    var routesPreviewCameraOptions: CameraOptions {
        let topInset: CGFloat
        let bottomInset: CGFloat
        let leftInset: CGFloat
        let rightInset: CGFloat
        let spacing: CGFloat = 50.0
        
        if traitCollection.verticalSizeClass == .regular {
            topInset = 150.0
            bottomInset = navigationView.bottomBannerContainerView.frame.height + spacing
            leftInset = view.safeAreaInsets.left + spacing
            rightInset = view.safeAreaInsets.right + spacing
        } else {
            topInset = 50.0
            bottomInset = 50.0
            leftInset = navigationView.bottomBannerContainerView.frame.width + spacing
            rightInset = view.safeAreaInsets.right + spacing
        }
        
        let padding = UIEdgeInsets(top: topInset,
                                   left: leftInset,
                                   bottom: bottomInset,
                                   right: rightInset)
        
        let pitch = 0.0
        
        return CameraOptions(padding: padding, pitch: pitch)
    }
    
    var backButton: BackButton!
    
    // :nodoc:
    public var navigationView: NavigationView {
        view as! NavigationView
    }
    
    var speedLimitView: SpeedLimitView!
    
    var wayNameView: WayNameView!
    
    var finalDestinationAnnotations: [PointAnnotation]? = nil
    
    var pointAnnotationManager: PointAnnotationManager?
    
    var cameraFloatingButton: CameraFloatingButton!
    
    var styleManager: StyleManager!
    
    public private(set) var presentedBottomBannerViewController: UIViewController?
    
    var topBannerContainerViewHeightConstraint: NSLayoutConstraint!
    
    // :nodoc:
    public weak var delegate: PreviewViewControllerDelegate?
    
    open override func loadView() {
        let frame = parent?.view.bounds ?? UIScreen.main.bounds
        let navigationView = NavigationView(frame: frame)
        navigationView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        navigationView.navigationMapView.delegate = self
        navigationView.navigationMapView.userLocationStyle = .courseView()
        
        navigationView.navigationMapView.mapView.mapboxMap.onNext(.styleLoaded) { [weak self] _ in
            guard let self = self else { return }
            self.pointAnnotationManager = self.navigationView.navigationMapView.mapView.annotations.makePointAnnotationManager()
            
            if let finalDestinationAnnotations = self.finalDestinationAnnotations,
               let pointAnnotationManager = self.pointAnnotationManager {
                pointAnnotationManager.annotations = finalDestinationAnnotations
                
                self.finalDestinationAnnotations = nil
            }
        }
        
        view = navigationView
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackButton()
        setupSpeedLimitView()
        setupWayNameView()
        setupFloatingButtons()
        setupTopBannerContainerView()
        setupBottomBannerContainerView()
        
        setupNavigationViewportDataSource()
        setupPassiveLocationManager()
        setupStyleManager()
        setupOrnaments()
        setupGestureRecognizers()
        subscribeForNotifications()
        
        state = .browsing
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Style should be applied each time to prevent usage of the styles that were set via
        // `NavigationViewController`.
        styleManager.applyStyle()
    }
    
    func setupStyleManager() {
        styleManager = StyleManager()
        styleManager.delegate = self
        // styleManager.styles = [PreviewDayStyle()]
        // styleManager.styles = [PreviewNightStyle()]
        styleManager.styles = [PreviewDayStyle(), PreviewNightStyle()]
    }
    
    open override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        
        if topBannerContainerViewHeightConstraint != nil {
            let heightInset = view.safeAreaInsets.top
            topBannerContainerViewHeightConstraint.constant = heightInset
        }
    }
    
    func setupFloatingButtons() {
        navigationView.floatingStackView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor,
                                                                   constant: -10.0).isActive = true
        
        cameraFloatingButton = CameraFloatingButton(type: .system)
        cameraFloatingButton.delegate = self
        
        navigationView.floatingButtons = [
            cameraFloatingButton
        ]
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    // MARK: Notifications Observer Methods
    
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
        
        speedLimitView.signStandard = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.signStandardKey] as? SignStandard
        speedLimitView.speedLimit = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.speedLimitKey] as? Measurement<UnitSpeed>
        
        let roadNameFromStatus = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.roadNameKey] as? String
        if let roadName = roadNameFromStatus?.nonEmptyString {
            let representation = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.routeShieldRepresentationKey] as? VisualInstruction.Component.ImageRepresentation
            wayNameView.label.updateRoad(roadName: roadName, representation: representation)
            wayNameView.containerView.isHidden = false
        } else {
            wayNameView.text = nil
            wayNameView.containerView.isHidden = true
        }
        
        updateViewportDataSource(for: location)
    }
    
    @objc func orientationDidChange(_ notification: Notification) {
        let passiveLocationProvider = navigationView.navigationMapView.mapView.location.locationProvider as? PassiveLocationProvider
        updateViewportDataSource(for: passiveLocationProvider?.locationManager.location)
        
        // In case if routes are already shown and orientation changes - fit camera so that all
        // routes fit into available space.
        if case .routesPreviewing(let previewOptions) = state {
            fitCamera(to: previewOptions.routeResponse)
        }
    }
    
    func updateViewportDataSource(for location: CLLocation?) {
        guard let location = location,
              let navigationViewportDataSource = navigationView.navigationMapView.navigationCamera.viewportDataSource as? NavigationViewportDataSource else { return }
        
        let topInset: CGFloat = UIScreen.main.bounds.height - view.safeAreaInsets.bottom - 150.0
        let bottomInset: CGFloat = 149.0 + view.safeAreaInsets.bottom
        let leftInset: CGFloat = 50.0
        let rightInset: CGFloat = 50.0
        
        navigationViewportDataSource.followingMobileCamera.padding = UIEdgeInsets(top: topInset,
                                                                                  left: leftInset,
                                                                                  bottom: bottomInset,
                                                                                  right: rightInset)
        
        navigationViewportDataSource.followingMobileCamera.bearing = location.course
        navigationViewportDataSource.followingMobileCamera.pitch = 40.0
    }
    
    func addDestinationAnnotations(for coordinates: [CLLocationCoordinate2D]) {
        let markerImage = UIImage(named: "final_destination_pin", in: .mapboxNavigation, compatibleWith: nil)!
        
        let destinationAnnotations: [PointAnnotation] = coordinates.enumerated().map {
            let identifier = "\(NavigationMapView.AnnotationIdentifier.finalDestinationAnnotation)_\($0.offset)"
            var destinationAnnotation = PointAnnotation(id: identifier, coordinate: $0.element)
            destinationAnnotation.image = .init(image: markerImage, name: "default_marker")
            
            return destinationAnnotation
        }
        
        // If `PointAnnotationManager` is available - add `PointAnnotation`, if not - remember it
        // and add it only after fully loading `MapView` style.
        if let pointAnnotationManager = self.pointAnnotationManager {
            pointAnnotationManager.annotations = destinationAnnotations
        } else {
            finalDestinationAnnotations = destinationAnnotations
        }
    }
    
    // :nodoc:
    public func preview(_ waypoints: [Waypoint]) {
        let destinationOptions = DestinationOptions(waypoints: waypoints)
        state = .destinationPreviewing(destinationOptions)
        
        let coordinates = waypoints.map({ $0.coordinate })
        
        // TODO: Show intermediate waypoints differently.
        addDestinationAnnotations(for: coordinates)
        
        if let primaryText = destinationOptions.primaryText {
            let primaryAttributedString = NSAttributedString(string: primaryText)
            (presentedBottomBannerViewController as? DestinationPreviewViewController)?.destinationLabel.attributedText =
            delegate?.previewViewController(self, willPresent: primaryAttributedString) ?? primaryAttributedString
        }
    }
    
    // :nodoc:
    public func preview(_ coordinates: [CLLocationCoordinate2D]) {
        let destinationOptions = DestinationOptions(coordinates: coordinates)
        state = .destinationPreviewing(destinationOptions)
        
        // TODO: Show intermediate waypoints differently.
        addDestinationAnnotations(for: coordinates)
    }
    
    // :nodoc:
    public func preview(_ routeResponse: RouteResponse, routeIndex: Int = 0) {
        let routesPreviewOptions = RoutesPreviewOptions(routeResponse: routeResponse, routeIndex: routeIndex)
        state = .routesPreviewing(routesPreviewOptions)
        
        if let lastLeg = routesPreviewOptions.routeResponse.routes?.first?.legs.last,
           let destinationCoordinate = lastLeg.destination?.coordinate {
            addDestinationAnnotations(for: [destinationCoordinate])
        }
        
        showcase(routeResponse: routeResponse, routeIndex: routeIndex)
    }
    
    func showcase(routeResponse: RouteResponse, routeIndex: Int) {
        guard var routes = routeResponse.routes else { return }
        
        routes.insert(routes.remove(at: routeIndex), at: 0)
        
        navigationView.navigationMapView.showcase(routes,
                                                  routesPresentationStyle: .all(shouldFit: true,
                                                                                cameraOptions: routesPreviewCameraOptions))
    }
    
    // :nodoc:
    public func fitCamera(to routeResponse: RouteResponse?) {
        guard let routes = routeResponse?.routes else { return }
        
        navigationView.navigationMapView.navigationCamera.stop()
        navigationView.navigationMapView.fitCamera(to: routes,
                                                   routesPresentationStyle: .all(shouldFit: true,
                                                                                 cameraOptions: routesPreviewCameraOptions),
                                                   animated: true,
                                                   duration: 1.0)
    }
    
    func setupOrnaments() {
        navigationView.navigationMapView.mapView.ornaments.options.compass.visibility = .hidden
    }
    
    func updateInternalComponents(to state: State) {
        delegate?.previewViewController(self, stateDidChangeTo: state)
        
        switch state {
        case .browsing:
            backButton.isHidden = true
            pointAnnotationManager?.annotations = []
            navigationView.resumeButton.isHidden = true
            
            navigationView.navigationMapView.removeWaypoints()
            navigationView.navigationMapView.removeRoutes()
            
            // Speed limit, road name and floating buttons should be shown.
            speedLimitView.isAlwaysHidden = false
            wayNameView.isHidden = false
            
            cameraFloatingButton.cameraState = .following
            
            if let customBottomBannerViewController = delegate?.previewViewController(self,
                                                                                      bottomBannerViewControllerFor: state) {
                navigationView.bottomBannerContainerView.isHidden = false
                embed(customBottomBannerViewController, in: navigationView.bottomBannerContainerView)
                
                presentedBottomBannerViewController = customBottomBannerViewController
            } else {
                navigationView.bottomBannerContainerView.hide()
            }
        case .destinationPreviewing(let destinationOptions):
            // Speed limit, road name and floating buttons should be hidden.
            speedLimitView.isAlwaysHidden = true
            wayNameView.isHidden = true
            
            navigationView.navigationMapView.removeWaypoints()
            navigationView.navigationMapView.removeRoutes()
            
            navigationView.bottomBannerContainerView.show()
            backButton.isHidden = false
            
            navigationView.bottomBannerContainerView.subviews.forEach {
                $0.removeFromSuperview()
            }
            
            let destinationPreviewViewController: DestinationPreviewing
            if let customDestinationPreviewViewController = delegate?.previewViewController(self,
                                                                                            bottomBannerViewControllerFor: state) {
                guard let customDestinationPreviewViewController = customDestinationPreviewViewController as? DestinationPreviewing else {
                    preconditionFailure("UIViewController should conform to DestinationPreviewing protocol.")
                }
                
                destinationPreviewViewController = customDestinationPreviewViewController
            } else {
                destinationPreviewViewController = DestinationPreviewViewController(destinationOptions)
                (destinationPreviewViewController as? DestinationPreviewViewController)?.delegate = self
            }
            
            presentedBottomBannerViewController = destinationPreviewViewController
            embed(destinationPreviewViewController, in: navigationView.bottomBannerContainerView)
        case .routesPreviewing(let routesPreviewOptions):
            // Speed limit, road name and floating buttons should be hidden.
            speedLimitView.isAlwaysHidden = true
            wayNameView.isHidden = true
            
            navigationView.navigationMapView.removeWaypoints()
            navigationView.navigationMapView.removeRoutes()
            
            navigationView.bottomBannerContainerView.isHidden = false
            backButton.isHidden = false
            
            navigationView.bottomBannerContainerView.subviews.forEach {
                $0.removeFromSuperview()
            }
            
            let routesPreviewViewController: RoutesPreviewing
            if let customRoutesPreviewViewController = delegate?.previewViewController(self,
                                                                                       bottomBannerViewControllerFor: state) {
                guard let customRoutesPreviewViewController = customRoutesPreviewViewController as? RoutesPreviewing else {
                    preconditionFailure("UIViewController should conform to RoutesPreviewing protocol.")
                }
                
                routesPreviewViewController = customRoutesPreviewViewController
            } else {
                routesPreviewViewController = RoutesPreviewViewController(routesPreviewOptions)
                (routesPreviewViewController as? RoutesPreviewViewController)?.delegate = self
            }
            
            presentedBottomBannerViewController = routesPreviewViewController
            embed(routesPreviewViewController, in: navigationView.bottomBannerContainerView)
        }
    }
    
    public func setupNavigationViewportDataSource() {
        let navigationViewportDataSource = NavigationViewportDataSource(navigationView.navigationMapView.mapView,
                                                                        viewportDataSourceType: .passive)
        
        navigationViewportDataSource.options.followingCameraOptions.bearingUpdatesAllowed = false
        navigationViewportDataSource.options.followingCameraOptions.pitchUpdatesAllowed = false
        navigationViewportDataSource.options.followingCameraOptions.paddingUpdatesAllowed = false
        navigationView.navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
    }
    
    public func setupPassiveLocationManager() {
        let passiveLocationManager = PassiveLocationManager()
        let passiveLocationProvider = PassiveLocationProvider(locationManager: passiveLocationManager)
        navigationView.navigationMapView.mapView.location.overrideLocationProvider(with: passiveLocationProvider)
    }
    
    func setupSpeedLimitView() {
        let speedLimitView: SpeedLimitView = .forAutoLayout()
        navigationView.addSubview(speedLimitView)
        
        let speedLimitViewConstraints = [
            speedLimitView.topAnchor.constraint(equalTo: navigationView.topBannerContainerView.bottomAnchor,
                                                constant: 10),
            speedLimitView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                    constant: 10),
            speedLimitView.widthAnchor.constraint(equalToConstant: 50),
            speedLimitView.heightAnchor.constraint(equalToConstant: 50)
        ]
        
        NSLayoutConstraint.activate(speedLimitViewConstraints)
        
        self.speedLimitView = speedLimitView
    }
    
    func setupWayNameView() {
        let wayNameView: WayNameView = .forAutoLayout()
        wayNameView.containerView.clipsToBounds = true
        view.addSubview(wayNameView)
        
        let wayNameViewLayoutConstraints = [
            wayNameView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor,
                                                constant: -60.0),
            wayNameView.centerXAnchor.constraint(equalTo: view.safeCenterXAnchor),
            wayNameView.widthAnchor.constraint(lessThanOrEqualTo: view.safeWidthAnchor,
                                               multiplier: 0.95)
        ]
        
        NSLayoutConstraint.activate(wayNameViewLayoutConstraints)
        
        self.wayNameView = wayNameView
    }
    
    func setupBackButton() {
        let backButton = BackButton(type: .system)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.setTitle("Back", for: .normal)
        backButton.clipsToBounds = true
        backButton.addTarget(self, action: #selector(didPressBackButton), for: .touchUpInside)
        
        let backImage = UIImage(named: "back", in: .mapboxNavigation, compatibleWith: nil)!
        backButton.setImage(backImage, for: .normal)
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.imageEdgeInsets = UIEdgeInsets(top: 10,
                                                  left: 0,
                                                  bottom: 10,
                                                  right: 10)
        navigationView.addSubview(backButton)
        
        let backButtonLayoutConstraints = [
            backButton.widthAnchor.constraint(equalToConstant: 110),
            backButton.heightAnchor.constraint(equalToConstant: 50),
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                constant: 10.0),
            backButton.topAnchor.constraint(equalTo: navigationView.topBannerContainerView.bottomAnchor,
                                            constant: 10.0)
        ]
        
        NSLayoutConstraint.activate(backButtonLayoutConstraints)
        
        self.backButton = backButton
    }
    
    @objc func didPressBackButton() {
        if case let .destinationPreviewing(destinationOptions) = previousState {
            previousState = nil
            preview(destinationOptions.waypoints)
        } else if case .destinationPreviewing(_) = state {
            state = .browsing
        } else if case .routesPreviewing(_) = state {
            state = .browsing
        }
    }
    
    func setupTopBannerContainerView() {
        let topBannerContainerViewHeight = view.safeAreaInsets.top
        topBannerContainerViewHeightConstraint = navigationView.topBannerContainerView.heightAnchor.constraint(equalToConstant: topBannerContainerViewHeight)
        topBannerContainerViewHeightConstraint.isActive = true
        navigationView.topBannerContainerView.isHidden = false
        navigationView.topBannerContainerView.backgroundColor = .clear
    }
    
    func setupBottomBannerContainerView() {
        // Round top left and top right corners of the bottom container view.
        navigationView.bottomBannerContainerView.clipsToBounds = true
        navigationView.bottomBannerContainerView.layer.cornerRadius = 10.0
        navigationView.bottomBannerContainerView.layer.maskedCorners = [
            .layerMinXMinYCorner,
            .layerMaxXMinYCorner
        ]
        
        navigationView.bottomBannerContainerView.isHidden = true
        navigationView.bottomBannerContainerView.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        let bottomBannerContainerViewHeight = 120.0 + view.safeAreaInsets.bottom
        
        let bottomBannerContainerViewLayoutConstraints = [
            navigationView.bottomBannerContainerView.heightAnchor.constraint(equalToConstant: bottomBannerContainerViewHeight)
        ]
        
        NSLayoutConstraint.activate(bottomBannerContainerViewLayoutConstraints)
    }
    
    func setupGestureRecognizers() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        navigationView.addGestureRecognizer(longPressGestureRecognizer)
        
        // In case if map view is panned, rotated or pinched, camera state should be reset.
        for gestureRecognizer in navigationView.navigationMapView.mapView.gestureRecognizers ?? []
        where gestureRecognizer is UIPanGestureRecognizer
        || gestureRecognizer is UIRotationGestureRecognizer
        || gestureRecognizer is UIPinchGestureRecognizer {
            gestureRecognizer.addTarget(self, action: #selector(resetCameraState))
        }
    }
    
    // MARK: - Gesture recognizers
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began,
              let passiveLocationProvider = navigationView.navigationMapView.mapView.location.locationProvider as? PassiveLocationProvider,
              let originCoordinate = passiveLocationProvider.locationManager.location?.coordinate,
              case _ = State.browsing else { return }
        
        let destinationCoordinate = navigationView.navigationMapView.mapView.mapboxMap.coordinate(for: gesture.location(in: navigationView.navigationMapView.mapView))
        let coordinates = [
            originCoordinate,
            destinationCoordinate,
        ]
        
        delegate?.previewViewController(self, didLongPressFor: coordinates)
    }
    
    @objc func resetCameraState() {
        if cameraFloatingButton.cameraState == .idle { return }
        cameraFloatingButton.cameraState = .idle
    }
}

// MARK: - NavigationMapViewDelegate methods

extension PreviewViewController: NavigationMapViewDelegate {
    
    public func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        delegate?.previewViewController(self, didSelect: route)
    }
}

extension PreviewViewController: DestinationPreviewViewControllerDelegate, RoutesPreviewViewControllerDelegate {
    
    func didPressPreviewButton() {
        previousState = state
        delegate?.previewViewControllerWillPreviewRoutes(self)
    }
    
    func didPressStartButton() {
        delegate?.previewViewControllerWillBeginNavigation(self)
    }
}

extension PreviewViewController: CameraFloatingButtonDelegate {
    
    func cameraFloatingButton(_ cameraFloatingButton: CameraFloatingButton,
                              cameraStateDidChangeTo state: CameraFloatingButton.State) {
        switch state {
        case .idle:
            navigationView.navigationMapView.navigationCamera.stop()
            
            let passiveLocationProvider = navigationView.navigationMapView.mapView.location.locationProvider as? PassiveLocationProvider
            let centerCoordinate = passiveLocationProvider?.locationManager.location?.coordinate
            let padding = UIEdgeInsets(floatLiteral: 10.0)
            let cameraOptions = CameraOptions(center: centerCoordinate,
                                              padding: padding,
                                              bearing: 0.0,
                                              pitch: 0.0)
            navigationView.navigationMapView.mapView.camera.ease(to: cameraOptions,
                                                                 duration: 1.0)
        case .centered:
            let passiveLocationProvider = navigationView.navigationMapView.mapView.location.locationProvider as? PassiveLocationProvider
            let centerCoordinate = passiveLocationProvider?.locationManager.location?.coordinate
            let padding = UIEdgeInsets(floatLiteral: 10.0)
            let cameraOptions = CameraOptions(center: centerCoordinate,
                                              padding: padding)
            navigationView.navigationMapView.mapView.camera.ease(to: cameraOptions,
                                                                 duration: 1.0)
        case .following:
            navigationView.navigationMapView.navigationCamera.follow()
        }
    }
}

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
