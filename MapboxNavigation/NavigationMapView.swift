import Foundation
import Mapbox
import MapboxDirections
import MapboxCoreNavigation
import Turf

typealias CongestionSegment = ([CLLocationCoordinate2D], CongestionLevel)

let routeLineWidthAtZoomLevels: [Int: MGLStyleValue<NSNumber>] = [
    10: MGLStyleValue(rawValue: 8),
    13: MGLStyleValue(rawValue: 9),
    16: MGLStyleValue(rawValue: 11),
    19: MGLStyleValue(rawValue: 22),
    22: MGLStyleValue(rawValue: 28)
]

let sourceOptions: [MGLShapeSourceOption: Any] = [.maximumZoomLevel: 16]

/**
 `NavigationMapView` is a subclass of `MGLMapView` with convenience functions for adding `Route` lines to a map.
 */
@objc(MBNavigationMapView)
open class NavigationMapView: MGLMapView, UIGestureRecognizerDelegate {
    
    // MARK: Class Constants
    
    /**
     Returns the altitude that the map camera initally defaults to.
     */
    @objc public static let defaultAltitude: CLLocationDistance = 1000.0
    
    /**
     Returns the altitude the map conditionally zooms out to when user is on a motorway, and the maneuver length is sufficently long.
    */
    @objc public static let zoomedOutMotorwayAltitude: CLLocationDistance = 2000.0
    
    /**
     Returns the threshold for what the map considers a "long-enough" maneuver distance to trigger a zoom-out when the user enters a motorway.
     */
    @objc public static let longManeuverDistance: CLLocationDistance = 1000.0
    
    /**
     Maximum distance the user can tap for a selection to be valid when selecting an alternate route.
     */
    @objc public var tapGestureDistanceThreshold: CGFloat = 50
    
    // MARK: Instance Properties
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
    let currentLegAttribute = "isCurrentLeg"
    let instructionSource = "instructionSource"
    let instructionLabel = "instructionLabel"
    let instructionCircle = "instructionCircle"
    let alternateSourceIdentifier = "alternateSource"
    let alternateLayerIdentifier = "alternateLayer"

    let routeLineWidthAtZoomLevels: [Int: MGLStyleValue<NSNumber>] = [
        10: MGLStyleValue(rawValue: 8),
        13: MGLStyleValue(rawValue: 9),
        16: MGLStyleValue(rawValue: 12),
        19: MGLStyleValue(rawValue: 24),
        22: MGLStyleValue(rawValue: 30)
    ]
    
    @objc dynamic public var trafficUnknownColor: UIColor = .trafficUnknown
    @objc dynamic public var trafficLowColor: UIColor = .trafficLow
    @objc dynamic public var trafficModerateColor: UIColor = .trafficModerate
    @objc dynamic public var trafficHeavyColor: UIColor = .trafficHeavy
    @objc dynamic public var trafficSevereColor: UIColor = .trafficSevere
    @objc dynamic public var routeCasingColor: UIColor = .defaultRouteCasing
    @objc dynamic public var routeAlternateColor: UIColor = .defaultAlternateLine
    
    var userLocationForCourseTracking: CLLocation?
    var animatesUserLocation: Bool = false
    var isPluggedIn: Bool = false
    var batteryStateObservation: NSKeyValueObservation?
    var altitude: CLLocationDistance = defaultAltitude
    
    struct FrameIntervalOptions {
        fileprivate static let durationUntilNextManeuver: TimeInterval = 7
        fileprivate static let durationSincePreviousManeuver: TimeInterval = 3
        fileprivate static let defaultFramesPerSecond: Int = 60
        fileprivate static let pluggedInFramesPerSecond: Int = 30
        fileprivate static let decreasedFramesPerSecond: Int = 5
    }
    
