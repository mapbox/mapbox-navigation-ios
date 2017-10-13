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

/**
 `NavigationMapView` is a subclass of `MGLMapView` with convenience functions for adding `Route` lines to a map.
 */
@objc(MBNavigationMapView)
open class NavigationMapView: MGLMapView {
    
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

    let routeLineWidthAtZoomLevels: [Int: MGLStyleValue<NSNumber>] = [
        10: MGLStyleValue(rawValue: 8),
        13: MGLStyleValue(rawValue: 9),
        16: MGLStyleValue(rawValue: 12),
        19: MGLStyleValue(rawValue: 24),
        22: MGLStyleValue(rawValue: 30)
    ]
    
    dynamic public var trafficUnknownColor: UIColor = .trafficUnknown
    dynamic public var trafficLowColor: UIColor = .trafficLow
    dynamic public var trafficModerateColor: UIColor = .trafficModerate
    dynamic public var trafficHeavyColor: UIColor = .trafficHeavy
    dynamic public var trafficSevereColor: UIColor = .trafficSevere
    dynamic public var routeCasingColor: UIColor = .defaultRouteCasing
    
    var userLocationForCourseTracking: CLLocation?
    var animatesUserLocation: Bool = false
    var isPluggedIn: Bool = false
    var altitude: CLLocationDistance = 1000
    let defaultAltitude: CLLocationDistance = 1000
    
    struct FrameIntervalOptions {
        fileprivate static let durationUntilNextManeuver: TimeInterval = 30
        fileprivate static let durationSincePreviousManeuver: TimeInterval = 10
        fileprivate static let decreasedFrameInterval: Int = 12
        fileprivate static let defaultFrameInterval: Int = 1
    }
    
