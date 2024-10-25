import Combine
import MapboxDirections
@_spi(Experimental) import MapboxMaps
import enum SwiftUI.ColorScheme
import UIKit

struct CustomizedLayerProvider {
    var customizedLayer: (Layer) -> Layer
}

struct MapStyleConfig: Equatable {
    var routeCasingColor: UIColor
    var routeAlternateCasingColor: UIColor
    var routeRestrictedAreaColor: UIColor
    var traversedRouteColor: UIColor?
    var maneuverArrowColor: UIColor
    var maneuverArrowStrokeColor: UIColor

    var routeAnnotationSelectedColor: UIColor
    var routeAnnotationColor: UIColor
    var routeAnnotationSelectedTextColor: UIColor
    var routeAnnotationTextColor: UIColor
    var routeAnnotationMoreTimeTextColor: UIColor
    var routeAnnotationLessTimeTextColor: UIColor
    var routeAnnotationTextFont: UIFont

    var routeLineTracksTraversal: Bool
    var isRestrictedAreaEnabled: Bool
    var showsTrafficOnRouteLine: Bool
    var showsAlternatives: Bool
    var showsIntermediateWaypoints: Bool
    var occlusionFactor: Value<Double>?
    var congestionConfiguration: CongestionConfiguration

    var waypointColor: UIColor
    var waypointStrokeColor: UIColor
}

/// Manages all the sources/layers used in NavigationMap.
@MainActor
final class NavigationMapStyleManager {
    private let mapView: MapView
    private var lifetimeSubscriptions: Set<AnyCancellable> = []
    private var layersOrder: MapLayersOrder
    private var layerIds: [String]

    var customizedLayerProvider: CustomizedLayerProvider = .init { $0 }
    var customRouteLineLayerPosition: LayerPosition?

    private let routeFeaturesStore: MapFeaturesStore
    private let waypointFeaturesStore: MapFeaturesStore
    private let arrowFeaturesStore: MapFeaturesStore
    private let voiceInstructionFeaturesStore: MapFeaturesStore
    private let intersectionAnnotationsFeaturesStore: MapFeaturesStore
    private let routeAnnotationsFeaturesStore: MapFeaturesStore
    private let routeAlertsFeaturesStore: MapFeaturesStore

    init(mapView: MapView, customRouteLineLayerPosition: LayerPosition?) {
        self.mapView = mapView
        self.layersOrder = Self.makeMapLayersOrder(
            with: mapView,
            customRouteLineLayerPosition: customRouteLineLayerPosition
        )
        self.layerIds = mapView.mapboxMap.allLayerIdentifiers.map(\.id)
        self.routeFeaturesStore = .init(mapView: mapView)
        self.waypointFeaturesStore = .init(mapView: mapView)
        self.arrowFeaturesStore = .init(mapView: mapView)
        self.voiceInstructionFeaturesStore = .init(mapView: mapView)
        self.intersectionAnnotationsFeaturesStore = .init(mapView: mapView)
        self.routeAnnotationsFeaturesStore = .init(mapView: mapView)
        self.routeAlertsFeaturesStore = .init(mapView: mapView)

        mapView.mapboxMap.onStyleLoaded.sink { [weak self] _ in
            self?.onStyleLoaded()
        }.store(in: &lifetimeSubscriptions)
    }

    func onStyleLoaded() {
        // MapsSDK removes all layers when a style is loaded, so we have to recreate MapLayersOrder.
        layersOrder = Self.makeMapLayersOrder(with: mapView, customRouteLineLayerPosition: customRouteLineLayerPosition)
        layerIds = mapView.mapboxMap.allLayerIdentifiers.map(\.id)
        layersOrder.setStyleIds(layerIds)

        routeFeaturesStore.styleLoaded(order: &layersOrder)
        waypointFeaturesStore.styleLoaded(order: &layersOrder)
        arrowFeaturesStore.styleLoaded(order: &layersOrder)
        voiceInstructionFeaturesStore.styleLoaded(order: &layersOrder)
        intersectionAnnotationsFeaturesStore.styleLoaded(order: &layersOrder)
        routeAnnotationsFeaturesStore.styleLoaded(order: &layersOrder)
        routeAlertsFeaturesStore.styleLoaded(order: &layersOrder)
    }

