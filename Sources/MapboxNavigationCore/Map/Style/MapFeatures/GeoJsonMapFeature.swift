import Foundation
import MapboxMaps
import Turf

/// Simplifies source/layer/image managements for MapView
///
/// ## Supported features:
///
/// ### Layers
///
/// Can be added/removed but not updated. Custom update logic can be performed using `onUpdate` callback. This
/// is done for performance reasons and to simplify implementation as map layers doesn't support equatable protocol.
/// If you want to update layers, you can consider assigning updated layer a new id.
///
/// It there is only one source, layers will get it assigned automatically, overwise, layers should has source set
/// manually.
///
/// ### Sources
///
/// Sources can also be added/removed, but unlike layers, sources are always updated.
///
///
struct GeoJsonMapFeature: MapFeature {
    struct Source {
        let id: String
        let geoJson: GeoJSONObject
    }

    typealias LayerId = String
    typealias SourceId = String

    let id: String
    let sources: [SourceId: Source]

    let customizeSource: @MainActor (_ source: inout GeoJSONSource, _ id: String) -> Void

    let layers: [LayerId: any Layer]

    // MARK: Lifecycle callbacks

    let onBeforeAdd: @MainActor (_ mapView: MapView) -> Void
    let onAfterAdd: @MainActor (_ mapView: MapView) -> Void
    let onUpdate: @MainActor (_ mapView: MapView) throws -> Void
    let onAfterUpdate: @MainActor (_ mapView: MapView) throws -> Void
    let onAfterRemove: @MainActor (_ mapView: MapView) -> Void

    init(
        id: String,
        sources: [Source],
        customizeSource: @escaping @MainActor (_: inout GeoJSONSource, _ id: String) -> Void,
        layers: [any Layer],
        onBeforeAdd: @escaping @MainActor (_: MapView) -> Void = { _ in },
        onAfterAdd: @escaping @MainActor (_: MapView) -> Void = { _ in },
        onUpdate: @escaping @MainActor (_: MapView) throws -> Void = { _ in },
        onAfterUpdate: @escaping @MainActor (_: MapView) throws -> Void = { _ in },
        onAfterRemove: @escaping @MainActor (_: MapView) -> Void = { _ in }
    ) {
        self.id = id
        self.sources = Dictionary(uniqueKeysWithValues: sources.map { ($0.id, $0) })
        self.customizeSource = customizeSource
        self.layers = Dictionary(uniqueKeysWithValues: layers.map { ($0.id, $0) })
        self.onBeforeAdd = onBeforeAdd
        self.onAfterAdd = onAfterAdd
        self.onUpdate = onUpdate
        self.onAfterUpdate = onAfterUpdate
        self.onAfterRemove = onAfterRemove
    }

    // MARK: - MapFeature conformance

    @MainActor
    func add(to mapView: MapView, order: inout MapLayersOrder) {
        onBeforeAdd(mapView)

        let map: MapboxMap = mapView.mapboxMap
        for (_, source) in sources {
            addSource(source, to: map)
        }

        for (_, var layer) in layers {
            addLayer(&layer, to: map, order: &order)
        }

        onAfterAdd(mapView)
    }

    @MainActor
    private func addLayer(_ layer: inout any Layer, to map: MapboxMap, order: inout MapLayersOrder) {
        do {
            if map.layerExists(withId: layer.id) {
                try map.removeLayer(withId: layer.id)
            }
            order.insert(id: layer.id)
            if let slot = order.slot(forId: layer.id), map.allSlotIdentifiers.contains(slot) {
                layer.slot = slot
            }
            try map.addLayer(layer, layerPosition: order.position(forId: layer.id))
        } catch {
            Log.error("Failed to add layer '\(layer.id)': \(error)", category: .navigationUI)
        }
    }

    @MainActor
    private func addSource(_ source: Source, to map: MapboxMap) {
        do {
            if map.sourceExists(withId: source.id) {
                map.updateGeoJSONSource(
                    withId: source.id,
                    geoJSON: source.geoJson
                )
            } else {
                var geoJsonSource = GeoJSONSource(id: source.id)
                geoJsonSource.data = source.geoJson.sourceData
                customizeSource(&geoJsonSource, source.id)
                try map.addSource(geoJsonSource)
            }
        } catch {
            Log.error("Failed to add source '\(source.id)': \(error)", category: .navigationUI)
        }
    }

