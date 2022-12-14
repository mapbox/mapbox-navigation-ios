import UIKit
import CoreLocation
import MapboxMaps
import MapboxCoreMaps
import MapboxDirections
import MapboxCoreNavigation
import Turf

/**
 `NavigationMapView` is a subclass of `UIView`, which draws `MapView` on its surface and provides
 convenience functions for adding `Route` lines to a map.
 */
open class NavigationMapView: UIView {
    
    // :nodoc:
    public typealias AnimationCompletionHandler = (_ animatingPosition: UIViewAnimatingPosition) -> Void
    
    // MARK: Traffic and Congestion Visualization
    
    /**
     A collection of street road classes for which a congestion level substitution should occur.
     
     For any street road class included in the `roadClassesWithOverriddenCongestionLevels`,
     all route segments with an `CongestionLevel.unknown` traffic congestion level and
     a matching `MapboxDirections.MapboxStreetsRoadClass`.
     will be replaced with the `CongestionLevel.low` congestion level.
     */
    public var roadClassesWithOverriddenCongestionLevels: Set<MapboxStreetsRoadClass>? = nil
    
    /**
     Controls whether to show congestion levels on alternative route lines. Defaults to `false`.
     
     If `true` and there're multiple routes to choose, the alternative route lines would display
     the congestion levels at different colors, similar to the main route. To customize the
     congestion colors that represent different congestion levels, override the `alternativeTrafficUnknownColor`,
     `alternativeTrafficLowColor`, `alternativeTrafficModerateColor`, `alternativeTrafficHeavyColor`,
     `alternativeTrafficSevereColor` property for the `NavigationMapView.appearance()`.
     */
    public var showsCongestionForAlternativeRoutes: Bool = false
    
    /**
     Controls wheter to show restricted portions of a route line.
     
     Restricted areas are drawn using `routeRestrictedAreaColor` which is customizable.
     */
    public var showsRestrictedAreasOnRoute: Bool = false {
        didSet {
            updateRouteLineWithRouteLineTracksTraversal()
        }
    }

    /**
     The tolerance value used for configuring the underlying map source of route line, maneuver arrow and restricted areas.

     Controls the level of simplification by specifying the maximum allowed distance between the original line point and the simplified point. A higher tolerance value results in higher simplification and faster performance.
     Changing the property will affect only newly added sources.
     */
    public var overlaySimplificationTolerance: Double = 0.375
    
    /**
     Controls whether to show fading gradient color on route lines between two different congestion
     level segments. Defaults to `false`.
     
     If `true`, the congestion level change between two segments in the route line will be shown as
     fading gradient color instead of abrupt and steep change.
     */
    public var crossfadesCongestionSegments: Bool = false {
        didSet {
            updateRouteLineWithRouteLineTracksTraversal()
        }
    }
    
    /**
     Controls whether the main route style layer and its casing disappears as the user location puck travels over it. Defaults to `false`.
     
     Used in standalone `NavigationMapView` during active navigation. If using `NavigationViewController` and `CarPlayNavigationViewController`
     for active navigation, update `NavigationViewController.routeLineTracksTraversal` and `CarPlayNavigationViewController.routeLineTracksTraversal` instead.
     
     If `true`, the part of the route that has been traversed will be
     rendered with full transparency, to give the illusion of a
     disappearing route. To customize the color that appears on the
     traversed section of a route, override the `traversedRouteColor` property
     for the `NavigationMapView.appearance()`. If `false`, the whole route will be shown without traversed
     part disappearing effect.
     
     To update the route line during active navigation when `RouteProgress` changes, add observer for `Notification.Name.routeControllerProgressDidChange` and
     call `NavigationMapView.updateRouteLine(routeProgress:coordinate:shouldRedraw:)` with `shouldRedraw` as `false`.
     
     To update the route line during active navigation when route refresh or rerouting happens, add observers for `Notification.Name.routeControllerDidRefreshRoute` and
     `Notification.Name.routeControllerDidReroute`. And call `NavigationMapView.updateRouteLine(routeProgress:coordinate:shouldRedraw:)`
     with `shouldRedraw` as `true`.
     */
    public var routeLineTracksTraversal: Bool = false {
        didSet {
            updateRouteLineWithRouteLineTracksTraversal()
        }
    }
    
    /**
     Location manager that is used to track accuracy and status authorization changes.
     */
    let locationManager = CLLocationManager()
    
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
    @objc dynamic public var routeRestrictedAreaColor: UIColor = .defaultRouteRestrictedAreaColor
    
    // MARK: Customizing and Displaying the Route Line(s)
    
    /**
     Maximum distance (in screen points) the user can tap for a selection to be valid when selecting
     an alternate route.
     */
    public var tapGestureDistanceThreshold: CGFloat = 50
    
    /**
     Gesture recognizer, that is used to detect taps on waypoints and routes that are currently
     present on the map. Enabled by default.
     */
    public private(set) var mapViewTapGestureRecognizer: UITapGestureRecognizer!
    
    @objc dynamic public var routeCasingColor: UIColor = .defaultRouteCasing
    @objc dynamic public var routeAlternateColor: UIColor = .defaultAlternateLine
    @objc dynamic public var routeAlternateCasingColor: UIColor = .defaultAlternateLineCasing
    @objc dynamic public var traversedRouteColor: UIColor = .defaultTraversedRouteColor
    @objc dynamic public var maneuverArrowColor: UIColor = .defaultManeuverArrow
    @objc dynamic public var maneuverArrowStrokeColor: UIColor = .defaultManeuverArrowStroke
    
    /**
     A pending user location coordinate, which is used to calculate the bottleneck distance for
     vanishing route line when a location update comes in.
     */
    var pendingCoordinateForRouteLine: CLLocationCoordinate2D?
    
    /**
     A custom route line layer position.
     */
    var customRouteLineLayerPosition: MapboxMaps.LayerPosition? = nil
    
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
    
    func updateRouteLineWithRouteLineTracksTraversal() {
        if let routes = self.routes {
            let offset = fractionTraveled
            show(routes, layerPosition: customRouteLineLayerPosition, legIndex: currentLegIndex)
            if let route = routes.first, routeLineTracksTraversal {
                updateRouteLineOffset(along: route, offset: offset)
            }
        }
    }
    
    /**
     Visualizes the given routes and their waypoints and zooms the map to fit, removing any
     existing routes and waypoints from the map.
     
     Each route is visualized as a line. Each line is color-coded by traffic congestion, if congestion
     levels are present and `NavigationMapView.crossfadesCongestionSegments` is set to `true`.
     
     Waypoints along the route are visualized as markers. Implement `NavigationMapViewDelegate` methods
     to customize the appearance of the lines and markers representing the routes and waypoints.
     
     To only visualize the routes and not the waypoints, or to have more control over the camera,
     use the `show(_:legIndex:)` method.
     
     - parameter routes: The routes to visualize in order of priority. The first route is displayed
     as if it is currently selected or active, while the remaining routes are displayed as if they
     are currently deselected or inactive. The order of routes in this array may differ from
     the order in the original `RouteResponse`, for example in response to a user selecting a preferred
     route.
     - parameter routesPresentationStyle: Route lines presentation style. By default the map will be
     updated to fit all routes.
     - parameter legIndex: The zero-based index of the currently active leg along the active route.
     The active leg is highlighted more prominently than inactive legs.
     - parameter animated: `true` to asynchronously animate the camera, or `false` to instantaneously
     zoom and pan the map.
     - parameter duration: Duration of the animation (in seconds). In case if `animated` parameter
     is set to `false` this value is ignored.
     - parameter completion: A completion handler that will be called once routes presentation completes.
     */
    public func showcase(_ routes: [Route],
                         routesPresentationStyle: RoutesPresentationStyle = .all(),
                         legIndex: Int? = nil,
                         animated: Bool = false,
                         duration: TimeInterval = 1.0,
                         completion: AnimationCompletionHandler? = nil) {
        guard let activeRoute = routes.first,
              let coordinates = activeRoute.shape?.coordinates,
              !coordinates.isEmpty else { return }
        
        removeArrow()
        removeRoutes()
        removeWaypoints()
        removeContinuousAlternativesRoutes()
        
        switch routesPresentationStyle {
        case .single:
            show([activeRoute], layerPosition: customRouteLineLayerPosition, legIndex: legIndex)
        case .all:
            show(routes, layerPosition: customRouteLineLayerPosition, legIndex: legIndex)
        }
        
        showWaypoints(on: activeRoute)
        
        navigationCamera.stop()
        fitCamera(to: routes,
                  routesPresentationStyle: routesPresentationStyle,
                  animated: animated,
                  duration: duration,
                  completion: completion)
    }
    
    /**
     Visualizes the given routes and it's alternatives, removing any existing from the map.
     
     Each route is visualized as a line. Each line is color-coded by traffic congestion, if congestion
     levels are present and `NavigationMapView.crossfadesCongestionSegments` is set to `true`.
     
     Waypoints along the route are visualized as markers. Implement `NavigationMapViewDelegate` methods
     to customize the appearance of the lines and markers representing the routes and waypoints.
     
     To only visualize the routes and not the waypoints, or to have more control over the camera,
     use the `show(_:legIndex:)` method.
     
     - parameter routeResponse: `IndexedRouteResponse` containing routes to visualize. The selected route by `routeIndex` is considered primary, while the remaining routes are displayed as if they are currently deselected or inactive.
     - parameter routesPresentationStyle: Route lines presentation style. By default the map will be
     updated to fit all routes.
     - parameter legIndex: The zero-based index of the currently active leg along the active route.
     The active leg is highlighted more prominently than inactive legs.
     - parameter animated: `true` to asynchronously animate the camera, or `false` to instantaneously
     zoom and pan the map.
     - parameter duration: Duration of the animation (in seconds). In case if `animated` parameter
     is set to `false` this value is ignored.
     - parameter completion: A completion handler that will be called once routes presentation completes.
     */
    public func showcase(_ routeResponse: IndexedRouteResponse,
                         routesPresentationStyle: RoutesPresentationStyle = .all(),
                         legIndex: Int? = nil,
                         animated: Bool = false,
                         duration: TimeInterval = 1.0,
                         completion: AnimationCompletionHandler? = nil) {
        guard let routes = routeResponse.routeResponse.routes,
              let activeRoute = routeResponse.currentRoute,
              let coordinates = activeRoute.shape?.coordinates,
              !coordinates.isEmpty else { return }
        
        removeArrow()
        removeRoutes()
        removeWaypoints()
        removeContinuousAlternativesRoutes()
        
        switch routesPresentationStyle {
        case .single:
            show([activeRoute], layerPosition: customRouteLineLayerPosition, legIndex: legIndex)
        case .all:
            show(routeResponse, layerPosition: customRouteLineLayerPosition, legIndex: legIndex)
        }
        
        showWaypoints(on: activeRoute)
        
        navigationCamera.stop()
        fitCamera(to: routes,
                  routesPresentationStyle: routesPresentationStyle,
                  animated: animated,
                  duration: duration,
                  completion: completion)
    }
    
