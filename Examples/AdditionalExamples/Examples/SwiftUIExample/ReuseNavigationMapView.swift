import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import SwiftUI
import UIKit

struct ReuseNavigationMapView: View {
    let mapboxNavigation: MapboxNavigationProvider = {
        let provider = MapboxNavigationProvider(
            coreConfig: .init(
                locationSource: simulationIsEnabled ? .simulation(
                    initialLocation: .init(
                        latitude: 37.77440680146262,
                        longitude: -122.43539772352648
                    )
                ) : .live
            )
        )
        // Free Drive is required to recieve updates and map matched location
        // Check Pricing docs https://docs.mapbox.com/ios/navigation/guides/pricing/#free-drive-trip
        provider.tripSession().startFreeDrive()
        return provider
    }()

    var body: some View {
        NavigationMapViewWrapper(mapboxNavigation: mapboxNavigation)
            .ignoresSafeArea()
    }
}