    func updateRoutes(
        _ routes: NavigationRoutes,
        config: MapStyleConfig,
        featureProvider: RouteLineFeatureProvider
    ) {
        routeFeaturesStore.update(
            using: routeLineMapFeatures(
                routes: routes,
                config: config,
                featureProvider: featureProvider,
                customizedLayerProvider: customizedLayerProvider
            ),
            order: &layersOrder
        )
    }

    func updateWaypoints(
        route: Route,
        legIndex: Int,
        config: MapStyleConfig,
        featureProvider: WaypointFeatureProvider
    ) {
        let waypoints = route.waypointsMapFeature(
            mapView: mapView,
            legIndex: legIndex,
            config: config,
            featureProvider: featureProvider,
            customizedLayerProvider: customizedLayerProvider
        )
        waypointFeaturesStore.update(
            using: waypoints.map { [$0] } ?? [],
            order: &layersOrder
        )
    }

    func updateArrows(
        route: Route,
        legIndex: Int,
        stepIndex: Int,
        config: MapStyleConfig
    ) {
        guard route.containsStep(at: legIndex, stepIndex: stepIndex)
        else {
            removeArrows(); return
        }

        arrowFeaturesStore.update(
            using: route.maneuverArrowMapFeatures(
                ids: .nextArrow(),
                cameraZoom: mapView.mapboxMap.cameraState.zoom,
                legIndex: legIndex,
                stepIndex: stepIndex,
                config: config,
                customizedLayerProvider: customizedLayerProvider
            ),
            order: &layersOrder
        )
    }

    func updateVoiceInstructions(route: Route) {
        voiceInstructionFeaturesStore.update(
            using: route.voiceInstructionMapFeatures(
                ids: .init(),
                customizedLayerProvider: customizedLayerProvider
            ),
            order: &layersOrder
        )
    }

    func updateIntersectionAnnotations(routeProgress: RouteProgress) {
        intersectionAnnotationsFeaturesStore.update(
            using: routeProgress.intersectionAnnotationsMapFeatures(
                ids: .currentRoute,
                customizedLayerProvider: customizedLayerProvider
            ),
            order: &layersOrder
        )
    }

    func updateRouteAnnotations(
        navigationRoutes: NavigationRoutes,
        annotationKinds: Set<RouteAnnotationKind>,
        config: MapStyleConfig
    ) {
        routeAnnotationsFeaturesStore.update(
            using: navigationRoutes.routeDurationMapFeatures(
                annotationKinds: annotationKinds,
                config: config
            ),
            order: &layersOrder
        )
    }

    func updateRouteAlertsAnnotations(
        navigationRoutes: NavigationRoutes,
        excludedRouteAlertTypes: RoadAlertType,
        distanceTraveled: CLLocationDistance = 0.0
    ) {
        routeAlertsFeaturesStore.update(
            using: navigationRoutes.routeAlertsAnnotationsMapFeatures(
                ids: .default,
                distanceTraveled: distanceTraveled,
                customizedLayerProvider: customizedLayerProvider,
                excludedRouteAlertTypes: excludedRouteAlertTypes
            ),
            order: &layersOrder
        )
    }

    func updateFreeDriveAlertsAnnotations(
        roadObjects: [RoadObjectAhead],
        excludedRouteAlertTypes: RoadAlertType,
        distanceTraveled: CLLocationDistance = 0.0
    ) {
        guard !roadObjects.isEmpty else {
            return removeRoadAlertsAnnotations()
        }
        routeAlertsFeaturesStore.update(
            using: roadObjects.routeAlertsAnnotationsMapFeatures(
                ids: .default,
                distanceTraveled: distanceTraveled,
                customizedLayerProvider: customizedLayerProvider,
                excludedRouteAlertTypes: excludedRouteAlertTypes
            ),
            order: &layersOrder
        )
    }

    func removeRoutes() {
        routeFeaturesStore.update(using: nil, order: &layersOrder)
    }

    func removeWaypoints() {
        waypointFeaturesStore.update(using: nil, order: &layersOrder)
    }