    fileprivate var preferredFramesPerSecond: Int = 60 {
        didSet {
            if #available(iOS 10.0, *) {
                displayLink?.preferredFramesPerSecond = preferredFramesPerSecond
            } else {
                displayLink?.frameInterval = FrameIntervalOptions.defaultFramesPerSecond / preferredFramesPerSecond
            }
        }
    }
    private lazy var mapTapGesture = UITapGestureRecognizer(target: self, action: #selector(didRecieveTap(sender:)))
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        let image = UIImage(named: "feedback-map-error", in: .mapboxNavigation, compatibleWith: nil)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .center
        imageView.backgroundColor = .gray
        imageView.frame = bounds
        addSubview(imageView)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        commonInit()
    }
    
    public override init(frame: CGRect, styleURL: URL?) {
        super.init(frame: frame, styleURL: styleURL)
        commonInit()
    }
    
    fileprivate func commonInit() {
        makeGestureRecognizersRespectCourseTracking()
        makeGestureRecognizersUpdateCourseView()
        
        batteryStateObservation = UIDevice.current.observe(\.batteryState) { [weak self] (device, changed) in
            self?.isPluggedIn = device.batteryState == .charging || device.batteryState == .full
        }
        
        resumeNotifications()
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_:)), name: .routeControllerProgressDidChange, object: nil)
        
        let gestures = gestureRecognizers ?? []
        let mapTapGesture = self.mapTapGesture
        mapTapGesture.requireFailure(of: gestures)
        addGestureRecognizer(mapTapGesture)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: nil)
    }
    
    @objc func progressDidChange(_ notification: Notification) {
        guard tracksUserCourse else { return }
        
        let routeProgress = notification.userInfo![RouteControllerProgressDidChangeNotificationProgressKey] as! RouteProgress
        
        let stepProgress = routeProgress.currentLegProgress.currentStepProgress
        let expectedTravelTime = stepProgress.step.expectedTravelTime
        let durationUntilNextManeuver = stepProgress.durationRemaining
        let durationSincePreviousManeuver = expectedTravelTime - durationUntilNextManeuver
        
        guard !isPluggedIn else {
            preferredFramesPerSecond = FrameIntervalOptions.pluggedInFramesPerSecond
            return
        }
    
        if let upcomingStep = routeProgress.currentLegProgress.upComingStep,
            upcomingStep.maneuverDirection == .straightAhead || upcomingStep.maneuverDirection == .slightLeft || upcomingStep.maneuverDirection == .slightRight {
            preferredFramesPerSecond = shouldPositionCourseViewFrameByFrame ? FrameIntervalOptions.defaultFramesPerSecond : FrameIntervalOptions.decreasedFramesPerSecond
        } else if durationUntilNextManeuver > FrameIntervalOptions.durationUntilNextManeuver &&
            durationSincePreviousManeuver > FrameIntervalOptions.durationSincePreviousManeuver {
            preferredFramesPerSecond = shouldPositionCourseViewFrameByFrame ? FrameIntervalOptions.defaultFramesPerSecond : FrameIntervalOptions.decreasedFramesPerSecond
        } else {
            preferredFramesPerSecond = FrameIntervalOptions.pluggedInFramesPerSecond
        }
    }
    
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
    
    open override func anchorPoint(forGesture gesture: UIGestureRecognizer) -> CGPoint {
        if tracksUserCourse {
            return userAnchorPoint
        } else {
            return super.anchorPoint(forGesture: gesture)
        }
    }
    
    deinit {
        suspendNotifications()
    }
    
    @objc func updateCourseView(_ sender: UIGestureRecognizer) {
        preferredFramesPerSecond = FrameIntervalOptions.defaultFramesPerSecond
        
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
            userCourseView?.layer.removeAllAnimations()
            userCourseView?.center = convert(location.coordinate, toPointTo: self)
        }
    }
    
    var shouldPositionCourseViewFrameByFrame = false {
        didSet {
            if shouldPositionCourseViewFrameByFrame {
                preferredFramesPerSecond = FrameIntervalOptions.defaultFramesPerSecond
            }
        }
    }
    
    // Track position on a frame by frame basis. Used for first location update and when resuming tracking mode
    func enableFrameByFrameCourseViewTracking(for duration: TimeInterval) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(disableFrameByFramePositioning), object: nil)
        perform(#selector(disableFrameByFramePositioning), with: nil, afterDelay: duration)
        shouldPositionCourseViewFrameByFrame = true
    }
    
    @objc fileprivate func disableFrameByFramePositioning() {
        shouldPositionCourseViewFrameByFrame = false
    }
    
    var showsRoute: Bool {
        get {
            return style?.layer(withIdentifier: routeLayerIdentifier) != nil
        }
    }
    
    public weak var navigationMapDelegate: NavigationMapViewDelegate?
    weak var courseTrackingDelegate: NavigationMapViewCourseTrackingDelegate!
    
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
    
    @objc private func disableUserCourseTracking() {
        tracksUserCourse = false
    }
    
    @objc public func updateCourseTracking(location: CLLocation?, animated: Bool) {
        animatesUserLocation = animated
        userLocationForCourseTracking = location
        guard let location = location, CLLocationCoordinate2DIsValid(location.coordinate) else {
            return
        }
        
        if tracksUserCourse {
            let point = userAnchorPoint
            let padding = UIEdgeInsets(top: point.y, left: point.x, bottom: bounds.height - point.y, right: bounds.width - point.x)
            let newCamera = MGLMapCamera(lookingAtCenter: location.coordinate, fromDistance: altitude, pitch: 45, heading: location.course)
            let function: CAMediaTimingFunction? = animated ? CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear) : nil
            let duration: TimeInterval = animated ? 1 : 0
            setCamera(newCamera, withDuration: duration, animationTimingFunction: function, edgePadding: padding, completionHandler: nil)
        }
        
        let duration: TimeInterval = animated ? 1 : 0
        UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear, .beginFromCurrentState], animations: {
            self.userCourseView?.center = self.convert(location.coordinate, toPointTo: self)
        }, completion: nil)
        
        if let userCourseView = userCourseView as? UserCourseView {
            if let customTransformation = userCourseView.update?(location: location, pitch: camera.pitch, direction: direction, animated: animated, tracksUserCourse: tracksUserCourse) {
                customTransformation
            } else {
                self.userCourseView?.applyDefaultUserPuckTransformation(location: location, pitch: camera.pitch, direction: direction, animated: animated, tracksUserCourse: tracksUserCourse)
            }
        } else {
            userCourseView?.applyDefaultUserPuckTransformation(location: location, pitch: camera.pitch, direction: direction, animated: animated, tracksUserCourse: tracksUserCourse)
        }
    }
    
    /**
     Center point of the user course view in screen coordinates relative to the map view.
     - seealso: NavigationMapViewDelegate.navigationMapViewUserAnchorPoint(_:)
     */
    var userAnchorPoint: CGPoint {
        if let anchorPoint = navigationMapDelegate?.navigationMapViewUserAnchorPoint?(self), anchorPoint != .zero {
            return anchorPoint
        }
        
        let contentFrame = UIEdgeInsetsInsetRect(bounds, contentInset)
        let courseViewWidth = userCourseView?.frame.width ?? 0
        let courseViewHeight = userCourseView?.frame.height ?? 0
        let edgePadding = UIEdgeInsets(top: 50 + courseViewHeight / 2,
                                       left: 50 + courseViewWidth / 2,
                                       bottom: 50 + courseViewHeight / 2,
                                       right: 50 + courseViewWidth / 2)
        return CGPoint(x: max(min(contentFrame.midX,
                              contentFrame.maxX - edgePadding.right),
                              contentFrame.minX + edgePadding.left),
                       y: max(max(min(contentFrame.minY + contentFrame.height * 0.8,
                                      contentFrame.maxY - edgePadding.bottom),
                                  contentFrame.minY + edgePadding.top),
                              contentFrame.minY + contentFrame.height * 0.5))
    }
    
    /**
     Determines whether the map should follow the user location and rotate when the course changes.
     - seealso: NavigationMapViewCourseTrackingDelegate
     */
    open var tracksUserCourse: Bool = false {
        didSet {
            if tracksUserCourse {
                enableFrameByFrameCourseViewTracking(for: 3)
                altitude = NavigationMapView.defaultAltitude
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
    
    open override func mapViewDidFinishRenderingFrameFullyRendered(_ fullyRendered: Bool) {
        super.mapViewDidFinishRenderingFrameFullyRendered(fullyRendered)
        
        guard shouldPositionCourseViewFrameByFrame else { return }
        guard let location = userLocationForCourseTracking else { return }
        
        userCourseView?.center = convert(location.coordinate, toPointTo: self)
    }
    
    /**
     A `UIView` used to indicate the user’s location and course on the map.
     
     If the view conforms to `UserCourseView`, its `UserCourseView.update(location:pitch:direction:animated:)` method is frequently called to ensure that its visual appearance matches the map’s camera.
     */
    @objc public var userCourseView: UIView? {
        didSet {
            if let userCourseView = userCourseView {
                addSubview(userCourseView)
            }
        }
    }
    
    var routes: [Route]?
    
    // MARK: TapGestureRecognizer
    
    /**
     Fired when NavigationMapView detects a tap not handled elsewhere by other gesture recognizers.
     */
    @objc func didRecieveTap(sender: UITapGestureRecognizer) {
        guard let routes = routes, let tapPoint = sender.point else { return }
        
        let waypointTest = waypoints(on: routes, closeTo: tapPoint) //are there waypoints near the tapped location?
        if let selected = waypointTest?.first { //test passes
            navigationMapDelegate?.navigationMapView?(self, didSelect: selected)
            return
        } else if let routes = self.routes(closeTo: tapPoint) {
            guard let selectedRoute = routes.first else { return }
            navigationMapDelegate?.navigationMapView?(self, didSelect: selectedRoute)
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
    
    // MARK: Feature Addition/Removal
    
    /**
     Adds or updates both the route line and the route line casing
     */
    @objc public func showRoutes(_ routes: [Route], legIndex: Int = 0) {
        guard let style = style else { return }
        guard let activeRoute = routes.first else { return }
        
        let mainPolyline = navigationMapDelegate?.navigationMapView?(self, shapeDescribing: activeRoute) ?? shape(describing: activeRoute, legIndex: legIndex)
        let mainPolylineSimplified = navigationMapDelegate?.navigationMapView?(self, simplifiedShapeDescribing: activeRoute) ?? shape(describingCasing: activeRoute, legIndex: legIndex)
        
        if let source = style.source(withIdentifier: sourceIdentifier) as? MGLShapeSource,
            let sourceSimplified = style.source(withIdentifier: sourceCasingIdentifier) as? MGLShapeSource {
            source.shape = mainPolyline
            sourceSimplified.shape = mainPolylineSimplified
        } else {
            let lineSource = MGLShapeSource(identifier: sourceIdentifier, shape: mainPolyline, options: nil)
            let lineCasingSource = MGLShapeSource(identifier: sourceCasingIdentifier, shape: mainPolylineSimplified, options: nil)
            style.addSource(lineSource)
            style.addSource(lineCasingSource)
            
            let line = navigationMapDelegate?.navigationMapView?(self, routeStyleLayerWithIdentifier: routeLayerIdentifier, source: lineSource) ?? routeStyleLayer(identifier: routeLayerIdentifier, source: lineSource)
            let lineCasing = navigationMapDelegate?.navigationMapView?(self, routeCasingStyleLayerWithIdentifier: routeLayerCasingIdentifier, source: lineCasingSource) ?? routeCasingStyleLayer(identifier: routeLayerCasingIdentifier, source: lineSource)
            
            for layer in style.layers.reversed() {
                if !(layer is MGLSymbolStyleLayer) &&
                    layer.identifier != arrowLayerIdentifier && layer.identifier != arrowSymbolLayerIdentifier && layer.identifier != arrowCasingSymbolLayerIdentifier && layer.identifier != arrowLayerStrokeIdentifier && layer.identifier != waypointCircleIdentifier {
                    style.insertLayer(line, below: layer)
                    style.insertLayer(lineCasing, below: line)
                    break
                }
            }
        }
        guard routes.count > 1 else {
            removeAlternates()
            return
        }
        
        self.routes = routes
        var tmpRoutes = routes
        tmpRoutes.removeFirst()
        guard let alternateRoute = tmpRoutes.first else { return }
        
        let alternatePolyline = MGLPolylineFeature(coordinates: alternateRoute.coordinates!, count: alternateRoute.coordinateCount)
        
        if let source = style.source(withIdentifier: alternateSourceIdentifier) as? MGLShapeSource {
            source.shape = alternatePolyline
        } else {
            let alternateSource = MGLShapeSource(identifier: alternateSourceIdentifier, shape: alternatePolyline, options: nil)
            style.addSource(alternateSource)
            
            let alternateLayer = alternateRouteStyleLayer(identifier: alternateLayerIdentifier, source: alternateSource)
            
            if let layer = style.layer(withIdentifier: routeLayerCasingIdentifier) {
                style.insertLayer(alternateLayer, below: layer)
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
        removeAlternates()
    }
    
    func removeAlternates() {
        guard let style = style else {
            return
        }
        
        if let altSource = style.source(withIdentifier: alternateSourceIdentifier) {
            style.removeSource(altSource)
        }
        
        if let altLayer = style.layer(withIdentifier: alternateLayerIdentifier) {
            style.removeLayer(altLayer)
        }
    }
    
    /**
     Adds the route waypoints to the map given the current leg index. Previous waypoints for completed legs will be omitted.
     */
    @objc public func showWaypoints(_ route: Route, legIndex: Int = 0) {
        guard let style = style else {
            return
        }

        let remainingWaypoints = Array(route.legs.suffix(from: legIndex).map { $0.destination }.dropLast())
        
        let source = navigationMapDelegate?.navigationMapView?(self, shapeFor: remainingWaypoints) ?? shape(for: remainingWaypoints)
        if route.routeOptions.waypoints.count > 2 { //are we on a multipoint route?
            
            routes = [route] //update the model
            if let waypointSource = style.source(withIdentifier: waypointSourceIdentifier) as? MGLShapeSource {
                waypointSource.shape = source
            } else {
                let sourceShape = MGLShapeSource(identifier: waypointSourceIdentifier, shape: source, options: sourceOptions)
                style.addSource(sourceShape)
                
                let circles = navigationMapDelegate?.navigationMapView?(self, waypointStyleLayerWithIdentifier: waypointCircleIdentifier, source: sourceShape) ?? routeWaypointCircleStyleLayer(identifier: waypointCircleIdentifier, source: sourceShape)
                let symbols = navigationMapDelegate?.navigationMapView?(self, waypointSymbolStyleLayerWithIdentifier: waypointSymbolIdentifier, source: sourceShape) ?? routeWaypointSymbolStyleLayer(identifier: waypointSymbolIdentifier, source: sourceShape)
                
                if let arrowLayer = style.layer(withIdentifier: arrowCasingSymbolLayerIdentifier) {
                    style.insertLayer(circles, below: arrowLayer)
                } else {
                    style.addLayer(circles)
                }
                
                style.insertLayer(symbols, above: circles)
            }
        }
        
        if let lastLeg =  route.legs.last {
            removeAnnotations(annotations ?? [])
            let destination = MGLPointAnnotation()
            destination.coordinate = lastLeg.destination.coordinate
            addAnnotation(destination)
        }
    }
    /**
     Removes all waypoints from the map.
     */
    @objc public func removeWaypoints() {
        guard let style = style else { return }
        
        removeAnnotations(annotations ?? [])
        
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
        guard let routeCoordinates = route.coordinates else { return }
        
        guard let style = style else {
            return
        }

        guard let triangleImage = Bundle.mapboxNavigation.image(named: "triangle")?.withRenderingMode(.alwaysTemplate) else { return }
        style.setImage(triangleImage, forName: "triangle-tip-navigation")
        
        guard step.maneuverType != .arrive else { return }
        
        let minimumZoomLevel: Float = 14.5
        
        let shaftLength = max(min(30 * metersPerPoint(atLatitude: maneuverCoordinate.latitude), 30), 10)
        let polyline = Polyline(routeCoordinates)
        let shaftCoordinates = Array(polyline.trimmed(from: maneuverCoordinate, distance: -shaftLength).coordinates.reversed()
            + polyline.trimmed(from: maneuverCoordinate, distance: shaftLength).coordinates.suffix(from: 1))
        
        if shaftCoordinates.count > 1 {
            var shaftStrokeCoordinates = shaftCoordinates
            let shaftStrokePolyline = ArrowStrokePolyline(coordinates: &shaftStrokeCoordinates, count: UInt(shaftStrokeCoordinates.count))
            let shaftDirection = shaftStrokeCoordinates[shaftStrokeCoordinates.count - 2].direction(to: shaftStrokeCoordinates.last!)
            let maneuverArrowStrokePolylines = [shaftStrokePolyline]
            let shaftPolyline = ArrowFillPolyline(coordinates: shaftCoordinates, count: UInt(shaftCoordinates.count))
            
            let arrowShape = MGLShapeCollection(shapes: [shaftPolyline])
            let arrowStrokeShape = MGLShapeCollection(shapes: maneuverArrowStrokePolylines)
            
            let cap = NSValue(mglLineCap: .butt)
            let join = NSValue(mglLineJoin: .round)
            
            let arrowSourceStroke = MGLShapeSource(identifier: arrowSourceStrokeIdentifier, shape: arrowStrokeShape, options: sourceOptions)
            let arrowStroke = MGLLineStyleLayer(identifier: arrowLayerStrokeIdentifier, source: arrowSourceStroke)
            let arrowSource = MGLShapeSource(identifier: arrowSourceIdentifier, shape: arrowShape, options: sourceOptions)
            let arrow = MGLLineStyleLayer(identifier: arrowLayerIdentifier, source: arrowSource)
            
            if let source = style.source(withIdentifier: arrowSourceIdentifier) as? MGLShapeSource {
                source.shape = arrowShape
            } else {
                arrow.minimumZoomLevel = minimumZoomLevel
                arrow.lineCap = MGLStyleValue(rawValue: cap)
                arrow.lineJoin = MGLStyleValue(rawValue: join)
                arrow.lineWidth = MGLStyleValue(interpolationMode: .exponential,
                                                cameraStops: routeLineWidthAtZoomLevels.multiplied(by: 0.70),
                                                options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.5)])
                arrow.lineColor = MGLStyleValue(rawValue: .white)
                
                style.addSource(arrowSource)
                style.addLayer(arrow)
            }
            
            if let source = style.source(withIdentifier: arrowSourceStrokeIdentifier) as? MGLShapeSource {
                source.shape = arrowStrokeShape
            } else {
                
                arrowStroke.minimumZoomLevel = minimumZoomLevel
                arrowStroke.lineCap = MGLStyleValue(rawValue: cap)
                arrowStroke.lineJoin = MGLStyleValue(rawValue: join)
                arrowStroke.lineWidth = MGLStyleValue(interpolationMode: .exponential,
                                                      cameraStops: routeLineWidthAtZoomLevels.multiplied(by: 0.80),
                                                      options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.5)])
                arrowStroke.lineColor = MGLStyleValue(rawValue: .defaultArrowStroke)
                
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
                    arrowSymbolLayer.iconRotation = MGLStyleValue(rawValue: shaftDirection as NSNumber)
                }
                if let arrowSymbolLayerCasing = style.layer(withIdentifier: arrowCasingSymbolLayerIdentifier) as? MGLSymbolStyleLayer {
                    arrowSymbolLayerCasing.iconRotation = MGLStyleValue(rawValue: shaftDirection as NSNumber)
                }
            } else {
                let arrowSymbolLayer = MGLSymbolStyleLayer(identifier: arrowSymbolLayerIdentifier, source: arrowSymbolSource)
                arrowSymbolLayer.minimumZoomLevel = minimumZoomLevel
                arrowSymbolLayer.iconImageName = MGLStyleValue(rawValue: "triangle-tip-navigation")
                arrowSymbolLayer.iconColor = MGLStyleValue(rawValue: .white)
                arrowSymbolLayer.iconRotationAlignment = MGLStyleValue(rawValue: NSValue(mglIconRotationAlignment: .map))
                arrowSymbolLayer.iconRotation = MGLStyleValue(rawValue: shaftDirection as NSNumber)
                arrowSymbolLayer.iconScale = MGLStyleValue(interpolationMode: .exponential,
                                                           cameraStops: routeLineWidthAtZoomLevels.multiplied(by: 0.12),
                                                           options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 0.2)])
                arrowSymbolLayer.iconAllowsOverlap = MGLStyleValue(rawValue: true)
                
                let arrowSymbolLayerCasing = MGLSymbolStyleLayer(identifier: arrowCasingSymbolLayerIdentifier, source: arrowSymbolSource)
                arrowSymbolLayerCasing.minimumZoomLevel = minimumZoomLevel
                arrowSymbolLayerCasing.iconImageName = MGLStyleValue(rawValue: "triangle-tip-navigation")
                arrowSymbolLayerCasing.iconColor = MGLStyleValue(rawValue: .defaultArrowStroke)
                arrowSymbolLayerCasing.iconRotationAlignment = MGLStyleValue(rawValue: NSValue(mglIconRotationAlignment: .map))
                arrowSymbolLayerCasing.iconRotation = MGLStyleValue(rawValue: shaftDirection as NSNumber)
                arrowSymbolLayerCasing.iconScale = MGLStyleValue(interpolationMode: .exponential,
                                                                 cameraStops: routeLineWidthAtZoomLevels.multiplied(by: 0.14),
                                                                 options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 0.2)])
                arrowSymbolLayerCasing.iconAllowsOverlap = MGLStyleValue(rawValue: true)
                
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
    
    func shape(describing route: Route, legIndex: Int?) -> MGLShape? {
        guard let coordinates = route.coordinates else { return nil }
        
        var linesPerLeg: [[MGLPolylineFeature]] = []
        
        for (index, leg) in route.legs.enumerated() {
            // If there is no congestion, don't try and add it
            guard let legCongestion = leg.segmentCongestionLevels else {
                return shape(describingCasing: route, legIndex: legIndex)
            }
            
            guard legCongestion.count + 1 <= coordinates.count else {
                return shape(describingCasing: route, legIndex: legIndex)
            }
            
            // The last coord of the preceding step, is shared with the first coord of the next step.
            // We don't need both.
            var legCoordinates = Array(leg.steps.flatMap {
                $0.coordinates?.suffix(from: 1)
            }.joined())
            
            // We need to add the first coord of the route in.
            if let firstCoord = leg.steps.first?.coordinates?.first {
                legCoordinates.insert(firstCoord, at: 0)
            }
            
            // We're trying to create a sequence that conforms to `((segmentStartCoordinate, segmentEndCoordinate), segmentCongestionLevel)`.
            // This is represents a segment on the route and it's associated congestion level.
            let segments = zip(legCoordinates, legCoordinates.suffix(from: 1)).map { [$0.0, $0.1] }
            let congestionSegments = Array(zip(segments, legCongestion))
            
            // Merge adjacent segments with the same congestion level
            var mergedCongestionSegments = [CongestionSegment]()
            for seg in congestionSegments {
                let coordinates = seg.0
                let congestionLevel = seg.1
                if let last = mergedCongestionSegments.last, last.1 == congestionLevel {
                    mergedCongestionSegments[mergedCongestionSegments.count - 1].0 += coordinates
                } else {
                    mergedCongestionSegments.append(seg)
                }
            }
            
            let lines = mergedCongestionSegments.map { (congestionSegment: CongestionSegment) -> MGLPolylineFeature in
                let polyline = MGLPolylineFeature(coordinates: congestionSegment.0, count: UInt(congestionSegment.0.count))
                polyline.attributes["congestion"] = String(describing: congestionSegment.1)
                if let legIndex = legIndex {
                    polyline.attributes[currentLegAttribute] = index == legIndex
                } else {
                    polyline.attributes[currentLegAttribute] = index == 0
                }
                return polyline
            }
            
            linesPerLeg.append(lines)
        }
        
        return MGLShapeCollectionFeature(shapes: Array(linesPerLeg.joined()))
    }
    
    func shape(describingCasing route: Route, legIndex: Int?) -> MGLShape? {
        var linesPerLeg: [MGLPolylineFeature] = []
        
        for (index, leg) in route.legs.enumerated() {
            let legCoordinates = Array(leg.steps.flatMap {
                $0.coordinates
            }.joined())
            
            let polyline = MGLPolylineFeature(coordinates: legCoordinates, count: UInt(legCoordinates.count))
            if let legIndex = legIndex {
                polyline.attributes[currentLegAttribute] = index == legIndex
            } else {
                polyline.attributes[currentLegAttribute] = index == 0
            }
            linesPerLeg.append(polyline)
        }
        
        return MGLShapeCollectionFeature(shapes: linesPerLeg)
    }
    
    func shape(for waypoints: [Waypoint]) -> MGLShape? {
        var features = [MGLPointFeature]()
        
        for (waypointIndex, waypoint) in waypoints.enumerated() {
            let feature = MGLPointFeature()
            feature.coordinate = waypoint.coordinate
            feature.attributes = [ "name": waypointIndex + 1 ]
            features.append(feature)
        }
        
        return MGLShapeCollectionFeature(shapes: features)
    }
    
    func alternateRouteStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
        
        let lineCasing = MGLLineStyleLayer(identifier: identifier, source: source)
        
        // Take the default line width and make it wider for the casing
        lineCasing.lineWidth = MGLStyleValue(interpolationMode: .exponential,
                                             cameraStops: routeLineWidthAtZoomLevels.multiplied(by: 0.85),
                                             options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.5)])
        
        lineCasing.lineColor = MGLStyleValue(rawValue: routeAlternateColor)
        lineCasing.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        lineCasing.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        lineCasing.lineOpacity = MGLStyleValue(rawValue: 0.9)
        
        return lineCasing
    }
    
    func routeWaypointCircleStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
        let circles = MGLCircleStyleLayer(identifier: waypointCircleIdentifier, source: source)
        circles.circleColor = MGLStyleValue(rawValue: UIColor(red:0.9, green:0.9, blue:0.9, alpha:1.0))
        circles.circleOpacity = MGLStyleValue(interpolationMode: .exponential,
                                              cameraStops: [2: MGLStyleValue(rawValue: 0.5),
                                                            7: MGLStyleValue(rawValue: 1)],
                                              options: nil)
        circles.circleRadius = MGLStyleValue(rawValue: 10)
        circles.circleStrokeColor = MGLStyleValue(rawValue: .black)
        circles.circleStrokeWidth = MGLStyleValue(rawValue: 1)
        
        return circles
    }
    
    func routeWaypointSymbolStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
        let symbol = MGLSymbolStyleLayer(identifier: identifier, source: source)
        
        symbol.text = MGLStyleValue(rawValue: "{name}")
        symbol.textFontSize = MGLStyleValue(rawValue: 10)
        symbol.textHaloWidth = MGLStyleValue(rawValue: 0.25)
        symbol.textHaloColor = MGLStyleValue(rawValue: .black)
        
        return symbol
    }
    
    func routeStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
        
        let line = MGLLineStyleLayer(identifier: identifier, source: source)
        line.lineWidth = MGLStyleValue(interpolationMode: .exponential,
                                       cameraStops: routeLineWidthAtZoomLevels,
                                       options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.5)])
        
        line.lineColor = MGLStyleValue(interpolationMode: .categorical, sourceStops: [
            "unknown": MGLStyleValue(rawValue: trafficUnknownColor),
            "low": MGLStyleValue(rawValue: trafficLowColor),
            "moderate": MGLStyleValue(rawValue: trafficModerateColor),
            "heavy": MGLStyleValue(rawValue: trafficHeavyColor),
            "severe": MGLStyleValue(rawValue: trafficSevereColor)
            ], attributeName: "congestion", options: [.defaultValue: MGLStyleValue(rawValue: trafficUnknownColor)])
        
        line.lineOpacity = MGLStyleValue(interpolationMode: .categorical, sourceStops: [
            true: MGLStyleValue(rawValue: 1),
            false: MGLStyleValue(rawValue: 0)
            ], attributeName: currentLegAttribute, options: nil)
        
        line.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        
        return line
    }
    
    func routeCasingStyleLayer(identifier: String, source: MGLSource) -> MGLStyleLayer {
        
        let lineCasing = MGLLineStyleLayer(identifier: identifier, source: source)
        
        // Take the default line width and make it wider for the casing
        lineCasing.lineWidth = MGLStyleValue(interpolationMode: .exponential,
                                             cameraStops: routeLineWidthAtZoomLevels.multiplied(by: 1.5),
                                             options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.5)])
        
        lineCasing.lineColor = MGLStyleValue(rawValue: routeCasingColor)
        lineCasing.lineCap = MGLStyleValue(rawValue: NSValue(mglLineCap: .round))
        lineCasing.lineJoin = MGLStyleValue(rawValue: NSValue(mglLineJoin: .round))
        
        lineCasing.lineOpacity = MGLStyleValue(interpolationMode: .categorical, sourceStops: [
            true: MGLStyleValue(rawValue: 1),
            false: MGLStyleValue(rawValue: 0.85)
            ], attributeName: currentLegAttribute, options: nil)
        
        return lineCasing
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
            symbol.text = MGLStyleValue(rawValue: "{instruction}")
            symbol.textFontSize = MGLStyleValue(rawValue: 14)
            symbol.textHaloWidth = MGLStyleValue(rawValue: 1)
            symbol.textHaloColor = MGLStyleValue(rawValue: .white)
            symbol.textOpacity = MGLStyleValue(rawValue: 0.75)
            symbol.textAnchor = MGLStyleValue(rawValue: NSValue(mglTextAnchor: .bottomLeft))
            symbol.textJustification = MGLStyleValue(rawValue: NSValue(mglTextJustification: .left))
            
            let circle = MGLCircleStyleLayer(identifier: instructionCircle, source: sourceShape)
            circle.circleRadius = MGLStyleValue(rawValue: 5)
            circle.circleOpacity = MGLStyleValue(rawValue: 0.75)
            circle.circleColor = MGLStyleValue(rawValue: .white)
            
            style.addLayer(circle)
            style.addLayer(symbol)
        }
    }
}

