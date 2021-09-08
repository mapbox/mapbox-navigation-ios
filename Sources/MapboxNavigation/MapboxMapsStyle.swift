import MapboxMaps

extension MapboxMaps.Style {
    /**
     Remove the given style layers from the style in order.
     */
    func removeLayers(_ identifiers: Set<String>) {
        identifiers.forEach {
            do {
                try removeLayer(withId: $0)
            } catch {
                NSLog("Failed to remove layer \($0) with error: \(error.localizedDescription).")
            }
        }
    }
    
    /**
     Remove the given sources from the style.
     
     Only remove a source after removing all the style layers that use it.
     */
    func removeSources(_ identifiers: Set<String>) {
        identifiers.forEach {
            do {
                try removeSource(withId: $0)
            } catch {
                NSLog("Failed to remove source \($0) with error: \(error.localizedDescription).")
            }
        }
    }
}
