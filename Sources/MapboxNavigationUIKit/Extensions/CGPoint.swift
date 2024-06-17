import UIKit

extension CGPoint {
    /// Calculates the straight line distance between two `CGPoint`.
    public func distance(to: CGPoint) -> CGFloat {
        return sqrt((x - to.x) * (x - to.x) + (y - to.y) * (y - to.y))
    }
}
