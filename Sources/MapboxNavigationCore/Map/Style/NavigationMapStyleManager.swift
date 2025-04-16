import Combine
import MapboxDirections
@_spi(Experimental) import MapboxMaps
import UIKit

// TODO: remove after declarative Maps API is fully supported.
struct CustomizedLayerProvider {
    var customizedLayer: (Layer) -> Layer
}

struct CustomizedTypeLayerProvider<T: MapStyleContent> {
    var customizedLayer: (T) -> T
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
    var routeAnnotationSelectedCaptionTextColor: UIColor
    var routeAnnotationCaptionTextColor: UIColor
    var routeAnnotationMoreTimeTextColor: UIColor
    var routeAnnotationLessTimeTextColor: UIColor
    var routeAnnotationTextFont: UIFont
    var routeAnnnotationCaptionTextFont: UIFont

    var routeLineTracksTraversal: Bool
    var isRestrictedAreaEnabled: Bool
    var showsTrafficOnRouteLine: Bool
    var showsAlternatives: Bool
    var showsIntermediateWaypoints: Bool
    var showsVoiceInstructionsOnMap: Bool
    var showsIntersectionAnnotations: Bool
    var occlusionFactor: Value<Double>?
    var congestionConfiguration: CongestionConfiguration
    var excludedRouteAlertTypes: RoadAlertType

    var waypointColor: UIColor
    var waypointStrokeColor: UIColor

    var routeCalloutAnchors: [ViewAnnotationAnchor]
    var fixedRouteCalloutPosition: NavigationMapView.FixedRouteCalloutPosition {
        didSet {
            let validRange = 0.0...1.0
            if case .fixed(let position) = fixedRouteCalloutPosition, !validRange.contains(position) {
                assertionFailure("Position value out of range: \(position). Must be between 0.0 and 1.0.")
                fixedRouteCalloutPosition = .fixed(position.clamped(to: validRange))
            }
        }
    }

    var useLegacyEtaRouteAnnotations = false
}

@MainActor
protocol NavigationMapStyleManagerDelegate: AnyObject {
    func styleManager<T>(_ styleManager: NavigationMapStyleManager, layer: T) -> T? where T: Layer & MapStyleContent
}

/// Manages all the sources/layers used in NavigationMap.
@MainActor
final class NavigationMapStyleManager {
    // TODO: remove after declarative Maps API is fully supported.
    var shouldUseDeclarativeApproach: Bool = false {
        didSet {
            guard shouldUseDeclarativeApproach else { return }

            mapContent = NavigationStyleContent(
                routeLines: [:]
            )
        }
    }

    private let mapView: MapView
    private var lifetimeSubscriptions: Set<AnyCancellable> = []
    private var layersOrder: MapLayersOrder
    private var layerIds: [String]

    var customizedLayerProvider: CustomizedLayerProvider = .init { $0 }
    weak var delegate: NavigationMapStyleManagerDelegate?

    private func customizedLayer<T>(_ layer: T) -> T where T: Layer & MapStyleContent {
        guard let customizedLayer = delegate?.styleManager(self, layer: layer) else {
            return layer
        }
        return customizedLayer
    }

    var customRouteLineLayerPosition: LayerPosition? {
        didSet {
            mapContent?.customRoutePosition = customRouteLineLayerPosition
            mapStyleDeclarativeContentUpdate()
        }
    }

    var customizedLineLayerProvider: CustomizedTypeLayerProvider<LineLayer> {
        .init { [weak self] in
            guard let self else { return $0 }
            return customizedLayer($0)
        }
    }

    var customizedSymbolLayerProvider: CustomizedTypeLayerProvider<SymbolLayer> {
        .init { [weak self] in
            guard let self else { return $0 }
            return customizedLayer($0)
        }
    }

    var customizedCircleLayerProvider: CustomizedTypeLayerProvider<CircleLayer> {
        .init { [weak self] in
            guard let self else { return $0 }
            return customizedLayer($0)
        }
    }

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
        self.customRouteLineLayerPosition = customRouteLineLayerPosition
        mapContent?.customRoutePosition = customRouteLineLayerPosition
        mapStyleDeclarativeContentUpdate()

