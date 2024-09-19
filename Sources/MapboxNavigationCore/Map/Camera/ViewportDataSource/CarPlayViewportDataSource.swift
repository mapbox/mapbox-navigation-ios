import Combine
import CoreLocation
import MapboxDirections
import MapboxMaps
import Turf
import UIKit

/// The class, which conforms to ``ViewportDataSource`` protocol and provides default implementation of it for CarPlay.
@MainActor
public class CarPlayViewportDataSource: ViewportDataSource {
    private var commonDataSource: CommonViewportDataSource

    weak var mapView: MapView?

    /// Initializes ``CarPlayViewportDataSource`` instance.
    /// - Parameter mapView: An instance of `MapView`, which is going to be used for viewport calculation. `MapView`
    /// will be weakly stored by ``CarPlayViewportDataSource``.
    public required init(_ mapView: MapView) {
        self.mapView = mapView
        self.commonDataSource = .init(mapView)
    }

    /// Options, which give the ability to control whether certain `CameraOptions` will be generated.
    public var options: NavigationViewportDataSourceOptions {
        get { commonDataSource.options }
        set { commonDataSource.options = newValue }
    }

    /// Notifies that the navigation camera options have changed in response to a viewport change.
    public var navigationCameraOptions: AnyPublisher<NavigationCameraOptions, Never> {
        commonDataSource.navigationCameraOptions
    }

    /// The last calculated ``NavigationCameraOptions``.
    public var currentNavigationCameraOptions: NavigationCameraOptions {
        get {
            commonDataSource.currentNavigationCameraOptions
        }

        set {
            commonDataSource.currentNavigationCameraOptions = newValue
        }
    }

    /// Updates ``NavigationCameraOptions`` accoridng to the navigation state.
    /// - Parameters:
    ///   - viewportState: The current viewport state.
    public func update(using viewportState: ViewportState) {
        commonDataSource.update(using: viewportState) { [weak self] state in
            guard let self else { return nil }
            return NavigationCameraOptions(
                followingCamera: newFollowingCamera(with: state),
                overviewCamera: newOverviewCamera(with: state)
            )
        }
    }

