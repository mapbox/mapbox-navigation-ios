import Foundation
import FBSnapshotTestCase

@nonobjc extension FBSnapshotTestCase {
    func verify(_ view: UIView) {
        FBSnapshotVerifyView(view, suffixes: ["_64"], tolerance: 0.05)
    }
    func verify(_ layer: CALayer) {
        FBSnapshotVerifyLayer(layer, suffixes: ["_64"], tolerance: 0.05)
    }
}
