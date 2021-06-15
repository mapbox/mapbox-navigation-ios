import UIKit
import MapboxMaps
import MapboxCoreMaps
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigationNative
import Turf

private enum RouteDurationAnnotationTailPosition: Int {
    case left
    case right
}

/**
 `NavigationMapView` is a subclass of `UIView`, which draws `MapView` on its surface and provides convenience functions for adding `Route` lines to a map.
 */
open class NavigationMapView: UIView {
    
    // MARK: Class constants
    
    struct FrameIntervalOptions {
        static let durationUntilNextManeuver: TimeInterval = 7
        static let durationSincePreviousManeuver: TimeInterval = 3
        static let defaultFramesPerSecond = PreferredFPS.normal
        static let pluggedInFramesPerSecond = PreferredFPS.maximum
    }
    
    /**
     The minimum preferred frames per second at which to render map animations.
     
     This property takes effect when the application has limited resources for animation, such as when the device is running on battery power. By default, this property is set to `PreferredFPS.normal`.
     */
    public var minimumFramesPerSecond = PreferredFPS.normal
    
    /**
     Maximum distance the user can tap for a selection to be valid when selecting an alternate route.
     */
    public var tapGestureDistanceThreshold: CGFloat = 50
    
    /**
     A collection of street road classes for which a congestion level substitution should occur.
     
     For any street road class included in the `roadClassesWithOverriddenCongestionLevels`, all route segments with an `CongestionLevel.unknown` traffic congestion level and a matching `MapboxDirections.MapboxStreetsRoadClass`
     will be replaced with the `CongestionLevel.low` congestion level.
     */
    public var roadClassesWithOverriddenCongestionLevels: Set<MapboxStreetsRoadClass>? = nil
    
    /**
     `NavigationCamera`, which allows to control camera states.
     */
    public private(set) var navigationCamera: NavigationCamera!
    
    /**
     Controls whether to show congestion levels on alternative route lines. Defaults to `false`.
     
     If `true` and there're multiple routes to choose, the alternative route lines would display the congestion levels at different colors, similar to the main route. To customize the congestion colors that represent different congestion levels, override the `alternativeTrafficUnknownColor`, `alternativeTrafficLowColor`, `alternativeTrafficModerateColor`, `alternativeTrafficHeavyColor`, `alternativeTrafficSevereColor` property for the `NavigationMapView.appearance()`.
     */
    public var showsCongestionForAlternativeRoutes: Bool = false

    @objc dynamic public var trafficUnknownColor: UIColor = .trafficUnknown
    @objc dynamic public var trafficLowColor: UIColor = .trafficLow
    @objc dynamic public var trafficModerateColor: UIColor = .trafficModerate
    @objc dynamic public var trafficHeavyColor: UIColor = .trafficHeavy
    @objc dynamic public var trafficSevereColor: UIColor = .trafficSevere
    @objc dynamic public var alternativeTrafficUnknownColor: UIColor = .alternativeTrafficUnknown
    @objc dynamic public var alternativeTrafficLowColor: UIColor = .alternativeTrafficLow
    @objc dynamic public var alternativeTrafficModerateColor: UIColor = .alternativeTrafficModerate
    @objc dynamic public var alternativeTrafficHeavyColor: UIColor = .alternativeTrafficHeavy
    @objc dynamic public var alternativeTrafficSevereColor: UIColor = .alternativeTrafficSevere
    
    @objc dynamic public var routeCasingColor: UIColor = .defaultRouteCasing
    @objc dynamic public var routeAlternateColor: UIColor = .defaultAlternateLine
    @objc dynamic public var routeAlternateCasingColor: UIColor = .defaultAlternateLineCasing
    @objc dynamic public var traversedRouteColor: UIColor = .defaultTraversedRouteColor
    @objc dynamic public var maneuverArrowColor: UIColor = .defaultManeuverArrow
    @objc dynamic public var maneuverArrowStrokeColor: UIColor = .defaultManeuverArrowStroke
    @objc dynamic public var buildingDefaultColor: UIColor = .defaultBuildingColor
    @objc dynamic public var buildingHighlightColor: UIColor = .defaultBuildingHighlightColor
    @objc dynamic public var intersectionAnnotationDefaultBackgroundColor: UIColor = .intersectionAnnotationDefaultBackgroundColor
    @objc dynamic public var intersectionAnnotationSelectedBackgroundColor: UIColor = .intersectionAnnotationSelectedBackgroundColor
    @objc dynamic public var intersectionAnnotationDefaultLabelColor: UIColor = .intersectionAnnotationDefaultLabelColor
    @objc dynamic public var intersectionAnnotationSelectedLabelColor: UIColor = .intersectionAnnotationSelectedLabelColor
    @objc dynamic public var intersectionAnnotationFontNames: [String] = ["DIN Pro Medium", "Noto Sans CJK JP Medium", "Arial Unicode MS Regular"]

    @objc dynamic public var reducedAccuracyActivatedMode: Bool = false {
        didSet {
            let frame = CGRect(origin: .zero, size: 75.0)
            let isHidden = userCourseView.isHidden
            switch userLocationStyle {
            case .courseView(let courseView):
                userCourseView = reducedAccuracyActivatedMode
                    ? UserHaloCourseView(frame: frame)
                    : courseView
            default:
                userCourseView = reducedAccuracyActivatedMode
                ? UserHaloCourseView(frame: frame)
                : UserPuckCourseView(frame: frame)
            }
            userCourseView.isHidden = isHidden
        }
    }
    
    @objc dynamic public var routeDurationAnnotationSelectedColor: UIColor = .selectedRouteDurationAnnotationColor
    @objc dynamic public var routeDurationAnnotationColor: UIColor = .routeDurationAnnotationColor
    @objc dynamic public var routeDurationAnnotationSelectedTextColor: UIColor = .selectedRouteDurationAnnotationTextColor
    @objc dynamic public var routeDurationAnnotationTextColor: UIColor = .routeDurationAnnotationTextColor

    /**
     List of Mapbox Maps font names to be used for any symbol layers added by the Navigation SDK.
     These are used for features such as Route Duration Annotations that are optionally added during route preview.
     See https://docs.mapbox.com/ios/maps/api/6.3.0/customizing-fonts.html for more information about server-side fonts.
     */
    @objc dynamic public var routeDurationAnnotationFontNames: [String] = [
        "DIN Pro Medium",
        "Noto Sans CJK JP Medium",
        "Arial Unicode MS Regular"
    ]
    
    /**
     `MapView`, which is added on top of `NavigationMapView` and allows to render navigation related components.
     */
    public private(set) var mapView: MapView!
    
    /**
     The object that acts as the navigation delegate of the map view.
     */
    public weak var delegate: NavigationMapViewDelegate?
    
    /**
     `PointAnnotationManager`, which is used to manage addition and removal of final destination annotation.
     `PointAnnotationManager` will become valid only after fully loading `MapView` style.
     */
    public var pointAnnotationManager: PointAnnotationManager?
    
    /**
     Most recent user location, which is used to place `UserCourseView`.
     */
    var mostRecentUserCourseViewLocation: CLLocation?
    
    var routes: [Route]?
    var routePoints: RoutePoints?
    var routeLineGranularDistances: RouteLineGranularDistances?
    var routeRemainingDistancesIndex: Int?
    var routeLineTracksTraversal: Bool = false
    var fractionTraveled: Double = 0.0
    var preFractionTraveled: Double = 0.0
    var vanishingRouteLineUpdateTimer: Timer? = nil
    var currentLegIndex: Int?
    
    var showsRoute: Bool {
        get {
            guard let mainRouteLayerIdentifier = routes?.first?.identifier(.route(isMainRoute: true)),
                  let mainRouteCasingLayerIdentifier = routes?.first?.identifier(.routeCasing(isMainRoute: true)) else { return false }
            
            let identifiers = [
                mainRouteLayerIdentifier,
                mainRouteCasingLayerIdentifier
            ]
            
            for identifier in identifiers {
                if !mapView.mapboxMap.style.layerExists(withId: identifier) {
                    return false
                }
            }

            return true
        }
    }
    
    /**
     A `UserCourseView` used to indicate the user’s location and course on the map.
     
     The `UserCourseView`'s `UserCourseView.update(location:pitch:direction:animated:)` method is frequently called to ensure that its visual appearance matches the map’s camera.
     */
    public var userCourseView: UserCourseView = UserPuckCourseView(frame: CGRect(origin: .zero, size: 75.0)) {
        didSet {
            oldValue.removeFromSuperview()
            installUserCourseView()
        }
    }
    
    var simulatesLocation: Bool = true
    
    /**
     Specifies how the map displays the user’s current location, including the appearance and underlying implementation.
     
     By default, this property is set to `UserLocationStyle.courseView`, the bearing source is location course.
     */
    public var userLocationStyle: UserLocationStyle = .courseView(UserPuckCourseView(frame: CGRect(origin: .zero, size: 75.0))) {
        didSet {
            setupUserLocation()
        }
    }
    
    /**
     A manager object, used to init and maintain predictive caching.
     */
    private(set) var predictiveCacheManager: PredictiveCacheManager?
    
    /**
     A `TileStore` instance used by map view.
     */
    open var mapTileStore: TileStore? {
        mapView.mapboxMap.resourceOptions.tileStore
    }
    
