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
    public var delegate: ViewportDataSourceDelegate?
    
    /**
     `CameraOptions`, which are used on iOS when transitioning to `NavigationCameraState.following` or
     for continuous updates when already in `NavigationCameraState.following` state.
     */
    public var followingMobileCamera: CameraOptions = CameraOptions()
    
    /**
     `CameraOptions`, which are used on CarPlay when transitioning to `NavigationCameraState.following` or
     for continuous updates when already in `NavigationCameraState.following` state.
     */
    public var followingHeadUnitCamera: CameraOptions = CameraOptions()
    
    /**
     `CameraOptions`, which are used on iOS when transitioning to `NavigationCameraState.overview` or
     for continuous updates when already in `NavigationCameraState.overview` state.
     */
    public var overviewMobileCamera: CameraOptions = CameraOptions()
    
    /**
     `CameraOptions`, which are used on CarPlay when transitioning to `NavigationCameraState.overview` or
     for continuous updates when already in `NavigationCameraState.overview` state.
     */
    public var overviewHeadUnitCamera: CameraOptions = CameraOptions()
    
    /**
     Value of maximum pitch, which will be taken into account when preparing `CameraOption`s during
     active guidance navigation.
     */
    public var maximumPitch: Double = 45.0
    
    /**
     Value of default viewport padding.
     */
    var viewportPadding: UIEdgeInsets = .zero
    
    weak var mapView: MapView?
    
    // MARK: - Initializer methods
    
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
        
        subscribeForNotifications(viewportDataSourceType)
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    // MARK: - Notifications observer methods
    
    func subscribeForNotifications(_ viewportDataSourceType: ViewportDataSourceType = .passive) {
        switch viewportDataSourceType {
        case .raw:
            self.mapView?.locationManager.addLocationConsumer(newConsumer: self)
        case .passive:
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(progressDidChange(_:)),
                                                   name: .passiveLocationDataSourceDidUpdate,
                                                   object: nil)
        case .active:
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(progressDidChange(_:)),
                                                   name: .routeControllerProgressDidChange,
                                                   object: nil)
        }
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerProgressDidChange,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .passiveLocationDataSourceDidUpdate,
                                                  object: nil)
    }
    
    @objc func progressDidChange(_ notification: NSNotification) {
        let passiveLocation = notification.userInfo?[PassiveLocationDataSource.NotificationUserInfoKey.locationKey] as? CLLocation
        let activeLocation = notification.userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation
        let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
        let cameraOptions = self.cameraOptions(passiveLocation: passiveLocation,
                                               activeLocation: activeLocation,
                                               routeProgress: routeProgress)
        delegate?.viewportDataSource(self, didUpdate: cameraOptions)
        
        NotificationCenter.default.post(name: .navigationCameraViewportDidChange, object: self, userInfo: [
            NavigationCamera.NotificationUserInfoKey.cameraOptionsKey: cameraOptions
        ])
    }
    
    // MARK: - CameraOptions methods
    
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
            CameraOptions.followingMobileCameraKey: followingMobileCamera,
            CameraOptions.overviewMobileCameraKey: overviewMobileCamera,
            CameraOptions.followingHeadUnitCameraKey: followingHeadUnitCamera,
            CameraOptions.overviewHeadUnitCameraKey: overviewHeadUnitCamera
        ]
        
        return cameraOptions
    }
    
    func updateFollowingCamera(_ rawLocation: CLLocation? = nil,
                               passiveLocation: CLLocation? = nil,
                               activeLocation: CLLocation? = nil,
                               routeProgress: RouteProgress? = nil) {
        guard let mapView = mapView else { return }
        
        if let location = rawLocation ?? passiveLocation {
            let followingWithoutRouteZoomLevel = CGFloat(14.0)
            
            followingMobileCamera.center = location.coordinate
            followingMobileCamera.zoom = followingWithoutRouteZoomLevel
            followingMobileCamera.bearing = 0.0
            followingMobileCamera.anchor = mapView.center
            followingMobileCamera.pitch = 0.0
            followingMobileCamera.padding = .zero
            
            followingHeadUnitCamera.center = location.coordinate
            followingHeadUnitCamera.zoom = followingWithoutRouteZoomLevel
            followingHeadUnitCamera.bearing = 0.0
            followingHeadUnitCamera.anchor = mapView.center
            followingHeadUnitCamera.pitch = 0.0
            followingHeadUnitCamera.padding = .zero
            
            return
        }
        
        if let location = activeLocation, let routeProgress = routeProgress {
            let pitchСoefficient = self.pitchСoefficient(routeProgress, currentCoordinate: location.coordinate)
            let pitch = maximumPitch * pitchСoefficient
            var compoundManeuvers: [[CLLocationCoordinate2D]] = []
            let stepIndex = routeProgress.currentLegProgress.stepIndex
            let nextStepIndex = min(stepIndex + 1, routeProgress.currentLeg.steps.count - 1)
            let coordinatesAfterCurrentStep = routeProgress.currentLeg.steps[nextStepIndex...].map({ $0.shape?.coordinates })
            for step in coordinatesAfterCurrentStep {
                guard let stepCoordinates = step, let distance = stepCoordinates.distance() else { continue }
                if distance > 0.0 && distance < 150.0 {
                    compoundManeuvers.append(stepCoordinates)
                } else {
                    let distanceAfterManeuverToIncludeInFraming = 30.0
                    compoundManeuvers.append(stepCoordinates.trimmed(distance: distanceAfterManeuverToIncludeInFraming))
                    break
                }
            }
            
            let coordinatesForManeuverFraming = compoundManeuvers.reduce([], +)
            let coordinatesToManeuver = routeProgress.currentLegProgress.currentStep.shape?.coordinates.sliced(from: location.coordinate) ?? []
            let centerLineString = LineString([location.coordinate, (coordinatesToManeuver + coordinatesForManeuverFraming).map({ mapView.point(for: $0) }).boundingBoxPoints.map({ mapView.coordinate(for: $0) }).centerCoordinate])
            let centerLineStringTotalDistance = centerLineString.distance() ?? 0.0
            let centerCoordDistance = centerLineStringTotalDistance * (1 - pitchСoefficient)
            
            var center: CLLocationCoordinate2D = location.coordinate
            if let adjustedCenter = centerLineString.coordinateFromStart(distance: centerCoordDistance) {
                center = adjustedCenter
            }
            
            let averageIntersectionDistances = routeProgress.route.legs.map { (leg) -> [CLLocationDistance] in
                return leg.steps.map { (step) -> CLLocationDistance in
                    if let firstStepCoordinate = step.shape?.coordinates.first,
                       let lastStepCoordinate = step.shape?.coordinates.last {
                        let intersectionLocations = [firstStepCoordinate] + (step.intersections?.map({ $0.location }) ?? []) + [lastStepCoordinate]
                        let intersectionDistances = intersectionLocations[1...].enumerated().map({ (index, intersection) -> CLLocationDistance in
                            return intersection.distance(to: intersectionLocations[index])
                        })
                        let filteredIntersectionDistances = intersectionDistances.filter { $0 > 20 }
                        let averageIntersectionDistance = filteredIntersectionDistances.reduce(0.0, +) / Double(filteredIntersectionDistances.count)
                        return averageIntersectionDistance
                    }
                    
                    return 0.0
                }
            }
            
            let currentRouteLegIndex = routeProgress.legIndex
            let currentRouteStepIndex = routeProgress.currentLegProgress.stepIndex
            let numberOfIntersections = 10
            let lookaheadDistance = averageIntersectionDistances[currentRouteLegIndex][currentRouteStepIndex] * Double(numberOfIntersections)
            let coordinatesForIntersections = coordinatesToManeuver.sliced(from: nil, to: LineString(coordinatesToManeuver).coordinateFromStart(distance: fmax(lookaheadDistance, 150.0)))
            let bearing = self.bearing(location.course, coordinatesToManeuver: coordinatesForIntersections)

            followingMobileCamera.center = center
            followingMobileCamera.zoom = CGFloat(self.zoom(coordinatesToManeuver + coordinatesForManeuverFraming,
                                                           pitch: pitch,
                                                           edgeInsets: viewportPadding,
                                                           defaultZoomLevel: 2.0,
                                                           maxZoomLevel: 16.35))
            followingMobileCamera.bearing = bearing
            followingMobileCamera.anchor = self.anchor(pitchСoefficient,
                                                       maxPitch: maximumPitch,
                                                       bounds: mapView.bounds,
                                                       edgeInsets: viewportPadding)
            followingMobileCamera.pitch = CGFloat(pitch)
            followingMobileCamera.padding = viewportPadding
            
            let headUnitCameraPadding = mapView.safeArea + UIEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
            followingHeadUnitCamera.center = center
            followingHeadUnitCamera.zoom = CGFloat(self.zoom(coordinatesToManeuver + coordinatesForManeuverFraming,
                                                             pitch: pitch,
                                                             edgeInsets: headUnitCameraPadding,
                                                             defaultZoomLevel: 2.0,
                                                             maxZoomLevel: 16.35))
            followingHeadUnitCamera.bearing = bearing
            followingHeadUnitCamera.anchor = self.anchor(pitchСoefficient,
                                                         maxPitch: maximumPitch,
                                                         bounds: mapView.bounds,
                                                         edgeInsets: headUnitCameraPadding)
            followingHeadUnitCamera.pitch = CGFloat(pitch)
            followingHeadUnitCamera.padding = headUnitCameraPadding
        }
    }
    
    func updateOverviewCamera(_ activeLocation: CLLocation?, routeProgress: RouteProgress?) {
        guard let mapView = mapView,
              let coordinate = activeLocation?.coordinate,
              let heading = activeLocation?.course,
              let routeProgress = routeProgress else { return }
        
        let stepIndex = routeProgress.currentLegProgress.stepIndex
        let nextStepIndex = min(stepIndex + 1, routeProgress.currentLeg.steps.count - 1)
        let coordinatesAfterCurrentStep = routeProgress.currentLeg.steps[nextStepIndex...].map({ $0.shape?.coordinates })
        let untraveledCoordinatesOnCurrentStep = routeProgress.currentLegProgress.currentStep.shape?.coordinates.sliced(from: coordinate) ?? []
        let remainingCoordinatesOnRoute = coordinatesAfterCurrentStep.flatten() + untraveledCoordinatesOnCurrentStep

        let center = remainingCoordinatesOnRoute.map({ mapView.point(for: $0) }).boundingBoxPoints.map({ mapView.coordinate(for: $0) }).centerCoordinate
        
        var zoom = self.zoom(remainingCoordinatesOnRoute,
                             edgeInsets: viewportPadding,
                             maxZoomLevel: 16.35)
        
        // In case if `NavigationCamera` is already in `NavigationCameraState.overview` value of bearing will be ignored.
        let bearing = CLLocationDirection(mapView.bearing) +
            heading.shortestRotation(angle: CLLocationDirection(mapView.bearing))
        
        overviewMobileCamera.pitch = 0.0
        overviewMobileCamera.center = center
        overviewMobileCamera.zoom = CGFloat(zoom)
        overviewMobileCamera.anchor = self.anchor(0.0,
                                                  maxPitch: maximumPitch,
                                                  bounds: mapView.bounds,
                                                  edgeInsets: viewportPadding)
        overviewMobileCamera.bearing = bearing
        overviewMobileCamera.padding = viewportPadding
        
        let headUnitCameraPadding = mapView.safeArea + UIEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)

        zoom = self.zoom(remainingCoordinatesOnRoute,
                         edgeInsets: headUnitCameraPadding,
                         maxZoomLevel: 16.35)
        
        overviewHeadUnitCamera.pitch = 0.0
        overviewHeadUnitCamera.center = center
        overviewHeadUnitCamera.zoom = CGFloat(zoom)
        overviewHeadUnitCamera.anchor = self.anchor(0.0,
                                                    maxPitch: maximumPitch,
                                                    bounds: mapView.bounds,
                                                    edgeInsets: headUnitCameraPadding)
        overviewHeadUnitCamera.bearing = bearing
        overviewHeadUnitCamera.padding = headUnitCameraPadding
    }
    
    func bearing(_ initialBearing: CLLocationDirection,
                 coordinatesToManeuver: [CLLocationCoordinate2D]? = nil) -> CLLocationDirection {
        var bearing = initialBearing

        if let coordinates = coordinatesToManeuver,
           let firstCoordinate = coordinates.first,
           let lastCoordinate = coordinates.last {
            let directionToManeuver = firstCoordinate.direction(to: lastCoordinate)
            let directionDiff = directionToManeuver.shortestRotation(angle: initialBearing)
            let bearingModeClampedManeuverMaxDiff = 20.0
            if fabs(directionDiff) > bearingModeClampedManeuverMaxDiff {
                bearing += bearingModeClampedManeuverMaxDiff * (directionDiff < 0.0 ? -1.0 : 1.0)
            } else {
                bearing = firstCoordinate.direction(to: lastCoordinate)
            }
        }
        
        let mapViewBearing = Double(mapView?.bearing ?? 0.0)
        return mapViewBearing + bearing.shortestRotation(angle: mapViewBearing)
    }
    
    func zoom(_ coordinates: [CLLocationCoordinate2D],
              pitch: Double = 0.0,
              edgeInsets: UIEdgeInsets = .zero,
              defaultZoomLevel: Double = 12.0,
              maxZoomLevel: Double = 22.0,
              minZoomLevel: Double = 2.0) -> Double {
        guard let mapView = mapView,
              let boundingBox = BoundingBox(from: coordinates) else { return defaultZoomLevel }
        
        let mapViewInsetWidth = mapView.bounds.size.width - edgeInsets.left - edgeInsets.right
        let mapViewInsetHeight = mapView.bounds.size.height - edgeInsets.top - edgeInsets.bottom
        let widthDelta = mapViewInsetHeight * 2 - mapViewInsetWidth
        let widthWithPitchEffect = CGFloat(mapViewInsetWidth + CGFloat(pitch / maximumPitch) * widthDelta)
        let heightWithPitchEffect = CGFloat(mapViewInsetHeight + mapViewInsetHeight * CGFloat(sin(pitch * .pi / 180.0)) * 1.25)
        let zoomLevel = boundingBox.zoomLevel(fitTo: CGSize(width: widthWithPitchEffect, height: heightWithPitchEffect))
        
        return max(min(zoomLevel, maxZoomLevel), minZoomLevel)
    }
    
    func anchor(_ pitchСoefficient: Double,
                maxPitch: Double,
                bounds: CGRect,
                edgeInsets: UIEdgeInsets) -> CGPoint {
        let xCenter = max(((bounds.size.width - edgeInsets.left - edgeInsets.right) / 2.0) + edgeInsets.left, 0.0)
        let height = (bounds.size.height - edgeInsets.top - edgeInsets.bottom)
        let yCenter = max((height / 2.0) + edgeInsets.top, 0.0)
        let yOffsetCenter = max((height / 2.0) - 7.0, 0.0) * CGFloat(pitchСoefficient) + yCenter
        
        return CGPoint(x: xCenter, y: yOffsetCenter)
    }
    
    func pitchСoefficient(_ routeProgress: RouteProgress, currentCoordinate: CLLocationCoordinate2D) -> Double {
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
        let defaultPitchСoefficient = 1.0
        guard let distance = LineString(coordinatesToManeuver).distance() else { return defaultPitchСoefficient }
        let pitchEffectDistanceStart: CLLocationDistance = 180.0
        let pitchEffectDistanceEnd: CLLocationDistance = 150.0
        let pitchСoefficient = shouldIgnoreManeuver
            ? defaultPitchСoefficient
            : (max(min(distance, pitchEffectDistanceStart), pitchEffectDistanceEnd) - pitchEffectDistanceEnd) / (pitchEffectDistanceStart - pitchEffectDistanceEnd)
        
        return pitchСoefficient
    }
}

// MARK: - LocationConsumer delegate

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
        let cameraOptions = self.cameraOptions(newLocation.internalLocation)
        delegate?.viewportDataSource(self, didUpdate: cameraOptions)
    }
}
