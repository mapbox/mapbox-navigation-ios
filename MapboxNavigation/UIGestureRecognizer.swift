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
}
