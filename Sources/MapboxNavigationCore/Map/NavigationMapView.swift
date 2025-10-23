import _MapboxNavigationHelpers
import Combine
import MapboxDirections
import MapboxMaps
import UIKit

/// `NavigationMapView` is a subclass of `UIView`, which draws `MapView` on its surface and provides
/// convenience functions for adding ``NavigationRoutes`` lines to a map.
@MainActor
open class NavigationMapView: UIView {
    private enum Constants {
        static let initialMapRect = CGRect(x: 0, y: 0, width: 64, height: 64)
        static let initialViewportPadding = UIEdgeInsets(top: 20, left: 20, bottom: 40, right: 20)
    }

    /// The `MapView` instance added on top of ``NavigationMapView`` renders navigation-related components.
    public let mapView: MapView

    /// ``NavigationCamera``, which allows to control camera states.
    public let navigationCamera: NavigationCamera
    let mapStyleManager: NavigationMapStyleManager

    /// The object that acts as the navigation delegate of the map view.
    public weak var delegate: NavigationMapViewDelegate?

    private var lifetimeSubscriptions: Set<AnyCancellable> = []
    private var viewportDebugView: UIView?

    // Vanishing route line properties
    var routePoints: RoutePoints?
    var routeLineGranularDistances: RouteLineGranularDistances?
    var routeRemainingDistancesIndex: Int?

    private(set) var routes: NavigationRoutes?

    /// The gesture recognizer, that is used to detect taps on waypoints and routes that are currently
    /// present on the map. Enabled by default.
    public internal(set) var mapViewTapGestureRecognizer: UITapGestureRecognizer!

    /// Provides the possibility to use the manual layer order calculation approach.
    /// This property is`true` by default. Change this value to test a new rendering approach.
    @_spi(ExperimentalMapboxAPI)
    public var useLegacyManualLayersOrderApproach: Bool {
        get { !mapStyleManager.shouldUseDeclarativeApproach }
        set { mapStyleManager.shouldUseDeclarativeApproach = !newValue }
    }

    /// The current navigation style content being used.
    /// Returns `nil` if the declarative map style is not used.
    /// Set `NavigationMapView.useLegacyManualLayersOrderApproach` to `false` in order to enable it.
    public var currentNavigationStyleContent: NavigationStyleContent? {
        mapStyleManager.currentNavigationStyleContent
    }

    /// A Boolean value that determines whether the declarative map content should be automatically set by the Nav SDK.
    /// Setting this to `false` allows manual control over the declarative map content.
    /// You would need to set the content by subscribing to the ``NavigationMapView/navigationStyleContent`` updates.
    /// This property is`true` by default.
    /// Set `NavigationMapView.useLegacyManualLayersOrderApproach`` to `false` in order to enable the declarative
    /// styling approach.
    public var automaticallySetDeclarativeMapContent: Bool {
        get { !mapStyleManager.automaticallySetDeclarativeMapContent }
        set { mapStyleManager.automaticallySetDeclarativeMapContent = newValue }
    }

    /// A publisher that emits updates to the current navigation style content.
    ///
    /// Subscribers can observe this publisher to be notified when the ``NavigationStyleContent`` changes.
    /// Set `NavigationMapView.useLegacyManualLayersOrderApproach` to `false` in order to enable the declarative
    /// styling approach.
    public var navigationStyleContent: AnyPublisher<NavigationStyleContent?, Never> {
        mapStyleManager.navigationStyleContent
    }

    /// Initializes ``NavigationMapView`` instance.
    /// - Parameters:
    ///   - location: A publisher that emits current user location.
    ///   - routeProgress: A publisher that emits route navigation progress.
    ///   - navigationCameraType: The type of ``NavigationCamera``. Defaults to ``NavigationCameraType/mobile``.
    ///   which is used for the current instance of ``NavigationMapView``.
    ///   - heading: A publisher that emits current user heading. Defaults to `nil.`
    ///   - predictiveCacheManager: An instance of ``PredictiveCacheManager`` used to continuously cache upcoming map
    /// tiles.
    public convenience init(
        location: AnyPublisher<CLLocation, Never>,
        routeProgress: AnyPublisher<RouteProgress?, Never>,
        navigationCameraType: NavigationCameraType = .mobile,
        heading: AnyPublisher<CLHeading, Never>? = nil,
        predictiveCacheManager: PredictiveCacheManager? = nil
    ) {
        self.init(
            location: location,
            routeProgress: routeProgress,
            navigationCameraType: navigationCameraType,
            heading: heading,
            predictiveCacheManager: predictiveCacheManager,
            useLegacyManualLayersOrderApproach: false
        )
    }