// MARK: Extensions

extension Dictionary where Key == Int, Value: MGLStyleValue<NSNumber> {
    func multiplied(by factor: Double) -> Dictionary {
        var newCameraStop: [Int: MGLStyleValue<NSNumber>] = [:]
        for stop in routeLineWidthAtZoomLevels {
            let f = stop.value as! MGLConstantStyleValue
            let newValue =  f.rawValue.doubleValue * factor
            newCameraStop[stop.key] = MGLStyleValue<NSNumber>(rawValue: NSNumber(value:newValue))
        }
        return newCameraStop as! Dictionary<Key, Value>
    }
}

/**
 The `NavigationMapViewDelegate` provides methods for configuring the NavigationMapView, as well as responding to events triggered by the NavigationMapView.
 */
@objc(MBNavigationMapViewDelegate)
public protocol NavigationMapViewDelegate: class {
    /**
     Asks the receiver to return an MGLStyleLayer for routes, given an identifier and source.
     This method is invoked when the map view loads and any time routes are added.
     - parameter mapView: The NavigationMapView.
     - parameter identifier: The style identifier.
     - parameter source: The Layer source containing the route data that this method would style.
     - returns: An MGLStyleLayer that the map applies to all routes.
     */
    @objc optional func navigationMapView(_ mapView: NavigationMapView, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Asks the receiver to return an MGLStyleLayer for waypoints, given an identifier and source.
     This method is invoked when the map view loads and any time waypoints are added.
     - parameter mapView: The NavigationMapView.
     - parameter identifier: The style identifier.
     - parameter source: The Layer source containing the waypoint data that this method would style.
     - returns: An MGLStyleLayer that the map applies to all waypoints.
     */
    @objc optional func navigationMapView(_ mapView: NavigationMapView, waypointStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Asks the receiver to return an MGLStyleLayer for waypoint symbols, given an identifier and source.
     This method is invoked when the map view loads and any time waypoints are added.
     - parameter mapView: The NavigationMapView.
     - parameter identifier: The style identifier.
     - parameter source: The Layer source containing the waypoint data that this method would style.
     - returns: An MGLStyleLayer that the map applies to all waypoint symbols.
     */
    @objc optional func navigationMapView(_ mapView: NavigationMapView, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Asks the receiver to return an MGLStyleLayer for route casings, given an identifier and source.
     This method is invoked when the map view loads and anytime routes are added.
     - note: Specify a casing to ensure good contrast between the route line and the underlying map layers.
     - parameter mapView: The NavigationMapView.
     - parameter identifier: The style identifier.
     - parameter source: The Layer source containing the route data that this method would style.
     - returns: An MGLStyleLayer that the map applies to the route.
     */
    @objc optional func navigationMapView(_ mapView: NavigationMapView, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Tells the receiver that the user has selected a route by interacting with the map view.
     - parameter mapView: The NavigationMapView.
     - parameter route: The route that was selected.
    */
    @objc(navigationMapView:didSelectRoute:)
    optional func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route)
    
    /**
     Tells the receiver that a waypoint was selected.
     - parameter mapView: The NavigationMapView.
     - parameter waypoint: The waypoint that was selected.
     */
    @objc(navigationMapView:didSelectWaypoint:)
    optional func navigationMapView(_ mapView: NavigationMapView, didSelect waypoint: Waypoint)
    
    /**
     Asks the receiver to return an MGLShape that describes the geometry of the route.
     - note: The returned value represents the route in full detail. For example, individual `MGLPolyline` objects in an `MGLShapeCollectionFeature` object can represent traffic congestion segments. For improved performance, you should also implement `navigationMapView(_:simplifiedShapeDescribing:)`, which defines the overall route as a single feature.
     - parameter mapView: The NavigationMapView.
     - parameter route: The route that the sender is asking about.
     - returns: Optionally, a `MGLShape` that defines the shape of the route, or `nil` to use default behavior.
     */
    @objc(navigationMapView:shapeDescribingRoute:)
    optional func navigationMapView(_ mapView: NavigationMapView, shapeDescribing route: Route) -> MGLShape?
    
    /**
     Asks the receiver to return an MGLShape that describes the geometry of the route at lower zoomlevels.
     - note: The returned value represents the simplfied route. It is designed to be used with `navigationMapView(_:shapeDescribing:), and if used without its parent method, can cause unexpected behavior.
     - parameter mapView: The NavigationMapView.
     - parameter route: The route that the sender is asking about.
     - returns: Optionally, a `MGLShape` that defines the shape of the route at lower zoomlevels, or `nil` to use default behavior.
     */
    @objc(navigationMapView:simplifiedShapeDescribingRoute:)
    optional func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeDescribing route: Route) -> MGLShape?
    
    /**
     Asks the receiver to return an MGLShape that describes the geometry of the waypoint.
     - parameter mapView: The NavigationMapView.
     - parameter waypoint: The waypoint that the sender is asking about.
     - returns: Optionally, a `MGLShape` that defines the shape of the waypoint, or `nil` to use default behavior.
     */
    @objc(navigationMapView:shapeDescribingWaypoints:)
    optional func navigationMapView(_ mapView: NavigationMapView, shapeFor waypoints: [Waypoint]) -> MGLShape?
    
    /**
     Asks the receiver to return a CGPoint to serve as the anchor for the user icon.
     - important: The return value should be returned in the normal UIKit coordinate-space, NOT CoreAnimation's unit coordinate-space.
     - parameter mapView: The NavigationMapView.
     - returns: A CGPoint (in regular coordinate-space) that represents the point on-screen where the user location icon should be drawn.
    */
    @objc(navigationMapViewUserAnchorPoint:)
    optional func navigationMapViewUserAnchorPoint(_ mapView: NavigationMapView) -> CGPoint
}

// MARK: NavigationMapViewCourseTrackingDelegate
/**
 The `NavigationMapViewCourseTrackingDelegate` provides methods for responding to the `NavigationMapView` starting or stopping course tracking.
 */
protocol NavigationMapViewCourseTrackingDelegate: class {
    /**
     Tells the receiver that the map is now tracking the user course.
     - seealso: NavigationMapView.tracksUserCourse
     - parameter mapView: The NavigationMapView.
     */
    func navigationMapViewDidStartTrackingCourse(_ mapView: NavigationMapView)
    
    /**
     Tells the receiver that `tracksUserCourse` was set to false, signifying that the map is no longer tracking the user course.
     - seealso: NavigationMapView.tracksUserCourse
     - parameter mapView: The NavigationMapView.
     */
    func navigationMapViewDidStopTrackingCourse(_ mapView: NavigationMapView)
}