    func removeArrows() {
        arrowFeaturesStore.update(using: nil, order: &layersOrder)
    }

    func removeVoiceInstructions() {
        voiceInstructionFeaturesStore.update(using: nil, order: &layersOrder)
    }

    func removeIntersectionAnnotations() {
        intersectionAnnotationsFeaturesStore.update(using: nil, order: &layersOrder)
    }

    func removeRouteAnnotations() {
        routeAnnotationsFeaturesStore.update(using: nil, order: &layersOrder)
    }

    private func removeRoadAlertsAnnotations() {
        routeAlertsFeaturesStore.update(using: nil, order: &layersOrder)
    }

    func removeAllFeatures() {
        removeRoutes()
        removeWaypoints()
        removeArrows()
        removeVoiceInstructions()
        removeIntersectionAnnotations()
        removeRouteAnnotations()
        removeRoadAlertsAnnotations()
    }

    private func routeLineMapFeatures(
        routes: NavigationRoutes,
        config: MapStyleConfig,
        featureProvider: RouteLineFeatureProvider,
        customizedLayerProvider: CustomizedLayerProvider
    ) -> [any MapFeature] {
        var features: [any MapFeature] = []

        features.append(contentsOf: routes.mainRoute.route.routeLineMapFeatures(
            ids: .main,
            offset: 0,
            isSoftGradient: true,
            isAlternative: false,
            config: config,
            featureProvider: featureProvider,
            customizedLayerProvider: customizedLayerProvider
        ))

        if config.showsAlternatives {
            for (idx, alternativeRoute) in routes.alternativeRoutes.enumerated() {
                let deviationOffset = alternativeRoute.deviationOffset()
                features.append(contentsOf: alternativeRoute.route.routeLineMapFeatures(
                    ids: .alternative(idx: idx),
                    offset: deviationOffset,
                    isSoftGradient: true,
                    isAlternative: true,
                    config: config,
                    featureProvider: featureProvider,
                    customizedLayerProvider: customizedLayerProvider
                ))
            }
        }

        return features
    }

    func setRouteLineOffset(
        _ offset: Double,
        for routeLineIds: FeatureIds.RouteLine
    ) {
        mapView.mapboxMap.setRouteLineOffset(offset, for: routeLineIds)
    }

    private static func makeMapLayersOrder(
        with mapView: MapView,
        customRouteLineLayerPosition: LayerPosition?
    ) -> MapLayersOrder {
        let alternative_0_ids = FeatureIds.RouteLine.alternative(idx: 0)
        let alternative_1_ids = FeatureIds.RouteLine.alternative(idx: 1)
        let mainLineIds = FeatureIds.RouteLine.main
        let arrowIds = FeatureIds.ManeuverArrow.nextArrow()
        let waypointIds = FeatureIds.RouteWaypoints.default
        let voiceInstructionIds = FeatureIds.VoiceInstruction.currentRoute
        let intersectionIds = FeatureIds.IntersectionAnnotation.currentRoute
        let routeAlertIds = FeatureIds.RouteAlertAnnotation.default
        typealias R = MapLayersOrder.Rule
        typealias SlottedRules = MapLayersOrder.SlottedRules

        let allSlotIdentifiers = mapView.mapboxMap.allSlotIdentifiers
        let containsMiddleSlot = Slot.middle.map(allSlotIdentifiers.contains) ?? false
        let legacyPosition: ((String) -> MapboxMaps.LayerPosition?)? = containsMiddleSlot ? nil : {
            legacyLayerPosition(for: $0, mapView: mapView, customRouteLineLayerPosition: customRouteLineLayerPosition)
        }

        return MapLayersOrder(
            builder: {
                SlottedRules(.middle) {
                    R.orderedIds([
                        alternative_0_ids.casing,
                        alternative_0_ids.main,
                    ])
                    R.orderedIds([
                        alternative_1_ids.casing,
                        alternative_1_ids.main,
                    ])
                    R.orderedIds([
                        mainLineIds.traversedRoute,
                        mainLineIds.casing,
                        mainLineIds.main,
                    ])
                    R.orderedIds([
                        arrowIds.arrowStroke,
                        arrowIds.arrow,
                        arrowIds.arrowSymbolCasing,
                        arrowIds.arrowSymbol,
                    ])
                    R.orderedIds([
                        alternative_0_ids.restrictedArea,
                        alternative_1_ids.restrictedArea,
                        mainLineIds.restrictedArea,
                    ])
                    /// To show on top of arrows
                    R.hasPrefix("poi")
                    R.orderedIds([
                        voiceInstructionIds.layer,
                        voiceInstructionIds.circleLayer,
                    ])
                }
                // Setting the top position on the map. We cannot explicitly set `.top` position because `.top`
                // renders behind Place and Transit labels
                SlottedRules(nil) {
                    R.orderedIds([
                        intersectionIds.layer,
                        routeAlertIds.layer,
                        waypointIds.innerCircle,
                        waypointIds.markerIcon,
                        NavigationMapView.LayerIdentifier.puck2DLayer,
                        NavigationMapView.LayerIdentifier.puck3DLayer,
                    ])
                }
            },
            legacyPosition: legacyPosition
        )
    }

