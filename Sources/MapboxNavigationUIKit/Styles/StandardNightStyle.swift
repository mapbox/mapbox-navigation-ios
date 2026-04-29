import Combine
import MapboxMaps
import MapboxNavigationCore
import UIKit

/// ``StandardNightStyle`` is the default night style for Mapbox Navigation SDK. Only will be applied when necessary and
/// if ``StyleManager/automaticallyAdjustsStyleForTimeOfDay`` is `true` .
open class StandardNightStyle: NightStyle {
    private var lifetimeSubscription: AnyCancellable?

    public required init() {
        super.init()

        mapStyleURL = StyleURI.navigationMapStyleUrl
        previewMapStyleURL = mapStyleURL
        styleType = .night
        statusBarStyle = .lightContent
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
                value: "night"
            )
            lifetimeSubscription = nil
        } catch {
            Log.error(
                "Failed to apply night lightPreset with error: \(error.localizedDescription).",
                category: .navigationUI
            )
        }
    }
}
