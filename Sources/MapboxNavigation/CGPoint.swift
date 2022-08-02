import UIKit

extension CGPoint {
    /**
     Calculates the straight line distance between two `CGPoint`.
     */
    public func distance(to: CGPoint) -> CGFloat {
        return sqrt((self.x - to.x) * (self.x - to.x) + (self.y - to.y) * (self.y - to.y))
    }
    
    // `MapView.mapboxMap.point(for:)` will return the point if the coordinate is outside of the `MapView` bounds.
    static let pointOutOfMapViewBounds = CGPoint(x: -1.0, y: -1.0)
}
