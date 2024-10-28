import CarPlay
import Combine
import Foundation
import MapboxDirections
@_spi(Restricted) import MapboxMaps
import MapboxNavigationCore

/// ``CarPlayMapViewController`` is responsible for administering the Mapbox map, the interface styles and the map
/// template buttons to display on CarPlay.
/// - Important: Loading ``CarPlayMapViewController`` view will start a Free Drive session by default. You can change
/// default behavior using ``CarPlayMapViewController/startFreeDriveAutomatically`` property. For more information, see
/// the “[Pricing](https://docs.mapbox.com/ios/navigation/guides/pricing/)” guide.
open class CarPlayMapViewController: UIViewController {
    // MARK: UI Elements Configuration

    /// The view controller’s delegate, that is used by the ``CarPlayManager``.
    ///
    /// Do not overwrite this property and use ``CarPlayManagerDelegate`` methods directly.
    public weak var delegate: CarPlayMapViewControllerDelegate?

    /// Controls the styling of ``CarPlayMapViewController`` and its components.
    ///
    /// The style can be modified programmatically by using ``StyleManager/applyStyle(type:)``.
    public private(set) var styleManager: StyleManager?

    /// A very coarse location manager used for distinguishing between daytime and nighttime.
    fileprivate let coarseLocationManager: CLLocationManager = {
        let coarseLocationManager = CLLocationManager()
        coarseLocationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        return coarseLocationManager
    }()

    /// A view that displays the current speed limit.
    public var speedLimitView: SpeedLimitView!

    /// A view that displays the current road name.
    public var wayNameView: WayNameView!

    /// Session configuration that is used to track `CPContentStyle` related changes.
    var sessionConfiguration: CPSessionConfiguration!

    /// The interface styles available to ``styleManager`` for display.
    var styles: [Style] {
        didSet {
            styleManager?.styles = styles
        }
    }

    @MainActor
    var navigationMapView: NavigationMapView {
        return view as! NavigationMapView
    }

    /// An optional metadata to be provided as initial value of `NavigationEventsManager.userInfo` property.
    public var userInfo: [String: String?]?

    /// Controls whether ``CarPlayMapViewController`` starts a Free Drive session automatically on map load.
    ///
    /// If you set this property to false, you can start a Free Drive session using
    /// ``CarPlayMapViewController/startFreeDriveNavigation()`` method.
    public var startFreeDriveAutomatically: Bool = true

    // MARK: Bar Buttons Configuration

    /// The map button for recentering the map view if a user action causes it to stop following the user.
    public lazy var recenterButton: CPMapButton = {
        let recenter = CPMapButton { [weak self] button in
            self?.navigationMapView.navigationCamera.update(cameraState: .following)
            button.isHidden = true
        }

        let bundle = Bundle.mapboxNavigation
        recenter.image = UIImage(named: "carplay_locate", in: bundle, compatibleWith: traitCollection)

        return recenter
    }()

    /// The map button for zooming in the current map view.
    public lazy var zoomInButton: CPMapButton = {
        let zoomInButton = CPMapButton { [weak self] _ in
            guard let self else { return }

            let mapView = navigationMapView.mapView
            navigationMapView.navigationCamera.stop()

            var cameraOptions = CameraOptions(cameraState: mapView.mapboxMap.cameraState)
            cameraOptions.zoom = mapView.mapboxMap.cameraState.zoom + 1.0
            mapView.mapboxMap.setCamera(to: cameraOptions)
        }

        let bundle = Bundle.mapboxNavigation
        zoomInButton.image = UIImage(named: "carplay_plus", in: bundle, compatibleWith: traitCollection)

        return zoomInButton
    }()

    /// The map button for zooming out the current map view.
    public lazy var zoomOutButton: CPMapButton = {
        let zoomOutButton = CPMapButton { [weak self] _ in
            guard let self else { return }
            let mapView = navigationMapView.mapView
            navigationMapView.navigationCamera.stop()

            var cameraOptions = CameraOptions(cameraState: mapView.mapboxMap.cameraState)
            cameraOptions.zoom = mapView.mapboxMap.cameraState.zoom - 1.0
            mapView.mapboxMap.setCamera(to: cameraOptions)
        }

        let bundle = Bundle.mapboxNavigation
        zoomOutButton.image = UIImage(named: "carplay_minus", in: bundle, compatibleWith: traitCollection)

        return zoomOutButton
    }()

