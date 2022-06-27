import XCTest
import MapboxMaps
import SnapshotTesting
import TestHelper
@testable import MapboxNavigation

class CarPlayCompassViewMock: CarPlayCompassView {
    
    override var traitCollection: UITraitCollection {
        return UITraitCollection(userInterfaceIdiom: .carPlay)
    }
}

class CarPlayCompassViewSnapshotTests: TestCase {
    
    private let styles = [DayStyle(), NightStyle()]
    
    override func setUp() {
        super.setUp()
        isRecording = false
    }
    
    func testCarPlayCompassView() {
        for style in styles {
            // `StyleManager` switches between user interface styles depending on platform, on
            // which it was created (to prevent global appearance updates of UI components that are
            // used on both phone and CarPlay).
            // In this case trait collection is changed directly.
            style.traitCollection = UITraitCollection(userInterfaceIdiom: .carPlay)
            
            let stackView = UIStackView(orientation: .vertical, spacing: 5, autoLayout: true)
            style.apply()
            
            let horizontalStackView = UIStackView(orientation: .horizontal, spacing: 2, autoLayout: true)
            
            for course in stride(from: 0, to: 360, by: 45) {
                let carPlayCompassViewMock = CarPlayCompassViewMock(frame: .zero)
                carPlayCompassViewMock.isHidden = false
                carPlayCompassViewMock.course = CLLocationDirection(course)
                horizontalStackView.addArrangedSubview(carPlayCompassViewMock)
            }
            
            stackView.addArrangedSubview(horizontalStackView)
            assertImageSnapshot(matching: stackView, as: .image(precision: 0.95))
        }
    }
}
