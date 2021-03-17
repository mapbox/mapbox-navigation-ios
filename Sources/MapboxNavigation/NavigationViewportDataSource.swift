import UIKit
import MapboxMaps
import MapboxCoreNavigation
import Turf
import MapboxDirections

public class NavigationViewportDataSource: ViewportDataSource {
    
    public var delegate: ViewportDataSourceDelegate?
    
    public var followingMobileCamera: CameraOptions = CameraOptions()
    
    public var followingHeadUnitCamera: CameraOptions = CameraOptions()
    
    public var overviewMobileCamera: CameraOptions = CameraOptions()
    
    public var overviewHeadUnitCamera: CameraOptions = CameraOptions()
    
    public var maximumPitch: Double = 45.0
    
    weak var mapView: MapView?
    
    public required init(_ mapView: MapView) {
        self.mapView = mapView
        
        subscribeForNotifications()
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    // MARK: - Notifications observer methods
    
    func subscribeForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(progressDidChange(_:)),
                                               name: .routeControllerProgressDidChange,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(progressDidChange(_:)),
                                               name: .passiveLocationDataSourceDidUpdate,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerProgressDidChange,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .passiveLocationDataSourceDidUpdate,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: UIDevice.orientationDidChangeNotification,
                                                  object: nil)
    }
    
    @objc func progressDidChange(_ notification: NSNotification) {
        let activeLocation = notification.userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation
        let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
        let passiveLocation = notification.userInfo?[PassiveLocationDataSource.NotificationUserInfoKey.locationKey] as? CLLocation
        let cameraOptions = self.cameraOptions(passiveLocation, activeLocation: activeLocation, routeProgress: routeProgress)
        delegate?.viewportDataSource(self, didUpdate: cameraOptions)
    }
    
    @objc func orientationDidChange() {
        if UIDevice.current.orientation.isPortrait {
            followingMobileCamera.padding = UIEdgeInsets(top: 300.0, left: 0.0, bottom: 0.0, right: 0.0)
        } else {
            followingMobileCamera.padding = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
        }
        
        let cameraOptions = [
            CameraOptions.followingMobileCameraKey: followingMobileCamera,
        ]
        delegate?.viewportDataSource(self, didUpdate: cameraOptions)
    }
    
    func cameraOptions(_ passiveLocation: CLLocation?, activeLocation: CLLocation?, routeProgress: RouteProgress?) -> [String: CameraOptions] {
        updateFollowingCamera(passiveLocation, activeLocation: activeLocation, routeProgress: routeProgress)
        updateOverviewCamera(passiveLocation, activeLocation: activeLocation, routeProgress: routeProgress)
        
        let cameraOptions = [
            CameraOptions.followingMobileCameraKey: followingMobileCamera,
            CameraOptions.overviewMobileCameraKey: overviewMobileCamera,
            CameraOptions.followingHeadUnitCameraKey: followingHeadUnitCamera,
            CameraOptions.overviewHeadUnitCameraKey: overviewHeadUnitCamera
        ]
        
        return cameraOptions
    }
    
    func updateFollowingCamera(_ passiveLocation: CLLocation?, activeLocation: CLLocation?, routeProgress: RouteProgress?) {
        guard let mapView = mapView else { return }
        
        if let location = passiveLocation {
            let followingWithoutRouteZoomLevel = CGFloat(14.0)
            
            followingMobileCamera.center = location.coordinate
            followingMobileCamera.zoom = followingWithoutRouteZoomLevel
            followingMobileCamera.bearing = 0
            followingMobileCamera.anchor = mapView.center
            followingMobileCamera.pitch = 0
            followingMobileCamera.padding = .zero
            
            followingHeadUnitCamera.center = location.coordinate
            followingHeadUnitCamera.zoom = followingWithoutRouteZoomLevel
            followingHeadUnitCamera.bearing = 0
            followingHeadUnitCamera.anchor = mapView.center
            followingHeadUnitCamera.pitch = 0
            followingHeadUnitCamera.padding = .zero
            
            return
        }
        
        if let location = activeLocation, let routeProgress = routeProgress {
            let edgeInsets: UIEdgeInsets = UIEdgeInsets(top: 150.0, left: 80.0, bottom: 150.0, right: 80.0)
            let pitchСoefficient = self.pitchСoefficient(routeProgress, currentCoordinate: location.coordinate)
            
            let anchor = self.anchor(pitchСoefficient,
                                     maxPitch: maximumPitch,
                                     bounds: mapView.bounds,
                                     edgeInsets: edgeInsets)
            let pitch = maximumPitch * pitchСoefficient
            
            var compoundManeuvers: [[CLLocationCoordinate2D]] = []
            let stepIndex = routeProgress.currentLegProgress.stepIndex
            let nextStepIndex = min(stepIndex + 1, routeProgress.currentLeg.steps.count - 1)
            let coordinatesAfterCurrentStep = routeProgress.currentLeg.steps[nextStepIndex...].map({ $0.shape?.coordinates })
            for step in coordinatesAfterCurrentStep {
                guard let stepCoordinates = step, let distance = stepCoordinates.distance() else { continue }
                if distance > 0 && distance < 150 {
                    compoundManeuvers.append(stepCoordinates)
                } else {
                    let distanceAfterManeuverToIncludeInFraming = 30.0
                    compoundManeuvers.append(stepCoordinates.trimmed(distance: distanceAfterManeuverToIncludeInFraming))
                    break
                }
            }
            
            let coordinatesForManeuverFraming = compoundManeuvers.reduce([], +)
            let coordinatesToManeuver = routeProgress.currentLegProgress.currentStep.shape?.coordinates.sliced(from: location.coordinate) ?? []
            let zoom = self.zoom(coordinatesToManeuver + coordinatesForManeuverFraming,
                                 pitch: pitch,
                                 edgeInsets: edgeInsets,
                                 defaultZoomLevel: 2.0,
                                 maxZoomLevel: 16.35,
                                 minZoomLevel: 2.0)
            
            let centerLineString = LineString([location.coordinate, (coordinatesToManeuver + coordinatesForManeuverFraming).map({ mapView.point(for: $0) }).boundingBoxPoints.map({ mapView.coordinate(for: $0) }).centerCoordinate])
            let centerLineStringTotalDistance = centerLineString.distance() ?? 0.0
            let centerCoordDistance = centerLineStringTotalDistance * (1 - pitchСoefficient)
            
            var centerCoordinate: CLLocationCoordinate2D = location.coordinate
            if let adjustedCenterCoordinate = centerLineString.coordinateFromStart(distance: centerCoordDistance) {
                centerCoordinate = adjustedCenterCoordinate
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

            followingMobileCamera.center = centerCoordinate
            followingMobileCamera.zoom = CGFloat(zoom)
            followingMobileCamera.bearing = bearing
            followingMobileCamera.anchor = anchor
            followingMobileCamera.pitch = CGFloat(pitch)
            followingMobileCamera.padding = edgeInsets
            
            followingHeadUnitCamera.center = centerCoordinate
            followingHeadUnitCamera.zoom = CGFloat(zoom)
            followingHeadUnitCamera.bearing = bearing
            followingHeadUnitCamera.anchor = anchor
            followingHeadUnitCamera.pitch = CGFloat(pitch)
            followingHeadUnitCamera.padding = UIEdgeInsets(top: 40.0, left: 200.0, bottom: 40.0, right: 40.0)
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "ViewportDidChange"), object: self, userInfo: [
                "EdgeInsets": edgeInsets,
                "Anchor": anchor
            ])
        }
    }
    
    func updateOverviewCamera(_ passiveLocation: CLLocation?, activeLocation: CLLocation?, routeProgress: RouteProgress?) {
        guard let mapView = mapView,
              let coordinate = activeLocation?.coordinate,
              let heading = activeLocation?.course,
              let routeProgress = routeProgress else { return }
        
        let edgeInsets = UIEdgeInsets(top: 100.0, left: 80.0, bottom: 100.0, right: 80.0)
        let anchor = self.anchor(0.0,
                                 maxPitch: maximumPitch,
                                 bounds: mapView.bounds,
                                 edgeInsets: edgeInsets)
        let stepIndex = routeProgress.currentLegProgress.stepIndex
        let nextStepIndex = min(stepIndex + 1, routeProgress.currentLeg.steps.count - 1)
        let coordinatesAfterCurrentStep = routeProgress.currentLeg.steps[nextStepIndex...].map({ $0.shape?.coordinates })
        let untraveledCoordinatesOnCurrentStep = routeProgress.currentLegProgress.currentStep.shape?.coordinates.sliced(from: coordinate) ?? []
        let remainingCoordinatesOnRoute = coordinatesAfterCurrentStep.flatten() + untraveledCoordinatesOnCurrentStep

        let center = remainingCoordinatesOnRoute.map({ mapView.point(for: $0) }).boundingBoxPoints.map({ mapView.coordinate(for: $0) }).centerCoordinate
        
        let zoom = self.zoom(remainingCoordinatesOnRoute,
                             pitch: 0.0,
                             edgeInsets: edgeInsets,
                             maxZoomLevel: 16.35,
                             minZoomLevel: 2.0)
        
        // In case if `NavigationCamera` is already in `NavigationCameraState.overview` value of bearing will be ignored.
        let bearing = CLLocationDirection(mapView.cameraView.bearing) +
            heading.shortestRotation(angle: CLLocationDirection(mapView.cameraView.bearing))
        
        overviewMobileCamera.pitch = 0.0
        overviewMobileCamera.center = center
        overviewMobileCamera.zoom = CGFloat(zoom)
        overviewMobileCamera.anchor = anchor
        overviewMobileCamera.bearing = bearing
    }
    
    func bearing(_ initialBearing: CLLocationDirection, coordinatesToManeuver: [CLLocationCoordinate2D]? = nil) -> CLLocationDirection {
        let bearingModeClampedManeuverMaxDiff = 20.0
        var bearing = initialBearing

        if let coords = coordinatesToManeuver, let firstCoordinate = coords.first, let lastCoordinate = coords.last {
            let directionToManeuver = firstCoordinate.direction(to: lastCoordinate)
            let directionDiff = directionToManeuver.shortestRotation(angle: initialBearing)
            if fabs(directionDiff) > bearingModeClampedManeuverMaxDiff {
                bearing += bearingModeClampedManeuverMaxDiff * (directionDiff < 0.0 ? -1.0 : 1.0)
            } else {
                bearing = firstCoordinate.direction(to: lastCoordinate)
            }
        }
        
        let mapViewBearing = Double(mapView?.cameraView.bearing ?? 0.0)
        return mapViewBearing + bearing.shortestRotation(angle: mapViewBearing)
    }
    
    func zoom(_ coordinates: [CLLocationCoordinate2D],
              pitch: Double = 0,
              edgeInsets: UIEdgeInsets = .zero,
              defaultZoomLevel: Double = 12.0,
              maxZoomLevel: Double = 22.0,
              minZoomLevel: Double = 2.0) -> Double {
        guard let mapView = mapView,
              let boundingBox = BoundingBox(from: coordinates) else { return defaultZoomLevel }
        
        let mapInsetWidth = mapView.bounds.size.width - edgeInsets.left - edgeInsets.right
        let mapInsetHeight = mapView.bounds.size.height - edgeInsets.top - edgeInsets.bottom
        let widthDelta = mapInsetHeight * 2 - mapInsetWidth
        let widthWithPitchEffect = CGFloat(mapInsetWidth + CGFloat(pitch / maximumPitch) * widthDelta)
        let heightWithPitchEffect = CGFloat(mapInsetHeight + mapInsetHeight * CGFloat(sin(pitch * .pi / 180.0)) * 1.25)
        let zoomLevel = coordinateBoundsZoomLevel(boundingBox, fitToSize: CGSize(width: widthWithPitchEffect, height: heightWithPitchEffect))
        
        return max(min(zoomLevel, maxZoomLevel), minZoomLevel)
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
        let pitchEffectDistanceStart: CLLocationDistance = 180
        let pitchEffectDistanceEnd: CLLocationDistance = 150
        let pitchСoefficient = shouldIgnoreManeuver
            ? defaultPitchСoefficient
            : (max(min(distance, pitchEffectDistanceStart), pitchEffectDistanceEnd) - pitchEffectDistanceEnd) / (pitchEffectDistanceStart - pitchEffectDistanceEnd)
        
        return pitchСoefficient
    }
    
    func anchor(_ pitchСoefficient: Double, maxPitch: Double, bounds: CGRect, edgeInsets: UIEdgeInsets) -> CGPoint {
        let xCenter = max(((bounds.size.width - edgeInsets.left - edgeInsets.right) / 2.0) + edgeInsets.left, 0.0)
        let height = (bounds.size.height - edgeInsets.top - edgeInsets.bottom)
        let yCenter = max((height / 2.0) + edgeInsets.top, 0.0)
        let yOffsetCenter = max((height / 2.0) - 7.0, 0.0) * CGFloat(pitchСoefficient) + yCenter
        return CGPoint(x: xCenter, y: yOffsetCenter)
    }
    
    func coordinateBoundsZoomLevel(_ boundingBox: BoundingBox, fitToSize: CGSize) -> Double {
        let latFraction = (boundingBox.northEast.latitude.radius - boundingBox.southWest.latitude.radius) / .pi
        let lngDiff = boundingBox.northEast.longitude - boundingBox.southWest.longitude
        let lngFraction = ((lngDiff < 0) ? (lngDiff + 360) : lngDiff) / 360
        let latZoom = log(Double(fitToSize.height) / 512.0 / latFraction) / M_LN2
        let lngZoom = log(Double(fitToSize.width) / 512.0 / lngFraction) / M_LN2
        return min(latZoom, lngZoom, 21.0)
    }
}
