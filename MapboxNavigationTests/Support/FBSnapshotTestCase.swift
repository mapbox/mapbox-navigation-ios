import Foundation
import FBSnapshotTestCase

fileprivate let suffix: NSOrderedSet = ["_64"]

@nonobjc extension FBSnapshotTestCase {
    
    func verify(_ view: UIView, overallTolerance: CGFloat = 0.05) {
        FBSnapshotVerifyView(view, suffixes: suffix, overallTolerance: overallTolerance)
    }
    
    func verify(_ layer: CALayer, overallTolerance: CGFloat = 0.05) {
        FBSnapshotVerifyLayer(layer, suffixes: suffix, overallTolerance: overallTolerance)
    }
}
