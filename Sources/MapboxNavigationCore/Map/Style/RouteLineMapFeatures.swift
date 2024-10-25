import _MapboxNavigationHelpers
import MapboxDirections
@_spi(Experimental) import MapboxMaps
import Turf
import UIKit

struct LineGradientSettings {
    let isSoft: Bool
    let baseColor: UIColor
    let featureColor: (Turf.Feature) -> UIColor
}

struct RouteLineFeatureProvider {
    var customRouteLineLayer: (String, String) -> Layer?
    var customRouteCasingLineLayer: (String, String) -> Layer?
    var customRouteRestrictedAreasLineLayer: (String, String) -> Layer?
}

extension Route {
    func routeLineMapFeatures(
        ids: FeatureIds.RouteLine,
        offset: Double,
        isSoftGradient: Bool,
        isAlternative: Bool,
        config: MapStyleConfig,
        featureProvider: RouteLineFeatureProvider,
        customizedLayerProvider: CustomizedLayerProvider
    ) -> [any MapFeature] {
        var features: [any MapFeature] = []

        if let shape {
            let congestionFeatures = congestionFeatures(
                legIndex: nil,
                rangesConfiguration: config.congestionConfiguration.ranges
            )
            let gradientStops = routeLineCongestionGradient(
                congestionFeatures: congestionFeatures,
                isMain: !isAlternative,
                isSoft: isSoftGradient,
                config: config
            )
            let colors = config.congestionConfiguration.colors
            let trafficGradient: Value<StyleColor> = .expression(
                .routeLineGradientExpression(
                    gradientStops,
                    lineBaseColor: isAlternative ? colors.alternativeRouteColors.unknown : colors.mainRouteColors
                        .unknown,
                    isSoft: isSoftGradient
                )
            )

            var sources: [GeoJsonMapFeature.Source] = [
                .init(
                    id: ids.source,
                    geoJson: .init(Feature(geometry: .lineString(shape)))
                ),
            ]

            let customRouteLineLayer = featureProvider.customRouteLineLayer(ids.main, ids.source)
            let customRouteCasingLineLayer = featureProvider.customRouteCasingLineLayer(ids.casing, ids.source)
            var layers: [any Layer] = [
                customRouteLineLayer ?? customizedLayerProvider.customizedLayer(defaultRouteLineLayer(
                    ids: ids,
                    isAlternative: isAlternative,
                    trafficGradient: trafficGradient,
                    config: config
                )),
                customRouteCasingLineLayer ?? customizedLayerProvider.customizedLayer(defaultRouteCasingLineLayer(
                    ids: ids,
                    isAlternative: isAlternative,
                    config: config
                )),
            ]

            if let traversedRouteColor = config.traversedRouteColor, !isAlternative, config.routeLineTracksTraversal {
                layers.append(
                    customizedLayerProvider.customizedLayer(defaultTraversedRouteLineLayer(
                        ids: ids,
                        traversedRouteColor: traversedRouteColor,
                        config: config
                    ))
                )
            }

            let restrictedRoadsFeatures: [Feature]? = config.isRestrictedAreaEnabled ? restrictedRoadsFeatures() : nil
            let restrictedAreaGradientExpression: Value<StyleColor>? = restrictedRoadsFeatures
                .map { routeLineRestrictionsGradient($0, config: config) }
                .map {
                    .expression(
                        MapboxMaps.Expression.routeLineGradientExpression(
                            $0,
                            lineBaseColor: config.routeRestrictedAreaColor
                        )
                    )
                }

            if let restrictedRoadsFeatures, let restrictedAreaGradientExpression {
                let shape = LineString(restrictedRoadsFeatures.compactMap {
                    guard case .lineString(let lineString) = $0.geometry else {
                        return nil
                    }
                    return lineString.coordinates
                }.reduce([CLLocationCoordinate2D](), +))

                sources.append(
                    .init(
                        id: ids.restrictedAreaSource,
                        geoJson: .geometry(.lineString(shape))
                    )
                )
                let customRouteRestrictedAreasLine = featureProvider.customRouteRestrictedAreasLineLayer(
                    ids.restrictedArea,
                    ids.restrictedAreaSource
                )

                layers.append(
                    customRouteRestrictedAreasLine ??
                        customizedLayerProvider.customizedLayer(defaultRouteRestrictedAreasLine(
                            ids: ids,
                            gradientExpression: restrictedAreaGradientExpression,
                            config: config
                        ))
                )
            }

            features.append(
                GeoJsonMapFeature(
                    id: ids.main,
                    sources: sources,
                    customizeSource: { source, _ in
                        source.lineMetrics = true
                        source.tolerance = 0.375
                    },
                    layers: layers,
                    onAfterAdd: { mapView in
                        mapView.mapboxMap.setRouteLineOffset(offset, for: ids)
                    },
                    onUpdate: { mapView in
                        mapView.mapboxMap.setRouteLineOffset(offset, for: ids)
                    },
                    onAfterUpdate: { mapView in
                        let map: MapboxMap = mapView.mapboxMap
                        try map.updateLayer(withId: ids.main, type: LineLayer.self, update: { layer in
                            layer.lineGradient = trafficGradient
                        })
                        if let restrictedAreaGradientExpression {
                            try map.updateLayer(withId: ids.restrictedArea, type: LineLayer.self, update: { layer in
                                layer.lineGradient = restrictedAreaGradientExpression
                            })
                        }
                    }
                )
            )
        }

        return features
    }

