import XCTest
import SnapshotTesting
import MapboxDirections
@testable import TestHelper
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

@available(iOS 12.0, *)
let lightUserInterfaceStylePhoneTraitCollection = UITraitCollection(traitsFrom: [
    UITraitCollection(userInterfaceIdiom: .phone),
    UITraitCollection(userInterfaceStyle: .light)
])

@available(iOS 12.0, *)
let lightUserInterfaceStyleCarPlayTraitCollection = UITraitCollection(traitsFrom: [
    UITraitCollection(userInterfaceIdiom: .carPlay),
    UITraitCollection(userInterfaceStyle: .light)
])

@available(iOS 12.0, *)
let darkUserInterfaceStyleCarPlayTraitCollection = UITraitCollection(traitsFrom: [
    UITraitCollection(userInterfaceIdiom: .carPlay),
    UITraitCollection(userInterfaceStyle: .dark)
])

class LaneViewSnapshotTests: TestCase {
    
    let styles = [DayStyle(), NightStyle()]

    @available(iOS 12.0, *)
    func laneViews(for traitCollection: UITraitCollection) -> [LaneViewMock] {
        let indications: LaneIndication = [
            .left,
            .straightAhead
        ]

        let direction: ManeuverDirection = .left

        let laneViews = [
            LaneViewMock(for: traitCollection,
                         indications: indications,
                         isUsable: true,
                         direction: direction,
                         showHighlightedColors: true),
            LaneViewMock(for: traitCollection,
                         indications: indications,
                         isUsable: true,
                         direction: direction,
                         showHighlightedColors: false),
            LaneViewMock(for: traitCollection,
                         indications: indications,
                         isUsable: false,
                         direction: direction,
                         showHighlightedColors: true),
            LaneViewMock(for: traitCollection,
                         indications: indications,
                         isUsable: false,
                         direction: direction,
                         showHighlightedColors: false)
        ]

        return laneViews
    }
    
    override func setUp() {
        super.setUp()
        isRecording = false
        DayStyle().apply()
    }
    
    func testAllLanes30x30() {
        verifyAllLanes(size: CGSize(size: 30))
    }
    
    func testAllLanes90x90() {
        verifyAllLanes(size: CGSize(size: 90))
    }
    
    func verifyAllLanes(size: CGSize) {
        let leftHandLanes = TestableLane.testableLanes(drivingSide: .left)
        let rightHandLanes = TestableLane.testableLanes(drivingSide: .right)
        
        func addLanes(lanes: [TestableLane], stackView: UIStackView) {
            let containerView = UIStackView(orientation: .vertical, spacing: 5, autoLayout: true)
            
            for lane in lanes {
                let groupView = UIStackView(orientation: .vertical, autoLayout: true)
                groupView.alignment = .center
                
                let laneView = LaneView(indications: lane.indications, isUsable: true, direction: lane.maneuverDirection)
                laneView.drivingSide = lane.drivingSide
                
                laneView.backgroundColor = .white
                laneView.bounds = CGRect(origin: .zero, size: size)
                
                let label = UILabel(frame: .zero)
                label.textColor = .white
                label.text = "\(lane.description) (\(lane.drivingSide == .left ? "L" : "R"))"
                
                groupView.addArrangedSubview(label)
                groupView.addArrangedSubview(laneView)
                
                containerView.addArrangedSubview(groupView)
            }
            
            stackView.addArrangedSubview(containerView)
        }
        
        let view = UIStackView(orientation: .vertical, spacing: 5, autoLayout: true)
        view.setBackgroundColor(.black)
        
        addLanes(lanes: rightHandLanes, stackView: view)
        addLanes(lanes: leftHandLanes, stackView: view)
        
        assertImageSnapshot(matching: view, as: .image(precision: 0.95))
    }
    
    @available(iOS 12.0, *)
    func testLaneViewLightUserInterfaceStylePhone() {
        for style in styles {
            let stackView = UIStackView(orientation: .vertical, spacing: 5, autoLayout: true)
            stackView.backgroundColor = .white
            style.traitCollection = UITraitCollection(userInterfaceIdiom: .phone)
            style.apply()
            
            let horizontalStackView = UIStackView(orientation: .horizontal,
                                                  spacing: 2,
                                                  autoLayout: true)
            
            for laneView in laneViews(for: lightUserInterfaceStylePhoneTraitCollection) {
                horizontalStackView.addArrangedSubview(laneView)
            }
            
            stackView.addArrangedSubview(horizontalStackView)
            
            assertImageSnapshot(matching: stackView, as: .image(precision: 0.95))
        }
    }
    