    fileprivate var frameInterval: Int {
        get {
            return displayLink?.frameInterval ?? FrameIntervalOptions.defaultFrameInterval
        }
        set {
            if displayLink?.frameInterval != newValue {
                displayLink?.frameInterval = newValue
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        makeGestureRecognizersRespectCourseTracking()
        makeGestureRecognizersUpdateCourseView()
        
        resumeNotifications()
    }
    
    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        makeGestureRecognizersRespectCourseTracking()
        makeGestureRecognizersUpdateCourseView()
        
        resumeNotifications()
    }
    
    func resumeNotifications() {
        UIDevice.current.addObserver(self, forKeyPath: "batteryState", options: [.initial, .new], context: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_:)), name: RouteControllerProgressDidChange, object: nil)
        
    }
    
    func suspendNotifications() {
        UIDevice.current.removeObserver(self, forKeyPath: "batteryState")
        NotificationCenter.default.removeObserver(self, name: RouteControllerProgressDidChange, object: nil)
    }
    
    func progressDidChange(_ notification: Notification) {
        guard tracksUserCourse else { return }
        
        let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
        
        let stepProgress = routeProgress.currentLegProgress.currentStepProgress
        let expectedTravelTime = stepProgress.step.expectedTravelTime
        let durationUntilNextManeuver = stepProgress.durationRemaining
        let durationSincePreviousManeuver = expectedTravelTime - durationUntilNextManeuver
        
        if !isPluggedIn,
            durationUntilNextManeuver > FrameIntervalOptions.durationUntilNextManeuver,
            durationSincePreviousManeuver > FrameIntervalOptions.durationSincePreviousManeuver {
            frameInterval = FrameIntervalOptions.decreasedFrameInterval
        } else {
            frameInterval = FrameIntervalOptions.defaultFrameInterval
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
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "batteryState" {
            let batteryState = UIDevice.current.batteryState
            isPluggedIn = batteryState == .charging || batteryState == .full
        }
    }
    
    func updateCourseView(_ sender: UIGestureRecognizer) {
        frameInterval = FrameIntervalOptions.defaultFrameInterval
        
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
    
    var shouldPositionCourseViewFrameByFrame = false
    
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
    
    @objc func disableUserCourseTracking() {
        tracksUserCourse = false
    }
    
    public func updateCourseTracking(location: CLLocation?, animated: Bool) {
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
            userCourseView.update(location: location, pitch: camera.pitch, direction: direction, animated: animated, tracksUserCourse: tracksUserCourse)
        }
    }
    
    /**
     Center point of the user course view in screen coordinates relative to the map view.
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
    
    var tracksUserCourse: Bool = false {
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
    public var userCourseView: UIView? {
        didSet {
            if let userCourseView = userCourseView {
                addSubview(userCourseView)
            }
        }
    }
    
    /**
     Adds or updates both the route line and the route line casing
     */
    public func showRoute(_ route: Route, legIndex: Int? = nil) {
        guard let style = style else {
            return
        }
        
        let polyline = navigationMapDelegate?.navigationMapView?(self, shapeDescribing: route) ?? shape(describing: route, legIndex: legIndex)
        let polylineSimplified = navigationMapDelegate?.navigationMapView?(self, simplifiedShapeDescribing: route) ?? shape(describingCasing: route, legIndex: legIndex)
        
        if let source = style.source(withIdentifier: sourceIdentifier) as? MGLShapeSource,
            let sourceSimplified = style.source(withIdentifier: sourceCasingIdentifier) as? MGLShapeSource {
            source.shape = polyline
            sourceSimplified.shape = polylineSimplified
        } else {
            let lineSource = MGLShapeSource(identifier: sourceIdentifier, shape: polyline, options: nil)
            let lineCasingSource = MGLShapeSource(identifier: sourceCasingIdentifier, shape: polylineSimplified, options: nil)
            style.addSource(lineSource)
            style.addSource(lineCasingSource)
            
            let line = navigationMapDelegate?.navigationMapView?(self, routeStyleLayerWithIdentifier: routeLayerIdentifier, source: lineSource) ?? routeStyleLayer(identifier: routeLayerIdentifier, source: lineSource)
            let lineCasing = navigationMapDelegate?.navigationMapView?(self, routeCasingStyleLayerWithIdentifier: routeLayerCasingIdentifier, source: lineCasingSource) ?? routeCasingStyleLayer(identifier: routeLayerCasingIdentifier, source: lineSource)
            
            for layer in style.layers.reversed() {
                if !(layer is MGLSymbolStyleLayer) &&
                    layer.identifier != arrowLayerIdentifier && layer.identifier != arrowSymbolLayerIdentifier && layer.identifier != arrowCasingSymbolLayerIdentifier && layer.identifier != arrowLayerStrokeIdentifier && layer.identifier != waypointCircleIdentifier {
                    style.insertLayer(line, below: layer)
                    style.insertLayer(lineCasing, below: line)
                    return
                }
            }
        }
    }
    
    /**
     Removes route line and route line casing from map
     */
    public func removeRoute() {
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
    public func showWaypoints(_ route: Route, legIndex: Int = 0) {
        guard let style = style else {
            return
        }
        
        let remainingWaypoints = Array(route.legs.suffix(from: legIndex).map { $0.destination }.dropLast())
        
        let source = navigationMapDelegate?.navigationMapView?(self, shapeFor: remainingWaypoints) ?? shape(for: remainingWaypoints)
        
        if let waypointSource = style.source(withIdentifier: waypointSourceIdentifier) as? MGLShapeSource {
            waypointSource.shape = source
        } else {
            let sourceShape = MGLShapeSource(identifier: waypointSourceIdentifier, shape: source, options: nil)
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
    public func removeWaypoints() {
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
    
    func shape(describing route: Route, legIndex: Int?) -> MGLShape? {
        guard let coordinates = route.coordinates else { return nil }
        
        var linesPerLeg: [[MGLPolylineFeature]] = []
        var previousLegCongestionIndex = 0
        
        for (index, leg) in route.legs.enumerated() {
            // If there is no congestion, don't try and add it
            guard let legCongestion = leg.segmentCongestionLevels else {
                return shape(describingCasing: route, legIndex: legIndex)
            }
            
            guard legCongestion.count + 1 <= coordinates.count else {
                return shape(describingCasing: route, legIndex: legIndex)
            }
            
            let coordsForLeg = coordinates[previousLegCongestionIndex..<previousLegCongestionIndex + legCongestion.count + 1]
            let destination = coordinates.suffix(from: previousLegCongestionIndex + 1)
            let segment = zip(coordsForLeg, destination).map { [$0.0, $0.1] }
            let congestionSegments = Array(zip(segment, legCongestion))
            
            previousLegCongestionIndex = legCongestion.count
            
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
                                             cameraStops: routeLineWidthAtZoomLevels.muliplied(by: 1.5),
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
    
    /**
     Shows the step arrow given the current `RouteProgress`.
     */
    public func addArrow(route: Route, legIndex: Int, stepIndex: Int) {
        guard route.legs.indices.contains(legIndex),
            route.legs[legIndex].steps.indices.contains(stepIndex) else { return }
        
        let step = route.legs[legIndex].steps[stepIndex]
        let maneuverCoordinate = step.maneuverLocation
        guard let routeCoordinates = route.coordinates else { return }
        
        guard let style = style else {
            return
        }
        
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
            
            let arrowSourceStroke = MGLShapeSource(identifier: arrowSourceStrokeIdentifier, shape: arrowStrokeShape, options: nil)
            let arrowStroke = MGLLineStyleLayer(identifier: arrowLayerStrokeIdentifier, source: arrowSourceStroke)
            let arrowSource = MGLShapeSource(identifier: arrowSourceIdentifier, shape: arrowShape, options: nil)
            let arrow = MGLLineStyleLayer(identifier: arrowLayerIdentifier, source: arrowSource)
            
            if let source = style.source(withIdentifier: arrowSourceIdentifier) as? MGLShapeSource {
                source.shape = arrowShape
            } else {
                arrow.minimumZoomLevel = minimumZoomLevel
                arrow.lineCap = MGLStyleValue(rawValue: cap)
                arrow.lineJoin = MGLStyleValue(rawValue: join)
                arrow.lineWidth = MGLStyleValue(interpolationMode: .exponential,
                                                     cameraStops: routeLineWidthAtZoomLevels.muliplied(by: 0.70),
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
                                                cameraStops: routeLineWidthAtZoomLevels.muliplied(by: 0.80),
                                                options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 1.5)])
                arrowStroke.lineColor = MGLStyleValue(rawValue: .defaultArrowStroke)
                
                style.addSource(arrowSourceStroke)
                style.insertLayer(arrowStroke, below: arrow)
            }
            
            // Arrow symbol
            let point = MGLPointFeature()
            point.coordinate = shaftStrokeCoordinates.last!
            let arrowSymbolSource = MGLShapeSource(identifier: arrowSymbolSourceIdentifier, features: [point], options: nil)
            
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
                                                     cameraStops: routeLineWidthAtZoomLevels.muliplied(by: 0.12),
                                                     options: [.defaultValue : MGLConstantStyleValue<NSNumber>(rawValue: 0.2)])
                arrowSymbolLayer.iconAllowsOverlap = MGLStyleValue(rawValue: true)
                
                
                let arrowSymbolLayerCasing = MGLSymbolStyleLayer(identifier: arrowCasingSymbolLayerIdentifier, source: arrowSymbolSource)
                arrowSymbolLayerCasing.minimumZoomLevel = minimumZoomLevel
                arrowSymbolLayerCasing.iconImageName = MGLStyleValue(rawValue: "triangle-tip-navigation")
                arrowSymbolLayerCasing.iconColor = MGLStyleValue(rawValue: .defaultArrowStroke)
                arrowSymbolLayerCasing.iconRotationAlignment = MGLStyleValue(rawValue: NSValue(mglIconRotationAlignment: .map))
                arrowSymbolLayerCasing.iconRotation = MGLStyleValue(rawValue: shaftDirection as NSNumber)
                arrowSymbolLayerCasing.iconScale = MGLStyleValue(interpolationMode: .exponential,
                                                           cameraStops: routeLineWidthAtZoomLevels.muliplied(by: 0.14),
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
    public func removeArrow() {
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
}

extension Dictionary where Key == Int, Value: MGLStyleValue<NSNumber> {
    func muliplied(by factor: Double) -> Dictionary {
        var newCameraStop:[Int:MGLStyleValue<NSNumber>] = [:]
        for stop in routeLineWidthAtZoomLevels {
            let f = stop.value as! MGLConstantStyleValue
            let newValue =  f.rawValue.doubleValue * factor
            newCameraStop[stop.key] = MGLStyleValue<NSNumber>(rawValue: NSNumber(value:newValue))
        }
        return newCameraStop as! Dictionary<Key, Value>
    }
}

@objc
public protocol NavigationMapViewDelegate: class  {
    @objc optional func navigationMapView(_ mapView: NavigationMapView, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    @objc optional func navigationMapView(_ mapView: NavigationMapView, waypointStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    @objc optional func navigationMapView(_ mapView: NavigationMapView, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    @objc optional func navigationMapView(_ mapView: NavigationMapView, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    @objc(navigationMapView:shapeDescribingRoute:)
    optional func navigationMapView(_ mapView: NavigationMapView, shapeDescribing route: Route) -> MGLShape?
    
    @objc(navigationMapView:simplifiedShapeDescribingRoute:)
    optional func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeDescribing route: Route) -> MGLShape?
    
    @objc(navigationMapView:shapeDescribingWaypoints:)
    optional func navigationMapView(_ mapView: NavigationMapView, shapeFor waypoints: [Waypoint]) -> MGLShape?
    
    @objc(navigationMapViewUserAnchorPoint:)
    optional func navigationMapViewUserAnchorPoint(_ mapView: NavigationMapView) -> CGPoint
}

protocol NavigationMapViewCourseTrackingDelegate: class {
    func navigationMapViewDidStartTrackingCourse(_ mapView: NavigationMapView)
    func navigationMapViewDidStopTrackingCourse(_ mapView: NavigationMapView)
}