    /// Initializes ``NavigationMapView`` instance.
    /// - Parameters:
    ///   - location: A publisher that emits current user location.
    ///   - routeProgress: A publisher that emits route navigation progress.
    ///   - navigationCameraType: The type of ``NavigationCamera``. Defaults to ``NavigationCameraType/mobile``.
    ///   which is used for the current instance of ``NavigationMapView``.
    ///   - heading: A publisher that emits current user heading. Defaults to `nil.`
    ///   - predictiveCacheManager: An instance of ``PredictiveCacheManager`` used to continuously cache upcoming map
    /// tiles.
    ///   - useLegacyManualLayersOrderApproach: Provides the possibility to use the manual layer order calculation
    /// approach.
    @_spi(ExperimentalMapboxAPI)
    public init(
        location: AnyPublisher<CLLocation, Never>,
        routeProgress: AnyPublisher<RouteProgress?, Never>,
        navigationCameraType: NavigationCameraType = .mobile,
        heading: AnyPublisher<CLHeading, Never>? = nil,
        predictiveCacheManager: PredictiveCacheManager? = nil,
        useLegacyManualLayersOrderApproach: Bool = false
    ) {
        self.mapView = MapView(frame: Constants.initialMapRect).autoresizing()
        mapView.location.override(
            locationProvider: location.map { [Location(clLocation: $0)] }.eraseToSignal(),
            headingProvider: heading?.map { Heading(from: $0) }.eraseToSignal()
        )

        self.mapStyleManager = .init(
            mapView: mapView,
            customRouteLineLayerPosition: customRouteLineLayerPosition,
            shouldUseDeclarativeApproach: !useLegacyManualLayersOrderApproach
        )
        self.navigationCamera = NavigationCamera(
            mapView,
            location: location,
            routeProgress: routeProgress,
            heading: heading,
            navigationCameraType: navigationCameraType
        )
        super.init(frame: Constants.initialMapRect)

        mapStyleManager.customizedLayerProvider = customizedLayerProvider
        mapStyleManager.delegate = self
        setupMapView()
        observeCamera()
        enablePredictiveCaching(with: predictiveCacheManager)
        subscribeToNavigatonUpdates(routeProgress)
    }

    private var currentRouteProgress: RouteProgress?

    // MARK: - Initialization

    private func subscribeToNavigatonUpdates(
        _ routeProgressPublisher: AnyPublisher<RouteProgress?, Never>
    ) {
        routeProgressPublisher
            .sink { [weak self] routeProgress in
                switch routeProgress {
                case nil:
                    self?.currentRouteProgress = routeProgress
                    self?.removeRoutes()
                case let routeProgress?:
                    guard let self else {
                        return
                    }
                    let alternativesUpdated = routeProgress.navigationRoutes.alternativeRoutes.map(\.routeId) != routes?
                        .alternativeRoutes.map(\.routeId)
                    if routes == nil || routeProgress.routeId != routes?.mainRoute.routeId
                        || alternativesUpdated
                    {
                        show(
                            routeProgress.navigationRoutes,
                            routeAnnotationKinds: showsRelativeDurationsOnAlternativeManuever ?
                                [.relativeDurationsOnAlternativeManuever] : []
                        )
                        delegate?.navigationMapView(
                            self,
                            didAddRedrawActiveGuidanceRoutes: routeProgress.navigationRoutes
                        )
                    }

                    currentRouteProgress = routeProgress
                    updateRouteLine(routeProgress: routeProgress)
                }
            }
            .store(in: &lifetimeSubscriptions)

        routeProgressPublisher
            .compactMap { $0 }
            .removeDuplicates { $0.legIndex == $1.legIndex }
            .sink { [weak self] _ in
                self?.updateWaypointsVisiblity()
            }.store(in: &lifetimeSubscriptions)
    }

    /// `PointAnnotationManager`, which is used to manage addition and removal of a final destination annotation.
    /// `PointAnnotationManager` will become valid only after fully loading `MapView` style.
    @available(
        *,
        deprecated,
        message: "This property is deprecated and should no longer be used, as the final destination annotation is no longer added to the map. Use 'AnnotationOrchestrator.makePointAnnotationManager()' to create your own annotation manager instead. For more information see the following guide: https://docs.mapbox.com/ios/maps/guides/markers-and-annotations/annotations/#markers"
    )
    public private(set) var pointAnnotationManager: PointAnnotationManager?

    private func setupMapView() {
        addSubview(mapView)
        mapView.pinEdgesToSuperview()
        mapView.gestures.delegate = self
        mapView.ornaments.options.scaleBar.visibility = .hidden
        mapView.preferredFramesPerSecond = 60

        mapView.location.onPuckRender.sink { [weak self] data in
            self?.travelAlongRouteLine(to: data.location.coordinate)
        }.store(in: &lifetimeSubscriptions)
        setupGestureRecognizers()
        setupUserLocation()
    }

    private func observeCamera() {
        navigationCamera.cameraStates
            .sink { [weak self] cameraState in
                guard let self else { return }
                updateIntersectionLaneGuidance(routeProgress: currentRouteProgress)
                delegate?.navigationMapView(self, didChangeCameraState: cameraState)
            }.store(in: &lifetimeSubscriptions)
    }

    @available(*, unavailable)
    override public init(frame: CGRect) {
        fatalError("NavigationMapView.init(frame:) is unavailable")
    }

    @available(*, unavailable)
    public init() {
        fatalError("NavigationMapView.init() is unavailable")
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("NavigationMapView.init(coder:) is unavailable")
    }

