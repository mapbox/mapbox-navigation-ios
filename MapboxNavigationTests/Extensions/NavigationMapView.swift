import UIKit
import MapboxNavigation

extension NavigationMapView {
    
    public func snapshot() -> UIImage? {
        let image = UIGraphicsImageRenderer(bounds: bounds).image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
        
        return image
    }
}
