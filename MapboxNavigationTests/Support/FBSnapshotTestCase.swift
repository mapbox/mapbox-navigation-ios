import Foundation
import FBSnapshotTestCase

@nonobjc extension FBSnapshotTestCase {
    func verify(_ view: UIView, file: StaticString = #file, line: UInt = #line) {
        FBSnapshotVerifyView(view, suffixes: ["_64"], tolerance: 0.05, file: file, line: line)
    }
    
    func verify(_ layer: CALayer, file: StaticString = #file, line: UInt = #line) {
        FBSnapshotVerifyLayer(layer, suffixes: ["_64"], tolerance: 0.05, file: file, line: line)
    }
}
