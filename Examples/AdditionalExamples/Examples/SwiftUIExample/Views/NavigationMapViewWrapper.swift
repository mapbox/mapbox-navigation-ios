import MapboxNavigationCore
import SwiftUI
import UIKit

struct NavigationMapViewWrapper: UIViewControllerRepresentable {
    let mapViewController: NavigationMapViewController

    init(mapboxNavigation: MapboxNavigationProvider) {
        let controller = NavigationMapViewController(mapboxNavigation: mapboxNavigation)
        self.mapViewController = controller
    }

    func makeUIViewController(context: Context) -> NavigationMapViewController {
        return mapViewController
    }

    func updateUIViewController(_ uiViewController: NavigationMapViewController, context: Context) {}
}