    /**
     Visualizes the given routes, removing any existing routes from the map.
     
     Each route is visualized as a line. Each line is color-coded by traffic congestion, if congestion
     levels are present. Implement `NavigationMapViewDelegate` methods to customize the appearance of
     the lines representing the routes. To also visualize waypoints and zoom the map to fit,
     use the `showcase(_:animated:)` method.
     
     To undo the effects of this method, use the `removeRoutes()` method.
     
     - parameter routes: The routes to visualize in order of priority. The first route is displayed
     as if it is currently selected or active, while the remaining routes are displayed as if they
     are currently deselected or inactive. The order of routes in this array may differ from the
     order in the original `RouteResponse`, for example in response to a user selecting a preferred
     route.
     - parameter layerPosition: Position of the first route layer. Remaining routes and their casings
     are always displayed below the first and all other subsequent route layers. Defaults to `nil`.
     If layer position is set to `nil`, the route layer appears below the bottommost symbol layer.
     - parameter legIndex: The zero-based index of the currently active leg along the active route.
     The active leg is highlighted more prominently than inactive legs.
     */
    public func show(_ routes: [Route],
                     layerPosition: MapboxMaps.LayerPosition? = nil,
                     legIndex: Int? = nil) {
        removeRoutes()
        removeContinuousAlternativesRoutesLayers()
        
        self.routes = routes
        currentLegIndex = legIndex
        customRouteLineLayerPosition = layerPosition
        
        applyRoutesDisplay(layerPosition: layerPosition)
    }
    
    /**
     Visualizes the given routes and it's alternatives, removing any existing from the map.
     
     Each route is visualized as a line. Each line is color-coded by traffic congestion, if congestion
     levels are present. Implement `NavigationMapViewDelegate` methods to customize the appearance of
     the lines representing the routes. To also visualize waypoints and zoom the map to fit,
     use the `showcase(_:animated:)` method.
     
     To undo the effects of this method, use `removeRoutes()` and `removeContinuousAlternativesRoutes()` methods.
     
     - parameter routeResponse: `IndexedRouteResponse` containing routes to visualize. The selected route by `routeIndex` is considered primary, while the remaining routes are displayed as if they are currently deselected or inactive.
     - parameter layerPosition: Position of the first route layer. Remaining routes and their casings
     are always displayed below the first and all other subsequent route layers. Defaults to `nil`.
     If layer position is set to `nil`, the route layer appears below the bottommost symbol layer.
     - parameter legIndex: The zero-based index of the currently active leg along the primary route.
     The active leg is highlighted more prominently than inactive legs.
     */
    public func show(_ routeResponse: IndexedRouteResponse,
                     layerPosition: MapboxMaps.LayerPosition? = nil,
                     legIndex: Int? = nil) {
        guard let mainRoute = routeResponse.currentRoute else {
            return
        }
        
        removeRoutes()
        removeContinuousAlternativesRoutesLayers()
        
        self.routes = [mainRoute]
        self.continuousAlternatives = routeResponse.parseAlternativeRoutes()
        currentLegIndex = legIndex
        customRouteLineLayerPosition = layerPosition
        
        applyRoutesDisplay(layerPosition: layerPosition)
    }
    
    func applyRoutesDisplay(layerPosition: MapboxMaps.LayerPosition? = nil) {
        var parentLayerIdentifier: String? = nil
        guard let routes = routes else { return }
        
        for (index, route) in routes.enumerated() {
            if index == 0 {
                
                if routeLineTracksTraversal {
                    initPrimaryRoutePoints(route: route)
                }
                
                if showsRestrictedAreasOnRoute {
                    parentLayerIdentifier = addRouteRestrictedAreaLayer(route,
                                                                        customLayerPosition: layerPosition)
                }
                
                pendingCoordinateForRouteLine = route.shape?.coordinates.first ?? mostRecentUserCourseViewLocation?.coordinate
            }
            
            // Use custom layer position for the main route layer. All other alternative route layers
            // will be placed below it.
            let customLayerPosition = index == 0 ? layerPosition : nil
            
            parentLayerIdentifier = addRouteLayer(route,
                                                  customLayerPosition: customLayerPosition,
                                                  below: parentLayerIdentifier,
                                                  isMainRoute: index == 0,
                                                  legIndex: currentLegIndex)
            parentLayerIdentifier = addRouteCasingLayer(route,
                                                        below: parentLayerIdentifier,
                                                        isMainRoute: index == 0)
            
            if index == 0 && routeLineTracksTraversal {
                parentLayerIdentifier = addTraversedRouteLayer(route, below: parentLayerIdentifier)
            }
        }
        
        guard let continuousAlternatives = continuousAlternatives else { return }
        for (index, routeAlternative) in continuousAlternatives.enumerated() {
            guard let route = routeAlternative.indexedRouteResponse.currentRoute,
                  alternativesRouteLineDeviationOffsets?.count ?? 0 > index,
                  let offset = alternativesRouteLineDeviationOffsets?[index] else {
                return
            }
            
            parentLayerIdentifier = addRouteLayer(route,
                                                  below: parentLayerIdentifier,
                                                  isMainRoute: false,
                                                  legIndex: nil)
            if let alternativeRouteLayerIdentifier = parentLayerIdentifier {
                setLayerLineGradient(for: alternativeRouteLayerIdentifier, with: offset)
            }
            
            parentLayerIdentifier = addRouteCasingLayer(route,
                                                        below: parentLayerIdentifier,
                                                        isMainRoute: false)
            if let alternativeRouteCasingIdentifier = parentLayerIdentifier {
                setLayerLineGradient(for: alternativeRouteCasingIdentifier, with: offset)
            }
        }
    }
    
    /**
     Remove any lines visualizing routes from the map.
     
     This method undoes the effects of the `show(_:legIndex:)` method.
     */
    public func removeRoutes() {
        var sourceIdentifiers = Set<String>()
        var layerIdentifiers = Set<String>()
        routes?.enumerated().forEach {
            sourceIdentifiers.insert($0.element.identifier(.source(isMainRoute: $0.offset == 0, isSourceCasing: true)))
            sourceIdentifiers.insert($0.element.identifier(.source(isMainRoute: $0.offset == 0, isSourceCasing: false)))
            sourceIdentifiers.insert($0.element.identifier(.restrictedRouteAreaSource))
            layerIdentifiers.insert($0.element.identifier(.route(isMainRoute: $0.offset == 0)))
            layerIdentifiers.insert($0.element.identifier(.routeCasing(isMainRoute: $0.offset == 0)))
            layerIdentifiers.insert($0.element.identifier(.traversedRoute))
            layerIdentifiers.insert($0.element.identifier(.restrictedRouteAreaRoute))
        }
        
        mapView.mapboxMap.style.removeLayers(layerIdentifiers)
        mapView.mapboxMap.style.removeSources(sourceIdentifiers)
        
        routes = nil
        removeLineGradientStops()
    }
    
    /**
     Removes all alternative routes that are currently shown on a map.
     */
    public func removeAlternativeRoutes() {
        var sourceIdentifiers = Set<String>()
        var layerIdentifiers = Set<String>()
        routes?.dropFirst().forEach {
            sourceIdentifiers.insert($0.identifier(.source(isMainRoute: false, isSourceCasing: true)))
            sourceIdentifiers.insert($0.identifier(.source(isMainRoute: false, isSourceCasing: false)))
            sourceIdentifiers.insert($0.identifier(.restrictedRouteAreaSource))
            layerIdentifiers.insert($0.identifier(.route(isMainRoute: false)))
            layerIdentifiers.insert($0.identifier(.routeCasing(isMainRoute: false)))
            layerIdentifiers.insert($0.identifier(.restrictedRouteAreaRoute))
        }
        
        mapView.mapboxMap.style.removeLayers(layerIdentifiers)
        mapView.mapboxMap.style.removeSources(sourceIdentifiers)
    }
    