    /**
     Initializes a newly allocated `NavigationMapView` object with the specified frame rectangle.
     
     - parameter frame: The frame rectangle for the `NavigationMapView`.
     */
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupMapView(frame)
        commonInit()
    }
    
    /**
     Initializes a newly allocated `NavigationMapView` object with the specified frame rectangle and type of `NavigationCamera`.
     
     - parameter frame: The frame rectangle for the `NavigationMapView`.
     - parameter navigationCameraType: Type of `NavigationCamera`, which is used for the current instance of `NavigationMapView`.
     - parameter tileStoreLocation: Configuration of `TileStore` location, where Map tiles are stored. Use `nil` to disable onboard tile storage.
     */
    public init(frame: CGRect,
                navigationCameraType: NavigationCameraType = .mobile,
                tileStoreLocation: TileStoreConfiguration.Location? = .default) {
        super.init(frame: frame)
        
        setupMapView(frame, navigationCameraType: navigationCameraType, tileStoreLocation: tileStoreLocation)
        commonInit()
    }
    
    /**
     Returns a `NavigationMapView` object initialized from data in a given unarchiver.
     
     - parameter coder: An unarchiver object.
     */
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupMapView(self.bounds)
        commonInit()
    }
    
    fileprivate func commonInit() {
        makeGestureRecognizersResetFrameRate()
        setupGestureRecognizers()
        installUserCourseView()
        subscribeForNotifications()
        setupUserLocation()
    }
    
    func setupUserLocation() {
        mapView.mapboxMap.onNext(.styleLoaded) { [weak self] _ in
            guard let self = self else { return }
            switch self.userLocationStyle {
            case .courseView((let courseView)):
                self.mapView.location.options.puckType = nil
                self.userCourseView = courseView
                self.userCourseView.isHidden = false
            case .puck2D(configuration: var configuration):
                self.userCourseView.isHidden = true
                self.mapView.location.options.puckType = .puck2D(configuration ?? Puck2DConfiguration())
                configuration = configuration ?? Puck2DConfiguration()
            case .puck3D(configuration: let configuration):
                self.userCourseView.isHidden = true
                self.mapView.location.options.puckType = .puck3D(configuration)
            }
        }
        mapView.location.options.puckBearingSource = .course
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    func subscribeForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(navigationCameraStateDidChange(_:)),
                                               name: .navigationCameraStateDidChange,
                                               object: navigationCamera)
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .navigationCameraStateDidChange,
                                                  object: nil)
    }
    
    @objc func navigationCameraStateDidChange(_ notification: Notification) {
        guard let location = mostRecentUserCourseViewLocation,
              let navigationCameraState = notification.userInfo?[NavigationCamera.NotificationUserInfoKey.state] as? NavigationCameraState else { return }
        
        switch navigationCameraState {
        case .idle:
            break
        case .transitionToFollowing, .following, .transitionToOverview, .overview:
            moveUserLocation(to: location)
            break
        }
    }
    
    func setupMapView(_ frame: CGRect,
                      navigationCameraType: NavigationCameraType = .mobile,
                      tileStoreLocation: TileStoreConfiguration.Location? = .default) {
        let accessToken = ResourceOptionsManager.default.resourceOptions.accessToken
        
        // TODO: allow customising tile store location.
        let tileStore = tileStoreLocation?.tileStore
        
        // In case of CarPlay, use `pixelRatio` value, which is used on second `UIScreen`.
        var pixelRatio = UIScreen.main.scale
        if navigationCameraType == .carPlay, UIScreen.screens.indices.contains(1) {
            pixelRatio = UIScreen.screens[1].scale
        }
        
        let mapOptions = MapOptions(constrainMode: .widthAndHeight,
                                    viewportMode: .default,
                                    orientation: .upwards,
                                    crossSourceCollisions: false,
                                    optimizeForTerrain: false,
                                    size: nil,
                                    pixelRatio: pixelRatio,
                                    glyphsRasterizationOptions: .init())
        
        let resourceOptions = ResourceOptions(accessToken: accessToken,
                                              tileStore: tileStore)
        
        let mapInitOptions = MapInitOptions(resourceOptions: resourceOptions,
                                            mapOptions: mapOptions)
        
        mapView = MapView(frame: frame, mapInitOptions: mapInitOptions)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.ornaments.options.scaleBar.visibility = .hidden
        
        mapView.mapboxMap.onEvery(.renderFrameFinished) { [weak self] _ in
            guard let self = self,
                  let location = self.mostRecentUserCourseViewLocation else { return }
            self.moveUserLocation(to: location)
            
            switch self.userLocationStyle {
            case .courseView:
                if let locationProvider = self.mapView.location.locationProvider {
                    self.mapView.location.locationProvider(locationProvider, didUpdateLocations: [location])
                }
            default:
                if self.simulatesLocation, let locationProvider = self.mapView.location.locationProvider {
                    self.mapView.location.locationProvider(locationProvider, didUpdateLocations: [location])
                }
            }
        }
        
        mapView.mapboxMap.onNext(.styleLoaded) { [weak self] _ in
            guard let self = self else { return }
            self.pointAnnotationManager = self.mapView.annotations.makePointAnnotationManager()
        }

        mapView.mapboxMap.onNext(.mapLoaded, handler: { [weak self] _ in
            try? self?.updateAnnotationSymbolImages()
        })

        addSubview(mapView)
        
        mapView.pinTo(parentView: self)
        
        navigationCamera = NavigationCamera(mapView, navigationCameraType: navigationCameraType)
        navigationCamera.follow()
    }
    
    func setupGestureRecognizers() {
        // Gesture recognizer, which is used to detect taps on route line and waypoint.
        let mapViewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didReceiveTap(sender:)))
        mapViewTapGestureRecognizer.delegate = self
        mapView.addGestureRecognizer(mapViewTapGestureRecognizer)
    }
    
    /**
     Setups the Predictive Caching mechanism using provided Options.
     
     This will handle all the required manipulations to enable the feature and maintain it during the navigations. Once enabled, it will be present as long as `NavigationMapView` is retained.
     If `NavigationMapView` was not configured to maintain a tile storage - this function does nothing.
     
     - parameter options: options, controlling caching parameters like area radius and concurrent downloading threads.
     - parameter tileStoreConfiguration: configuration for tile storage parameters. If `nil` - default settings will be used.
     */
    public func enablePredictiveCaching(options predictiveCacheOptions: PredictiveCacheOptions, tileStoreConfiguration: TileStoreConfiguration?) {
        let styleSourcePaths = mapView.styleSourceDatasets(["raster", "vector"])
        
        if let tileStoreConfiguration = tileStoreConfiguration {
            let tileStoreMapOptions = PredictiveCacheManager.TileStoreMapOptions(tileStoreConfiguration,
                                                                                 styleSourcePaths)
                                                                                 
            
            predictiveCacheManager = PredictiveCacheManager(predictiveCacheOptions: predictiveCacheOptions,
                                                            tileStoreMapOptions: tileStoreMapOptions)
        } else if let tileStore = mapTileStore {
            let mapOptions = PredictiveCacheManager.MapOptions(tileStore,
                                                               styleSourcePaths)
            
            predictiveCacheManager = PredictiveCacheManager(predictiveCacheOptions: predictiveCacheOptions,
                                                            mapOptions: mapOptions)
        }
    }
    
    // MARK: - Overridden methods
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        // TODO: Verify that image is correctly drawn when `NavigationMapView` is created in storyboard.
        let image = UIImage(named: "feedback-map-error", in: .mapboxNavigation, compatibleWith: nil)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .center
        imageView.backgroundColor = .gray
        imageView.frame = bounds
        addSubview(imageView)
    }
    
    @objc private func resetFrameRate(_ sender: UIGestureRecognizer) {
        mapView.preferredFramesPerSecond = NavigationMapView.FrameIntervalOptions.defaultFramesPerSecond
    }
    
    /**
     Updates the map view’s preferred frames per second to the appropriate value for the current route progress.
     
     This method accounts for the proximity to a maneuver and the current power source.
     It has no effect if `NavigationCamera` is in `NavigationCameraState.following` state.
     
     - parameter routeProgress: Object, which stores current progress along specific route.
     */
    public func updatePreferredFrameRate(for routeProgress: RouteProgress) {
        guard navigationCamera.state == .following else { return }
        
        let stepProgress = routeProgress.currentLegProgress.currentStepProgress
        let expectedTravelTime = stepProgress.step.expectedTravelTime
        let durationUntilNextManeuver = stepProgress.durationRemaining
        let durationSincePreviousManeuver = expectedTravelTime - durationUntilNextManeuver
        
        var preferredFramesPerSecond = FrameIntervalOptions.defaultFramesPerSecond
        let maneuverDirections: [ManeuverDirection] = [.straightAhead, .slightLeft, .slightRight]
        if let maneuverDirection = routeProgress.currentLegProgress.upcomingStep?.maneuverDirection,
           maneuverDirections.contains(maneuverDirection) ||
            (durationUntilNextManeuver > FrameIntervalOptions.durationUntilNextManeuver &&
                durationSincePreviousManeuver > FrameIntervalOptions.durationSincePreviousManeuver) {
            preferredFramesPerSecond = UIDevice.current.isPluggedIn ? FrameIntervalOptions.pluggedInFramesPerSecond : minimumFramesPerSecond
        }
        
        mapView.preferredFramesPerSecond = preferredFramesPerSecond
    }
    
    // MARK: - User tracking methods
    
    func installUserCourseView() {
        userCourseView.isHidden = true
        mapView.addSubview(userCourseView)
    }
    
    /**
     Updates `UserLocationStyle` to provided location.
     
     - parameter location: Location, where `UserLocationStyle` should be shown.
     - parameter animated: Property, which determines whether `UserLocationStyle` transition to new location will be animated.
     */
    public func moveUserLocation(to location: CLLocation, animated: Bool = false) {
        guard CLLocationCoordinate2DIsValid(location.coordinate) else { return }
        
        mostRecentUserCourseViewLocation = location
        
        switch userLocationStyle {
        case .courseView:
            // While animating to overview mode, don't animate the puck.
            let duration: TimeInterval = animated && navigationCamera.state != .transitionToOverview ? 1 : 0
            UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear]) { [weak self] in
                guard let point = self?.mapView.point(for: location.coordinate) else { return }
                self?.userCourseView.center = point
            }
            
            let cameraOptions = CameraOptions(cameraState: mapView.cameraState)
            userCourseView.update(location: location,
                                  pitch: cameraOptions.pitch!,
                                  direction: cameraOptions.bearing!,
                                  animated: animated,
                                  navigationCameraState: navigationCamera.state)
            
        default: break
        }
    }
    
    // MARK: Feature addition/removal methods
    
    /**
     Showcases route array. Adds routes and waypoints to map, and sets camera to point encompassing the route.
     
     - parameter routes: List of `Route` objects, which will be shown on `MapView`.
     - parameter animated: Property, which determines whether camera movement will be animated while fitting first route.
     */
    public func showcase(_ routes: [Route], animated: Bool = false) {
        guard let activeRoute = routes.first,
              let coordinates = activeRoute.shape?.coordinates,
              !coordinates.isEmpty else { return }
        
        removeArrow()
        removeRoutes()
        removeWaypoints()
        
        show(routes)
        showWaypoints(on: activeRoute)
        
        navigationCamera.stop()
        fitCamera(to: activeRoute, animated: animated)
    }
    
    /**
     Adds main and alternative route lines and their casings on `MapView`. Prior to showing, previous
     route lines and their casings will be removed.
     
     - parameter routes: List of `Route` objects, which will be shown on `MapView`.
     - parameter legIndex: Index, which will be used to highlight specific `RouteLeg` on main route.
     */
    public func show(_ routes: [Route], legIndex: Int? = nil) {
        removeRoutes()
        
        self.routes = routes
        currentLegIndex = legIndex
        
        var parentLayerIdentifier: String? = nil
        for (index, route) in routes.enumerated() {
            if index == 0, routeLineTracksTraversal {
                initPrimaryRoutePoints(route: route)
            }
            
            parentLayerIdentifier = addRouteLayer(route, below: parentLayerIdentifier, isMainRoute: index == 0, legIndex: legIndex)
            parentLayerIdentifier = addRouteCasingLayer(route, below: parentLayerIdentifier, isMainRoute: index == 0)
        }
    }
    
    func fitCamera(to route: Route, animated: Bool = false) {
        guard let routeShape = route.shape, !routeShape.coordinates.isEmpty else { return }
        let edgeInsets = safeArea + UIEdgeInsets.centerEdgeInsets
        if let cameraOptions = mapView?.mapboxMap.camera(for: .lineString(routeShape),
                                                         padding: edgeInsets,
                                                         bearing: nil,
                                                         pitch: nil) {
            mapView?.mapboxMap.setCamera(to: cameraOptions)
        }
    }

    /**
     Sets initial `CameraOptions` for specific coordinate.
     
     - parameter coordinate: Coordinate, where `MapView` will be centered.
     */
    func setInitialCamera(_ coordinate: CLLocationCoordinate2D) {
        guard let navigationViewportDataSource = navigationCamera.viewportDataSource as? NavigationViewportDataSource else { return }
        
        mapView.mapboxMap.setCamera(to: CameraOptions(center: coordinate,
                                                   zoom: CGFloat(navigationViewportDataSource.options.followingCameraOptions.maximumZoomLevel)))
        moveUserLocation(to: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }

    @discardableResult func addRouteLayer(_ route: Route,
                                          below parentLayerIndentifier: String? = nil,
                                          isMainRoute: Bool = true,
                                          legIndex: Int? = nil) -> String? {
        guard let shape = route.shape else { return nil }
        
        let geoJSONSource = self.geoJSONSource(delegate?.navigationMapView(self, casingShapeFor: route) ?? shape)
        let sourceIdentifier = route.identifier(.source(isMainRoute: isMainRoute, isSourceCasing: true))
        
        do {
            try mapView.mapboxMap.style.addSource(geoJSONSource, id: sourceIdentifier)
        } catch {
            NSLog("Failed to add route source \(sourceIdentifier) with error: \(error.localizedDescription).")
        }
        
        let layerIdentifier = route.identifier(.route(isMainRoute: isMainRoute))
        var lineLayer = delegate?.navigationMapView(self,
                                                    routeLineLayerWithIdentifier: layerIdentifier,
                                                    sourceIdentifier: sourceIdentifier)
        
        if lineLayer == nil {
            lineLayer = LineLayer(id: layerIdentifier)
            lineLayer?.source = sourceIdentifier
            lineLayer?.lineColor = .constant(.init(color: trafficUnknownColor))
            lineLayer?.lineWidth = .expression(Expression.routeLineWidthExpression())
            lineLayer?.lineJoin = .constant(.round)
            lineLayer?.lineCap = .constant(.round)
            
            // TODO: Verify that `isAlternativeRoute` parameter usage is needed.
            if isMainRoute {
                let congestionFeatures = route.congestionFeatures(legIndex: legIndex, roadClassesWithOverriddenCongestionLevels: roadClassesWithOverriddenCongestionLevels)
                let gradientStops = routeLineGradient(congestionFeatures,
                                                      fractionTraveled: routeLineTracksTraversal ? fractionTraveled : 0.0)
                lineLayer?.lineGradient = .expression((Expression.routeLineGradientExpression(gradientStops, lineBaseColor: trafficUnknownColor)))
            } else {
                if showsCongestionForAlternativeRoutes {
                    let gradientStops = routeLineGradient(route.congestionFeatures(roadClassesWithOverriddenCongestionLevels: roadClassesWithOverriddenCongestionLevels),
                                                          fractionTraveled: routeLineTracksTraversal ? fractionTraveled : 0.0,
                                                          isMain: false)
                    lineLayer?.lineGradient = .expression((Expression.routeLineGradientExpression(gradientStops, lineBaseColor: trafficUnknownColor)))
                } else {
                    lineLayer?.lineColor = .constant(.init(color: routeAlternateColor))
                }
            }
        }
        
        if let lineLayer = lineLayer {
            do {
                var layerPosition: MapboxMaps.LayerPosition? = nil
                
                if isMainRoute {
                    if let aboveLayerIdentifier = mapView.mainRouteLineParentLayerIdentifier {
                        layerPosition = .above(aboveLayerIdentifier)
                    }
                } else {
                    if let belowLayerIdentifier = parentLayerIndentifier {
                        layerPosition = .below(belowLayerIdentifier)
                    }
                }
                
                try mapView.mapboxMap.style.addLayer(lineLayer, layerPosition: layerPosition)
            } catch {
                NSLog("Failed to add route layer \(layerIdentifier) with error: \(error.localizedDescription).")
            }
        }
        
        return layerIdentifier
    }
    
    @discardableResult func addRouteCasingLayer(_ route: Route, below parentLayerIndentifier: String? = nil, isMainRoute: Bool = true) -> String? {
        guard let shape = route.shape else { return nil }
        
        let geoJSONSource = self.geoJSONSource(delegate?.navigationMapView(self, shapeFor: route) ?? shape)
        let sourceIdentifier = route.identifier(.source(isMainRoute: isMainRoute, isSourceCasing: isMainRoute))
        do {
            try mapView.mapboxMap.style.addSource(geoJSONSource, id: sourceIdentifier)
        } catch {
            NSLog("Failed to add route casing source \(sourceIdentifier) with error: \(error.localizedDescription).")
        }
        
        let layerIdentifier = route.identifier(.routeCasing(isMainRoute: isMainRoute))
        var lineLayer = delegate?.navigationMapView(self,
                                                    routeCasingLineLayerWithIdentifier: layerIdentifier,
                                                    sourceIdentifier: sourceIdentifier)
        
        if lineLayer == nil {
            lineLayer = LineLayer(id: layerIdentifier)
            lineLayer?.source = sourceIdentifier
            lineLayer?.lineColor = .constant(.init(color: routeCasingColor))
            lineLayer?.lineWidth = .expression(Expression.routeLineWidthExpression(1.5))
            lineLayer?.lineJoin = .constant(.round)
            lineLayer?.lineCap = .constant(.round)
            
            if isMainRoute {
                let gradientStops = routeLineGradient(fractionTraveled: routeLineTracksTraversal ? fractionTraveled : 0.0)
                lineLayer?.lineGradient = .expression((Expression.routeLineGradientExpression(gradientStops, lineBaseColor: routeCasingColor)))
            } else {
                lineLayer?.lineColor = .constant(.init(color: routeAlternateCasingColor))
            }
        }
        
        if let lineLayer = lineLayer {
            do {
                var layerPosition: MapboxMaps.LayerPosition? = nil
                if let parentLayerIndentifier = parentLayerIndentifier {
                    layerPosition = .below(parentLayerIndentifier)
                }
                try mapView.mapboxMap.style.addLayer(lineLayer, layerPosition: layerPosition)
            } catch {
                NSLog("Failed to add route casing layer \(layerIdentifier) with error: \(error.localizedDescription).")
            }
        }
        
        return layerIdentifier
    }
    
    func geoJSONSource(_ shape: LineString) -> GeoJSONSource {
        var geoJSONSource = GeoJSONSource()
        geoJSONSource.data = .geometry(.lineString(shape))
        geoJSONSource.lineMetrics = true
        
        return geoJSONSource
    }
    
    /**
     Adds the route waypoints to the map given the current leg index. Previous waypoints for completed legs will be omitted.
     
     - parameter route: `Route`, on which a certain `Waypoint` will be shown.
     - parameter legIndex: Index, which determines for which `RouteLeg` `Waypoint` will be shown.
     */
    public func showWaypoints(on route: Route, legIndex: Int = 0) {
        let waypoints: [MapboxDirections.Waypoint] = Array(route.legs.dropLast().compactMap({ $0.destination }))

        var features = [Turf.Feature]()
        for (waypointIndex, waypoint) in waypoints.enumerated() {
            var feature = Feature(geometry: .point(Point(waypoint.coordinate)))
            feature.properties = [
                "waypointCompleted": waypointIndex < legIndex,
                "name": waypointIndex + 1
            ]
            features.append(feature)
        }
        
        let shape = delegate?.navigationMapView(self, shapeFor: waypoints, legIndex: legIndex) ?? FeatureCollection(features: features)
        
        if route.legs.count > 1 {
            routes = [route]
            
            do {
                let waypointSourceIdentifier = NavigationMapView.SourceIdentifier.waypointSource
                
                if mapView.mapboxMap.style.sourceExists(withId: waypointSourceIdentifier) {
                    try mapView.mapboxMap.style.updateGeoJSONSource(withId: waypointSourceIdentifier, geoJSON: shape)
                } else {
                    var waypointSource = GeoJSONSource()
                    waypointSource.data = .featureCollection(shape)
                    try mapView.mapboxMap.style.addSource(waypointSource, id: waypointSourceIdentifier)
                    
                    let waypointCircleLayerIdentifier = NavigationMapView.LayerIdentifier.waypointCircleLayer
                    let circlesLayer = delegate?.navigationMapView(self,
                                                                   waypointCircleLayerWithIdentifier: waypointCircleLayerIdentifier,
                                                                   sourceIdentifier: waypointSourceIdentifier) ?? defaultWaypointCircleLayer()
                    
                    if mapView.mapboxMap.style.layerExists(withId: NavigationMapView.LayerIdentifier.arrowSymbolLayer) {
                        try mapView.mapboxMap.style.addLayer(circlesLayer, layerPosition: .above(NavigationMapView.LayerIdentifier.arrowSymbolLayer))
                    } else {
                        let layerIdentifier = route.identifier(.route(isMainRoute: true))
                        try mapView.mapboxMap.style.addLayer(circlesLayer, layerPosition: .above(layerIdentifier))
                    }
                    
                    let waypointSymbolLayerIdentifier = NavigationMapView.LayerIdentifier.waypointSymbolLayer
                    let symbolsLayer = delegate?.navigationMapView(self,
                                                                   waypointSymbolLayerWithIdentifier: waypointSymbolLayerIdentifier,
                                                                   sourceIdentifier: waypointSourceIdentifier) ?? defaultWaypointSymbolLayer()
                    
                    try mapView.mapboxMap.style.addLayer(symbolsLayer, layerPosition: .above(circlesLayer.id))
                }
            } catch {
                NSLog("Failed to perform operation while adding waypoint with error: \(error.localizedDescription).")
            }
        }

        if let lastLeg = route.legs.last,
           let destinationCoordinate = lastLeg.destination?.coordinate,
           let pointAnnotationManager = pointAnnotationManager {
            let identifier = NavigationMapView.AnnotationIdentifier.finalDestinationAnnotation
            var destinationAnnotation = PointAnnotation(id: identifier, coordinate: destinationCoordinate)
            destinationAnnotation.image = .default
            pointAnnotationManager.syncAnnotations([destinationAnnotation])
            
            delegate?.navigationMapView(self, didAdd: destinationAnnotation, pointAnnotationManager: pointAnnotationManager)
        }
    }
    
    func defaultWaypointCircleLayer() -> CircleLayer {
        var circleLayer = CircleLayer(id: NavigationMapView.LayerIdentifier.waypointCircleLayer)
        circleLayer.source = NavigationMapView.SourceIdentifier.waypointSource
        let opacity = Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "waypointCompleted"
                }
            }
            0.5
            1
        }
        circleLayer.circleColor = .constant(.init(color: UIColor(red:0.9, green:0.9, blue:0.9, alpha:1.0)))
        circleLayer.circleOpacity = .expression(opacity)
        circleLayer.circleRadius = .constant(.init(10))
        circleLayer.circleStrokeColor = .constant(.init(color: UIColor.black))
        circleLayer.circleStrokeWidth = .constant(.init(1))
        circleLayer.circleStrokeOpacity = .expression(opacity)
        
        return circleLayer
    }
    
    func defaultWaypointSymbolLayer() -> SymbolLayer {
        var symbolLayer = SymbolLayer(id: NavigationMapView.LayerIdentifier.waypointSymbolLayer)
        symbolLayer.source = NavigationMapView.SourceIdentifier.waypointSource
        symbolLayer.textField = .expression(Exp(.toString) {
            Exp(.get) {
                "name"
            }
        })
        symbolLayer.textSize = .constant(.init(10))
        symbolLayer.textOpacity = .expression(Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "waypointCompleted"
                }
            }
            0.5
            1
        })
        symbolLayer.textHaloWidth = .constant(.init(0.25))
        symbolLayer.textHaloColor = .constant(.init(color: UIColor.black))
        
        return symbolLayer
    }
    
    /**
     Removes all existing `Route` objects from `MapView`, which were added by `NavigationMapView`.
     */
    public func removeRoutes() {
        var sourceIdentifiers = Set<String>()
        var layerIdentifiers = Set<String>()
        routes?.enumerated().forEach {
            sourceIdentifiers.insert($0.element.identifier(.source(isMainRoute: $0.offset == 0, isSourceCasing: true)))
            sourceIdentifiers.insert($0.element.identifier(.source(isMainRoute: $0.offset == 0, isSourceCasing: false)))
            layerIdentifiers.insert($0.element.identifier(.route(isMainRoute: $0.offset == 0)))
            layerIdentifiers.insert($0.element.identifier(.routeCasing(isMainRoute: $0.offset == 0)))
        }
        
        mapView.mapboxMap.style.removeLayers(layerIdentifiers)
        mapView.mapboxMap.style.removeSources(sourceIdentifiers)
        
        routes = nil
        routePoints = nil
        routeLineGranularDistances = nil
    }
    
    /**
     Removes all existing `Waypoint` objects from `MapView`, which were added by `NavigationMapView`.
     */
    public func removeWaypoints() {
        pointAnnotationManager?.syncAnnotations([])
        
        let layers: Set = [
            NavigationMapView.LayerIdentifier.waypointCircleLayer,
            NavigationMapView.LayerIdentifier.waypointSymbolLayer
        ]
        
        mapView.mapboxMap.style.removeLayers(layers)
        mapView.mapboxMap.style.removeSources([NavigationMapView.SourceIdentifier.waypointSource])
    }
    
    func annotationsToRemove() -> [Annotation] {
        let identifier = NavigationMapView.AnnotationIdentifier.finalDestinationAnnotation
        return pointAnnotationManager?.annotations.filter({ $0.id == identifier }) ?? []
    }
    
    /**
     Shows the step arrow given the current `RouteProgress`.
     
     - parameter route: `Route` object, for which maneuver arrows will be shown.
     - parameter legIndex: Zero-based index of the `RouteLeg` which contains the maneuver.
     - parameter stepIndex: Zero-based index of the `RouteStep` which contains the maneuver.
     */
    public func addArrow(route: Route, legIndex: Int, stepIndex: Int) {
        guard route.legs.indices.contains(legIndex),
              route.legs[legIndex].steps.indices.contains(stepIndex),
              let triangleImage = Bundle.mapboxNavigation.image(named: "triangle")?.withRenderingMode(.alwaysTemplate) else { return }
        
        do {
            try mapView.mapboxMap.style.addImage(triangleImage, id: NavigationMapView.ImageIdentifier.arrowImage)
            let step = route.legs[legIndex].steps[stepIndex]
            let maneuverCoordinate = step.maneuverLocation
            guard step.maneuverType != .arrive else { return }
            
            // TODO: Implement ability to change `shaftLength` depending on zoom level.
            let shaftLength = max(min(30 * mapView.metersPerPointAtLatitude(latitude: maneuverCoordinate.latitude), 30), 10)
            let shaftPolyline = route.polylineAroundManeuver(legIndex: legIndex, stepIndex: stepIndex, distance: shaftLength)
            
            var puckLayerIdentifier: String?
            switch userLocationStyle {
            case .puck2D(configuration: _):
                puckLayerIdentifier = NavigationMapView.LayerIdentifier.puck2DLayer
            case .puck3D(configuration: _):
                puckLayerIdentifier = NavigationMapView.LayerIdentifier.puck3DLayer
            default: break
            }
            
            if shaftPolyline.coordinates.count > 1 {
                let allLayerIds = mapView.mapboxMap.style.allLayerIdentifiers.map{ $0.id }
                let mainRouteLayerIdentifier = route.identifier(.route(isMainRoute: true))
                let minimumZoomLevel: Double = 14.5
                let shaftStrokeCoordinates = shaftPolyline.coordinates
                let shaftDirection = shaftStrokeCoordinates[shaftStrokeCoordinates.count - 2].direction(to: shaftStrokeCoordinates.last!)
                
                var arrowSource = GeoJSONSource()
                arrowSource.data = .feature(Feature(geometry: .lineString(shaftPolyline)))
                var arrowLayer = LineLayer(id: NavigationMapView.LayerIdentifier.arrowLayer)
                if mapView.mapboxMap.style.sourceExists(withId: NavigationMapView.SourceIdentifier.arrowSource) {
                    let geoJSON = Feature(geometry: .lineString(shaftPolyline))
                    try mapView.mapboxMap.style.updateGeoJSONSource(withId: NavigationMapView.SourceIdentifier.arrowSource, geoJSON: geoJSON)
                } else {
                    arrowLayer.minZoom = Double(minimumZoomLevel)
                    arrowLayer.lineCap = .constant(.butt)
                    arrowLayer.lineJoin = .constant(.round)
                    arrowLayer.lineWidth = .expression(Expression.routeLineWidthExpression(0.70))
                    arrowLayer.lineColor = .constant(.init(color: maneuverArrowColor))
                    
                    try mapView.mapboxMap.style.addSource(arrowSource, id: NavigationMapView.SourceIdentifier.arrowSource)
                    arrowLayer.source = NavigationMapView.SourceIdentifier.arrowSource
                    
                    if let puckLayer = puckLayerIdentifier, allLayerIds.contains(puckLayer) {
                        try mapView.mapboxMap.style.addLayer(arrowLayer, layerPosition: .below(puckLayer))
                    } else if mapView.mapboxMap.style.sourceExists(withId: NavigationMapView.LayerIdentifier.waypointCircleLayer) {
                        try mapView.mapboxMap.style.addLayer(arrowLayer, layerPosition: .below(NavigationMapView.LayerIdentifier.waypointCircleLayer))
                    } else {
                        try mapView.mapboxMap.style.addLayer(arrowLayer)
                    }
                }
                
                var arrowStrokeSource = GeoJSONSource()
                arrowStrokeSource.data = .feature(Feature(geometry: .lineString(shaftPolyline)))
                var arrowStrokeLayer = LineLayer(id: NavigationMapView.LayerIdentifier.arrowStrokeLayer)
                if mapView.mapboxMap.style.sourceExists(withId: NavigationMapView.SourceIdentifier.arrowStrokeSource) {
                    let geoJSON = Feature(geometry: .lineString(shaftPolyline))
                    try mapView.mapboxMap.style.updateGeoJSONSource(withId: NavigationMapView.SourceIdentifier.arrowStrokeSource,
                                                                    geoJSON: geoJSON)
                } else {
                    arrowStrokeLayer.minZoom = arrowLayer.minZoom
                    arrowStrokeLayer.lineCap = arrowLayer.lineCap
                    arrowStrokeLayer.lineJoin = arrowLayer.lineJoin
                    arrowStrokeLayer.lineWidth = .expression(Expression.routeLineWidthExpression(0.80))
                    arrowStrokeLayer.lineColor = .constant(.init(color: maneuverArrowStrokeColor))
                    
                    try mapView.mapboxMap.style.addSource(arrowStrokeSource, id: NavigationMapView.SourceIdentifier.arrowStrokeSource)
                    arrowStrokeLayer.source = NavigationMapView.SourceIdentifier.arrowStrokeSource
                    
                    let arrowStrokeLayerPsoition = allLayerIds.contains(mainRouteLayerIdentifier) ? LayerPosition.above(mainRouteLayerIdentifier) : LayerPosition.below(NavigationMapView.LayerIdentifier.arrowLayer)
                    try mapView.mapboxMap.style.addLayer(arrowStrokeLayer, layerPosition: arrowStrokeLayerPsoition)
                }
                
                let point = Point(shaftStrokeCoordinates.last!)
                var arrowSymbolSource = GeoJSONSource()
                arrowSymbolSource.data = .feature(Feature(geometry: .point(point)))
                if mapView.mapboxMap.style.sourceExists(withId: NavigationMapView.SourceIdentifier.arrowSymbolSource) {
                    let geoJSON = Feature.init(geometry: Geometry.point(point))
                    try mapView.mapboxMap.style.updateGeoJSONSource(withId: NavigationMapView.SourceIdentifier.arrowSymbolSource,
                                                                    geoJSON: geoJSON)
                    
                    try mapView.mapboxMap.style.setLayerProperty(for: NavigationMapView.LayerIdentifier.arrowSymbolLayer,
                                                                 property: "icon-rotate",
                                                                 value: shaftDirection)
                    
                    try mapView.mapboxMap.style.setLayerProperty(for: NavigationMapView.LayerIdentifier.arrowSymbolCasingLayer,
                                                                 property: "icon-rotate",
                                                                 value: shaftDirection)
                } else {
                    var arrowSymbolLayer = SymbolLayer(id: NavigationMapView.LayerIdentifier.arrowSymbolLayer)
                    arrowSymbolLayer.minZoom = Double(minimumZoomLevel)
                    arrowSymbolLayer.iconImage = .constant(.name(NavigationMapView.ImageIdentifier.arrowImage))
                    // FIXME: `iconColor` has no effect.
                    arrowSymbolLayer.iconColor = .constant(.init(color: maneuverArrowColor))
                    arrowSymbolLayer.iconRotationAlignment = .constant(.map)
                    arrowSymbolLayer.iconRotate = .constant(.init(shaftDirection))
                    arrowSymbolLayer.iconSize = .expression(Expression.routeLineWidthExpression(0.12))
                    arrowSymbolLayer.iconAllowOverlap = .constant(true)
                    
                    var arrowSymbolCasingLayer = SymbolLayer(id: NavigationMapView.LayerIdentifier.arrowSymbolCasingLayer)
                    arrowSymbolCasingLayer.minZoom = arrowSymbolLayer.minZoom
                    arrowSymbolCasingLayer.iconImage = arrowSymbolLayer.iconImage
                    // FIXME: `iconColor` has no effect.
                    arrowSymbolCasingLayer.iconColor = .constant(.init(color: maneuverArrowStrokeColor))
                    arrowSymbolCasingLayer.iconRotationAlignment = arrowSymbolLayer.iconRotationAlignment
                    arrowSymbolCasingLayer.iconRotate = arrowSymbolLayer.iconRotate
                    arrowSymbolCasingLayer.iconSize = .expression(Expression.routeLineWidthExpression(0.14))
                    arrowSymbolCasingLayer.iconAllowOverlap = arrowSymbolLayer.iconAllowOverlap
                    
                    try mapView.mapboxMap.style.addSource(arrowSymbolSource, id: NavigationMapView.SourceIdentifier.arrowSymbolSource)
                    arrowSymbolLayer.source = NavigationMapView.SourceIdentifier.arrowSymbolSource
                    arrowSymbolCasingLayer.source = NavigationMapView.SourceIdentifier.arrowSymbolSource
                    
                    if let puckLayer = puckLayerIdentifier, allLayerIds.contains(puckLayer) {
                        try mapView.mapboxMap.style.addLayer(arrowSymbolLayer, layerPosition: .below(puckLayer))
                    } else {
                        try mapView.mapboxMap.style.addLayer(arrowSymbolLayer)
                    }
                    try mapView.mapboxMap.style.addLayer(arrowSymbolCasingLayer,
                                                         layerPosition: .below(NavigationMapView.LayerIdentifier.arrowSymbolLayer))
                }
            }
        } catch {
            NSLog("Failed to perform operation while adding maneuver arrow with error: \(error.localizedDescription).")
        }
    }
    
    /**
     Removes the `RouteStep` arrow from the `MapView`.
     */
    public func removeArrow() {
        let layers: Set = [
            NavigationMapView.LayerIdentifier.arrowLayer,
            NavigationMapView.LayerIdentifier.arrowStrokeLayer,
            NavigationMapView.LayerIdentifier.arrowSymbolLayer,
            NavigationMapView.LayerIdentifier.arrowSymbolCasingLayer
        ]
        mapView.mapboxMap.style.removeLayers(layers)
        
        let sources: Set = [
            NavigationMapView.SourceIdentifier.arrowSource,
            NavigationMapView.SourceIdentifier.arrowStrokeSource,
            NavigationMapView.SourceIdentifier.arrowSymbolSource
        ]
        mapView.mapboxMap.style.removeSources(sources)
    }
    
    // MARK: - Route duration annotations methods

    /**
     Shows a callout containing the duration of each route.
     Useful as a way to give the user more information when picking between multiple route alternatives.
     If the route contains any tolled segments then the callout will specify that as well.
     */
    public func showRouteDurations(along routes: [Route]?) {
        guard let visibleRoutes = routes, visibleRoutes.count > 0 else { return }
        
        do {
            try updateAnnotationSymbolImages()
        } catch {
            NSLog("Error occured while updating annotation symbol images: \(error.localizedDescription).")
        }
        
        updateRouteDurations(along: visibleRoutes)
    }

    /**
     Updates the image assets in the map style for the route duration annotations. Useful when the desired callout colors change, such as when transitioning between light and dark mode on iOS 13 and later.
     */
    private func updateAnnotationSymbolImages() throws {
        let style = mapView.mapboxMap.style
        
        guard style.image(withId: "RouteInfoAnnotationLeftHanded") == nil,
              style.image(withId: "RouteInfoAnnotationRightHanded") == nil else { return }
        
        // Right-hand pin
        if let image = Bundle.mapboxNavigation.image(named: "RouteInfoAnnotationRightHanded") {
            // define the "stretchable" areas in the image that will be fitted to the text label
            let stretchX = [ImageStretches(first: Float(12), second: Float(20))]
            let stretchY = [ImageStretches(first: Float(12), second: Float(18))]
            let imageContent = ImageContent(left: 12, top: 12, right: 20, bottom: 18)
            
            let regularAnnotationImage = image.tint(routeDurationAnnotationColor)
            try style.addImage(regularAnnotationImage,
                               id: "RouteInfoAnnotationRightHanded",
                               stretchX: stretchX,
                               stretchY: stretchY,
                               content: imageContent)
            
            let selectedAnnotationImage = image.tint(routeDurationAnnotationSelectedColor)
            try style.addImage(selectedAnnotationImage,
                               id: "RouteInfoAnnotationRightHanded-Selected",
                               stretchX: stretchX,
                               stretchY: stretchY,
                               content: imageContent)
        }
        
        // Left-hand pin
        if let image = Bundle.mapboxNavigation.image(named: "RouteInfoAnnotationLeftHanded") {
            // define the "stretchable" areas in the image that will be fitted to the text label
            let stretchX = [ImageStretches(first: Float(17), second: Float(25))]
            let stretchY = [ImageStretches(first: Float(12), second: Float(18))]
            let imageContent = ImageContent(left: 17, top: 12, right: 25, bottom: 18)
            
            let regularAnnotationImage = image.tint(routeDurationAnnotationColor)
            try style.addImage(regularAnnotationImage,
                               id: "RouteInfoAnnotationLeftHanded",
                               stretchX: stretchX,
                               stretchY: stretchY,
                               content: imageContent)
            
            let selectedAnnotationImage = image.tint(routeDurationAnnotationSelectedColor)
            try style.addImage(selectedAnnotationImage,
                               id: "RouteInfoAnnotationLeftHanded-Selected",
                               stretchX: stretchX,
                               stretchY: stretchY,
                               content: imageContent)
        }

        // Centered pin
        if let image = Bundle.mapboxNavigation.image(named: "AnnotationCentered") {
            // define the "stretchable" areas in the image that will be fitted to the text label
            let stretchX = [ImageStretches(first: Float(5), second: Float(7)), ImageStretches(first: Float(24), second: Float(27))]
            let stretchY = [ImageStretches(first: Float(6), second: Float(8))]
            let imageContent = ImageContent(left: 5, top: 6, right: 27, bottom: 8)

            let regularAnnotationImage = image.tint(routeDurationAnnotationColor)
            try style.addImage(regularAnnotationImage,
                               id: "AnnotationCentered",
                               stretchX: stretchX,
                               stretchY: stretchY,
                               content: imageContent)

            let selectedAnnotationImage = image.tint(routeDurationAnnotationSelectedColor)
            try style.addImage(selectedAnnotationImage,
                               id: "AnnotationCentered-Highlighted",
                               stretchX: stretchX,
                               stretchY: stretchY,
                               content: imageContent)
        }
    }

    /**
     Remove any old route duration callouts and generate new ones for each passed in route.
     */
    private func updateRouteDurations(along routes: [Route]?) {
        let style = mapView.mapboxMap.style
        
        // remove any existing route annotation
        removeRouteDurationAnnotationsLayerFromStyle(style)

        guard let routes = routes else { return }

        let coordinateBounds = mapView.mapboxMap.coordinateBounds(for: mapView.frame)
        let visibleBoundingBox = BoundingBox(southWest: coordinateBounds.southwest, northEast: coordinateBounds.northeast)

        let tollRoutes = routes.filter { route -> Bool in
            return (route.tollIntersections?.count ?? 0) > 0
        }
        let routesContainTolls = tollRoutes.count > 0

        // pick a random tail direction to keep things varied
        guard let randomTailPosition = [RouteDurationAnnotationTailPosition.left, RouteDurationAnnotationTailPosition.right].randomElement() else { return }

        var features = [Turf.Feature]()

        // Run through our heuristic algorithm looking for a good coordinate along each route line to place it's route annotation
        // First, we will look for a set of RouteSteps unique to each route
        var excludedSteps = [RouteStep]()
        for (index, route) in routes.enumerated() {
            let allSteps = route.legs.flatMap { return $0.steps }
            let alternateSteps = allSteps.filter { !excludedSteps.contains($0) }

            excludedSteps.append(contentsOf: alternateSteps)
            let visibleAlternateSteps = alternateSteps.filter { $0.intersects(visibleBoundingBox) }

            var coordinate: CLLocationCoordinate2D?

            // Obtain a polyline of the set of steps. We'll look for a good spot along this line to place the annotation.
            // We will consider a good spot to be somewhere near the middle of the line, making sure that the coordinate is visible on-screen.
            if let continuousLine = visibleAlternateSteps.continuousShape(), continuousLine.coordinates.count > 0 {
                coordinate = continuousLine.coordinates[0]

                // Pick a coordinate using some randomness in order to give visual variety.
                // Take care to snap that coordinate to one that lays on the original route line.
                // If the chosen snapped coordinate is not visible on the screen, then we walk back along the route coordinates looking for one that is.
                // If none of the earlier points are on screen then we walk forward along the route coordinates until we find one that is.
                if let distance = continuousLine.distance(), let sampleCoordinate = continuousLine.indexedCoordinateFromStart(distance: distance * CLLocationDistance.random(in: 0.3...0.8))?.coordinate, let routeShape = route.shape, let snappedCoordinate = routeShape.closestCoordinate(to: sampleCoordinate) {
                    var foundOnscreenCoordinate = false
                    var firstOnscreenCoordinate = snappedCoordinate.coordinate
                    for indexedCoordinate in routeShape.coordinates.prefix(through: snappedCoordinate.index).reversed() {
                        if visibleBoundingBox.contains(indexedCoordinate) {
                            firstOnscreenCoordinate = indexedCoordinate
                            foundOnscreenCoordinate = true
                            break
                        }
                    }

                    if foundOnscreenCoordinate {
                        // We found a point that is both on the route and on-screen
                        coordinate = firstOnscreenCoordinate
                    } else {
                        // we didn't find a previous point that is on-screen so we'll move forward through the coordinates looking for one
                        for indexedCoordinate in routeShape.coordinates.suffix(from: snappedCoordinate.index) {
                            if visibleBoundingBox.contains(indexedCoordinate) {
                                firstOnscreenCoordinate = indexedCoordinate
                                break
                            }
                        }
                        coordinate = firstOnscreenCoordinate
                    }
                }
            }

            guard let annotationCoordinate = coordinate else { return }

            // form the appropriate text string for the annotation
            let labelText = self.annotationLabelForRoute(route, tolls: routesContainTolls)

            // Create the feature for this route annotation. Set the styling attributes that will be used to render the annotation in the style layer.
            var feature = Feature(geometry: .point(Point(annotationCoordinate)))

            var tailPosition = randomTailPosition

            // convert our coordinate to screen space so we can make a choice on which side of the coordinate the label ends up on
            let unprojectedCoordinate = mapView.mapboxMap.point(for: annotationCoordinate)

            // pick the orientation of the bubble "stem" based on how close to the edge of the screen it is
            if tailPosition == .left && unprojectedCoordinate.x > bounds.width * 0.75 {
                tailPosition = .right
            } else if tailPosition == .right && unprojectedCoordinate.x < bounds.width * 0.25 {
                tailPosition = .left
            }

            var imageName = tailPosition == .left ? "RouteInfoAnnotationLeftHanded" : "RouteInfoAnnotationRightHanded"

            // the selected route uses the colored annotation image
            if index == 0 {
                imageName += "-Selected"
            }

            // set the feature attributes which will be used in styling the symbol style layer
            feature.properties = ["selected": index == 0, "tailPosition": tailPosition.rawValue, "text": labelText, "imageName": imageName, "sortOrder": index == 0 ? index : -index]

            features.append(feature)
        }

        // add the features to the style
        do {
            try addRouteAnnotationSymbolLayer(features: FeatureCollection(features: features))
        } catch {
            NSLog("Error occured while adding route annotation symbol layer: \(error.localizedDescription).")
        }
    }

    /**
     Add the MGLSymbolStyleLayer for the route duration annotations.
     */
    private func addRouteAnnotationSymbolLayer(features: FeatureCollection) throws {
        let style = mapView.mapboxMap.style
        
        let routeDurationAnnotationsSourceIdentifier = NavigationMapView.SourceIdentifier.routeDurationAnnotationsSource
        if style.sourceExists(withId: routeDurationAnnotationsSourceIdentifier) {
            try style.updateGeoJSONSource(withId: routeDurationAnnotationsSourceIdentifier, geoJSON: features)
        } else {
            var dataSource = GeoJSONSource()
            dataSource.data = .featureCollection(features)
            try style.addSource(dataSource, id: routeDurationAnnotationsSourceIdentifier)
        }
        
        let routeDurationAnnotationsLayerIdentifier = NavigationMapView.LayerIdentifier.routeDurationAnnotationsLayer
        var shapeLayer: SymbolLayer
        if let layer = try? style.layer(withId: routeDurationAnnotationsLayerIdentifier) as SymbolLayer {
            shapeLayer = layer
        } else {
            shapeLayer = SymbolLayer(id: routeDurationAnnotationsLayerIdentifier)
        }

        shapeLayer.source = routeDurationAnnotationsSourceIdentifier

        shapeLayer.textField = .expression(Exp(.get) {
            "text"
        })

        shapeLayer.iconImage = .expression(Exp(.get) {
            "imageName"
        })

        shapeLayer.textColor = .expression(Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "selected"
                }
            }
            routeDurationAnnotationSelectedTextColor
            routeDurationAnnotationTextColor
        })

        shapeLayer.textSize = .constant(16)
        shapeLayer.iconTextFit = .constant(IconTextFit.both)
        shapeLayer.iconAllowOverlap = .constant(true)
        shapeLayer.textAllowOverlap = .constant(true)
        shapeLayer.textJustify = .constant(TextJustify.left)
        shapeLayer.symbolZOrder = .constant(SymbolZOrder.auto)
        shapeLayer.textFont = .constant(self.routeDurationAnnotationFontNames)

        try style.addLayer(shapeLayer)

        let symbolSortKeyString =
        """
        ["get", "sortOrder"]
        """

        if let expressionData = symbolSortKeyString.data(using: .utf8),
           let expJSONObject = try? JSONSerialization.jsonObject(with: expressionData, options: []) {
            let property = "symbol-sort-key"
            try style.setLayerProperty(for: routeDurationAnnotationsLayerIdentifier,
                                       property: property,
                                       value: expJSONObject)
        }

        let expressionString =
        """
        [
          "match",
          ["get", "tailPosition"],
          [0],
          "bottom-left",
          [1],
          "bottom-right",
          "center"
        ]
        """

        if let expressionData = expressionString.data(using: .utf8),
           let expJSONObject = try? JSONSerialization.jsonObject(with: expressionData, options: []) {
            try style.setLayerProperty(for: routeDurationAnnotationsLayerIdentifier,
                                       property: "icon-anchor",
                                       value: expJSONObject)
            try style.setLayerProperty(for: routeDurationAnnotationsLayerIdentifier,
                                       property: "text-anchor",
                                       value: expJSONObject)
        }

        let offsetExpressionString =
            """
        [
          "match",
          ["get", "tailPosition"],
          [0],
          ["literal", [0.5, -1]],
          ["literal", [-0.5, -1]]
        ]
        """
        
        if let expressionData = offsetExpressionString.data(using: .utf8),
           let expJSONObject = try? JSONSerialization.jsonObject(with: expressionData, options: []) {
            try style.setLayerProperty(for: routeDurationAnnotationsLayerIdentifier,
                                       property: "icon-offset",
                                       value: expJSONObject)
            
            try style.setLayerProperty(for: routeDurationAnnotationsLayerIdentifier,
                                       property: "text-offset",
                                       value: expJSONObject)
        }
    }

    /**
     Removes all visible route duration callouts.
     */
    public func removeRouteDurations() {
        let style = mapView.mapboxMap.style
        removeRouteDurationAnnotationsLayerFromStyle(style)
    }

    /**
     Remove the underlying style layers and data sources for the route duration annotations.
     */
    private func removeRouteDurationAnnotationsLayerFromStyle(_ style: MapboxMaps.Style) {
        style.removeLayers([NavigationMapView.LayerIdentifier.routeDurationAnnotationsLayer])
        style.removeSources([NavigationMapView.SourceIdentifier.routeDurationAnnotationsSource])
    }

    /**
     Generate the text for the label to be shown on screen. It will include estimated duration
     and info on Tolls, if applicable.
     */
    private func annotationLabelForRoute(_ route: Route, tolls: Bool) -> String {
        var eta = DateComponentsFormatter.shortDateComponentsFormatter.string(from: route.expectedTravelTime) ?? ""

        let hasTolls = (route.tollIntersections?.count ?? 0) > 0
        if hasTolls {
            eta += "\n" + NSLocalizedString("ROUTE_HAS_TOLLS", value: "Tolls", comment: "This route does have tolls")
            if let symbol = Locale.current.currencySymbol {
                eta += " " + symbol
            }
        } else if tolls {
            // If one of the routes has tolls, but this one does not then it needs to explicitly say that it has no tolls
            // If no routes have tolls at all then we can omit this portion of the string.
            eta += "\n" + NSLocalizedString("ROUTE_HAS_NO_TOLLS", value: "No Tolls", comment: "This route does not have tolls")
        }

        return eta
    }
    
    // MARK: - Road labels localization methods
    
    public func localizeLabels() {
        // TODO: Implement ability to localize road labels.
    }
    
    // MARK: - Route voice instructions methods
    
    /**
     Shows voice instructions for specific `Route` object.
     
     - parameter route: `Route` object, along which voice instructions will be shown.
     */
    public func showVoiceInstructionsOnMap(route: Route) {
        var featureCollection = FeatureCollection(features: [])
        
        for (legIndex, leg) in route.legs.enumerated() {
            for (stepIndex, step) in leg.steps.enumerated() {
                guard let instructions = step.instructionsSpokenAlongStep else { continue }
                for instruction in instructions {
                    guard let shape = route.legs[legIndex].steps[stepIndex].shape,
                          let coordinateFromStart = LineString(shape.coordinates.reversed()).coordinateFromStart(distance: instruction.distanceAlongStep) else { continue }
                    
                    var feature = Feature(geometry: .point(Point(coordinateFromStart)))
                    feature.properties = [
                        "instruction": instruction.text
                    ]
                    featureCollection.features.append(feature)
                }
            }
        }
        
        do {
            if mapView.mapboxMap.style.sourceExists(withId: NavigationMapView.SourceIdentifier.voiceInstructionSource) {
                try mapView.mapboxMap.style.updateGeoJSONSource(withId: NavigationMapView.SourceIdentifier.voiceInstructionSource, geoJSON: featureCollection)
            } else {
                var source = GeoJSONSource()
                source.data = .featureCollection(featureCollection)
                try mapView.mapboxMap.style.addSource(source, id: NavigationMapView.SourceIdentifier.voiceInstructionSource)
                
                var symbolLayer = SymbolLayer(id: NavigationMapView.LayerIdentifier.voiceInstructionLabelLayer)
                symbolLayer.source = NavigationMapView.SourceIdentifier.voiceInstructionSource
                
                let instruction = Exp(.toString) {
                    Exp(.get) {
                        "instruction"
                    }
                }
                
                symbolLayer.textField = .expression(instruction)
                symbolLayer.textSize = .constant(14)
                symbolLayer.textHaloWidth = .constant(1)
                symbolLayer.textHaloColor = .constant(.init(color: .white))
                symbolLayer.textOpacity = .constant(0.75)
                symbolLayer.textAnchor = .constant(.bottom)
                symbolLayer.textJustify = .constant(.left)
                try mapView.mapboxMap.style.addLayer(symbolLayer)
                
                var circleLayer = CircleLayer(id: NavigationMapView.LayerIdentifier.voiceInstructionCircleLayer)
                circleLayer.source = NavigationMapView.SourceIdentifier.voiceInstructionSource
                circleLayer.circleRadius = .constant(5)
                circleLayer.circleOpacity = .constant(0.75)
                circleLayer.circleColor = .constant(.init(color: .white))
                try mapView.mapboxMap.style.addLayer(circleLayer)
            }
        } catch {
            NSLog("Failed to perform operation while adding voice instructions with error: \(error.localizedDescription).")
        }
    }
    
    // MARK: - Gesture recognizers methods
    
    /**
     Fired when NavigationMapView detects a tap not handled elsewhere by other gesture recognizers.
     */
    @objc func didReceiveTap(sender: UITapGestureRecognizer) {
        guard let routes = routes, let tapPoint = sender.point else { return }
        
        let waypointTest = waypoints(on: routes, closeTo: tapPoint)
        if let selected = waypointTest?.first {
            delegate?.navigationMapView(self, didSelect: selected)
            return
        } else if let routes = self.routes(closeTo: tapPoint) {
            guard let selectedRoute = routes.first else { return }
            delegate?.navigationMapView(self, didSelect: selectedRoute)
        }
    }
    
    private func waypoints(on routes: [Route], closeTo point: CGPoint) -> [MapboxDirections.Waypoint]? {
        let tapCoordinate = mapView.mapboxMap.coordinate(for: point)
        let multipointRoutes = routes.filter { $0.legs.count > 1}
        guard multipointRoutes.count > 0 else { return nil }
        let waypoints = multipointRoutes.compactMap { route in
            route.legs.dropLast().compactMap { $0.destination }
        }.flatMap {$0}
        
        // Sort the array in order of closest to tap.
        let closest = waypoints.sorted { (left, right) -> Bool in
            let leftDistance = calculateDistance(coordinate1: left.coordinate, coordinate2: tapCoordinate)
            let rightDistance = calculateDistance(coordinate1: right.coordinate, coordinate2: tapCoordinate)
            return leftDistance < rightDistance
        }
        
        // Filter to see which ones are under threshold.
        let candidates = closest.filter({
            let coordinatePoint = mapView.mapboxMap.point(for: $0.coordinate)
            
            return coordinatePoint.distance(to: point) < tapGestureDistanceThreshold
        })
        
        return candidates
    }
    
    private func routes(closeTo point: CGPoint) -> [Route]? {
        let tapCoordinate = mapView.mapboxMap.coordinate(for: point)
        
        // Filter routes with at least 2 coordinates.
        guard let routes = routes?.filter({ $0.shape?.coordinates.count ?? 0 > 1 }) else { return nil }
        
        // Sort routes by closest distance to tap gesture.
        let closest = routes.sorted { (left, right) -> Bool in
            // Existence has been assured through use of filter.
            let leftLine = left.shape!
            let rightLine = right.shape!
            let leftDistance = leftLine.closestCoordinate(to: tapCoordinate)!.coordinate.distance(to: tapCoordinate)
            let rightDistance = rightLine.closestCoordinate(to: tapCoordinate)!.coordinate.distance(to: tapCoordinate)
            
            return leftDistance < rightDistance
        }
        
        // Filter closest coordinates by which ones are under threshold.
        let candidates = closest.filter {
            let closestCoordinate = $0.shape!.closestCoordinate(to: tapCoordinate)!.coordinate
            let closestPoint = mapView.mapboxMap.point(for: closestCoordinate)
            
            return closestPoint.distance(to: point) < tapGestureDistanceThreshold
        }
        
        return candidates
    }

    func makeGestureRecognizersResetFrameRate() {
        for gestureRecognizer in gestureRecognizers ?? [] {
            gestureRecognizer.addTarget(self, action: #selector(resetFrameRate(_:)))
        }
    }

    public var showIntersectionAnnotations: Bool = false {
        didSet {
            guard oldValue != showIntersectionAnnotations else { return }
            intersectionsToAnnotate = nil
            if showIntersectionAnnotations {
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(didUpdateElectronicHorizonPosition),
                                                       name: .electronicHorizonDidUpdatePosition,
                                                       object: nil)
            } else {
                removeRouteAnnotationsLayerFromStyle()
                NotificationCenter.default.removeObserver(self, name: .electronicHorizonDidUpdatePosition, object: nil)
            }
        }
    }

    private func edgeIsCandidate(_ edge: RoadGraph.Edge, roadGraph: RoadGraph) -> Bool {
        // Criteria for accepting an edge as a candidate intersecting road
        //  • Is of a large enough road class
        //  • Is of a non-trivial length in meters
        //  • Intersection point is currently visible on screen

        guard edge.level != 0 else { return false }

        guard let edgeMetadata = roadGraph.edgeMetadata(edgeIdentifier: edge.identifier), let geometry = roadGraph.edgeShape(edgeIdentifier: edge.identifier) else { return false }

        guard ![MapboxStreetsRoadClass.service, MapboxStreetsRoadClass.ferry, MapboxStreetsRoadClass.path, MapboxStreetsRoadClass.majorRail, MapboxStreetsRoadClass.minorRail, MapboxStreetsRoadClass.serviceRail, MapboxStreetsRoadClass.aerialway, MapboxStreetsRoadClass.golf].contains(edgeMetadata.mapboxStreetsRoadClass) else {
            // edge is of type that we choose not to label
            return false
        }

        guard edgeMetadata.names.count > 0 else { return false }

        guard edgeMetadata.length >= 5 else {
            // edge is at least 5 meters long
            return false
        }

        guard let length = geometry.distance() else { return false }

        let targetDistance = min(length / 2, Double(30))
        guard let annotationPoint = geometry.coordinateFromStart(distance: targetDistance) else {
            // unable to find a coordinate to label
            return false
        }

        let onscreenPoint = self.mapView.mapboxMap.point(for: annotationPoint)

        guard mapView.bounds.insetBy(dx: 20, dy: 20).contains(onscreenPoint) else {
            // intersection coordinate is not visible on screen
            return false
        }
        return true
    }

    private func updateIntersectionAnnotationSet(startingEdge: RoadGraph.Edge, roadGraph: RoadGraph) {
        guard let currentWayname = startingEdge.edgeNames(roadGraph: roadGraph)?.first else { return }

        // grab the MPP from the Electronic Horizon
        guard let edges = startingEdge.mpp else { return }

        var intersections = [EdgeIntersection]()
        var addedIntersections = [String]()

        for mppEdge in edges {
            guard let rootMetadata = roadGraph.edgeMetadata(edgeIdentifier: mppEdge.identifier), let rootShape = roadGraph.edgeShape(edgeIdentifier: mppEdge.identifier) else { continue }

            for outEdge in mppEdge.outletEdges {
                // look for a name for the outlet road and check that it meets certain conditions:
                //  • it isn't the road we are traveling on
                //  • it isn't the road that matches the maneuver since that will already be annotated
                //  • it hasn't already been added to our list of annotations
                guard let outEdgeWayname = outEdge.edgeNames(roadGraph: roadGraph)?.first, outEdgeWayname.count > 0, outEdgeWayname != currentWayname, outEdgeWayname != lastManeuverWayName, !addedIntersections.contains(outEdgeWayname) else { continue }

                // Check if this annotation was already on screen. If it was then we just reuse the same feature
                if let existingIntersection = intersectionsToAnnotate?.first(where: { $0.intersectingWayName == outEdgeWayname }) {
                    addedIntersections.append(outEdgeWayname)
                    intersections.append(existingIntersection)
                    continue
                }

                // This outlet hasn't been encountered yet, so check the criteria for being a road we want to annotate
                if !edgeIsCandidate(outEdge, roadGraph: roadGraph) {
                    continue
                }

                // It's an acceptable intersection so record the edge information for use in creating the annotation Feature and add it to the list
                guard let branchMetadata = roadGraph.edgeMetadata(edgeIdentifier: outEdge.identifier), let branchGeometry = roadGraph.edgeShape(edgeIdentifier: outEdge.identifier) else { continue }

                intersections.append(EdgeIntersection(root: mppEdge, branch: outEdge, rootMetadata: rootMetadata, rootShape: rootShape, branchMetadata: branchMetadata, branchShape: branchGeometry))
                addedIntersections.append(outEdgeWayname)
            }
        }

        // sort the edges by distance from the user
        if let userCoordinate = mostRecentUserCourseViewLocation?.coordinate {
            intersections.sort { (intersection1, intersection2) -> Bool in
                if let edge1Start = intersection1.coordinate, let edge2Start = intersection2.coordinate {
                    return userCoordinate.distance(to: edge1Start) < userCoordinate.distance(to: edge2Start)
                }
                return true
            }
        }

        // take up to 4 intersections to annotate. Limit it to prevent cluttering the map with too many annotations
        intersectionsToAnnotate = Array(intersections.prefix(4))

        if let intersectionsToAnnotate = intersectionsToAnnotate {
            let userInfo: [String: Any] = [
                "intersectionAnnotations": intersectionsToAnnotate
            ]
            NotificationCenter.default.post(name: NSNotification.Name(NavigationMapView.intersectionAnnotations), object: self, userInfo: userInfo)
        }
    }

    var lastManeuverWayName: String?
    public var intersectionsToAnnotate: [EdgeIntersection]?

    open func updateAnnotations(for routeProgress: RouteProgress?) {
        var features = [Turf.Feature]()

        try? updateAnnotationSymbolImages()

        // add an annotation for the next step
        if let upcomingStep = routeProgress?.upcomingStep, let currentLeg = routeProgress?.currentLeg {
            var feature = upcomingStep.annotationFeature
            if upcomingStep == currentLeg.steps.last, let destination = currentLeg.destination?.name {
                feature.properties?["text"] = destination
                lastManeuverWayName = currentLeg.destination?.name
            } else {
                lastManeuverWayName = upcomingStep.annotationLabel
            }
            features.append(feature)
        }

        guard let intersectionsToAnnotate = intersectionsToAnnotate else { return }
        for (index, intersection) in intersectionsToAnnotate.enumerated() {
            guard let intersectingWayName = intersection.intersectingWayName, intersectingWayName != lastManeuverWayName, var feature = intersection.feature else { continue }
            feature.properties?["sortOrder"] = -(index + 1)
            features.append(feature)
        }
        
        updateAnnotationLayer(with: FeatureCollection(features: features))
    }

    private func removeRouteAnnotationsLayerFromStyle() {
        mapView.mapboxMap.style.removeLayers([NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer])
        try? mapView.mapboxMap.style.removeSource(withId: NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer)
    }

    static let intersectionAnnotations = "intersectionAnnotations"

    private func updateAnnotationLayer(with features: FeatureCollection) {
        let existingDataSource = try? mapView.mapboxMap.style.source(withId: NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer) as GeoJSONSource
        if existingDataSource != nil {
            try! mapView.mapboxMap.style.updateGeoJSONSource(withId: NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer, geoJSON: features)
            return
        } else {
            var dataSource = GeoJSONSource()
            dataSource.data = .featureCollection(features)
            try! mapView.mapboxMap.style.addSource(dataSource, id: NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer)
        }

        _ = try? mapView.mapboxMap.style.removeLayer(withId: NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer)

        var shapeLayer = SymbolLayer(id: NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer)
        shapeLayer.source = NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer

        shapeLayer.textField = .expression(Exp(.get) {
            "text"
        })

        shapeLayer.iconImage = .expression(Exp(.get) {
            "imageName"
        })

        shapeLayer.textColor = .expression(Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "highlighted"
                }
            }
            self.intersectionAnnotationSelectedLabelColor
            self.intersectionAnnotationDefaultLabelColor
        })

        shapeLayer.textSize = .constant(16)
        shapeLayer.iconTextFit = .constant(.both)
        shapeLayer.iconAllowOverlap = .constant(true)
        shapeLayer.textAllowOverlap = .constant(true)
        shapeLayer.textJustify = .constant(.center)
        shapeLayer.symbolZOrder = .constant(.auto)
        shapeLayer.textFont = .constant(self.intersectionAnnotationFontNames)
        shapeLayer.iconTextFitPadding = .constant([-4, 0, -3, 0])

        try? mapView.mapboxMap.style.addLayer(shapeLayer, layerPosition: nil)

        let symbolSortKeyString =
        """
        ["get", "sortOrder"]
        """

        if let expressionData = symbolSortKeyString.data(using: .utf8), let expJSONObject = try? JSONSerialization.jsonObject(with: expressionData, options: []) {

            try! mapView.mapboxMap.style.setLayerProperty(for: NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer, property: "symbol-sort-key", value: expJSONObject)
        }

        let expressionString =
        """
        [
          "match",
          ["get", "tailPosition"],
          [0],
          "bottom-left",
          [1],
          "bottom-right",
          [2],
          "bottom",
          "center"
        ]
        """

        if let expressionData = expressionString.data(using: .utf8), let expJSONObject = try? JSONSerialization.jsonObject(with: expressionData, options: []) {

            try! mapView.mapboxMap.style.setLayerProperty(for: NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer, property: "icon-anchor", value: expJSONObject)

            try! mapView.mapboxMap.style.setLayerProperty(for: NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer, property: "text-anchor", value: expJSONObject)
        }

        let offsetExpressionString =
        """
        [
          "match",
          ["get", "tailPosition"],
          [0],
          ["literal", [0.5, -1]],
          [1],
          ["literal", [-0.5, -1]],
          [2],
          ["literal", [0.0, -1]],
          ["literal", [0.0, 0.0]]
        ]
        """

        if let expressionData = offsetExpressionString.data(using: .utf8), let expJSONObject = try? JSONSerialization.jsonObject(with: expressionData, options: []) {

            try! mapView.mapboxMap.style.setLayerProperty(for: NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer, property: "icon-offset", value: expJSONObject)

            try! mapView.mapboxMap.style.setLayerProperty(for: NavigationMapView.LayerIdentifier.intersectionAnnotationsLayer, property: "text-offset", value: expJSONObject)
        }
    }

    @objc func didUpdateElectronicHorizonPosition(_ notification: Notification) {
        guard let startingEdge = notification.userInfo?[RoadGraph.NotificationUserInfoKey.treeKey] as? RoadGraph.Edge, let roadGraph = notification.userInfo?[RoadGraph.NotificationUserInfoKey.roadGraphIdentifierKey] as? RoadGraph else {
            return
        }

        DispatchQueue.main.async {
            self.updateIntersectionAnnotationSet(startingEdge: startingEdge, roadGraph: roadGraph)
        }
    }
}

