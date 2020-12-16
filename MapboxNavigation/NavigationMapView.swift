import Foundation
import Mapbox
import MapboxDirections
import MapboxCoreNavigation
import Turf

let identifierNamespace = Bundle.mapboxNavigation.bundleIdentifier ?? ""

/**
 `NavigationMapView` is a subclass of `MGLMapView` with convenience functions for adding `Route` lines to a map.
 */
open class NavigationMapView: MGLMapView, UIGestureRecognizerDelegate {
    // MARK: Class Constants
    
    struct FrameIntervalOptions {
        static let durationUntilNextManeuver: TimeInterval = 7
        static let durationSincePreviousManeuver: TimeInterval = 3
        static let defaultFramesPerSecond = MGLMapViewPreferredFramesPerSecond.maximum
        static let pluggedInFramesPerSecond = MGLMapViewPreferredFramesPerSecond.lowPower
    }
    
    /**
     The minimum preferred frames per second at which to render map animations.
     
     This property takes effect when the application has limited resources for animation, such as when the device is running on battery power. By default, this property is set to `MGLMapViewPreferredFramesPerSecond.lowPower`.
     */
    public var minimumFramesPerSecond = MGLMapViewPreferredFramesPerSecond(20)
    
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
    
    /**
     The object that acts as the navigation delegate of the map view.
     */
    public weak var navigationMapViewDelegate: NavigationMapViewDelegate?
    @available(swift, obsoleted: 0.1, renamed: "navigationMapViewDelegate")
    public weak var navigationMapDelegate: NavigationMapViewDelegate? {
        fatalError()
    }
    
    /**
     The object that acts as the course tracking delegate of the map view.
     */
    public weak var courseTrackingDelegate: NavigationMapViewCourseTrackingDelegate?
    
    let sourceOptions: [MGLShapeSourceOption: Any] = [.maximumZoomLevel: 16]

    struct SourceIdentifier {
        static let waypoint = "\(identifierNamespace).waypoints"
        static let waypointCircle = "\(identifierNamespace).waypointsCircle"
        static let waypointSymbol = "\(identifierNamespace).waypointsSymbol"

        static let arrow = "\(identifierNamespace).arrow"
        static let arrowSymbol = "\(identifierNamespace).arrowSymbol"
        static let arrowStroke = "\(identifierNamespace).arrowStroke"
        
        static let instruction = "\(identifierNamespace).instruction"
        
        static let buildingExtrusion = "\(identifierNamespace).buildingExtrusion"
    }
    
    struct StyleLayerIdentifier {
        static let namespace = Bundle.mapboxNavigation.bundleIdentifier ?? ""

        static let waypointCircle = "\(identifierNamespace).waypointsCircle"
        static let waypointSymbol = "\(identifierNamespace).waypointsSymbol"

        static let arrow = "\(identifierNamespace).arrow"
        static let arrowSymbol = "\(identifierNamespace).arrowSymbol"
        static let arrowStroke = "\(identifierNamespace).arrowStroke"
        static let arrowCasingSymbol = "\(identifierNamespace).arrowCasingSymbol"

        static let instructionLabel = "\(identifierNamespace).instructionLabel"
        static let instructionCircle = "\(identifierNamespace).instructionCircle"
        
        static let buildingExtrusion = "\(identifierNamespace).buildingExtrusion"
    }
    
    enum IdentifierType: Int {
        case source
        
        case route
        
        case routeCasing
    }

