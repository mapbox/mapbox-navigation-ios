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
    var occlusionFactor: Value<Double>?
    var congestionConfiguration: CongestionConfiguration
}

/// Manages all the sources/layers used in NavigationMap.
@MainActor
final class NavigationMapStyleManager {
    private let mapView: MapView
    private var lifetimeSubscriptions: Set<AnyCancellable> = []
    private(set) var layersOrder: MapLayersOrder
    private(set) var layerIds: [String]

    var customizedLayerProvider: CustomizedLayerProvider = .init { $0 }

    private let routeFeaturesStore: MapFeaturesStore
    private let waypointFeaturesStore: MapFeaturesStore
    private let arrowFeaturesStore: MapFeaturesStore
    private let voiceInstructionFeaturesStore: MapFeaturesStore
    private let intersectionAnnotationsFeaturesStore: MapFeaturesStore
    private let routeAnnotationsFeaturesStore: MapFeaturesStore
    private let routeAlertsFeaturesStore: MapFeaturesStore

    init(mapView: MapView) {
        self.mapView = mapView
        self.layerIds = mapView.mapboxMap.allLayerIdentifiers.map(\.id)
        self.layersOrder = Self.makeMapLayersOrder()
        self.routeFeaturesStore = .init(mapView: mapView)
        self.waypointFeaturesStore = .init(mapView: mapView)
        self.arrowFeaturesStore = .init(mapView: mapView)
        self.voiceInstructionFeaturesStore = .init(mapView: mapView)
        self.intersectionAnnotationsFeaturesStore = .init(mapView: mapView)
        self.routeAnnotationsFeaturesStore = .init(mapView: mapView)
        self.routeAlertsFeaturesStore = .init(mapView: mapView)

        mapView.mapboxMap.onStyleLoaded.sink { [weak self] _ in
            // MapsSDK removes all layers when a style is loaded, so we have to recreate MapLayersOrder
            self?.layersOrder = Self.makeMapLayersOrder()
            self?.onStyleLoaded()
        }.store(in: &lifetimeSubscriptions)
    }

    func onStyleLoaded() {
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

    func updateIntermediateWaypoints(
        route: Route,
        legIndex: Int,
        config: MapStyleConfig,
        featureProvider: IntermediateWaypointFeatureProvider
    ) {
        waypointFeaturesStore.update(
            using: route.intermediateWaypointsMapFeatures(
                mapView: mapView,
                legIndex: legIndex,
                config: config,
                featureProvider: featureProvider,
                customizedLayerProvider: customizedLayerProvider
            ),
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

        features.append(contentsOf: routes.mainRoute.route.routeLineMapFeatures(
            ids: .main,
            offset: 0,
            isSoftGradient: true,
            isAlternative: false,
            config: config,
            featureProvider: featureProvider,
            customizedLayerProvider: customizedLayerProvider
        ))

        return features
    }

    func setRouteLineOffset(
        _ offset: Double,
        for routeLineIds: FeatureIds.RouteLine
    ) {
        mapView.mapboxMap.setRouteLineOffset(offset, for: routeLineIds)
    }

    private static func makeMapLayersOrder() -> MapLayersOrder {
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
        return .init(builder: {
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
                    waypointIds.baseCircle,
                    waypointIds.innerCircle,
                    waypointIds.markerIcon,
                    NavigationMapView.LayerIdentifier.puck2DLayer,
                    NavigationMapView.LayerIdentifier.puck3DLayer,
                ])
            }
        })
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
