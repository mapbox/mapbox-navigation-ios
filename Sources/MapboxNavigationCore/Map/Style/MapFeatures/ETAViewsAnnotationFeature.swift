import Foundation
import MapboxDirections
import MapboxMaps

struct ETAViewsAnnotationFeature: MapFeature {
    var id: String

    private let viewAnnotations: [ViewAnnotation]

    init(
        for navigationRoutes: NavigationRoutes,
        showMainRoute: Bool,
        showAlternatives: Bool,
        isRelative: Bool,
        annotateAtManeuver: Bool,
        mapStyleConfig: MapStyleConfig
    ) {
        let routesContainTolls = navigationRoutes.alternativeRoutes.contains {
            ($0.route.tollIntersections?.count ?? 0) > 0
        }
        var featureId = ""

        var annotations = [ViewAnnotation]()
        if showAlternatives {
            for (idx, alternativeRoute) in navigationRoutes.alternativeRoutes.enumerated() {
                featureId += alternativeRoute.routeId.rawValue
                let tollsHint = routesContainTolls ? alternativeRoute.route.containsTolls : nil
                let etaView = if isRelative {
                    ETAView(
                        travelTimeDelta: alternativeRoute.expectedTravelTimeDelta,
                        tollsHint: tollsHint,
                        mapStyleConfig: mapStyleConfig
                    )
                } else {
                    ETAView(
                        eta: alternativeRoute.infoFromOrigin.duration,
                        isSelected: false,
                        tollsHint: tollsHint,
                        mapStyleConfig: mapStyleConfig
                    )
                }
                let limit: Range<Double>
                let deviationOffset = alternativeRoute.deviationOffset()
                if annotateAtManeuver {
                    limit = (deviationOffset + 0.01)..<(deviationOffset + 0.05)
                } else {
                    limit = (deviationOffset + 0.01)..<0.8
                }
                let viewAnnotation = if let geometry = alternativeRoute.route.geometryForCallout(
                    clampedTo: limit,
                    mapStyleConfig: mapStyleConfig
                ) {
                    ViewAnnotation(annotatedFeature: .geometry(geometry), view: etaView)
                } else {
                    ViewAnnotation(layerId: FeatureIds.RouteAnnotation.alternative(index: idx).layerId, view: etaView)
                }
                annotations.append(viewAnnotation)
            }

            if showMainRoute {
                featureId += navigationRoutes.mainRoute.routeId.rawValue
                let tollsHint = routesContainTolls ? navigationRoutes.mainRoute.route.containsTolls : nil
                let etaView = ETAView(
                    eta: navigationRoutes.mainRoute.route.expectedTravelTime,
                    isSelected: true,
                    tollsHint: tollsHint,
                    mapStyleConfig: mapStyleConfig
                )
                let viewAnnotation = if let geometry =
                    navigationRoutes.mainRoute.route.geometryForCallout(mapStyleConfig: mapStyleConfig)
                {
                    ViewAnnotation(annotatedFeature: .geometry(geometry), view: etaView)
                } else {
                    ViewAnnotation(layerId: FeatureIds.RouteAnnotation.main.layerId, view: etaView)
                }
                annotations.append(viewAnnotation)
            }
        }

        annotations.forEach {
            guard let etaView = $0.view as? ETAView else { return }
            $0.setup(with: etaView)
        }
        self.id = featureId
        self.viewAnnotations = annotations
    }

    func add(to mapView: MapboxMaps.MapView, order: inout MapLayersOrder) {
        for annotation in viewAnnotations {
            mapView.viewAnnotations.add(annotation)
        }
    }

    func remove(from mapView: MapboxMaps.MapView, order: inout MapLayersOrder) {
        viewAnnotations.forEach { $0.remove() }
    }

    func update(oldValue: any MapFeature, in mapView: MapboxMaps.MapView, order: inout MapLayersOrder) {
        oldValue.remove(from: mapView, order: &order)
        add(to: mapView, order: &order)
    }
}

extension Route {
    fileprivate func geometryForCallout(
        clampedTo range: Range<Double> = 0.2..<0.8,
        mapStyleConfig: MapStyleConfig
    ) -> Geometry? {
        guard !mapStyleConfig.fixedEtaAnnotationPosition else {
            let centerDistance = distance * (range.lowerBound + (range.upperBound - range.lowerBound) / 3)
            let coordinate = shape?.coordinateFromStart(distance: centerDistance)
            return coordinate.map { Point($0).geometry }
        }

        return shape?.trimmed(
            from: distance * range.lowerBound,
            to: distance * range.upperBound
        )?.geometry
    }

    fileprivate var containsTolls: Bool {
        !(tollIntersections?.isEmpty ?? true)
    }
}

extension ViewAnnotation {
    fileprivate func setup(with etaView: ETAView) {
        ignoreCameraPadding = true
        onAnchorChanged = { config in
            etaView.anchor = config.anchor
        }
        variableAnchors = etaView.mapStyleConfig.etaAnnotationAnchors.map {
            ViewAnnotationAnchorConfig(anchor: $0)
        }
        setNeedsUpdateSize()
    }
}
