import Combine
import Foundation
import MapboxDirections
import MapboxMaps

@MainActor
struct ExperimentalRouteCalloutsFeature: RedrawableMapFeature {
    private static let similarTimeThreshold: TimeInterval = 180.0

    let id: String

    private let viewAnnotations: [ViewAnnotation]

    var redrawRequestPublisher: AnyPublisher<AnyHashable, Never> { _redrawRequestPublisher.eraseToAnyPublisher() }
    private var _redrawRequestPublisher: PassthroughSubject<AnyHashable, Never> = .init()

    private var redrawSubscription: AnyCancellable?

    private let navigationRoutes: NavigationRoutes
    private let mapStyleConfig: MapStyleConfig
    private let routerCalloutViewProvider: RouteCalloutViewProvider

    init(
        for navigationRoutes: NavigationRoutes,
        mapStyleConfig: MapStyleConfig,
        routeCalloutViewProvider: RouteCalloutViewProvider
    ) {
        self.navigationRoutes = navigationRoutes
        self.mapStyleConfig = mapStyleConfig
        self.routerCalloutViewProvider = routeCalloutViewProvider

        var annotations = [ViewAnnotation]()
        var featureId = navigationRoutes.mainRoute.routeId.rawValue

        let viewContainers = routeCalloutViewProvider.createRouteCalloutViewContainers(for: navigationRoutes)

        if let mainContainer = viewContainers[navigationRoutes.mainRoute.routeId] {
            let geometry = navigationRoutes.mainRoute.route
                .geometryForCallout(
                    clampedTo: mainContainer.allowedRouteOffsetRange,
                    mapStyleConfig: mapStyleConfig
                )

            let viewAnnotation = if let geometry {
                ViewAnnotation(annotatedFeature: .geometry(geometry), view: mainContainer.view)
            } else {
                ViewAnnotation(layerId: FeatureIds.RouteAnnotation.main.layerId, view: mainContainer.view)
            }
            viewAnnotation.ignoreCameraPadding = true
            viewAnnotation.variableAnchors = routeCalloutViewProvider.anchorConfigs
            viewAnnotation.onAnchorChanged = mainContainer.onAnchorConfigChanged
            viewAnnotation.setNeedsUpdateSize()
            annotations.append(viewAnnotation)
        }

        for (idx, alternativeRoute) in navigationRoutes.alternativeRoutes.enumerated() {
            featureId += alternativeRoute.routeId.rawValue

            if let alternativeContainer = viewContainers[alternativeRoute.routeId] {
                let geometry = alternativeRoute.route
                    .geometryForCallout(
                        clampedTo: alternativeContainer.allowedRouteOffsetRange,
                        mapStyleConfig: mapStyleConfig
                    )

                let viewAnnotattion = if let geometry {
                    ViewAnnotation(annotatedFeature: .geometry(geometry), view: alternativeContainer.view)
                } else {
                    ViewAnnotation(
                        layerId: FeatureIds.RouteAnnotation.alternative(index: idx).layerId,
                        view: alternativeContainer.view
                    )
                }
                viewAnnotattion.ignoreCameraPadding = true
                viewAnnotattion.variableAnchors = routeCalloutViewProvider.anchorConfigs
                viewAnnotattion.onAnchorChanged = alternativeContainer.onAnchorConfigChanged
                viewAnnotattion.setNeedsUpdateSize()
                annotations.append(viewAnnotattion)
            }
        }

        self.id = featureId
        self.viewAnnotations = annotations

        self.redrawSubscription = routeCalloutViewProvider.redrawRequestPublisher
            .map { _ in featureId }
            .subscribe(_redrawRequestPublisher)
    }

    func add(to mapView: MapboxMaps.MapView, order: inout MapLayersOrder) {
        for annotation in viewAnnotations {
            mapView.viewAnnotations.add(annotation)
        }
    }

    func remove(from mapView: MapboxMaps.MapView, order: inout MapLayersOrder) {
        redrawSubscription?.cancel()

        viewAnnotations.forEach { $0.remove() }
    }

    func update(oldValue: any MapFeature, in mapView: MapboxMaps.MapView, order: inout MapLayersOrder) {
        oldValue.remove(from: mapView, order: &order)
        add(to: mapView, order: &order)
    }

    func refreshed() -> Self {
        return Self(
            for: navigationRoutes,
            mapStyleConfig: mapStyleConfig,
            routeCalloutViewProvider: routerCalloutViewProvider
        )
    }
}

extension Route {
    fileprivate func geometryForCallout(
        clampedTo range: ClosedRange<Double> = 0.2...0.8,
        mapStyleConfig: MapStyleConfig
    ) -> Geometry? {
        if case .fixed(let positionModifier) = mapStyleConfig.fixedRouteCalloutPosition {
            let centerDistance = distance *
                (range.lowerBound + (range.upperBound - range.lowerBound) * positionModifier)
            let coordinate = shape?.coordinateFromStart(distance: centerDistance)
            return coordinate.map { Point($0).geometry }
        }

        return shape?.trimmed(
            from: distance * range.lowerBound,
            to: distance * range.upperBound
        )?.geometry
    }
}