    private static func legacyLayerPosition(
        for layerIdentifier: String,
        mapView: MapView,
        customRouteLineLayerPosition: LayerPosition?
    ) -> MapboxMaps.LayerPosition? {
        let mainLineIds = FeatureIds.RouteLine.main
        if layerIdentifier.hasPrefix(mainLineIds.main),
           let customRouteLineLayerPosition,
           !mapView.mapboxMap.allLayerIdentifiers.contains(where: { $0.id.hasPrefix(mainLineIds.main) })
        {
            return customRouteLineLayerPosition
        }

        let alternative_0_ids = FeatureIds.RouteLine.alternative(idx: 0)
        let alternative_1_ids = FeatureIds.RouteLine.alternative(idx: 1)
        let arrowIds = FeatureIds.ManeuverArrow.nextArrow()
        let waypointIds = FeatureIds.RouteWaypoints.default
        let voiceInstructionIds = FeatureIds.VoiceInstruction.currentRoute
        let intersectionIds = FeatureIds.IntersectionAnnotation.currentRoute
        let routeAlertIds = FeatureIds.RouteAlertAnnotation.default

        let lowermostSymbolLayers: [String] = [
            alternative_0_ids.casing,
            alternative_0_ids.main,
            alternative_1_ids.casing,
            alternative_1_ids.main,
            mainLineIds.traversedRoute,
            mainLineIds.casing,
            mainLineIds.main,
            mainLineIds.restrictedArea,
        ].compactMap { $0 }
        let aboveRoadLayers: [String] = [
            arrowIds.arrowStroke,
            arrowIds.arrow,
            arrowIds.arrowSymbolCasing,
            arrowIds.arrowSymbol,
            intersectionIds.layer,
            routeAlertIds.layer,
            waypointIds.innerCircle,
            waypointIds.markerIcon,
        ]
        let uppermostSymbolLayers: [String] = [
            voiceInstructionIds.layer,
            voiceInstructionIds.circleLayer,
            NavigationMapView.LayerIdentifier.puck2DLayer,
            NavigationMapView.LayerIdentifier.puck3DLayer,
        ]
        let isLowermostLayer = lowermostSymbolLayers.contains(layerIdentifier)
        let isAboveRoadLayer = aboveRoadLayers.contains(layerIdentifier)
        let allAddedLayers: [String] = lowermostSymbolLayers + aboveRoadLayers + uppermostSymbolLayers

        var layerPosition: MapboxMaps.LayerPosition?
        var lowerLayers = Set<String>()
        var upperLayers = Set<String>()
        var targetLayer: String?

        if let index = allAddedLayers.firstIndex(of: layerIdentifier) {
            lowerLayers = Set(allAddedLayers.prefix(upTo: index))
            if allAddedLayers.indices.contains(index + 1) {
                upperLayers = Set(allAddedLayers.suffix(from: index + 1))
            }
        }

        var foundAboveLayer = false
        for layerInfo in mapView.mapboxMap.allLayerIdentifiers.reversed() {
            if lowerLayers.contains(layerInfo.id) {
                // find the topmost layer that should be below the layerIdentifier.
                if !foundAboveLayer {
                    layerPosition = .above(layerInfo.id)
                    foundAboveLayer = true
                }
            } else if upperLayers.contains(layerInfo.id) {
                // find the bottommost layer that should be above the layerIdentifier.
                layerPosition = .below(layerInfo.id)
            } else if isLowermostLayer {
                // find the topmost non symbol layer for layerIdentifier in lowermostSymbolLayers.
                if targetLayer == nil,
                   layerInfo.type.rawValue != "symbol",
                   let sourceLayer = mapView.mapboxMap.layerProperty(for: layerInfo.id, property: "source-layer")
                       .value as? String,
                       !sourceLayer.isEmpty
                {
                    if layerInfo.type.rawValue == "circle",
                       let isPersistentCircle = try? mapView.mapboxMap.isPersistentLayer(id: layerInfo.id)
                    {
                        let pitchAlignment = mapView.mapboxMap.layerProperty(
                            for: layerInfo.id,
                            property: "circle-pitch-alignment"
                        ).value as? String
                        if isPersistentCircle || (pitchAlignment != "map") {
                            continue
                        }
                    }
                    targetLayer = layerInfo.id
                }
            } else if isAboveRoadLayer {
                // find the topmost road name label layer for layerIdentifier in arrowLayers.
                if targetLayer == nil,
                   layerInfo.id.contains("road-label"),
                   mapView.mapboxMap.layerExists(withId: layerInfo.id)
                {
                    targetLayer = layerInfo.id
                }
            } else {
                // find the topmost layer for layerIdentifier in uppermostSymbolLayers.
                if targetLayer == nil,
                   let sourceLayer = mapView.mapboxMap.layerProperty(for: layerInfo.id, property: "source-layer")
                       .value as? String,
                       !sourceLayer.isEmpty
                {
                    targetLayer = layerInfo.id
                }
            }
        }

        guard let targetLayer else { return layerPosition }
        guard let layerPosition else { return .above(targetLayer) }

        if isLowermostLayer {
            // For layers should be below symbol layers.
            if case .below(let sequenceLayer) = layerPosition, !lowermostSymbolLayers.contains(sequenceLayer) {
                // If the sequenceLayer isn't in lowermostSymbolLayers, it's above symbol layer.
                // So for the layerIdentifier, it should be put above the targetLayer, which is the topmost non symbol
                // layer,
                // but under the symbol layers.
                return .above(targetLayer)
            }
        } else if isAboveRoadLayer {
            // For layers should be above road name labels but below other symbol layers.
            if case .below(let sequenceLayer) = layerPosition, uppermostSymbolLayers.contains(sequenceLayer) {
                // If the sequenceLayer is in uppermostSymbolLayers, it's above all symbol layers.
                // So for the layerIdentifier, it should be put above the targetLayer, which is the topmost road name
                // symbol layer.
                return .above(targetLayer)
            } else if case .above(let sequenceLayer) = layerPosition, lowermostSymbolLayers.contains(sequenceLayer) {
                // If the sequenceLayer is in lowermostSymbolLayers, it's below all symbol layers.
                // So for the layerIdentifier, it should be put above the targetLayer, which is the topmost road name
                // symbol layer.
                return .above(targetLayer)
            }
        } else {
            // For other layers should be uppermost and above symbol layers.
            if case .above(let sequenceLayer) = layerPosition, !uppermostSymbolLayers.contains(sequenceLayer) {
                // If the sequenceLayer isn't in uppermostSymbolLayers, it's below some symbol layers.
                // So for the layerIdentifier, it should be put above the targetLayer, which is the topmost layer.
                return .above(targetLayer)
            }
        }

        return layerPosition
    }
}

extension NavigationMapStyleManager {
    // TODO: These ids are specific to Standard style, we should allow customers to customize this
    var poiLayerIds: [String] {
        let poiLayerIds = layerIds.filter { layerId in
            NavigationMapView.LayerIdentifier.clickablePoiLabels.contains {
                layerId.hasPrefix($0)
            }
        }
        return Array(poiLayerIds)
    }
}
