import Foundation
import MapboxDirections
import MapboxMaps

struct RouteCalloutsFeature: MapFeature {
    private static let similarTimeThreshold: TimeInterval = 180.0

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
        var featureId = ""
        var annotations = [ViewAnnotation]()
        let mainRouteTravelTime = navigationRoutes.mainRoute.route.expectedTravelTime

        if showMainRoute {
            let isOnlyMainRoutePresent = navigationRoutes.alternativeRoutes.isEmpty

            var isSingleFastestRoute = false
            if !isOnlyMainRoutePresent {
                let isFastest = navigationRoutes.alternativeRoutes.allSatisfy {
                    $0.route.expectedTravelTime > mainRouteTravelTime
                }

                isSingleFastestRoute = isFastest && navigationRoutes.alternativeRoutes
                    .allSatisfy {
                        $0.route.expectedTravelTime.wholeMinutes != mainRouteTravelTime.wholeMinutes
                    }
            }

            let isSuggested = navigationRoutes.mainRoute.isSuggested

            let captionText: String?
            captionText = if isOnlyMainRoutePresent {
                "Best".localizedValue(prefix: "ROUTE_CALLOUT_")
            } else if isSingleFastestRoute {
                "Fastest".localizedValue(prefix: "ROUTE_CALLOUT_")
            } else if isSuggested {
                "Suggested".localizedValue(prefix: "ROUTE_CALLOUT_")
            } else {
                nil
            }

            featureId += navigationRoutes.mainRoute.routeId.rawValue
            let containsTolls = navigationRoutes.mainRoute.route.containsTolls

            let calloutView = RouteCalloutView(
                eta: navigationRoutes.mainRoute.route.expectedTravelTime,
                captionText: captionText,
                isSelected: true,
                containsTolls: containsTolls,
                mapStyleConfig: mapStyleConfig
            )

            let viewAnnotation = if let geometry =
                navigationRoutes.mainRoute.route.geometryForCallout(mapStyleConfig: mapStyleConfig)
            {
                ViewAnnotation(annotatedFeature: .geometry(geometry), view: calloutView)
            } else {
                ViewAnnotation(layerId: FeatureIds.RouteAnnotation.main.layerId, view: calloutView)
            }
            annotations.append(viewAnnotation)
        }

        if showAlternatives {
            for (idx, alternativeRoute) in navigationRoutes.alternativeRoutes.enumerated() {
                featureId += alternativeRoute.routeId.rawValue

                let otherAlternativeRoutes = navigationRoutes.alternativeRoutes.filter { $0 != alternativeRoute }
                let otherRoutes: [Route] = [navigationRoutes.mainRoute.route] + otherAlternativeRoutes.map { $0.route }

                let calloutView = Self.calloutViewFor(
                    alternativeRoute: alternativeRoute,
                    otherRoutes: otherRoutes,
                    isRelative: isRelative,
                    mapsStyleConfig: mapStyleConfig
                )

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
                    ViewAnnotation(annotatedFeature: .geometry(geometry), view: calloutView)
                } else {
                    ViewAnnotation(
                        layerId: FeatureIds.RouteAnnotation.alternative(index: idx).layerId,
                        view: calloutView
                    )
                }
                annotations.append(viewAnnotation)
            }
        }

        annotations.forEach {
            guard let calloutView = $0.view as? RouteCalloutView else { return }
            $0.setup(with: calloutView)
        }
        self.id = featureId
        self.viewAnnotations = annotations
    }

    private static func calloutViewFor(
        alternativeRoute: AlternativeRoute,
        otherRoutes: [Route],
        isRelative: Bool,
        mapsStyleConfig: MapStyleConfig
    ) -> RouteCalloutView {
        let calloutView: RouteCalloutView
        let containsTolls = alternativeRoute.route.containsTolls
        let travelTimeDelta = alternativeRoute.expectedTravelTimeDelta

        if isRelative {
            let calloutText: String
            var captionText: String?

            if abs(travelTimeDelta) >= Self.similarTimeThreshold {
                calloutText = DateComponentsFormatter.travelTimeString(
                    travelTimeDelta,
                    signed: false
                )
                captionText = travelTimeDelta < 0
                    ? "faster".localizedValue(prefix: "ROUTE_CALLOUT_")
                    : "slower".localizedValue(prefix: "ROUTE_CALLOUT_")
            } else {
                calloutText = "Similar ETA".localizedValue(prefix: "ROUTE_CALLOUT_")
            }
            calloutView = RouteCalloutView(
                text: calloutText,
                captionText: captionText,
                isSelected: false,
                containsTolls: containsTolls,
                mapStyleConfig: mapsStyleConfig
            )
        } else {
            let isFastest = otherRoutes.allSatisfy {
                $0.expectedTravelTime > alternativeRoute.route.expectedTravelTime
            }

            let isSingleFastestRoute = isFastest && otherRoutes
                .allSatisfy {
                    $0.expectedTravelTime.wholeMinutes != alternativeRoute.route.expectedTravelTime.wholeMinutes
                }

            let isSuggested = alternativeRoute.isSuggested

            let nonRelativeCaptionText: String?
            nonRelativeCaptionText = if isSingleFastestRoute {
                "Fastest".localizedValue(prefix: "ROUTE_CALLOUT_")
            } else if isSuggested {
                "Suggested".localizedValue(prefix: "ROUTE_CALLOUT_")
            } else {
                nil
            }

            calloutView = RouteCalloutView(
                eta: alternativeRoute.infoFromOrigin.duration,
                captionText: nonRelativeCaptionText,
                isSelected: false,
                containsTolls: containsTolls,
                mapStyleConfig: mapsStyleConfig
            )
        }
        return calloutView
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

    fileprivate var containsTolls: Bool {
        !(tollIntersections?.isEmpty ?? true)
    }
}

extension ViewAnnotation {
    fileprivate func setup(with calloutView: RouteCalloutView) {
        ignoreCameraPadding = true
        onAnchorChanged = { config in
            calloutView.anchor = config.anchor
        }
        variableAnchors = calloutView.mapStyleConfig.routeCalloutAnchors.map {
            ViewAnnotationAnchorConfig(anchor: $0)
        }
        setNeedsUpdateSize()
    }
}

extension TimeInterval {
    fileprivate var wholeMinutes: Int {
        Int(self / 60)
    }
}

extension NavigationRoute {
    fileprivate var isSuggested: Bool {
        nativeRoute.getRouteIndex() == 0
    }
}

extension AlternativeRoute {
    fileprivate var isSuggested: Bool {
        nativeRoute.getRouteIndex() == 0
    }
}
