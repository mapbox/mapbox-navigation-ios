import UIKit

extension CGPoint {
    /**
     Calculates the straight line distance between two `CGPoint`.
     */
    public func distance(to: CGPoint) -> CGFloat {
        return sqrt((self.x - to.x) * (self.x - to.x) + (self.y - to.y) * (self.y - to.y))
    }
}