extension ElectronicHorizon.Edge {
    var mpp: [ElectronicHorizon.Edge]? {

        guard level == 0 else { return nil }

        var mostProbablePath = [self]

        for child in outletEdges {
            if let childMPP = child.mpp {
                mostProbablePath.append(contentsOf: childMPP)
            }
        }

        return mostProbablePath
    }
}

extension ElectronicHorizon.Edge {
    func edgeNames(roadGraph: RoadGraph) -> [String] {
        guard let metadata = roadGraph.edgeMetadata(edgeIdentifier: identifier) else {
            return []
        }
        let names = metadata.names.map { name -> String in
            switch name {
            case .name(let name):
                return name
            case .code(let code):
                return "(\(code))"
            }
        }

        // If the road is unnamed, fall back to the road class.
        if names.isEmpty {
            return ["\(metadata.mapboxStreetsRoadClass.rawValue)"]
        }
        return names
    }
}

struct EdgeIntersection {
    var root: ElectronicHorizon.Edge
    var branch: ElectronicHorizon.Edge
    var rootMetadata: ElectronicHorizon.Edge.Metadata
    var rootShape: LineString
    var branchMetadata: ElectronicHorizon.Edge.Metadata
    var branchShape: LineString

    var coordinate: CLLocationCoordinate2D? {
        rootShape.coordinates.first
    }

