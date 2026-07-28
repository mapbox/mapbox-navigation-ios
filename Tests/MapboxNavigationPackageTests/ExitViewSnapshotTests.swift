@testable import MapboxNavigationUIKit
import SnapshotTesting
import TestHelper
import XCTest

class ExitViewSnapshotTests: TestCase {
    private static let precision: Float = 0.99

    override func setUp() {
        super.setUp()
        DayStyle().apply()
    }

    func testRightSide() {
        assertImageSnapshot(matching: snapshot(side: .right, text: "123A"), as: .image(precision: Self.precision))
    }

    func testLeftSide() {
        assertImageSnapshot(matching: snapshot(side: .left, text: "123A"), as: .image(precision: Self.precision))
    }

    func testShortText() {
        assertImageSnapshot(matching: snapshot(side: .right, text: "5"), as: .image(precision: Self.precision))
    }

    func testLongText() {
        assertImageSnapshot(matching: snapshot(side: .right, text: "123ABC"), as: .image(precision: Self.precision))
    }

    func testCustomForegroundColor() {
        assertImageSnapshot(
            matching: snapshot(side: .right, text: "42", foregroundColor: .blue),
            as: .image(precision: Self.precision)
        )
    }

    // MARK: - Helpers

    private func snapshot(
        side: ExitSide,
        text: String,
        pointSize: CGFloat = 20,
        foregroundColor: UIColor = .black
    ) -> ExitView {
        let view = ExitView(pointSize: pointSize, side: side, text: text)
        view.backgroundColor = .white
        view.borderColor = .black
        view.foregroundColor = foregroundColor
        view.borderWidth = 1.0
        view.cornerRadius = 5.0

        let size = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        view.frame = CGRect(origin: .zero, size: size)
        view.layoutIfNeeded()

        return view
    }
}
