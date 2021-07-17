import XCTest
import MapboxMaps
import SnapshotTesting
import TestHelper
@testable import MapboxNavigation

class CarPlayCompassViewSnapshotTests: TestCase {
    private let styles = [DayStyle(), NightStyle()]
    
    override func setUp() {
        super.setUp()
        isRecording = false
    }
    
    func testCarPlayCompassView() {
        for style in styles {
            let stackView = UIStackView(orientation: .vertical, spacing: 5, autoLayout: true)
            style.apply()
            
            let horizontalStackView = UIStackView(orientation: .horizontal, spacing: 2, autoLayout: true)
            
            for course in stride(from: 0, to: 360, by: 45) {
                let compassView = CarPlayCompassView(frame: .zero)
                compassView.isHidden = false
                compassView.course = CLLocationDirection(course)
                horizontalStackView.addArrangedSubview(compassView)
            }
            
            stackView.addArrangedSubview(horizontalStackView)
            assertImageSnapshot(matching: stackView, as: .image(precision: 0.95))
        }

    }
}