    var annotationPoint: CLLocationCoordinate2D? {
        guard let length = branchShape.distance() else { return nil }
        let targetDistance = min(length / 2, Double.random(in: 15...30))
        guard let annotationPoint = branchShape.coordinateFromStart(distance: targetDistance) else { return nil }
        return annotationPoint
    }

    var wayName: String? {
        guard let roadName = rootMetadata.names.first else { return nil }

        switch roadName {
        case .name(let name):
            return name
        case .code(let code):
            return "(\(code))"
        }
    }
    var intersectingWayName: String? {
        guard let roadName = branchMetadata.names.first else { return nil }

        switch roadName {
        case .name(let name):
            return name
        case .code(let code):
            return "(\(code))"
        }
    }

    var incidentAngle: CLLocationDegrees {
        return (branchMetadata.heading - rootMetadata.heading).wrap(min: 0, max: 360)
    }

    var description: String {
        return "EdgeIntersection: root: \(wayName ?? "") intersection: \(intersectingWayName ?? "") coordinate: \(String(describing: coordinate))"
    }
}

private enum AnnotationTailPosition: Int {
    case left
    case right
    case center
}

class AnnotationCacheEntry: Equatable, Hashable {
    var wayname: String
    var coordinate: CLLocationCoordinate2D
    var intersection: EdgeIntersection?
    var feature: Feature
    var lastAccessTime: Date

