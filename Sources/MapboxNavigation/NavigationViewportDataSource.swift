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
     Returns the altitude that the `NavigationCamera` initally defaults to.
     This value is changed whenever user double taps on `MapView`.
     */
    // TODO: On CarPlay `defaultAltitude` should be set to 500.
    public var altitude: CLLocationDistance = 1000.0
    
    /**
     Returns the altitude the map conditionally zooms out to when user is on a motorway, and the maneuver length is sufficently long.
     */
    // TODO: Implement ability to handle `zoomedOutMotorwayAltitude` on iOS (2000 meters) and CarPlay (1000 meters).
    public var zoomedOutMotorwayAltitude: CLLocationDistance = 2000.0
    
    /**
     Returns the threshold for what the map considers a "long-enough" maneuver distance to trigger a zoom-out when the user enters a motorway.
     */
    // TODO: On CarPlay `longManeuverDistance` should be set to 500.
    public var longManeuverDistance: CLLocationDistance = 1000.0
    
    /**
     Returns the pitch that the `NavigationCamera` initally defaults to.
     */
    public var defaultPitch: Double = 45.0
    
    /**
     The minimum default insets from the content frame to the edges of the user course view.
     */
    public let courseViewMinimumInsets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50)
    
    /**
     Showcases route array. Adds routes and waypoints to map, and sets camera to point encompassing the route.
     */
    public let defaultPadding: UIEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
    
    weak var mapView: MapView?
    
    let maxPitch = 45.0
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
        makeGestureRecognizersUpdateAltitude()
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    func makeGestureRecognizersUpdateAltitude() {
        for gestureRecognizer in mapView?.gestureRecognizers ?? [] {
            gestureRecognizer.addTarget(self, action: #selector(updateAltitude(_:)))
        }
    }
    
    // MARK: - Notifications observer methods
    
    func subscribeForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(progressDidChange(_:)),
                                               name: .routeControllerProgressDidChange,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReroute(_:)),
                                               name: .routeControllerDidReroute,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(progressDidChange(_:)),
                                               name: .passiveLocationDataSourceDidUpdate,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(orientationDidChange),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        
        // TODO: Subscribe for .routeControllerDidPassSpokenInstructionPoint to be able to control
        // change camera in case when building highlighting is required.
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerProgressDidChange,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerDidReroute,
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
        guard let location = activeLocation,
              let mapView = mapView,
              let routeProgress = routeProgress else { return }
        
        let heading = location.course
        let edgeInsets: UIEdgeInsets = UIEdgeInsets(top: 100.0, left: 80.0, bottom: 150.0, right: 80.0)
        
        lastKnownEdgeInsets = edgeInsets
        updateEdgeInsetsDebugView()
        
        let untraveledCoordinatesOnCurrentStep = routeProgress.currentLegProgress.currentStep.shape?.coordinates.sliced(from: activeLocation?.coordinate) ?? []
        let stepIndex = routeProgress.currentLegProgress.stepIndex
        let nextStepIndex = min(stepIndex + 1, routeProgress.currentLeg.steps.count - 1)
        let coordinatesAfterCurrentStep = routeProgress.currentLeg.steps[nextStepIndex...].map({ $0.shape?.coordinates })
        
        var cameraShouldIgnoreManeuver = false
        if let upcomingStep = routeProgress.currentLeg.steps[safe: routeProgress.currentLegProgress.stepIndex + 1] {
            if routeProgress.currentLegProgress.stepIndex == routeProgress.currentLegProgress.leg.steps.count - 2 {
                cameraShouldIgnoreManeuver = true
            }
            
            let maneuvers: [ManeuverType] = [.continue, .merge, .takeOnRamp, .takeOffRamp, .reachFork]
            if maneuvers.contains(upcomingStep.maneuverType) {
                cameraShouldIgnoreManeuver = true
            }
        }
        
        let coordinatesToManeuver = coordinatesAfterCurrentStep.flatten() + untraveledCoordinatesOnCurrentStep
        guard let distance = LineString(coordinatesToManeuver).distance() else { return }
        let pitchEffectDistanceStart: CLLocationDistance = 180
        let pitchEffectDistanceEnd: CLLocationDistance = 150
        let pitchPercentage = cameraShouldIgnoreManeuver ? 1.0 : getPitchEffectPercentage(currentDistance: distance,
                                                                                          effectStartRemainingDistance: pitchEffectDistanceStart,
                                                                                          effectEndRemainingDistance: pitchEffectDistanceEnd)
        let pitchAndScreenCoordinate = getPitchAndScreenCenterPoint(pitchEffectPercentage: pitchPercentage,
                                                                    maxPitch: maxPitch,
                                                                    bounds: mapView.bounds,
                                                                    edgeInsets: edgeInsets)
        let newPitch = pitchAndScreenCoordinate.pitch
        let newCenterScreenCoordinate = pitchAndScreenCoordinate.screenCenterPoint
        
        var coordinatesForManeuverFraming: [CLLocationCoordinate2D]
        var compoundManeuvers: [[CLLocationCoordinate2D]] = []
        for step in coordinatesAfterCurrentStep {
            if let coordsForStep = step {
                let distance = coordsForStep.distance()
                if distance < 150 && distance > 0 {
                    compoundManeuvers.append(coordsForStep)
                } else {
                    let distanceAfterManeuverToIncludeInFraming = 30.0
                    compoundManeuvers.append(coordsForStep.trimmed(distance: distanceAfterManeuverToIncludeInFraming))
                    break
                }
            }
        }
        
        coordinatesForManeuverFraming = compoundManeuvers.reduce([], +)
        
        let cameraParams = getZoomLevelAndCenterCoordinateForFollowing(coordinates: coordinatesToManeuver + coordinatesForManeuverFraming,
                                                                       heading: heading,
                                                                       pitch: newPitch,
                                                                       edgeInsets: edgeInsets)
        let newZoomLevel = cameraParams.zoomLevel

        var newCenter: CLLocationCoordinate2D = location.coordinate
        let centerLineString = LineString([location.coordinate, cameraParams.centerCoordinate!])
        guard let centerLineStringTotalDistance = centerLineString.distance() else { return }
        let centerCoordDistance = centerLineStringTotalDistance * (1 - pitchPercentage)
        let adjustedCenterCoord = centerLineString.coordinateFromStart(distance: centerCoordDistance)
        newCenter = adjustedCenterCoord!

        let newMapBearing = normalizeAngle(angle: heading, anchorAngle: mapView.bearing)
        
        followingMobileCamera.center = newCenter
        followingMobileCamera.zoom = CGFloat(newZoomLevel)
        followingMobileCamera.bearing = newMapBearing
        followingMobileCamera.anchor = newCenterScreenCoordinate
        followingMobileCamera.pitch = CGFloat(newPitch)
        followingMobileCamera.padding = edgeInsets
    }
    
    func getZoomLevelAndCenterCoordinateForFollowing(coordinates: [CLLocationCoordinate2D],
                                                     heading: CLLocationDirection = 0,
                                                     pitch: Double = 0,
                                                     edgeInsets: UIEdgeInsets = .zero) -> (zoomLevel: Double, centerCoordinate: CLLocationCoordinate2D?) {
        let maxNavigationZoomLevel = 16.35
        let minNavigationZoomLevel = 2.0
        
        return getZoomLevelAndCenterCoordinate(coordinates: coordinates,
                                               heading: heading,
                                               pitch: pitch,
                                               edgeInsets: edgeInsets,
                                               maxZoomLevel: maxNavigationZoomLevel,
                                               minZoomLevel: minNavigationZoomLevel,
                                               defaultZoomLevel: minNavigationZoomLevel)
    }
    
    func updateOverviewCamera(_ passiveLocation: CLLocation?, activeLocation: CLLocation?, routeProgress: RouteProgress?) {
        guard let mapView = mapView else { return }
        guard let location = activeLocation?.coordinate else { return }
        guard let heading = activeLocation?.course else { return }
        
        let edgeInsets: UIEdgeInsets = UIEdgeInsets(top: 100.0, left: 80.0, bottom: 100.0, right: 80.0)
        let pitchPercentage = 0.0
        let pitchAndScreenCoordinate = getPitchAndScreenCenterPoint(pitchEffectPercentage: pitchPercentage,
                                                                    maxPitch: maxPitch,
                                                                    bounds: mapView.bounds,
                                                                    edgeInsets: edgeInsets)
        let newPitch = pitchAndScreenCoordinate.pitch
        let newCenterScreenCoordinate = pitchAndScreenCoordinate.screenCenterPoint

        guard let routeProgress = routeProgress else { return }
        let stepIndex = routeProgress.currentLegProgress.stepIndex
        let nextStepIndex = min(stepIndex + 1, routeProgress.currentLeg.steps.count - 1)
        let coordinatesAfterCurrentStep = routeProgress.currentLeg.steps[nextStepIndex...].map({ $0.shape?.coordinates })
        let untraveledCoordinatesOnCurrentStep = routeProgress.currentLegProgress.currentStep.shape?.coordinates.sliced(from: activeLocation?.coordinate) ?? []
        let remainingCoordsOnRoute = coordinatesAfterCurrentStep.flatten() + untraveledCoordinatesOnCurrentStep
        let cameraParams = getZoomLevelAndCenterCoordinateForOverview(coordinates: remainingCoordsOnRoute,
                                                                      // TODO: Heading should be 0.0 if already in overview.
                                                                      heading: heading,
                                                                      // TODO: Pitch should be 0.0 if already in overview.
                                                                      pitch: newPitch,
                                                                      edgeInsets: edgeInsets)
        let newZoomLevel = cameraParams.zoomLevel
        
        var newCenter: CLLocationCoordinate2D = location
        if cameraParams.centerCoordinate != nil {
            newCenter = cameraParams.centerCoordinate!
        }
        
        overviewMobileCamera.pitch = CGFloat(newPitch)
        overviewMobileCamera.center = newCenter
        overviewMobileCamera.zoom = CGFloat(newZoomLevel)
        overviewMobileCamera.anchor = newCenterScreenCoordinate
        // TODO: Heading should be 0.0 if already in overview.
        overviewMobileCamera.bearing = CLLocationDirection(mapView.cameraView.bearing) + shortestRotationDiff(angle: heading,
                                                                                                              anchorAngle: CLLocationDirection(mapView.cameraView.bearing))
    }
    
    @objc func didReroute(_ notification: NSNotification) {
        // TODO: Change `CameraOptions` when re-reouting occurs.
    }
    
    @objc func updateAltitude(_ sender: UIGestureRecognizer) {
        if sender.state == .ended, let validAltitude = mapView?.altitude {
            altitude = validAltitude
        }
        
        // Capture altitude for double tap and two finger tap after animation finishes
        if sender is UITapGestureRecognizer, sender.state == .ended {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                if let altitude = self.mapView?.altitude {
                    self.altitude = altitude
                }
            })
        }
    }
    
    func getZoomLevelAndCenterCoordinateForOverview(coordinates: [CLLocationCoordinate2D],
                                                    heading: CLLocationDirection = 0,
                                                    pitch: Double = 0,
                                                    edgeInsets: UIEdgeInsets = .zero) -> (zoomLevel: Double, centerCoordinate: CLLocationCoordinate2D?) {
        let maxNavigationZoomLevel = 16.35
        return getZoomLevelAndCenterCoordinate(coordinates: coordinates,
                                               heading: heading,
                                               pitch: pitch,
                                               edgeInsets: edgeInsets,
                                               maxZoomLevel: maxNavigationZoomLevel,
                                               minZoomLevel: 2.0,
                                               defaultZoomLevel: 12.0)
    }
    
    func getZoomLevelAndCenterCoordinate(coordinates: [CLLocationCoordinate2D],
                                         heading: CLLocationDirection = 0,
                                         pitch: Double = 0,
                                         edgeInsets: UIEdgeInsets = .zero,
                                         maxZoomLevel: Double = 22.0,
                                         minZoomLevel: Double = 2.0,
                                         defaultZoomLevel: Double = 12.0) -> (zoomLevel: Double, centerCoordinate: CLLocationCoordinate2D?) {
        guard let mapView = mapView else {
            return (zoomLevel: defaultZoomLevel, centerCoordinate: nil)
        }
        
        let mapInsetWidth = mapView.bounds.size.width - edgeInsets.left - edgeInsets.right
        let mapInsetHeight = mapView.bounds.size.height - edgeInsets.top - edgeInsets.bottom
        
        let widthForMinPitch = mapInsetWidth
        let widthForMaxPitch = mapInsetHeight * 2
        let widthDelta = widthForMaxPitch - widthForMinPitch
        let widthWithPitchEffect = CGFloat(Double(widthForMinPitch) + ((pitch / maxPitch) * Double(widthDelta)))
        let heightWithPitchEffect = CGFloat( Double(mapInsetHeight) + (Double(mapInsetHeight) * sin(pitch * .pi / 180.0) * 1.25) )
        
        let coordinateScreenPoints = coordinates.map { mapView.point(for: $0) }
        let coordinateScreenPointsBbox = coordinateScreenPoints.getBoxPoints()
        let coordinatesFromScreenPointBbox = coordinateScreenPointsBbox.map { mapView.coordinate(for: $0) }
        let centerCoordinateOfBbox = coordinatesFromScreenPointBbox.getCenterCoordinate()
        
        let coordinateScreenPointsBboxSizeInMeters = (width: coordinatesFromScreenPointBbox[0].distance(to: coordinatesFromScreenPointBbox[1]), height: coordinatesFromScreenPointBbox[1].distance(to: coordinatesFromScreenPointBbox[2]))
        let bboxNorth = centerCoordinateOfBbox.coordinate(at: coordinateScreenPointsBboxSizeInMeters.height / 2, facing: 0)
        let bboxSouth = centerCoordinateOfBbox.coordinate(at: coordinateScreenPointsBboxSizeInMeters.height / 2, facing: 180)
        let bboxWest = centerCoordinateOfBbox.coordinate(at: coordinateScreenPointsBboxSizeInMeters.width / 2, facing: 270)
        let bboxEast = centerCoordinateOfBbox.coordinate(at: coordinateScreenPointsBboxSizeInMeters.width / 2, facing: 90)
        let rotatedBbox = [
            CLLocationCoordinate2D(latitude: bboxNorth.latitude, longitude: bboxWest.longitude),
            CLLocationCoordinate2D(latitude: bboxNorth.latitude, longitude: bboxEast.longitude),
            CLLocationCoordinate2D(latitude: bboxSouth.latitude, longitude: bboxEast.longitude),
            CLLocationCoordinate2D(latitude: bboxSouth.latitude, longitude: bboxWest.longitude)
        ]
        
        let zl = getCoordinateBoundsZoomLevel(bounds: rotatedBbox, fitToSize: CGSize(width: widthWithPitchEffect, height: heightWithPitchEffect))
        
        return (zoomLevel: max(min(zl, maxZoomLevel), minZoomLevel), centerCoordinate: centerCoordinateOfBbox)
    }
    
    func getPitchAndScreenCenterPoint(pitchEffectPercentage: Double, maxPitch: Double, bounds: CGRect, edgeInsets: UIEdgeInsets) -> (pitch: Double, screenCenterPoint: CGPoint) {
        let xCenter = max(((bounds.size.width - edgeInsets.left - edgeInsets.right) / 2.0) + edgeInsets.left, 0.0)
        let height = (bounds.size.height - edgeInsets.top - edgeInsets.bottom)
        let yCenter = max((height / 2.0) + edgeInsets.top, 0.0)
        let yOffsetCenter = max((height / 2.0) - 7.0, 0.0) * CGFloat(pitchEffectPercentage) + yCenter
        return (pitch: maxPitch * pitchEffectPercentage, screenCenterPoint: CGPoint(x: xCenter, y: yOffsetCenter))
    }
    
    func shortestRotationDiff(angle: CLLocationDirection, anchorAngle: CLLocationDirection) -> CLLocationDirection {
        guard !angle.isNaN && !anchorAngle.isNaN else { return 0.0 }
        return (angle - anchorAngle).wrap(min: -180.0, max: 180.0)
    }
    
    func getCoordinateBoundsZoomLevel(bounds: [CLLocationCoordinate2D], fitToSize: CGSize) -> Double {
        let bbox = bounds.getBoxCoordinates()
        let ne = bbox[1]
        let sw = bbox[3]
        let latFraction = (latRad(ne.latitude) - latRad(sw.latitude)) / .pi
        
        let lngDiff = ne.longitude - sw.longitude
        let lngFraction = ((lngDiff < 0) ? (lngDiff + 360) : lngDiff) / 360
        
        let latZoom = zoom(displayDimensionSize: Double(fitToSize.height), tileSize: 512.0, fraction: latFraction)
        let lngZoom = zoom(displayDimensionSize: Double(fitToSize.width), tileSize: 512.0, fraction: lngFraction)
        
        return min(latZoom, lngZoom, 21.0)
    }
    
    func latRad(_ lat: CLLocationDegrees) -> Double {
        let sinVal = sin(lat * .pi / 180)
        let radX2 = log((1 + sinVal) / (1 - sinVal)) / 2
        return max(min(radX2, .pi), -.pi) / 2
    }
    
    func zoom(displayDimensionSize: Double, tileSize: Double, fraction: Double) -> Double {
        return log(displayDimensionSize / tileSize / fraction) / M_LN2
    }
    
    func getPitchEffectPercentage(currentDistance: CLLocationDistance,
                                  effectStartRemainingDistance: CLLocationDistance,
                                  effectEndRemainingDistance: CLLocationDistance) -> Double {
        return (max(min(currentDistance, effectStartRemainingDistance), effectEndRemainingDistance) - effectEndRemainingDistance) / (effectStartRemainingDistance - effectEndRemainingDistance)
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
