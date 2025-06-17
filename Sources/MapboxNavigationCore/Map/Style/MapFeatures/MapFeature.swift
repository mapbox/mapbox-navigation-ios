import Combine
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

protocol RedrawableMapFeature: MapFeature, Identifiable {
    /// Subscribers to this publisher can use the emitted identifier to determine which
    /// specific instance requested a redraw.
    @MainActor
    var redrawRequestPublisher: AnyPublisher<AnyHashable, Never> { get }

    /// Implementation should provide a recreated map feature using original data used for initialization.
    /// The resulting map feature can differ though because of other factors (like different settings in dependencies).
    @MainActor
    func refreshed() -> Self
}