    /// The map button property for hiding or showing the pan map button.
    public internal(set) var panMapButton: CPMapButton?

    /// The map button property for exiting the pan map mode.
    public internal(set) var dismissPanningButton: CPMapButton?

    /// Creates a new pan map button for the CarPlay map view controller.
    /// - Parameter mapTemplate: The map template available to the pan map button for display.
    /// - Returns: `CPMapButton` instance.
    @discardableResult
    public func panningInterfaceDisplayButton(for mapTemplate: CPMapTemplate) -> CPMapButton {
        let panButton = CPMapButton { [weak mapTemplate] _ in
            guard let mapTemplate else { return }
            if !mapTemplate.isPanningInterfaceVisible {
                mapTemplate.showPanningInterface(animated: true)
            }
        }

        let bundle = Bundle.mapboxNavigation
        panButton.image = UIImage(named: "carplay_pan", in: bundle, compatibleWith: traitCollection)

        return panButton
    }

    /// Creates a new close button to dismiss the visible panning buttons on the map.
    ///
    /// - Parameter mapTemplate: The map template available to the pan map button for display.
    /// - returns: `CPMapButton` instance.
    @discardableResult
    public func panningInterfaceDismissalButton(for mapTemplate: CPMapTemplate) -> CPMapButton {
        let defaultButtons = mapTemplate.mapButtons
        let closeButton = CPMapButton { [weak mapTemplate] _ in
            guard let mapTemplate else { return }

            mapTemplate.mapButtons = defaultButtons
            mapTemplate.dismissPanningInterface(animated: true)
        }

        let bundle = Bundle.mapboxNavigation
        closeButton.image = UIImage(named: "carplay_close", in: bundle, compatibleWith: traitCollection)

        return closeButton
    }

    private var safeTrailingSpeedLimitViewConstraint: NSLayoutConstraint!
    private var trailingSpeedLimitViewConstraint: NSLayoutConstraint!

    // MARK: Initialization Methods

    private var mapMatchingStateCancellable: AnyCancellable?
    private let core: MapboxNavigation

    ///  Initializes a new CarPlay map view controller.
    /// - Parameters:
    ///   - core: The entry point for interacting with the Mapbox Navigation SDK.
    ///   - styles: The interface styles initially available to the style manager for display.
    public init(
        core: MapboxNavigation,
        styles: [Style]
    ) {
        self.core = core
        self.styles = styles
        super.init(nibName: nil, bundle: nil)
        self.sessionConfiguration = CPSessionConfiguration(delegate: self)
    }

    /// Returns nil.
    /// - Parameter decoder: An unarchiver object.
    /// - Important:  The `CarPlayMapViewController`` creation with the decoder is not supported.
    public required init?(coder decoder: NSCoder) {
        assertionFailure("The `CarPlayMapViewController`` creation with the decoder is not supported.")
        return nil
    }

    deinit {
        unsubscribeFromFreeDriveNotifications()
    }

    private var lifetimeSubscriptions: Set<AnyCancellable> = []

    func setupNavigationMapView() {
        let location = core.navigation().locationMatching.map(\.enhancedLocation).eraseToAnyPublisher()
        let routeProgress = core.navigation().routeProgress.map { $0?.routeProgress }.eraseToAnyPublisher()
        let navigationMapView = NavigationMapView(
            location: location,
            routeProgress: routeProgress,
            navigationCameraType: .carPlay
        )

        navigationMapView.delegate = self
        navigationMapView.mapView.mapboxMap.onStyleLoaded.sink { [weak navigationMapView] _ in
            navigationMapView?.localizeLabels()
        }.store(in: &lifetimeSubscriptions)

        navigationMapView.puckType = .puck2D(.navigationDefault)

        navigationMapView.mapView.ornaments.options.logo.visibility = .hidden
        navigationMapView.mapView.ornaments.options.attributionButton.visibility = .hidden
        navigationMapView.mapView.ornaments.options.compass.visibility = .hidden

        view = navigationMapView
    }

