import CoreLocation
import MapboxDirections
import MapboxMaps
import Turf
import UIKit

extension ViewportDataSource {
    func bearing(
        _ initialBearing: CLLocationDirection,
        mapView: MapView?,
        coordinatesToManeuver: [CLLocationCoordinate2D]? = nil
    ) -> CLLocationDirection {
        var bearing = initialBearing

        if let coordinates = coordinatesToManeuver,
           let firstCoordinate = coordinates.first,
           let lastCoordinate = coordinates.last
        {
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

        let mapViewBearing = Double(mapView?.mapboxMap.cameraState.bearing ?? 0.0)
        return mapViewBearing + bearing.shortestRotation(angle: mapViewBearing)
    }

    func zoom(
        _ coordinates: [CLLocationCoordinate2D],
        mapView: MapView?,
        pitch: Double = 0.0,
        maxPitch: Double = 0.0,
        edgeInsets: UIEdgeInsets = .zero,
        defaultZoomLevel: Double = 12.0,
        maxZoomLevel: Double = 22.0,
        minZoomLevel: Double = 2.0
    ) -> CGFloat {
        guard let mapView,
              let boundingBox = BoundingBox(from: coordinates) else { return CGFloat(defaultZoomLevel) }

        let mapViewInsetWidth = mapView.bounds.size.width - edgeInsets.left - edgeInsets.right
        let mapViewInsetHeight = mapView.bounds.size.height - edgeInsets.top - edgeInsets.bottom
        let widthDelta = mapViewInsetHeight * 2 - mapViewInsetWidth
        let pitchDelta = CGFloat(pitch / maxPitch) * widthDelta
        let widthWithPitchEffect = CGFloat(mapViewInsetWidth + CGFloat(pitchDelta.isNaN ? 0.0 : pitchDelta))
        let heightWithPitchEffect =
            CGFloat(mapViewInsetHeight + mapViewInsetHeight * CGFloat(sin(pitch * .pi / 180.0)) * 1.25)
        let zoomLevel = boundingBox.zoomLevel(fitTo: CGSize(width: widthWithPitchEffect, height: heightWithPitchEffect))

        return CGFloat(max(min(zoomLevel, maxZoomLevel), minZoomLevel))
    }

    func overviewCameraZoom(
        _ coordinates: [CLLocationCoordinate2D],
        mapView: MapView?,
        pitch: CGFloat?,
        bearing: CLLocationDirection?,
        edgeInsets: UIEdgeInsets,
        defaultZoomLevel: Double = 12.0,
        maxZoomLevel: Double = 22.0,
        minZoomLevel: Double = 2.0
    ) -> CGFloat {
        guard let mapView else { return CGFloat(defaultZoomLevel) }

        let initialCameraOptions = CameraOptions(
            padding: edgeInsets,
            bearing: 0,
            pitch: 0
        )
        guard let options = try? mapView.mapboxMap.camera(
            for: coordinates,
            camera: initialCameraOptions,
            coordinatesPadding: nil,
            maxZoom: nil,
            offset: nil
        ) else {
            return CGFloat(defaultZoomLevel)
        }
        return CGFloat(max(min(options.zoom ?? defaultZoomLevel, maxZoomLevel), minZoomLevel))
    }

    func anchor(
        _ pitchСoefficient: Double = 0.0,
        bounds: CGRect = .zero,
        edgeInsets: UIEdgeInsets = .zero
    ) -> CGPoint {
        let xCenter = max(((bounds.size.width - edgeInsets.left - edgeInsets.right) / 2.0) + edgeInsets.left, 0.0)
        let height = (bounds.size.height - edgeInsets.top - edgeInsets.bottom)
        let yCenter = max((height / 2.0) + edgeInsets.top, 0.0)
        let yOffsetCenter = max((height / 2.0) - 7.0, 0.0) * CGFloat(pitchСoefficient) + yCenter

        return CGPoint(x: xCenter, y: yOffsetCenter)
    }

    func pitchСoefficient(
        distanceRemainingOnStep: CLLocationDistance,
        currentCoordinate: CLLocationCoordinate2D,
        currentLegStepIndex: Int,
        currentLegSteps: [RouteStep]
    ) -> Double {
        let defaultPitchСoefficient = 1.0
        let pitchNearManeuver = options.followingCameraOptions.pitchNearManeuver
        guard pitchNearManeuver.enabled else { return defaultPitchСoefficient }

        var shouldIgnoreManeuver = false
        if let upcomingStep = currentLegSteps[safe: currentLegStepIndex + 1] {
            if currentLegStepIndex == currentLegSteps.count - 2 {
                shouldIgnoreManeuver = true
            }

            let maneuvers: [ManeuverType] = [.continue, .merge, .takeOnRamp, .takeOffRamp, .reachFork]
            if maneuvers.contains(upcomingStep.maneuverType) {
                shouldIgnoreManeuver = true
            }
        }

        if distanceRemainingOnStep <= pitchNearManeuver.triggerDistanceToManeuver, !shouldIgnoreManeuver,
           pitchNearManeuver.triggerDistanceToManeuver != 0.0
        {
            return distanceRemainingOnStep / pitchNearManeuver.triggerDistanceToManeuver
        }
        return defaultPitchСoefficient
    }

    var followingCamera: CameraOptions {
        currentNavigationCameraOptions.followingCamera
    }

    var overviewCamera: CameraOptions {
        currentNavigationCameraOptions.overviewCamera
    }
}

extension ViewportDataSourceState.NavigationState {
    var isInPassiveNavigationOrCompletedActive: Bool {
        if case .passive = self { return true }
        if case .active(let activeState) = self, activeState.isRouteComplete { return true }
        return false
    }
}