    // MARK: - Instance Properties
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
            userCourseView = reducedAccuracyActivatedMode ? UserHaloCourseView(frame: CGRect(origin: .zero, size: 75.0)) : UserPuckCourseView(frame: CGRect(origin: .zero, size: 75.0))
        }
    }
    
    var userLocationForCourseTracking: CLLocation?
    var animatesUserLocation: Bool = false
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
                preferredFramesPerSecond = .maximum
            }
        }
    }
    
    var showsRoute: Bool {
        get {
            guard let mainRouteLayerIdentifier = identifier(routes?.first, identifierType: .route),
                  let mainRouteCasingLayerIdentifier = identifier(routes?.first, identifierType: .routeCasing) else { return false }
            
            return style?.layer(withIdentifier: mainRouteLayerIdentifier) != nil &&
                style?.layer(withIdentifier: mainRouteCasingLayerIdentifier) != nil
        }
    }
    
    open override var showsUserLocation: Bool {
        get {
            if tracksUserCourse || userLocationForCourseTracking != nil {
                return !(userCourseView.isHidden)
            }
            return super.showsUserLocation
        }
        set {
            if tracksUserCourse || userLocationForCourseTracking != nil {
                super.showsUserLocation = false
                
                userCourseView.isHidden = !newValue
            } else {
                userCourseView.isHidden = true
                super.showsUserLocation = newValue
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
        if let anchorPoint = navigationMapViewDelegate?.navigationMapViewUserAnchorPoint(self), anchorPoint != .zero {
            return anchorPoint
        }
        let contentFrame = bounds.inset(by: contentInset)
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
    
    private lazy var mapTapGesture = UITapGestureRecognizer(target: self, action: #selector(didRecieveTap(sender:)))
    
    //MARK: - Initalizers
    
    public override init(frame: CGRect) {
        altitude = defaultAltitude
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder decoder: NSCoder) {
        altitude = defaultAltitude
        super.init(coder: decoder)
        commonInit()
    }
    
    public override init(frame: CGRect, styleURL: URL?) {
        altitude = defaultAltitude
        super.init(frame: frame, styleURL: styleURL)
        commonInit()
    }
    
    fileprivate func commonInit() {
        makeGestureRecognizersRespectCourseTracking()
        makeGestureRecognizersUpdateCourseView()
        
        let gestures = gestureRecognizers ?? []
        let mapTapGesture = self.mapTapGesture
        mapTapGesture.requireFailure(of: gestures)
        addGestureRecognizer(mapTapGesture)
        
        installUserCourseView()
        showsUserLocation = false
        
    }
    
    open override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        enableFrameByFrameCourseViewTracking(for: 3)
    }
    
    //MARK: - Overrides
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        let image = UIImage(named: "feedback-map-error", in: .mapboxNavigation, compatibleWith: nil)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .center
        imageView.backgroundColor = .gray
        imageView.frame = bounds
        addSubview(imageView)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        //If the map is in tracking mode, make sure we update the camera after the layout pass.
        if (tracksUserCourse) {
            updateCourseTracking(location: userLocationForCourseTracking, camera:self.camera, animated: false)
        }
    }
    
    open override func anchorPoint(forGesture gesture: UIGestureRecognizer) -> CGPoint {
        if tracksUserCourse {
            return userAnchorPoint
        } else {
            return super.anchorPoint(forGesture: gesture)
        }
    }
    
    open override func mapViewDidFinishRenderingFrameFullyRendered(_ fullyRendered: Bool) {
        super.mapViewDidFinishRenderingFrameFullyRendered(fullyRendered)
        
        guard shouldPositionCourseViewFrameByFrame else { return }
        guard let location = userLocationForCourseTracking else { return }
        
        userCourseView.center = convert(location.coordinate, toPointTo: self)
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
            preferredFramesPerSecond = shouldPositionCourseViewFrameByFrame ? FrameIntervalOptions.defaultFramesPerSecond : conservativeFramesPerSecond
        } else if durationUntilNextManeuver > FrameIntervalOptions.durationUntilNextManeuver &&
            durationSincePreviousManeuver > FrameIntervalOptions.durationSincePreviousManeuver {
            preferredFramesPerSecond = shouldPositionCourseViewFrameByFrame ? FrameIntervalOptions.defaultFramesPerSecond : conservativeFramesPerSecond
        } else {
            preferredFramesPerSecond = FrameIntervalOptions.pluggedInFramesPerSecond
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
    
    //MARK: - User Tracking
    
    func installUserCourseView() {
        if let location = userLocationForCourseTracking {
            updateCourseTracking(location: location, animated: false)
        }
        addSubview(userCourseView)
    }
    
    @objc private func disableUserCourseTracking() {
        guard tracksUserCourse else { return }
        tracksUserCourse = false
    }
    
    public func updateCourseTracking(location: CLLocation?, camera: MGLMapCamera? = nil, animated: Bool = false) {
        // While animating to overhead mode, don't animate the puck.
        let duration: TimeInterval = animated && !isAnimatingToOverheadMode ? 1 : 0
        animatesUserLocation = animated
        userLocationForCourseTracking = location
        guard let location = location, CLLocationCoordinate2DIsValid(location.coordinate) else {
            return
        }
        
        let centerUserCourseView = { [weak self] in
            guard let point = self?.convert(location.coordinate, toPointTo: self) else { return }
            self?.userCourseView.center = point
        }
        
        if tracksUserCourse {
            centerUserCourseView()
            
            let newCamera = camera ?? MGLMapCamera(lookingAtCenter: location.coordinate, altitude: altitude, pitch: 45, heading: location.course)
            let function: CAMediaTimingFunction? = animated ? CAMediaTimingFunction(name: .linear) : nil
            setCamera(newCamera, withDuration: duration, animationTimingFunction: function, completionHandler: nil)
        } else {
            // Animate course view updates in overview mode
            UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear], animations: centerUserCourseView)
        }
        
        userCourseView.update(location: location, pitch: self.camera.pitch, direction: direction, animated: animated, tracksUserCourse: tracksUserCourse)
    }
    
    //MARK: - Gesture Recognizers
    
    /**
     Fired when NavigationMapView detects a tap not handled elsewhere by other gesture recognizers.
     */
    @objc func didRecieveTap(sender: UITapGestureRecognizer) {
        guard let routes = routes, let tapPoint = sender.point else { return }
        
        let waypointTest = waypoints(on: routes, closeTo: tapPoint) //are there waypoints near the tapped location?
        if let selected = waypointTest?.first { //test passes
            navigationMapViewDelegate?.navigationMapView(self, didSelect: selected)
            return
        } else if let routes = self.routes(closeTo: tapPoint) {
            guard let selectedRoute = routes.first else { return }
            navigationMapViewDelegate?.navigationMapView(self, didSelect: selectedRoute)
        }
    }
    
    @objc func updateCourseView(_ sender: UIGestureRecognizer) {
        if sender.state == .ended {
            altitude = self.camera.altitude
            enableFrameByFrameCourseViewTracking(for: 2)
        }
        
        // Capture altitude for double tap and two finger tap after animation finishes
        if sender is UITapGestureRecognizer, sender.state == .ended {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                self.altitude = self.camera.altitude
            })
        }
        
        if let pan = sender as? UIPanGestureRecognizer {
            if sender.state == .ended || sender.state == .cancelled {
                let velocity = pan.velocity(in: self)
                let didFling = sqrt(velocity.x * velocity.x + velocity.y * velocity.y) > 100
                if didFling {
                    enableFrameByFrameCourseViewTracking(for: 1)
                }
            }
        }
        
        if sender.state == .changed {
            guard let location = userLocationForCourseTracking else { return }
            
            updateCourseView(to: location)
        }
    }
    
    // MARK: Feature Addition/Removal
    /**
     Showcases route array. Adds routes and waypoints to map, and sets camera to point encompassing the route.
     */
    public static let defaultPadding: UIEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    
    public func showcase(_ routes: [Route], animated: Bool = false) {
        guard let active = routes.first,
            let coords = active.shape?.coordinates,
            !coords.isEmpty else { return } //empty array
        
        removeArrow()
        removeRoutes()
        removeWaypoints()
        
        show(routes)
        showWaypoints(on: active)
        
        fit(to: active, facing: 0, animated: animated)
    }
    
    func fit(to route: Route, facing direction:CLLocationDirection = 0, animated: Bool = false) {
        guard let shape = route.shape, !shape.coordinates.isEmpty else { return }
      
        setUserTrackingMode(.none, animated: false, completionHandler: nil)
        let line = MGLPolyline(shape)
        
        // Current contentInset gets incorporated to cameraThatFitsShape.
        // edgePadding is set to .zero as there's no need for additional padding.
        contentInset = safeArea + NavigationMapView.defaultPadding
        let camera = cameraThatFitsShape(line, direction: direction, edgePadding: .zero)
        setCamera(camera, animated: animated)
    }
    
    /**
     Adds or updates both the route line and the route line casing.

     This method will be called multiple times:
     • When the route preview map is shown, rendering alternative routes if necessary.
     • When the navigation session starts, rendering only the single route line.
     */
    public func show(_ routes: [Route], legIndex: Int = 0) {
        guard let style = style else { return }
        
        removeRoutes()
        
        self.routes = routes
        
        var parentLayer: MGLStyleLayer? = nil
        for (index, route) in routes.enumerated() {
            guard let routeSourceIdentifier = identifier(route, identifierType: .source),
                  let routeCasingSourceIdentifier = identifier(route, identifierType: .source, isMainRouteCasingSource: true),
                  let routeIdentifier = identifier(route, identifierType: .route),
                  let routeCasingIdentifier = identifier(route, identifierType: .routeCasing) else { continue }
            
            // In case of main route there is the ability to provide custom `MGLShape` for either route or route casing by implemeting
            // `NavigationMapViewDelegate.navigationMapView(_:shapeFor:)` or `NavigationMapViewDelegate.navigationMapView(_:simplifiedShapeFor:)`.
            if index == 0 {
                
                let routeShape = navigationMapViewDelegate?.navigationMapView(self, shapeFor: [route]) ??
                    shape(for: route, legIndex: legIndex, isAlternateRoute: false)
                
                let routeSource = addRouteSource(style, identifier: routeSourceIdentifier, shape: routeShape)
                
                let fractionTraveledForGradient = routeLineTracksTraversal ? fractionTraveled : 0.0
                
                let mainRouteLayer = addMainRouteLayer(style,
                                                       source: routeSource,
                                                       identifier: routeIdentifier,
                                                       lineGradient: routeLineGradient(route, fractionTraveled: fractionTraveledForGradient))
                
                let mainRouteCasingShape = navigationMapViewDelegate?.navigationMapView(self, simplifiedShapeFor: route) ??
                    shape(forCasingOf: route, legIndex: legIndex)
                
                let routeCasingSource = addRouteSource(style, identifier: routeCasingSourceIdentifier, shape: mainRouteCasingShape)
                
                parentLayer = addMainRouteCasingLayer(style,
                                                      source: routeCasingSource,
                                                      identifier: routeCasingIdentifier,
                                                      lineGradient: routeCasingGradient(fractionTraveledForGradient),
                                                      below: mainRouteLayer)
                
                if routeLineTracksTraversal {
                    initPrimaryRoutePoints(route: route)
                }
                
                continue
            }
            
            let routeShape = shape(for: route, legIndex: legIndex, isAlternateRoute: true)
            let routeSource = addRouteSource(style, identifier: routeSourceIdentifier, shape: routeShape)
            
            if let tempLayer = parentLayer {
                let alternativeRouteLayer = addAlternativeRoutesLayer(style,
                                                                      source: routeSource,
                                                                      identifier: routeIdentifier,
                                                                      below: tempLayer)
                
                parentLayer = addAlternativeRoutesCasingLayer(style,
                                                              source: routeSource,
                                                              identifier: routeCasingIdentifier,
                                                              below: alternativeRouteLayer)
            }
        }
    }
    
    // MARK: - Route line insertion methods
    
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
    
    func addRouteSource(_ style: MGLStyle, identifier: String, shape: MGLShape?) -> MGLSource {
        if let routeSource = style.source(withIdentifier: identifier) as? MGLShapeSource {
            routeSource.shape = shape
            return routeSource
        }
        
        let routeSource = MGLShapeSource(identifier: identifier, shape: shape, options: [.lineDistanceMetrics: true])
        style.addSource(routeSource)
        
        return routeSource
    }

    @discardableResult func addMainRouteLayer(_ style: MGLStyle, source: MGLSource, identifier: String, lineGradient: NSExpression?) -> MGLStyleLayer {
        let customMainRouteLayer = navigationMapViewDelegate?.navigationMapView(self,
                                                                                mainRouteStyleLayerWithIdentifier: identifier,
                                                                                source: source)
        let currentMainRouteLayer = style.layer(withIdentifier: identifier)
        
        var parentLayer: MGLStyleLayer? {
            let identifiers = [
                StyleLayerIdentifier.arrow,
                StyleLayerIdentifier.arrowSymbol,
                StyleLayerIdentifier.arrowCasingSymbol,
                StyleLayerIdentifier.arrowStroke,
                StyleLayerIdentifier.waypointCircle
            ]
            
            var parentLayer: MGLStyleLayer? = nil
            for layer in style.layers.reversed() {
                if !(layer is MGLSymbolStyleLayer) && !identifiers.contains(layer.identifier) {
                    // MGLMapView automatically adds an MGLLineStyleLayer or MGLFillStyleLayer to the top of the layer stack when adding a polyline or polygon annotation, respectively. There’s no way to insert them lower in the layer stack, so they aren’t good indicators of where to insert the route line.
                    // Detect and skip such a layer by checking if its source lacks a dedicated MGLSource subclass.
                    if let vectorLayer = layer as? MGLVectorStyleLayer,
                       let sourceIdentifier = vectorLayer.sourceIdentifier,
                       let source = style.source(withIdentifier: sourceIdentifier), type(of: source) == MGLSource.self {
                        continue
                    }
                    
                    parentLayer = layer
                    break
                }
            }
            
            return parentLayer
        }
        
        if let mainRouteLayer = customMainRouteLayer, currentMainRouteLayer == nil, let parentLayer = parentLayer {
            style.insertLayer(mainRouteLayer, above: parentLayer)
            return mainRouteLayer
        }
        
        if let mainRouteLayer = currentMainRouteLayer as? MGLLineStyleLayer {
            return mainRouteLayer
        }
        
        let mainRouteLayer = MGLLineStyleLayer(identifier: identifier, source: source)
        mainRouteLayer.predicate = NSPredicate(format: "isAlternateRoute == false")
        mainRouteLayer.lineColor = NSExpression(forConstantValue: trafficUnknownColor)
        mainRouteLayer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel)
        mainRouteLayer.lineJoin = NSExpression(forConstantValue: "round")
        mainRouteLayer.lineCap = NSExpression(forConstantValue: "round")
        mainRouteLayer.lineGradient = lineGradient
        
        if let parentLayer = parentLayer {
            style.insertLayer(mainRouteLayer, above: parentLayer)
        }
        
        return mainRouteLayer
    }

    @discardableResult func addMainRouteCasingLayer(_ style: MGLStyle, source: MGLSource, identifier: String, lineGradient: NSExpression, below layer: MGLStyleLayer) -> MGLStyleLayer {
        let customMainRouteCasingLayer = navigationMapViewDelegate?.navigationMapView(self,
                                                                                      mainRouteCasingStyleLayerWithIdentifier: identifier,
                                                                                      source: source)
        let currentMainRouteCasingLayer = style.layer(withIdentifier: identifier)
        
        if let mainRouteCasingLayer = customMainRouteCasingLayer, let _ = currentMainRouteCasingLayer {
            return mainRouteCasingLayer
        }
        
        if let mainRouteCasingLayer = customMainRouteCasingLayer, currentMainRouteCasingLayer == nil {
            style.insertLayer(mainRouteCasingLayer, below: layer)
            return mainRouteCasingLayer
        }
        
        if let mainRouteCasingLayer = currentMainRouteCasingLayer as? MGLLineStyleLayer {
            return mainRouteCasingLayer
        }
        
        let mainRouteCasingLayer = MGLLineStyleLayer(identifier: identifier, source: source)
        mainRouteCasingLayer.predicate = NSPredicate(format: "isAlternateRoute == false")
        mainRouteCasingLayer.lineColor = NSExpression(forConstantValue: routeCasingColor)
        mainRouteCasingLayer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 1.5))
        mainRouteCasingLayer.lineJoin = NSExpression(forConstantValue: "round")
        mainRouteCasingLayer.lineCap = NSExpression(forConstantValue: "round")
        mainRouteCasingLayer.lineGradient = lineGradient
        
        style.insertLayer(mainRouteCasingLayer, below: layer)
        
        return mainRouteCasingLayer
    }
    
    @discardableResult func addAlternativeRoutesLayer(_ style: MGLStyle, source: MGLSource, identifier: String, below layer: MGLStyleLayer) -> MGLStyleLayer {
        let customAlternativeRoutesLayer = navigationMapViewDelegate?.navigationMapView(self,
                                                                                        alternativeRouteStyleLayerWithIdentifier: identifier,
                                                                                        source: source)
        let currentAlternativeRoutesLayer = style.layer(withIdentifier: identifier)
        
        if let alternativeRoutesLayer = customAlternativeRoutesLayer, let _ = currentAlternativeRoutesLayer {
            return alternativeRoutesLayer
        }
        
        if let alternativeRoutesLayer = customAlternativeRoutesLayer, currentAlternativeRoutesLayer == nil {
            style.insertLayer(alternativeRoutesLayer, below: layer)
            return alternativeRoutesLayer
        }
        
        if let alternativeRoutesLayer = currentAlternativeRoutesLayer {
            return alternativeRoutesLayer
        }
        
        let alternativeRoutesLayer = MGLLineStyleLayer(identifier: identifier, source: source)
        alternativeRoutesLayer.predicate = NSPredicate(format: "isAlternateRoute == true")
        alternativeRoutesLayer.lineColor = NSExpression(forConstantValue: routeAlternateColor)
        alternativeRoutesLayer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel)
        alternativeRoutesLayer.lineJoin = NSExpression(forConstantValue: "round")
        alternativeRoutesLayer.lineCap = NSExpression(forConstantValue: "round")
        style.insertLayer(alternativeRoutesLayer, below: layer)
        
        return alternativeRoutesLayer
    }
    
    @discardableResult func addAlternativeRoutesCasingLayer(_ style: MGLStyle, source: MGLSource, identifier: String, below layer: MGLStyleLayer) -> MGLStyleLayer {
        let customAlternativeRoutesCasingLayer = navigationMapViewDelegate?.navigationMapView(self,
                                                                                              alternativeRouteCasingStyleLayerWithIdentifier: identifier,
                                                                                              source: source)
        let currentAlternativeRoutesCasingLayer = style.layer(withIdentifier: identifier)
        
        if let alternativeRoutesCasingLayer = customAlternativeRoutesCasingLayer, let _ = currentAlternativeRoutesCasingLayer {
            return alternativeRoutesCasingLayer
        }
        
        if let alternativeRoutesCasingLayer = customAlternativeRoutesCasingLayer, currentAlternativeRoutesCasingLayer == nil {
            style.insertLayer(alternativeRoutesCasingLayer, below: layer)
            return alternativeRoutesCasingLayer
        }
        
        if let alternativeRoutesCasingLayer = currentAlternativeRoutesCasingLayer {
            return alternativeRoutesCasingLayer
        }
        
        let alternativeRoutesCasingLayer = MGLLineStyleLayer(identifier: identifier, source: source)
        alternativeRoutesCasingLayer.predicate = NSPredicate(format: "isAlternateRoute == true")
        alternativeRoutesCasingLayer.lineColor = NSExpression(forConstantValue: routeAlternateCasingColor)
        alternativeRoutesCasingLayer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 1.5))
        alternativeRoutesCasingLayer.lineJoin = NSExpression(forConstantValue: "round")
        alternativeRoutesCasingLayer.lineCap = NSExpression(forConstantValue: "round")
        style.insertLayer(alternativeRoutesCasingLayer, below: layer)
        
        return alternativeRoutesCasingLayer
    }
    
    /**
     Removes route line and route line casing from map
     */
    public func removeRoutes() {
        guard let style = style else { return }
        
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
        
        style.remove(layerIdentifiers.compactMap({ style.layer(withIdentifier: $0) }))
        style.remove(Set(sourceIdentifiers.compactMap({ style.source(withIdentifier: $0) })))
        
        routes = nil
        routePoints = nil
        routeLineGranularDistances = nil
    }
    
    /**
     Adds the route waypoints to the map given the current leg index. Previous waypoints for completed legs will be omitted.
     */
    public func showWaypoints(on route: Route, legIndex: Int = 0) {
        guard let style = style else {
            return
        }

        let waypoints: [Waypoint] = Array(route.legs.dropLast().compactMap { $0.destination })
        
        let source = navigationMapViewDelegate?.navigationMapView(self, shapeFor: waypoints, legIndex: legIndex) ?? shape(for: waypoints, legIndex: legIndex)
        if route.legs.count > 1 { //are we on a multipoint route?
            
            routes = [route] //update the model
            if let waypointSource = style.source(withIdentifier: SourceIdentifier.waypoint) as? MGLShapeSource {
                waypointSource.shape = source
            } else {
                let sourceShape = MGLShapeSource(identifier: SourceIdentifier.waypoint, shape: source, options: sourceOptions)
                style.addSource(sourceShape)
                
                let circles = navigationMapViewDelegate?.navigationMapView(self, waypointStyleLayerWithIdentifier: StyleLayerIdentifier.waypointCircle, source: sourceShape) ?? routeWaypointCircleStyleLayer(identifier: StyleLayerIdentifier.waypointCircle, source: sourceShape)
                let symbols = navigationMapViewDelegate?.navigationMapView(self, waypointSymbolStyleLayerWithIdentifier: StyleLayerIdentifier.waypointSymbol, source: sourceShape) ?? routeWaypointSymbolStyleLayer(identifier: StyleLayerIdentifier.waypointSymbol, source: sourceShape)
                
                if let arrowLayer = style.layer(withIdentifier: StyleLayerIdentifier.arrowCasingSymbol) {
                    style.insertLayer(circles, above: arrowLayer)
                } else {
                    style.addLayer(circles)
                }
                
                style.insertLayer(symbols, above: circles)
            }
        }
        
        if let lastLeg =  route.legs.last, let destinationCoordinate = lastLeg.destination?.coordinate {
            removeAnnotations(annotationsToRemove() ?? [])
            let destination = NavigationAnnotation()
            destination.coordinate = destinationCoordinate
            addAnnotation(destination)
        }
    }
    
    func annotationsToRemove() -> [MGLAnnotation]? {
        return annotations?.filter { $0 is NavigationAnnotation }
    }
    
    /**
     Removes all waypoints from the map.
     */
    public func removeWaypoints() {
        guard let style = style else { return }
        
        removeAnnotations(annotationsToRemove() ?? [])
        
        style.remove([
            StyleLayerIdentifier.waypointCircle,
            StyleLayerIdentifier.waypointSymbol,
        ].compactMap { style.layer(withIdentifier: $0) })
        style.remove(Set([
            SourceIdentifier.waypoint,
            SourceIdentifier.waypointCircle,
            SourceIdentifier.waypointSymbol,
        ].compactMap { style.source(withIdentifier: $0) }))
    }
    
    /**
     Shows the step arrow given the current `RouteProgress`.
     */
    public func addArrow(route: Route, legIndex: Int, stepIndex: Int) {
        guard route.legs.indices.contains(legIndex),
            route.legs[legIndex].steps.indices.contains(stepIndex) else { return }
        
        let step = route.legs[legIndex].steps[stepIndex]
        let maneuverCoordinate = step.maneuverLocation
        
        guard let style = style else {
            return
        }

        guard let triangleImage = Bundle.mapboxNavigation.image(named: "triangle")?.withRenderingMode(.alwaysTemplate) else { return }
        
        style.setImage(triangleImage, forName: "triangle-tip-navigation")
        
        guard step.maneuverType != .arrive else { return }
        
        let minimumZoomLevel: Float = 14.5
        
        let shaftLength = max(min(30 * metersPerPoint(atLatitude: maneuverCoordinate.latitude), 30), 10)
        let shaftPolyline = route.polylineAroundManeuver(legIndex: legIndex, stepIndex: stepIndex, distance: shaftLength)
        
        if shaftPolyline.coordinates.count > 1 {
            var shaftStrokeCoordinates = shaftPolyline.coordinates
            let shaftStrokePolyline = ArrowStrokePolyline(coordinates: &shaftStrokeCoordinates, count: UInt(shaftStrokeCoordinates.count))
            let shaftDirection = shaftStrokeCoordinates[shaftStrokeCoordinates.count - 2].direction(to: shaftStrokeCoordinates.last!)
            let maneuverArrowStrokePolylines = [shaftStrokePolyline]
            let shaftPolyline = ArrowFillPolyline(coordinates: shaftPolyline.coordinates, count: UInt(shaftPolyline.coordinates.count))
            
            let arrowShape = MGLShapeCollection(shapes: [shaftPolyline])
            let arrowStrokeShape = MGLShapeCollection(shapes: maneuverArrowStrokePolylines)
            
            let arrowSourceStroke = MGLShapeSource(identifier: SourceIdentifier.arrowStroke, shape: arrowStrokeShape, options: sourceOptions)
            let arrowStroke = MGLLineStyleLayer(identifier: StyleLayerIdentifier.arrowStroke, source: arrowSourceStroke)
            let arrowSource = MGLShapeSource(identifier: SourceIdentifier.arrow, shape: arrowShape, options: sourceOptions)
            let arrow = MGLLineStyleLayer(identifier: StyleLayerIdentifier.arrow, source: arrowSource)
            
            if let source = style.source(withIdentifier: SourceIdentifier.arrow) as? MGLShapeSource {
                source.shape = arrowShape
            } else {
                arrow.minimumZoomLevel = minimumZoomLevel
                arrow.lineCap = NSExpression(forConstantValue: "butt")
                arrow.lineJoin = NSExpression(forConstantValue: "round")
                arrow.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 0.70))
                arrow.lineColor = NSExpression(forConstantValue: maneuverArrowColor)
                
                style.addSource(arrowSource)
                if let waypoints = style.layer(withIdentifier: StyleLayerIdentifier.waypointCircle) {
                    style.insertLayer(arrow, below: waypoints)
                } else {
                    style.addLayer(arrow)
                }
            }
            
            if let source = style.source(withIdentifier: SourceIdentifier.arrowStroke) as? MGLShapeSource {
                source.shape = arrowStrokeShape
            } else {
                arrowStroke.minimumZoomLevel = arrow.minimumZoomLevel
                arrowStroke.lineCap = arrow.lineCap
                arrowStroke.lineJoin = arrow.lineJoin
                arrowStroke.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 0.80))
                arrowStroke.lineColor = NSExpression(forConstantValue: maneuverArrowStrokeColor)
                
                style.addSource(arrowSourceStroke)
                style.insertLayer(arrowStroke, below: arrow)
            }
            
            // Arrow symbol
            let point = MGLPointFeature()
            point.coordinate = shaftStrokeCoordinates.last!
            let arrowSymbolSource = MGLShapeSource(identifier: SourceIdentifier.arrowSymbol, features: [point], options: sourceOptions)
            
            if let source = style.source(withIdentifier: SourceIdentifier.arrowSymbol) as? MGLShapeSource {
                source.shape = arrowSymbolSource.shape
                if let arrowSymbolLayer = style.layer(withIdentifier: StyleLayerIdentifier.arrowSymbol) as? MGLSymbolStyleLayer {
                    arrowSymbolLayer.iconRotation = NSExpression(forConstantValue: shaftDirection as NSNumber)
                }
                if let arrowSymbolLayerCasing = style.layer(withIdentifier: StyleLayerIdentifier.arrowCasingSymbol) as? MGLSymbolStyleLayer {
                    arrowSymbolLayerCasing.iconRotation = NSExpression(forConstantValue: shaftDirection as NSNumber)
                }
            } else {
                let arrowSymbolLayer = MGLSymbolStyleLayer(identifier: StyleLayerIdentifier.arrowSymbol, source: arrowSymbolSource)
                arrowSymbolLayer.minimumZoomLevel = minimumZoomLevel
                arrowSymbolLayer.iconImageName = NSExpression(forConstantValue: "triangle-tip-navigation")
                arrowSymbolLayer.iconColor = NSExpression(forConstantValue: maneuverArrowColor)
                arrowSymbolLayer.iconRotationAlignment = NSExpression(forConstantValue: "map")
                arrowSymbolLayer.iconRotation = NSExpression(forConstantValue: shaftDirection as NSNumber)
                arrowSymbolLayer.iconScale = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 0.12))
                arrowSymbolLayer.iconAllowsOverlap = NSExpression(forConstantValue: true)
                
                let arrowSymbolLayerCasing = MGLSymbolStyleLayer(identifier: StyleLayerIdentifier.arrowCasingSymbol, source: arrowSymbolSource)
                arrowSymbolLayerCasing.minimumZoomLevel = arrowSymbolLayer.minimumZoomLevel
                arrowSymbolLayerCasing.iconImageName = arrowSymbolLayer.iconImageName
                arrowSymbolLayerCasing.iconColor = NSExpression(forConstantValue: maneuverArrowStrokeColor)
                arrowSymbolLayerCasing.iconRotationAlignment = arrowSymbolLayer.iconRotationAlignment
                arrowSymbolLayerCasing.iconRotation = arrowSymbolLayer.iconRotation
                arrowSymbolLayerCasing.iconScale = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 0.14))
                arrowSymbolLayerCasing.iconAllowsOverlap = arrowSymbolLayer.iconAllowsOverlap
                
                style.addSource(arrowSymbolSource)
                style.insertLayer(arrowSymbolLayer, above: arrow)
                style.insertLayer(arrowSymbolLayerCasing, below: arrow)
            }
        }
    }
    
    /**
     Removes the step arrow from the map.
     */
    public func removeArrow() {
        guard let style = style else {
            return
        }
        
        style.remove([
            StyleLayerIdentifier.arrow,
            StyleLayerIdentifier.arrowStroke,
            StyleLayerIdentifier.arrowSymbol,
            StyleLayerIdentifier.arrowCasingSymbol,
        ].compactMap { style.layer(withIdentifier: $0) })
        style.remove(Set([
            SourceIdentifier.arrow,
            SourceIdentifier.arrowStroke,
            SourceIdentifier.arrowSymbol,
        ].compactMap { style.source(withIdentifier: $0) }))
    }
    
    // MARK: Utility Methods
    
    /** Modifies the gesture recognizers to also disable course tracking. */
    func makeGestureRecognizersRespectCourseTracking() {
        for gestureRecognizer in gestureRecognizers ?? []
            where gestureRecognizer is UIPanGestureRecognizer || gestureRecognizer is UIRotationGestureRecognizer {
                gestureRecognizer.addTarget(self, action: #selector(disableUserCourseTracking))
        }
    }
    
    func makeGestureRecognizersUpdateCourseView() {
        for gestureRecognizer in gestureRecognizers ?? [] {
            gestureRecognizer.addTarget(self, action: #selector(updateCourseView(_:)))
        }
    }
    
    private func updateCourseView(to location: CLLocation, pitch: CGFloat? = nil, direction: CLLocationDirection? = nil, animated: Bool = false) {
        userCourseView.update(location: location,
                              pitch: pitch ?? camera.pitch,
                              direction: direction ?? self.direction,
                              animated: animated,
                              tracksUserCourse: tracksUserCourse)
        
        userCourseView.center = convert(location.coordinate, toPointTo: self)
    }
    
    private func waypoints(on routes: [Route], closeTo point: CGPoint) -> [Waypoint]? {
        let tapCoordinate = convert(point, toCoordinateFrom: self)
        let multipointRoutes = routes.filter { $0.legs.count > 1}
        guard multipointRoutes.count > 0 else { return nil }
        let waypoints = multipointRoutes.compactMap { route in
            route.legs.dropLast().compactMap { $0.destination }
        }.flatMap {$0}
        
        //lets sort the array in order of closest to tap
        let closest = waypoints.sorted { (left, right) -> Bool in
            let leftDistance = calculateDistance(coordinate1: left.coordinate, coordinate2: tapCoordinate)
            let rightDistance = calculateDistance(coordinate1: right.coordinate, coordinate2: tapCoordinate)
            return leftDistance < rightDistance
        }
        
        //lets filter to see which ones are under threshold
        let candidates = closest.filter({
            let coordinatePoint = self.convert($0.coordinate, toPointTo: self)
            return coordinatePoint.distance(to: point) < tapGestureDistanceThreshold
        })
        
        return candidates
    }
    
    private func routes(closeTo point: CGPoint) -> [Route]? {
        let tapCoordinate = convert(point, toCoordinateFrom: self)
        
        //do we have routes? If so, filter routes with at least 2 coordinates.
        guard let routes = routes?.filter({ $0.shape?.coordinates.count ?? 0 > 1 }) else { return nil }
        
        //Sort routes by closest distance to tap gesture.
        let closest = routes.sorted { (left, right) -> Bool in
            //existance has been assured through use of filter.
            let leftLine = left.shape!
            let rightLine = right.shape!
            let leftDistance = leftLine.closestCoordinate(to: tapCoordinate)!.coordinate.distance(to: tapCoordinate)
            let rightDistance = rightLine.closestCoordinate(to: tapCoordinate)!.coordinate.distance(to: tapCoordinate)
            
            return leftDistance < rightDistance
        }
        
        //filter closest coordinates by which ones are under threshold.
        let candidates = closest.filter {
            let closestCoordinate = $0.shape!.closestCoordinate(to: tapCoordinate)!.coordinate
            let closestPoint = self.convert(closestCoordinate, toPointTo: self)
            
            return closestPoint.distance(to: point) < tapGestureDistanceThreshold
        }
        return candidates
    }

    func shape(for route: Route, legIndex: Int?, isAlternateRoute: Bool) -> MGLShape? {
        let mainRoute = MGLPolylineFeature(route.shape!)
        mainRoute.attributes["isAlternateRoute"] = isAlternateRoute

        return MGLShapeCollectionFeature(shapes: [mainRoute])
    }
    
    func addCongestion(to route: Route, legIndex: Int?) -> [MGLPolylineFeature]? {
        guard let coordinates = route.shape?.coordinates else { return nil }

        var linesPerLeg: [MGLPolylineFeature] = []

        for (index, leg) in route.legs.enumerated() {
            let lines: [MGLPolylineFeature]
            if let legCongestion = leg.segmentCongestionLevels, legCongestion.count < coordinates.count {
                // The last coord of the preceding step, is shared with the first coord of the next step, we don't need both.
                let legCoordinates: [CLLocationCoordinate2D] = leg.steps.enumerated().reduce([]) { allCoordinates, current in
                    let index = current.offset
                    let step = current.element
                    let stepCoordinates = step.shape!.coordinates

                    return index == 0 ? stepCoordinates : allCoordinates + stepCoordinates.suffix(from: 1)
                }
                
                let mergedCongestionSegments = combine(legCoordinates,
                                                       with: legCongestion,
                                                       streetsRoadClasses: leg.streetsRoadClasses,
                                                       roadClassesWithOverriddenCongestionLevels: roadClassesWithOverriddenCongestionLevels)

                lines = mergedCongestionSegments.map { (congestionSegment: CongestionSegment) -> MGLPolylineFeature in
                    let polyline = MGLPolylineFeature(coordinates: congestionSegment.0, count: UInt(congestionSegment.0.count))
                    polyline.attributes[MBCongestionAttribute] = String(describing: congestionSegment.1)
                    return polyline
                }
            } else {
                // If there is no congestion, don't try and add it
                lines = [MGLPolylineFeature(route.shape!)]
            }

            for line in lines {
                line.attributes["isAlternateRoute"] = false
                if let legIndex = legIndex {
                    line.attributes[MBCurrentLegAttribute] = index == legIndex
                } else {
                    line.attributes[MBCurrentLegAttribute] = index == 0
                }
            }

            linesPerLeg.append(contentsOf: lines)
        }

        return linesPerLeg
    }
    
    /**
     Returns an array of congestion segments by associating the given congestion levels with the coordinates of the respective line segments that they apply to.
     
     This method coalesces consecutive line segments that have the same congestion level.
     
     For each item in the`CongestionSegment` collection a `CongestionLevel` substitution will take place that has a streets road class contained in the `roadClassesWithOverriddenCongestionLevels` collection.
     For each of these items the `CongestionLevel` for `.unknown` traffic congestion will be replaced with the `.low` traffic congestion.
     
     - parameter coordinates: The coordinates of a leg.
     - parameter congestions: The congestion levels along a leg. There should be one fewer congestion levels than coordinates.
     - parameter streetsRoadClasses: A collection of streets road classes for each geometry index in `Intersection`. There should be the same amount of `streetsRoadClasses` and `congestions`.
     - parameter roadClassesWithOverriddenCongestionLevels: Streets road classes for which a `CongestionLevel` substitution should occur.
     - returns: A list of `CongestionSegment` tuples with coordinate and congestion level.
     */
    func combine(_ coordinates: [CLLocationCoordinate2D],
                 with congestions: [CongestionLevel],
                 streetsRoadClasses: [MapboxStreetsRoadClass?]? = nil,
                 roadClassesWithOverriddenCongestionLevels: Set<MapboxStreetsRoadClass>? = nil) -> [CongestionSegment] {
        var segments: [CongestionSegment] = []
        segments.reserveCapacity(congestions.count)
        
        var index = 0
        for (firstSegment, congestionLevel) in zip(zip(coordinates, coordinates.suffix(from: 1)), congestions) {
            let coordinates = [firstSegment.0, firstSegment.1]
            
            var overriddenCongestionLevel = congestionLevel
            if let streetsRoadClasses = streetsRoadClasses,
               let roadClassesWithOverriddenCongestionLevels = roadClassesWithOverriddenCongestionLevels,
               streetsRoadClasses.indices.contains(index),
               let streetsRoadClass = streetsRoadClasses[index],
               congestionLevel == .unknown,
               roadClassesWithOverriddenCongestionLevels.contains(streetsRoadClass) {
                overriddenCongestionLevel = .low
            }
            
            if segments.last?.1 == overriddenCongestionLevel {
                segments[segments.count - 1].0 += coordinates
            } else {
                segments.append((coordinates, overriddenCongestionLevel))
            }
            
            index += 1
        }
        
        return segments
    }

    /**
     Creates a single route line for each route leg.

     A route with multiple legs (caused by adding more than one waypoint),
     will cause linesPerLeg.count > 1.
     */
    func shape(forCasingOf route: Route, legIndex: Int?) -> MGLShape? {
        var linesPerLeg: [MGLPolylineFeature] = []
        
        for (index, leg) in route.legs.enumerated() {
            let polyline = MGLPolylineFeature(leg.shape)
            if let legIndex = legIndex {
                polyline.attributes[MBCurrentLegAttribute] = index == legIndex
            } else {
                polyline.attributes[MBCurrentLegAttribute] = index == 0
            }
            polyline.attributes["isAlternateRoute"] = false
            linesPerLeg.append(polyline)
        }
        
        return MGLShapeCollectionFeature(shapes: linesPerLeg)
    }
    
    func shape(for waypoints: [Waypoint], legIndex: Int) -> MGLShape? {
        var features = [MGLPointFeature]()
        
        for (waypointIndex, waypoint) in waypoints.enumerated() {
            let feature = MGLPointFeature()
            feature.coordinate = waypoint.coordinate
            feature.attributes = [
                "waypointCompleted": waypointIndex < legIndex,
                "name": waypointIndex + 1
            ]
            features.append(feature)
        }
        
        return MGLShapeCollectionFeature(shapes: features)
    }
    
    func routeWaypointCircleStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
        let circles = MGLCircleStyleLayer(identifier: identifier, source: source)
        let opacity = NSExpression(forConditional: NSPredicate(format: "waypointCompleted == true"), trueExpression: NSExpression(forConstantValue: 0.5), falseExpression: NSExpression(forConstantValue: 1))
        
        circles.circleColor = NSExpression(forConstantValue: UIColor(red:0.9, green:0.9, blue:0.9, alpha:1.0))
        circles.circleOpacity = opacity
        circles.circleRadius = NSExpression(forConstantValue: 10)
        circles.circleStrokeColor = NSExpression(forConstantValue: UIColor.black)
        circles.circleStrokeWidth = NSExpression(forConstantValue: 1)
        circles.circleStrokeOpacity = opacity
        
        return circles
    }
    
    func routeWaypointSymbolStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
        let symbol = MGLSymbolStyleLayer(identifier: identifier, source: source)
        
        symbol.text = NSExpression(format: "CAST(name, 'NSString')")
        symbol.textOpacity = NSExpression(forConditional: NSPredicate(format: "waypointCompleted == true"), trueExpression: NSExpression(forConstantValue: 0.5), falseExpression: NSExpression(forConstantValue: 1))
        symbol.textFontSize = NSExpression(forConstantValue: 10)
        symbol.textHaloWidth = NSExpression(forConstantValue: 0.25)
        symbol.textHaloColor = NSExpression(forConstantValue: UIColor.black)
        
        return symbol
    }

    
    /**
     Attempts to localize road labels into the local language and other labels
     into the system’s preferred language.
     
     When this property is enabled, the style automatically modifies the `text`
     property of any symbol style layer whose source is the
     <a href="https://docs.mapbox.com/vector-tiles/mapbox-streets-v7/#overview">Mapbox
     Streets source</a>. On iOS, the user can set the system’s preferred
     language in Settings, General Settings, Language & Region.
     
     Unlike the `MGLStyle.localizeLabels(into:)` method, this method localizes
     road labels into the local language, regardless of the system’s preferred
     language, in an effort to match road signage. The turn banner always
     displays road names and exit destinations in the local language, so you
     should call this method in the
     `MGLMapViewDelegate.mapView(_:didFinishLoading:)` method of any delegate of
     a standalone `NavigationMapView`. The map view embedded in
     `NavigationViewController` is localized automatically, so you do not need
     to call this method on the value of `NavigationViewController.mapView`.
     */
    public func localizeLabels() {
        guard MGLAccountManager.hasChinaBaseURL == false else{
            return
        }
        
        guard let style = style else {
            return
        }
        
        let streetsSourceIdentifiers: [String] = style.sources.compactMap {
            $0 as? MGLVectorTileSource
        }.filter {
            $0.isMapboxStreets
        }.map {
            $0.identifier
        }
        
        for layer in style.layers where layer is MGLSymbolStyleLayer {
            let layer = layer as! MGLSymbolStyleLayer
            guard let sourceIdentifier = layer.sourceIdentifier,
                streetsSourceIdentifiers.contains(sourceIdentifier) else {
                continue
            }
            guard let text = layer.text else {
                continue
            }
            
            // Road labels should match road signage.
            let isLabelLayer = MGLVectorTileSource.roadLabelLayerIdentifiersByTileSetIdentifier.values.contains(layer.sourceLayerIdentifier ?? "")
            let locale = isLabelLayer ? Locale(identifier: "mul") : nil
            
            let localizedText = text.mgl_expressionLocalized(into: locale)
            if localizedText != text {
                layer.text = localizedText
            }
        }
    }
    
    public func showVoiceInstructionsOnMap(route: Route) {
        guard let style = style else {
            return
        }
        
        var features = [MGLPointFeature]()
        for (legIndex, leg) in route.legs.enumerated() {
            for (stepIndex, step) in leg.steps.enumerated() {
                for instruction in step.instructionsSpokenAlongStep! {
                    let feature = MGLPointFeature()
                    feature.coordinate = LineString(route.legs[legIndex].steps[stepIndex].shape!.coordinates.reversed()).coordinateFromStart(distance: instruction.distanceAlongStep)!
                    feature.attributes = [ "instruction": instruction.text ]
                    features.append(feature)
                }
            }
        }
        
        let instructionPoints = MGLShapeCollectionFeature(shapes: features)
        
        if let instructionSource = style.source(withIdentifier: SourceIdentifier.instruction) as? MGLShapeSource {
            instructionSource.shape = instructionPoints
        } else {
            let sourceShape = MGLShapeSource(identifier: SourceIdentifier.instruction, shape: instructionPoints, options: nil)
            style.addSource(sourceShape)
            
            let symbol = MGLSymbolStyleLayer(identifier: StyleLayerIdentifier.instructionLabel, source: sourceShape)
            symbol.text = NSExpression(format: "instruction")
            symbol.textFontSize = NSExpression(forConstantValue: 14)
            symbol.textHaloWidth = NSExpression(forConstantValue: 1)
            symbol.textHaloColor = NSExpression(forConstantValue: UIColor.white)
            symbol.textOpacity = NSExpression(forConstantValue: 0.75)
            symbol.textAnchor = NSExpression(forConstantValue: "bottom-left")
            symbol.textJustification = NSExpression(forConstantValue: "left")
            
            let circle = MGLCircleStyleLayer(identifier: StyleLayerIdentifier.instructionCircle, source: sourceShape)
            circle.circleRadius = NSExpression(forConstantValue: 5)
            circle.circleOpacity = NSExpression(forConstantValue: 0.75)
            circle.circleColor = NSExpression(forConstantValue: UIColor.white)
            
            style.addLayer(circle)
            style.addLayer(symbol)
        }
    }
    
    /**
     Sets the camera directly over a series of coordinates.
     */
    public func setOverheadCameraView(from userLocation: CLLocation, along lineString: LineString, for padding: UIEdgeInsets) {
        isAnimatingToOverheadMode = true
        
        let line = MGLPolyline(lineString)
        
        tracksUserCourse = false
        
        // If the user has a short distance left on the route, prevent the camera from zooming all the way.
        // `MGLMapView.setVisibleCoordinateBounds(:edgePadding:animated:)` will go beyond what is convenient for the driver.
        guard line.overlayBounds.ne.distance(to: line.overlayBounds.sw) > NavigationMapViewMinimumDistanceForOverheadZooming else {
            let camera = self.camera
            camera.pitch = 0
            camera.heading = 0
            camera.centerCoordinate = userLocation.coordinate
            camera.altitude = self.defaultAltitude
            setCamera(camera, withDuration: 1, animationTimingFunction: nil) { [weak self] in
                self?.isAnimatingToOverheadMode = false
            }
            self.updateCourseView(to: userLocation, pitch: camera.pitch, direction: camera.heading, animated: true)
            return
        }
        
        let currentCamera = self.camera
        currentCamera.pitch = 0
        currentCamera.heading = 0

        contentInset = padding
        // Current contentInset gets incorporated to calculated camera.
        // edgePadding is set to .zero as there's no need for additional padding.
        let newCamera = camera(currentCamera, fitting: line, edgePadding: .zero)
        
        setCamera(newCamera, withDuration: 1, animationTimingFunction: nil) { [weak self] in
            self?.isAnimatingToOverheadMode = false
        }
        self.updateCourseView(to: userLocation, pitch: newCamera.pitch, direction: newCamera.heading, animated: true)
    }
    
    /**
     Recenters the camera and begins tracking the user's location.
     */
    public func recenterMap() {
        tracksUserCourse = true
        enableFrameByFrameCourseViewTracking(for: 3)
    }
}

