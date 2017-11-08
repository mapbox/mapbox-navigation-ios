import Foundation
import UIKit

extension UIGestureRecognizer {
    var point: CGPoint? {
        guard let view = view else { return nil }
        return location(in: view)
    }
    
    func requireFailure(of gestures: [UIGestureRecognizer]?) {
        guard let gestures = gestures else { return }
        gestures.forEach(self.require(toFail:))
    }
    
    func coordinate(in map: MGLMapView) -> CLLocationCoordinate2D? {
        guard let point = self.point else { return nil }
        return map.convert(point, toCoordinateFrom: self.view)
    }
}