    /**
     Shows the step arrow given the current `RouteProgress`.
     
     - parameter route: `Route` object, for which maneuver arrows will be shown.
     - parameter legIndex: Zero-based index of the `RouteLeg` which contains the maneuver.
     - parameter stepIndex: Zero-based index of the `RouteStep` which contains the maneuver.
     */
    public func addArrow(route: Route, legIndex: Int, stepIndex: Int) {
        guard route.containsStep(at: legIndex, stepIndex: stepIndex),
              let triangleImage = Bundle.mapboxNavigation.image(named: "triangle")?.withRenderingMode(.alwaysTemplate) else { return }
        
        do {
            if mapView.mapboxMap.style.image(withId: NavigationMapView.ImageIdentifier.arrowImage) == nil {
                try mapView.mapboxMap.style.addImage(triangleImage,
                                                     id: NavigationMapView.ImageIdentifier.arrowImage,
                                                     sdf: true,
                                                     stretchX: [],
                                                     stretchY: [])
            }
            
            let step = route.legs[legIndex].steps[stepIndex]
            let maneuverCoordinate = step.maneuverLocation
            guard step.maneuverType != .arrive else { return }
            
            let metersPerPoint = Projection.metersPerPoint(for: maneuverCoordinate.latitude,
                                                           zoom: mapView.cameraState.zoom)
            
            // TODO: Implement ability to change `shaftLength` depending on zoom level.
            let shaftLength = max(min(50 * metersPerPoint, 50), 30)
            let shaftPolyline = route.polylineAroundManeuver(legIndex: legIndex, stepIndex: stepIndex, distance: shaftLength)
            
            if shaftPolyline.coordinates.count > 1 {
                let minimumZoomLevel: Double = 14.5
                let shaftStrokeCoordinates = shaftPolyline.coordinates
                let shaftDirection = shaftStrokeCoordinates[shaftStrokeCoordinates.count - 2].direction(to: shaftStrokeCoordinates.last!)
                
                var arrowSource = GeoJSONSource()
                arrowSource.data = .feature(Feature(geometry: .lineString(shaftPolyline)))
                arrowSource.tolerance = overlaySimplificationTolerance
                var arrowLayer = LineLayer(id: NavigationMapView.LayerIdentifier.arrowLayer)
                if mapView.mapboxMap.style.sourceExists(withId: NavigationMapView.SourceIdentifier.arrowSource) {
                    let geoJSON = Feature(geometry: .lineString(shaftPolyline))
                    try mapView.mapboxMap.style.updateGeoJSONSource(withId: NavigationMapView.SourceIdentifier.arrowSource, geoJSON: .feature(geoJSON))
                } else {
                    arrowLayer.minZoom = Double(minimumZoomLevel)
                    arrowLayer.lineCap = .constant(.butt)
                    arrowLayer.lineJoin = .constant(.round)
                    arrowLayer.lineWidth = .expression(Expression.routeLineWidthExpression(0.70))
                    arrowLayer.lineColor = .constant(.init(maneuverArrowColor))
                    
                    try mapView.mapboxMap.style.addSource(arrowSource, id: NavigationMapView.SourceIdentifier.arrowSource)
                    arrowLayer.source = NavigationMapView.SourceIdentifier.arrowSource
                    arrowLayer = customizedLayer(arrowLayer)
                    
                    let layerPosition = layerPosition(for: NavigationMapView.LayerIdentifier.arrowLayer, route: route)
                    try mapView.mapboxMap.style.addPersistentLayer(arrowLayer, layerPosition: layerPosition)
                }
                
                var arrowStrokeSource = GeoJSONSource()
                arrowStrokeSource.data = .feature(Feature(geometry: .lineString(shaftPolyline)))
                arrowStrokeSource.tolerance = overlaySimplificationTolerance
                var arrowStrokeLayer = LineLayer(id: NavigationMapView.LayerIdentifier.arrowStrokeLayer)
                if mapView.mapboxMap.style.sourceExists(withId: NavigationMapView.SourceIdentifier.arrowStrokeSource) {
                    let geoJSON = Feature(geometry: .lineString(shaftPolyline))
                    try mapView.mapboxMap.style.updateGeoJSONSource(withId: NavigationMapView.SourceIdentifier.arrowStrokeSource,
                                                                    geoJSON: .feature(geoJSON))
                } else {
                    arrowStrokeLayer.minZoom = arrowLayer.minZoom
                    arrowStrokeLayer.lineCap = arrowLayer.lineCap
                    arrowStrokeLayer.lineJoin = arrowLayer.lineJoin
                    arrowStrokeLayer.lineWidth = .expression(Expression.routeLineWidthExpression(0.80))
                    arrowStrokeLayer.lineColor = .constant(.init(maneuverArrowStrokeColor))
                    
                    try mapView.mapboxMap.style.addSource(arrowStrokeSource, id: NavigationMapView.SourceIdentifier.arrowStrokeSource)
                    arrowStrokeLayer.source = NavigationMapView.SourceIdentifier.arrowStrokeSource
                    arrowStrokeLayer = customizedLayer(arrowStrokeLayer)
                    
                    try mapView.mapboxMap.style.addPersistentLayer(arrowStrokeLayer, layerPosition: .below(NavigationMapView.LayerIdentifier.arrowLayer))
                }
                
                let point = Point(shaftStrokeCoordinates.last!)
                var arrowSymbolSource = GeoJSONSource()
                arrowSymbolSource.data = .feature(Feature(geometry: .point(point)))
                arrowSymbolSource.tolerance = overlaySimplificationTolerance
                if mapView.mapboxMap.style.sourceExists(withId: NavigationMapView.SourceIdentifier.arrowSymbolSource) {
                    let geoJSON = Feature.init(geometry: Geometry.point(point))
                    try mapView.mapboxMap.style.updateGeoJSONSource(withId: NavigationMapView.SourceIdentifier.arrowSymbolSource,
                                                                    geoJSON: .feature(geoJSON))
                    
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
                    arrowSymbolLayer.iconColor = .constant(.init(maneuverArrowColor))
                    arrowSymbolLayer.iconRotationAlignment = .constant(.map)
                    arrowSymbolLayer.iconRotate = .constant(.init(shaftDirection))
                    arrowSymbolLayer.iconSize = .expression(Expression.routeLineWidthExpression(0.12))
                    arrowSymbolLayer.iconAllowOverlap = .constant(true)
                    
                    var arrowSymbolCasingLayer = SymbolLayer(id: NavigationMapView.LayerIdentifier.arrowSymbolCasingLayer)
                    arrowSymbolCasingLayer.minZoom = arrowSymbolLayer.minZoom
                    arrowSymbolCasingLayer.iconImage = arrowSymbolLayer.iconImage
                    arrowSymbolCasingLayer.iconColor = .constant(.init(maneuverArrowStrokeColor))
                    arrowSymbolCasingLayer.iconRotationAlignment = arrowSymbolLayer.iconRotationAlignment
                    arrowSymbolCasingLayer.iconRotate = arrowSymbolLayer.iconRotate
                    arrowSymbolCasingLayer.iconSize = .expression(Expression.routeLineWidthExpression(0.14))
                    arrowSymbolCasingLayer.iconAllowOverlap = arrowSymbolLayer.iconAllowOverlap
                    
                    try mapView.mapboxMap.style.addSource(arrowSymbolSource, id: NavigationMapView.SourceIdentifier.arrowSymbolSource)
                    arrowSymbolLayer.source = NavigationMapView.SourceIdentifier.arrowSymbolSource
                    arrowSymbolLayer = customizedLayer(arrowSymbolLayer)
                    arrowSymbolCasingLayer.source = NavigationMapView.SourceIdentifier.arrowSymbolSource
                    arrowSymbolCasingLayer = customizedLayer(arrowSymbolCasingLayer)
                    
                    try mapView.mapboxMap.style.addPersistentLayer(arrowSymbolLayer, layerPosition: .above(NavigationMapView.LayerIdentifier.arrowLayer))
                    try mapView.mapboxMap.style.addPersistentLayer(arrowSymbolCasingLayer,
                                                                   layerPosition: .below(NavigationMapView.LayerIdentifier.arrowSymbolLayer))
                }
            }
        } catch {
            Log.error("Failed to perform operation while adding maneuver arrow with error: \(error.localizedDescription).",
                      category: .navigationUI)
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
        
        do {
            if mapView.mapboxMap.style.image(withId: NavigationMapView.ImageIdentifier.arrowImage) != nil {
                try mapView.mapboxMap.style.removeImage(withId: NavigationMapView.ImageIdentifier.arrowImage)
            }
        } catch {
            Log.error("Failed to remove image \(NavigationMapView.ImageIdentifier.arrowImage) from style with error: \(error.localizedDescription).",
                      category: .navigationUI)
        }
    }
    
    /**
     Stop the vanishing effect for route line when `routeLineTracksTraversal` disabled.
     */
    func removeLineGradientStops() {
        fractionTraveled = 0.0
        if let routes = self.routes {
            show(routes, layerPosition: customRouteLineLayerPosition, legIndex: currentLegIndex)
        }
        
        routePoints = nil
        routeLineGranularDistances = nil
        routeRemainingDistancesIndex = nil
        pendingCoordinateForRouteLine = nil
    }
    
    @discardableResult func addRouteRestrictedAreaLayer(_ route: Route,
                                                        customLayerPosition: MapboxMaps.LayerPosition? = nil ) -> String? {
        let sourceIdentifier = route.identifier(.restrictedRouteAreaSource)
        let restrictedRoadsFeatures = route.restrictedRoadsFeatures()
        
        do {
            let shape = delegate?.navigationMapView(self, restrictedAreasShapeFor: route) ?? LineString(restrictedRoadsFeatures.compactMap {
                guard case let .lineString(lineString) = $0.geometry else {
                    return nil
                }
                return lineString.coordinates
            }.reduce([LocationCoordinate2D](), +))
            
            if mapView.mapboxMap.style.sourceExists(withId: sourceIdentifier) {
                try mapView.mapboxMap.style.updateGeoJSONSource(withId: sourceIdentifier,
                                                                geoJSON: .geometry(.lineString(shape)))
            } else {
                var restrictedAreaGeoJSON = GeoJSONSource()
                restrictedAreaGeoJSON.data = .geometry(.lineString(shape))
                restrictedAreaGeoJSON.lineMetrics = true
                restrictedAreaGeoJSON.tolerance = overlaySimplificationTolerance
                
                try mapView.mapboxMap.style.addSource(restrictedAreaGeoJSON, id: sourceIdentifier)
            }
        } catch {
            Log.error("Failed to add route source \(sourceIdentifier) with error: \(error.localizedDescription).",
                      category: .navigationUI)
        }
        
        let layerIdentifier = route.identifier(.restrictedRouteAreaRoute)
        var lineLayer = delegate?.navigationMapView(self,
                                                    routeRestrictedAreasLineLayerWithIdentifier: layerIdentifier,
                                                    sourceIdentifier: sourceIdentifier)

        var layerAlreadyExists = false
        if lineLayer == nil && mapView.mapboxMap.style.layerExists(withId: layerIdentifier) {
            lineLayer = try? mapView.mapboxMap.style.layer(withId: layerIdentifier) as? LineLayer
            layerAlreadyExists = true
        }
        
        if lineLayer == nil {
            var defaultLineLayer = LineLayer(id: layerIdentifier)
            defaultLineLayer.source = sourceIdentifier
            defaultLineLayer.lineColor = .constant(.init(routeRestrictedAreaColor))
            defaultLineLayer.lineWidth = .expression(Expression.routeLineWidthExpression(0.5))
            defaultLineLayer.lineJoin = .constant(.round)
            defaultLineLayer.lineCap = .constant(.round)
            defaultLineLayer.lineOpacity = .constant(0.5)
            
            let routeLineStops = routeLineRestrictionsGradient(restrictedRoadsFeatures)
            defaultLineLayer.lineGradient = .expression(Expression.routeLineGradientExpression(routeLineStops,
                                                                                         lineBaseColor: routeRestrictedAreaColor))
            defaultLineLayer.lineDasharray = .constant([0.5, 2.0])
            lineLayer = customizedLayer(defaultLineLayer)
        }
        
        if let lineLayer = lineLayer {
            do {
                let layerPosition = layerPosition(for: layerIdentifier, route: route, customLayerPosition: customLayerPosition)
                if layerAlreadyExists {
                    if let layerPosition = layerPosition {
                        try mapView.mapboxMap.style.moveLayer(withId: layerIdentifier, to: layerPosition)
                    }
                } else {
                    try mapView.mapboxMap.style.addPersistentLayer(lineLayer, layerPosition: layerPosition)
                }
            } catch {
                Log.error("Failed to add route layer \(layerIdentifier) with error: \(error.localizedDescription).",
                          category: .navigationUI)
            }
        }
        
        return layerIdentifier
    }
    
    @discardableResult func addRouteLayer(_ route: Route,
                                          customLayerPosition: MapboxMaps.LayerPosition? = nil,
                                          below parentLayerIndentifier: String? = nil,
                                          isMainRoute: Bool = true,
                                          legIndex: Int? = nil) -> String? {
        guard let defaultShape = route.shape else { return nil }
        let shape = delegate?.navigationMapView(self, shapeFor: route) ?? defaultShape
        
        let geoJSONSource = self.geoJSONSource(shape)
        let sourceIdentifier = route.identifier(.source(isMainRoute: isMainRoute, isSourceCasing: false))

        do {
            if mapView.mapboxMap.style.sourceExists(withId: sourceIdentifier) {
                try mapView.mapboxMap.style.updateGeoJSONSource(withId: sourceIdentifier,
                                                                geoJSON: .geometry(.lineString(shape)))
            } else {
                try mapView.mapboxMap.style.addSource(geoJSONSource, id: sourceIdentifier)
            }
        } catch {
            Log.error("Failed to add route source \(sourceIdentifier) with error: \(error.localizedDescription).",
                      category: .navigationUI)
        }
        
        let layerIdentifier = route.identifier(.route(isMainRoute: isMainRoute))
        var lineLayer = delegate?.navigationMapView(self,
                                                    routeLineLayerWithIdentifier: layerIdentifier,
                                                    sourceIdentifier: sourceIdentifier)
        
        var layerAlreadyExists = false
        if lineLayer == nil && mapView.mapboxMap.style.layerExists(withId: layerIdentifier) {
            lineLayer = try? mapView.mapboxMap.style.layer(withId: layerIdentifier) as? LineLayer
            layerAlreadyExists = true
        }
        
        if lineLayer == nil {
            var defaultLineLayer = LineLayer(id: layerIdentifier)
            defaultLineLayer.source = sourceIdentifier
            defaultLineLayer.lineColor = .constant(.init(trafficUnknownColor))
            defaultLineLayer.lineWidth = .expression(Expression.routeLineWidthExpression())
            defaultLineLayer.lineJoin = .constant(.round)
            defaultLineLayer.lineCap = .constant(.round)
            
            if isMainRoute {
                let congestionFeatures = route.congestionFeatures(legIndex: legIndex, roadClassesWithOverriddenCongestionLevels: roadClassesWithOverriddenCongestionLevels)
                let gradientStops = routeLineCongestionGradient(route,
                                                                congestionFeatures: congestionFeatures,
                                                                isSoft: crossfadesCongestionSegments)
                defaultLineLayer.lineGradient = .expression((Expression.routeLineGradientExpression(gradientStops,
                                                                                              lineBaseColor: trafficUnknownColor,
                                                                                              isSoft: crossfadesCongestionSegments)))
            } else {
                if showsCongestionForAlternativeRoutes {
                    let gradientStops = routeLineCongestionGradient(route,
                                                                    congestionFeatures: route.congestionFeatures(roadClassesWithOverriddenCongestionLevels: roadClassesWithOverriddenCongestionLevels),
                                                                    isMain: false,
                                                                    isSoft: crossfadesCongestionSegments)
                    defaultLineLayer.lineGradient = .expression((Expression.routeLineGradientExpression(gradientStops,
                                                                                                  lineBaseColor: alternativeTrafficUnknownColor,
                                                                                                  isSoft: crossfadesCongestionSegments)))
                } else {
                    let gradientStops: [Double: UIColor] = [1.0: routeAlternateColor]
                    defaultLineLayer.lineGradient = .expression((Expression.routeLineGradientExpression(gradientStops,
                                                                                                  lineBaseColor: routeAlternateColor,
                                                                                                  isSoft: false)))
                }
            }
            
            lineLayer = customizedLayer(defaultLineLayer)
        }
        
        if let lineLayer = lineLayer {
            do {
                var layerPosition: MapboxMaps.LayerPosition? = nil
                
                // In case if custom layer position was set - use it, otherwise in case if the route
                // is the main one place it above `MapView.mainRouteLineParentLayerIdentifier`. All
                // other alternative routes will be placed below it.
                if let belowLayerIdentifier = parentLayerIndentifier, mapView.mapboxMap.style.layerExists(withId: belowLayerIdentifier) {
                    layerPosition = .below(belowLayerIdentifier)
                } else {
                    layerPosition = self.layerPosition(for: layerIdentifier, route: route, customLayerPosition: customLayerPosition)
                }
                if layerAlreadyExists {
                    if let layerPosition = layerPosition {
                        try mapView.mapboxMap.style.moveLayer(withId: layerIdentifier, to: layerPosition)
                    }
                } else {
                    try mapView.mapboxMap.style.addPersistentLayer(lineLayer, layerPosition: layerPosition)
                }
            } catch {
                Log.error("Failed to add route layer \(layerIdentifier) with error: \(error.localizedDescription).",
                          category: .navigationUI)
            }
        }
        
        return layerIdentifier
    }
    
    @discardableResult func addRouteCasingLayer(_ route: Route,
                                                below parentLayerIndentifier: String? = nil,
                                                isMainRoute: Bool = true) -> String? {
        guard let defaultShape = route.shape else { return nil }
        let shape = delegate?.navigationMapView(self, casingShapeFor: route) ?? defaultShape
        
        let geoJSONSource = self.geoJSONSource(shape)
        let sourceIdentifier = route.identifier(.source(isMainRoute: isMainRoute, isSourceCasing: true))
        
        do {
            if mapView.mapboxMap.style.sourceExists(withId: sourceIdentifier) {
                try mapView.mapboxMap.style.updateGeoJSONSource(withId: sourceIdentifier,
                                                                geoJSON: .geometry(.lineString(shape)))
            } else {
                try mapView.mapboxMap.style.addSource(geoJSONSource, id: sourceIdentifier)
            }
        } catch {
            Log.error("Failed to add route casing source \(sourceIdentifier) with error: \(error.localizedDescription).",
                      category: .navigationUI)
        }
        
        let layerIdentifier = route.identifier(.routeCasing(isMainRoute: isMainRoute))
        var lineLayer = delegate?.navigationMapView(self,
                                                    routeCasingLineLayerWithIdentifier: layerIdentifier,
                                                    sourceIdentifier: sourceIdentifier)
        
        var layerAlreadyExists = false
        if lineLayer == nil && mapView.mapboxMap.style.layerExists(withId: layerIdentifier) {
            lineLayer = try? mapView.mapboxMap.style.layer(withId: layerIdentifier) as? LineLayer
            layerAlreadyExists = true
        }
        
        if lineLayer == nil {
            var defaultLineLayer = LineLayer(id: layerIdentifier)
            defaultLineLayer.source = sourceIdentifier
            defaultLineLayer.lineColor = .constant(.init(routeCasingColor))
            defaultLineLayer.lineWidth = .expression(Expression.routeLineWidthExpression(1.5))
            defaultLineLayer.lineJoin = .constant(.round)
            defaultLineLayer.lineCap = .constant(.round)
            
            if isMainRoute {
                let gradientStops = routeLineCongestionGradient(route)
                defaultLineLayer.lineGradient = .expression((Expression.routeLineGradientExpression(gradientStops, lineBaseColor: routeCasingColor)))
            } else {
                let gradientStops: [Double: UIColor] = [1.0: routeAlternateCasingColor]
                defaultLineLayer.lineGradient = .expression((Expression.routeLineGradientExpression(gradientStops,
                                                                                              lineBaseColor: routeAlternateCasingColor,
                                                                                              isSoft: false)))
            }
            
            lineLayer = customizedLayer(defaultLineLayer)
        }
        
        if let lineLayer = lineLayer {
            do {
                var layerPosition: MapboxMaps.LayerPosition? = nil
                if let parentLayerIndentifier = parentLayerIndentifier, mapView.mapboxMap.style.layerExists(withId: parentLayerIndentifier) {
                    layerPosition = .below(parentLayerIndentifier)
                } else {
                    layerPosition = self.layerPosition(for: layerIdentifier, route: route)
                }
                if layerAlreadyExists {
                    if let layerPosition = layerPosition {
                        try mapView.mapboxMap.style.moveLayer(withId: layerIdentifier, to: layerPosition)
                    }
                } else {
                    try mapView.mapboxMap.style.addPersistentLayer(lineLayer, layerPosition: layerPosition)
                }
            } catch {
                Log.error("Failed to add route casing layer \(layerIdentifier) with error: \(error.localizedDescription).",
                          category: .navigationUI)
            }
        }
        
        return layerIdentifier
    }
    
    @discardableResult func addTraversedRouteLayer(_ route: Route, below parentLayerIndentifier: String? = nil) -> String? {
        guard let defaultShape = route.shape else { return nil }
        
        // The traversed route layer should have the source as the main route casing source.
        let sourceIdentifier = route.identifier(.source(isMainRoute: true, isSourceCasing: true))
        
        if !mapView.mapboxMap.style.sourceExists(withId: sourceIdentifier) {
            let shape = delegate?.navigationMapView(self, casingShapeFor: route) ?? defaultShape
            let geoJSONSource = self.geoJSONSource(shape)
            do {
                try mapView.mapboxMap.style.addSource(geoJSONSource, id: sourceIdentifier)
            } catch {
                Log.error("Failed to add route casing source \(sourceIdentifier) for traversed route with error: \(error.localizedDescription).",
                          category: .navigationUI)
            }
        }
        
        var lineLayer: LineLayer? = nil
        let layerIdentifier = route.identifier(.traversedRoute)
        
        let layerAlreadyExists = mapView.mapboxMap.style.layerExists(withId: layerIdentifier)
        if layerAlreadyExists {
            lineLayer = try? mapView.mapboxMap.style.layer(withId: layerIdentifier) as? LineLayer
        }
        
        if lineLayer == nil {
            lineLayer = LineLayer(id: layerIdentifier)
            lineLayer?.source = sourceIdentifier
            lineLayer?.lineColor = .constant(.init(traversedRouteColor))
        }
        
        if var defaultLinelayer = lineLayer {
            let routeCasingLayerIdentifier = route.identifier(.routeCasing(isMainRoute: true))
            // Because users could modify the route casing layer property, the traversed route layer should have same property values as the main route casing layer,
            // except the line color.
            if let routeCasingLayer = try? mapView.mapboxMap.style.layer(withId: routeCasingLayerIdentifier, type: LineLayer.self) {
                // The traversed route layer should have the same width as the main route casing layer.
                defaultLinelayer.lineWidth = routeCasingLayer.lineWidth
                defaultLinelayer.lineJoin = routeCasingLayer.lineJoin
                defaultLinelayer.lineCap = routeCasingLayer.lineCap
            } else {
                defaultLinelayer.lineWidth = .expression(Expression.routeLineWidthExpression(1.5))
                defaultLinelayer.lineJoin = .constant(.round)
                defaultLinelayer.lineCap = .constant(.round)
            }
            lineLayer = customizedLayer(defaultLinelayer)
        }
        
        if let lineLayer = lineLayer {
            do {
                var layerPosition: MapboxMaps.LayerPosition? = nil
                if let parentLayerIndentifier = parentLayerIndentifier, mapView.mapboxMap.style.layerExists(withId: parentLayerIndentifier) {
                    layerPosition = .below(parentLayerIndentifier)
                } else {
                    layerPosition = self.layerPosition(for: layerIdentifier, route: route)
                }
                if layerAlreadyExists {
                    if let layerPosition = layerPosition {
                        try mapView.mapboxMap.style.moveLayer(withId: layerIdentifier, to: layerPosition)
                    }
                } else {
                    try mapView.mapboxMap.style.addPersistentLayer(lineLayer, layerPosition: layerPosition)
                }
            } catch {
                Log.error("Failed to add traversed route layer \(layerIdentifier) with error: \(error.localizedDescription).",
                          category: .navigationUI)
            }
        }
        
        return layerIdentifier
    }
    
    func geoJSONSource(_ shape: LineString) -> GeoJSONSource {
        var geoJSONSource = GeoJSONSource()
        geoJSONSource.data = .geometry(.lineString(shape))
        geoJSONSource.lineMetrics = true
        geoJSONSource.tolerance = overlaySimplificationTolerance
        return geoJSONSource
    }
    
    // MARK: Building Extrusion Highlighting
    
    /**
     Color of the buildings, which were found at specific coordinates by calling
     `NavigationMapView.highlightBuildings(at:in3D:extrudeAll:completion:)` and when `extrudeAll`
     parameter is set to `false`.
     */
    @objc dynamic public var buildingHighlightColor: UIColor = .defaultBuildingHighlightColor
    
    /**
     Color of all other buildings, which will be highlighted after calling
     `NavigationMapView.highlightBuildings(at:in3D:extrudeAll:completion:)` and when `extrudeAll`
     parameter is set to `true`.
     */
    @objc dynamic public var buildingDefaultColor: UIColor = .defaultBuildingColor
    
    // MARK: User Tracking Features
    
    var _locationChangesAllowed = true
    
    var authorizationStatus: CLAuthorizationStatus = .notDetermined {
        didSet {
            if isAuthorized() {
                setupUserLocation()
            } else {
                mapView.location.options.puckType = nil
                reducedAccuracyUserHaloCourseView = nil
                
                if let currentCourseView = mapView.viewWithTag(NavigationMapView.userCourseViewTag) {
                    currentCourseView.removeFromSuperview()
                }
            }
        }
    }
    
    var accuracyAuthorization: CLAccuracyAuthorization = .fullAccuracy {
        didSet {
            // `UserHaloCourseView` will be applied in only one case:
            // when user explicitly sets `NavigationMapView.reducedAccuracyActivatedMode` to `true`,
            // and the `Precise Location` property in the settings of current application is disabled by user.
            let shouldApply = reducedAccuracyActivatedMode && accuracyAuthorization == .reducedAccuracy
            applyReducedAccuracyMode(shouldApply: shouldApply)
        }
    }
    
    var allowedAuthorizationStatuses: [CLAuthorizationStatus] = [
        .authorizedAlways,
        .authorizedWhenInUse
    ]
    
    /**
     Specifies how the map displays the user’s current location, including the appearance and underlying implementation.
     
     By default, this property is set to `UserLocationStyle.puck2D(configuration:)`, the bearing source is location course.
     */
    public var userLocationStyle: UserLocationStyle? = .puck2D() {
        didSet {
            setupUserLocation()
        }
    }
    
    /**
     Most recent user location, which is used to place `UserCourseView`.
     */
    var mostRecentUserCourseViewLocation: CLLocation?
    
    /**
     The coordinates and corresponding identifiers for highlight buildings.
     */
    var highlightedBuildingIdentifiersByCoordinate = [CLLocationCoordinate2DHashable: Int64]()
    
    func setupUserLocation() {
        if !isAuthorized() { return }
        
        // Since Mapbox Maps will not provide location data in case if `LocationOptions.puckType` is
        // set to nil, we have to draw empty and transparent `UIImage` instead of puck. This is used
        // in case when user wants to stop showing location puck or draw a custom one.
        let clearImage = UIColor.clear.image(CGSize(size: 1.0))
        let emptyPuckConfiguration = Puck2DConfiguration(topImage: clearImage,
                                                         bearingImage: clearImage,
                                                         shadowImage: clearImage,
                                                         scale: nil,
                                                         showsAccuracyRing: false)
        
        // In case if location puck style is changed (e.g. when setting
        // `NavigationMapView.reducedAccuracyActivatedMode` to `true` or when setting
        // default `PuckType.puck2D()`) previously set `UserCourseView` will be removed.
        if let currentCourseView = mapView.viewWithTag(NavigationMapView.userCourseViewTag) {
            currentCourseView.removeFromSuperview()
        }
        
        if let reducedAccuracyUserHaloCourseView = reducedAccuracyUserHaloCourseView {
            mapView.location.options.puckType = .puck2D(emptyPuckConfiguration)
            
            reducedAccuracyUserHaloCourseView.tag = NavigationMapView.userCourseViewTag
            mapView.addSubview(reducedAccuracyUserHaloCourseView)
        } else {
            switch userLocationStyle {
            case .courseView(let courseView):
                mapView.location.options.puckType = .puck2D(emptyPuckConfiguration)
                
                courseView.tag = NavigationMapView.userCourseViewTag
                mapView.addSubview(courseView)
                
                if let location = mostRecentUserCourseViewLocation {
                    moveUserLocation(to: location)
                }
            case .puck2D(configuration: let configuration):
                mapView.location.options.puckType = .puck2D(configuration ?? Puck2DConfiguration())
            case .puck3D(configuration: let configuration):
                mapView.location.options.puckType = .puck3D(configuration)
            case .none:
                mapView.location.options.puckType = .puck2D(emptyPuckConfiguration)
            }
            mapView.location.options.puckBearingSource = .course
        }
    }
    
    func setupLocationManager() {
        locationManager.delegate = self
    }
    
    /**
     Allows to control current user location styling based on accuracy authorization permission on iOS 14 and above.
     Defaults to `false`.
     
     When user disable the `Precise Location` property in the settings of current application:
     If `false`, user location will be drawn based on style, which was set in `NavigationMapView.userLocationStyle`.
     If `true`, `UserHaloCourseView` will be shown.
     */
    @objc dynamic public var reducedAccuracyActivatedMode: Bool = false {
        didSet {
            let shouldApply = reducedAccuracyActivatedMode && accuracyAuthorization == .reducedAccuracy
            applyReducedAccuracyMode(shouldApply: shouldApply)
        }
    }
    
    func applyReducedAccuracyMode(shouldApply: Bool) {
        if shouldApply {
            let userHaloCourseViewFrame = CGRect(origin: .zero, size: 75.0)
            reducedAccuracyUserHaloCourseView = UserHaloCourseView(frame: userHaloCourseViewFrame)
            
            // In case if the most recent user location is available use it while adding
            // `UserHaloCourseView` on a map.
            if let location = mostRecentUserCourseViewLocation {
                moveUserLocation(to: location)
            }
        } else {
            reducedAccuracyUserHaloCourseView = nil
        }
    }
    
    /**
     `UserHaloCourseView`, which is shown after enabling accuracy authorization permission on iOS 14 and higher.
     */
    var reducedAccuracyUserHaloCourseView: UserHaloCourseView? = nil {
        didSet {
            setupUserLocation()
        }
    }
    
    /**
     Updates `UserLocationStyle` to provided location.
     
     - parameter location: Location, where `UserLocationStyle` should be shown.
     - parameter animated: Property, which determines whether `UserLocationStyle` transition to new location will be animated.
     */
    public func moveUserLocation(to location: CLLocation, animated: Bool = false) {
        guard CLLocationCoordinate2DIsValid(location.coordinate) else { return }
        
        let previousUserCourseViewLocation = mostRecentUserCourseViewLocation
        mostRecentUserCourseViewLocation = location
        
        if let reducedAccuracyUserHaloCourseView = reducedAccuracyUserHaloCourseView {
            move(reducedAccuracyUserHaloCourseView,
                 from: previousUserCourseViewLocation,
                 to: location,
                 animated: animated)
            return
        }
        
        if case let .courseView(view) = userLocationStyle {
            move(view,
                 from: previousUserCourseViewLocation,
                 to: location,
                 animated: animated)
        }
    }
    
    func move(_ userCourseView: UserCourseView,
              from previousLocation: CLLocation? = nil,
              to location: CLLocation,
              animated: Bool = false) {
        // If the point is outside of the bounds of `MapView` - hide user course view.
        let point = mapView.mapboxMap.point(for: location.coordinate)
        if point == .pointOutOfMapViewBounds {
            userCourseView.isHidden = true
            return
        } else {
            userCourseView.isHidden = false
        }
        
        if let previousLocation = previousLocation {
            let point = mapView.mapboxMap.point(for: previousLocation.coordinate)
            userCourseView.center = point
        }
        
        // While animating to overview mode, don't animate the puck.
        let duration: TimeInterval = animated && navigationCamera.state != .transitionToOverview ? 1 : 0
        UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear]) { [weak self] in
            guard let self = self else { return }
            let point = self.mapView.mapboxMap.point(for: location.coordinate)
            userCourseView.center = point
        }
        
