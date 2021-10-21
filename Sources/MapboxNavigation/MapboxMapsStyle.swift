import MapboxMaps

extension MapboxMaps.Style {
    /**
     Remove the given style layers from the style in order.
     
     - parameter identifiers: Set of layer identifiers, which will be removed.
     */
    func removeLayers(_ identifiers: Set<String>) {
        identifiers.forEach {
            do {
                if layerExists(withId: $0) {
                    try removeLayer(withId: $0)
                }
            } catch {
                NSLog("Failed to remove layer \($0) with error: \(error.localizedDescription).")
            }
        }
    }
    
    /**
     Remove the given sources from the style.
     
     Only remove a source after removing all the style layers that use it.
     
     - parameter identifiers: Set of source identifiers, which will be removed.
     */
    func removeSources(_ identifiers: Set<String>) {
        identifiers.forEach {
            do {
                if sourceExists(withId: $0) {
                    try removeSource(withId: $0)
                }
            } catch {
                NSLog("Failed to remove source \($0) with error: \(error.localizedDescription).")
            }
        }
    }
}
