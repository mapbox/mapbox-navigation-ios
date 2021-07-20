import XCTest
import UIKit
import TestHelper
@testable import MapboxNavigation

class UIViewAnimationOptionsTests: TestCase {
    func testAnimationCurveConversion() {
        let animationCurve = unsafeBitCast(7, to: UIView.AnimationCurve.self)
        let animationOptions = UIView.AnimationOptions(curve: animationCurve)
        XCTAssert(animationOptions == nil || animationOptions?.rawValue == 1 << 16, "Private curve value should fail the initializer gracefully if it fails at all.")
    }
}