    override open func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        updateCameraPadding()
    }

    // MARK: - Public configuration

    /// The padding applied to the viewport in addition to the safe area.
    public var viewportPadding: UIEdgeInsets = Constants.initialViewportPadding {
        didSet { updateCameraPadding() }
    }

    @_spi(MapboxInternal) public var showsViewportDebugView: Bool = false {
        didSet { updateDebugViewportVisibility() }
    }

    /// Controls whether to show annotations on intersections, e.g. traffic signals, railroad crossings, yield and stop
    /// signs. Defaults to `true`.
    public var showsIntersectionAnnotations: Bool = true {
        didSet {
            updateIntersectionAnnotations(routeProgress: currentRouteProgress)
            mapStyleManager.mapStyleDeclarativeContentUpdate()
        }
    }

    /// Controls whether to show lane guidance callouts on intersections. Defaults to `false`.
    @_spi(MapboxInternal)
    public var showsIntersectionLaneGuidance: Bool = false {
        didSet {
            updateIntersectionLaneGuidance(routeProgress: currentRouteProgress)
        }
    }

    /// Toggles displaying alternative routes. If enabled, view will draw actual alternative route lines on the map.
    /// Defaults to `true`.
    public var showsAlternatives: Bool = true {
        didSet {
            updateAlternatives(routeProgress: currentRouteProgress)
        }
    }

    /// Toggles displaying relative ETA callouts on alternative routes, during active guidance.
    /// Defaults to `true`.
    public var showsRelativeDurationsOnAlternativeManuever: Bool = true {
        didSet {
            if showsRelativeDurationsOnAlternativeManuever {
                routeAnnotationKinds = [.relativeDurationsOnAlternativeManuever]
            } else {
                routeAnnotationKinds.removeAll()
            }
            updateAlternatives(routeProgress: currentRouteProgress)
        }
    }

    /// Controls whether the main route style layer and its casing disappears as the user location puck travels over it.
    /// Defaults to `true`.
    ///
    /// If `true`, the part of the route that has been traversed will be rendered with full transparency, to give the
    /// illusion of a disappearing route. If `false`, the whole route will be shown without traversed part disappearing
    /// effect.
    public var routeLineTracksTraversal: Bool = true

    /// The maximum distance (in screen points) the user can tap for a selection to be valid when selecting a POI.
    public var poiClickableAreaSize: CGFloat = 40

    /// Controls whether to show restricted portions of a route line. Defaults to true.
    public var showsRestrictedAreasOnRoute: Bool = true

    /// Decreases route line opacity based on occlusion from 3D objects.
    /// Value `0` disables occlusion, value `1` means fully occluded. Defaults to `0.85`.
    public var routeLineOcclusionFactor: Double = 0.85

    /// Configuration for displaying congestion levels on the route line.
    /// Allows to customize the congestion colors and ranges that represent different congestion levels.
    public var congestionConfiguration: CongestionConfiguration = .default

    /// Controls whether the traffic should be drawn on the route line or not. Defaults to true.
    public var showsTrafficOnRouteLine: Bool = true

    /// Maximum distance (in screen points) the user can tap for a selection to be valid when selecting an alternate
    /// route.
    public var tapGestureDistanceThreshold: CGFloat = 50

    /// Controls whether the voice instructions should be drawn on the route line or not. Defaults to `false`.
    public var showsVoiceInstructionsOnMap: Bool = false {
        didSet {
            updateVoiceInstructionsVisiblity()
        }
    }

    /// Controls whether intermediate waypoints displayed on the route line. Defaults to `true`.
    public var showsIntermediateWaypoints: Bool = true {
        didSet {
            updateWaypointsVisiblity()
        }
    }

    /// Specifies how the map displays the user’s current location, including the appearance and underlying
    /// implementation.
    ///
    /// By default, this property is set to `PuckType.puck3D(.navigationDefault)` , the bearing source is location
    /// course.
    public var puckType: PuckType? = .puck3D(.navigationDefault) {
        didSet { setupUserLocation() }
    }

    /// Specifies if a `Puck` should use `Heading` or `Course` for the bearing. Defaults to `PuckBearing.course`.
    public var puckBearing: PuckBearing = .course {
        didSet { setupUserLocation() }
    }

    /// A custom route line layer position.
    public var customRouteLineLayerPosition: MapboxMaps.LayerPosition? {
        didSet {
            mapStyleManager.customRouteLineLayerPosition = customRouteLineLayerPosition
        }
    }

    // MARK: RouteLine Customization

    /// Configures the route line color for the main route.
    /// If set, overrides the `.unknown` and `.low` traffic colors.
    @objc public dynamic var routeColor: UIColor {
        get {
            congestionConfiguration.colors.mainRouteColors.unknown
        }
        set {
            congestionConfiguration.colors.mainRouteColors.unknown = newValue
            congestionConfiguration.colors.mainRouteColors.low = newValue
        }
    }

    /// Configures the route line color for alternative routes.
    /// If set, overrides the `.unknown` and `.low` traffic colors.
    @objc public dynamic var routeAlternateColor: UIColor {
        get {
            congestionConfiguration.colors.alternativeRouteColors.unknown
        }
        set {
            congestionConfiguration.colors.alternativeRouteColors.unknown = newValue
            congestionConfiguration.colors.alternativeRouteColors.low = newValue
        }
    }

    /// Configures the casing route line color for the main route.
    @objc public dynamic var routeCasingColor: UIColor = .defaultRouteCasing
    /// Configures the casing route line color for alternative routes.
    @objc public dynamic var routeAlternateCasingColor: UIColor = .defaultAlternateLineCasing
    /// Configures the color for restricted areas on the route line.
    @objc public dynamic var routeRestrictedAreaColor: UIColor = .defaultRouteRestrictedAreaColor
    /// Configures the color for the traversed part of the main route. The traversed part is rendered only if the color
    /// is not `nil`.
    /// Defaults to `nil`.
    @objc public dynamic var traversedRouteColor: UIColor?
    /// Configures the color of the maneuver arrow.
    @objc public dynamic var maneuverArrowColor: UIColor = .defaultManeuverArrow
    /// Configures the stroke color of the maneuver arrow.
    @objc public dynamic var maneuverArrowStrokeColor: UIColor = .defaultManeuverArrowStroke

    // MARK: Route Annotations Customization

    /// Configures the color of the route annotation background (selected state).
    @objc public dynamic var routeAnnotationSelectedColor: UIColor =
        .defaultSelectedRouteAnnotationColor
    /// Configures the color of the route annotation background (not selected state).
    @objc public dynamic var routeAnnotationColor: UIColor = .defaultRouteAnnotationColor
    /// Configures the text color of the route annotation primary text (selected state).
    @objc public dynamic var routeAnnotationSelectedTextColor: UIColor = .defaultSelectedRouteAnnotationTextColor
    /// Configures the text color of the route annotation caption text (selected state).
    @objc public dynamic var routeAnnotationSelectedCaptionTextColor: UIColor =
        .defaultSelectedRouteAnnotationCaptionTextColor
    /// Configures the text color of the route annotation primary text (not selected state).
    @objc public dynamic var routeAnnotationTextColor: UIColor = .defaultRouteAnnotationTextColor
    /// Configures the text color of the route annotation caption text (not selected state).
    @objc public dynamic var routeAnnotationCaptionTextColor: UIColor = .defaultRouteAnnotationCaptionTextColor
    /// Configures the text color of the route annotation for alternative routes when relative duration is greater then
    /// the main route.
    @available(
        *,
        deprecated,
        message: "Has no effect in current design. Use `routeAnnotationTextColor` and `routeAnnotationCaptionTextColor` instead."
    )
    @objc public dynamic var routeAnnotationMoreTimeTextColor: UIColor {
        set { deprecatedRouteAnnotationMoreTimeTextColor = newValue }
        get { deprecatedRouteAnnotationMoreTimeTextColor }
    }

    @_spi(MapboxInternal)
    @objc public dynamic var deprecatedRouteAnnotationMoreTimeTextColor: UIColor =
        .defaultRouteAnnotationMoreTimeTextColor

    /// Configures the text color of the route annotation for alternative routes when relative duration is lesser then
    /// the main route.
    @available(
        *,
        deprecated,
        message: "Has no effect in current design. Use `routeAnnotationTextColor` and `routeAnnotationCaptionTextColor` instead."
    )
    @objc public dynamic var routeAnnotationLessTimeTextColor: UIColor {
        set { deprecatedRouteAnnotationLessTimeTextColor = newValue }
        get { deprecatedRouteAnnotationLessTimeTextColor }
    }

    @_spi(MapboxInternal)
    @objc public dynamic var deprecatedRouteAnnotationLessTimeTextColor: UIColor =
        .defaultRouteAnnotationLessTimeTextColor
    /// Configures the text font of the route annotations.
    @objc public dynamic var routeAnnotationTextFont: UIFont = .defaultRouteAnnotationTextFont
    /// Configures the secondary text font of the route annotations.
    @objc public dynamic var routeAnnotationCaptionTextFont: UIFont = .defaultRouteAnnotationCaptionTextFont
    /// Configures the waypoint color.
    @objc public dynamic var waypointColor: UIColor = .defaultWaypointColor
    /// Configures the waypoint stroke color.
    @objc public dynamic var waypointStrokeColor: UIColor = .defaultWaypointStrokeColor

    // MARK: Route callouts customization

    /// Enables the experimental API for custom route callouts.
    ///
    /// When enabled, route callouts will be created using the `routeCalloutViewProvider` instead of
    /// the default annotation approach. Must be set to `true` to use custom route callouts.
    /// Defaults to `false`.
    @_spi(ExperimentalMapboxAPI)
    public var apiRouteCalloutViewProviderEnabled = false

    /// A provider that creates route callout views displayed on the map.
    ///
    /// Use this property to customize the appearance and behavior of route callouts, which display
    /// information like estimated travel times, toll information, etc. The provider is responsible for
    /// creating appropriate callout views for each route.
    ///
    /// To use custom route callouts:
    /// 1. Set `apiRouteCalloutViewProviderEnabled` to `true`
    /// 2. Assign your custom provider or use ``DefaultRouteCalloutViewProvider``
    ///
    /// New ``showRoutes(_:)`` and ``showcaseRoutes(_:routesPresentationStyle:animated:duration:)`` methods
    /// are available without `routeAnnotationKinds` parameter but original methods ``show(_:routeAnnotationKinds:)``
    /// and ``showcase(_:routesPresentationStyle:routeAnnotationKinds:animated:duration:)``
    /// also work and their `routeAnnotationKinds` parameter is ignored.
    ///
    /// For default Mapbox-styled route callouts, you can use the ``DefaultRouteCalloutViewProvider`` class:
    /// ```swift
    /// navigationMapView.apiRouteCalloutViewProviderEnabled = true
    /// let sessionController = navigationProvider.mapboxNavigation.tripSession()
    /// navigationMapView.routeCalloutViewProvider =
    ///     DefaultRouteCalloutViewProvider(sessionController: sessionController)
    ///
    /// navigationMapView.showRoutes(routes)
    /// // or
    /// navigationMapView.showcaseRoutes(routes, routesPresentationStyle: .all())
    /// ```
    @_spi(ExperimentalMapboxAPI)
    public var routeCalloutViewProvider: RouteCalloutViewProvider? {
        didSet {
            if let defaultProvider = routeCalloutViewProvider as? DefaultRouteCalloutViewProvider {
                defaultProvider.mapStyleConfig = mapStyleConfig
            }
        }
    }

    // MARK: - Public methods

    /// Updates the inner navigation camera state.
    /// - Parameter navigationCameraState: The navigation camera state. See ``NavigationCameraState`` for the
    /// possible values.
    public func update(navigationCameraState: NavigationCameraState) {
        guard navigationCameraState != navigationCamera.currentCameraState else { return }
        navigationCamera.update(cameraState: navigationCameraState)
    }

    /// Updates road alerts in the free drive state. In active navigation road alerts are taken automatically from the
    /// currently set route.
    /// - Parameter roadObjects: An array of road objects to be displayed.
    public func updateFreeDriveAlertAnnotations(_ roadObjects: [RoadObjectAhead]) {
        mapStyleManager.updateFreeDriveAlertsAnnotations(
            roadObjects: roadObjects,
            excludedRouteAlertTypes: excludedRouteAlertTypes
        )
        mapStyleManager.mapStyleDeclarativeContentUpdate()
    }

    // MARK: Customizing and Displaying the Route Line(s)

    /// Visualizes the given main route and its alternatives, removing any existing from the map.
    ///
    /// Each route is visualized as a line. Each line is color-coded by traffic congestion, if congestion levels are
    /// present.
    /// Waypoints along the route are visualized as markers.
    /// To only visualize the routes and not the waypoints, or to have more control over the camera,
    /// use the ``show(_:routeAnnotationKinds:)`` method.
    ///
    /// If experimental route callouts API is enabled with `apiRouteCalloutViewProviderEnabled` set to `true`
    /// then `routeAnnotationKinds` parameter is ignored and `routeCalloutViewProvider`
    /// will be used to create route callouts which will be displayed. If it is `nil` no callouts will be displayed.
    ///
    /// - parameter navigationRoutes: ``NavigationRoutes`` containing routes to visualize. The selected route by
    /// `routeIndex` is considered primary, while the remaining routes are displayed as if they are currently deselected
    /// or inactive.
    /// - parameter routesPresentationStyle: Route lines presentation style. By default the map will be
    /// updated to fit all routes.
    /// - parameter routeAnnotationKinds: A set of ``RouteAnnotationKind`` that should be displayed. Defaults to
    /// ``RouteAnnotationKind/relativeDurationsOnAlternative``.
    /// - parameter animated: `true` to asynchronously animate the camera, or `false` to instantaneously
    /// zoom and pan the map. Defaults to `false`.
    /// - parameter duration: Duration of the animation (in seconds). In case if `animated` parameter
    /// is set to `false` this value is ignored. Defaults to `1`.
    public func showcase(
        _ navigationRoutes: NavigationRoutes,
        routesPresentationStyle: RoutesPresentationStyle = .all(),
        routeAnnotationKinds: Set<RouteAnnotationKind> = [.relativeDurationsOnAlternative],
        animated: Bool = false,
        duration: TimeInterval = 1.0
    ) {
        show(navigationRoutes, routeAnnotationKinds: routeAnnotationKinds)

        fitCamera(
            routes: navigationRoutes,
            routesPresentationStyle: routesPresentationStyle,
            animated: animated,
            duration: duration
        )
    }

    /// Visualizes the given main route and its alternatives, removing any existing from the map.
    ///
    /// Each route is visualized as a line. Each line is color-coded by traffic congestion, if congestion levels are
    /// present.
    /// Waypoints along the route are visualized as markers.
    /// To only visualize the routes and not the waypoints, or to have more control over the camera,
    /// use the ``showRoutes(_:)`` method.
    ///
    /// If experimental route callouts API is enabled with `apiRouteCalloutViewProviderEnabled` set to `true`
    /// `routeCalloutViewProvider` will be used to create route callouts which will be displayed.
    /// If it is `nil` no callouts will be displayed. Also no callouts are displayed in case when
    /// `apiRouteCalloutViewProviderEnabled` is set to `false`.
    ///
    /// - parameter navigationRoutes: ``NavigationRoutes`` containing routes to visualize. The selected route by
    /// `routeIndex` is considered primary, while the remaining routes are displayed as if they are currently deselected
    /// or inactive.
    /// - parameter routesPresentationStyle: Route lines presentation style. By default the map will be
    /// updated to fit all routes.
    /// - parameter animated: `true` to asynchronously animate the camera, or `false` to instantaneously
    /// zoom and pan the map. Defaults to `false`.
    /// - parameter duration: Duration of the animation (in seconds). In case if `animated` parameter
    /// is set to `false` this value is ignored. Defaults to `1`.
    @_spi(ExperimentalMapboxAPI)
    public func showcaseRoutes(
        _ navigationRoutes: NavigationRoutes,
        routesPresentationStyle: RoutesPresentationStyle = .all(),
        animated: Bool = false,
        duration: TimeInterval = 1.0
    ) {
        showcase(
            navigationRoutes,
            routesPresentationStyle: routesPresentationStyle,
            routeAnnotationKinds: Set<RouteAnnotationKind>(),
            animated: animated,
            duration: duration
        )
    }

    private(set) var routeAnnotationKinds: Set<RouteAnnotationKind> = []

    /// Represents a set of ``RoadAlertType`` values that should be hidden from the map display.
    /// By default, this is an empty set, which indicates that all road alerts will be displayed.
    ///
    /// - Note: If specific `RoadAlertType` values are added to this set, those alerts will be
    ///   excluded from the map rendering.
    public var excludedRouteAlertTypes: RoadAlertType = [] {
        didSet {
            mapStyleManager.updateRouteAlertsAnnotations(
                navigationRoutes: routes,
                excludedRouteAlertTypes: excludedRouteAlertTypes
            )
            mapStyleManager.mapStyleDeclarativeContentUpdate()
        }
    }

    /// Visualizes the given main route and its alternatives, removing any existing from the map.
    ///
    /// Each route is visualized as a line. Each line is color-coded by traffic congestion, if congestion
    /// levels are present. To also visualize waypoints and zoom the map to fit,
    /// use the ``showcase(_:routesPresentationStyle:routeAnnotationKinds:animated:duration:)`` method.
    ///
    /// If experimental route callouts API is enabled with `apiRouteCalloutViewProviderEnabled` set to `true`
    /// then `routeAnnotationKinds` parameter is ignored and `routeCalloutViewProvider`
    /// will be used to create route callouts which will be displayed. If it is `nil` no callouts will be displayed.
    ///
    /// To undo the effects of this method, use ``removeRoutes()`` method.
    /// - Parameters:
    ///   - navigationRoutes: ``NavigationRoutes`` to be displayed on the map.
    ///   - routeAnnotationKinds: A set of ``RouteAnnotationKind`` that should be displayed.
    public func show(
        _ navigationRoutes: NavigationRoutes,
        routeAnnotationKinds: Set<RouteAnnotationKind>
    ) {
        removeRoutes()

        routes = navigationRoutes
        routeRemainingDistancesIndex = nil
        self.routeAnnotationKinds = routeAnnotationKinds
        let mainRoute = navigationRoutes.mainRoute.route
        if routeLineTracksTraversal {
            initPrimaryRoutePoints(route: mainRoute)
        }
        mapStyleManager.showRoutes(
            routes,
            routeProgress: currentRouteProgress,
            annotationKinds: routeAnnotationKinds,
            config: mapStyleConfig,
            routelineFeatureProvider: customRouteLineFeatureProvider,
            waypointFeatureProvider: waypointsFeatureProvider,
            routeCalloutViewProvider: routeCalloutViewProvider
        )
    }

    /// Visualizes the given main route and its alternatives, removing any existing from the map.
    ///
    /// Each route is visualized as a line. Each line is color-coded by traffic congestion, if congestion
    /// levels are present. To also visualize waypoints and zoom the map to fit,
    /// use the ``showcaseRoutes(_:routesPresentationStyle:animated:duration:)`` method.
    ///
    /// If experimental route callouts API is enabled with `apiRouteCalloutViewProviderEnabled` set to `true`
    /// `routeCalloutViewProvider` will be used to create route callouts which will be displayed.
    /// If it is `nil` no callouts will be displayed. Also no callouts are displayed in case when
    /// `apiRouteCalloutViewProviderEnabled` is set to `false`.
    ///
    /// To undo the effects of this method, use ``removeRoutes()`` method.
    /// - Parameters:
    ///   - navigationRoutes: ``NavigationRoutes`` to be displayed on the map.
    @_spi(ExperimentalMapboxAPI)
    public func showRoutes(_ navigationRoutes: NavigationRoutes) {
        show(navigationRoutes, routeAnnotationKinds: Set<RouteAnnotationKind>())
    }

    /// Removes routes and all visible annotations from the map.
    public func removeRoutes() {
        routes = nil
        routeLineGranularDistances = nil
        routeRemainingDistancesIndex = nil
        mapStyleManager.removeAllFeatures()
    }

    func updateArrow(routeProgress: RouteProgress) {
        mapStyleManager.updateArrows(
            routeProgress: routeProgress,
            config: mapStyleConfig
        )
        mapStyleManager.mapStyleDeclarativeContentUpdate()
    }

    // MARK: - Debug Viewport

    private func updateDebugViewportVisibility() {
        if showsViewportDebugView {
            let viewportDebugView = with(UIView(frame: .zero)) {
                $0.layer.borderWidth = 1
                $0.layer.borderColor = UIColor.blue.cgColor
                $0.backgroundColor = .clear
            }
            addSubview(viewportDebugView)
            self.viewportDebugView = viewportDebugView
            viewportDebugView.isUserInteractionEnabled = false
            updateViewportDebugView()
        } else {
            viewportDebugView?.removeFromSuperview()
            viewportDebugView = nil
        }
    }

    private func updateViewportDebugView() {
        viewportDebugView?.frame = bounds.inset(by: navigationCamera.viewportPadding)
    }

    // MARK: - Camera

    private func updateCameraPadding() {
        let padding = viewportPadding
        let safeAreaInsets = safeAreaInsets

        navigationCamera.viewportPadding = .init(
            top: safeAreaInsets.top + padding.top,
            left: safeAreaInsets.left + padding.left,
            bottom: safeAreaInsets.bottom + padding.bottom,
            right: safeAreaInsets.right + padding.right
        )
        updateViewportDebugView()
    }

    private func fitCamera(
        routes: NavigationRoutes,
        routesPresentationStyle: RoutesPresentationStyle,
        animated: Bool = false,
        duration: TimeInterval
    ) {
        navigationCamera.stop()
        let coordinates: [CLLocationCoordinate2D]
        switch routesPresentationStyle {
        case .main, .all(shouldFit: false):
            coordinates = routes.mainRoute.route.shape?.coordinates ?? []
        case .all(true):
            let routes = [routes.mainRoute.route] + routes.alternativeRoutes.map(\.route)
            coordinates = MultiLineString(routes.compactMap(\.shape?.coordinates)).coordinates.flatMap { $0 }
        }
        let initialCameraOptions = CameraOptions(
            padding: navigationCamera.viewportPadding,
            bearing: 0,
            pitch: 0
        )
        do {
            let cameraOptions = try mapView.mapboxMap.camera(
                for: coordinates,
                camera: initialCameraOptions,
                coordinatesPadding: nil,
                maxZoom: nil,
                offset: nil
            )
            mapView.camera.ease(to: cameraOptions, duration: animated ? duration : 0.0)
        } catch {
            Log.error("Failed to fit the camera: \(error.localizedDescription)", category: .navigationUI)
        }
    }

    // MARK: - Localization

    /// Attempts to localize labels into the preferred language.
    ///
    /// This method automatically modifies the `SymbolLayer.textField` property of any symbol style
    /// layer whose source is the [Mapbox Streets
    /// source](https://docs.mapbox.com/vector-tiles/reference/mapbox-streets-v8/#overview).
    /// The user can set the system’s preferred language in Settings, General Settings, Language & Region.
    ///
    /// This method avoids localizing road labels into the preferred language, in an effort
    /// to match road signage and the turn banner, which always display road names and exit destinations
    /// in the local language.
    ///
    /// - parameter locale: `Locale` in which the map will attempt to be localized.
    /// To use the system’s preferred language, if supported, specify nil. Defaults to `nil`.
    public func localizeLabels(locale: Locale? = nil) {
        guard let preferredLocale = locale ?? VectorSource
            .preferredMapboxStreetsLocale(for: nil) else { return }
        mapView.localizeLabels(into: preferredLocale)
    }

    private func updateVoiceInstructionsVisiblity() {
        mapStyleManager.updateVoiceInstructions(route: routes?.mainRoute.route, config: mapStyleConfig)
        mapStyleManager.mapStyleDeclarativeContentUpdate()
    }

    private var customRouteLineFeatureProvider: RouteLineFeatureProvider {
        .init { [weak self] identifier, sourceIdentifier in
            guard let self else { return nil }
            return delegate?.navigationMapView(
                self,
                routeLineLayerWithIdentifier: identifier,
                sourceIdentifier: sourceIdentifier
            )
        } customRouteCasingLineLayer: { [weak self] identifier, sourceIdentifier in
            guard let self else { return nil }
            return delegate?.navigationMapView(
                self,
                routeCasingLineLayerWithIdentifier: identifier,
                sourceIdentifier: sourceIdentifier
            )
        } customRouteRestrictedAreasLineLayer: { [weak self] identifier, sourceIdentifier in
            guard let self else { return nil }
            return delegate?.navigationMapView(
                self,
                routeRestrictedAreasLineLayerWithIdentifier: identifier,
                sourceIdentifier: sourceIdentifier
            )
        }
    }

    private var waypointsFeatureProvider: WaypointFeatureProvider {
        .init { [weak self] waypoints, legIndex in
            guard let self else { return nil }
            return delegate?.navigationMapView(self, shapeFor: waypoints, legIndex: legIndex)
        } customCirleLayer: { [weak self] identifier, sourceIdentifier in
            guard let self else { return nil }
            return delegate?.navigationMapView(
                self,
                waypointCircleLayerWithIdentifier: identifier,
                sourceIdentifier: sourceIdentifier
            )
        } customSymbolLayer: { [weak self] identifier, sourceIdentifier in
            guard let self else { return nil }
            return delegate?.navigationMapView(
                self,
                waypointSymbolLayerWithIdentifier: identifier,
                sourceIdentifier: sourceIdentifier
            )
        }
    }

    private var customizedLayerProvider: CustomizedLayerProvider {
        .init { [weak self] in
            guard let self else { return $0 }
            return customizedLayer($0)
        }
    }

    private func customizedLayer<T>(_ layer: T) -> T where T: Layer {
        guard let customizedLayer = delegate?.navigationMapView(self, willAdd: layer) else {
            return layer
        }
        guard let customizedLayer = customizedLayer as? T else {
            let message = "The customized layer should have the same layer type as the default layer."
            assertionFailure(message)
            Log.error(message, category: .navigationUI)
            return layer
        }
        return customizedLayer
    }

    private func updateWaypointsVisiblity() {
        mapStyleManager.updateWaypoints(
            routes: routes,
            legIndex: currentRouteProgress?.legIndex,
            config: mapStyleConfig,
            featureProvider: waypointsFeatureProvider
        )
        mapStyleManager.mapStyleDeclarativeContentUpdate()
    }

    // - MARK: User Tracking Features

    private func setupUserLocation() {
        mapView.location.options.puckType = puckType ?? .puck2D(.emptyPuck)
        mapView.location.options.puckBearing = puckBearing
        mapView.location.options.puckBearingEnabled = true
    }

    // MARK: Configuring Cache and Tiles Storage

    private var predictiveCacheMapObserver: MapboxMaps.Cancelable?

    /// Setups the Predictive Caching mechanism using provided Options.
    ///
    /// This will handle all the required manipulations to enable the feature and maintain it during the navigations.
    /// Once enabled, it will be present as long as `NavigationMapView` is retained.
    ///
    /// - parameter options: options, controlling caching parameters like area radius and concurrent downloading
    /// threads.
    private func enablePredictiveCaching(with predictiveCacheManager: PredictiveCacheManager?) {
        predictiveCacheMapObserver?.cancel()

        guard let predictiveCacheManager else {
            predictiveCacheMapObserver = nil
            return
        }

        predictiveCacheManager.updateMapControllers(mapView: mapView)
        predictiveCacheMapObserver = mapView.mapboxMap.onStyleLoaded.observe { [
            weak self,
            predictiveCacheManager
        ] _ in
            guard let self else { return }

            predictiveCacheManager.updateMapControllers(mapView: mapView)
        }
    }

    var routeCalloutAnchors: [ViewAnnotationAnchor] = [
        .bottomLeft, .bottomRight, .topLeft, .topRight,
    ]

    enum FixedRouteCalloutPosition: Equatable {
        /// Position is dynamic
        case disabled
        /// Modifier from 0.0 to 1.0 describing the position within the available range used for callouts
        case fixed(Double)
    }

    var fixedRouteCalloutPosition: FixedRouteCalloutPosition = .disabled {
        didSet {
            let validRange = 0.0...1.0
            if case .fixed(let position) = fixedRouteCalloutPosition, !validRange.contains(position) {
                assertionFailure("Position value out of range: \(position). Must be between 0.0 and 1.0.")
                fixedRouteCalloutPosition = .fixed(position.clamped(to: validRange))
            }
        }
    }

    @_spi(ExperimentalMapboxAPI)
    public var useLegacyEtaRouteAnnotations = false

    var mapStyleConfig: MapStyleConfig {
        .init(
            routeCasingColor: routeCasingColor,
            routeAlternateCasingColor: routeAlternateCasingColor,
            routeRestrictedAreaColor: routeRestrictedAreaColor,
            traversedRouteColor: traversedRouteColor,
            maneuverArrowColor: maneuverArrowColor,
            maneuverArrowStrokeColor: maneuverArrowStrokeColor,
            routeAnnotationSelectedColor: routeAnnotationSelectedColor,
            routeAnnotationColor: routeAnnotationColor,
            routeAnnotationSelectedTextColor: routeAnnotationSelectedTextColor,
            routeAnnotationTextColor: routeAnnotationTextColor,
            routeAnnotationSelectedCaptionTextColor: routeAnnotationSelectedCaptionTextColor,
            routeAnnotationCaptionTextColor: routeAnnotationCaptionTextColor,
            routeAnnotationMoreTimeTextColor: deprecatedRouteAnnotationMoreTimeTextColor,
            routeAnnotationLessTimeTextColor: deprecatedRouteAnnotationLessTimeTextColor,
            routeAnnotationTextFont: routeAnnotationTextFont,
            routeAnnnotationCaptionTextFont: routeAnnotationCaptionTextFont,
            routeLineTracksTraversal: routeLineTracksTraversal,
            isRestrictedAreaEnabled: showsRestrictedAreasOnRoute,
            showsTrafficOnRouteLine: showsTrafficOnRouteLine,
            showsAlternatives: showsAlternatives,
            showsIntermediateWaypoints: showsIntermediateWaypoints,
            showsVoiceInstructionsOnMap: showsVoiceInstructionsOnMap,
            showsIntersectionAnnotations: showsIntersectionAnnotations,
            showsIntersectionLaneGuidance: showsIntersectionLaneGuidance,
            occlusionFactor: .constant(routeLineOcclusionFactor),
            congestionConfiguration: congestionConfiguration,
            excludedRouteAlertTypes: excludedRouteAlertTypes,
            waypointColor: waypointColor,
            waypointStrokeColor: waypointStrokeColor,
            routeCalloutAnchors: routeCalloutAnchors,
            fixedRouteCalloutPosition: fixedRouteCalloutPosition,
            useLegacyEtaRouteAnnotations: useLegacyEtaRouteAnnotations,
            apiRouteCalloutViewProviderEnabled: apiRouteCalloutViewProviderEnabled
        )
    }
}

extension NavigationMapView: NavigationMapStyleManagerDelegate {
    func styleManager<T>(_ styleManager: NavigationMapStyleManager, layer: T) -> T? where T: Layer, T: MapStyleContent {
        guard let customizedLayer = delegate?.navigationMapView(self, willAdd: layer) else {
            return layer
        }
        guard let customizedLayer = customizedLayer as? T else {
            let message = "The customized layer should have the same layer type as the default layer."
            assertionFailure(message)
            Log.error(message, category: .navigationUI)
            return layer
        }
        return customizedLayer
    }
}
