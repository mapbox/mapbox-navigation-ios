import Foundation
import UIKit

extension Array where Iterator.Element == NSLayoutConstraint {
    func activate() {
        NSLayoutConstraint.activate(self)
    }
    func deactivate() {
        NSLayoutConstraint.deactivate(self)
    }
    
    var active: [NSLayoutConstraint] {
        return self.filter({ $0.isActive })
    }
}