// MARK: - Building Extrusion Highlighting

extension NavigationMapView {
       
    /**
     Receives coordinates for searching the map for buildings. If buildings are found, they will be highlighted in 2D or 3D depending on the `in3D` value.
     
     - parameter coordinates: Coordinates which represent building locations.
     - parameter extrudesBuildings: Switch which allows to highlight buildings in either 2D or 3D. Defaults to true.
     
     - returns: Bool indicating if number of buildings found equals number of coordinates supplied.
     */
    @discardableResult public func highlightBuildings(at coordinates: [CLLocationCoordinate2D], in3D extrudesBuildings: Bool = true) -> Bool {
        let foundBuildingIds = Set(coordinates.compactMap({ buildingIdentifier(at: $0) }))
        highlightBuildings(with: foundBuildingIds, in3D: extrudesBuildings)
        return foundBuildingIds.count == coordinates.count
    }
    
    /**
     Removes the highlight from all buildings highlighted by `highlightBuildings(at:in3D:)`.
     */
    public func unhighlightBuildings() {
        guard let highlightedBuildingsLayer = style?.layer(withIdentifier: StyleLayerIdentifier.buildingExtrusion) else { return }
        
        style?.removeLayer(highlightedBuildingsLayer)
    }
    
    private func addBuildingsSource() -> MGLSource? {
        let buildingsSource = style?.source(withIdentifier: SourceIdentifier.buildingExtrusion)
        if buildingsSource == nil {
            let buildingsSource = MGLVectorTileSource(identifier: SourceIdentifier.buildingExtrusion,
                                                      configurationURL: URL(string: "mapbox://mapbox.mapbox-streets-v8")!)
            style?.addSource(buildingsSource)
            
            return buildingsSource
        }
        
        return buildingsSource
    }
    
