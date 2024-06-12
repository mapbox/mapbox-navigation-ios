import Foundation
import MapboxMaps

/// A store for ``MapFeature``s.
///
/// It handle style reload by re-adding currently active features (make sure you call `styleLoaded` method).
/// Use `update(using:)` method to provide a new snapshot of features that are managed by this store. The store will
/// handle updates/removes/additions to the map view.
@MainActor
final class MapFeaturesStore {
    private struct Features: Sequence {
        private var features: [String: any MapFeature] = [:]

        func makeIterator() -> some IteratorProtocol<MapFeature> {
            features.values.makeIterator()
        }

        subscript(_ id: String) -> (any MapFeature)? {
            features[id]
        }

        mutating func insert(_ feature: any MapFeature) {
            features[feature.id] = feature
        }

        mutating func remove(_ feature: any MapFeature) -> (any MapFeature)? {
            features.removeValue(forKey: feature.id)
        }

        mutating func removeAll() -> some Sequence<any MapFeature> {
            let allFeatures = features.values
            features = [:]
            return allFeatures
        }
    }

    private let mapView: MapView
    private var styleLoadSubscription: MapboxMaps.Cancelable?
    private var features: Features = .init()

    private var currentStyleLoaded: Bool = false
    private var currentStyleUri: StyleURI?

    private var styleLoaded: Bool {
        if currentStyleUri != mapView.mapboxMap.styleURI {
            currentStyleLoaded = false
        }
        return currentStyleLoaded
    }

    init(mapView: MapView) {
        self.mapView = mapView
        self.currentStyleUri = mapView.mapboxMap.styleURI
        self.currentStyleLoaded = mapView.mapboxMap.isStyleLoaded
    }

    func deactivate(order: inout MapLayersOrder) {
        styleLoadSubscription?.cancel()
        guard styleLoaded else { return }
        features.forEach { $0.remove(from: mapView, order: &order) }
    }

    func update(using allFeatures: [any MapFeature]?, order: inout MapLayersOrder) {
        guard let allFeatures, !allFeatures.isEmpty else {
            removeAll(order: &order); return
        }

        let newFeatureIds = Set(allFeatures.map(\.id))
        for existingFeature in features where !newFeatureIds.contains(existingFeature.id) {
            remove(existingFeature, order: &order)
        }

        for feature in allFeatures {
            update(feature, order: &order)
        }
    }

    private func removeAll(order: inout MapLayersOrder) {
        let allFeatures = features.removeAll()
        guard styleLoaded else { return }

        for feature in allFeatures {
            feature.remove(from: mapView, order: &order)
        }
    }

    private func update(_ feature: any MapFeature, order: inout MapLayersOrder) {
        defer {
            features.insert(feature)
        }

        guard styleLoaded else { return }

        if let oldFeature = features[feature.id] {
            feature.update(oldValue: oldFeature, in: mapView, order: &order)
        } else {
            feature.add(to: mapView, order: &order)
        }
    }

    private func remove(_ feature: some MapFeature, order: inout MapLayersOrder) {
        guard let removeFeature = features.remove(feature) else { return }

        if styleLoaded {
            removeFeature.remove(from: mapView, order: &order)
        }
    }

    func styleLoaded(order: inout MapLayersOrder) {
        currentStyleUri = mapView.mapboxMap.styleURI
        currentStyleLoaded = true

        for feature in features {
            feature.add(to: mapView, order: &order)
        }
    }
}