    @MainActor
    func update(oldValue: any MapFeature, in mapView: MapView, order: inout MapLayersOrder) {
        guard let oldValue = oldValue as? Self else {
            preconditionFailure("Incorrect type passed for oldValue")
        }

        for (_, source) in sources {
            guard mapView.mapboxMap.sourceExists(withId: source.id)
            else {
                // In case the map style was changed and the source is missing we're re-adding it back.
                oldValue.remove(from: mapView, order: &order)
                remove(from: mapView, order: &order)
                add(to: mapView, order: &order)
                return
            }
        }

        do {
            try onUpdate(mapView)
            let map: MapboxMap = mapView.mapboxMap

            let diff = diff(oldValue: oldValue, newValue: self)
            for var addedLayer in diff.addedLayers {
                addLayer(&addedLayer, to: map, order: &order)
            }
            for removedLayer in diff.removedLayers {
                removeLayer(removedLayer, from: map, order: &order)
            }
            for addedSource in diff.addedSources {
                addSource(addedSource, to: map)
            }
            for removedSource in diff.removedSources {
                removeSource(removedSource.id, from: map)
            }

            for (_, source) in sources {
                mapView.mapboxMap.updateGeoJSONSource(
                    withId: source.id,
                    geoJSON: source.geoJson
                )
            }
            try onAfterUpdate(mapView)
        } catch {
            Log.error("Failed to update map feature '\(id)': \(error)", category: .navigationUI)
        }
    }

    @MainActor
    func remove(from mapView: MapView, order: inout MapLayersOrder) {
        let map: MapboxMap = mapView.mapboxMap

        for (_, layer) in layers {
            removeLayer(layer, from: map, order: &order)
        }

        for sourceId in sources.keys {
            removeSource(sourceId, from: map)
        }

        onAfterRemove(mapView)
    }

    @MainActor
    private func removeLayer(_ layer: any Layer, from map: MapboxMap, order: inout MapLayersOrder) {
        guard map.layerExists(withId: layer.id) else { return }
        do {
            try map.removeLayer(withId: layer.id)
            order.remove(id: layer.id)
        } catch {
            Log.error("Failed to remove layer '\(layer.id)': \(error)", category: .navigationUI)
        }
    }

    @MainActor
    private func removeSource(_ sourceId: SourceId, from map: MapboxMap) {
        if map.sourceExists(withId: sourceId) {
            do {
                try map.removeSource(withId: sourceId)
            } catch {
                Log.error("Failed to remove source '\(sourceId)': \(error)", category: .navigationUI)
            }
        }
    }

    // MARK: Diff

    private struct Diff {
        let addedLayers: [any Layer]
        let removedLayers: [any Layer]
        let addedSources: [Source]
        let removedSources: [Source]
    }

    private func diff(oldValue: Self, newValue: Self) -> Diff {
        .init(
            addedLayers: newValue.layers.filter { oldValue.layers[$0.key] == nil }.map(\.value),
            removedLayers: oldValue.layers.filter { newValue.layers[$0.key] == nil }.map(\.value),
            addedSources: newValue.sources.filter { oldValue.sources[$0.key] == nil }.map(\.value),
            removedSources: oldValue.sources.filter { newValue.sources[$0.key] == nil }.map(\.value)
        )
    }
}

// MARK: Helpers

extension GeoJSONObject {
    /// Ported from MapboxMaps as the same var is internal in the SDK.
    var sourceData: GeoJSONSourceData? {
        switch self {
        case .geometry(let geometry):
            return .geometry(geometry)
        case .feature(let feature):
            return .feature(feature)
        case .featureCollection(let collection):
            return .featureCollection(collection)
        @unknown default:
            return nil
        }
    }
}

extension GeoJsonMapFeature.Source {
    static let defaultTolerance: Double = 0.375

    func data(
        lineMetrics: Bool = false,
        tolerance: Double? = nil
    ) -> GeoJSONSource? {
        guard let jsonSourceData = geoJson.sourceData else { return nil }

        var data = GeoJSONSource(id: id).data(jsonSourceData)
        data.lineMetrics = lineMetrics
        if let tolerance {
            data.tolerance = tolerance
        }
        return data
    }
}
