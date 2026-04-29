import SwiftUI
import UIKit

struct MapView: UIViewControllerRepresentable {
    let navigation: Navigation

    func makeUIViewController(context: Context) -> UIViewController {
        MapViewController(navigation: navigation)
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
