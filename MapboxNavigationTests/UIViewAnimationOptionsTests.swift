import XCTest
import UIKit
@testable import MapboxNavigation

class UIViewAnimationOptionsTests: XCTestCase {
    func testAnimationCurveConversion() {
        let animationCurve = unsafeBitCast(7, to: UIViewAnimationCurve.self)
        let animationOptions = UIViewAnimationOptions(curve: animationCurve)
        XCTAssert(animationOptions == nil || animationOptions?.rawValue == 1 << 16, "Private curve value should fail the initializer gracefully if it fails at all.")
    }
}
