import MapboxMaps

extension MapboxMap {
    /// Adds image to style if it doesn't exist already and log any errors that occur.
    func provisionImage(id: String, _ addImageToMap: (MapboxMap) throws -> Void) {
        if !imageExists(withId: id) {
            do {
                try addImageToMap(self)
            } catch {
                Log.error("Failed to add image (id: \(id)) to style with error \(error)", category: .navigationUI)
            }
        }
    }

    func setRouteLineOffset(
        _ offset: Double,
        for routeLineIds: FeatureIds.RouteLine
    ) {
        guard offset >= 0.0 else { return }
        do {
            let layerIds: [String] = [
                routeLineIds.main,
                routeLineIds.casing,
                routeLineIds.restrictedArea,
            ]

            for layerId in layerIds where layerExists(withId: layerId) {
                try setLayerProperty(
                    for: layerId,
                    property: "line-trim-offset",
                    value: [0.0, Double.minimum(1.0, offset)]
                )
            }
        } catch {
            Log.error("Failed to update route line gradient with error: \(error)", category: .navigationUI)
        }
    }
}
