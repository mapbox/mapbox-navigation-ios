import Foundation

extension CGPoint {
    func CGPointDistanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }
    
    /**
     Calculates the straight line distance between two `CGPoint`.
     */
    public func distance(to: CGPoint) -> CGFloat {
        return sqrt(CGPointDistanceSquared(from: self, to: to))
    }
}