    private func addBuildingsLayer() -> MGLFillExtrusionStyleLayer? {
        if let highlightedBuildingsLayer = style?.layer(withIdentifier: StyleLayerIdentifier.buildingExtrusion) as? MGLFillExtrusionStyleLayer { return highlightedBuildingsLayer }
        guard let buildingsSource = addBuildingsSource() else { return nil }
        
        let highlightedBuildingsLayer = MGLFillExtrusionStyleLayer(identifier: StyleLayerIdentifier.buildingExtrusion, source: buildingsSource)
        highlightedBuildingsLayer.sourceLayerIdentifier = "building"
        highlightedBuildingsLayer.fillExtrusionColor = NSExpression(forConstantValue: buildingDefaultColor)
        highlightedBuildingsLayer.fillExtrusionOpacity = NSExpression(forConstantValue: 0.05)
        highlightedBuildingsLayer.fillExtrusionHeightTransition = MGLTransition(duration: 0.8, delay: 0)
        highlightedBuildingsLayer.fillExtrusionOpacityTransition = MGLTransition(duration: 0.8, delay: 0)
        
        style?.addLayer(highlightedBuildingsLayer)
        
        return highlightedBuildingsLayer
    }

    private func buildingIdentifier(at coordinate: CLLocationCoordinate2D) -> Int64? {
        let screenCoordinate = convert(coordinate, toPointTo: self)
        guard let style = style else { return nil }
        
        let identifiers = Set(style.layers.compactMap({ $0 as? MGLVectorStyleLayer }).filter({ $0.sourceLayerIdentifier == "building" }).compactMap({ $0.identifier }))
        let features = visibleFeatures(at: screenCoordinate, styleLayerIdentifiers: identifiers)

        if let feature = features.first, let identifier = feature.identifier as? Int64 {
            return identifier
        }
        
        return nil
    }
    