    func setupStyleManager() {
        styleManager = StyleManager(traitCollection: UITraitCollection(userInterfaceIdiom: .carPlay))
        styleManager?.delegate = self
        styleManager?.styles = styles
    }

    func setupSpeedLimitView() {
        let speedLimitView = SpeedLimitView()
        speedLimitView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(speedLimitView)

        speedLimitView.topAnchor.constraint(equalTo: view.safeTopAnchor, constant: 8).isActive = true
        safeTrailingSpeedLimitViewConstraint = speedLimitView.trailingAnchor.constraint(
            equalTo: view.safeTrailingAnchor,
            constant: -8
        )
        trailingSpeedLimitViewConstraint = speedLimitView.trailingAnchor.constraint(
            equalTo: view.trailingAnchor,
            constant: -8
        )
        speedLimitView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        speedLimitView.heightAnchor.constraint(equalToConstant: 30).isActive = true

        self.speedLimitView = speedLimitView
    }

    func setupWayNameView() {
        let wayNameView: WayNameView = .forAutoLayout()
        wayNameView.containerView.isHidden = true
        wayNameView.containerView.clipsToBounds = true
        wayNameView.label.textAlignment = .center
        view.addSubview(wayNameView)

        NSLayoutConstraint.activate([
            wayNameView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor, constant: -8),
            wayNameView.centerXAnchor.constraint(equalTo: view.safeCenterXAnchor),
            wayNameView.widthAnchor.constraint(lessThanOrEqualTo: view.safeWidthAnchor, multiplier: 0.95),
            wayNameView.heightAnchor.constraint(equalToConstant: 30.0),
        ])

        self.wayNameView = wayNameView
    }

    /// Starts a Free Drive session if it is not started already.
    ///
    /// Free Drive session starts automatically on map load by default. You can change this behavior using
    /// ``CarPlayMapViewController/startFreeDriveAutomatically`` method.
    ///
    /// - Note: Paused Free Drive sessions are not resumed by this method.
    public func startFreeDriveNavigation() {
        core.tripSession().startFreeDrive()
        subscribeForFreeDriveNotifications()
    }

    // MARK: Notifications Observer Methods

    func subscribeForFreeDriveNotifications() {
        mapMatchingStateCancellable = core.navigation().locationMatching.sink { [weak self] state in
            self?.didUpdatePassiveLocation(state)
        }
    }

    func unsubscribeFromFreeDriveNotifications() {
        mapMatchingStateCancellable?.cancel()
    }

    func didUpdatePassiveLocation(_ state: MapMatchingState) {
        if let speedLimitView {
            speedLimitView.signStandard = state.speedLimit.signStandard
            speedLimitView.speedLimit = state.speedLimit.value

            speedLimitView.currentSpeed = state.enhancedLocation.speed
        }

        if let wayNameView {
            let roadNameFromStatus = state.roadName?.text
            if let roadName = roadNameFromStatus?.nonEmptyString {
                wayNameView.label.updateRoad(
                    roadName: roadName,
                    representation: state.roadName?.routeShieldRepresentation,
                    idiom: .carPlay
                )
                wayNameView.containerView.isHidden = false
            } else {
                wayNameView.text = nil
                wayNameView.containerView.isHidden = true
            }
        }
    }

    // MARK: UIViewController Lifecycle Methods

    override public func loadView() {
        setupNavigationMapView()
        if startFreeDriveAutomatically, core.tripSession().currentSession.state == .idle {
            startFreeDriveNavigation()
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        setupStyleManager()
        setupSpeedLimitView()
        setupWayNameView()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        applyStyleIfNeeded(sessionConfiguration.contentStyle)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Whenever `CarPlayMapViewController` appears on a screen - switch camera to the following
        // mode.

        navigationMapView.update(navigationCameraState: .following)
    }

    func applyStyleIfNeeded(_ contentStyle: CPContentStyle) {
        if contentStyle.contains(.dark) {
            styleManager?.applyStyle(type: .night)
        } else if contentStyle.contains(.light) {
            styleManager?.applyStyle(type: .day)
        }
    }

    override public func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()

        // Trigger update of view constraints to correctly position views like `SpeedLimitView`.
        view.setNeedsUpdateConstraints()
        guard let routes = core.tripSession().currentNavigationRoutes else {
            return
        }

        if navigationMapView.navigationCamera.currentCameraState == .idle {
            var cameraOptions = CameraOptions(cameraState: navigationMapView.mapView.mapboxMap.cameraState)
            cameraOptions.pitch = 0
            navigationMapView.mapView.mapboxMap.setCamera(to: cameraOptions)

            navigationMapView.showcase(
                routes,
                routeAnnotationKinds: [.relativeDurationsOnAlternativeManuever]
            )
        }
    }

    override public func updateViewConstraints() {
        if view.safeAreaInsets.right > 38.0 {
            safeTrailingSpeedLimitViewConstraint.isActive = true
            trailingSpeedLimitViewConstraint.isActive = false
        } else {
            safeTrailingSpeedLimitViewConstraint.isActive = false
            trailingSpeedLimitViewConstraint.isActive = true
        }

        super.updateViewConstraints()
    }
}

