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
    private let routerCalloutViewProvider: RouteCalloutViewProvider

    init(
        for navigationRoutes: NavigationRoutes,
        routeCalloutViewProvider: RouteCalloutViewProvider
    ) {
        self.navigationRoutes = navigationRoutes
        self.routerCalloutViewProvider = routeCalloutViewProvider

        var annotations = [ViewAnnotation]()
        var featureId = navigationRoutes.mainRoute.routeId.rawValue

        let viewContainers = routeCalloutViewProvider.createRouteCalloutViewContainers(for: navigationRoutes)

        if let mainContainer = viewContainers[navigationRoutes.mainRoute.routeId] {
            let viewAnnotation = mainContainer.makeViewAnnotation(
                for: navigationRoutes.mainRoute.route,
                fallbackLayerId: FeatureIds.RouteAnnotation.main.layerId,
                anchors: routeCalloutViewProvider.anchorConfigs
            )
            viewAnnotation.setNeedsUpdateSize()
            annotations.append(viewAnnotation)
        }

        for (idx, alternativeRoute) in navigationRoutes.alternativeRoutes.enumerated() {
            featureId += alternativeRoute.routeId.rawValue

            if let alternativeContainer = viewContainers[alternativeRoute.routeId] {
                let viewAnnotation = alternativeContainer.makeViewAnnotation(
                    for: alternativeRoute.route,
                    fallbackLayerId: FeatureIds.RouteAnnotation.alternative(index: idx).layerId,
                    anchors: routeCalloutViewProvider.anchorConfigs
                )
                viewAnnotation.setNeedsUpdateSize()
                annotations.append(viewAnnotation)
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
            routeCalloutViewProvider: routerCalloutViewProvider
        )
    }
}

extension RouteCalloutViewContainer {
    @_spi(MapboxInternal)
    @MainActor
    public func makeViewAnnotation(
        for route: Route,
        fallbackLayerId: String,
        anchors: [ViewAnnotationAnchorConfig]
    ) -> ViewAnnotation {
        let geometry = route.geometryForCallout(clampedTo: allowedRouteOffsetRange, placement: placement)
        let annotation = if let geometry {
            ViewAnnotation(annotatedFeature: .geometry(geometry), view: view)
        } else {
            ViewAnnotation(layerId: fallbackLayerId, view: view)
        }
        annotation.ignoreCameraPadding = true
        annotation.variableAnchors = anchors
        annotation.onAnchorChanged = onAnchorConfigChanged
        return annotation
    }
}

extension Route {
    fileprivate func geometryForCallout(
        clampedTo range: ClosedRange<Double>,
        placement: RouteCalloutViewContainer.Placement
    ) -> Geometry? {
        if case .fixed(let fraction) = placement {
            let centerDistance = distance *
                min(range.lowerBound + (range.upperBound - range.lowerBound) * fraction, 1)
            let coordinate = shape?.coordinateFromStart(distance: centerDistance)
            return coordinate.map { Point($0).geometry }
        }

        return shape?.trimmed(
            from: distance * range.lowerBound,
            to: distance * range.upperBound
        )?.geometry
    }
}
