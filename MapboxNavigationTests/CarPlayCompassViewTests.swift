import XCTest
import SnappyShrimp
import Mapbox
@testable import MapboxNavigation

class CarPlayCompassViewTests: SnapshotTest {
    
    var window: UIWindow!
    let styles = [DayStyle(), NightStyle()]
    
    override func setUp() {
        super.setUp()
        recordMode = false
        window = UIApplication.shared.windows[0]
    }
    
    func testEN() {
        snapshotTests(language: "Base")
    }
    
    func testHE() {
        snapshotTests(language: "he")
    }
    
    func snapshotTests(language: String) {
        let stackView = UIStackView(orientation: .vertical, spacing: 5, autoLayout: true)
        window.addSubview(stackView)
        
        let baseBundle = Bundle(for: MGLCompassDirectionFormatter.self)
        let bundle = Bundle(path: baseBundle.path(forResource: language, ofType: "lproj")!)!
        let directions = ["COMPASS_N_SHORT",
                          "COMPASS_NE_SHORT",
                          "COMPASS_E_SHORT",
                          "COMPASS_SE_SHORT",
                          "COMPASS_S_SHORT",
                          "COMPASS_SW_SHORT",
                          "COMPASS_W_SHORT",
                          "COMPASS_NW_SHORT",
        ]
        
        for style in styles {
            style.apply()
            
            let horizontalStackView = UIStackView(orientation: .horizontal, spacing: 2, autoLayout: true)
            
            for key in directions {
                let compassView = CarPlayCompassView(frame: .zero)
                compassView.isHidden = false
                compassView.label.text = NSLocalizedString(key, tableName: "Foundation", bundle: bundle, comment: "no comment")
                horizontalStackView.addArrangedSubview(compassView)
            }
            
            stackView.addArrangedSubview(horizontalStackView)
        }
        
        verify(stackView)
    }
}