        mapView.mapboxMap.onStyleLoaded.sink { [weak self] _ in
            self?.onStyleLoaded()
        }.store(in: &lifetimeSubscriptions)
    }

    func onStyleLoaded() {
        // MapsSDK removes all layers when a style is loaded, so we have to recreate MapLayersOrder.
        layersOrder = Self.makeMapLayersOrder(with: mapView, customRouteLineLayerPosition: customRouteLineLayerPosition)
        layerIds = mapView.mapboxMap.allLayerIdentifiers.map(\.id)
        layersOrder.setStyleIds(layerIds)

        if !shouldUseDeclarativeApproach {
            routeFeaturesStore.styleLoaded(order: &layersOrder)
            waypointFeaturesStore.styleLoaded(order: &layersOrder)
            arrowFeaturesStore.styleLoaded(order: &layersOrder)
            voiceInstructionFeaturesStore.styleLoaded(order: &layersOrder)
            intersectionAnnotationsFeaturesStore.styleLoaded(order: &layersOrder)
            routeAnnotationsFeaturesStore.styleLoaded(order: &layersOrder)
            routeAlertsFeaturesStore.styleLoaded(order: &layersOrder)
        } else {
            addMiddleSlotIfNeeded()
            // Until ViewAnnotations are supported in Declarative Map Styling in Maps SDK iOS,
            // we should use the old approach for route annotations.
            routeAnnotationsFeaturesStore.styleLoaded(order: &layersOrder)
        }
    }

    private func addMiddleSlotIfNeeded() {
        guard shouldUseDeclarativeApproach else { return }

        // Add middle slot for the route line. The clients can customize the slot position using
        // `NavigationMapView.customRouteLineLayerPosition`.
        if let middleSlot = Slot.middle,
           !mapView.mapboxMap.allSlotIdentifiers.contains(middleSlot)
        {
            try? mapView.mapboxMap.addLayer(
                SlotLayer(id: middleSlot.rawValue), layerPosition: middleSlotPosition()
            )
        }
    }

    private(set) var mapContent: NavigationStyleContent?

    // Should be called for each maps content update
    func mapStyleDeclarativeContentUpdate() {
        guard shouldUseDeclarativeApproach else { return }

        addMiddleSlotIfNeeded()
        if let mapContent {
            mapView.mapboxMap.setMapStyleContent {
                mapContent
            }
        } else {
            mapView.mapboxMap.setMapStyleContent {
                EmptyMapStyleContent()
            }
        }
    }

    func showRoutes(
        _ routes: NavigationRoutes?,
        routeProgress: RouteProgress?,
        annotationKinds: Set<RouteAnnotationKind>,
        config: MapStyleConfig,
        routelineFeatureProvider: RouteLineFeatureProvider,
        waypointFeatureProvider: WaypointFeatureProvider
    ) {
        defer { mapStyleDeclarativeContentUpdate() }
        cleanup()

        guard let routes else { return }

        updateRoutes(routes, config: config, featureProvider: routelineFeatureProvider)
        updateWaypoints(
            routes: routes,
            legIndex: routeProgress?.legIndex,
            config: config,
            featureProvider: waypointFeatureProvider
        )
        updateVoiceInstructions(route: routes.mainRoute.route, config: config)
        updateRouteAnnotations(
            navigationRoutes: routes,
            annotationKinds: annotationKinds,
            config: config
        )
        updateRouteAlertsAnnotations(
            navigationRoutes: routes,
            excludedRouteAlertTypes: config.excludedRouteAlertTypes
        )
        updateIntersectionAnnotations(routeProgress: routeProgress, config: config)
    }

    func updateRouteLine(
        routeProgress: RouteProgress,
        config: MapStyleConfig
    ) {
        updateIntersectionAnnotations(routeProgress: routeProgress, config: config)
        updateRouteAlertsAnnotations(
            navigationRoutes: routeProgress.navigationRoutes,
            excludedRouteAlertTypes: config.excludedRouteAlertTypes,
            distanceTraveled: routeProgress.distanceTraveled
        )

        if routeProgress.routeIsComplete, config.routeLineTracksTraversal {
            removeRouteLines()
            removeArrows()
        } else {
            updateArrows(routeProgress: routeProgress, config: config)
        }
        mapStyleDeclarativeContentUpdate()
    }

    private func updateRoutes(
        _ routes: NavigationRoutes,
        config: MapStyleConfig,
        featureProvider: RouteLineFeatureProvider
    ) {
        let features = routeLineMapFeatures(
            routes: routes,
            config: config,
            featureProvider: featureProvider,
            customizedLayerProvider: customizedLineLayerProvider,
            customPosition: customRouteLineLayerPosition
        )
        if !shouldUseDeclarativeApproach {
            routeFeaturesStore.update(
                using: features.map { $0.1 },
                order: &layersOrder
            )
        } else {
            mapContent?.routeLines = features.reduce(into: [:]) { $0[$1.0.featureIds] = $1.0 }
        }
    }

    func updateWaypoints(
        routes: NavigationRoutes?,
        legIndex: Int?,
        config: MapStyleConfig,
        featureProvider: WaypointFeatureProvider
    ) {
        let feature = routes?.mainRoute.route.waypointsMapFeature(
            mapView: mapView,
            legIndex: legIndex ?? 0,
            config: config,
            featureProvider: featureProvider,
            customizedCircleLayerProvider: customizedCircleLayerProvider,
            customizedSymbolLayerProvider: customizedSymbolLayerProvider
        )
        if shouldUseDeclarativeApproach {
            mapContent?.waypoints = feature?.0
        } else {
            waypointFeaturesStore.update(
                with: feature?.1,
                order: &layersOrder
            )
        }
    }

    func updateArrows(
        routeProgress: RouteProgress?,
        config: MapStyleConfig
    ) {
        guard let routeProgress,
              !routeProgress.routeIsComplete,
              routeProgress.currentLegProgress.followOnStep != nil
        else {
            removeArrows()
            return
        }

        let route = routeProgress.route
        let legIndex = routeProgress.legIndex
        let stepIndex = routeProgress.currentLegProgress.stepIndex + 1
        guard route.containsStep(at: legIndex, stepIndex: stepIndex)
        else {
            removeArrows()
            return
        }

        let arrowFeature = route.maneuverArrowMapFeatures(
            ids: .nextArrow(),
            cameraZoom: mapView.mapboxMap.cameraState.zoom,
            mapboxMap: mapView.mapboxMap,
            legIndex: legIndex,
            stepIndex: stepIndex,
            config: config,
            customizedLineLayerProvider: customizedLineLayerProvider,
            customizedSymbolLayerProvider: customizedSymbolLayerProvider
        )

        if shouldUseDeclarativeApproach {
            mapContent?.maneuverArrow = arrowFeature?.0
        } else {
            arrowFeaturesStore.update(
                with: arrowFeature?.1,
                order: &layersOrder
            )
        }
    }

    func updateVoiceInstructions(route: Route?, config: MapStyleConfig) {
        guard let route, config.showsVoiceInstructionsOnMap else {
            removeVoiceInstructions()
            return
        }
        let feature = route.voiceInstructionMapFeatures(
            ids: .init(),
            customizedSymbolLayerProvider: customizedSymbolLayerProvider,
            customizedCircleLayerProvider: customizedCircleLayerProvider
        )
        if shouldUseDeclarativeApproach {
            mapContent?.voiceInstruction = feature?.0
        } else {
            voiceInstructionFeaturesStore.update(
                with: feature?.1,
                order: &layersOrder
            )
        }
    }

    func updateIntersectionAnnotations(
        routeProgress: RouteProgress?,
        config: MapStyleConfig
    ) {
        guard let routeProgress, config.showsIntersectionAnnotations else {
            removeIntersectionAnnotations()
            return
        }
        let feature = routeProgress.intersectionAnnotationsMapFeatures(
            ids: .currentRoute,
            mapboxMap: mapView.mapboxMap,
            customizedSymbolLayerProvider: customizedSymbolLayerProvider
        )
        if shouldUseDeclarativeApproach {
            mapContent?.intersectionAnnotations = feature?.0
        } else {
            intersectionAnnotationsFeaturesStore.update(
                with: feature?.1,
                order: &layersOrder
            )
        }
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
        navigationRoutes: NavigationRoutes?,
        excludedRouteAlertTypes: RoadAlertType,
        distanceTraveled: CLLocationDistance = 0.0
    ) {
        let feature = navigationRoutes?.routeAlertsAnnotationsMapFeatures(
            ids: .default,
            mapboxMap: mapView.mapboxMap,
            distanceTraveled: distanceTraveled,
            customizedSymbolLayerProvider: customizedSymbolLayerProvider,
            excludedRouteAlertTypes: excludedRouteAlertTypes
        )
        updateAlertsAnnotations(with: feature)
    }

    func updateFreeDriveAlertsAnnotations(
        roadObjects: [RoadObjectAhead],
        excludedRouteAlertTypes: RoadAlertType,
        distanceTraveled: CLLocationDistance = 0.0
    ) {
        guard !roadObjects.isEmpty else {
            removeAlertsAnnotations()
            return
        }

        let feature = roadObjects.routeAlertsAnnotationsMapFeatures(
            ids: .default,
            mapboxMap: mapView.mapboxMap,
            distanceTraveled: distanceTraveled,
            customizedSymbolLayerProvider: customizedSymbolLayerProvider,
            excludedRouteAlertTypes: excludedRouteAlertTypes
        )
        updateAlertsAnnotations(with: feature)
    }

    private func updateAlertsAnnotations(
        with feature: (RouteAlertsStyleContent, MapFeature)?
    ) {
        if shouldUseDeclarativeApproach {
            mapContent?.routeAlert = feature?.0
        } else {
            routeAlertsFeaturesStore.update(
                with: feature?.1,
                order: &layersOrder
            )
        }
    }

    private func removeAlertsAnnotations() {
        if shouldUseDeclarativeApproach {
            mapContent?.routeAlert = nil
        } else {
            routeAlertsFeaturesStore.update(using: nil, order: &layersOrder)
        }
    }

    private func removeRouteLines() {
        if shouldUseDeclarativeApproach {
            mapContent?.routeLines = [:]
        } else {
            routeFeaturesStore.update(using: nil, order: &layersOrder)
        }
    }

    private func removeArrows() {
        if shouldUseDeclarativeApproach {
            mapContent?.maneuverArrow = nil
        } else {
            arrowFeaturesStore.update(using: nil, order: &layersOrder)
        }
    }

    private func removeVoiceInstructions() {
        if shouldUseDeclarativeApproach {
            mapContent?.voiceInstruction = nil
        } else {
            voiceInstructionFeaturesStore.update(using: nil, order: &layersOrder)
        }
    }

    private func removeIntersectionAnnotations() {
        if shouldUseDeclarativeApproach {
            mapContent?.intersectionAnnotations = nil
        } else {
            intersectionAnnotationsFeaturesStore.update(using: nil, order: &layersOrder)
        }
    }

    private func cleanup() {
        if shouldUseDeclarativeApproach {
            mapContent = NavigationStyleContent()
            mapContent?.customRoutePosition = customRouteLineLayerPosition
            routeAnnotationsFeaturesStore.update(using: nil, order: &layersOrder)
        } else {
            routeFeaturesStore.update(using: nil, order: &layersOrder)
            waypointFeaturesStore.update(using: nil, order: &layersOrder)
            arrowFeaturesStore.update(using: nil, order: &layersOrder)
            voiceInstructionFeaturesStore.update(using: nil, order: &layersOrder)
            intersectionAnnotationsFeaturesStore.update(using: nil, order: &layersOrder)
            routeAnnotationsFeaturesStore.update(using: nil, order: &layersOrder)
            routeAlertsFeaturesStore.update(using: nil, order: &layersOrder)
        }
    }

    func removeAllFeatures() {
        cleanup()

        mapStyleDeclarativeContentUpdate()
    }

    private func routeLineMapFeatures(
        routes: NavigationRoutes,
        config: MapStyleConfig,
        featureProvider: RouteLineFeatureProvider,
        customizedLayerProvider: CustomizedTypeLayerProvider<LineLayer>,
        customPosition: LayerPosition?
    ) -> [(RouteLineStyleContent, MapFeature)] {
        var features: [(RouteLineStyleContent, MapFeature)] = []
        let mainRouteFeature = routes.mainRoute.route.routeLineMapFeatures(
            ids: .main,
            offset: 0,
            isSoftGradient: true,
            isAlternative: false,
            config: config,
            featureProvider: featureProvider,
            customizedLayerProvider: customizedLayerProvider,
            customPosition: customPosition
        )
        if let mainRouteFeature {
            features.append(mainRouteFeature)
        }

        if config.showsAlternatives {
            for (idx, alternativeRoute) in routes.alternativeRoutes.enumerated() {
                let deviationOffset = alternativeRoute.deviationOffset()
                if let alternativeRouteFeature = alternativeRoute.route.routeLineMapFeatures(
                    ids: .alternative(idx: idx),
                    offset: deviationOffset,
                    isSoftGradient: true,
                    isAlternative: true,
                    config: config,
                    featureProvider: featureProvider,
                    customizedLayerProvider: customizedLayerProvider,
                    customPosition: customPosition
                ) {
                    features.append(alternativeRouteFeature)
                }
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
            manualLayerPosition(for: $0, mapView: mapView, customRouteLineLayerPosition: customRouteLineLayerPosition)
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

    private func middleSlotPosition() -> MapboxMaps.LayerPosition? {
        var targetLayer: String?

        for layerInfo in mapView.mapboxMap.allLayerIdentifiers.reversed() {
            // find the topmost non symbol layer
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
        }

        guard let targetLayer else { return nil }
        return .above(targetLayer)
    }

    private static func manualLayerPosition(
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
            alternative_0_ids.restrictedArea,
            alternative_1_ids.casing,
            alternative_1_ids.main,
            alternative_1_ids.restrictedArea,
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
        ]
        let uppermostSymbolLayers: [String] = [
            voiceInstructionIds.layer,
            voiceInstructionIds.circleLayer,
            waypointIds.innerCircle,
            waypointIds.markerIcon,
            NavigationMapView.LayerIdentifier.puck2DLayer,
            NavigationMapView.LayerIdentifier.puck3DLayer,
        ]
        let isLowermostLayer = lowermostSymbolLayers.contains(layerIdentifier)
        let isAboveRoadLayer = aboveRoadLayers.contains(layerIdentifier)
        let isUppermostLayer = uppermostSymbolLayers.contains(layerIdentifier)
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
        } else if !isUppermostLayer {
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
