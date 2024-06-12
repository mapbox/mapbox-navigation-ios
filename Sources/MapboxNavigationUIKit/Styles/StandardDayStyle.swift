import Combine
import MapboxMaps
import MapboxNavigationCore
import UIKit

/// The standard navigation style is the default style for Mapbox Navigation SDK.
open class StandardDayStyle: DayStyle {
    private var lifetimeSubscription: AnyCancellable?

    public required init() {
        super.init()

        mapStyleURL = StyleURI.navigationMapStyleUrl
        previewMapStyleURL = mapStyleURL
        styleType = .day

        statusBarStyle = .darkContent
    }

    @MainActor
    override open func applyMapStyle(to navigationMapView: NavigationMapView) {
        super.applyMapStyle(to: navigationMapView)

        guard let mapboxMap = navigationMapView.mapView.mapboxMap else { return }

        // The light preset will be ignored if the style is not loaded
        applyLightPreset(to: mapboxMap)
        lifetimeSubscription = navigationMapView.mapView.mapboxMap.onStyleLoaded
            .first()
            .sink { [weak self] _ in
                self?.applyLightPreset(to: mapboxMap)
            }
    }

    private func applyLightPreset(to mapboxMap: MapboxMap) {
        do {
            try mapboxMap.setStyleImportConfigProperty(
                for: "basemap",
                config: "lightPreset",
                value: "day"
            )
            lifetimeSubscription = nil
        } catch {
            Log.error(
                "Failed to apply day lightPreset with error: \(error.localizedDescription).",
                category: .navigationUI
            )
        }
    }
}
