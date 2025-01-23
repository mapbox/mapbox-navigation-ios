import Foundation
import MapboxNavigationCore
import UIKit

extension NavigationMapView {
    func addImageIfNotExists(withId imageId: String, image: UIImage) {
        guard !mapView.mapboxMap.imageExists(withId: imageId) else {
            return
        }

        try! mapView.mapboxMap.addImage(
            image,
            id: imageId,
            stretchX: [],
            stretchY: []
        )
    }
}
