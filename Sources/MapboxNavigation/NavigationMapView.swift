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
        static let defaultFramesPerSecond = PreferredFPS.maximum
        static let pluggedInFramesPerSecond = PreferredFPS.lowPower
    }
    
    /**
     The minimum preferred frames per second at which to render map animations.
     
     This property takes effect when the application has limited resources for animation, such as when the device is running on battery power. By default, this property is set to `PreferredFPS.normal`.
     */
    // TODO: Mapbox Maps should provide the ability to set custom `PreferredFPS` value.
    public var minimumFramesPerSecond = PreferredFPS.normal
    
    /**
     Returns the altitude that the map camera initally defaults to.
     */
    public var defaultAltitude: CLLocationDistance = 1000.0
    
    /**
     Returns the altitude the map conditionally zooms out to when user is on a motorway, and the maneuver length is sufficently long.
     */
    public var zoomedOutMotorwayAltitude: CLLocationDistance = 2000.0
    
    /**
     Returns the threshold for what the map considers a "long-enough" maneuver distance to trigger a zoom-out when the user enters a motorway.
     */
    public var longManeuverDistance: CLLocationDistance = 1000.0
    
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
        static let routeDurationAnnotations = "\(identifier)_routeDurationAnnotations"
    }
    
    @objc dynamic public var trafficUnknownColor: UIColor = .trafficUnknown
    @objc dynamic public var trafficLowColor: UIColor = .trafficLow
    @objc dynamic public var trafficModerateColor: UIColor = .trafficModerate
    @objc dynamic public var trafficHeavyColor: UIColor = .trafficHeavy
    @objc dynamic public var trafficSevereColor: UIColor = .trafficSevere
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
            userCourseView = reducedAccuracyActivatedMode
                ? UserHaloCourseView(frame: frame)
                : UserPuckCourseView(frame: frame)
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
     The object that acts as the course tracking delegate of the map view.
     */
    public weak var courseTrackingDelegate: NavigationMapViewCourseTrackingDelegate?
    

    @objc dynamic public var routeDurationAnnotationSelectedColor: UIColor = .selectedRouteDurationAnnotationColor
    @objc dynamic public var routeDurationAnnotationColor: UIColor = .routeDurationAnnotationColor
    @objc dynamic public var routeDurationAnnotationSelectedTextColor: UIColor = .selectedRouteDurationAnnotationTextColor
    @objc dynamic public var routeDurationAnnotationTextColor: UIColor = .routeDurationAnnotationTextColor
    @objc dynamic public var routeDurationAnnotationFontName: String = "DIN Pro Medium"
    var userLocationForCourseTracking: CLLocation?
    var altitude: CLLocationDistance
    var routes: [Route]?
    var isAnimatingToOverheadMode = false
    var routePoints: RoutePoints?
    var routeLineGranularDistances: RouteLineGranularDistances?
    var routeRemainingDistancesIndex: Int?
    var routeLineTracksTraversal: Bool = false
    var fractionTraveled: Double = 0.0
    var preFractionTraveled: Double = 0.0
    var vanishingRouteLineUpdateTimer: Timer? = nil
    
    var shouldPositionCourseViewFrameByFrame = false {
        didSet {
            if shouldPositionCourseViewFrameByFrame {
                mapView.preferredFPS = .maximum
            }
        }
    }
    
    var showsRoute: Bool {
        get {
            guard let mainRouteLayerIdentifier = identifier(routes?.first, identifierType: .route),
                  let mainRouteCasingLayerIdentifier = identifier(routes?.first, identifierType: .routeCasing) else { return false }
            
            guard let _ = try? mapView.style.getLayer(with: mainRouteLayerIdentifier, type: LineLayer.self).get(),
                  let _ = try? mapView.style.getLayer(with: mainRouteCasingLayerIdentifier, type: LineLayer.self).get() else { return false }

            return true
        }
    }
    
    // TODO: When using previous version of Maps SDK `showsUserLocation` was overridden property of `MGLMapView`. Clarify whether it needs to be exposed.
    open var showsUserLocation: Bool {
        get {
            if tracksUserCourse || userLocationForCourseTracking != nil {
                return !userCourseView.isHidden
            }
            
            return mapView.locationManager.showUserLocation
        }
        set {
            if tracksUserCourse || userLocationForCourseTracking != nil {
                mapView.update {
                    $0.location.showUserLocation = false
                }
                
                userCourseView.isHidden = !newValue
            } else {
                userCourseView.isHidden = true

                mapView.update {
                    $0.location.showUserLocation = newValue
                }
            }
        }
    }
    
    /**
     The minimum default insets from the content frame to the edges of the user course view.
     */
    static let courseViewMinimumInsets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
    
    /**
     Center point of the user course view in screen coordinates relative to the map view.
     - seealso: NavigationMapViewDelegate.navigationMapViewUserAnchorPoint(_:)
     */
    var userAnchorPoint: CGPoint {
        if let anchorPoint = delegate?.navigationMapViewUserAnchorPoint(self), anchorPoint != .zero {
            return anchorPoint
        }
        // TODO: Verify whether content insets verification is required.
        let contentFrame = bounds
        return CGPoint(x: contentFrame.midX, y: contentFrame.midY)
    }
    
    /**
     Determines whether the map should follow the user location and rotate when the course changes.
     - seealso: NavigationMapViewCourseTrackingDelegate
     */
    open var tracksUserCourse: Bool = false {
        didSet {
            if tracksUserCourse {
                enableFrameByFrameCourseViewTracking(for: 3)
                altitude = defaultAltitude
                showsUserLocation = true
                courseTrackingDelegate?.navigationMapViewDidStartTrackingCourse(self)
            } else {
                courseTrackingDelegate?.navigationMapViewDidStopTrackingCourse(self)
            }
            if let location = userLocationForCourseTracking {
                updateCourseTracking(location: location, animated: true)
            }
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
    
    public override init(frame: CGRect) {
        altitude = defaultAltitude
        super.init(frame: frame)
        
        setupMapView(frame)
        commonInit()
    }
    
    public required init?(coder: NSCoder) {
        altitude = defaultAltitude
        super.init(coder: coder)
        
        setupMapView(self.bounds)
        commonInit()
    }
    
    fileprivate func commonInit() {
        makeGestureRecognizersRespectCourseTracking()
        makeGestureRecognizersUpdateCourseView()
        setupGestureRecognizers()
        installUserCourseView()
        showsUserLocation = false
    }
    
    func setupMapView(_ frame: CGRect) {
        guard let accessToken = AccountManager.shared.accessToken else {
            fatalError("Access token was not set.")
        }
        
        let options = ResourceOptions(accessToken: accessToken,
                                      tileStorePath: Bundle.mapboxNavigation.suggestedTileURL?.path)
        
        mapView = MapView(with: frame, resourceOptions: options)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.update {
            $0.ornaments.showsScale = false
        }
        
        mapView.on(.renderFrameFinished) { [weak self] _ in
            guard let self = self,
                  self.shouldPositionCourseViewFrameByFrame,
                  let location = self.userLocationForCourseTracking else { return }
            
            self.userCourseView.center = self.mapView.screenCoordinate(for: location.coordinate).point
        }
        
        addSubview(mapView)
        
        mapView.pinTo(parentView: self)
    }
    
    func setupGestureRecognizers() {
        let gestures = gestureRecognizers ?? []
        let mapTapGesture = UITapGestureRecognizer(target: self, action: #selector(didRecieveTap(sender:)))
        mapTapGesture.requireFailure(of: gestures)
        mapView.addGestureRecognizer(mapTapGesture)
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
    
    open override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        enableFrameByFrameCourseViewTracking(for: 3)
    }
    
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
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        // If the map is in tracking mode, make sure we update the camera and anchor after the layout pass.
        if tracksUserCourse {
            updateCourseTracking(location: userLocationForCourseTracking, camera:mapView.cameraView.camera, animated: false)
            
            // TODO: Find appropriate place where anchor can be updated.
            mapView.cameraView.anchor = userAnchorPoint
        }
    }
    
    /**
     Updates the map view’s preferred frames per second to the appropriate value for the current route progress.
     
     This method accounts for the proximity to a maneuver and the current power source. It has no effect if `tracksUserCourse` is set to `true`.
     */
    open func updatePreferredFrameRate(for routeProgress: RouteProgress) {
        guard tracksUserCourse else { return }
        
        let stepProgress = routeProgress.currentLegProgress.currentStepProgress
        let expectedTravelTime = stepProgress.step.expectedTravelTime
        let durationUntilNextManeuver = stepProgress.durationRemaining
        let durationSincePreviousManeuver = expectedTravelTime - durationUntilNextManeuver
        let conservativeFramesPerSecond = UIDevice.current.isPluggedIn ? FrameIntervalOptions.pluggedInFramesPerSecond : minimumFramesPerSecond
        
        if let upcomingStep = routeProgress.currentLegProgress.upcomingStep,
           upcomingStep.maneuverDirection == .straightAhead || upcomingStep.maneuverDirection == .slightLeft || upcomingStep.maneuverDirection == .slightRight {
            mapView.preferredFPS = shouldPositionCourseViewFrameByFrame ? FrameIntervalOptions.defaultFramesPerSecond : conservativeFramesPerSecond
        } else if durationUntilNextManeuver > FrameIntervalOptions.durationUntilNextManeuver &&
                    durationSincePreviousManeuver > FrameIntervalOptions.durationSincePreviousManeuver {
            mapView.preferredFPS = shouldPositionCourseViewFrameByFrame ? FrameIntervalOptions.defaultFramesPerSecond : conservativeFramesPerSecond
        } else {
            mapView.preferredFPS = FrameIntervalOptions.pluggedInFramesPerSecond
        }
    }
    
    /**
     Track position on a frame by frame basis. Used for first location update and when resuming tracking mode
     */
    public func enableFrameByFrameCourseViewTracking(for duration: TimeInterval) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(disableFrameByFramePositioning), object: nil)
        perform(#selector(disableFrameByFramePositioning), with: nil, afterDelay: duration)
        shouldPositionCourseViewFrameByFrame = true
    }
    
    @objc fileprivate func disableFrameByFramePositioning() {
        shouldPositionCourseViewFrameByFrame = false
    }
    
    // MARK: - User tracking methods
    
    func installUserCourseView() {
        if let location = userLocationForCourseTracking {
            updateCourseTracking(location: location)
        }
        mapView.addSubview(userCourseView)
    }
    
    @objc private func disableUserCourseTracking() {
        guard tracksUserCourse else { return }
        tracksUserCourse = false
    }
    
    public func updateCourseTracking(location: CLLocation?, camera: CameraOptions? = nil, animated: Bool = false) {
        // While animating to overhead mode, don't animate the puck.
        let duration: TimeInterval = animated && !isAnimatingToOverheadMode ? 1 : 0
        userLocationForCourseTracking = location
        guard let location = location, CLLocationCoordinate2DIsValid(location.coordinate) else {
            return
        }
        
        let centerUserCourseView = { [weak self] in
            guard let point = self?.mapView.screenCoordinate(for: location.coordinate).point else { return }
            
            self?.userCourseView.center = point
        }
        
        if tracksUserCourse {
            centerUserCourseView()
            
            let zoomLevel = CGFloat(ZoomLevelForAltitude(altitude,
                                                         self.mapView.pitch,
                                                         location.coordinate.latitude,
                                                         self.mapView.bounds.size))
            
            let camera = camera ?? CameraOptions(center: location.coordinate,
                                                 zoom: zoomLevel,
                                                 bearing: location.course,
                                                 pitch: 45)
            mapView.cameraManager.setCamera(to: camera, animated: animated, duration: duration, completion: nil)
        } else {
            // Animate course view updates in overview mode
            UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear], animations: centerUserCourseView)
        }
        
        userCourseView.update(location: location,
                              pitch: mapView.cameraView.pitch,
                              direction: mapView.bearing,
                              animated: animated,
                              tracksUserCourse: tracksUserCourse)
    }
    
    // MARK: Feature Addition/removal properties and methods
    
    /**
     Showcases route array. Adds routes and waypoints to map, and sets camera to point encompassing the route.
     */
    public static let defaultPadding: UIEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    
    public func showcase(_ routes: [Route], animated: Bool = false) {
        guard let activeRoute = routes.first,
              let coordinates = activeRoute.shape?.coordinates,
              !coordinates.isEmpty else { return }
        
        removeArrow()
        removeRoutes()
        removeWaypoints()
        
        show(routes)
        showWaypoints(on: activeRoute)
        
        fit(to: activeRoute, facing: 0, animated: animated)
    }
    
    func fit(to route: Route, facing direction: CLLocationDirection = 0, animated: Bool = false) {
        guard let shape = route.shape, !shape.coordinates.isEmpty else { return }
        
        let newCamera = mapView.cameraManager.camera(fitting: .lineString(shape),
                                                     edgePadding: safeArea + NavigationMapView.defaultPadding,
                                                     bearing: CGFloat(direction),
                                                     pitch: 0)
        
        mapView.cameraManager.setCamera(to: newCamera, animated: animated, completion: nil)
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
        lineLayer.layout?.lineJoin = .round
        lineLayer.layout?.lineCap = .round
        
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
                IdentifierString.waypointCircle
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
        lineLayer.layout?.lineJoin = .round
        lineLayer.layout?.lineCap = .round
        
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
        lineLayer.layout?.lineJoin = .round
        lineLayer.layout?.lineCap = .round

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
        lineLayer.layout?.lineJoin = .round
        lineLayer.layout?.lineCap = .round
        
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

                if let arrows = try? mapView.style.getLayer(with: IdentifierString.arrowCasingSymbol, type: LineLayer.self).get() {
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
        symbols.layout?.textField = .expression(Exp(.toString){
                                                    Exp(.get){
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
                let geoJSON = Feature.init(geometry: Geometry.lineString(shaftPolyline))
                let _ = mapView.style.updateGeoJSON(for: IdentifierString.arrowSource, with: geoJSON)
            } else {
                arrow.minZoom = Double(minimumZoomLevel)
                arrow.layout?.lineCap = .butt
                arrow.layout?.lineJoin = .round
                arrow.paint?.lineWidth = .expression(Expression.routeLineWidthExpression(0.7))
                arrow.paint?.lineColor = .constant(.init(color: maneuverArrowColor))
                
                mapView.style.addSource(source: arrowSource, identifier: IdentifierString.arrowSource)
                arrow.source = IdentifierString.arrowSource
                if let _ = try? mapView.style.getLayer(with: IdentifierString.waypointCircle, type: LineLayer.self).get() {
                    mapView.style.addLayer(layer: arrow, layerPosition: LayerPosition(above: mainRouteLayerIdentifier, below: IdentifierString.waypointCircle))
                } else {
                    mapView.style.addLayer(layer: arrow, layerPosition: LayerPosition(above: mainRouteLayerIdentifier))
                }
            }
            
            var arrowStrokeSource = GeoJSONSource()
            arrowStrokeSource.data = .feature(Feature(shaftPolyline))
            var arrowStroke = LineLayer(id: IdentifierString.arrowStroke)
            if let _ = try? mapView.style.getSource(identifier: IdentifierString.arrowStrokeSource, type: GeoJSONSource.self).get() {
                let geoJSON = Feature.init(geometry: Geometry.lineString(shaftPolyline))
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
                arrowSymbolLayer.layout?.iconRotationAlignment = .map
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

    /**
     Shows a callout containing the duration of each route.
     Useful as a way to give the user more information when picking between multiple route alternatives.
     If the route contains any tolled segments then the callout will specify that as well.
     */
    public func showRouteDurations(along routes: [Route]?) {
        guard let visibleRoutes = self.routes, visibleRoutes.count > 0 else { return }
        updateAnnotationSymbolImages()
        updateRouteDurations(along: visibleRoutes)
    }

    /**
     Updates the image assets in the map style for the route duration annotations. Useful when the desired callout colors change, such as when transitioning between light and dark mode on iOS 13 and later.
     */
    private func updateAnnotationSymbolImages() {
        guard let style = mapView.style, style.getStyleImage(with: "RouteInfoAnnotationLeftHanded") == nil, style.getStyleImage(with: "RouteInfoAnnotationRightHanded") == nil else { return }

        //        let leftStretchX = ImageStretches(first: Float(35), second: Float(50))
        let leftStretchX = ImageStretches(first: Float(25), second: Float(55))
        let rightStretchX = ImageStretches(first: Float(85), second: Float(115))
        let stretchX = [leftStretchX, rightStretchX]
        let stretchY = [ImageStretches(first: Float(25), second: Float(100))]
        let imageContent = ImageContent(left: 25, top: 20, right: 115, bottom: 105)
        if let image =  Bundle.mapboxNavigation.image(named: "Rectangle") {
            let regularRouteImage = image.tint(routeDurationAnnotationColor)

            //            style.setStyleImage(image: regularRouteImage, with: "RouteInfoAnnotationLeftHanded", scale: scale)
            style.setStyleImage(image: regularRouteImage,
                                with: "RouteInfoAnnotationLeftHanded",
                                sdf: false,
                                stretchX: stretchX,
                                stretchY: stretchY,
                                scale: 2.0,
                                imageContent: imageContent)

            let selectedRouteImage = image.tint(routeDurationAnnotationSelectedColor)
            //            style.setStyleImage(image: selectedRouteImage, with: "RouteInfoAnnotationLeftHanded-Selected", scale: scale)
            style.setStyleImage(image: selectedRouteImage,
                                with: "RouteInfoAnnotationLeftHanded-Selected",
                                sdf: false,
                                stretchX: stretchX,
                                stretchY: stretchY,
                                scale: 2.0,
                                imageContent: imageContent)
        }

        if let image =  Bundle.mapboxNavigation.image(named: "Rectangle2") {
            let regularRouteImage = image.tint(routeDurationAnnotationColor)

            let lStretchX = ImageStretches(first: Float(25), second: Float(55))
            let stretchX = [lStretchX]
            let stretchY = [ImageStretches(first: Float(25), second: Float(100))]
            let imageContent = ImageContent(left: 25, top: 25, right: 90, bottom: 100)

            //            style.setStyleImage(image: regularRouteImage, with: "RouteInfoAnnotationRightHanded", scale: scale)
            style.setStyleImage(image: regularRouteImage,
                                with: "RouteInfoAnnotationRightHanded",
                                sdf: false,
                                stretchX: stretchX,
                                stretchY: stretchY,
                                scale: 2.0,
                                imageContent: imageContent)

            let selectedRouteImage = image.tint(routeDurationAnnotationSelectedColor)
            //            style.setStyleImage(image: selectedRouteImage, with: "RouteInfoAnnotationRightHanded-Selected", scale: scale)
            style.setStyleImage(image: selectedRouteImage,
                                with: "RouteInfoAnnotationRightHanded-Selected",
                                sdf: false,
                                stretchX: stretchX,
                                stretchY: stretchY,
                                scale: 2.0,
                                imageContent: imageContent)
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

        let visibleBoundingBox = BoundingBox(coordinateBounds: mapView.coordinateBounds(for: mapView))// coordinateBounds(for view: UIView) -> CoordinateBounds
//        let visibleBoundingBox = BoundingBox(coordinateBounds: mapView.visibleCoordinateBounds)

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
            let labelText = self.annotationLabelForRoute(route, tolls: routesContainTolls)// + " Extra Long Super Long"

            // Create the feature for this route annotation. Set the styling attributes that will be used to render the annotation in the style layer.
            var feature = Feature(Point(annotationCoordinate))

            var tailPosition = randomTailPosition

            // convert our coordinate to screen space so we can make a choice on which side of the coordinate the label ends up on
            let unprojectedCoordinate = mapView.point(for: annotationCoordinate, in: nil)

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
//            point.attributes = ["selected": index == 0, "tailPosition": tailPosition.rawValue, "text": labelText, "imageName": imageName, "sortOrder": -index]
            feature.properties = ["selected": index == 0, "tailPosition": tailPosition.rawValue, "text": labelText, "imageName": imageName, "sortOrder": -index]

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
        if let _ = try? mapView.style.getSource(identifier: IdentifierString.routeDurationAnnotations, type: GeoJSONSource.self).get() {
            let _ = mapView.style.updateGeoJSON(for: IdentifierString.arrowStrokeSource, with: features)
        } else {

            var dataSource = GeoJSONSource()
            dataSource.data = .featureCollection(features)
            mapView.style.addSource(source: dataSource, identifier: IdentifierString.routeDurationAnnotations)
        }

        var shapeLayer: SymbolLayer

        if let layer = try? mapView.style.getLayer(with: IdentifierString.routeDurationAnnotations, type: SymbolLayer.self).get() {
            shapeLayer = layer
        } else {
            shapeLayer = SymbolLayer(id: IdentifierString.routeDurationAnnotations)
        }

        shapeLayer.source = IdentifierString.routeDurationAnnotations

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
            UIColor.white
            UIColor.black
        })

        shapeLayer.layout?.textSize = .expression(
            Exp(.interpolate) {
                Exp(.linear)
                Exp(.zoom)
                13
                16
                15.5
                20
            }
        )

        shapeLayer.layout?.iconTextFit = .both
        shapeLayer.layout?.iconAllowOverlap = .constant(true)
        shapeLayer.layout?.textAllowOverlap = .constant(true)
        shapeLayer.layout?.textJustify = .left
        shapeLayer.layout?.symbolZOrder = .auto
        shapeLayer.layout?.textFont = .constant([self.routeDurationAnnotationFontName])

        style.addLayer(layer: shapeLayer, layerPosition: nil)

        #if false

        shapeLayer.textColor = NSExpression(forConditional: NSPredicate(format: "selected == true"),
                                            trueExpression: NSExpression(forConstantValue: routeDurationAnnotationSelectedTextColor),
                     falseExpression: NSExpression(forConstantValue: routeDurationAnnotationTextColor))

        shapeLayer.symbolSortKey = NSExpression(forConditional: NSPredicate(format: "selected == true"),
                                                trueExpression: NSExpression(forConstantValue: 1),
                                                   falseExpression: NSExpression(format: "sortOrder"))
        shapeLayer.iconOffset = NSExpression(forConditional: NSPredicate(format: "tailPosition == 0"),
                                             trueExpression: NSExpression(forConstantValue: CGVector(dx: 0.5, dy: -1.0)),
                      falseExpression: NSExpression(forConstantValue: CGVector(dx: -0.5, dy: -1.0)))
        shapeLayer.textOffset = shapeLayer.iconOffset

        #endif
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
        style.removeLayers([IdentifierString.routeDurationAnnotations])
        style.removeSources([IdentifierString.routeDurationAnnotations])
    }

    // This function generates the text for the label to be shown on screen. It will include estimated duration and info on Tolls, if applicable
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
            symbolLayer.layout?.textAnchor = .bottom
            symbolLayer.layout?.textJustify = .left
            mapView.style.addLayer(layer: symbolLayer)
            
            var circleLayer = CircleLayer(id: IdentifierString.instructionCircle)
            circleLayer.source = IdentifierString.instructionSource
            circleLayer.paint?.circleRadius = .constant(5)
            circleLayer.paint?.circleOpacity = .constant(0.75)
            circleLayer.paint?.circleColor = .constant(.init(color: .white))
            mapView.style.addLayer(layer: circleLayer)
        }
    }
    
    /**
     Sets the camera directly over a series of coordinates.
     */
    public func setOverheadCameraView(from userLocation: CLLocation, along lineString: LineString, for padding: UIEdgeInsets) {
        isAnimatingToOverheadMode = true
        tracksUserCourse = false
    
        // TODO: Implement functionality which allows to change camera options based on traversed distance.
        
        let newCamera = mapView.cameraManager.camera(fitting: .lineString(lineString),
                                                     edgePadding: padding,
                                                     bearing: 0,
                                                     pitch: 0)
        
        mapView.cameraManager.setCamera(to: newCamera, animated: true, duration: 1) { [weak self] _ in
            self?.isAnimatingToOverheadMode = false
        }

        updateCourseView(to: userLocation, pitch: newCamera.pitch, direction: newCamera.bearing, animated: true)
    }
    
    /**
     Recenters the camera and begins tracking the user's location.
     */
    public func recenterMap() {
        tracksUserCourse = true
        enableFrameByFrameCourseViewTracking(for: 3)
    }
    
    // MARK: - Gesture recognizers methods
    
    /**
     Fired when NavigationMapView detects a tap not handled elsewhere by other gesture recognizers.
     */
    @objc func didRecieveTap(sender: UITapGestureRecognizer) {
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
    
    @objc func updateCourseView(_ sender: UIGestureRecognizer) {
        if sender.state == .ended, let validAltitude = mapView.altitude {
            altitude = validAltitude
            enableFrameByFrameCourseViewTracking(for: 2)
        }
        
        // Capture altitude for double tap and two finger tap after animation finishes
        if sender is UITapGestureRecognizer, sender.state == .ended {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                if let altitude = self.mapView.altitude {
                    self.altitude = altitude
                }
            })
        }
        
        if let panGesture = sender as? UIPanGestureRecognizer,
           sender.state == .ended || sender.state == .cancelled {
            let velocity = panGesture.velocity(in: self)
            let didFling = sqrt(velocity.x * velocity.x + velocity.y * velocity.y) > 100
            if didFling {
                enableFrameByFrameCourseViewTracking(for: 1)
            }
        }
        
        if sender.state == .changed {
            guard let location = userLocationForCourseTracking else { return }
            updateCourseView(to: location)
        }
    }
    
    // MARK: - Utility methods
    
    /**
     Modifies the gesture recognizers to also disable course tracking.
     */
    func makeGestureRecognizersRespectCourseTracking() {
        for gestureRecognizer in mapView.gestureRecognizers ?? []
        where gestureRecognizer is UIPanGestureRecognizer || gestureRecognizer is UIRotationGestureRecognizer {
            gestureRecognizer.addTarget(self, action: #selector(disableUserCourseTracking))
        }
    }
    
    func makeGestureRecognizersUpdateCourseView() {
        for gestureRecognizer in mapView.gestureRecognizers ?? [] {
            gestureRecognizer.addTarget(self, action: #selector(updateCourseView(_:)))
        }
    }
    
    private func updateCourseView(to location: CLLocation, pitch: CGFloat? = nil, direction: CLLocationDirection? = nil, animated: Bool = false) {
        userCourseView.update(location: location,
                              pitch: pitch ?? mapView.cameraView.pitch,
                              direction: direction ?? mapView.bearing,
                              animated: animated,
                              tracksUserCourse: tracksUserCourse)
        
        userCourseView.center = mapView.screenCoordinate(for: location.coordinate).point
    }
}

extension UIColor {
    func toHex(alpha: Bool = false) -> String {
        guard let components = cgColor.components, components.count >= 3 else {
            return "#000000"
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if alpha {
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
