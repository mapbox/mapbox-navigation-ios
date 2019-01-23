import Foundation
import FBSnapshotTestCase

@nonobjc extension FBSnapshotTestCase {
    func verify(_ view: UIView, overallTolerance: CGFloat = 0.05) {
        FBSnapshotVerifyView(view, suffixes: ["_64"], overallTolerance: overallTolerance)
    }
    
    func verify(_ layer: CALayer, overallTolerance: CGFloat = 0.05) {
        FBSnapshotVerifyLayer(layer, suffixes: ["_64"], overallTolerance: overallTolerance)
    }
}
