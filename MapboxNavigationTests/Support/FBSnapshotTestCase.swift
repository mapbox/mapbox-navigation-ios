import Foundation
import FBSnapshotTestCase

extension FBSnapshotTestCase {
    func verify(_ view: UIView) {
        FBSnapshotVerifyView(view, suffixes: ["_64"])
    }
}
