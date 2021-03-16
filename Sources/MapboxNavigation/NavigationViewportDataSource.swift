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
    
    /**
     Returns the pitch that the `NavigationCamera` initally defaults to.
     */
    public var defaultPitch: Double = 45.0
    
    weak var mapView: MapView?
    
    var lastKnownEdgeInsets: UIEdgeInsets = .zero
    var showEdgeInsetsDebugView = true
    var edgeInsetsDebugView = UIView()
    var topEdgeInsetView = UIView()
    var rightEdgeInsetView = UIView()
    var bottomEdgeInsetView = UIView()
    var leftEdgeInsetView = UIView()
    
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
            let edgeInsets: UIEdgeInsets = UIEdgeInsets(top: 100.0, left: 80.0, bottom: 150.0, right: 80.0)
            
            lastKnownEdgeInsets = edgeInsets
            updateEdgeInsetsDebugView()
            
            let pitchСoefficient = self.pitchСoefficient(routeProgress, currentCoordinate: location.coordinate)
            
            let anchor = self.anchor(pitchСoefficient,
                                     maxPitch: defaultPitch,
                                     bounds: mapView.bounds,
                                     edgeInsets: edgeInsets)
            let pitch = defaultPitch * pitchСoefficient
            
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
            let zoom = zoomLevel(coordinatesToManeuver + coordinatesForManeuverFraming,
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
            
            let bearing = normalizeAngle(angle: location.course, anchorAngle: mapView.bearing)
            
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
        }
    }
    
    func updateOverviewCamera(_ passiveLocation: CLLocation?, activeLocation: CLLocation?, routeProgress: RouteProgress?) {
        guard let mapView = mapView,
              let coordinate = activeLocation?.coordinate,
              let heading = activeLocation?.course,
              let routeProgress = routeProgress else { return }
        
        let edgeInsets = UIEdgeInsets(top: 100.0, left: 80.0, bottom: 100.0, right: 80.0)
        let anchor = self.anchor(0.0,
                                 maxPitch: defaultPitch,
                                 bounds: mapView.bounds,
                                 edgeInsets: edgeInsets)
        let stepIndex = routeProgress.currentLegProgress.stepIndex
        let nextStepIndex = min(stepIndex + 1, routeProgress.currentLeg.steps.count - 1)
        let coordinatesAfterCurrentStep = routeProgress.currentLeg.steps[nextStepIndex...].map({ $0.shape?.coordinates })
        let untraveledCoordinatesOnCurrentStep = routeProgress.currentLegProgress.currentStep.shape?.coordinates.sliced(from: coordinate) ?? []
        let remainingCoordinatesOnRoute = coordinatesAfterCurrentStep.flatten() + untraveledCoordinatesOnCurrentStep

        let zoom = zoomLevel(remainingCoordinatesOnRoute,
                             pitch: 0.0,
                             edgeInsets: edgeInsets,
                             maxZoomLevel: 16.35,
                             minZoomLevel: 2.0)
        
        let center = remainingCoordinatesOnRoute.map({ mapView.point(for: $0) }).boundingBoxPoints.map({ mapView.coordinate(for: $0) }).centerCoordinate
        
        overviewMobileCamera.pitch = 0.0
        overviewMobileCamera.center = center
        overviewMobileCamera.zoom = CGFloat(zoom)
        overviewMobileCamera.anchor = anchor
        // TODO: Heading should be 0.0 if already in overview.
        overviewMobileCamera.bearing = CLLocationDirection(mapView.cameraView.bearing) + shortestRotationDiff(angle: heading,
                                                                                                              anchorAngle: CLLocationDirection(mapView.cameraView.bearing))
    }
    
    func zoomLevel(_ coordinates: [CLLocationCoordinate2D],
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
        let widthWithPitchEffect = CGFloat(mapInsetWidth + (CGFloat(pitch / defaultPitch) * widthDelta))
        let heightWithPitchEffect = CGFloat(Double(mapInsetHeight) + (Double(mapInsetHeight) * sin(pitch * .pi / 180.0) * 1.25))
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
    
    func shortestRotationDiff(angle: CLLocationDirection, anchorAngle: CLLocationDirection) -> CLLocationDirection {
        guard !angle.isNaN && !anchorAngle.isNaN else { return 0.0 }
        return (angle - anchorAngle).wrap(min: -180.0, max: 180.0)
    }
    
    func coordinateBoundsZoomLevel(_ boundingBox: BoundingBox, fitToSize: CGSize) -> Double {
        let latFraction = (latRad(boundingBox.northEast.latitude) - latRad(boundingBox.southWest.latitude)) / .pi
        let lngDiff = boundingBox.northEast.longitude - boundingBox.southWest.longitude
        let lngFraction = ((lngDiff < 0) ? (lngDiff + 360) : lngDiff) / 360
        let latZoom = zoom(displayDimensionSize: Double(fitToSize.height), tileSize: 512.0, fraction: latFraction)
        let lngZoom = zoom(displayDimensionSize: Double(fitToSize.width), tileSize: 512.0, fraction: lngFraction)
        
        return min(latZoom, lngZoom, 21.0)
    }
    
    func latRad(_ latitude: CLLocationDegrees) -> Double {
        let sinVal = sin(latitude * .pi / 180)
        let radX2 = log((1 + sinVal) / (1 - sinVal)) / 2
        return max(min(radX2, .pi), -.pi) / 2
    }
    
    func zoom(displayDimensionSize: Double, tileSize: Double, fraction: Double) -> Double {
        return log(displayDimensionSize / tileSize / fraction) / M_LN2
    }
    
    func normalizeAngle(angle: CLLocationDirection, anchorAngle: CLLocationDirection) -> CLLocationDirection {
        guard !angle.isNaN && !anchorAngle.isNaN else { return 0.0 }
        
        var localAngle = angle.wrap(min: 0.0, max: 360.0)
        let diff = abs(localAngle - anchorAngle)
        if abs(localAngle - 360.0 - anchorAngle) < diff {
            localAngle -= 360.0
        }
        if abs(localAngle + 360.0 - anchorAngle) < diff {
            localAngle += 360.0
        }
        return localAngle
    }
    
    func updateEdgeInsetsDebugView(_ color: UIColor = .green) {
        guard showEdgeInsetsDebugView else {
            edgeInsetsDebugView.subviews.forEach { view in
                view.removeFromSuperview()
            }
            
            edgeInsetsDebugView.removeFromSuperview()
            return
        }
        
        if let mapView = mapView {
            edgeInsetsDebugView.frame = CGRect(x: 0,
                                               y: 0,
                                               width: mapView.bounds.size.width,
                                               height: mapView.bounds.size.height)
            
            if edgeInsetsDebugView.superview == nil {
                edgeInsetsDebugView.isUserInteractionEnabled = false
                edgeInsetsDebugView.addSubview(topEdgeInsetView)
                edgeInsetsDebugView.addSubview(rightEdgeInsetView)
                edgeInsetsDebugView.addSubview(bottomEdgeInsetView)
                edgeInsetsDebugView.addSubview(leftEdgeInsetView)
            }
            
            mapView.insertSubview(edgeInsetsDebugView, at: mapView.subviews.count)
        }
        
        let width = edgeInsetsDebugView.frame.size.width
        let height = edgeInsetsDebugView.frame.size.height
        
        topEdgeInsetView.frame = CGRect(x: 0, y: lastKnownEdgeInsets.top, width: width, height: 2.0)
        topEdgeInsetView.backgroundColor = color
        
        rightEdgeInsetView.frame = CGRect(x: width - lastKnownEdgeInsets.right - 2.0, y: 0, width: 2.0, height: height)
        rightEdgeInsetView.backgroundColor = color
        
        bottomEdgeInsetView.frame = CGRect(x: 0, y: height - lastKnownEdgeInsets.bottom - 2.0, width: width, height: 2.0)
        bottomEdgeInsetView.backgroundColor = color
        
        leftEdgeInsetView.frame = CGRect(x: lastKnownEdgeInsets.left, y: 0, width: 2.0, height: height)
        leftEdgeInsetView.backgroundColor = color
    }
}
