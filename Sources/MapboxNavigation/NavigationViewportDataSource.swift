import MapboxMaps
import MapboxCoreNavigation
import Turf
import MapboxDirections

/**
 Class, which conforms to `ViewportDataSource` protocol and provides default implementation of it.
 */
public class NavigationViewportDataSource: ViewportDataSource {
    
    /**
     Delegate, which is used to notify `NavigationCamera` regarding upcoming `CameraOptions`
     related changes.
     */
    public weak var delegate: ViewportDataSourceDelegate?
    
    /**
     `CameraOptions`, which are used on iOS when transitioning to `NavigationCameraState.following` or
     for continuous updates when already in `NavigationCameraState.following` state.
     */
    public var followingMobileCamera: CameraOptions = CameraOptions()
    
    /**
     `CameraOptions`, which are used on CarPlay when transitioning to `NavigationCameraState.following` or
     for continuous updates when already in `NavigationCameraState.following` state.
     */
    public var followingCarPlayCamera: CameraOptions = CameraOptions()
    
    /**
     `CameraOptions`, which are used on iOS when transitioning to `NavigationCameraState.overview` or
     for continuous updates when already in `NavigationCameraState.overview` state.
     */
    public var overviewMobileCamera: CameraOptions = CameraOptions()
    
    /**
     `CameraOptions`, which are used on CarPlay when transitioning to `NavigationCameraState.overview` or
     for continuous updates when already in `NavigationCameraState.overview` state.
     */
    public var overviewCarPlayCamera: CameraOptions = CameraOptions()
    
    /**
     Options, which give the ability to control whether certain `CameraOptions` will be generated
     by `NavigationViewportDataSource` or can be provided by user directly.
     */
    public var options: NavigationViewportDataSourceOptions = NavigationViewportDataSourceOptions()
    
    /**
     Value of default viewport padding.
     */
    var viewportPadding: UIEdgeInsets = .zero
    
    weak var mapView: MapView?
    
    var viewportDataSourceType: ViewportDataSourceType = .passive
    
    var heading: CLHeading?
    
    // MARK: Initializer Methods
    