// MARK: StyleManagerDelegate Methods

extension CarPlayMapViewController: StyleManagerDelegate {
    public func location(for styleManager: StyleManager) -> CLLocation? {
        var latestLocation: CLLocation? = nil
        if let coordinate = navigationMapView.mapView.location.latestLocation?.coordinate {
            latestLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }

        return latestLocation ?? coarseLocationManager.location
    }

    public func styleManager(_ styleManager: StyleManager, didApply style: Style) {
        let styleURI = StyleURI(url: style.mapStyleURL)
        style.applyMapStyle(to: navigationMapView)

        wayNameView?.label.updateStyle(styleURI: styleURI, idiom: .carPlay)
    }

    public func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) {
        guard let mapboxMap = navigationMapView.mapView.mapboxMap,
              let styleURI = mapboxMap.styleURI else { return }

        mapboxMap.loadStyle(styleURI)
    }
}

// MARK: NavigationMapViewDelegate Methods

extension CarPlayMapViewController: NavigationMapViewDelegate {
    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        didAdd finalDestinationAnnotation: PointAnnotation,
        pointAnnotationManager: PointAnnotationManager
    ) {
        delegate?.carPlayMapViewController(
            self,
            didAdd: finalDestinationAnnotation,
            pointAnnotationManager: pointAnnotationManager
        )
    }

    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        shapeFor waypoints: [Waypoint],
        legIndex: Int
    ) -> FeatureCollection? {
        delegate?.carPlayMapViewController(
            self,
            shapeFor: waypoints,
            legIndex: legIndex
        )
    }

    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        waypointCircleLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> CircleLayer? {
        delegate?.carPlayMapViewController(
            self,
            waypointCircleLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier
        )
    }

    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        waypointSymbolLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> SymbolLayer? {
        delegate?.carPlayMapViewController(
            self,
            waypointSymbolLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier
        )
    }

    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        routeLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        delegate?.carPlayMapViewController(
            self,
            routeLineLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier
        )
    }

    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        routeCasingLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        delegate?.carPlayMapViewController(
            self,
            routeCasingLineLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier
        )
    }

    public func navigationMapView(
        _ navigationMapView: NavigationMapView,
        routeRestrictedAreasLineLayerWithIdentifier identifier: String,
        sourceIdentifier: String
    ) -> LineLayer? {
        delegate?.carPlayMapViewController(
            self,
            routeRestrictedAreasLineLayerWithIdentifier: identifier,
            sourceIdentifier: sourceIdentifier
        )
    }

    public func navigationMapView(_ navigationMapView: NavigationMapView, willAdd layer: Layer) -> Layer? {
        delegate?.carPlayMapViewController(self, willAdd: layer)
    }
}

extension CarPlayMapViewController: CPSessionConfigurationDelegate {
    public func sessionConfiguration(
        _ sessionConfiguration: CPSessionConfiguration,
        contentStyleChanged contentStyle: CPContentStyle
    ) {
        applyStyleIfNeeded(contentStyle)
    }
}
