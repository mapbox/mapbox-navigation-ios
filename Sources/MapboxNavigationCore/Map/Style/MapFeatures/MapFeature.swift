import Foundation
import MapboxMaps

/// Something that can be added/removed/updated in MapboxMaps.MapView.
///
/// Use ``MapFeaturesStore`` to manage a set of features.
protocol MapFeature {
    var id: String { get }

    @MainActor
    func add(to mapView: MapView, order: inout MapLayersOrder)
    @MainActor
    func remove(from mapView: MapView, order: inout MapLayersOrder)
    @MainActor
    func update(oldValue: MapFeature, in mapView: MapView, order: inout MapLayersOrder)
}