    private func highlightBuildings(with identifiers: Set<Int64>, in3D: Bool = false, extrudeAll: Bool = false) {
        // In case if set with highlighted building identifiers is empty - do nothing.
        if identifiers.isEmpty { return }
        // Add layer which will be used to highlight buildings if it wasn't added yet.
        guard let highlightedBuildingsLayer = addBuildingsLayer() else { return }
        
        if extrudeAll {
            highlightedBuildingsLayer.predicate = NSPredicate(format: "extrude = 'true' AND underground = 'false'")
        } else {
            // Form a predicate to filter out the other buildings from the datasource so only the desired ones are included.
            highlightedBuildingsLayer.predicate = NSPredicate(format: "extrude = 'true' AND underground = 'false' AND $featureIdentifier IN %@", identifiers.map { $0 })
        }
        
        // Buildings with identifiers will be highlighted with provided color. Rest of the buildings will be highlighted, but kept at a uniform color.
        let highlightedBuildingsHeightExpression = NSExpression(format: "TERNARY(%@ = TRUE AND (%@ = TRUE OR $featureIdentifier IN %@), height, 0)", in3D as NSValue, extrudeAll as NSValue, identifiers.map { $0 })
        let colorsByBuilding = Dictionary(identifiers.map { (NSExpression(forConstantValue: $0), NSExpression(forConstantValue: buildingHighlightColor)) }) { (_, last) in last }
        let highlightedBuildingsColorExpression = NSExpression(forMGLMatchingKey: NSExpression(forVariable: "featureIdentifier"), in: colorsByBuilding, default: NSExpression(forConstantValue: buildingDefaultColor))
        
        let fillExtrusionHeightStops = [0: NSExpression(forConstantValue: 0),
                                        13: NSExpression(forConstantValue: 0),
                                        13.25: highlightedBuildingsHeightExpression]
        
        let fillExtrusionBaseStops = [0: NSExpression(forConstantValue: 0),
                                      13: NSExpression(forConstantValue: 0),
                                      13.25: NSExpression(forKeyPath: "min_height")]
        
        let opacityStops = [13: 0.5, 17: 0.8]
        
        highlightedBuildingsLayer.fillExtrusionHeight = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", fillExtrusionHeightStops)
        highlightedBuildingsLayer.fillExtrusionBase = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", fillExtrusionBaseStops)
        highlightedBuildingsLayer.fillExtrusionColor = highlightedBuildingsColorExpression
        highlightedBuildingsLayer.fillExtrusionOpacity = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", opacityStops)
    }
}
