import Foundation
import Mapbox
import MapboxDirections
import MapboxCoreNavigation
import Turf

/**
 `NavigationMapView` is a subclass of `MGLMapView` with convenience functions for adding `Route` lines to a map.
 */
@objc(MBNavigationMapView)
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
    @objc public var minimumFramesPerSecond = MGLMapViewPreferredFramesPerSecond(20)
    
    /**
     Returns the altitude that the map camera initally defaults to.
     */
    @objc public var defaultAltitude: CLLocationDistance = 1000.0
    
    /**
     Returns the altitude the map conditionally zooms out to when user is on a motorway, and the maneuver length is sufficently long.
    */
    @objc public var zoomedOutMotorwayAltitude: CLLocationDistance = 2000.0
    
    /**
     Returns the threshold for what the map considers a "long-enough" maneuver distance to trigger a zoom-out when the user enters a motorway.
     */
    @objc public var longManeuverDistance: CLLocationDistance = 1000.0
    
    /**
     Maximum distance the user can tap for a selection to be valid when selecting an alternate route.
     */
    @objc public var tapGestureDistanceThreshold: CGFloat = 50
    
    /**
     The object that acts as the navigation delegate of the map view.
     */
    @objc public weak var navigationMapViewDelegate: NavigationMapViewDelegate?
    @available(*, deprecated, renamed: "navigationMapViewDelegate")
    @objc public weak var navigationMapDelegate: NavigationMapViewDelegate? {
        get { return navigationMapViewDelegate }
        set { navigationMapViewDelegate = newValue}
    }
    
    /**
     The object that acts as the course tracking delegate of the map view.
     */
    public weak var courseTrackingDelegate: NavigationMapViewCourseTrackingDelegate?
    
    let sourceOptions: [MGLShapeSourceOption: Any] = [.maximumZoomLevel: 16]

    // MARK: - Instance Properties
    let sourceIdentifier = "routeSource"
    let sourceCasingIdentifier = "routeCasingSource"
    let routeLayerIdentifier = "routeLayer"
    let routeLayerCasingIdentifier = "routeLayerCasing"
    let waypointSourceIdentifier = "waypointsSource"
    let waypointCircleIdentifier = "waypointsCircle"
    let waypointSymbolIdentifier = "waypointsSymbol"
    let arrowSourceIdentifier = "arrowSource"
    let arrowSourceStrokeIdentifier = "arrowSourceStroke"
    let arrowLayerIdentifier = "arrowLayer"
    let arrowSymbolLayerIdentifier = "arrowSymbolLayer"
    let arrowLayerStrokeIdentifier = "arrowStrokeLayer"
    let arrowCasingSymbolLayerIdentifier = "arrowCasingSymbolLayer"
    let arrowSymbolSourceIdentifier = "arrowSymbolSource"
    let instructionSource = "instructionSource"
    let instructionLabel = "instructionLabel"
    let instructionCircle = "instructionCircle"
    
    @objc dynamic public var trafficUnknownColor: UIColor = .trafficUnknown
    @objc dynamic public var trafficLowColor: UIColor = .trafficLow
    @objc dynamic public var trafficModerateColor: UIColor = .trafficModerate
    @objc dynamic public var trafficHeavyColor: UIColor = .trafficHeavy
    @objc dynamic public var trafficSevereColor: UIColor = .trafficSevere
    @objc dynamic public var routeCasingColor: UIColor = .defaultRouteCasing
    @objc dynamic public var routeAlternateColor: UIColor = .defaultAlternateLine
    @objc dynamic public var routeAlternateCasingColor: UIColor = .defaultAlternateLineCasing
    @objc dynamic public var maneuverArrowColor: UIColor = .defaultManeuverArrow
    @objc dynamic public var maneuverArrowStrokeColor: UIColor = .defaultManeuverArrowStroke
    
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
            return style?.layer(withIdentifier: routeLayerIdentifier) != nil
        }
    }
    
    open override var showsUserLocation: Bool {
        get {
            if tracksUserCourse || userLocationForCourseTracking != nil {
                return !(userCourseView?.isHidden ?? true)
            }
            return super.showsUserLocation
        }
        set {
            if tracksUserCourse || userLocationForCourseTracking != nil {
                super.showsUserLocation = false
                
                if userCourseView == nil {
                    userCourseView = UserPuckCourseView(frame: CGRect(origin: .zero, size: CGSize(width: 75, height: 75)))
                }
                userCourseView?.isHidden = !newValue
            } else {
                userCourseView?.isHidden = true
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
        if let anchorPoint = navigationMapViewDelegate?.navigationMapViewUserAnchorPoint?(self), anchorPoint != .zero {
            return anchorPoint
        }
        
        // Inset by the safe area to avoid notches.
        // Inset by the content inset to avoid application-defined content.
        var contentFrame = bounds.inset(by: safeArea).inset(by: contentInset)
        
        // Avoid letting the puck go partially off-screen, and add a comfortable padding beyond that.
        let courseViewBounds = userCourseView?.bounds ?? .zero
        contentFrame = contentFrame.insetBy(dx: min(NavigationMapView.courseViewMinimumInsets.left + courseViewBounds.width / 2.0, contentFrame.width / 2.0),
                                            dy: min(NavigationMapView.courseViewMinimumInsets.top + courseViewBounds.height / 2.0, contentFrame.height / 2.0))
        
        // Get the bottom-center of the remaining frame.
        assert(!contentFrame.isInfinite)
        return CGPoint(x: contentFrame.midX, y: contentFrame.maxY)
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
                courseTrackingDelegate?.navigationMapViewDidStartTrackingCourse?(self)
            } else {
                courseTrackingDelegate?.navigationMapViewDidStopTrackingCourse?(self)
            }
            if let location = userLocationForCourseTracking {
                updateCourseTracking(location: location, animated: true)
            }
        }
    }

    /**
     A `UIView` used to indicate the user’s location and course on the map.
     
     If the view conforms to `UserCourseView`, its `UserCourseView.update(location:pitch:direction:animated:)` method is frequently called to ensure that its visual appearance matches the map’s camera.
     */
    @objc public var userCourseView: UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let userCourseView = userCourseView {
                if let location = userLocationForCourseTracking {
                    updateCourseTracking(location: location, animated: false)
                } else {
                    userCourseView.center = userAnchorPoint
                }
                addSubview(userCourseView)
            }
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
        
        userCourseView?.center = convert(location.coordinate, toPointTo: self)
    }
    
    /**
     Updates the map view’s preferred frames per second to the appropriate value for the current route progress.
     
     This method accounts for the proximity to a maneuver and the current power source. It has no effect if `tracksUserCourse` is set to `true`.
     */
    @objc(updatePreferredFrameRateForRouteProgress:)
    open func updatePreferredFrameRate(for routeProgress: RouteProgress) {
        guard tracksUserCourse else { return }
        
        let stepProgress = routeProgress.currentLegProgress.currentStepProgress
        let expectedTravelTime = stepProgress.step.expectedTravelTime
        let durationUntilNextManeuver = stepProgress.durationRemaining
        let durationSincePreviousManeuver = expectedTravelTime - durationUntilNextManeuver
        
        if UIDevice.current.isPluggedIn {
            preferredFramesPerSecond = FrameIntervalOptions.pluggedInFramesPerSecond
        } else if let upcomingStep = routeProgress.currentLegProgress.upcomingStep,
            upcomingStep.maneuverDirection == .straightAhead || upcomingStep.maneuverDirection == .slightLeft || upcomingStep.maneuverDirection == .slightRight {
            preferredFramesPerSecond = shouldPositionCourseViewFrameByFrame ? FrameIntervalOptions.defaultFramesPerSecond : minimumFramesPerSecond
        } else if durationUntilNextManeuver > FrameIntervalOptions.durationUntilNextManeuver &&
            durationSincePreviousManeuver > FrameIntervalOptions.durationSincePreviousManeuver {
            preferredFramesPerSecond = shouldPositionCourseViewFrameByFrame ? FrameIntervalOptions.defaultFramesPerSecond : minimumFramesPerSecond
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
    
    @objc private func disableUserCourseTracking() {
        guard tracksUserCourse else { return }
        tracksUserCourse = false
    }
    
    @objc public func updateCourseTracking(location: CLLocation?, camera: MGLMapCamera? = nil, animated: Bool = false) {
        // While animating to overhead mode, don't animate the puck.
        let duration: TimeInterval = animated && !isAnimatingToOverheadMode ? 1 : 0
        animatesUserLocation = animated
        userLocationForCourseTracking = location
        guard let location = location, CLLocationCoordinate2DIsValid(location.coordinate) else {
            return
        }
        
        if tracksUserCourse {
            let newCamera = camera ?? MGLMapCamera(lookingAtCenter: location.coordinate, altitude: altitude, pitch: 45, heading: location.course)
            let function: CAMediaTimingFunction? = animated ? CAMediaTimingFunction(name: .linear) : nil
            let point = userAnchorPoint
            let padding = UIEdgeInsets(top: point.y, left: point.x, bottom: bounds.height - point.y, right: bounds.width - point.x)
            // Omit padding when https://github.com/mapbox/mapbox-gl-native/pull/14081 has landed
            setCamera(newCamera, withDuration: duration, animationTimingFunction: function, edgePadding: padding, completionHandler: nil)
            userCourseView?.center = userAnchorPoint
        } else {
            // Animate course view updates in overview mode
            UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear], animations: { [weak self] in
                guard let point = self?.convert(location.coordinate, toPointTo: self) else { return }
                self?.userCourseView?.center = point
            })
        }
        
        if let userCourseView = userCourseView as? UserCourseView {
            if let customTransformation = userCourseView.update?(location: location, pitch: self.camera.pitch, direction: direction, animated: animated, tracksUserCourse: tracksUserCourse) {
                customTransformation
            } else {
                self.userCourseView?.applyDefaultUserPuckTransformation(location: location, pitch: self.camera.pitch, direction: direction, animated: animated, tracksUserCourse: tracksUserCourse)
            }
        } else {
            userCourseView?.applyDefaultUserPuckTransformation(location: location, pitch: self.camera.pitch, direction: direction, animated: animated, tracksUserCourse: tracksUserCourse)
        }
    }
    
    //MARK: -  Gesture Recognizers
    
    /**
     Fired when NavigationMapView detects a tap not handled elsewhere by other gesture recognizers.
     */
    @objc func didRecieveTap(sender: UITapGestureRecognizer) {
        guard let routes = routes, let tapPoint = sender.point else { return }
        
        let waypointTest = waypoints(on: routes, closeTo: tapPoint) //are there waypoints near the tapped location?
        if let selected = waypointTest?.first { //test passes
            navigationMapViewDelegate?.navigationMapView?(self, didSelect: selected)
            return
        } else if let routes = self.routes(closeTo: tapPoint) {
            guard let selectedRoute = routes.first else { return }
            navigationMapViewDelegate?.navigationMapView?(self, didSelect: selectedRoute)
        }
        
    }
    
    typealias CompositeCourseView = UIView & UserCourseView
    
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
            
            if let userCourseView = userCourseView as? CompositeCourseView {
                userCourseView.update?(location: location,
                                       pitch: camera.pitch,
                                       direction: direction,
                                       animated: false,
                                       tracksUserCourse: tracksUserCourse)
                
                userCourseView.center = convert(location.coordinate, toPointTo: self)
            }
        }
    }
    
    // MARK: Feature Addition/Removal
    /**
     Showcases route array. Adds routes and waypoints to map, and sets camera to point encompassing the route.
    */
    public static let defaultPadding: UIEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    
    @objc public func showcase(_ routes: [Route], padding: UIEdgeInsets = NavigationMapView.defaultPadding, animated: Bool = false) {
        guard let active = routes.first,
              let coords = active.coordinates,
              !coords.isEmpty else { return } //empty array
        
        removeArrow()
        removeRoutes()
        removeWaypoints()
        
        showRoutes(routes)
        showWaypoints(active)
        
        fit(to: active, facing: 0, padding: padding, animated: animated)
    }
    
    func fit(to route: Route, facing direction:CLLocationDirection = 0, padding: UIEdgeInsets = NavigationMapView.defaultPadding, animated: Bool = false) {
        guard let coords = route.coordinates, !coords.isEmpty else { return }
      
        setUserTrackingMode(.none, animated: false)
        let line = MGLPolyline(coordinates: coords, count: UInt(coords.count))
        let camera = cameraThatFitsShape(line, direction: direction, edgePadding: padding)
        
        setCamera(camera, animated: animated)
    }
    
    /**
     Adds or updates both the route line and the route line casing
     */
    @objc public func showRoutes(_ routes: [Route], legIndex: Int = 0) {
        guard let style = style else { return }
        guard let mainRoute = routes.first else { return }
        self.routes = routes
        
        let polylines = navigationMapViewDelegate?.navigationMapView?(self, shapeFor: routes) ?? shape(for: routes, legIndex: legIndex)
        let mainPolylineSimplified = navigationMapViewDelegate?.navigationMapView?(self, simplifiedShapeFor: mainRoute) ?? shape(forCasingOf: mainRoute, legIndex: legIndex)
        
        if let source = style.source(withIdentifier: sourceIdentifier) as? MGLShapeSource,
            let sourceSimplified = style.source(withIdentifier: sourceCasingIdentifier) as? MGLShapeSource {
            source.shape = polylines
            sourceSimplified.shape = mainPolylineSimplified
        } else {
            let lineSource = MGLShapeSource(identifier: sourceIdentifier, shape: polylines, options: [.lineDistanceMetrics: true])
            let lineCasingSource = MGLShapeSource(identifier: sourceCasingIdentifier, shape: mainPolylineSimplified, options: [.lineDistanceMetrics: true])
            style.addSource(lineSource)
            style.addSource(lineCasingSource)
            
            let line = navigationMapViewDelegate?.navigationMapView?(self, routeStyleLayerWithIdentifier: routeLayerIdentifier, source: lineSource) ?? routeStyleLayer(identifier: routeLayerIdentifier, source: lineSource)
            let lineCasing = navigationMapViewDelegate?.navigationMapView?(self, routeCasingStyleLayerWithIdentifier: routeLayerCasingIdentifier, source: lineCasingSource) ?? routeCasingStyleLayer(identifier: routeLayerCasingIdentifier, source: lineSource)
            
            for layer in style.layers.reversed() {
                if !(layer is MGLSymbolStyleLayer) &&
                    layer.identifier != arrowLayerIdentifier && layer.identifier != arrowSymbolLayerIdentifier && layer.identifier != arrowCasingSymbolLayerIdentifier && layer.identifier != arrowLayerStrokeIdentifier && layer.identifier != waypointCircleIdentifier {
                    style.insertLayer(line, below: layer)
                    style.insertLayer(lineCasing, below: line)
                    break
                }
            }
        }
    }
    
    /**
     Removes route line and route line casing from map
     */
    @objc public func removeRoutes() {
        guard let style = style else {
            return
        }
        
        if let line = style.layer(withIdentifier: routeLayerIdentifier) {
            style.removeLayer(line)
        }
        
        if let lineCasing = style.layer(withIdentifier: routeLayerCasingIdentifier) {
            style.removeLayer(lineCasing)
        }
        
        if let lineSource = style.source(withIdentifier: sourceIdentifier) {
            style.removeSource(lineSource)
        }
        
        if let lineCasingSource = style.source(withIdentifier: sourceCasingIdentifier) {
            style.removeSource(lineCasingSource)
        }
    }
    
    /**
     Adds the route waypoints to the map given the current leg index. Previous waypoints for completed legs will be omitted.
     */
    @objc public func showWaypoints(_ route: Route, legIndex: Int = 0) {
        guard let style = style else {
            return
        }

        let waypoints: [Waypoint] = Array(route.legs.map { $0.destination }.dropLast())
        
        let source = navigationMapViewDelegate?.navigationMapView?(self, shapeFor: waypoints, legIndex: legIndex) ?? shape(for: waypoints, legIndex: legIndex)
        if route.routeOptions.waypoints.count > 2 { //are we on a multipoint route?
            
            routes = [route] //update the model
            if let waypointSource = style.source(withIdentifier: waypointSourceIdentifier) as? MGLShapeSource {
                waypointSource.shape = source
            } else {
                let sourceShape = MGLShapeSource(identifier: waypointSourceIdentifier, shape: source, options: sourceOptions)
                style.addSource(sourceShape)
                
                let circles = navigationMapViewDelegate?.navigationMapView?(self, waypointStyleLayerWithIdentifier: waypointCircleIdentifier, source: sourceShape) ?? routeWaypointCircleStyleLayer(identifier: waypointCircleIdentifier, source: sourceShape)
                let symbols = navigationMapViewDelegate?.navigationMapView?(self, waypointSymbolStyleLayerWithIdentifier: waypointSymbolIdentifier, source: sourceShape) ?? routeWaypointSymbolStyleLayer(identifier: waypointSymbolIdentifier, source: sourceShape)
                
                if let arrowLayer = style.layer(withIdentifier: arrowCasingSymbolLayerIdentifier) {
                    style.insertLayer(circles, above: arrowLayer)
                } else {
                    style.addLayer(circles)
                }
                
                style.insertLayer(symbols, above: circles)
            }
        }
        
        if let lastLeg =  route.legs.last {
            removeAnnotations(annotationsToRemove() ?? [])
            let destination = NavigationAnnotation()
            destination.coordinate = lastLeg.destination.coordinate
            addAnnotation(destination)
        }
    }
    
    func annotationsToRemove() -> [MGLAnnotation]? {
        return annotations?.filter { $0 is NavigationAnnotation }
    }
    
    /**
     Removes all waypoints from the map.
     */
    @objc public func removeWaypoints() {
        guard let style = style else { return }
        
        removeAnnotations(annotationsToRemove() ?? [])
        
        if let circleLayer = style.layer(withIdentifier: waypointCircleIdentifier) {
            style.removeLayer(circleLayer)
        }
        if let symbolLayer = style.layer(withIdentifier: waypointSymbolIdentifier) {
            style.removeLayer(symbolLayer)
        }
        if let waypointSource = style.source(withIdentifier: waypointSourceIdentifier) {
            style.removeSource(waypointSource)
        }
        if let circleSource = style.source(withIdentifier: waypointCircleIdentifier) {
            style.removeSource(circleSource)
        }
        if let symbolSource = style.source(withIdentifier: waypointSymbolIdentifier) {
            style.removeSource(symbolSource)
        }
    }
    
    /**
     Shows the step arrow given the current `RouteProgress`.
     */
    @objc public func addArrow(route: Route, legIndex: Int, stepIndex: Int) {
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
            
            let arrowSourceStroke = MGLShapeSource(identifier: arrowSourceStrokeIdentifier, shape: arrowStrokeShape, options: sourceOptions)
            let arrowStroke = MGLLineStyleLayer(identifier: arrowLayerStrokeIdentifier, source: arrowSourceStroke)
            let arrowSource = MGLShapeSource(identifier: arrowSourceIdentifier, shape: arrowShape, options: sourceOptions)
            let arrow = MGLLineStyleLayer(identifier: arrowLayerIdentifier, source: arrowSource)
            
            if let source = style.source(withIdentifier: arrowSourceIdentifier) as? MGLShapeSource {
                source.shape = arrowShape
            } else {
                arrow.minimumZoomLevel = minimumZoomLevel
                arrow.lineCap = NSExpression(forConstantValue: "butt")
                arrow.lineJoin = NSExpression(forConstantValue: "round")
                arrow.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 0.70))
                arrow.lineColor = NSExpression(forConstantValue: maneuverArrowColor)
                
                style.addSource(arrowSource)
                if let waypoints = style.layer(withIdentifier: waypointCircleIdentifier) {
                    style.insertLayer(arrow, below: waypoints)
                } else {
                    style.addLayer(arrow)
                }
            }
            
            if let source = style.source(withIdentifier: arrowSourceStrokeIdentifier) as? MGLShapeSource {
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
            let arrowSymbolSource = MGLShapeSource(identifier: arrowSymbolSourceIdentifier, features: [point], options: sourceOptions)
            
            if let source = style.source(withIdentifier: arrowSymbolSourceIdentifier) as? MGLShapeSource {
                source.shape = arrowSymbolSource.shape
                if let arrowSymbolLayer = style.layer(withIdentifier: arrowSymbolLayerIdentifier) as? MGLSymbolStyleLayer {
                    arrowSymbolLayer.iconRotation = NSExpression(forConstantValue: shaftDirection as NSNumber)
                }
                if let arrowSymbolLayerCasing = style.layer(withIdentifier: arrowCasingSymbolLayerIdentifier) as? MGLSymbolStyleLayer {
                    arrowSymbolLayerCasing.iconRotation = NSExpression(forConstantValue: shaftDirection as NSNumber)
                }
            } else {
                let arrowSymbolLayer = MGLSymbolStyleLayer(identifier: arrowSymbolLayerIdentifier, source: arrowSymbolSource)
                arrowSymbolLayer.minimumZoomLevel = minimumZoomLevel
                arrowSymbolLayer.iconImageName = NSExpression(forConstantValue: "triangle-tip-navigation")
                arrowSymbolLayer.iconColor = NSExpression(forConstantValue: maneuverArrowColor)
                arrowSymbolLayer.iconRotationAlignment = NSExpression(forConstantValue: "map")
                arrowSymbolLayer.iconRotation = NSExpression(forConstantValue: shaftDirection as NSNumber)
                arrowSymbolLayer.iconScale = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 0.12))
                arrowSymbolLayer.iconAllowsOverlap = NSExpression(forConstantValue: true)
                
                let arrowSymbolLayerCasing = MGLSymbolStyleLayer(identifier: arrowCasingSymbolLayerIdentifier, source: arrowSymbolSource)
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
    @objc public func removeArrow() {
        guard let style = style else {
            return
        }
        
        if let arrowLayer = style.layer(withIdentifier: arrowLayerIdentifier) {
            style.removeLayer(arrowLayer)
        }
        
        if let arrowLayerStroke = style.layer(withIdentifier: arrowLayerStrokeIdentifier) {
            style.removeLayer(arrowLayerStroke)
        }
        
        if let arrowSymbolLayer = style.layer(withIdentifier: arrowSymbolLayerIdentifier) {
            style.removeLayer(arrowSymbolLayer)
        }
        
        if let arrowCasingSymbolLayer = style.layer(withIdentifier: arrowCasingSymbolLayerIdentifier) {
            style.removeLayer(arrowCasingSymbolLayer)
        }
        
        if let arrowSource = style.source(withIdentifier: arrowSourceIdentifier) {
            style.removeSource(arrowSource)
        }
        
        if let arrowStrokeSource = style.source(withIdentifier: arrowSourceStrokeIdentifier) {
            style.removeSource(arrowStrokeSource)
        }
        
        if let arrowSymboleSource = style.source(withIdentifier: arrowSymbolSourceIdentifier) {
            style.removeSource(arrowSymboleSource)
        }
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
    
    //TODO: Change to point-based distance calculation
    private func waypoints(on routes: [Route], closeTo point: CGPoint) -> [Waypoint]? {
        let tapCoordinate = convert(point, toCoordinateFrom: self)
        let multipointRoutes = routes.filter { $0.routeOptions.waypoints.count >= 3}
        guard multipointRoutes.count > 0 else { return nil }
        let waypoints = multipointRoutes.flatMap({$0.routeOptions.waypoints})
        
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
        guard let routes = routes?.filter({ $0.coordinates?.count ?? 0 > 1 }) else { return nil }
        
        //Sort routes by closest distance to tap gesture.
        let closest = routes.sorted { (left, right) -> Bool in
            
            //existance has been assured through use of filter.
            let leftLine = Polyline(left.coordinates!)
            let rightLine = Polyline(right.coordinates!)
            let leftDistance = leftLine.closestCoordinate(to: tapCoordinate)!.distance
            let rightDistance = rightLine.closestCoordinate(to: tapCoordinate)!.distance
            
            return leftDistance < rightDistance
        }
        
        //filter closest coordinates by which ones are under threshold.
        let candidates = closest.filter {
            let closestCoordinate = Polyline($0.coordinates!).closestCoordinate(to: tapCoordinate)!.coordinate
            let closestPoint = self.convert(closestCoordinate, toPointTo: self)
            
            return closestPoint.distance(to: point) < tapGestureDistanceThreshold
        }
        return candidates
    }

    func shape(for routes: [Route], legIndex: Int?) -> MGLShape? {
        guard let firstRoute = routes.first else { return nil }
        guard let congestedRoute = addCongestion(to: firstRoute, legIndex: legIndex) else { return nil }
        
        var altRoutes: [MGLPolylineFeature] = []
        
        for route in routes.suffix(from: 1) {
            let polyline = MGLPolylineFeature(coordinates: route.coordinates!, count: UInt(route.coordinates!.count))
            polyline.attributes["isAlternateRoute"] = true
            altRoutes.append(polyline)
        }
        
        return MGLShapeCollectionFeature(shapes: altRoutes + congestedRoute)
    }
    
    func addCongestion(to route: Route, legIndex: Int?) -> [MGLPolylineFeature]? {
        guard let coordinates = route.coordinates else { return nil }
        
        var linesPerLeg: [MGLPolylineFeature] = []
        
        for (index, leg) in route.legs.enumerated() {
            // If there is no congestion, don't try and add it
            guard let legCongestion = leg.segmentCongestionLevels, legCongestion.count < coordinates.count else {
                return [MGLPolylineFeature(coordinates: route.coordinates!, count: UInt(route.coordinates!.count))]
            }
            
            // The last coord of the preceding step, is shared with the first coord of the next step, we don't need both.
            let legCoordinates: [CLLocationCoordinate2D] = leg.steps.enumerated().reduce([]) { allCoordinates, current in
                let index = current.offset
                let step = current.element
                let stepCoordinates = step.coordinates!
                
                return index == 0 ? stepCoordinates : allCoordinates + stepCoordinates.suffix(from: 1)
            }
            
            let mergedCongestionSegments = combine(legCoordinates, with: legCongestion)
            
            let lines: [MGLPolylineFeature] = mergedCongestionSegments.map { (congestionSegment: CongestionSegment) -> MGLPolylineFeature in
                let polyline = MGLPolylineFeature(coordinates: congestionSegment.0, count: UInt(congestionSegment.0.count))
                polyline.attributes[MBCongestionAttribute] = String(describing: congestionSegment.1)
                polyline.attributes["isAlternateRoute"] = false
                if let legIndex = legIndex {
                    polyline.attributes[MBCurrentLegAttribute] = index == legIndex
                } else {
                    polyline.attributes[MBCurrentLegAttribute] = index == 0
                }
                return polyline
            }
            
            linesPerLeg.append(contentsOf: lines)
        }
        
        return linesPerLeg
    }
    
    func combine(_ coordinates: [CLLocationCoordinate2D], with congestions: [CongestionLevel]) -> [CongestionSegment] {
        var segments: [CongestionSegment] = []
        segments.reserveCapacity(congestions.count)
        for (index, congestion) in congestions.enumerated() {
            
            let congestionSegment: ([CLLocationCoordinate2D], CongestionLevel) = ([coordinates[index], coordinates[index + 1]], congestion)
            let coordinates = congestionSegment.0
            let congestionLevel = congestionSegment.1
            
            if segments.last?.1 == congestionLevel {
                segments[segments.count - 1].0 += coordinates
            } else {
                segments.append(congestionSegment)
            }
        }
        return segments
    }
    
    func shape(forCasingOf route: Route, legIndex: Int?) -> MGLShape? {
        var linesPerLeg: [MGLPolylineFeature] = []
        
        for (index, leg) in route.legs.enumerated() {
            let legCoordinates: [CLLocationCoordinate2D] = Array(leg.steps.compactMap {
                $0.coordinates
            }.joined())
            
            let polyline = MGLPolylineFeature(coordinates: legCoordinates, count: UInt(legCoordinates.count))
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
    
    func routeStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
        
        let line = MGLLineStyleLayer(identifier: identifier, source: source)
        line.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel)
        line.lineOpacity = NSExpression(forConditional:
            NSPredicate(format: "isAlternateRoute == true"),
                                        trueExpression: NSExpression(forConstantValue: 1),
                                        falseExpression: NSExpression(forConditional: NSPredicate(format: "isCurrentLeg == true"),
                                                                      trueExpression: NSExpression(forConstantValue: 1),
                                                                      falseExpression: NSExpression(forConstantValue: 0)))
        line.lineColor = NSExpression(format: "TERNARY(isAlternateRoute == true, %@, MGL_MATCH(congestion, 'low' , %@, 'moderate', %@, 'heavy', %@, 'severe', %@, %@))", routeAlternateColor, trafficLowColor, trafficModerateColor, trafficHeavyColor, trafficSevereColor, trafficUnknownColor)
        line.lineJoin = NSExpression(forConstantValue: "round")
        
        return line
    }
    
    func routeCasingStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
        
        let lineCasing = MGLLineStyleLayer(identifier: identifier, source: source)
        
        // Take the default line width and make it wider for the casing
        lineCasing.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)", MBRouteLineWidthByZoomLevel.multiplied(by: 1.5))
        
        lineCasing.lineColor = NSExpression(forConditional: NSPredicate(format: "isAlternateRoute == true"),
                     trueExpression: NSExpression(forConstantValue: routeAlternateCasingColor),
                     falseExpression: NSExpression(forConstantValue: routeCasingColor))
        
        lineCasing.lineCap = NSExpression(forConstantValue: "round")
        lineCasing.lineJoin = NSExpression(forConstantValue: "round")
        
        lineCasing.lineOpacity = NSExpression(forConditional: NSPredicate(format: "isAlternateRoute == true"),
                                            trueExpression: NSExpression(forConstantValue: 1),
                                            falseExpression: NSExpression(forConditional: NSPredicate(format: "isCurrentLeg == true"), trueExpression: NSExpression(forConstantValue: 1), falseExpression: NSExpression(forConstantValue: 0.85)))
        
        return lineCasing
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
    @objc public func localizeLabels() {
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
    
    @objc public func showVoiceInstructionsOnMap(route: Route) {
        guard let style = style else {
            return
        }
        
        var features = [MGLPointFeature]()
        for (legIndex, leg) in route.legs.enumerated() {
            for (stepIndex, step) in leg.steps.enumerated() {
                for instruction in step.instructionsSpokenAlongStep! {
                    let feature = MGLPointFeature()
                    feature.coordinate = Polyline(route.legs[legIndex].steps[stepIndex].coordinates!.reversed()).coordinateFromStart(distance: instruction.distanceAlongStep)!
                    feature.attributes = [ "instruction": instruction.text ]
                    features.append(feature)
                }
            }
        }
        
        let instructionPointSource = MGLShapeCollectionFeature(shapes: features)
        
        if let instructionSource = style.source(withIdentifier: instructionSource) as? MGLShapeSource {
            instructionSource.shape = instructionPointSource
        } else {
            let sourceShape = MGLShapeSource(identifier: instructionSource, shape: instructionPointSource, options: nil)
            style.addSource(sourceShape)
            
            let symbol = MGLSymbolStyleLayer(identifier: instructionLabel, source: sourceShape)
            symbol.text = NSExpression(format: "instruction")
            symbol.textFontSize = NSExpression(forConstantValue: 14)
            symbol.textHaloWidth = NSExpression(forConstantValue: 1)
            symbol.textHaloColor = NSExpression(forConstantValue: UIColor.white)
            symbol.textOpacity = NSExpression(forConstantValue: 0.75)
            symbol.textAnchor = NSExpression(forConstantValue: "bottom-left")
            symbol.textJustification = NSExpression(forConstantValue: "left")
            
            let circle = MGLCircleStyleLayer(identifier: instructionCircle, source: sourceShape)
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
    @objc public func setOverheadCameraView(from userLocation: CLLocationCoordinate2D, along coordinates: [CLLocationCoordinate2D], for padding: UIEdgeInsets) {
        isAnimatingToOverheadMode = true
        
        let line = MGLPolyline(coordinates: coordinates, count: UInt(coordinates.count))
        
        tracksUserCourse = false
        
        // If the user has a short distance left on the route, prevent the camera from zooming all the way.
        // `MGLMapView.setVisibleCoordinateBounds(:edgePadding:animated:)` will go beyond what is convenient for the driver.
        guard line.overlayBounds.ne.distance(to: line.overlayBounds.sw) > NavigationMapViewMinimumDistanceForOverheadZooming else {
            let camera = self.camera
            camera.pitch = 0
            camera.heading = 0
            camera.centerCoordinate = userLocation
            camera.altitude = self.defaultAltitude
            setCamera(camera, withDuration: 1, animationTimingFunction: nil) { [weak self] in
                self?.isAnimatingToOverheadMode = false
            }
            return
        }
        
        let currentCamera = self.camera
        currentCamera.pitch = 0
        currentCamera.heading = 0
        
        let newCamera = camera(currentCamera, fitting: line, edgePadding: padding)
        
        setCamera(newCamera, withDuration: 1, animationTimingFunction: nil) { [weak self] in
            self?.isAnimatingToOverheadMode = false
        }
    }
    
    /**
     Recenters the camera and begins tracking the user's location.
     */
    @objc public func recenterMap() {
        tracksUserCourse = true
        enableFrameByFrameCourseViewTracking(for: 3)
    }
}

