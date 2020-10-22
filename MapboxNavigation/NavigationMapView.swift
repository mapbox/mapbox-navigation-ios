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
        static let allRoutes = "\(identifierNamespace).allRoutes"

        static let waypoint = "\(identifierNamespace).waypoints"
        static let waypointCircle = "\(identifierNamespace).waypointsCircle"
        static let waypointSymbol = "\(identifierNamespace).waypointsSymbol"

        static let arrow = "\(identifierNamespace).arrow"
        static let arrowSymbol = "\(identifierNamespace).arrowSymbol"
        static let arrowStroke = "\(identifierNamespace).arrowStroke"
        
        static let instruction = "\(identifierNamespace).instruction"
        
        static let mainRouteCasing = "\(identifierNamespace).mainRouteCasing"
        
        static let buildingExtrusion = "\(identifierNamespace).buildingExtrusion"
    }
    
    struct StyleLayerIdentifier {
        static let namespace = Bundle.mapboxNavigation.bundleIdentifier ?? ""

        static let mainRoute = "\(identifierNamespace).mainRoute"
        static let mainRouteCasing = "\(identifierNamespace).mainRouteCasing"
        static let alternativeRoutes = "\(identifierNamespace).alternativeRoutes"
        static let alternativeRoutesCasing = "\(identifierNamespace).alternativeRoutesCasing"

        static let route = "\(identifierNamespace).route"
        static let routeCasing = "\(identifierNamespace).routeCasing"

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
    
    var userLocationForCourseTracking: CLLocation?
    var animatesUserLocation: Bool = false
    var altitude: CLLocationDistance
    var routes: [Route]?
    var isAnimatingToOverheadMode = false
    
    var shouldPositionCourseViewFrameByFrame = false {
        didSet {
            if shouldPositionCourseViewFrameByFrame {
                preferredFramesPerSecond = .maximum
            }
        }
    }
    
    var showsRoute: Bool {
        get {
            return style?.layer(withIdentifier: StyleLayerIdentifier.mainRoute) != nil &&
                   style?.layer(withIdentifier: StyleLayerIdentifier.mainRouteCasing) != nil
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
        guard let mainRoute = routes.first else { return }
        
        removeRoutes()
        
        self.routes = routes
        
        let allRoutesShape = navigationMapViewDelegate?.navigationMapView(self, shapeFor: routes) ?? shape(for: routes, legIndex: legIndex)
        let allRoutesSource = addAllRoutesSource(style, shape: allRoutesShape)
        
        let mainRouteCasingShape = navigationMapViewDelegate?.navigationMapView(self, shapeFor: [mainRoute]) ?? shape(for: [mainRoute], legIndex: legIndex)
        let mainRouteCasingSource = addMainRouteCasingSource(style, shape: mainRouteCasingShape)
        
        let mainRouteLayer = addMainRouteLayer(style, source: allRoutesSource, lineGradient: routeLineGradient(mainRoute, fractionTraveled: 0.0))
        let mainRouteCasingLayer = addMainRouteCasingLayer(style, source: mainRouteCasingSource, lineGradient: routeCasingGradient(0.0), below: mainRouteLayer)
        let alternativeRoutesLayer = addAlternativeRoutesLayer(style, source: allRoutesSource, below: mainRouteCasingLayer)
        addAlternativeRoutesCasingLayer(style, source: allRoutesSource, below: alternativeRoutesLayer)
    }
    
    // MARK: - Route line insertion methods
    
    func addAllRoutesSource(_ style: MGLStyle, shape: MGLShape?) -> MGLSource {
        if let allRoutesSource = style.source(withIdentifier: SourceIdentifier.allRoutes) as? MGLShapeSource {
            allRoutesSource.shape = shape
            return allRoutesSource
        }
        
        let allRoutesSource = MGLShapeSource(identifier: SourceIdentifier.allRoutes, shape: shape, options: [.lineDistanceMetrics: true])
        style.addSource(allRoutesSource)
        
        return allRoutesSource
    }
    
    func addMainRouteCasingSource(_ style: MGLStyle, shape: MGLShape?) -> MGLSource {
        if let mainRouteCasingSource = style.source(withIdentifier: SourceIdentifier.mainRouteCasing) as? MGLShapeSource {
            mainRouteCasingSource.shape = shape
            return mainRouteCasingSource
        }
        
        // FIXME: Using mainRouteCasingSource is a temporary workaround to prevent glitches when main route line and casing share the same source.
        // After fixing https://github.com/mapbox/mapbox-gl-native-ios/issues/355 creation of separate source for main route casing should be removed.
        let mainRouteCasingSource = MGLShapeSource(identifier: SourceIdentifier.mainRouteCasing, shape: shape, options: [.lineDistanceMetrics: true])
        style.addSource(mainRouteCasingSource)
        
        return mainRouteCasingSource
    }

    @discardableResult func addMainRouteLayer(_ style: MGLStyle, source: MGLSource, lineGradient: NSExpression?) -> MGLStyleLayer {
        let customMainRouteLayer = navigationMapViewDelegate?.navigationMapView(self,
                                                                                mainRouteStyleLayerWithIdentifier: StyleLayerIdentifier.mainRoute,
                                                                                source: source)
        let currentMainRouteLayer = style.layer(withIdentifier: StyleLayerIdentifier.mainRoute)
        
        if let mainRouteLayer = customMainRouteLayer, let _ = currentMainRouteLayer {
            return mainRouteLayer
        }
        
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
        
        let mainRouteLayer = MGLLineStyleLayer(identifier: StyleLayerIdentifier.mainRoute, source: source)
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

    @discardableResult func addMainRouteCasingLayer(_ style: MGLStyle, source: MGLSource, lineGradient: NSExpression, below layer: MGLStyleLayer) -> MGLStyleLayer {
        let customMainRouteCasingLayer = navigationMapViewDelegate?.navigationMapView(self,
                                                                                      mainRouteCasingStyleLayerWithIdentifier: StyleLayerIdentifier.mainRouteCasing,
                                                                                      source: source)
        let currentMainRouteCasingLayer = style.layer(withIdentifier: StyleLayerIdentifier.mainRouteCasing)
        
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
        
        let mainRouteCasingLayer = MGLLineStyleLayer(identifier: StyleLayerIdentifier.mainRouteCasing, source: source)
        mainRouteCasingLayer.predicate = NSPredicate(format: "isAlternateRoute == false")
        mainRouteCasingLayer.lineColor = NSExpression(forConstantValue: routeCasingColor)
        mainRouteCasingLayer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 1.5))
        mainRouteCasingLayer.lineJoin = NSExpression(forConstantValue: "round")
        mainRouteCasingLayer.lineCap = NSExpression(forConstantValue: "round")
        mainRouteCasingLayer.lineGradient = lineGradient
        
        style.insertLayer(mainRouteCasingLayer, below: layer)
        
        return mainRouteCasingLayer
    }
    
    @discardableResult func addAlternativeRoutesLayer(_ style: MGLStyle, source: MGLSource, below layer: MGLStyleLayer) -> MGLStyleLayer {
        let customAlternativeRoutesLayer = navigationMapViewDelegate?.navigationMapView(self,
                                                                                        alternativeRouteStyleLayerWithIdentifier: StyleLayerIdentifier.alternativeRoutes,
                                                                                        source: source)
        let currentAlternativeRoutesLayer = style.layer(withIdentifier: StyleLayerIdentifier.alternativeRoutes)
        
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
        
        let alternativeRoutesLayer = MGLLineStyleLayer(identifier: StyleLayerIdentifier.alternativeRoutes, source: source)
        alternativeRoutesLayer.predicate = NSPredicate(format: "isAlternateRoute == true")
        alternativeRoutesLayer.lineColor = NSExpression(forConstantValue: routeAlternateColor)
        alternativeRoutesLayer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel)
        alternativeRoutesLayer.lineJoin = NSExpression(forConstantValue: "round")
        alternativeRoutesLayer.lineCap = NSExpression(forConstantValue: "round")
        style.insertLayer(alternativeRoutesLayer, below: layer)
        
        return alternativeRoutesLayer
    }
    
    @discardableResult func addAlternativeRoutesCasingLayer(_ style: MGLStyle, source: MGLSource, below layer: MGLStyleLayer) -> MGLStyleLayer {
        let customAlternativeRoutesCasingLayer = navigationMapViewDelegate?.navigationMapView(self,
                                                                                              alternativeRouteCasingStyleLayerWithIdentifier: StyleLayerIdentifier.alternativeRoutesCasing,
                                                                                              source: source)
        let currentAlternativeRoutesCasingLayer = style.layer(withIdentifier: StyleLayerIdentifier.alternativeRoutesCasing)
        
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
        
        let alternativeRoutesCasingLayer = MGLLineStyleLayer(identifier: StyleLayerIdentifier.alternativeRoutesCasing, source: source)
        alternativeRoutesCasingLayer.predicate = NSPredicate(format: "isAlternateRoute == true")
        alternativeRoutesCasingLayer.lineColor = NSExpression(forConstantValue: routeAlternateCasingColor)
        alternativeRoutesCasingLayer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 1.5))
        alternativeRoutesCasingLayer.lineJoin = NSExpression(forConstantValue: "round")
        alternativeRoutesCasingLayer.lineCap = NSExpression(forConstantValue: "round")
        style.insertLayer(alternativeRoutesCasingLayer, below: layer)
        
        return alternativeRoutesCasingLayer
    }

    // MARK: - Vanishing route line methods
    
    /**
     Updates the route style layer and its casing style layer to gradually disappear as the user location puck travels along the displayed route.
     
     - parameter routeProgress: Current route progress.
     */
    public func updateRoute(_ routeProgress: RouteProgress) {
        guard let mainRouteLayer = style?.layer(withIdentifier: StyleLayerIdentifier.mainRoute) as? MGLLineStyleLayer,
            let mainRouteCasingLayer = style?.layer(withIdentifier: StyleLayerIdentifier.mainRouteCasing) as? MGLLineStyleLayer else { return }
        
        let fractionTraveled = routeProgress.fractionTraveled
        
        // In case if route was fully travelled - remove main route and its casing.
        if fractionTraveled >= 1.0 {
            style?.remove([mainRouteLayer, mainRouteCasingLayer])
            return
        }
        
        mainRouteLayer.lineGradient = routeLineGradient(routeProgress.route, fractionTraveled: fractionTraveled)
        mainRouteCasingLayer.lineGradient = routeCasingGradient(fractionTraveled)
    }
    
    private func routeLineGradient(_ route: Route, fractionTraveled: Double) -> NSExpression? {
        var gradientStops = [CGFloat: UIColor]()
        
        // In case if mainRouteLayer was already added - extract congestion segments out of it.
        if let mainRouteLayer = style?.layer(withIdentifier: StyleLayerIdentifier.mainRoute) as? MGLLineStyleLayer,
            // lineGradient contains 4 arguments, last one (stops) allows to store line gradient stops, if they're present - reuse them.
            let lineGradients = mainRouteLayer.lineGradient?.arguments?[3],
            let stops = lineGradients.expressionValue(with: nil, context: nil) as? NSDictionary {
            
            for (key, value) in stops {
                if let key = key as? CGFloat, let value = (value as? NSExpression)?.expressionValue(with: nil, context: nil) as? UIColor {
                    gradientStops[key] = value
                }
            }
        } else {
            /**
             We will keep track of this value as we iterate through
             the various congestion segments.
             */
            var distanceTraveled = fractionTraveled

            /**
             Begin by calculating individual congestion segments associated
             with a congestion level, represented as `MGLPolylineFeature`s.
             */
            guard let congestionSegments = addCongestion(to: route, legIndex: 0) else { return nil }

            /**
             To create the stops dictionary that represents the route line expressed
             as gradients, for every congestion segment we need one pair of dictionary
             entries to represent the color to be displayed between that range. Depending
             on the index of the congestion segment, the pair's first or second key
             will have a buffer value added or subtracted to make room for a gradient
             transition between congestion segments.

                green       gradient       red
                           transition
             |-----------|~~~~~~~~~~~~|----------|
             0         0.499        0.501       1.0
             */
            for (index, line) in congestionSegments.enumerated() {
                line.getCoordinates(line.coordinates, range: NSMakeRange(0, Int(line.pointCount)))
                // `UnsafeMutablePointer` is needed here to get the line’s coordinates.
                let buffPtr = UnsafeMutableBufferPointer(start: line.coordinates, count: Int(line.pointCount))
                let lineCoordinates = Array(buffPtr)

                // Get congestion color for the stop.
                let congestionLevel = line.attributes["congestion"] as? String
                let associatedCongestionColor = congestionColor(for: congestionLevel)

                // Measure the line length of the traffic segment.
                let lineString = LineString(lineCoordinates)
                guard let distance = lineString.distance() else { return nil }

                /**
                 If this is the first congestion segment, then the starting
                 percentage point will be zero.
                 */
                if index == congestionSegments.startIndex {
                    distanceTraveled = distanceTraveled + distance

                    let segmentEndPercentTraveled = CGFloat((distanceTraveled / route.distance))
                    gradientStops[segmentEndPercentTraveled.nextDown] = associatedCongestionColor
                    continue
                }

                /**
                 If this is the last congestion segment, then the ending
                 percentage point will be 1.0, to represent 100%.
                 */
                if index == congestionSegments.endIndex - 1 {
                    let segmentEndPercentTraveled = CGFloat(1.0)
                    gradientStops[segmentEndPercentTraveled.nextDown] = associatedCongestionColor
                    continue
                }

                /**
                 If this is not the first or last congestion segment, then
                 the starting and ending percent values traveled for this segment
                 will be a fractional amount more/less than the actual values.
                 */
                let segmentStartPercentTraveled = CGFloat((distanceTraveled / route.distance))
                gradientStops[segmentStartPercentTraveled.nextUp] = associatedCongestionColor

                distanceTraveled = distanceTraveled + distance

                let segmentEndPercentTraveled = CGFloat((distanceTraveled / route.distance))
                gradientStops[segmentEndPercentTraveled.nextDown] = associatedCongestionColor
            }
        }
                
        let percentTraveled = CGFloat(fractionTraveled)
        
        // Filter out only the stops that are greater than or equal to the percent of the route traveled.
        var filteredGradientStops = gradientStops.filter { key, value in
            return key >= percentTraveled
        }
        
        // Then, get the lowest value from the above and fade the range from zero that lowest value,
        // which represents the % of the route traveled.
        if let minStop = filteredGradientStops.min(by: { $0.0 < $1.0 }) {
            filteredGradientStops[0.0] = traversedRouteColor
            filteredGradientStops[percentTraveled.nextDown] = traversedRouteColor
            filteredGradientStops[percentTraveled] = minStop.value
        }
        
        // It's not possible to create line gradient in case if there are no route gradient stops.
        if !filteredGradientStops.isEmpty {
            // Dictionary usage is causing crashes in Release mode (when built with optimization SWIFT_OPTIMIZATION_LEVEL = -O flag).
            // Even though Dictionary contains valid objects prior to passing it to NSExpression:
            // [0.4109119609930762: UIExtendedSRGBColorSpace 0.952941 0.65098 0.309804 1,
            // 0.4109119609930761: UIExtendedSRGBColorSpace 0.337255 0.658824 0.984314 1]
            // keys become nil in NSExpression arguments list:
            // [0.4109119609930762 = nil,
            // 0.4109119609930761 = nil]
            // Passing NSDictionary with all data from original Dictionary to NSExpression fixes issue.
            return NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($lineProgress, 'linear', nil, %@)", NSDictionary(dictionary: filteredGradientStops))
        }
        
        return nil
    }
    
    private func routeCasingGradient(_ fractionTraveled: Double) -> NSExpression {
        let percentTraveled = CGFloat(fractionTraveled)
        var gradientStops = [CGFloat: UIColor]()
        gradientStops[0.0] = traversedRouteColor
        gradientStops[percentTraveled.nextDown] = traversedRouteColor
        gradientStops[percentTraveled] = routeCasingColor
        
        return NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($lineProgress, 'linear', nil, %@)", NSDictionary(dictionary: gradientStops))
    }
    
    /**
     Removes route line and route line casing from map
     */
    public func removeRoutes() {
        guard let style = style else {
            return
        }
        
        style.remove([
            StyleLayerIdentifier.mainRoute,
            StyleLayerIdentifier.mainRouteCasing,
            StyleLayerIdentifier.alternativeRoutes,
            StyleLayerIdentifier.alternativeRoutesCasing
        ].compactMap { style.layer(withIdentifier: $0) })
        style.remove(Set([
            SourceIdentifier.allRoutes,
            SourceIdentifier.mainRouteCasing
        ].compactMap { style.source(withIdentifier: $0) }))
        
        routes = nil
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
    
    //TODO: Change to point-based distance calculation
    private func waypoints(on routes: [Route], closeTo point: CGPoint) -> [Waypoint]? {
        let tapCoordinate = convert(point, toCoordinateFrom: self)
        let multipointRoutes = routes.filter { $0.legs.count > 1}
        guard multipointRoutes.count > 0 else { return nil }
        let waypoints = multipointRoutes.compactMap { route in
            route.legs.dropLast().compactMap { $0.destination }
        }.flatMap {$0}
        
        //lets sort the array in order of closest to tap
        let closest = waypoints.sorted { (left, right) -> Bool in
            let leftDistance = left.coordinate.distance(to: tapCoordinate)
            let rightDistance = right.coordinate.distance(to: tapCoordinate)
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

    func shape(for routes: [Route], legIndex: Int?) -> MGLShape? {
        guard let firstRoute = routes.first else { return nil }

        let mainRoute = MGLPolylineFeature(firstRoute.shape!)
        mainRoute.attributes["isAlternateRoute"] = false
        
        var altRoutes: [MGLPolylineFeature] = []
        
        for route in routes.suffix(from: 1) {
            let polyline = MGLPolylineFeature(route.shape!)
            polyline.attributes["isAlternateRoute"] = true
            altRoutes.append(polyline)
        }

        return MGLShapeCollectionFeature(shapes: altRoutes + [mainRoute])
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

                let mergedCongestionSegments = combine(legCoordinates, with: legCongestion)

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
     
     - coordinates: The coordinates of a leg.
     - congestions: The congestion levels along a leg. There should be one fewer congestion levels than coordinates.
     */
    func combine(_ coordinates: [CLLocationCoordinate2D], with congestions: [CongestionLevel]) -> [CongestionSegment] {
        var segments: [CongestionSegment] = []
        segments.reserveCapacity(congestions.count)
        for (firstSegment, congestionLevel) in zip(zip(coordinates, coordinates.suffix(from: 1)), congestions) {
            let coordinates = [firstSegment.0, firstSegment.1]
            if segments.last?.1 == congestionLevel {
                segments[segments.count - 1].0 += coordinates
            } else {
                segments.append((coordinates, congestionLevel))
            }
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
     Given a congestion level, return its associated color.
     */
    private func congestionColor(for congestionLevel: String?) -> UIColor {
        switch congestionLevel {
        case "low":
            return trafficLowColor
        case "moderate":
            return trafficModerateColor
        case "heavy":
            return trafficHeavyColor
        case "severe":
            return trafficSevereColor
        default:
            return trafficUnknownColor
        }
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