    private func newFollowingCamera(with state: ViewportDataSourceState) -> CameraOptions {
        guard let mapView else { return .init() }

        let followingCameraOptions = options.followingCameraOptions

        var newOptions = currentNavigationCameraOptions.followingCamera
        if let location = state.location, state.navigationState.isInPassiveNavigationOrCompletedActive {
            if followingCameraOptions.centerUpdatesAllowed || followingCamera.center == nil {
                newOptions.center = location.coordinate
            }

            if followingCameraOptions.zoomUpdatesAllowed || followingCamera.zoom == nil {
                let altitude = 1700.0
                let zoom = CGFloat(ZoomLevelForAltitude(
                    altitude,
                    mapView.mapboxMap.cameraState.pitch,
                    location.coordinate.latitude,
                    mapView.bounds.size
                ))

                newOptions.zoom = zoom
            }

            if followingCameraOptions.bearingUpdatesAllowed || followingCamera.bearing == nil {
                if followingCameraOptions.followsLocationCourse {
                    newOptions.bearing = location.course
                } else {
                    newOptions.bearing = 0.0
                }
            }

            newOptions.anchor = mapView.center

            if followingCameraOptions.pitchUpdatesAllowed || followingCamera.pitch == nil {
                newOptions.pitch = 0.0
            }

            if followingCameraOptions.paddingUpdatesAllowed || followingCamera.padding == nil {
                newOptions.padding = mapView.safeAreaInsets
            }

            return newOptions
        }

        if let location = state.location, case .active(let activeState) = state.navigationState,
           !activeState.isRouteComplete
        {
            let coordinatesToManeuver = activeState.coordinatesToManeuver
            let lookaheadDistance = activeState.lookaheadDistance

            var compoundManeuvers: [[CLLocationCoordinate2D]] = []
            let geometryFramingAfterManeuver = followingCameraOptions.geometryFramingAfterManeuver
            let pitchСoefficient = pitchСoefficient(
                distanceRemainingOnStep: activeState.distanceRemainingOnStep,
                currentCoordinate: location.coordinate,
                currentLegStepIndex: activeState.currentLegStepIndex,
                currentLegSteps: activeState.currentLegSteps
            )
            let pitch = followingCameraOptions.defaultPitch * pitchСoefficient
            var carPlayCameraPadding = mapView.safeAreaInsets + UIEdgeInsets.centerEdgeInsets

            // Bottom of the viewport on CarPlay should be placed at the same level with
            // trip estimate view.
            carPlayCameraPadding.bottom += 65.0

            if geometryFramingAfterManeuver.enabled {
                let nextStepIndex = min(activeState.currentLegStepIndex + 1, activeState.currentLegSteps.count - 1)

                var totalDistance: CLLocationDistance = 0.0
                for (index, step) in activeState.currentLegSteps.dropFirst(nextStepIndex).enumerated() {
                    guard let stepCoordinates = step.shape?.coordinates,
                          let distance = stepCoordinates.distance() else { continue }

                    if index == 0 {
                        if distance >= geometryFramingAfterManeuver.distanceToFrameAfterManeuver {
                            let trimmedStepCoordinates = stepCoordinates
                                .trimmed(distance: geometryFramingAfterManeuver.distanceToFrameAfterManeuver)
                            compoundManeuvers.append(trimmedStepCoordinates)
                            break
                        } else {
                            compoundManeuvers.append(stepCoordinates)
                            totalDistance += distance
                        }
                    } else if distance >= 0.0, totalDistance < geometryFramingAfterManeuver
                        .distanceToCoalesceCompoundManeuvers
                    {
                        if distance + totalDistance >= geometryFramingAfterManeuver
                            .distanceToCoalesceCompoundManeuvers
                        {
                            let remanentDistance = geometryFramingAfterManeuver
                                .distanceToCoalesceCompoundManeuvers - totalDistance
                            let trimmedStepCoordinates = stepCoordinates.trimmed(distance: remanentDistance)
                            compoundManeuvers.append(trimmedStepCoordinates)
                            break
                        } else {
                            compoundManeuvers.append(stepCoordinates)
                            totalDistance += distance
                        }
                    }
                }
            }

            let coordinatesForManeuverFraming = compoundManeuvers.reduce([], +)
            var coordinatesToFrame = coordinatesToManeuver.sliced(
                from: nil,
                to: LineString(coordinatesToManeuver).coordinateFromStart(distance: lookaheadDistance)
            )
            let pitchNearManeuver = followingCameraOptions.pitchNearManeuver
            if pitchNearManeuver.enabled,
               activeState.distanceRemainingOnStep <= pitchNearManeuver.triggerDistanceToManeuver
            {
                coordinatesToFrame += coordinatesForManeuverFraming
            }

            if options.followingCameraOptions.centerUpdatesAllowed || followingCamera.center == nil {
                var center = location.coordinate
                if let boundingBox = BoundingBox(from: coordinatesToFrame) {
                    let coordinates = [
                        center,
                        [boundingBox.northEast, boundingBox.southWest].centerCoordinate,
                    ]

                    let centerLineString = LineString(coordinates)
                    let centerLineStringTotalDistance = centerLineString.distance() ?? 0.0
                    let centerCoordDistance = centerLineStringTotalDistance * (1 - pitchСoefficient)
                    if let adjustedCenter = centerLineString.coordinateFromStart(distance: centerCoordDistance) {
                        center = adjustedCenter
                    }
                }

                newOptions.center = center
            }

            if options.followingCameraOptions.zoomUpdatesAllowed || followingCamera.zoom == nil {
                let defaultZoomLevel = 12.0
                let followingCarPlayCameraZoom = zoom(
                    coordinatesToFrame,
                    mapView: mapView,
                    pitch: pitch,
                    maxPitch: followingCameraOptions.defaultPitch,
                    edgeInsets: carPlayCameraPadding,
                    defaultZoomLevel: defaultZoomLevel,
                    maxZoomLevel: followingCameraOptions.zoomRange.upperBound,
                    minZoomLevel: followingCameraOptions.zoomRange.lowerBound
                )
                newOptions.zoom = followingCarPlayCameraZoom
            }

            if options.followingCameraOptions.bearingUpdatesAllowed || followingCamera.bearing == nil {
                var bearing = location.course
                let distance = fmax(
                    lookaheadDistance,
                    geometryFramingAfterManeuver.enabled
                        ? geometryFramingAfterManeuver.distanceToCoalesceCompoundManeuvers
                        : 0.0
                )
                let coordinatesForIntersections = coordinatesToManeuver.sliced(
                    from: nil,
                    to: LineString(coordinatesToManeuver)
                        .coordinateFromStart(distance: distance)
                )

                bearing = self.bearing(
                    location.course,
                    mapView: mapView,
                    coordinatesToManeuver: coordinatesForIntersections
                )
                newOptions.bearing = bearing
            }

            let followingCarPlayCameraAnchor = anchor(
                pitchСoefficient,
                bounds: mapView.bounds,
                edgeInsets: carPlayCameraPadding
            )

            newOptions.anchor = followingCarPlayCameraAnchor

            if options.followingCameraOptions.pitchUpdatesAllowed || followingCamera.pitch == nil {
                newOptions.pitch = CGFloat(pitch)
            }

            if options.followingCameraOptions.paddingUpdatesAllowed || followingCamera.padding == nil {
                if mapView.window?.screen.traitCollection.userInterfaceIdiom == .carPlay {
                    newOptions.padding = UIEdgeInsets(
                        top: followingCarPlayCameraAnchor.y,
                        left: carPlayCameraPadding.left,
                        bottom: mapView.bounds
                            .height - followingCarPlayCameraAnchor.y + 1.0,
                        right: carPlayCameraPadding.right
                    )
                } else {
                    newOptions.padding = carPlayCameraPadding
                }
            }
        }
        return newOptions
    }

