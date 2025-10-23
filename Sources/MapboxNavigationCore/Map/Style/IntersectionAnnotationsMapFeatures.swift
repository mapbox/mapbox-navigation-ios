import _MapboxNavigationHelpers
import MapboxDirections
import MapboxMaps
import enum SwiftUI.ColorScheme

struct IntersectionAnnotationsStyleContent: MapStyleContent {
    let source: GeoJSONSource
    let symbolLayer: SymbolLayer

    var body: some MapStyleContent {
        source

        symbolLayer
            .slot(NavigationSlot.aboveBasemap)
    }
}

private let imageNameKey = "imageName"

extension RouteProgress {
    func intersectionAnnotationsMapFeatures(
        ids: FeatureIds.IntersectionAnnotation,
        mapboxMap: MapboxMap,
        customizedSymbolLayerProvider: CustomizedTypeLayerProvider<SymbolLayer>
    ) -> (IntersectionAnnotationsStyleContent, MapFeature)? {
        guard !routeIsComplete else { return nil }

        var featureCollection = FeatureCollection(features: [])

        let stepProgress = currentLegProgress.currentStepProgress
        let intersectionIndex = stepProgress.intersectionIndex
        let intersections = stepProgress.intersectionsIncludingUpcomingManeuverIntersection ?? []
        let stepIntersections = Array(intersections.dropFirst(intersectionIndex))

        for intersection in stepIntersections {
            if let feature = intersectionFeature(from: intersection, ids: ids) {
                featureCollection.features.append(feature)
            }
        }

        let source = GeoJsonMapFeature.Source(
            id: ids.source,
            geoJson: .featureCollection(featureCollection)
        )
        guard let sourceData = source.data() else { return nil }

        let layer = with(SymbolLayer(id: ids.layer, source: ids.source)) {
            $0.iconAllowOverlap = .constant(false)
            $0.iconImage = .expression(Exp(.get) {
                imageNameKey
            })
        }

        Self.upsertIntersectionSymbolImages(
            map: mapboxMap,
            ids: ids
        )

        let customizedLayer = customizedSymbolLayerProvider.customizedLayer(layer)

        let content = IntersectionAnnotationsStyleContent(
            source: sourceData,
            symbolLayer: customizedLayer
        )

        let mapFeature = GeoJsonMapFeature(
            id: ids.featureId,
            sources: [source],
            customizeSource: { _, _ in },
            layers: [customizedLayer],
            onBeforeAdd: { mapView in
                Self.upsertIntersectionSymbolImages(
                    map: mapView.mapboxMap,
                    ids: ids
                )
            },
            onUpdate: { mapView in
                Self.upsertIntersectionSymbolImages(
                    map: mapView.mapboxMap,
                    ids: ids
                )
            },
            onAfterRemove: { mapView in
                do {
                    try Self.removeIntersectionSymbolImages(
                        map: mapView.mapboxMap,
                        ids: ids
                    )
                } catch {
                    Log.error(
                        "Failed to remove intersection annotation images with error \(error)",
                        category: .navigationUI
                    )
                }
            }
        )
        return (content, mapFeature)
    }

    private func intersectionFeature(
        from intersection: Intersection,
        ids: FeatureIds.IntersectionAnnotation
    ) -> Feature? {
        var properties: JSONObject?
        if intersection.yieldSign == true {
            properties = [imageNameKey: .string(ids.yieldSignImage)]
        }
        if intersection.stopSign == true {
            properties = [imageNameKey: .string(ids.stopSignImage)]
        }
        if intersection.railroadCrossing == true {
            properties = [imageNameKey: .string(ids.railroadCrossingImage)]
        }
        if intersection.trafficSignal == true {
            properties = [imageNameKey: .string(ids.trafficSignalImage)]
        }

        guard let properties else { return nil }

        var feature = Feature(geometry: .point(Point(intersection.location)))
        feature.properties = properties
        return feature
    }

    func debugIntersectionAnnotationsMapStyleContent(
        ids: FeatureIds.IntersectionAnnotation,
        mapboxMap: MapboxMap,
        customizedSymbolLayerProvider: CustomizedTypeLayerProvider<SymbolLayer>
    ) -> IntersectionAnnotationsStyleContent? {
        guard !routeIsComplete else { return nil }

        var featureCollection = FeatureCollection(features: [])

        let stepProgress = currentLegProgress.currentStepProgress
        let intersectionIndex = stepProgress.intersectionIndex
        let intersections = stepProgress.intersectionsIncludingUpcomingManeuverIntersection ?? []
        let stepIntersections = Array(intersections.dropFirst(intersectionIndex))

        for intersection in stepIntersections {
            if let feature = debugIntersectionMarkFeature(from: intersection, ids: ids) {
                featureCollection.features.append(feature)
            }
        }

        let source = GeoJsonMapFeature.Source(
            id: ids.source,
            geoJson: .featureCollection(featureCollection)
        )
        guard let sourceData = source.data() else { return nil }

        let layer = with(SymbolLayer(id: ids.layer, source: ids.source)) {
            $0.iconAllowOverlap = .constant(false)
            $0.iconImage = .expression(Exp(.get) {
                imageNameKey
            })
        }

        Self.upsertIntersectionSymbolImages(
            map: mapboxMap,
            ids: ids
        )

        let customizedLayer = customizedSymbolLayerProvider.customizedLayer(layer)
        let content = IntersectionAnnotationsStyleContent(
            source: sourceData,
            symbolLayer: customizedLayer
        )
        return content
    }

    private func debugIntersectionMarkFeature(
        from intersection: Intersection,
        ids: FeatureIds.IntersectionAnnotation
    ) -> Feature? {
        let properties: JSONObject = [imageNameKey: .string(ids.debugCrossMarkImage)]
        var feature = Feature(geometry: .point(Point(intersection.location)))
        feature.properties = properties
        return feature
    }

    private static func upsertIntersectionSymbolImages(
        map: MapboxMap,
        ids: FeatureIds.IntersectionAnnotation
    ) {
        for (imageName, imageIdentifier) in imageNameToMapIdentifier(ids: ids) {
            if let image = Bundle.mapboxNavigationUXCore.image(named: imageName) {
                map.provisionImage(id: imageIdentifier) { style in
                    try style.addImage(image, id: imageIdentifier)
                }
            }
        }
    }

    private static func removeIntersectionSymbolImages(
        map: MapboxMap,
        ids: FeatureIds.IntersectionAnnotation
    ) throws {
        for (_, imageIdentifier) in imageNameToMapIdentifier(ids: ids) {
            try map.removeImage(withId: imageIdentifier)
        }
    }

    private static func imageNameToMapIdentifier(
        ids: FeatureIds.IntersectionAnnotation
    ) -> [String: String] {
        return [
            "TrafficSignal": ids.trafficSignalImage,
            "RailroadCrossing": ids.railroadCrossingImage,
            "YieldSign": ids.yieldSignImage,
            "StopSign": ids.stopSignImage,
            "debug_cross_mark": ids.debugCrossMarkImage,
        ]
    }
}