    @available(iOS 12.0, *)
    func testLaneViewLightUserInterfaceStyleCarPlay() {
        for style in styles {
            let stackView = UIStackView(orientation: .vertical, spacing: 5, autoLayout: true)
            stackView.backgroundColor = .white
            style.traitCollection = UITraitCollection(userInterfaceIdiom: .carPlay)
            style.apply()
            
            let horizontalStackView = UIStackView(orientation: .horizontal,
                                                  spacing: 2,
                                                  autoLayout: true)
            
            for laneView in laneViews(for: lightUserInterfaceStyleCarPlayTraitCollection) {
                horizontalStackView.addArrangedSubview(laneView)
            }
            
            stackView.addArrangedSubview(horizontalStackView)
            
            assertImageSnapshot(matching: stackView, as: .image(precision: 0.95))
        }
    }
    
    @available(iOS 12.0, *)
    func testLaneViewDarkUserInterfaceStyleCarPlay() {
        for style in styles {
            let stackView = UIStackView(orientation: .vertical, spacing: 5, autoLayout: true)
            stackView.backgroundColor = .black
            style.traitCollection = UITraitCollection(userInterfaceIdiom: .carPlay)
            style.apply()
            
            let horizontalStackView = UIStackView(orientation: .horizontal,
                                                  spacing: 2,
                                                  autoLayout: true)
            
            for laneView in laneViews(for: darkUserInterfaceStyleCarPlayTraitCollection) {
                horizontalStackView.addArrangedSubview(laneView)
            }
            
            stackView.addArrangedSubview(horizontalStackView)
            
            assertImageSnapshot(matching: stackView, as: .image(precision: 0.95))
        }
    }
}

struct TestableLane {
    var description: String
    var indications: LaneIndication
    var drivingSide: DrivingSide
    var maneuverDirection: ManeuverDirection
    
    static func testableLanes(drivingSide: DrivingSide) -> [TestableLane] {
        let namedIndications: [(String, LaneIndication, ManeuverDirection)]
        
        namedIndications = [
            ("Sharp Left, Straight Ahead",      [.sharpLeft, .straightAhead], .sharpLeft),
            ("Straight Ahead, Sharp Left",      [.straightAhead, .sharpLeft], .sharpLeft),
            ("Left",                            [.left], .left),
            ("Slight Left",                     [.slightLeft], .slightLeft),
            ("Sharp Left",                      [.sharpLeft], .sharpLeft),
            ("Straight Ahead",                  [.straightAhead], .straightAhead),
            ("u-Turn",                          [.uTurn], .uTurn),
            ("Sharp Right",                     [.sharpRight], .sharpRight),
            ("Slight Right",                    [.slightRight], .slightRight),
            ("Right",                           [.right], .right),
            ("Sharp Right, Straight Ahead",     [.sharpRight, .straightAhead], .sharpRight),
            ("Straight Ahead, Sharp Right",     [.straightAhead, .sharpRight], .sharpRight),
        ]
        
        return namedIndications.map { TestableLane(description: $0.0, indications: $0.1, drivingSide: drivingSide, maneuverDirection: $0.2) }
    }
}

extension UIStackView {
    func setBackgroundColor(_ color: UIColor) {
        let subview = UIView(frame: bounds)
        subview.backgroundColor = color
        subview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(subview, at: 0)
    }
}

@available(iOS 12.0, *)
class LaneViewMock: LaneView {
    
    var customTraitCollection: UITraitCollection!
    
    override init(frame: CGRect) {
        customTraitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceIdiom: .phone),
            UITraitCollection(userInterfaceStyle: .light)
        ])
        
        super.init(frame: frame)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(for traitCollection: UITraitCollection,
                     indications: LaneIndication,
                     isUsable: Bool,
                     direction: ManeuverDirection?,
                     showHighlightedColors: Bool = false) {
        self.init(frame: LaneView.defaultFrame)
        customTraitCollection = traitCollection
        backgroundColor = .clear
        self.indications = indications
        maneuverDirection = direction ?? ManeuverDirection(rawValue: indications.description)
        self.isUsable = isUsable
        self.showHighlightedColors = showHighlightedColors
    }
    
    override var traitCollection: UITraitCollection {
        customTraitCollection
    }
}
