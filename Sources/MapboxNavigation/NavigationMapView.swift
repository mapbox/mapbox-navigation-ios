import UIKit
import MapboxMaps
import MapboxCoreMaps
import MapboxDirections
import MapboxCoreNavigation
import Turf

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
    
    enum IdentifierType: Int {
        case source
        
        case route
        
        case routeCasing
    }
    
    struct IdentifierString {
        static let identifier = Bundle.mapboxNavigation.bundleIdentifier ?? ""
        static let arrowImage = "triangle-tip-navigation"
        static let arrowSource = "\(identifier)_arrowSource"
        static let arrow = "\(identifier)_arrow"
        static let arrowStrokeSource = "\(identifier)arrowStrokeSource"
        static let arrowStroke = "\(identifier)_arrowStroke"
        static let arrowSymbolSource = "\(identifier)_arrowSymbolSource"
        static let arrowSymbol = "\(identifier)_arrowSymbol"
        static let arrowCasingSymbol = "\(identifier)_arrowCasingSymbol"
        static let instructionSource = "\(identifier)_instructionSource"
        static let instructionLabel = "\(identifier)_instructionLabel"
        static let instructionCircle = "\(identifier)_instructionCircle"
        static let waypointSource = "\(identifier)_waypointSource"
        static let waypointCircle = "\(identifier)_waypointCircle"
        static let waypointSymbol = "\(identifier)_waypointSymbol"
        static let buildingExtrusionLayer = "\(identifier)_buildingExtrusionLayer"
        static let intersectionAnnotationsLayer = "\(identifier)_intersectionAnnotations"
    }
    
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
    var routes: [Route]?
    var routePoints: RoutePoints?
    var routeLineGranularDistances: RouteLineGranularDistances?
    var routeRemainingDistancesIndex: Int?
    var routeLineTracksTraversal: Bool = false
    var fractionTraveled: Double = 0.0
    var preFractionTraveled: Double = 0.0
    var vanishingRouteLineUpdateTimer: Timer? = nil
    
    var showsRoute: Bool {
        get {
            guard let mainRouteLayerIdentifier = identifier(routes?.first, identifierType: .route),
                  let mainRouteCasingLayerIdentifier = identifier(routes?.first, identifierType: .routeCasing) else { return false }
            
            guard let _ = try? mapView.style.getLayer(with: mainRouteLayerIdentifier, type: LineLayer.self).get(),
                  let _ = try? mapView.style.getLayer(with: mainRouteCasingLayerIdentifier, type: LineLayer.self).get() else { return false }

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
     */
    public init(frame: CGRect, navigationCameraType: NavigationCameraType = .mobile) {
        super.init(frame: frame)
        
        setupMapView(frame, navigationCameraType: navigationCameraType)
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
        setupGestureRecognizers()
        installUserCourseView()
        subscribeForNotifications()
        annotationCache = AnnotationCache()
    }

    deinit {
        annotationCache = nil
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
    
    func setupMapView(_ frame: CGRect, navigationCameraType: NavigationCameraType = .mobile) {
        guard let accessToken = AccountManager.shared.accessToken else {
            fatalError("Access token was not set.")
        }
        
        let options = ResourceOptions(accessToken: accessToken,
                                      tileStorePath: Bundle.mapboxNavigation.suggestedTileURL?.path,
                                      loadTilePacksFromNetwork: false)
        
        mapView = MapView(with: frame, resourceOptions: options)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.update {
            $0.ornaments.showsScale = false
        }
        
        mapView.on(.renderFrameFinished) { [weak self] _ in
            guard let self = self,
                  let location = self.mostRecentUserCourseViewLocation else { return }
            self.updateUserCourseView(location, animated: false)
        }

        mapView.on(.mapLoaded)  { [weak self] _ in
            self?.addAnnotationSymbolImages()
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
     
     - parameter options: options, controlling caching parameters like area radius and concurrent downloading threads.
     */
    public func enablePredictiveCaching(options predictiveCacheOptions: PredictiveCacheOptions) {
        let mapTileSource = try? TileStoreManager.getTileStore(for: mapView.__map.getResourceOptions())
        var mapOptions: PredictiveCacheManager.MapOptions?
        if let tileStore = mapTileSource?.value as? TileStore {
            mapOptions = PredictiveCacheManager.MapOptions(tileStore, mapView.styleSourceDatasets(["raster", "vector"]))
        }
        
        predictiveCacheManager = PredictiveCacheManager(predictiveCacheOptions: predictiveCacheOptions,
                                                        mapOptions: mapOptions)
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
    
    /**
     Updates the map view’s preferred frames per second to the appropriate value for the current route progress.
     
     This method accounts for the proximity to a maneuver and the current power source.
     It has no effect if `NavigationCameraState` is in `.following` mode.
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
     */
    public func updateUserCourseView(_ location: CLLocation, animated: Bool = false) {
        guard CLLocationCoordinate2DIsValid(location.coordinate) else { return }
        
        mostRecentUserCourseViewLocation = location
        
        // While animating to overview mode, don't animate the puck.
        let duration: TimeInterval = animated && navigationCamera.state != .transitionToOverview ? 1 : 0
        UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear]) { [weak self] in
            guard let point = self?.mapView.screenCoordinate(for: location.coordinate).point else { return }
            self?.userCourseView.center = point
        }
        
        userCourseView.update(location: location,
                              pitch: mapView.pitch,
                              direction: mapView.bearing,
                              animated: animated,
                              navigationCameraState: navigationCamera.state)
    }
    
    // MARK: Feature addition/removal properties and methods
    
    /**
     Showcases route array. Adds routes and waypoints to map, and sets camera to point encompassing the route.
     
     - parameter routes: List of `Route` objects, which will be shown on `MapView.`
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
    
    func fitCamera(to route: Route, animated: Bool = false) {
        guard let routeShape = route.shape, !routeShape.coordinates.isEmpty else { return }
        let edgeInsets = safeArea + UIEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
        if let cameraOptions = mapView?.cameraManager.camera(fitting: .lineString(routeShape),
                                                             edgePadding: edgeInsets) {
            mapView?.cameraManager.setCamera(to: cameraOptions, animated: animated)
        }
    }
    
    public func show(_ routes: [Route], legIndex: Int = 0) {
        removeRoutes()
        
        self.routes = routes
        
        // TODO: Add ability to handle legIndex.
        var parentLayerIdentifier: String? = nil
        for (index, route) in routes.enumerated() {
            if index == 0 {
                parentLayerIdentifier = addMainRouteLayer(route)
                parentLayerIdentifier = addMainRouteCasingLayer(route, below: parentLayerIdentifier)
                
                if routeLineTracksTraversal {
                    initPrimaryRoutePoints(route: route)
                }
                
                continue
            }
            
            parentLayerIdentifier = addAlternativeRouteLayer(route,  below: parentLayerIdentifier)
            addAlternativeRouteCasingLayer(route, below: parentLayerIdentifier)
        }
    }
    
    /**
     Sets initial `CameraOptions` for specific coordinate.
     
     - parameter coordinate: Coordinate, where `MapView` will be centered.
     */
    func setInitialCamera(_ coordinate: CLLocationCoordinate2D) {
        guard let navigationViewportDataSource = navigationCamera.viewportDataSource as? NavigationViewportDataSource else { return }
        
        let zoom = CGFloat(ZoomLevelForAltitude(navigationViewportDataSource.defaultAltitude,
                                                mapView.pitch,
                                                coordinate.latitude,
                                                mapView.bounds.size))
        
        mapView.cameraManager.setCamera(to: CameraOptions(center: coordinate, zoom: zoom))
        updateUserCourseView(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
    
    @discardableResult func addMainRouteLayer(_ route: Route) -> String? {
        guard let shape = route.shape else { return nil }
        
        var geoJSONSource = GeoJSONSource()
        geoJSONSource.data = .geometry(.lineString(shape))
        geoJSONSource.lineMetrics = true
        
        guard let sourceIdentifier = identifier(route, identifierType: .source) else { return nil }
        mapView.style.addSource(source: geoJSONSource, identifier: sourceIdentifier)
        
        let fractionTraveledForStops = routeLineTracksTraversal ? fractionTraveled : 0.0
        guard let layerIdentifier = identifier(route, identifierType: .route) else { return nil }
        var lineLayer = LineLayer(id: layerIdentifier)
        lineLayer.source = sourceIdentifier
        lineLayer.paint?.lineWidth = .expression(Expression.routeLineWidthExpression())
        lineLayer.layout?.lineJoin = .constant(.round)
        lineLayer.layout?.lineCap = .constant(.round)
        
        if let gradientStops = routeLineGradient(route, fractionTraveled: fractionTraveledForStops) {
            lineLayer.paint?.lineGradient = .expression((Expression.routeLineGradientExpression(gradientStops)))
        }
        
        var parentLayer: String? {
            var parentLayer: String? = nil
            let identifiers = [
                IdentifierString.arrow,
                IdentifierString.arrowSymbol,
                IdentifierString.arrowCasingSymbol,
                IdentifierString.arrowStroke,
                IdentifierString.waypointCircle,
                IdentifierString.buildingExtrusionLayer
            ]
            
            guard let layers = try? mapView.__map.getStyleLayers().reversed() else { return nil }
            for layer in layers {
                if !(layer.type == "symbol") && !identifiers.contains(layer.id) {
                    let sourceLayer = try? mapView.__map.getStyleLayerProperty(forLayerId: layer.id, property: "source-layer").value as? String
                    
                    if let sourceLayer = sourceLayer,
                       sourceLayer.isEmpty {
                        continue
                    }
                    
                    parentLayer = layer.id
                    break
                }
            }
            
            return parentLayer
        }
        
        mapView.style.addLayer(layer: lineLayer, layerPosition: LayerPosition(above: parentLayer))
        
        return layerIdentifier
    }
    
    @discardableResult func addMainRouteCasingLayer(_ route: Route, below parentLayerIndentifier: String? = nil) -> String? {
        guard let shape = route.shape else { return nil }
        
        var geoJSONSource = GeoJSONSource()
        geoJSONSource.data = .geometry(.lineString(shape))
        geoJSONSource.lineMetrics = true
        
        guard let sourceIdentifier = identifier(route, identifierType: .source, isMainRouteCasingSource: true) else { return nil }
        mapView.style.addSource(source: geoJSONSource, identifier: sourceIdentifier)
        
        let fractionTraveledForStops = routeLineTracksTraversal ? fractionTraveled : 0.0
        guard let layerIdentifier = identifier(route, identifierType: .routeCasing) else { return nil }
        var lineLayer = LineLayer(id: layerIdentifier)
        lineLayer.source = sourceIdentifier
        lineLayer.paint?.lineColor = .constant(.init(color: routeCasingColor))
        lineLayer.paint?.lineWidth = .expression(Expression.routeLineWidthExpression(1.5))
        lineLayer.layout?.lineJoin = .constant(.round)
        lineLayer.layout?.lineCap = .constant(.round)
        
        mapView.style.addLayer(layer: lineLayer, layerPosition: LayerPosition(below: parentLayerIndentifier))
        
        let gradientStops = routeCasingGradient(fractionTraveledForStops)
        lineLayer.paint?.lineGradient = .expression(Expression.routeLineGradientExpression(gradientStops))

        return layerIdentifier
    }
    
    @discardableResult func addAlternativeRouteLayer(_ route: Route, below parentLayerIndentifier: String? = nil) -> String? {
        guard let shape = route.shape else { return nil }
        
        var geoJSONSource = GeoJSONSource()
        geoJSONSource.data = .geometry(.lineString(shape))
        geoJSONSource.lineMetrics = true
        
        guard let sourceIdentifier = identifier(route, identifierType: .source) else { return nil }
        mapView.style.addSource(source: geoJSONSource, identifier: sourceIdentifier)
        
        guard let layerIdentifier = identifier(route, identifierType: .route) else { return nil }
        var lineLayer = LineLayer(id: layerIdentifier)
        lineLayer.source = sourceIdentifier
        lineLayer.paint?.lineColor = .constant(.init(color: routeAlternateColor))
        lineLayer.paint?.lineWidth = .expression(Expression.routeLineWidthExpression())
        lineLayer.layout?.lineJoin = .constant(.round)
        lineLayer.layout?.lineCap = .constant(.round)

        if showsCongestionForAlternativeRoutes, let gradientStops = routeLineGradient(route, fractionTraveled: 0.0, isMain: false) {
            lineLayer.paint?.lineGradient = .expression((Expression.routeLineGradientExpression(gradientStops)))
        }
        mapView.style.addLayer(layer: lineLayer, layerPosition: LayerPosition(below: parentLayerIndentifier))
        
        return layerIdentifier
    }
    
    @discardableResult func addAlternativeRouteCasingLayer(_ route: Route, below parentLayerIndentifier: String? = nil) -> String? {
        guard let shape = route.shape else { return nil }
        
        var geoJSONSource = GeoJSONSource()
        geoJSONSource.data = .geometry(.lineString(shape))
        geoJSONSource.lineMetrics = true
        
        guard let sourceIdentifier = identifier(route, identifierType: .source) else { return nil }
        mapView.style.addSource(source: geoJSONSource, identifier: sourceIdentifier)
        
        guard let layerIdentifier = identifier(route, identifierType: .routeCasing) else { return nil }
        var lineLayer = LineLayer(id: layerIdentifier)
        lineLayer.source = sourceIdentifier
        lineLayer.paint?.lineColor = .constant(.init(color: routeAlternateCasingColor))
        lineLayer.paint?.lineWidth = .expression(Expression.routeLineWidthExpression(1.5))
        lineLayer.layout?.lineJoin = .constant(.round)
        lineLayer.layout?.lineCap = .constant(.round)
        
        mapView.style.addLayer(layer: lineLayer, layerPosition: LayerPosition(below: parentLayerIndentifier))
        
        return layerIdentifier
    }
    
    /**
     Adds the route waypoints to the map given the current leg index. Previous waypoints for completed legs will be omitted.
     */
    public func showWaypoints(on route: Route, legIndex: Int = 0) {
        let waypoints: [Waypoint] = Array(route.legs.dropLast().compactMap({$0.destination}))

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

        if route.legs.count > 1 { // are we on a multipoint route?
            routes = [route]

            if let _ = try? mapView.style.getSource(identifier: IdentifierString.waypointSource, type: GeoJSONSource.self).get() {
                let _ = mapView.style.updateGeoJSON(for: IdentifierString.waypointSource, with: shape)
            } else {
                var waypointSource = GeoJSONSource()
                waypointSource.data = .featureCollection(shape)
                mapView.style.addSource(source: waypointSource, identifier: IdentifierString.waypointSource)

                let circles = delegate?.navigationMapView(self, waypointCircleLayerWithIdentifier: IdentifierString.waypointCircle, sourceIdentifier: IdentifierString.waypointSource) ?? defaultWaypointCircleLayer()
                let symbols = delegate?.navigationMapView(self, waypointSymbolLayerWithIdentifier: IdentifierString.waypointSymbol, sourceIdentifier: IdentifierString.waypointSource) ?? defaultWaypointSymbolLayer()

                if let arrows = try? mapView.style.getLayer(with: IdentifierString.arrowSymbol, type: LineLayer.self).get() {
                    mapView.style.addLayer(layer: circles, layerPosition: LayerPosition(above: arrows.id))
                } else {
                    guard let layerIdentifier = identifier(route, identifierType: .route) else { return }
                    mapView.style.addLayer(layer: circles, layerPosition: LayerPosition(above: layerIdentifier))
                }
                mapView.style.addLayer(layer: symbols, layerPosition: LayerPosition(above: circles.id))
            }
        }

        if let lastLeg = route.legs.last, let destinationCoordinate = lastLeg.destination?.coordinate {
            mapView.annotationManager.removeAnnotations(annotationsToRemove())
            
            var destinationAnnotation = PointAnnotation(coordinate: destinationCoordinate)
            destinationAnnotation.title = "navigation_annotation"
            mapView.annotationManager.addAnnotation(destinationAnnotation)
        }
    }
    
    func defaultWaypointCircleLayer() -> CircleLayer {
        var circles = CircleLayer(id: IdentifierString.waypointCircle)
        circles.source = IdentifierString.waypointSource
        let opacity = Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "waypointCompleted"
                }
            }
            0.5
            1
        }
        circles.paint?.circleColor = .constant(.init(color: UIColor(red:0.9, green:0.9, blue:0.9, alpha:1.0)))
        circles.paint?.circleOpacity = .expression(opacity)
        circles.paint?.circleRadius = .constant(.init(10))
        circles.paint?.circleStrokeColor = .constant(.init(color: UIColor.black))
        circles.paint?.circleStrokeWidth = .constant(.init(1))
        circles.paint?.circleStrokeOpacity = .expression(opacity)
        return circles
    }
    
    func defaultWaypointSymbolLayer() -> SymbolLayer {
        var symbols = SymbolLayer(id: IdentifierString.waypointSymbol)
        symbols.source = IdentifierString.waypointSource
        symbols.layout?.textField = .expression(Exp(.toString) {
            Exp(.get) {
                "name"
            }
        })
        symbols.layout?.textSize = .constant(.init(10))
        symbols.paint?.textOpacity = .expression(Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "waypointCompleted"
                }
            }
            0.5
            1
        })
        symbols.paint?.textHaloWidth = .constant(.init(0.25))
        symbols.paint?.textHaloColor = .constant(.init(color: UIColor.black))
        return symbols
    }
    
    public func removeRoutes() {
        var sourceIdentifiers = Set<String>()
        var layerIdentifiers = Set<String>()
        routes?.enumerated().forEach {
            if $0.offset == 0, let identifier = identifier($0.element, identifierType: .source, isMainRouteCasingSource: true) {
                sourceIdentifiers.insert(identifier)
            }
            
            if let identifier = identifier($0.element, identifierType: .source) {
                sourceIdentifiers.insert(identifier)
            }
            
            if let identifier = identifier($0.element, identifierType: .route) {
                layerIdentifiers.insert(identifier)
            }
            
            if let identifier = identifier($0.element, identifierType: .routeCasing) {
                layerIdentifiers.insert(identifier)
            }
        }
        
        mapView.style.removeLayers(layerIdentifiers)
        mapView.style.removeSources(sourceIdentifiers)
        
        routes = nil
        routePoints = nil
        routeLineGranularDistances = nil
    }
    
    func identifier(_ route: Route?, identifierType: IdentifierType, isMainRouteCasingSource: Bool = false) -> String? {
        guard let route = route else { return nil }
        let identifier = Unmanaged.passUnretained(route).toOpaque()
        
        switch identifierType {
        case .source:
            if isMainRouteCasingSource {
                return "\(identifier)_casing_source"
            }
            
            return "\(identifier)_source"
            
        case .route:
            return "\(identifier)_route"
            
        case .routeCasing:
            return "\(identifier)_casing"
        }
    }
    
    public func removeWaypoints() {
        mapView.annotationManager.removeAnnotations(annotationsToRemove())
        
        let layerSet: Set = [IdentifierString.waypointCircle,
                             IdentifierString.waypointSymbol]
        mapView.style.removeLayers(layerSet)
        mapView.style.removeSources([IdentifierString.waypointSource])
    }
    
    func annotationsToRemove() -> [Annotation] {
        // TODO: Improve annotations filtering functionality.
        return mapView.annotationManager.annotations.values.filter({ $0.title == "navigation_annotation" })
    }
    
    /**
     Shows the step arrow given the current `RouteProgress`.
     */
    public func addArrow(route: Route, legIndex: Int, stepIndex: Int) {
        guard route.legs.indices.contains(legIndex),
              route.legs[legIndex].steps.indices.contains(stepIndex),
              let mainRouteLayerIdentifier = identifier(route, identifierType: .route),
              let triangleImage = Bundle.mapboxNavigation.image(named: "triangle")?.withRenderingMode(.alwaysTemplate) else { return }
        
        let _ = mapView.style.setStyleImage(image: triangleImage, with: IdentifierString.arrowImage, scale: 1.0)
        
        let minimumZoomLevel: Double = 8.0
        let step = route.legs[legIndex].steps[stepIndex]
        let maneuverCoordinate = step.maneuverLocation
        
        guard step.maneuverType != .arrive else { return }
        
        // TODO: Implement ability to change `shaftLength` depending on zoom level.
        let shaftLength = max(min(30 * mapView.metersPerPointAtLatitude(latitude: maneuverCoordinate.latitude), 30), 10)
        let shaftPolyline = route.polylineAroundManeuver(legIndex: legIndex, stepIndex: stepIndex, distance: shaftLength)
        
        if shaftPolyline.coordinates.count > 1 {
            let shaftStrokeCoordinates = shaftPolyline.coordinates
            let shaftDirection = shaftStrokeCoordinates[shaftStrokeCoordinates.count - 2].direction(to: shaftStrokeCoordinates.last!)
            
            var arrowSource = GeoJSONSource()
            arrowSource.data = .feature(Feature(shaftPolyline))
            var arrow = LineLayer(id: IdentifierString.arrow)
            if let _ = try? mapView.style.getSource(identifier: IdentifierString.arrowSource, type: GeoJSONSource.self).get() {
                let geoJSON = Feature(shaftPolyline)
                let _ = mapView.style.updateGeoJSON(for: IdentifierString.arrowSource, with: geoJSON)
            } else {
                arrow.minZoom = Double(minimumZoomLevel)
                arrow.layout?.lineCap = .constant(.butt)
                arrow.layout?.lineJoin = .constant(.round)
                arrow.paint?.lineWidth = .expression(Expression.routeLineWidthExpression(0.7))
                arrow.paint?.lineColor = .constant(.init(color: maneuverArrowColor))
                
                mapView.style.addSource(source: arrowSource, identifier: IdentifierString.arrowSource)
                arrow.source = IdentifierString.arrowSource
                mapView.style.addLayer(layer: arrow, layerPosition: LayerPosition(above: mainRouteLayerIdentifier))
            }
            
            var arrowStrokeSource = GeoJSONSource()
            arrowStrokeSource.data = .feature(Feature(shaftPolyline))
            var arrowStroke = LineLayer(id: IdentifierString.arrowStroke)
            if let _ = try? mapView.style.getSource(identifier: IdentifierString.arrowStrokeSource, type: GeoJSONSource.self).get() {
                let geoJSON = Feature(shaftPolyline)
                let _ = mapView.style.updateGeoJSON(for: IdentifierString.arrowStrokeSource, with: geoJSON)
            } else {
                arrowStroke.minZoom = arrow.minZoom
                arrowStroke.layout?.lineCap = arrow.layout?.lineCap
                arrowStroke.layout?.lineJoin = arrow.layout?.lineJoin
                arrowStroke.paint?.lineWidth = .expression(Expression.routeLineWidthExpression(0.8))
                arrowStroke.paint?.lineColor = .constant(.init(color: maneuverArrowStrokeColor))
                
                mapView.style.addSource(source: arrowStrokeSource, identifier: IdentifierString.arrowStrokeSource)
                arrowStroke.source = IdentifierString.arrowStrokeSource
                mapView.style.addLayer(layer: arrowStroke, layerPosition: LayerPosition(above: mainRouteLayerIdentifier))
            }
            
            let point = Point(shaftStrokeCoordinates.last!)
            var arrowSymbolSource = GeoJSONSource()
            arrowSymbolSource.data = .feature(Feature(point))
            if let _ = try? mapView.style.getSource(identifier: IdentifierString.arrowSymbolSource, type: GeoJSONSource.self).get() {
                let geoJSON = Feature.init(geometry: Geometry.point(point))
                let _ = mapView.style.updateGeoJSON(for: IdentifierString.arrowSymbolSource, with: geoJSON)
                let _ = try? mapView.__map.setStyleLayerPropertyForLayerId(IdentifierString.arrowSymbol, property: "icon-rotate", value: shaftDirection)
                let _ = try? mapView.__map.setStyleLayerPropertyForLayerId(IdentifierString.arrowCasingSymbol, property: "icon-rotate", value: shaftDirection)
            } else {
                var arrowSymbolLayer = SymbolLayer(id: IdentifierString.arrowSymbol)
                arrowSymbolLayer.minZoom = Double(minimumZoomLevel)
                arrowSymbolLayer.layout?.iconImage = .constant(.name(IdentifierString.arrowImage))
                arrowSymbolLayer.paint?.iconColor = .constant(.init(color: maneuverArrowColor))
                arrowSymbolLayer.layout?.iconRotationAlignment = .constant(.map)
                arrowSymbolLayer.layout?.iconRotate = .constant(.init(shaftDirection))
                arrowSymbolLayer.layout?.iconSize = .expression(Expression.routeLineWidthExpression(0.12))
                arrowSymbolLayer.layout?.iconAllowOverlap = .constant(true)
                
                var arrowSymbolLayerCasing = SymbolLayer(id: IdentifierString.arrowCasingSymbol)
                arrowSymbolLayerCasing.minZoom = arrowSymbolLayer.minZoom
                arrowSymbolLayerCasing.layout?.iconImage = arrowSymbolLayer.layout?.iconImage
                arrowSymbolLayerCasing.paint?.iconColor = .constant(.init(color: maneuverArrowStrokeColor))
                arrowSymbolLayerCasing.layout?.iconRotationAlignment = arrowSymbolLayer.layout?.iconRotationAlignment
                arrowSymbolLayerCasing.layout?.iconRotate = arrowSymbolLayer.layout?.iconRotate
                arrowSymbolLayerCasing.layout?.iconSize = .expression(Expression.routeLineWidthExpression(0.14))
                arrowSymbolLayerCasing.layout?.iconAllowOverlap = arrowSymbolLayer.layout?.iconAllowOverlap
                
                mapView.style.addSource(source: arrowSymbolSource, identifier: IdentifierString.arrowSymbolSource)
                arrowSymbolLayer.source = IdentifierString.arrowSymbolSource
                arrowSymbolLayerCasing.source = IdentifierString.arrowSymbolSource
                mapView.style.addLayer(layer: arrowSymbolLayer)
                mapView.style.addLayer(layer: arrowSymbolLayerCasing, layerPosition: LayerPosition(below: IdentifierString.arrowSymbol))
            }
        }
    }
    
    /**
     Removes the step arrow from the map.
     */
    public func removeArrow() {
        let layerSet: Set = [
            IdentifierString.arrow,
            IdentifierString.arrowStroke,
            IdentifierString.arrowSymbol,
            IdentifierString.arrowCasingSymbol
        ]
        mapView.style.removeLayers(layerSet)
        
        let sourceSet: Set = [
            IdentifierString.arrowSource,
            IdentifierString.arrowStrokeSource,
            IdentifierString.arrowSymbolSource
        ]
        mapView.style.removeSources(sourceSet)
    }
    
    public func localizeLabels() {
        // TODO: Implement ability to localize road labels.
    }
    
    public func showVoiceInstructionsOnMap(route: Route) {
        var featureCollection = FeatureCollection(features: [])
        
        for (legIndex, leg) in route.legs.enumerated() {
            for (stepIndex, step) in leg.steps.enumerated() {
                for instruction in step.instructionsSpokenAlongStep! {
                    let coordinate = LineString(route.legs[legIndex].steps[stepIndex].shape!.coordinates.reversed()).coordinateFromStart(distance: instruction.distanceAlongStep)!
                    var feature = Feature(Point(coordinate))
                    feature.properties = [
                        "instruction": instruction.text
                    ]
                    featureCollection.features.append(feature)
                }
            }
        }

        if let _ = try? mapView.style.getSource(identifier: IdentifierString.instructionSource, type: GeoJSONSource.self).get() {
            _ = mapView.style.updateGeoJSON(for: IdentifierString.instructionSource, with: featureCollection)
        } else {
            var source = GeoJSONSource()
            source.data = .featureCollection(featureCollection)
            mapView.style.addSource(source: source, identifier: IdentifierString.instructionSource)
            
            var symbolLayer = SymbolLayer(id: IdentifierString.instructionLabel)
            symbolLayer.source = IdentifierString.instructionSource
            
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
            mapView.style.addLayer(layer: symbolLayer)
            
            var circleLayer = CircleLayer(id: IdentifierString.instructionCircle)
            circleLayer.source = IdentifierString.instructionSource
            circleLayer.paint?.circleRadius = .constant(5)
            circleLayer.paint?.circleOpacity = .constant(0.75)
            circleLayer.paint?.circleColor = .constant(.init(color: .white))
            mapView.style.addLayer(layer: circleLayer)
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
        let tapCoordinate = mapView.coordinate(for: point)
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
            let coordinatePoint = mapView.point(for: $0.coordinate)
            
            return coordinatePoint.distance(to: point) < tapGestureDistanceThreshold
        })
        
        return candidates
    }
    
    private func routes(closeTo point: CGPoint) -> [Route]? {
        let tapCoordinate = mapView.coordinate(for: point)
        
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
            let closestPoint = mapView.point(for: closestCoordinate)
            
            return closestPoint.distance(to: point) < tapGestureDistanceThreshold
        }
        
        return candidates
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

    private func updateIntersectionAnnotationSet(horizon: ElectronicHorizon, roadGraph: RoadGraph) {

        guard let currentWayname = horizon.start.edgeNames(roadGraph: roadGraph).first else { return }

        // grab the MPP from the Electronic Horizon
        guard let edges = horizon.start.mpp else { return }

        var intersections = [EdgeIntersection]()

        var intersectingWaynames = [String]()

        for mppEdge in edges {
            let metadata = roadGraph.edgeMetadata(edgeIdentifier: mppEdge.identifier)
            guard metadata?.names != nil else { continue }
            // look through all the edges to filter out ones we don't want to consider
            // These are ones that lack a name, are very short, or are not on-screen
            let level1Edges = mppEdge.outletEdges.filter { outEdge -> Bool in
                // Criteria for accepting an edge as a candidate intersecting road
                //  • Is not on the MPP
                //  • Is a named road
                //  • Is not the current road being travelled
                //  • Is not a road already accepted (happens since there will be more than one outlet edge if a road continues through the current one)
                //  • Is of a large enough road class
                //  • Is of a non-trivial length in meters
                //  • Intersection point is currently visible on screen

                guard outEdge.level != 0 else { return false }
                guard let edgeMetadata = roadGraph.edgeMetadata(edgeIdentifier: outEdge.identifier), let geometry = roadGraph.edgeShape(edgeIdentifier: mppEdge.identifier) else { return false }

                let names = edgeMetadata.names.map { name -> String in
                    switch name {
                    case .name(let name):
                        return name
                    case .code(let code):
                        return "(\(code))"
                    }
                }

                guard let firstName = names.first, firstName != "" else {
                    // edge has no name
                    return false
                }
                guard firstName != currentWayname else {
                    // edge is for the currently travelled road
                    return false
                }

                guard !intersectingWaynames.contains(firstName) else {
                    // an edge for this road is already chosen
                    return false
                }

                guard ![MapboxStreetsRoadClass.service, MapboxStreetsRoadClass.ferry, MapboxStreetsRoadClass.path, MapboxStreetsRoadClass.majorRail, MapboxStreetsRoadClass.minorRail, MapboxStreetsRoadClass.serviceRail, MapboxStreetsRoadClass.aerialway, MapboxStreetsRoadClass.golf].contains(edgeMetadata.mapboxStreetsRoadClass) else {
                    // edge is of type that we choose not to label
                    return false
                }

                guard edgeMetadata.length >= 5 else {
                    // edge is at least 5 meters long
                    return false
                }

                guard let length = geometry.distance() else { return false }

                let targetDistance = min(length / 2, Double.random(in: 15...30))
                guard let annotationPoint = geometry.coordinateFromStart(distance: targetDistance) else {
                    // unable to find a coordinate to label
                    return false
                }

                let onscreenPoint = self.mapView.point(for: annotationPoint, in: nil)

                guard mapView.bounds.insetBy(dx: 20, dy: 20).contains(onscreenPoint) else {
                    // intersection coordinate is not visible on screen
                    return false
                }

                // acceptable intersection to label
                intersectingWaynames.append(firstName)
                return true
            }

            // record the edge information for use in creating the annotation Turf.Feature
            let rootMetadata: ElectronicHorizon.Edge.Metadata? = roadGraph.edgeMetadata(edgeIdentifier: mppEdge.identifier)
            let rootShape: LineString? = roadGraph.edgeShape(edgeIdentifier: mppEdge.identifier)
            for branch in level1Edges {
                let branchMetadata: ElectronicHorizon.Edge.Metadata? = roadGraph.edgeMetadata(edgeIdentifier: branch.identifier)
                let branchShape: LineString? = roadGraph.edgeShape(edgeIdentifier: branch.identifier)
                guard let rootMetadata = rootMetadata, let rootShape = rootShape, let branchInfo = branchMetadata, let branchGeometry = branchShape else { return }

                intersections.append(EdgeIntersection(root: mppEdge, branch: branch, rootMetadata: rootMetadata, rootShape: rootShape, branchMetadata: branchInfo, branchShape: branchGeometry))
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

        // form a set of the names of current intersections
        // we will use this to check if any old intersections are no longer relevant or any additional ones have been picked
        let currentNames = intersections.compactMap { return $0.intersectingWayName }
        let currentNameSet = Set(currentNames)

        // if the road name set hasn't changed then we can just short-circuit out
        guard previousNameSet != currentNameSet else { return }

        // go ahead and update our list of currently labelled intersections
        previousNameSet = currentNameSet

        // take up to 4 intersections to annotate. Limit it to prevent cluttering the map with too many annotations
        intersectionsToAnnotate = Array(intersections.prefix(4))
    }

    var previousNameSet: Set<String>?
    var intersectionsToAnnotate: [EdgeIntersection]?

    open func updateAnnotations(for routeProgress: RouteProgress) {
        var features = [Feature]()

        // add an annotation for the next step

        if let upcomingStep = routeProgress.upcomingStep {
            let maneuverLocation = upcomingStep.maneuverLocation
            var labelText = upcomingStep.names?.first ?? ""
            let currentLeg = routeProgress.currentLeg

            if upcomingStep == currentLeg.steps.last, let destination = currentLeg.destination?.name {
                labelText = destination
            }

            if labelText == "", let destinationCodes = upcomingStep.destinationCodes, destinationCodes.count > 0 {
                labelText = destinationCodes[0]

                destinationCodes.dropFirst().forEach { destination in
                    labelText += " / " + destination
                }
            }

            if labelText == "", let exitCodes = upcomingStep.exitCodes, let code = exitCodes.first {
                labelText = "Exit \(code)"
            }

            if labelText == "", let destination = upcomingStep.destinations?.first {
                labelText = destination
            }

            if labelText == "", let exitName = upcomingStep.exitNames?.first {
                labelText = exitName
            }

            if labelText != "" {
                var featurePoint: Feature
                if let cachedEntry = cachedAnnotationFeature(for: labelText) {
                    featurePoint = cachedEntry.feature
                } else {
                    featurePoint = Feature(Point(maneuverLocation))

                    let tailPosition = AnnotationTailPosition.center

                    // set the feature attributes which will be used in styling the symbol style layer
                    featurePoint.properties = ["highlighted": true, "tailPosition": tailPosition.rawValue, "text": labelText, "imageName": "AnnotationCentered-Highlighted", "sortOrder": 0]

                    annotationCache?.setValue(feature: featurePoint, coordinate: maneuverLocation, intersection: nil, for: labelText)
                }
                features.append(featurePoint)
            }
        }

        guard let intersectionsToAnnotate = intersectionsToAnnotate else { return }
        for (index, intersection) in intersectionsToAnnotate.enumerated() {
            guard let coordinate = intersection.annotationPoint else { continue }
            var featurePoint: Feature

            if let intersectingWayName = intersection.intersectingWayName, let cachedEntry = cachedAnnotationFeature(for: intersectingWayName) {
                featurePoint = cachedEntry.feature
            } else {
                featurePoint = Feature(Point(coordinate))

                let tailPosition = intersection.incidentAngle < 180 ? AnnotationTailPosition.left : AnnotationTailPosition.right

                let imageName = tailPosition == .left ? "AnnotationLeftHanded" : "AnnotationRightHanded"

                // set the feature attributes which will be used in styling the symbol style layer
                featurePoint.properties = ["highlighted": false, "tailPosition": tailPosition.rawValue, "text": intersection.intersectingWayName, "imageName": imageName, "sortOrder": -index]

                if let intersectingWayName = intersection.intersectingWayName {
                    annotationCache?.setValue(feature: featurePoint, coordinate: coordinate, intersection: nil, for: intersectingWayName)
                }
            }
            features.append(featurePoint)
        }

        updateAnnotationLayer(with: FeatureCollection(features: features))
    }

    private func addAnnotationSymbolImages() {
        guard let style = mapView.style, style.getStyleImage(with: "AnnotationLeftHanded") == nil, style.getStyleImage(with: "AnnotationRightHanded") == nil else { return }

        // Centered pin
        if let image = UIImage(named: "AnnotationCentered", in: .mapboxNavigation, compatibleWith: nil) {
            let stretchX = [ImageStretches(first: Float(20), second: Float(30)), ImageStretches(first: Float(90), second: Float(100))]
            let stretchY = [ImageStretches(first: Float(26), second: Float(32))]
            let imageContent = ImageContent(left: 20, top: 26, right: 100, bottom: 33)

            let regularAnnotationImage = image.tint(.intersectionAnnotationDefaultBackgroundColor)

            style.setStyleImage(image: regularAnnotationImage,
                                with: "AnnotationCentered",
                                stretchX: stretchX,
                                stretchY: stretchY,
                                scale: 2.0,
                                imageContent: imageContent)

            let highlightedAnnotationImage = image.tint(.intersectionAnnotationSelectedBackgroundColor)
            style.setStyleImage(image: highlightedAnnotationImage,
                                with: "AnnotationCentered-Highlighted",
                                stretchX: stretchX,
                                stretchY: stretchY,
                                scale: 2.0,
                                imageContent: imageContent)
        }

        let stretchX = [ImageStretches(first: Float(32), second: Float(42))]
        let stretchY = [ImageStretches(first: Float(26), second: Float(32))]
        let imageContent = ImageContent(left: 32, top: 26, right: 47, bottom: 33)

        // Right-hand pin
        if let image =  UIImage(named: "AnnotationRightHanded", in: .mapboxNavigation, compatibleWith: nil) {
            let regularAnnotationImage = image.tint(.intersectionAnnotationDefaultBackgroundColor)

            style.setStyleImage(image: regularAnnotationImage,
                                with: "AnnotationRightHanded",
                                stretchX: stretchX,
                                stretchY: stretchY,
                                scale: 2.0,
                                imageContent: imageContent)

            let highlightedAnnotationImage = image.tint(.intersectionAnnotationSelectedBackgroundColor)
            style.setStyleImage(image: highlightedAnnotationImage,
                                with: "AnnotationRightHanded-Highlighted",
                                stretchX: stretchX,
                                stretchY: stretchY,
                                scale: 2.0,
                                imageContent: imageContent)
        }

        // Left-hand pin
        if let image =  UIImage(named: "AnnotationLeftHanded", in: .mapboxNavigation, compatibleWith: nil) {
            let regularAnnotationImage = image.tint(.intersectionAnnotationDefaultBackgroundColor)

            style.setStyleImage(image: regularAnnotationImage,
                                with: "AnnotationLeftHanded",
                                stretchX: stretchX,
                                stretchY: stretchY,
                                scale: 2.0,
                                imageContent: imageContent)

            let highlightedAnnotationImage = image.tint(.intersectionAnnotationSelectedBackgroundColor)
            style.setStyleImage(image: highlightedAnnotationImage,
                                with: "AnnotationLeftHanded-Highlighted",
                                stretchX: stretchX,
                                stretchY: stretchY,
                                scale: 2.0,
                                imageContent: imageContent)
        }
    }

    private func removeRouteAnnotationsLayerFromStyle() {
        mapView.style.removeLayers([NavigationMapView.intersectionAnnotations])
        _ = mapView.style.removeSource(for: NavigationMapView.intersectionAnnotations)
    }

    var annotationCache: AnnotationCache?
    static let intersectionAnnotations = "intersectionAnnotations"

    private func cachedAnnotationFeature(for labelText: String) -> AnnotationCacheEntry? {
        if let existingFeature = annotationCache?.value(for: labelText) {
            // ensure the cached feature is still visible on-screen. If it is not then remove the entry and return nil
            let unprojectedCoordinate = self.mapView.point(for: existingFeature.coordinate, in: nil)
            if mapView.bounds.contains(unprojectedCoordinate) {
                return existingFeature
            } else {
                annotationCache?.remove(existingFeature)
            }
        }

        return nil
    }

    private func updateAnnotationLayer(with features: FeatureCollection) {
        guard let style = mapView.style else { return }
        let existingDataSource = try? mapView.style.getSource(identifier: NavigationMapView.intersectionAnnotations, type: GeoJSONSource.self).get()
        if existingDataSource != nil {
            _ = mapView.style.updateGeoJSON(for: NavigationMapView.intersectionAnnotations, with: features)
            return
        } else {
            var dataSource = GeoJSONSource()
            dataSource.data = .featureCollection(features)
            mapView.style.addSource(source: dataSource, identifier: NavigationMapView.intersectionAnnotations)
        }

        _ = mapView.style.removeStyleLayer(forLayerId: NavigationMapView.intersectionAnnotations)

        var shapeLayer = SymbolLayer(id: NavigationMapView.intersectionAnnotations)
        shapeLayer.source = NavigationMapView.intersectionAnnotations

        shapeLayer.layout?.textField = .expression(Exp(.get) {
            "text"
        })

        shapeLayer.layout?.iconImage = .expression(Exp(.get) {
            "imageName"
        })

        shapeLayer.paint?.textColor = .expression(Exp(.switchCase) {
            Exp(.any) {
                Exp(.get) {
                    "highlighted"
                }
            }
            self.intersectionAnnotationSelectedLabelColor
            self.intersectionAnnotationDefaultLabelColor
        })

        shapeLayer.layout?.textSize = .constant(16)
        shapeLayer.layout?.iconTextFit = .constant(.both)
        shapeLayer.layout?.iconAllowOverlap = .constant(true)
        shapeLayer.layout?.textAllowOverlap = .constant(true)
        shapeLayer.layout?.textJustify = .constant(.center)
        shapeLayer.layout?.symbolZOrder = .constant(.auto)
        shapeLayer.layout?.textFont = .constant(self.intersectionAnnotationFontNames)
        shapeLayer.layout?.iconTextFitPadding = .constant([-4, 0, -3, 0])

        style.addLayer(layer: shapeLayer, layerPosition: nil)

        let symbolSortKeyString =
        """
        ["get", "sortOrder"]
        """

        if let expressionData = symbolSortKeyString.data(using: .utf8), let expJSONObject = try? JSONSerialization.jsonObject(with: expressionData, options: []) {

            try! mapView.__map.setStyleLayerPropertyForLayerId(NavigationMapView.intersectionAnnotations,
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
          [2],
          "bottom",
          "center"
        ]
        """

        if let expressionData = expressionString.data(using: .utf8), let expJSONObject = try? JSONSerialization.jsonObject(with: expressionData, options: []) {

            try! mapView.__map.setStyleLayerPropertyForLayerId(NavigationMapView.intersectionAnnotations,
                                                          property: "icon-anchor",
                                                          value: expJSONObject)
            try! mapView.__map.setStyleLayerPropertyForLayerId(NavigationMapView.intersectionAnnotations,
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
          [1],
          ["literal", [-0.5, -1]],
          [2],
          ["literal", [0.0, -1]],
          ["literal", [0.0, 0.0]]
        ]
        """

        if let expressionData = offsetExpressionString.data(using: .utf8), let expJSONObject = try? JSONSerialization.jsonObject(with: expressionData, options: []) {

            try! mapView.__map.setStyleLayerPropertyForLayerId(NavigationMapView.intersectionAnnotations,
                                                          property: "icon-offset",
                                                          value: expJSONObject)

            try! mapView.__map.setStyleLayerPropertyForLayerId(NavigationMapView.intersectionAnnotations,
                                                          property: "text-offset",
                                                          value: expJSONObject)
        }
    }

    @objc func didUpdateElectronicHorizonPosition(_ notification: Notification) {
        guard let horizon = notification.userInfo?[ElectronicHorizon.NotificationUserInfoKey.treeKey] as? ElectronicHorizon, let roadGraph = notification.userInfo?[ElectronicHorizon.NotificationUserInfoKey.roadGraphIdentifierKey] as? RoadGraph else {
            return
        }

        DispatchQueue.main.async {
            self.updateIntersectionAnnotationSet(horizon: horizon, roadGraph: roadGraph)
        }
    }

    func edgeNames(identifier: ElectronicHorizon.Edge.Identifier, roadGraph: RoadGraph) -> [String] {
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