        let cameraOptions = CameraOptions(cameraState: mapView.cameraState)

        userCourseView.update(location: location,
                              pitch: cameraOptions.pitch!,
                              direction: cameraOptions.bearing!,
                              animated: animated,
                              navigationCameraState: navigationCamera.state)
    }
    
    // MARK: Route-Related Annotations Displaying
    
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
     Shows a callout containing the duration of each route.
     Useful as a way to give the user more information when picking between multiple route alternatives.
     If the route contains any tolled segments then the callout will specify that as well.
     */
    public func showRouteDurations(along routes: [Route]?) {
        guard let visibleRoutes = routes, visibleRoutes.count > 0 else { return }
        
        do {
            try updateAnnotationSymbolImages()
        } catch {
            Log.error("Error occured while updating annotation symbol images: \(error.localizedDescription).",
                      category: .navigationUI)
        }
        
        updateRouteDurations(along: visibleRoutes)
    }
    
    /**
     Controls if displayed `continuousAlternative`s will also be annotated with estimated travel time delta relative to the main route.
     
     Callouts text font also respects `NavigationMapView.routeDurationAnnotationFontNames` property.
     Default value is `true`.
     */
    public var showsRelativeDurationOnContinuousAlternativeRoutes: Bool = true {
        didSet {
            showContinuousAlternativeRoutesDurations()
        }
    }
    
    let continuousAlternativeDurationAnnotationOffset: LocationDistance = 75
    
    /**
     Removes all visible route duration callouts.
     */
    public func removeRouteDurations() {
        let style = mapView.mapboxMap.style
        // Removes the underlying style layers and data sources for the route duration annotations.
        style.removeLayers([NavigationMapView.LayerIdentifier.routeDurationAnnotationsLayer])
        style.removeSources([NavigationMapView.SourceIdentifier.routeDurationAnnotationsSource])
    }
    
    /**
     Removes all visible continuous alternative routes duration callouts.
     */
    public func removeContinuousAlternativeRoutesDurations() {
        let style = mapView.mapboxMap.style
        style.removeLayers([NavigationMapView.LayerIdentifier.continuousAlternativeRoutesDurationAnnotationsLayer])
        style.removeSources([NavigationMapView.SourceIdentifier.continuousAlternativeRoutesDurationAnnotationsSource])
    }
    
    /**
     Array of `PointAnnotation`s, which should be added to the `MapView` when `PointAnnotationManager` becomes
     available. Since `PointAnnotationManager` is created only after loading `MapView` style, there
     is a chance that due to a race condition during `NavigationViewController` creation
     `NavigationMapView.showWaypoints(on:legIndex:)` will be called before loading style. In such case
     final destination `PointAnnotation` will be stored in this property and added to the `MapView`
     later on.
     */
    var finalDestinationAnnotations: [PointAnnotation] = []
    
    /**
     Adds the route waypoints to the map given the current leg index. Previous waypoints for completed legs will be omitted.
     
     - parameter route: `Route`, on which a certain `Waypoint` will be shown.
     - parameter legIndex: Index, which determines for which `RouteLeg` `Waypoint` will be shown.
     */
    public func showWaypoints(on route: Route, legIndex: Int = 0) {
        let waypoints: [Waypoint] = Array(route.legs.dropLast().compactMap({ $0.destination }))
        
        var features = [Turf.Feature]()
        for (waypointIndex, waypoint) in waypoints.enumerated() {
            var feature = Feature(geometry: .point(Point(waypoint.coordinate)))
            feature.properties = [
                "waypointCompleted": .boolean(waypointIndex < legIndex),
                "name": .number(Double(waypointIndex + 1)),
            ]
            features.append(feature)
        }
        
        let shape = delegate?.navigationMapView(self, shapeFor: waypoints, legIndex: legIndex) ?? FeatureCollection(features: features)
        
        if route.legs.count > 1 {
            removeAlternativeRoutes()
            routes = [route]
            
            do {
                let waypointSourceIdentifier = NavigationMapView.SourceIdentifier.waypointSource
                
                if mapView.mapboxMap.style.sourceExists(withId: waypointSourceIdentifier) {
                    try mapView.mapboxMap.style.updateGeoJSONSource(withId: waypointSourceIdentifier, geoJSON: .featureCollection(shape))
                } else {
                    var waypointSource = GeoJSONSource()
                    waypointSource.data = .featureCollection(shape)
                    try mapView.mapboxMap.style.addSource(waypointSource, id: waypointSourceIdentifier)
                    
                    let waypointCircleLayerIdentifier = NavigationMapView.LayerIdentifier.waypointCircleLayer
                    var circlesLayer = delegate?.navigationMapView(self,
                                                                   waypointCircleLayerWithIdentifier: waypointCircleLayerIdentifier,
                                                                   sourceIdentifier: waypointSourceIdentifier) ?? defaultWaypointCircleLayer()
                    circlesLayer = customizedLayer(circlesLayer)
                    
                    let layerPosition = layerPosition(for: waypointCircleLayerIdentifier, route: route)
                    try mapView.mapboxMap.style.addPersistentLayer(circlesLayer, layerPosition: layerPosition)
                    
                    let waypointSymbolLayerIdentifier = NavigationMapView.LayerIdentifier.waypointSymbolLayer
                    var symbolsLayer = delegate?.navigationMapView(self,
                                                                   waypointSymbolLayerWithIdentifier: waypointSymbolLayerIdentifier,
                                                                   sourceIdentifier: waypointSourceIdentifier) ?? defaultWaypointSymbolLayer()
                    symbolsLayer = customizedLayer(symbolsLayer)
                    
                    try mapView.mapboxMap.style.addPersistentLayer(symbolsLayer, layerPosition: .above(waypointCircleLayerIdentifier))
                }
            } catch {
                Log.error("Failed to perform operation while adding waypoint with error: \(error.localizedDescription).",
                          category: .navigationUI)
            }
        }
        
        if let lastLeg = route.legs.last,
           let destinationCoordinate = lastLeg.destination?.coordinate {
            addDestinationAnnotation(destinationCoordinate)
        }
    }
    
    func addDestinationAnnotation(_ coordinate: CLLocationCoordinate2D,
                                  identifier: String = NavigationMapView.AnnotationIdentifier.finalDestinationAnnotation) {
        var destinationAnnotation = PointAnnotation(id: identifier, coordinate: coordinate)
        destinationAnnotation.image = .init(image: .defaultMarkerImage, name: ImageIdentifier.markerImage)
        
        // If `PointAnnotationManager` is available - add `PointAnnotation`, if not - remember it
        // and add it only after fully loading `MapView` style.
        if let pointAnnotationManager = pointAnnotationManager {
            pointAnnotationManager.annotations.append(destinationAnnotation)
            delegate?.navigationMapView(self,
                                        didAdd: destinationAnnotation,
                                        pointAnnotationManager: pointAnnotationManager)
        } else {
            finalDestinationAnnotations.append(destinationAnnotation)
        }
    }
    
    func removeDestinationAnnotation(_ identifier: String = NavigationMapView.AnnotationIdentifier.finalDestinationAnnotation) {
        let remainingAnnotations = pointAnnotationManager?.annotations.filter {
            $0.id != identifier
        }
        
        pointAnnotationManager?.annotations = remainingAnnotations ?? []
    }
    
    /**
     Removes all existing `Waypoint` objects from `MapView`, which were added by `NavigationMapView`.
     */
    public func removeWaypoints() {
        removeDestinationAnnotation()
        
        let layers: Set = [
            NavigationMapView.LayerIdentifier.waypointCircleLayer,
            NavigationMapView.LayerIdentifier.waypointSymbolLayer
        ]
        
        mapView.mapboxMap.style.removeLayers(layers)
        mapView.mapboxMap.style.removeSources([NavigationMapView.SourceIdentifier.waypointSource])
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
        circleLayer.circleColor = .constant(.init(UIColor(red:0.9, green:0.9, blue:0.9, alpha:1.0)))
        circleLayer.circleOpacity = .expression(opacity)
        circleLayer.circleRadius = .constant(.init(10))
        circleLayer.circleStrokeColor = .constant(.init(UIColor.black))
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
        symbolLayer.textHaloColor = .constant(.init(UIColor.black))
        
        return symbolLayer
    }
    
    // MARK: Managing Annotations
    
    /**
     `PointAnnotationManager`, which is used to manage addition and removal of final destination annotation.
     `PointAnnotationManager` will become valid only after fully loading `MapView` style.
     */
    public var pointAnnotationManager: PointAnnotationManager?
    
    func annotationsToRemove() -> [Annotation] {
        let identifier = NavigationMapView.AnnotationIdentifier.finalDestinationAnnotation
        return pointAnnotationManager?.annotations.filter({ $0.id == identifier }) ?? []
    }
    
    // MARK: Map Rendering and Observing
    
    var routes: [Route]?
    var continuousAlternatives: [AlternativeRoute]? {
        didSet {
            alternativesRouteLineDeviationOffsets = continuousAlternatives?.map {
                guard let coordinates = $0.indexedRouteResponse.currentRoute?.shape?.coordinates,
                      let projectedOffset = calculateGranularDistanceOffset(coordinates,
                                                                            splitPoint: $0.alternativeRouteIntersection.location) else {
                    return 0.0
                }
                return projectedOffset
            }
        }
    }
    var alternativesRouteLineDeviationOffsets: [Double]?
    var routePoints: RoutePoints?
    var routeLineGranularDistances: RouteLineGranularDistances?
    var routeRemainingDistancesIndex: Int?
    var fractionTraveled: Double = 0.0
    var currentLegIndex: Int?
    var offRouteDistanceCheckEnabled: Bool = true
    
    /**
     The maximum distance threshold of vanishing route line update. When the user's location to the route line is larger than the threshold, the user is off the route and the route line won't be updated.
     */
    var offRouteDistanceUpdateThreshold: CLLocationDistance = 15.0
    
    /**
     `MapView`, which is added on top of `NavigationMapView` and allows to render navigation related components.
     */
    public private(set) var mapView: MapView!
    
    /**
     The object that acts as the navigation delegate of the map view.
     */
    public weak var delegate: NavigationMapViewDelegate?
    
    var locationProvider: LocationProvider?
    var simulatesLocation: Bool = true
    
    /**
     Attempts to localize labels into the system’s preferred language.
     
     This method automatically modifies the `SymbolLayer.textField` property of any symbol style
     layer whose source is the [Mapbox Streets source](https://docs.mapbox.com/vector-tiles/reference/mapbox-streets-v8/#overview).
     The user can set the system’s preferred language in Settings, General Settings, Language & Region.
     
     This method avoids localizing road labels into the system’s preferred language, in an effort
     to match road signage and the turn banner, which always display road names and exit destinations
     in the local language. If this `NavigationMapView` stands alone outside a `NavigationViewController`,
     you should call the `MapboxMap.onEvery(_:handler:)` on `mapView`, passing in
     `MapEvents.EventKind.styleLoaded`, and call this method inside the closure.
     The map view embedded in `NavigationViewController` is localized automatically, so you do not
     need to call this method on the value of `NavigationViewController.navigationMapView`.
     */
    public func localizeLabels() {
        guard let preferredLocale = VectorSource.preferredMapboxStreetsLocale(for: nil) else { return }
        mapView.localizeLabels(into: preferredLocale)
    }
    
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
                        "instruction": .string(instruction.text),
                    ]
                    featureCollection.features.append(feature)
                }
            }
        }
        
        do {
            if mapView.mapboxMap.style.sourceExists(withId: NavigationMapView.SourceIdentifier.voiceInstructionSource) {
                try mapView.mapboxMap.style.updateGeoJSONSource(withId: NavigationMapView.SourceIdentifier.voiceInstructionSource, geoJSON: .featureCollection(featureCollection))
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
                symbolLayer.textHaloColor = .constant(.init(.white))
                symbolLayer.textOpacity = .constant(0.75)
                symbolLayer.textAnchor = .constant(.bottom)
                symbolLayer.textJustify = .constant(.left)
                symbolLayer = customizedLayer(symbolLayer)
                
                let layerPosition = layerPosition(for: NavigationMapView.LayerIdentifier.voiceInstructionLabelLayer)
                try mapView.mapboxMap.style.addPersistentLayer(symbolLayer, layerPosition: layerPosition)
                
                var circleLayer = CircleLayer(id: NavigationMapView.LayerIdentifier.voiceInstructionCircleLayer)
                circleLayer.source = NavigationMapView.SourceIdentifier.voiceInstructionSource
                circleLayer.circleRadius = .constant(5)
                circleLayer.circleOpacity = .constant(0.75)
                circleLayer.circleColor = .constant(.init(.white))
                circleLayer = customizedLayer(circleLayer)
                
                try mapView.mapboxMap.style.addPersistentLayer(circleLayer, layerPosition: .above(NavigationMapView.LayerIdentifier.voiceInstructionLabelLayer))
            }
        } catch {
            Log.error("Failed to perform operation while adding voice instructions with error: \(error.localizedDescription).",
                      category: .navigationUI)
        }
    }
    
    func customizedLayer<T>(_ layer: T) -> T where T: Layer {
        if let customizedLayer = delegate?.navigationMapView(self, willAdd: layer) {
            guard let customizedLayer = customizedLayer as? T else {
                preconditionFailure("The customized layer should have the same layer type as the default layer.")
            }
            return customizedLayer
        }
        return layer
    }
    
    func layerPosition(for layerIdentifier: String, route: Route? = nil, customLayerPosition: MapboxMaps.LayerPosition? = nil) -> MapboxMaps.LayerPosition? {
        guard customLayerPosition == nil else { return customLayerPosition }
        
        let lowermostSymbolLayers: [String] = [
            LayerIdentifier.buildingExtrusionLayer,
            route?.identifier(.routeCasing(isMainRoute: false)),
            route?.identifier(.route(isMainRoute: false)),
            route?.identifier(.traversedRoute),
            route?.identifier(.routeCasing(isMainRoute: true)),
            route?.identifier(.route(isMainRoute: true)),
            route?.identifier(.restrictedRouteAreaRoute)
        ].compactMap{ $0 }
        let arrowLayers: [String] = [
            LayerIdentifier.arrowStrokeLayer,
            LayerIdentifier.arrowLayer,
            LayerIdentifier.arrowSymbolCasingLayer,
            LayerIdentifier.arrowSymbolLayer,
            LayerIdentifier.intersectionAnnotationsLayer
        ]
        let uppermostSymbolLayers: [String] = [
            LayerIdentifier.waypointCircleLayer,
            LayerIdentifier.waypointSymbolLayer,
            LayerIdentifier.continuousAlternativeRoutesDurationAnnotationsLayer,
            LayerIdentifier.routeDurationAnnotationsLayer,
            LayerIdentifier.voiceInstructionLabelLayer,
            LayerIdentifier.voiceInstructionCircleLayer,
            LayerIdentifier.puck2DLayer,
            LayerIdentifier.puck3DLayer
        ]
        let isLowermostLayer = lowermostSymbolLayers.contains(layerIdentifier)
        let isAboveRoadLayer = arrowLayers.contains(layerIdentifier)
        let allAddedLayers: [String] = lowermostSymbolLayers + arrowLayers + uppermostSymbolLayers
        
        var layerPosition: MapboxMaps.LayerPosition? = nil
        var lowerLayers = Set<String>()
        var upperLayers = Set<String>()
        var targetLayer: String? = nil
        
        if let index = allAddedLayers.firstIndex(of: layerIdentifier) {
            lowerLayers = Set(allAddedLayers.prefix(upTo: index))
            if allAddedLayers.indices.contains(index + 1) {
                upperLayers = Set(allAddedLayers.suffix(from: index + 1))
            }
        }
        
        var foundAboveLayer: Bool = false
        for layerInfo in mapView.mapboxMap.style.allLayerIdentifiers.reversed() {
            if lowerLayers.contains(layerInfo.id) {
                // find the topmost layer that should be below the layerIdentifier.
                if !foundAboveLayer {
                    layerPosition = .above(layerInfo.id)
                    foundAboveLayer = true
                }
            } else if upperLayers.contains(layerInfo.id) {
                // find the bottommost layer that should be above the layerIdentifier.
                layerPosition = .below(layerInfo.id)
            } else if isLowermostLayer {
                // find the topmost non symbol layer for layerIdentifier in lowermostSymbolLayers.
                if targetLayer == nil,
                   layerInfo.type.rawValue != "symbol",
                   let sourceLayer = mapView.mapboxMap.style.layerProperty(for: layerInfo.id, property: "source-layer").value as? String,
                   !sourceLayer.isEmpty {
                    if layerInfo.type.rawValue == "circle",
                       let isPersistentCircle = try? mapView.mapboxMap.style.isPersistentLayer(id: layerInfo.id) {
                        let pitchAlignment = mapView.mapboxMap.style.layerProperty(for: layerInfo.id, property: "circle-pitch-alignment").value as? String
                        if isPersistentCircle || (pitchAlignment != "map") {
                            continue
                        }
                    }
                    targetLayer = layerInfo.id
                }
            } else if isAboveRoadLayer {
                // find the topmost road name label layer for layerIdentifier in arrowLayers.
                if targetLayer == nil,
                   layerInfo.id.contains("road-label"),
                   mapView.mapboxMap.style.layerExists(withId: layerInfo.id) {
                    targetLayer = layerInfo.id
                }
            } else {
                // find the topmost layer for layerIdentifier in uppermostSymbolLayers.
                if targetLayer == nil,
                   let sourceLayer = mapView.mapboxMap.style.layerProperty(for: layerInfo.id, property: "source-layer").value as? String,
                   !sourceLayer.isEmpty {
                    targetLayer = layerInfo.id
                }
            }
        }
        
        guard let targetLayer = targetLayer else { return layerPosition }
        guard let layerPosition = layerPosition else { return .above(targetLayer) }
        
        if isLowermostLayer {
            // For layers should be below symbol layers.
            if case let .below(sequenceLayer) = layerPosition, !lowermostSymbolLayers.contains(sequenceLayer) {
                // If the sequenceLayer isn't in lowermostSymbolLayers, it's above symbol layer.
                // So for the layerIdentifier, it should be put above the targetLayer, which is the topmost non symbol layer,
                // but under the symbol layers.
                return .above(targetLayer)
            }
        } else if isAboveRoadLayer {
            // For layers should be above road name labels but below other symbol layers.
            if case let .below(sequenceLayer) = layerPosition, uppermostSymbolLayers.contains(sequenceLayer) {
                // If the sequenceLayer is in uppermostSymbolLayers, it's above all symbol layers.
                // So for the layerIdentifier, it should be put above the targetLayer, which is the topmost road name symbol layer.
                return .above(targetLayer)
            } else if case let .above(sequenceLayer) = layerPosition, lowermostSymbolLayers.contains(sequenceLayer) {
                // If the sequenceLayer is in lowermostSymbolLayers, it's below all symbol layers.
                // So for the layerIdentifier, it should be put above the targetLayer, which is the topmost road name symbol layer.
                return .above(targetLayer)
            }
        } else {
            // For other layers should be uppermost and above symbol layers.
            if case let .above(sequenceLayer) = layerPosition, !uppermostSymbolLayers.contains(sequenceLayer) {
                // If the sequenceLayer isn't in uppermostSymbolLayers, it's below some symbol layers.
                // So for the layerIdentifier, it should be put above the targetLayer, which is the topmost layer.
                return .above(targetLayer)
            }
        }
        
        return layerPosition
    }
    
    /**
     Initializes a newly allocated `NavigationMapView` object with the specified frame rectangle.
     
     - parameter frame: The frame rectangle for the `NavigationMapView`.
     */
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupMapView(mapView: makeMapView(frame: frame))
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
        let mapView = makeMapView(
            frame: frame,
            navigationCameraType: navigationCameraType,
            tileStoreLocation: tileStoreLocation
        )
        setupMapView(mapView: mapView, navigationCameraType: navigationCameraType)
        commonInit()
    }

    /// :nodoc:
    public init(
        frame: CGRect,
        navigationCameraType: NavigationCameraType = .mobile,
        mapView: MapView
    ) {
        super.init(frame: frame)

        setupMapView(mapView: mapView, navigationCameraType: navigationCameraType)
        commonInit()
    }
    
    /**
     Returns a `NavigationMapView` object initialized from data in a given unarchiver.
     
     - parameter coder: An unarchiver object.
     */
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupMapView(mapView: makeMapView(frame: bounds))
        commonInit()
    }
    
    fileprivate func commonInit() {
        setupLocationManager()
        makeGestureRecognizersResetFrameRate()
        setupGestureRecognizers()
        subscribeForNotifications()
        setupUserLocation()
        
        // To prevent the lengthy animation from the Null Island to the current location use
        // location from the location manager and set map view's camera to it (without animation).
        if let coordinate = locationManager.location?.coordinate {
            setInitialCamera(coordinate)
        }
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

    private func makeMapView(
            frame: CGRect,
            navigationCameraType: NavigationCameraType = .mobile,
            tileStoreLocation: TileStoreConfiguration.Location? = .default
    ) -> MapView {
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

        return MapView(frame: frame, mapInitOptions: mapInitOptions)
    }
    
    private func setupMapView(mapView: MapView, navigationCameraType: NavigationCameraType = .mobile) {
        self.mapView = mapView
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.ornaments.options.scaleBar.visibility = .hidden
        storeLocationProviderBeforeSimulation()
        
        mapView.mapboxMap.onEvery(event: .renderFrameFinished) { [weak self] _ in
            guard let self = self else { return }
            
            if let location = self.mostRecentUserCourseViewLocation {
                switch self.userLocationStyle {
                case .courseView:
                    self.moveUserLocation(to: location)
                    if self.routeLineTracksTraversal {
                        self.travelAlongRouteLine(to: location.coordinate)
                    }
                default:
                    if self.simulatesLocation,
                       let locationProvider = self.mapView.location.locationProvider as? NavigationLocationProvider {
                        locationProvider.didUpdateLocations(locations: [location])
                    }
                }
            }
            
            let locationIndicatorLayerIdentifier = "puck"
            if let locationIndicatorLayer = try? self.mapView.mapboxMap.style.layer(withId: locationIndicatorLayerIdentifier) as? LocationIndicatorLayer {
                try? self.mapView.mapboxMap.style.updateLayer(withId: locationIndicatorLayerIdentifier,
                                                              type: LocationIndicatorLayer.self,
                                                              update: { [weak self] oldLocationIndicatorLayer in
                    guard let self = self else { return }
                    
                    // In case if reduced accuracy mode is active - hide puck layer, that is drawn by the Maps SDK.
                    if let _ = self.reducedAccuracyUserHaloCourseView {
                        if locationIndicatorLayer.visibility == nil || locationIndicatorLayer.visibility == .constant(.visible) {
                            oldLocationIndicatorLayer.visibility = .constant(.none)
                        }
                    } else {
                        if locationIndicatorLayer.visibility == .constant(.none) {
                            oldLocationIndicatorLayer.visibility = .constant(.visible)
                        }
                    }
                })
            }
        }
        
        mapView.mapboxMap.onNext(event: .styleLoaded) { [weak self] _ in
            guard let self = self else { return }
            self.pointAnnotationManager = self.mapView.annotations.makePointAnnotationManager()
            
            if self.finalDestinationAnnotations.count != 0,
               let pointAnnotationManager = self.pointAnnotationManager {
                pointAnnotationManager.annotations = self.finalDestinationAnnotations
                
                self.finalDestinationAnnotations.forEach {
                    self.delegate?.navigationMapView(self,
                                                     didAdd: $0,
                                                     pointAnnotationManager: pointAnnotationManager)
                }
                
                self.finalDestinationAnnotations = []
            }
        }
        
        addSubview(mapView)
        
        mapView.pinTo(parentView: self)
        
        navigationCamera = NavigationCamera(mapView, navigationCameraType: navigationCameraType)
        navigationCamera.follow()
    }
    
    func storeLocationProviderBeforeSimulation() {
        simulatesLocation = true
        locationProvider = mapView.location.locationProvider
        locationProvider?.stopUpdatingLocation()
        locationProvider?.stopUpdatingHeading()
    }

    func useStoredLocationProvider() {
        simulatesLocation = false
        let locationProvider = self.locationProvider ?? AppleLocationProvider()
        mapView.location.overrideLocationProvider(with: locationProvider)
    }
    
    func setupGestureRecognizers() {
        // Gesture recognizer, which is used to detect taps on route line and waypoint.
        mapViewTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didReceiveTap(sender:)))
        mapViewTapGestureRecognizer.delegate = self
        mapView.addGestureRecognizer(mapViewTapGestureRecognizer)
    }
    
    /**
     Fired when NavigationMapView detects a tap not handled elsewhere by other gesture recognizers.
     */
    @objc func didReceiveTap(sender: UITapGestureRecognizer) {
        guard let routes = routes, let tapPoint = sender.point else { return }
        
        let waypointTest = legSeparatingWaypoints(on: routes, closeTo: tapPoint)
        if let selected = waypointTest?.first {
            delegate?.navigationMapView(self, didSelect: selected)
            return
        }
        
        route(at: tapPoint)  { [weak self] (routeFoundByPoint) in
            guard !routeFoundByPoint, let self = self else { return }
            if let routes = self.routes(closeTo: tapPoint),
               let selectedRoute = routes.first {
                self.delegate?.navigationMapView(self, didSelect: selectedRoute)
            } else if let alternativeRoutes = self.continuousAlternativeRoutes(closeTo: tapPoint),
                      let selectedRoute = alternativeRoutes.first {
                self.delegate?.navigationMapView(self, didSelect: selectedRoute)
            }
        }
    }
    
    func route(at point: CGPoint, completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        var routeFoundByPoint: Bool = false
        let layerIds: [String] = [
            LayerIdentifier.routeDurationAnnotationsLayer,
            LayerIdentifier.continuousAlternativeRoutesDurationAnnotationsLayer]
    
        for layerId in layerIds {
            group.enter()
            let options = RenderedQueryOptions(layerIds: [layerId], filter: nil)
            routeIndexFromMapQuery(with: options, at: point) { [weak self] (routeIndex) in
                defer { group.leave() }
                guard let self = self, let routeIndex = routeIndex else { return }
                if layerId == layerIds.first {
                    if let route = self.routes?[safe: routeIndex] {
                        routeFoundByPoint = true
                        self.delegate?.navigationMapView(self, didSelect: route)
                    }
                } else if let alternativeRoute = self.continuousAlternatives?[safe: routeIndex] {
                    routeFoundByPoint = true
                    self.delegate?.navigationMapView(self, didSelect: alternativeRoute)
                }
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            completion(routeFoundByPoint)
        }
    }
    
    func routeIndexFromMapQuery(with options: RenderedQueryOptions, at point: CGPoint, completion: @escaping (Int?) -> Void) {
        mapView.mapboxMap.queryRenderedFeatures(with: [point], options: options) { result in
            if case .success(let queriedFeatures) = result,
               let indexValue = queriedFeatures.first?.feature.properties?["routeIndex"] as? JSONValue,
               case .number(let routeIndex) = indexValue {
                completion(Int(routeIndex))
            } else {
                completion(nil)
            }
        }
    }
    
    func makeGestureRecognizersResetFrameRate() {
        for gestureRecognizer in gestureRecognizers ?? [] {
            gestureRecognizer.addTarget(self, action: #selector(resetFrameRate(_:)))
        }
    }
    
    /**
     Returns a list of waypoints, that are located on the routes with more than one leg and are
     close to a certain point and are within threshold distance defined in
     `NavigationMapView.tapGestureDistanceThreshold`.
     
     - parameter routes: List of the routes.
     - parameter point: Point on the screen.
     - returns: List of the waypoints, which were found. If no routes have more than one leg, `nil`
     will be returned.
     */
    public func legSeparatingWaypoints(on routes: [Route], closeTo point: CGPoint) -> [Waypoint]? {
        // In case if route does not contain more than one leg - do nothing.
        let multipointRoutes = routes.filter({ $0.legs.count > 1 })
        guard multipointRoutes.count > 0 else { return nil }
        
        let waypoints = multipointRoutes.compactMap { route in
            route.legs.dropLast().compactMap({ $0.destination })
        }.flatMap({ $0 })
        
        // Sort the array in order of closest to tap.
        let tapCoordinate = mapView.mapboxMap.coordinate(for: point)
        let closest = waypoints.sorted { (left, right) -> Bool in
            let leftDistance = left.coordinate.projectedDistance(to: tapCoordinate)
            let rightDistance = right.coordinate.projectedDistance(to: tapCoordinate)
            return leftDistance < rightDistance
        }
        
        // Filter to see which ones are under threshold.
        let candidates = closest.filter({
            let coordinatePoint = mapView.mapboxMap.point(for: $0.coordinate)
            
            return coordinatePoint.distance(to: point) < tapGestureDistanceThreshold
        })
        
        return candidates
    }
    
    /**
     Returns a list of the routes, that are close to a certain point and are within threshold distance
     defined in `NavigationMapView.tapGestureDistanceThreshold`.
     
     - parameter point: Point on the screen.
     - returns: List of the routes, which were found. If there are no routes on the map view `nil`
     will be returned.
     */
    public func routes(closeTo point: CGPoint) -> [Route]? {
        // Filter routes with at least 2 coordinates.
        guard let routes = routes?.filter({ $0.shape?.coordinates.count ?? 0 > 1 }) else { return nil }
        
        // Sort routes by closest distance to tap gesture.
        let tapCoordinate = mapView.mapboxMap.coordinate(for: point)
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
    
    // MARK: Configuring Cache and Tiles Storage
    
    /**
     A `TileStore` instance used by map view.
     */
    open var mapTileStore: TileStore? {
        mapView.mapboxMap.resourceOptions.tileStore
    }
    
    /**
     A manager object, used to init and maintain predictive caching.
     */
    private(set) var predictiveCacheManager: PredictiveCacheManager?
    
    private var predictiveCacheMapObserver: MapboxMaps.Cancelable? = nil

    /**
     Setups the Predictive Caching mechanism using provided Options.
     
     This will handle all the required manipulations to enable the feature and maintain it during the navigations. Once enabled, it will be present as long as `NavigationMapView` is retained.
     
     - parameter options: options, controlling caching parameters like area radius and concurrent downloading threads.
     */
    public func enablePredictiveCaching(options predictiveCacheOptions: PredictiveCacheOptions) {
        predictiveCacheMapObserver?.cancel()

        let cacheMapOptions = createCacheMapOptions(predictiveCacheOptions: predictiveCacheOptions)
        self.predictiveCacheManager = PredictiveCacheManager(predictiveCacheOptions: predictiveCacheOptions,
                                                             cacheMapOptions: cacheMapOptions)
        self.predictiveCacheMapObserver = mapView.mapboxMap?.onEvery(event: .styleLoaded) { [weak self] _ in
            guard let self = self else { return }

            let cacheMapOptions = self.createCacheMapOptions(predictiveCacheOptions: predictiveCacheOptions)
            self.predictiveCacheManager?.updateMapControllers(cacheMapOptions: cacheMapOptions)
        }
    }

    private func createCacheMapOptions(predictiveCacheOptions: PredictiveCacheOptions) -> PredictiveCacheManager.CacheMapOptions? {
        let tileStore = mapTileStore ?? NavigationSettings.shared.tileStoreConfiguration.mapLocation?.tileStore
        let mapsOptions = predictiveCacheOptions.predictiveCacheMapsOptions
        let tilesetDescriptor = self.mapView.tilesetDescriptor(zoomRange: mapsOptions.zoomRange)
        guard let tileStore = tileStore, let tilesetDescriptor = tilesetDescriptor else { return nil }

        return (tileStore: tileStore, tilesetDescriptor: tilesetDescriptor)
    }
    
    // MARK: Interacting with Camera
    
    struct FrameIntervalOptions {
        static let durationUntilNextManeuver: TimeInterval = 7
        static let durationSincePreviousManeuver: TimeInterval = 3
        static let defaultFramesPerSecond = 30
        static let pluggedInFramesPerSecond = 60
    }
    
    /**
     The minimum preferred frames per second at which to render map animations.
     
     This property takes effect when the application has limited resources for animation, such as when the device is running on battery power. By default, this property is set to `PreferredFPS.normal`.
     */
    public var minimumFramesPerSecond = FrameIntervalOptions.defaultFramesPerSecond
    
    /**
     `NavigationCamera`, which allows to control camera states.
     */
    public private(set) var navigationCamera: NavigationCamera!
    
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
    
    @objc private func resetFrameRate(_ sender: UIGestureRecognizer) {
        mapView.preferredFramesPerSecond = NavigationMapView.FrameIntervalOptions.defaultFramesPerSecond
    }
    
    func fitCamera(to routes: [Route],
                   routesPresentationStyle: RoutesPresentationStyle = .all(),
                   animated: Bool = false,
                   duration: TimeInterval = 1.0,
                   completion: AnimationCompletionHandler? = nil) {
        let geometry: Geometry
        let customCameraOptions: MapboxMaps.CameraOptions?
        
        switch routesPresentationStyle {
        case .single(cameraOptions: let cameraOptions):
            geometry = .lineString(LineString(routes.first?.shape?.coordinates ?? []))
            customCameraOptions = cameraOptions
        case .all(shouldFit: let shouldFit, cameraOptions: let cameraOptions):
            geometry = shouldFit ? .multiLineString(MultiLineString(routes.compactMap({ $0.shape?.coordinates }))) : .lineString(LineString(routes.first?.shape?.coordinates ?? []))
            customCameraOptions = cameraOptions
        }
        
        let edgeInsets = safeArea + UIEdgeInsets.centerEdgeInsets
        let bearing = customCameraOptions.flatMap({ $0.bearing }).map({ CGFloat($0) })
        if let cameraOptions = mapView?.mapboxMap.camera(for: geometry,
                                                         padding: customCameraOptions?.padding ?? edgeInsets,
                                                         bearing: bearing,
                                                         pitch: customCameraOptions?.pitch) {
            mapView?.camera.ease(to: cameraOptions,
                                 duration: animated ? duration : 0.0,
                                 completion: { animatingPosition in
                completion?(animatingPosition)
            })
        }
    }
    
    /**
     Sets initial `CameraOptions` for specific coordinate.
     
     - parameter coordinate: Coordinate, where `MapView` will be centered.
     */
    func setInitialCamera(_ coordinate: CLLocationCoordinate2D) {
        guard let navigationViewportDataSource = navigationCamera.viewportDataSource as? NavigationViewportDataSource else { return }
        layoutIfNeeded() // mapView isn't able to properly convert coordinates before layout.
        mapView.mapboxMap.setCamera(to: CameraOptions(center: coordinate,
                                                      zoom: CGFloat(navigationViewportDataSource.options.followingCameraOptions.zoomRange.upperBound)))
        moveUserLocation(to: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
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