    private func defaultRouteLineLayer(
        ids: FeatureIds.RouteLine,
        isAlternative: Bool,
        trafficGradient: Value<StyleColor>,
        config: MapStyleConfig
    ) -> LineLayer {
        let colors = config.congestionConfiguration.colors
        let routeColors = isAlternative ? colors.alternativeRouteColors : colors.mainRouteColors
        return with(LineLayer(id: ids.main, source: ids.source)) {
            $0.lineColor = .constant(.init(routeColors.unknown))
            $0.lineWidth = .expression(.routeLineWidthExpression())
            $0.lineJoin = .constant(.round)
            $0.lineCap = .constant(.round)
            $0.lineGradient = trafficGradient
            $0.lineDepthOcclusionFactor = config.occlusionFactor
            $0.lineEmissiveStrength = .constant(1)
        }
    }

    private func defaultRouteCasingLineLayer(
        ids: FeatureIds.RouteLine,
        isAlternative: Bool,
        config: MapStyleConfig
    ) -> LineLayer {
        let lineColor = isAlternative ? config.routeAlternateCasingColor : config.routeCasingColor
        return with(LineLayer(id: ids.casing, source: ids.source)) {
            $0.lineColor = .constant(.init(lineColor))
            $0.lineWidth = .expression(.routeCasingLineWidthExpression())
            $0.lineJoin = .constant(.round)
            $0.lineCap = .constant(.round)
            $0.lineDepthOcclusionFactor = config.occlusionFactor
            $0.lineEmissiveStrength = .constant(1)
        }
    }

    private func defaultTraversedRouteLineLayer(
        ids: FeatureIds.RouteLine,
        traversedRouteColor: UIColor,
        config: MapStyleConfig
    ) -> LineLayer {
        return with(LineLayer(id: ids.traversedRoute, source: ids.source)) {
            $0.lineColor = .constant(.init(traversedRouteColor))
            $0.lineWidth = .expression(.routeLineWidthExpression())
            $0.lineJoin = .constant(.round)
            $0.lineCap = .constant(.round)
            $0.lineDepthOcclusionFactor = config.occlusionFactor
            $0.lineEmissiveStrength = .constant(1)
        }
    }

    private func defaultRouteRestrictedAreasLine(
        ids: FeatureIds.RouteLine,
        gradientExpression: Value<StyleColor>?,
        config: MapStyleConfig
    ) -> LineLayer {
        return with(LineLayer(id: ids.restrictedArea, source: ids.restrictedAreaSource)) {
            $0.lineColor = .constant(.init(config.routeRestrictedAreaColor))
            $0.lineWidth = .expression(Expression.routeLineWidthExpression(0.5))
            $0.lineJoin = .constant(.round)
            $0.lineCap = .constant(.round)
            $0.lineOpacity = .constant(0.5)
            $0.lineDepthOcclusionFactor = config.occlusionFactor

            $0.lineGradient = gradientExpression
            $0.lineDasharray = .constant([0.5, 2.0])
        }
    }

    func routeLineCongestionGradient(
        congestionFeatures: [Turf.Feature]? = nil,
        isMain: Bool = true,
        isSoft: Bool,
        config: MapStyleConfig
    ) -> [Double: UIColor] {
        // If `congestionFeatures` is set to nil - check if overridden route line casing is used.
        let colors = config.congestionConfiguration.colors
        let baseColor: UIColor = if let _ = congestionFeatures {
            isMain ? colors.mainRouteColors.unknown : colors.alternativeRouteColors.unknown
        } else {
            config.routeCasingColor
        }
        let configuration = config.congestionConfiguration.colors

        let lineSettings = LineGradientSettings(
            isSoft: isSoft,
            baseColor: baseColor,
            featureColor: {
                guard config.showsTrafficOnRouteLine else {
                    return baseColor
                }
                if case .boolean(let isCurrentLeg) = $0.properties?[CurrentLegAttribute], isCurrentLeg {
                    let colors = isMain ? configuration.mainRouteColors : configuration.alternativeRouteColors
                    if case .string(let congestionLevel) = $0.properties?[CongestionAttribute] {
                        return congestionColor(for: congestionLevel, with: colors)
                    } else {
                        return congestionColor(for: nil, with: colors)
                    }
                }

                return config.routeCasingColor
            }
        )

        return routeLineFeaturesGradient(congestionFeatures, lineSettings: lineSettings)
    }

    /// Given a congestion level, return its associated color.
    func congestionColor(for congestionLevel: String?, with colors: CongestionColorsConfiguration.Colors) -> UIColor {
        switch congestionLevel {
        case "low":
            return colors.low
        case "moderate":
            return colors.moderate
        case "heavy":
            return colors.heavy
        case "severe":
            return colors.severe
        default:
            return colors.unknown
        }
    }