    /**
     Initializer of `NavigationViewportDataSource` object.
     
     - parameter mapView: Instance of `MapView`, which is going to be used for several operations,
     which includes (but not limited to) subscription to raw location updates via `LocationConsumer`
     (in case if `viewportDataSourceType` was set to `.raw`). `MapView` will be weakly stored by
     `NavigationViewportDataSource`.
     - parameter viewportDataSourceType: Type of locations, which will be used to prepare `CameraOptions`.
     */
    public required init(_ mapView: MapView, viewportDataSourceType: ViewportDataSourceType = .passive) {
        self.mapView = mapView
        self.viewportDataSourceType = viewportDataSourceType
        
        subscribeForNotifications()
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    // MARK: Notifications Observer Methods
    
    func subscribeForNotifications() {
        switch viewportDataSourceType {
        case .raw:
            mapView?.location.addLocationConsumer(newConsumer: self)
        case .passive:
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(progressDidChange(_:)),
                                                   name: .passiveLocationManagerDidUpdate,
                                                   object: nil)
        case .active:
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(progressDidChange(_:)),
                                                   name: .routeControllerProgressDidChange,
                                                   object: nil)
        }
    }
    
    func unsubscribeFromNotifications() {
        switch viewportDataSourceType {
        case .raw:
            mapView?.location.removeLocationConsumer(consumer: self)
        case .passive:
            NotificationCenter.default.removeObserver(self,
                                                      name: .passiveLocationManagerDidUpdate,
                                                      object: nil)
        case .active:
            NotificationCenter.default.removeObserver(self,
                                                      name: .routeControllerProgressDidChange,
                                                      object: nil)
        }
    }
    
    @objc func progressDidChange(_ notification: NSNotification) {
        let passiveLocation = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.locationKey] as? CLLocation
        let activeLocation = notification.userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation
        let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
        heading = notification.userInfo?[RouteController.NotificationUserInfoKey.headingKey] as? CLHeading
        
        let cameraOptions = self.cameraOptions(passiveLocation: passiveLocation,
                                               activeLocation: activeLocation,
                                               routeProgress: routeProgress)
        delegate?.viewportDataSource(self, didUpdate: cameraOptions)
        
        NotificationCenter.default.post(name: .navigationCameraViewportDidChange, object: self, userInfo: [
            NavigationCamera.NotificationUserInfoKey.cameraOptions: cameraOptions
        ])
    }
    
    // MARK: CameraOptions Methods
    
    func cameraOptions(_ rawLocation: CLLocation? = nil,
                       passiveLocation: CLLocation? = nil,
                       activeLocation: CLLocation? = nil,
                       routeProgress: RouteProgress? = nil) -> [String: CameraOptions] {
        updateFollowingCamera(rawLocation,
                              passiveLocation: passiveLocation,
                              activeLocation: activeLocation,
                              routeProgress: routeProgress)
        
        // In active guidance navigation, camera in overview mode is relevant, during free-drive
        // navigation it's not used.
        updateOverviewCamera(activeLocation,
                             routeProgress: routeProgress)
        
        let cameraOptions = [
            CameraOptions.followingMobileCamera: followingMobileCamera,
            CameraOptions.overviewMobileCamera: overviewMobileCamera,
            CameraOptions.followingCarPlayCamera: followingCarPlayCamera,
            CameraOptions.overviewCarPlayCamera: overviewCarPlayCamera
        ]
        
        return cameraOptions
    }
    
    func updateFollowingCamera(_ rawLocation: CLLocation? = nil,
                               passiveLocation: CLLocation? = nil,
                               activeLocation: CLLocation? = nil,
                               routeProgress: RouteProgress? = nil) {
        guard let mapView = mapView else { return }
        
        let followingCameraOptions = options.followingCameraOptions
        
        if let location = rawLocation ?? passiveLocation {
            if followingCameraOptions.centerUpdatesAllowed {
                followingMobileCamera.center = location.coordinate
                followingCarPlayCamera.center = location.coordinate
            }
            
            if followingCameraOptions.zoomUpdatesAllowed {
                let altitude = 4000.0
                let zoom = CGFloat(ZoomLevelForAltitude(altitude,
                                                        mapView.cameraState.pitch,
                                                        location.coordinate.latitude,
                                                        mapView.bounds.size))
                
                followingMobileCamera.zoom = zoom
                followingCarPlayCamera.zoom = zoom
            }
            
            if followingCameraOptions.bearingUpdatesAllowed {
                followingMobileCamera.bearing = 0.0
                followingCarPlayCamera.bearing = 0.0
            }
            
            followingMobileCamera.anchor = mapView.center
            followingCarPlayCamera.anchor = mapView.center
            
            if followingCameraOptions.pitchUpdatesAllowed {
                followingMobileCamera.pitch = 0.0
                followingCarPlayCamera.pitch = 0.0
            }
            
            if followingCameraOptions.paddingUpdatesAllowed {
                followingMobileCamera.padding = .zero
                followingCarPlayCamera.padding = .zero
            }
            
            return
        }
        
        if let location = activeLocation, let routeProgress = routeProgress {
            var compoundManeuvers: [[CLLocationCoordinate2D]] = []
            let geometryFramingAfterManeuver = followingCameraOptions.geometryFramingAfterManeuver
            let pitchСoefficient = self.pitchСoefficient(routeProgress, currentCoordinate: location.coordinate)
            let pitch = followingCameraOptions.defaultPitch * pitchСoefficient
            var carPlayCameraPadding = mapView.safeArea + UIEdgeInsets.centerEdgeInsets
            
            // Bottom of the viewport on CarPlay should be placed at the same level with
            // trip estimate view.
            carPlayCameraPadding.bottom += 65.0
            
            if geometryFramingAfterManeuver.enabled {
                let stepIndex = routeProgress.currentLegProgress.stepIndex
                let nextStepIndex = min(stepIndex + 1, routeProgress.currentLeg.steps.count - 1)
                let stepCoordinatesAfterCurrentStep = routeProgress.currentLeg.steps[nextStepIndex...]
                    .map({ $0.shape?.coordinates })
                
                for stepCoordinates in stepCoordinatesAfterCurrentStep {
                    guard let stepCoordinates = stepCoordinates,
                          let distance = stepCoordinates.distance() else { continue }
                    
                    if distance > 0.0 && distance < geometryFramingAfterManeuver.distanceToCoalesceCompoundManeuvers {
                        compoundManeuvers.append(stepCoordinates)
                    } else {
                        compoundManeuvers.append(stepCoordinates.trimmed(distance: geometryFramingAfterManeuver.distanceToFrameAfterManeuver))
                        break
                    }
                }
            }
            
            let coordinatesForManeuverFraming = compoundManeuvers.reduce([], +)
            let coordinatesToManeuver = routeProgress.currentLegProgress.currentStep.shape?.coordinates.sliced(from: location.coordinate) ?? []
            
            if options.followingCameraOptions.centerUpdatesAllowed {
                var center = location.coordinate
                if let boundingBox = BoundingBox(from: coordinatesToManeuver + coordinatesForManeuverFraming) {
                    let coordinates = [
                        center,
                        [boundingBox.northEast, boundingBox.southWest].centerCoordinate
                    ]
                    
                    let centerLineString = LineString(coordinates)
                    let centerLineStringTotalDistance = centerLineString.distance() ?? 0.0
                    let centerCoordDistance = centerLineStringTotalDistance * (1 - pitchСoefficient)
                    if let adjustedCenter = centerLineString.coordinateFromStart(distance: centerCoordDistance) {
                        center = adjustedCenter
                    }
                }
                
                followingMobileCamera.center = center
                followingCarPlayCamera.center = center
            }
            
            let lookaheadDistance = self.lookaheadDistance(routeProgress)
            
            if options.followingCameraOptions.zoomUpdatesAllowed {
                let defaultZoomLevel = 12.0
                
                let coordinatesForIntersections = coordinatesToManeuver.sliced(from: nil,
                                                                               to: LineString(coordinatesToManeuver).coordinateFromStart(distance: lookaheadDistance))
                
                let followingMobileCameraZoom = zoom(coordinatesForIntersections,
                                                     pitch: pitch,
                                                     maxPitch: followingCameraOptions.defaultPitch,
                                                     edgeInsets: viewportPadding,
                                                     defaultZoomLevel: defaultZoomLevel,
                                                     maxZoomLevel: followingCameraOptions.zoomRange.upperBound,
                                                     minZoomLevel: followingCameraOptions.zoomRange.lowerBound)
                
                followingMobileCamera.zoom = followingMobileCameraZoom
                
                let followingCarPlayCameraZoom = zoom(coordinatesForIntersections,
                                                      pitch: pitch,
                                                      maxPitch: followingCameraOptions.defaultPitch,
                                                      edgeInsets: carPlayCameraPadding,
                                                      defaultZoomLevel: defaultZoomLevel,
                                                      maxZoomLevel: followingCameraOptions.zoomRange.upperBound,
                                                      minZoomLevel: followingCameraOptions.zoomRange.lowerBound)
                followingCarPlayCamera.zoom = followingCarPlayCameraZoom
            }
            
            if options.followingCameraOptions.bearingUpdatesAllowed {
                var bearing = location.course
                let lookaheadDistance = self.lookaheadDistance(routeProgress)
                let distance = fmax(lookaheadDistance, geometryFramingAfterManeuver.enabled
                                    ? geometryFramingAfterManeuver.distanceToCoalesceCompoundManeuvers
                                    : 0.0)
                let coordinatesForIntersections = coordinatesToManeuver.sliced(from: nil,
                                                                               to: LineString(coordinatesToManeuver).coordinateFromStart(distance: distance))
                
                bearing = self.bearing(location.course, coordinatesToManeuver: coordinatesForIntersections)
                
                var headingDirection: CLLocationDirection?
                let isWalking = routeProgress.currentLegProgress.currentStep.transportType == .walking
                if isWalking {
                    if let trueHeading = heading?.trueHeading, trueHeading >= 0 {
                        headingDirection = trueHeading
                    } else if let magneticHeading = heading?.magneticHeading, magneticHeading >= 0 {
                        headingDirection = magneticHeading
                    } else {
                        headingDirection = bearing
                    }
                }
                
                followingMobileCamera.bearing = !isWalking ? bearing : headingDirection
                followingCarPlayCamera.bearing = bearing
            }
            
            let followingMobileCameraAnchor = anchor(pitchСoefficient,
                                                     bounds: mapView.bounds,
                                                     edgeInsets: viewportPadding)
            
            followingMobileCamera.anchor = followingMobileCameraAnchor
            
            let followingCarPlayCameraAnchor = anchor(pitchСoefficient,
                                                      bounds: mapView.bounds,
                                                      edgeInsets: carPlayCameraPadding)
            
            followingCarPlayCamera.anchor = followingCarPlayCameraAnchor
            
            if options.followingCameraOptions.pitchUpdatesAllowed {
                followingMobileCamera.pitch = CGFloat(pitch)
                followingCarPlayCamera.pitch = CGFloat(pitch)
            }
            
            if options.followingCameraOptions.paddingUpdatesAllowed {
                followingMobileCamera.padding = UIEdgeInsets(top: followingMobileCameraAnchor.y,
                                                             left: viewportPadding.left,
                                                             bottom: UIScreen.main.bounds.height - followingMobileCameraAnchor.y + 1.0,
                                                             right: viewportPadding.right)
                
                if let mainCarPlayScreen = UIScreen.mainCarPlay {
                    followingCarPlayCamera.padding = UIEdgeInsets(top: followingCarPlayCameraAnchor.y,
                                                                  left: carPlayCameraPadding.left,
                                                                  bottom: mainCarPlayScreen.bounds.height - followingCarPlayCameraAnchor.y + 1.0,
                                                                  right: carPlayCameraPadding.right)
                } else {
                    followingCarPlayCamera.padding = carPlayCameraPadding
                }
            }
        }
    }
    
    func updateOverviewCamera(_ activeLocation: CLLocation?, routeProgress: RouteProgress?) {
        guard let mapView = mapView,
              let coordinate = activeLocation?.coordinate,
              let routeProgress = routeProgress else { return }
        
        let stepIndex = routeProgress.currentLegProgress.stepIndex
        let nextStepIndex = min(stepIndex + 1, routeProgress.currentLeg.steps.count - 1)
        let coordinatesAfterCurrentStep = routeProgress.currentLeg.steps[nextStepIndex...]
            .map({ $0.shape?.coordinates })
        let untraveledCoordinatesOnCurrentStep = routeProgress.currentLegProgress.currentStep.shape?.coordinates.sliced(from: coordinate) ?? []
        let remainingCoordinatesOnRoute = coordinatesAfterCurrentStep.flatten() + untraveledCoordinatesOnCurrentStep
        let carPlayCameraPadding = mapView.safeArea + UIEdgeInsets.centerEdgeInsets
        let overviewCameraOptions = options.overviewCameraOptions
        
        if overviewCameraOptions.pitchUpdatesAllowed {
            overviewMobileCamera.pitch = 0.0
            overviewCarPlayCamera.pitch = 0.0
        }
        
        if overviewCameraOptions.centerUpdatesAllowed {
            if let boundingBox = BoundingBox(from: remainingCoordinatesOnRoute) {
                let center = [
                    boundingBox.southWest,
                    boundingBox.northEast
                ].centerCoordinate
                
                overviewMobileCamera.center = center
                overviewCarPlayCamera.center = center
            }
        }
        
        if overviewCameraOptions.zoomUpdatesAllowed {
            overviewMobileCamera.zoom = zoom(remainingCoordinatesOnRoute,
                                             edgeInsets: viewportPadding,
                                             maxZoomLevel: overviewCameraOptions.maximumZoomLevel)
            
            overviewCarPlayCamera.zoom = zoom(remainingCoordinatesOnRoute,
                                              edgeInsets: carPlayCameraPadding,
                                              maxZoomLevel: overviewCameraOptions.maximumZoomLevel)
        }
        
        overviewMobileCamera.anchor = anchor(bounds: mapView.bounds,
                                             edgeInsets: viewportPadding)
        
        overviewCarPlayCamera.anchor = anchor(bounds: mapView.bounds,
                                              edgeInsets: carPlayCameraPadding)
        
        if overviewCameraOptions.bearingUpdatesAllowed {
            // In case if `NavigationCamera` is already in `NavigationCameraState.overview` value
            // of bearing will be also ignored.
            let bearing = 0.0
            
            var headingDirection: CLLocationDirection?
            let isWalking = routeProgress.currentLegProgress.currentStep.transportType == .walking
            if isWalking {
                if let trueHeading = heading?.trueHeading, trueHeading >= 0 {
                    headingDirection = trueHeading
                } else if let magneticHeading = heading?.magneticHeading, magneticHeading >= 0 {
                    headingDirection = magneticHeading
                } else {
                    headingDirection = bearing
                }
            }
            
            overviewMobileCamera.bearing = !isWalking ? bearing : headingDirection
            overviewCarPlayCamera.bearing = bearing
        }
        
        if overviewCameraOptions.paddingUpdatesAllowed {
            overviewMobileCamera.padding = viewportPadding
            overviewCarPlayCamera.padding = carPlayCameraPadding
        }
    }
    
    func bearing(_ initialBearing: CLLocationDirection,
                 coordinatesToManeuver: [CLLocationCoordinate2D]? = nil) -> CLLocationDirection {
        var bearing = initialBearing
        
        if let coordinates = coordinatesToManeuver,
           let firstCoordinate = coordinates.first,
           let lastCoordinate = coordinates.last {
            let directionToManeuver = firstCoordinate.direction(to: lastCoordinate)
            let directionDiff = directionToManeuver.shortestRotation(angle: initialBearing)
            let bearingSmoothing = options.followingCameraOptions.bearingSmoothing
            let bearingMaxDiff = bearingSmoothing.enabled ? bearingSmoothing.maximumBearingSmoothingAngle : 0.0
            if fabs(directionDiff) > bearingMaxDiff {
                bearing += bearingMaxDiff * (directionDiff < 0.0 ? -1.0 : 1.0)
            } else {
                bearing = firstCoordinate.direction(to: lastCoordinate)
            }
        }
        
        let mapViewBearing = Double(mapView?.cameraState.bearing ?? 0.0)
        return mapViewBearing + bearing.shortestRotation(angle: mapViewBearing)
    }
    
    func zoom(_ coordinates: [CLLocationCoordinate2D],
              pitch: Double = 0.0,
              maxPitch: Double = 0.0,
              edgeInsets: UIEdgeInsets = .zero,
              defaultZoomLevel: Double = 12.0,
              maxZoomLevel: Double = 22.0,
              minZoomLevel: Double = 2.0) -> CGFloat {
        guard let mapView = mapView,
              let boundingBox = BoundingBox(from: coordinates) else { return CGFloat(defaultZoomLevel) }
        
        let mapViewInsetWidth = mapView.bounds.size.width - edgeInsets.left - edgeInsets.right
        let mapViewInsetHeight = mapView.bounds.size.height - edgeInsets.top - edgeInsets.bottom
        let widthDelta = mapViewInsetHeight * 2 - mapViewInsetWidth
        let pitchDelta = CGFloat(pitch / maxPitch) * widthDelta
        let widthWithPitchEffect = CGFloat(mapViewInsetWidth + CGFloat(pitchDelta.isNaN ? 0.0 : pitchDelta))
        let heightWithPitchEffect = CGFloat(mapViewInsetHeight + mapViewInsetHeight * CGFloat(sin(pitch * .pi / 180.0)) * 1.25)
        let zoomLevel = boundingBox.zoomLevel(fitTo: CGSize(width: widthWithPitchEffect, height: heightWithPitchEffect))
        
        return CGFloat(max(min(zoomLevel, maxZoomLevel), minZoomLevel))
    }
    
    func anchor(_ pitchСoefficient: Double = 0.0,
                bounds: CGRect = .zero,
                edgeInsets: UIEdgeInsets = .zero) -> CGPoint {
        let xCenter = max(((bounds.size.width - edgeInsets.left - edgeInsets.right) / 2.0) + edgeInsets.left, 0.0)
        let height = (bounds.size.height - edgeInsets.top - edgeInsets.bottom)
        let yCenter = max((height / 2.0) + edgeInsets.top, 0.0)
        let yOffsetCenter = max((height / 2.0) - 7.0, 0.0) * CGFloat(pitchСoefficient) + yCenter
        
        return CGPoint(x: xCenter, y: yOffsetCenter)
    }
    
    func pitchСoefficient(_ routeProgress: RouteProgress,
                          currentCoordinate: CLLocationCoordinate2D) -> Double {
        let defaultPitchСoefficient = 1.0
        let pitchNearManeuver = options.followingCameraOptions.pitchNearManeuver
        if pitchNearManeuver.enabled {
            var shouldIgnoreManeuver = false
            if let upcomingStep = routeProgress.currentLeg.steps[safe: routeProgress.currentLegProgress.stepIndex + 1] {
                if routeProgress.currentLegProgress.stepIndex == routeProgress.currentLegProgress.leg.steps.count - 2 {
                    shouldIgnoreManeuver = true
                }
                
                let maneuvers: [ManeuverType] = [.continue, .merge, .takeOnRamp, .takeOffRamp, .reachFork]
                if maneuvers.contains(upcomingStep.maneuverType) {
                    shouldIgnoreManeuver = true
                }
            }
            
            let coordinatesToManeuver = routeProgress.currentLegProgress.currentStep.shape?.coordinates.sliced(from: currentCoordinate) ?? []
            if let distanceToManeuver = LineString(coordinatesToManeuver).distance(),
               distanceToManeuver <= pitchNearManeuver.triggerDistanceToManeuver,
               !shouldIgnoreManeuver {
                return min(distanceToManeuver, pitchNearManeuver.triggerDistanceToManeuver) / pitchNearManeuver.triggerDistanceToManeuver
            }
        }
        
        return defaultPitchСoefficient
    }
    
    /**
     Calculates lookahead distance based on current `RouteProgress` and `IntersectionDensity` coefficients.
     
     Lookahead distance value will be influenced by both `IntersectionDensity.minimumDistanceBetweenIntersections` and
     `IntersectionDensity.averageDistanceMultiplier`.
     
     - parameter routeProgress: Current `RouteProgress`.
     - returns: Lookahead distance.
     */
    func lookaheadDistance(_ routeProgress: RouteProgress) -> CLLocationDistance {
        let intersectionDensity = options.followingCameraOptions.intersectionDensity
        let averageIntersectionDistances = routeProgress.route.legs.map { (leg) -> [CLLocationDistance] in
            return leg.steps.map { (step) -> CLLocationDistance in
                if let firstStepCoordinate = step.shape?.coordinates.first,
                   let lastStepCoordinate = step.shape?.coordinates.last {
                    let intersectionLocations = [firstStepCoordinate] + (step.intersections?.map({ $0.location }) ?? []) + [lastStepCoordinate]
                    let intersectionDistances = intersectionLocations[1...].enumerated().map({ (index, intersection) -> CLLocationDistance in
                        return intersection.distance(to: intersectionLocations[index])
                    })
                    let filteredIntersectionDistances = intersectionDensity.enabled
                    ? intersectionDistances.filter { $0 > intersectionDensity.minimumDistanceBetweenIntersections }
                    : intersectionDistances
                    let averageIntersectionDistance = filteredIntersectionDistances.reduce(0.0, +) / Double(filteredIntersectionDistances.count)
                    return averageIntersectionDistance
                }
                
                return 0.0
            }
        }
        
        let averageDistanceMultiplier = intersectionDensity.enabled ? intersectionDensity.averageDistanceMultiplier : 1.0
        let currentRouteLegIndex = routeProgress.legIndex
        let currentRouteStepIndex = routeProgress.currentLegProgress.stepIndex
        let lookaheadDistance = averageIntersectionDistances[currentRouteLegIndex][currentRouteStepIndex] * averageDistanceMultiplier
        
        return lookaheadDistance
    }
}

// MARK: LocationConsumer Delegate

extension NavigationViewportDataSource: LocationConsumer {
    
    public var shouldTrackLocation: Bool {
        get {
            return true
        }
        set(newValue) {
            // No-op
        }
    }
    
    public func locationUpdate(newLocation: Location) {
        let location = CLLocation(latitude: newLocation.coordinate.latitude,
                                  longitude: newLocation.coordinate.longitude)
        let cameraOptions = self.cameraOptions(location)
        delegate?.viewportDataSource(self, didUpdate: cameraOptions)
    }
}