    private func newOverviewCamera(with state: ViewportDataSourceState) -> CameraOptions {
        guard let mapView else { return .init() }

        // In active guidance navigation, camera in overview mode is relevant, during free-drive
        // navigation it's not used.
        guard case .active(let activeState) = state.navigationState else { return overviewCamera }

        var newOptions = currentNavigationCameraOptions.overviewCamera
        let remainingCoordinatesOnRoute = activeState.remainingCoordinatesOnRoute

        let carPlayCameraPadding = mapView.safeAreaInsets + UIEdgeInsets.centerEdgeInsets
        let overviewCameraOptions = options.overviewCameraOptions

        if overviewCameraOptions.pitchUpdatesAllowed || overviewCamera.pitch == nil {
            newOptions.pitch = 0.0
        }

        if overviewCameraOptions.centerUpdatesAllowed || overviewCamera.center == nil {
            if let boundingBox = BoundingBox(from: remainingCoordinatesOnRoute) {
                let center = [
                    boundingBox.southWest,
                    boundingBox.northEast,
                ].centerCoordinate

                newOptions.center = center
            }
        }

        newOptions.anchor = anchor(
            bounds: mapView.bounds,
            edgeInsets: carPlayCameraPadding
        )

        if overviewCameraOptions.bearingUpdatesAllowed || overviewCamera.bearing == nil {
            // In case if `NavigationCamera` is already in ``NavigationCameraState/overview`` value
            // of bearing will be also ignored.
            newOptions.bearing = 0.0
        }

        if overviewCameraOptions.zoomUpdatesAllowed || overviewCamera.zoom == nil {
            newOptions.zoom = overviewCameraZoom(
                remainingCoordinatesOnRoute,
                mapView: mapView,
                pitch: newOptions.pitch,
                bearing: newOptions.bearing,
                edgeInsets: carPlayCameraPadding,
                maxZoomLevel: overviewCameraOptions.maximumZoomLevel
            )
        }

        if overviewCameraOptions.paddingUpdatesAllowed || overviewCamera.padding == nil {
            newOptions.padding = carPlayCameraPadding
        }
        return newOptions
    }
}