    func routeLineFeaturesGradient(
        _ routeLineFeatures: [Turf.Feature]? = nil,
        lineSettings: LineGradientSettings
    ) -> [Double: UIColor] {
        var gradientStops = [Double: UIColor]()
        var distanceTraveled = 0.0

        if let routeLineFeatures {
            let routeDistance = routeLineFeatures.compactMap { feature -> LocationDistance? in
                if case .lineString(let lineString) = feature.geometry {
                    return lineString.distance()
                } else {
                    return nil
                }
            }.reduce(0, +)
            // lastRecordSegment records the last segmentEndPercentTraveled and associated congestion color added to the
            // gradientStops.
            var lastRecordSegment: (Double, UIColor) = (0.0, .clear)

            for (index, feature) in routeLineFeatures.enumerated() {
                let associatedFeatureColor = lineSettings.featureColor(feature)

                guard case .lineString(let lineString) = feature.geometry,
                      let distance = lineString.distance()
                else {
                    if gradientStops.isEmpty {
                        gradientStops[0.0] = lineSettings.baseColor
                    }
                    return gradientStops
                }
                let minimumPercentGap = 2e-16
                let stopGap = (routeDistance > 0.0) ? max(
                    min(GradientCongestionFadingDistance, distance * 0.1) / routeDistance,
                    minimumPercentGap
                ) : minimumPercentGap

                if index == routeLineFeatures.startIndex {
                    distanceTraveled = distanceTraveled + distance
                    gradientStops[0.0] = associatedFeatureColor

                    if index + 1 < routeLineFeatures.count {
                        let segmentEndPercentTraveled = (routeDistance > 0.0) ? distanceTraveled / routeDistance : 0
                        var currentGradientStop = lineSettings
                            .isSoft ? segmentEndPercentTraveled - stopGap :
                            Double(CGFloat(segmentEndPercentTraveled).nextDown)
                        currentGradientStop = min(max(currentGradientStop, 0.0), 1.0)
                        gradientStops[currentGradientStop] = associatedFeatureColor
                        lastRecordSegment = (currentGradientStop, associatedFeatureColor)
                    }

                    continue
                }

                if index == routeLineFeatures.endIndex - 1 {
                    if associatedFeatureColor == lastRecordSegment.1 {
                        gradientStops[lastRecordSegment.0] = nil
                    } else {
                        let segmentStartPercentTraveled = (routeDistance > 0.0) ? distanceTraveled / routeDistance : 0
                        var currentGradientStop = lineSettings
                            .isSoft ? segmentStartPercentTraveled + stopGap :
                            Double(CGFloat(segmentStartPercentTraveled).nextUp)
                        currentGradientStop = min(max(currentGradientStop, 0.0), 1.0)
                        gradientStops[currentGradientStop] = associatedFeatureColor
                    }

                    continue
                }

                if associatedFeatureColor == lastRecordSegment.1 {
                    gradientStops[lastRecordSegment.0] = nil
                } else {
                    let segmentStartPercentTraveled = (routeDistance > 0.0) ? distanceTraveled / routeDistance : 0
                    var currentGradientStop = lineSettings
                        .isSoft ? segmentStartPercentTraveled + stopGap :
                        Double(CGFloat(segmentStartPercentTraveled).nextUp)
                    currentGradientStop = min(max(currentGradientStop, 0.0), 1.0)
                    gradientStops[currentGradientStop] = associatedFeatureColor
                }

                distanceTraveled = distanceTraveled + distance
                let segmentEndPercentTraveled = (routeDistance > 0.0) ? distanceTraveled / routeDistance : 0
                var currentGradientStop = lineSettings
                    .isSoft ? segmentEndPercentTraveled - stopGap : Double(CGFloat(segmentEndPercentTraveled).nextDown)
                currentGradientStop = min(max(currentGradientStop, 0.0), 1.0)
                gradientStops[currentGradientStop] = associatedFeatureColor
                lastRecordSegment = (currentGradientStop, associatedFeatureColor)
            }

            if gradientStops.isEmpty {
                gradientStops[0.0] = lineSettings.baseColor
            }

        } else {
            gradientStops[0.0] = lineSettings.baseColor
        }

        return gradientStops
    }

    func routeLineRestrictionsGradient(
        _ restrictionFeatures: [Turf.Feature],
        config: MapStyleConfig
    ) -> [Double: UIColor] {
        // If there's no restricted feature, hide the restricted route line layer.
        guard restrictionFeatures.count > 0 else {
            let gradientStops: [Double: UIColor] = [0.0: .clear]
            return gradientStops
        }

        let lineSettings = LineGradientSettings(
            isSoft: false,
            baseColor: config.routeRestrictedAreaColor,
            featureColor: {
                if case .boolean(let isRestricted) = $0.properties?[RestrictedRoadClassAttribute],
                   isRestricted
                {
                    return config.routeRestrictedAreaColor
                }

                return .clear // forcing hiding non-restricted areas
            }
        )

        return routeLineFeaturesGradient(restrictionFeatures, lineSettings: lineSettings)
    }
}
