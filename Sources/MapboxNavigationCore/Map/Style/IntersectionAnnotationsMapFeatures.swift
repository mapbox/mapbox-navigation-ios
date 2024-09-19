import _MapboxNavigationHelpers
import MapboxDirections
import MapboxMaps
import enum SwiftUI.ColorScheme

extension RouteProgress {
    func intersectionAnnotationsMapFeatures(
        ids: FeatureIds.IntersectionAnnotation,
        customizedLayerProvider: CustomizedLayerProvider
    ) -> [any MapFeature] {
        guard !routeIsComplete else {
            return []
        }

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

        let layers: [any Layer] = [
            with(SymbolLayer(id: ids.layer, source: ids.source)) {
                $0.iconAllowOverlap = .constant(false)
                $0.iconImage = .expression(Exp(.get) {
                    "imageName"
                })
            },
        ]
        return [
            GeoJsonMapFeature(
                id: ids.featureId,
                sources: [
                    .init(
                        id: ids.source,
                        geoJson: .featureCollection(featureCollection)
                    ),
                ],
                customizeSource: { _, _ in },
                layers: layers.map { customizedLayerProvider.customizedLayer($0) },
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
            ),
        ]
    }

    private func intersectionFeature(
        from intersection: Intersection,
        ids: FeatureIds.IntersectionAnnotation
    ) -> Feature? {
        var properties: JSONObject?
        if intersection.yieldSign == true {
            properties = ["imageName": .string(ids.yieldSignImage)]
        }
        if intersection.stopSign == true {
            properties = ["imageName": .string(ids.stopSignImage)]
        }
        if intersection.railroadCrossing == true {
            properties = ["imageName": .string(ids.railroadCrossingImage)]
        }
        if intersection.trafficSignal == true {
            properties = ["imageName": .string(ids.trafficSignalImage)]
        }

        guard let properties else { return nil }

        var feature = Feature(geometry: .point(Point(intersection.location)))
        feature.properties = properties
        return feature
    }

    private static func upsertIntersectionSymbolImages(
        map: MapboxMap,
        ids: FeatureIds.IntersectionAnnotation
    ) {
        for (imageName, imageIdentifier) in imageNameToMapIdentifier(ids: ids) {
            if let image = Bundle.module.image(named: imageName) {
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
        ]
    }
}
