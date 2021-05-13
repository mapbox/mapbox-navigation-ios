import UIKit
import MapboxMaps
import MapboxCoreMaps
import MapboxDirections
import MapboxCoreNavigation
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
    @objc dynamic public var reducedAccuracyActivatedMode: Bool = false {
        didSet {
            let frame = CGRect(origin: .zero, size: 75.0)
            let isHidden = userCourseView.isHidden
            userCourseView = reducedAccuracyActivatedMode
                ? UserHaloCourseView(frame: frame)
                : UserPuckCourseView(frame: frame)
            
            userCourseView.isHidden = isHidden
        }
    }
    
    /**
     `MapView`, which is added on top of `NavigationMapView` and allows to render navigation related components.
     */
    public private(set) var mapView: MapView!
    
    /**
     The object that acts as the navigation delegate of the map view.
     */
    public weak var delegate: NavigationMapViewDelegate?
    
    /**
     Most recent user location, which is used to place `UserCourseView`.
     */
    var mostRecentUserCourseViewLocation: CLLocation?

    @objc dynamic public var routeDurationAnnotationSelectedColor: UIColor = .selectedRouteDurationAnnotationColor
    @objc dynamic public var routeDurationAnnotationColor: UIColor = .routeDurationAnnotationColor
    @objc dynamic public var routeDurationAnnotationSelectedTextColor: UIColor = .selectedRouteDurationAnnotationTextColor
    @objc dynamic public var routeDurationAnnotationTextColor: UIColor = .routeDurationAnnotationTextColor

    /**
     List of Mapbox Maps font names to be used for any symbol layers added by the Navigation SDK.
     These are used for features such as Route Duration Annotations that are optionally added during route preview.
     See https://docs.mapbox.com/ios/maps/api/6.3.0/customizing-fonts.html for more information about server-side fonts.
     */
    @objc dynamic public var routeDurationAnnotationFontNames: [String] = ["DIN Pro Medium", "Noto Sans CJK JP Medium", "Arial Unicode MS Regular"]

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
            
            guard let _ = try? mapView.style.layer(withId: mainRouteLayerIdentifier, type: LineLayer.self),
                  let _ = try? mapView.style.layer(withId: mainRouteCasingLayerIdentifier, type: LineLayer.self) else { return false }
            
            return true
        }
    }
    
    /**
     A type that represents a `UIView` that is `CourseUpdatable`.
     */
    public typealias UserCourseView = UIView & CourseUpdatable
    
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
    
    /**
     A manager object, used to init and maintain predictive caching.
     */
    private(set) var predictiveCacheManager: PredictiveCacheManager?
    
    /**
     A `TileStore` instance used by map view.
     */
    open var mapTileStore: TileStore? {
        mapView.mapboxMap.__map.getResourceOptions().tileStore
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
    public init(frame: CGRect, navigationCameraType: NavigationCameraType = .mobile, tileStoreLocation: TileStoreConfiguration.Location? = .default) {
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
            updateUserCourseView(location)
            break
        }
    }
    
    func setupMapView(_ frame: CGRect, navigationCameraType: NavigationCameraType = .mobile, tileStoreLocation: TileStoreConfiguration.Location? = .default) {
        guard let accessToken = CredentialsManager.default.accessToken else {
            fatalError("Access token was not set.")
        }
        
        let tileStore = tileStoreLocation?.tileStore
        // TODO: allow customising tile store location.
        let resourceOptions = ResourceOptions(accessToken: accessToken, tileStore: tileStore)
        mapView = MapView(frame: frame, mapInitOptions: MapInitOptions(resourceOptions: resourceOptions))
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.ornaments.options.scaleBar.visibility = .hidden
        
        mapView.on(.renderFrameFinished) { [weak self] _ in
            guard let self = self,
                  let location = self.mostRecentUserCourseViewLocation else { return }
            self.updateUserCourseView(location, animated: false)
        }
        
        addSubview(mapView)
        
        mapView.pinTo(parentView: self)
        
        navigationCamera = NavigationCamera(mapView, navigationCameraType: navigationCameraType)
        navigationCamera.follow()
    }
    
    func setupGestureRecognizers() {
        for recognizer in mapView.gestureRecognizers ?? [] where recognizer is UITapGestureRecognizer {
            recognizer.addTarget(self, action: #selector(didReceiveTap(sender:)))
        }
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
        mapView.update {
            $0.render.preferredFramesPerSecond = NavigationMapView.FrameIntervalOptions.defaultFramesPerSecond
        }
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

        mapView.update {
            $0.render.preferredFramesPerSecond = preferredFramesPerSecond
        }
    }
    
    // MARK: - User tracking methods
    
    func installUserCourseView() {
        userCourseView.isHidden = true
        mapView.addSubview(userCourseView)
    }
    
    /**
     Updates `UserCourseView` to provided location.
     
     - parameter location: Location, where `UserCourseView` should be shown.
     - parameter animated: Property, which determines whether `UserCourseView` transition to new location will be animated.
     */
    public func updateUserCourseView(_ location: CLLocation, animated: Bool = false) {
        guard CLLocationCoordinate2DIsValid(location.coordinate) else { return }
        
        mostRecentUserCourseViewLocation = location
        
        // While animating to overview mode, don't animate the puck.
        let duration: TimeInterval = animated && navigationCamera.state != .transitionToOverview ? 1 : 0
        UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear]) { [weak self] in
            guard let screenCoordinate = self?.mapView.screenCoordinate(for: location.coordinate) else { return }
            self?.userCourseView.center = CGPoint(x: screenCoordinate.x, y: screenCoordinate.y)
        }
        
        userCourseView.update(location: location,
                              pitch: mapView.cameraState.pitch,
                              direction: mapView.cameraState.bearing,
                              animated: animated,
                              navigationCameraState: navigationCamera.state)
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
            mapView?.camera.setCamera(to: cameraOptions)
        }
    }

    /**
     Sets initial `CameraOptions` for specific coordinate.
     
     - parameter coordinate: Coordinate, where `MapView` will be centered.
     */
    func setInitialCamera(_ coordinate: CLLocationCoordinate2D) {
        guard let navigationViewportDataSource = navigationCamera.viewportDataSource as? NavigationViewportDataSource else { return }
        
        mapView.camera.setCamera(to: CameraOptions(center: coordinate,
                                                   zoom: CGFloat(navigationViewportDataSource.options.followingCameraOptions.maximumZoomLevel)))
        updateUserCourseView(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }

    @discardableResult func addRouteLayer(_ route: Route,
                                          below parentLayerIndentifier: String? = nil,
                                          isMainRoute: Bool = true,
                                          legIndex: Int? = nil) -> String? {
        guard let shape = route.shape else { return nil }
        
        let geoJSONSource = self.geoJSONSource(delegate?.navigationMapView(self, casingShapeFor: route) ?? shape)
        let sourceIdentifier = route.identifier(.source(isMainRoute: isMainRoute, isSourceCasing: true))
        
        do {
            try mapView.style.addSource(geoJSONSource, id: sourceIdentifier)
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
            lineLayer?.paint?.lineColor = .constant(.init(color: trafficUnknownColor))
            lineLayer?.paint?.lineWidth = .expression(Expression.routeLineWidthExpression())
            lineLayer?.layout?.lineJoin = .constant(.round)
            lineLayer?.layout?.lineCap = .constant(.round)
            
            // TODO: Verify that `isAlternativeRoute` parameter usage is needed.
            if isMainRoute {
                let congestionFeatures = route.congestionFeatures(legIndex: legIndex, roadClassesWithOverriddenCongestionLevels: roadClassesWithOverriddenCongestionLevels)
                let gradientStops = routeLineGradient(congestionFeatures,
                                                      fractionTraveled: routeLineTracksTraversal ? fractionTraveled : 0.0)
                lineLayer?.paint?.lineGradient = .expression((Expression.routeLineGradientExpression(gradientStops)))
            } else {
                if showsCongestionForAlternativeRoutes {
                    let gradientStops = routeLineGradient(route.congestionFeatures(roadClassesWithOverriddenCongestionLevels: roadClassesWithOverriddenCongestionLevels),
                                                          fractionTraveled: routeLineTracksTraversal ? fractionTraveled : 0.0,
                                                          isMain: false)
                    lineLayer?.paint?.lineGradient = .expression((Expression.routeLineGradientExpression(gradientStops)))
                } else {
                    lineLayer?.paint?.lineColor = .constant(.init(color: routeAlternateColor))
                }
            }
        }
        
        if let lineLayer = lineLayer {
            do {
                try mapView.style.addLayer(lineLayer,
                                           layerPosition: isMainRoute ?
                                            LayerPosition(above: mapView.mainRouteLineParentLayerIdentifier) :
                                            LayerPosition(below: parentLayerIndentifier))
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
            try mapView.style.addSource(geoJSONSource, id: sourceIdentifier)
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
            lineLayer?.paint?.lineColor = .constant(.init(color: routeCasingColor))
            lineLayer?.paint?.lineWidth = .expression(Expression.routeLineWidthExpression(1.5))
            lineLayer?.layout?.lineJoin = .constant(.round)
            lineLayer?.layout?.lineCap = .constant(.round)
            
            if isMainRoute {
                let gradientStops = routeLineGradient(fractionTraveled: routeLineTracksTraversal ? fractionTraveled : 0.0)
                lineLayer?.paint?.lineGradient = .expression(Expression.routeLineGradientExpression(gradientStops))
            } else {
                lineLayer?.paint?.lineColor = .constant(.init(color: routeAlternateCasingColor))
            }
        }
        
        if let lineLayer = lineLayer {
            do {
                try mapView.style.addLayer(lineLayer, layerPosition: LayerPosition(below: parentLayerIndentifier))
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
        let waypoints: [Waypoint] = Array(route.legs.dropLast().compactMap({ $0.destination }))

        var features = [Feature]()
        for (waypointIndex, waypoint) in waypoints.enumerated() {
            var feature = Feature(Point(waypoint.coordinate))
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
                
                if let _ = try? mapView.style.source(withId: waypointSourceIdentifier, type: GeoJSONSource.self) {
                    try mapView.style.updateGeoJSONSource(withId: waypointSourceIdentifier, geoJSON: shape)
                } else {
                    var waypointSource = GeoJSONSource()
                    waypointSource.data = .featureCollection(shape)
                    try mapView.style.addSource(waypointSource, id: waypointSourceIdentifier)
                    
                    let waypointCircleLayerIdentifier = NavigationMapView.LayerIdentifier.waypointCircleLayer
                    let circlesLayer = delegate?.navigationMapView(self,
                                                                   waypointCircleLayerWithIdentifier: waypointCircleLayerIdentifier,
                                                                   sourceIdentifier: waypointSourceIdentifier) ?? defaultWaypointCircleLayer()
                    
                    if let arrows = try? mapView.style.layer(withId: NavigationMapView.LayerIdentifier.arrowSymbolLayer, type: LineLayer.self) {
                        try mapView.style.addLayer(circlesLayer, layerPosition: LayerPosition(above: arrows.id))
                    } else {
                        let layerIdentifier = route.identifier(.route(isMainRoute: true))
                        try mapView.style.addLayer(circlesLayer, layerPosition: LayerPosition(above: layerIdentifier))
                    }
                    
                    let waypointSymbolLayerIdentifier = NavigationMapView.LayerIdentifier.waypointSymbolLayer
                    let symbolsLayer = delegate?.navigationMapView(self,
                                                                   waypointSymbolLayerWithIdentifier: waypointSymbolLayerIdentifier,
                                                                   sourceIdentifier: waypointSourceIdentifier) ?? defaultWaypointSymbolLayer()
                    
                    try mapView.style.addLayer(symbolsLayer, layerPosition: LayerPosition(above: circlesLayer.id))
                }
            } catch {
                NSLog("Failed to perform operation while adding waypoint with error: \(error.localizedDescription).")
            }
        }

        if let lastLeg = route.legs.last, let destinationCoordinate = lastLeg.destination?.coordinate {
            mapView.annotations.removeAnnotations(annotationsToRemove())
            
            var destinationAnnotation = PointAnnotation(coordinate: destinationCoordinate)
            let title = NavigationMapView.AnnotationIdentifier.finalDestinationAnnotation
            destinationAnnotation.title = title
            mapView.annotations.addAnnotation(destinationAnnotation)
            
            delegate?.navigationMapView(self, didAdd: destinationAnnotation)
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
        circleLayer.paint?.circleColor = .constant(.init(color: UIColor(red:0.9, green:0.9, blue:0.9, alpha:1.0)))
        circleLayer.paint?.circleOpacity = .expression(opacity)
        circleLayer.paint?.circleRadius = .constant(.init(10))
        circleLayer.paint?.circleStrokeColor = .constant(.init(color: UIColor.black))
        circleLayer.paint?.circleStrokeWidth = .constant(.init(1))
        circleLayer.paint?.circleStrokeOpacity = .expression(opacity)
        
        return circleLayer
    }
    
    func defaultWaypointSymbolLayer() -> SymbolLayer {
        var symbolLayer = SymbolLayer(id: NavigationMapView.LayerIdentifier.waypointSymbolLayer)
        symbolLayer.source = NavigationMapView.SourceIdentifier.waypointSource
        symbolLayer.layout?.textField = .expression(Exp(.toString) {
            Exp(.get) {
                "name"
            }
        })
        symbolLayer.layout?.textSize = .constant(.init(10))
        symbolLayer.paint?.textOpacity = .expression(Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "waypointCompleted"
                }
            }
            0.5
            1
        })
        symbolLayer.paint?.textHaloWidth = .constant(.init(0.25))
        symbolLayer.paint?.textHaloColor = .constant(.init(color: UIColor.black))
        
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
        
        mapView.style.removeLayers(layerIdentifiers)
        mapView.style.removeSources(sourceIdentifiers)
        
        routes = nil
        routePoints = nil
        routeLineGranularDistances = nil
    }
    
    /**
     Removes all existing `Waypoint` objects from `MapView`, which were added by `NavigationMapView`.
     */
    public func removeWaypoints() {
        mapView.annotations.removeAnnotations(annotationsToRemove())
        
        let layers: Set = [
            NavigationMapView.LayerIdentifier.waypointCircleLayer,
            NavigationMapView.LayerIdentifier.waypointSymbolLayer
        ]
        
        mapView.style.removeLayers(layers)
        mapView.style.removeSources([NavigationMapView.SourceIdentifier.waypointSource])
    }
    
    func annotationsToRemove() -> [Annotation] {
        let title = NavigationMapView.AnnotationIdentifier.finalDestinationAnnotation
        return mapView.annotations.annotations.values.filter({ $0.title == title })
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
            try mapView.style.addImage(triangleImage, id: NavigationMapView.ImageIdentifier.arrowImage)
            let step = route.legs[legIndex].steps[stepIndex]
            let maneuverCoordinate = step.maneuverLocation
            guard step.maneuverType != .arrive else { return }
            
            // TODO: Implement ability to change `shaftLength` depending on zoom level.
            let shaftLength = max(min(30 * mapView.metersPerPointAtLatitude(latitude: maneuverCoordinate.latitude), 30), 10)
            let shaftPolyline = route.polylineAroundManeuver(legIndex: legIndex, stepIndex: stepIndex, distance: shaftLength)
            
            if shaftPolyline.coordinates.count > 1 {
                let mainRouteLayerIdentifier = route.identifier(.route(isMainRoute: true))
                let minimumZoomLevel: Double = 14.5
                let shaftStrokeCoordinates = shaftPolyline.coordinates
                let shaftDirection = shaftStrokeCoordinates[shaftStrokeCoordinates.count - 2].direction(to: shaftStrokeCoordinates.last!)
                
                var arrowSource = GeoJSONSource()
                arrowSource.data = .feature(Feature(shaftPolyline))
                var arrowLayer = LineLayer(id: NavigationMapView.LayerIdentifier.arrowLayer)
                if let _ = try? mapView.style.source(withId: NavigationMapView.SourceIdentifier.arrowSource, type: GeoJSONSource.self) {
                    let geoJSON = Feature(shaftPolyline)
                    try mapView.style.updateGeoJSONSource(withId: NavigationMapView.SourceIdentifier.arrowSource, geoJSON: geoJSON)
                } else {
                    arrowLayer.minZoom = Double(minimumZoomLevel)
                    arrowLayer.layout?.lineCap = .constant(.butt)
                    arrowLayer.layout?.lineJoin = .constant(.round)
                    arrowLayer.paint?.lineWidth = .expression(Expression.routeLineWidthExpression(0.70))
                    arrowLayer.paint?.lineColor = .constant(.init(color: maneuverArrowColor))
                    
                    try mapView.style.addSource(arrowSource, id: NavigationMapView.SourceIdentifier.arrowSource)
                    arrowLayer.source = NavigationMapView.SourceIdentifier.arrowSource
                    
                    if let _ = try? mapView.style.layer(withId: NavigationMapView.LayerIdentifier.waypointCircleLayer, type: LineLayer.self) {
                        try mapView.style.addLayer(arrowLayer, layerPosition: LayerPosition(below: NavigationMapView.LayerIdentifier.waypointCircleLayer))
                    } else {
                        try mapView.style.addLayer(arrowLayer)
                    }
                }
                
                var arrowStrokeSource = GeoJSONSource()
                arrowStrokeSource.data = .feature(Feature(shaftPolyline))
                var arrowStrokeLayer = LineLayer(id: NavigationMapView.LayerIdentifier.arrowStrokeLayer)
                if let _ = try? mapView.style.source(withId: NavigationMapView.SourceIdentifier.arrowStrokeSource, type: GeoJSONSource.self) {
                    let geoJSON = Feature(shaftPolyline)
                    try mapView.style.updateGeoJSONSource(withId: NavigationMapView.SourceIdentifier.arrowStrokeSource, geoJSON: geoJSON)
                } else {
                    arrowStrokeLayer.minZoom = arrowLayer.minZoom
                    arrowStrokeLayer.layout?.lineCap = arrowLayer.layout?.lineCap
                    arrowStrokeLayer.layout?.lineJoin = arrowLayer.layout?.lineJoin
                    arrowStrokeLayer.paint?.lineWidth = .expression(Expression.routeLineWidthExpression(0.80))
                    arrowStrokeLayer.paint?.lineColor = .constant(.init(color: maneuverArrowStrokeColor))
                    
                    try mapView.style.addSource(arrowStrokeSource, id: NavigationMapView.SourceIdentifier.arrowStrokeSource)
                    arrowStrokeLayer.source = NavigationMapView.SourceIdentifier.arrowStrokeSource
                    try mapView.style.addLayer(arrowStrokeLayer, layerPosition: LayerPosition(above: mainRouteLayerIdentifier))
                }
                
                let point = Point(shaftStrokeCoordinates.last!)
                var arrowSymbolSource = GeoJSONSource()
                arrowSymbolSource.data = .feature(Feature(point))
                if let _ = try? mapView.style.source(withId: NavigationMapView.SourceIdentifier.arrowSymbolSource, type: GeoJSONSource.self) {
                    let geoJSON = Feature.init(geometry: Geometry.point(point))
                    try mapView.style.updateGeoJSONSource(withId: NavigationMapView.SourceIdentifier.arrowSymbolSource, geoJSON: geoJSON)
                    mapView.mapboxMap.__map.setStyleLayerPropertyForLayerId(NavigationMapView.LayerIdentifier.arrowSymbolLayer, property: "icon-rotate", value: shaftDirection)
                    mapView.mapboxMap.__map.setStyleLayerPropertyForLayerId(NavigationMapView.LayerIdentifier.arrowSymbolCasingLayer, property: "icon-rotate", value: shaftDirection)
                } else {
                    var arrowSymbolLayer = SymbolLayer(id: NavigationMapView.LayerIdentifier.arrowSymbolLayer)
                    arrowSymbolLayer.minZoom = Double(minimumZoomLevel)
                    arrowSymbolLayer.layout?.iconImage = .constant(.name(NavigationMapView.ImageIdentifier.arrowImage))
                    // FIXME: `iconColor` has no effect.
                    arrowSymbolLayer.paint?.iconColor = .constant(.init(color: maneuverArrowColor))
                    arrowSymbolLayer.layout?.iconRotationAlignment = .constant(.map)
                    arrowSymbolLayer.layout?.iconRotate = .constant(.init(shaftDirection))
                    arrowSymbolLayer.layout?.iconSize = .expression(Expression.routeLineWidthExpression(0.12))
                    arrowSymbolLayer.layout?.iconAllowOverlap = .constant(true)
                    
                    var arrowSymbolCasingLayer = SymbolLayer(id: NavigationMapView.LayerIdentifier.arrowSymbolCasingLayer)
                    arrowSymbolCasingLayer.minZoom = arrowSymbolLayer.minZoom
                    arrowSymbolCasingLayer.layout?.iconImage = arrowSymbolLayer.layout?.iconImage
                    // FIXME: `iconColor` has no effect.
                    arrowSymbolCasingLayer.paint?.iconColor = .constant(.init(color: maneuverArrowStrokeColor))
                    arrowSymbolCasingLayer.layout?.iconRotationAlignment = arrowSymbolLayer.layout?.iconRotationAlignment
                    arrowSymbolCasingLayer.layout?.iconRotate = arrowSymbolLayer.layout?.iconRotate
                    arrowSymbolCasingLayer.layout?.iconSize = .expression(Expression.routeLineWidthExpression(0.14))
                    arrowSymbolCasingLayer.layout?.iconAllowOverlap = arrowSymbolLayer.layout?.iconAllowOverlap
                    
                    try mapView.style.addSource(arrowSymbolSource, id: NavigationMapView.SourceIdentifier.arrowSymbolSource)
                    arrowSymbolLayer.source = NavigationMapView.SourceIdentifier.arrowSymbolSource
                    arrowSymbolCasingLayer.source = NavigationMapView.SourceIdentifier.arrowSymbolSource
                    
                    try mapView.style.addLayer(arrowSymbolLayer)
                    try mapView.style.addLayer(arrowSymbolCasingLayer, layerPosition: LayerPosition(below: NavigationMapView.LayerIdentifier.arrowSymbolLayer))
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
        mapView.style.removeLayers(layers)
        
        let sources: Set = [
            NavigationMapView.SourceIdentifier.arrowSource,
            NavigationMapView.SourceIdentifier.arrowStrokeSource,
            NavigationMapView.SourceIdentifier.arrowSymbolSource
        ]
        mapView.style.removeSources(sources)
    }
    
    // MARK: - Route duration annotations methods

    /**
     Shows a callout containing the duration of each route.
     Useful as a way to give the user more information when picking between multiple route alternatives.
     If the route contains any tolled segments then the callout will specify that as well.
     */
    public func showRouteDurations(along routes: [Route]?) {
        guard let visibleRoutes = routes, visibleRoutes.count > 0 else { return }
        updateAnnotationSymbolImages()
        updateRouteDurations(along: visibleRoutes)
    }

    /**
     Updates the image assets in the map style for the route duration annotations. Useful when the desired callout colors change, such as when transitioning between light and dark mode on iOS 13 and later.
     */
    private func updateAnnotationSymbolImages() {
        guard let style = mapView.style,
              style.image(withId: "RouteInfoAnnotationLeftHanded") == nil,
              style.image(withId: "RouteInfoAnnotationRightHanded") == nil else { return }
        
        // Right-hand pin
        if let image = Bundle.mapboxNavigation.image(named: "RouteInfoAnnotationRightHanded") {
            do {
                // define the "stretchable" areas in the image that will be fitted to the text label
                let stretchX = [ImageStretches(first: Float(24), second: Float(40))]
                let stretchY = [ImageStretches(first: Float(25), second: Float(35))]
                let imageContent = ImageContent(left: 24, top: 25, right: 40, bottom: 35)
                
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
            } catch {
                NSLog("Failed to add image to style with error: \(error.localizedDescription).")
            }
        }
        
        // Left-hand pin
        if let image = Bundle.mapboxNavigation.image(named: "RouteInfoAnnotationLeftHanded") {
            do {
                // define the "stretchable" areas in the image that will be fitted to the text label
                let stretchX = [ImageStretches(first: Float(34), second: Float(50))]
                let stretchY = [ImageStretches(first: Float(25), second: Float(35))]
                let imageContent = ImageContent(left: 34, top: 25, right: 50, bottom: 35)
                
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
            } catch {
                NSLog("Failed to add image to style with error: \(error.localizedDescription).")
            }
        }
    }

    /**
     Remove any old route duration callouts and generate new ones for each passed in route.
     */
    private func updateRouteDurations(along routes: [Route]?) {
        guard let style = mapView.style else { return }
        
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

        var features = [Feature]()

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
            var feature = Feature(Point(annotationCoordinate))

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
        self.addRouteAnnotationSymbolLayer(features: FeatureCollection(features: features))
    }

    /**
     Add the MGLSymbolStyleLayer for the route duration annotations.
     */
    private func addRouteAnnotationSymbolLayer(features: FeatureCollection) {
        guard let style = mapView.style else { return }

        let routeDurationAnnotationsSourceIdentifier = NavigationMapView.SourceIdentifier.routeDurationAnnotationsSource
        do {
            if let _ = try? mapView.style.source(withId: routeDurationAnnotationsSourceIdentifier, type: GeoJSONSource.self) {
                try mapView.style.updateGeoJSONSource(withId: routeDurationAnnotationsSourceIdentifier, geoJSON: features)
            } else {
                var dataSource = GeoJSONSource()
                dataSource.data = .featureCollection(features)
                try mapView.style.addSource(dataSource, id: routeDurationAnnotationsSourceIdentifier)
            }
        } catch {
            NSLog("Failed to perform operation on \(routeDurationAnnotationsSourceIdentifier) with error: \(error.localizedDescription).")
        }

        let routeDurationAnnotationsLayerIdentifier = NavigationMapView.LayerIdentifier.routeDurationAnnotationsLayer
        var shapeLayer: SymbolLayer
        if let layer = try? mapView.style.layer(withId: routeDurationAnnotationsLayerIdentifier, type: SymbolLayer.self) {
            shapeLayer = layer
        } else {
            shapeLayer = SymbolLayer(id: routeDurationAnnotationsLayerIdentifier)
        }

        shapeLayer.source = routeDurationAnnotationsSourceIdentifier

        shapeLayer.layout?.textField = .expression(Exp(.get) {
            "text"
        })

        shapeLayer.layout?.iconImage = .expression(Exp(.get) {
            "imageName"
        })

        shapeLayer.paint?.textColor = .expression(Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "selected"
                }
            }
            routeDurationAnnotationSelectedTextColor
            routeDurationAnnotationTextColor
        })

        shapeLayer.layout?.textSize = .constant(16)
        shapeLayer.layout?.iconTextFit = .constant(IconTextFit.both)
        shapeLayer.layout?.iconAllowOverlap = .constant(true)
        shapeLayer.layout?.textAllowOverlap = .constant(true)
        shapeLayer.layout?.textJustify = .constant(TextJustify.left)
        shapeLayer.layout?.symbolZOrder = .constant(SymbolZOrder.auto)
        shapeLayer.layout?.textFont = .constant(self.routeDurationAnnotationFontNames)

        do {
            try style.addLayer(shapeLayer)
        } catch {
            NSLog("Failed to add \(routeDurationAnnotationsLayerIdentifier) with error: \(error.localizedDescription).")
        }

        let symbolSortKeyString =
        """
        ["get", "sortOrder"]
        """

        if let expressionData = symbolSortKeyString.data(using: .utf8),
           let expJSONObject = try? JSONSerialization.jsonObject(with: expressionData, options: []) {
            mapView.mapboxMap.__map.setStyleLayerPropertyForLayerId(routeDurationAnnotationsLayerIdentifier,
                                                                    property: "symbol-sort-key",
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
            mapView.mapboxMap.__map.setStyleLayerPropertyForLayerId(routeDurationAnnotationsLayerIdentifier,
                                                                    property: "icon-anchor",
                                                                    value: expJSONObject)
            mapView.mapboxMap.__map.setStyleLayerPropertyForLayerId(routeDurationAnnotationsLayerIdentifier,
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
            mapView.mapboxMap.__map.setStyleLayerPropertyForLayerId(routeDurationAnnotationsLayerIdentifier,
                                                                    property: "icon-offset",
                                                                    value: expJSONObject)
            
            mapView.mapboxMap.__map.setStyleLayerPropertyForLayerId(routeDurationAnnotationsLayerIdentifier,
                                                                    property: "text-offset",
                                                                    value: expJSONObject)
        }
    }

    /**
     Removes all visible route duration callouts.
     */
    public func removeRouteDurations() {
        guard let style = mapView.style else { return }
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
                    
                    var feature = Feature(Point(coordinateFromStart))
                    feature.properties = [
                        "instruction": instruction.text
                    ]
                    featureCollection.features.append(feature)
                }
            }
        }
        
        do {
            if let _ = try? mapView.style.source(withId: NavigationMapView.SourceIdentifier.voiceInstructionSource, type: GeoJSONSource.self) {
                try mapView.style.updateGeoJSONSource(withId: NavigationMapView.SourceIdentifier.voiceInstructionSource, geoJSON: featureCollection)
            } else {
                var source = GeoJSONSource()
                source.data = .featureCollection(featureCollection)
                try mapView.style.addSource(source, id: NavigationMapView.SourceIdentifier.voiceInstructionSource)
                
                var symbolLayer = SymbolLayer(id: NavigationMapView.LayerIdentifier.voiceInstructionLabelLayer)
                symbolLayer.source = NavigationMapView.SourceIdentifier.voiceInstructionSource
                
                let instruction = Exp(.toString) {
                    Exp(.get) {
                        "instruction"
                    }
                }
                
                symbolLayer.layout?.textField = .expression(instruction)
                symbolLayer.layout?.textSize = .constant(14)
                symbolLayer.paint?.textHaloWidth = .constant(1)
                symbolLayer.paint?.textHaloColor = .constant(.init(color: .white))
                symbolLayer.paint?.textOpacity = .constant(0.75)
                symbolLayer.layout?.textAnchor = .constant(.bottom)
                symbolLayer.layout?.textJustify = .constant(.left)
                try mapView.style.addLayer(symbolLayer)
                
                var circleLayer = CircleLayer(id: NavigationMapView.LayerIdentifier.voiceInstructionCircleLayer)
                circleLayer.source = NavigationMapView.SourceIdentifier.voiceInstructionSource
                circleLayer.paint?.circleRadius = .constant(5)
                circleLayer.paint?.circleOpacity = .constant(0.75)
                circleLayer.paint?.circleColor = .constant(.init(color: .white))
                try mapView.style.addLayer(circleLayer)
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
    
    private func waypoints(on routes: [Route], closeTo point: CGPoint) -> [Waypoint]? {
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
}