    init(coordinate: CLLocationCoordinate2D, wayname: String, intersection: EdgeIntersection? = nil, feature: Feature) {
        self.wayname = wayname
        self.coordinate = coordinate
        self.intersection = intersection
        self.feature = feature
        self.lastAccessTime = Date()
    }

    static func == (lhs: AnnotationCacheEntry, rhs: AnnotationCacheEntry) -> Bool {
        return lhs.wayname == rhs.wayname
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(wayname.hashValue)
    }
}

class AnnotationCache {
    private let maxEntryAge = TimeInterval(30)
    var entries = Set<AnnotationCacheEntry>()
    var cachePruningTimer: Timer?

    init() {
        // periodically prune the cache to remove entries that have been passed already
        cachePruningTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true, block: { [weak self] _ in
            self?.prune()
        })
    }

    deinit {
        cachePruningTimer?.invalidate()
        cachePruningTimer = nil
    }

    func setValue(feature: Feature, coordinate: CLLocationCoordinate2D, intersection: EdgeIntersection?, for wayname: String) {
        entries.insert(AnnotationCacheEntry(coordinate: coordinate, wayname: wayname, intersection: intersection, feature: feature))
    }

    func value(for wayname: String) -> AnnotationCacheEntry? {
        let matchingEntry = entries.first { entry -> Bool in
            entry.wayname == wayname
        }

        if let matchingEntry = matchingEntry {
            // update the timestamp used for pruning the cache
            matchingEntry.lastAccessTime = Date()
        }

        return matchingEntry
    }

    private func prune() {
        let now = Date()

        entries.filter { now.timeIntervalSince($0.lastAccessTime) > maxEntryAge }.forEach { remove($0) }
    }

    public func remove(_ entry: AnnotationCacheEntry) {
        entries.remove(entry)
    }
}

// MARK: - UIGestureRecognizerDelegate methods

extension NavigationMapView: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer &&
            otherGestureRecognizer is UITapGestureRecognizer {
            return true
        }
        
        return false
    }
}
