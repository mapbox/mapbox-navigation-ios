import XCTest
import MapboxDirections
@testable import MapboxNavigation

class LaneViewTests: XCTestCase {
    func testRankedIndications() {
        XCTAssertEqual(LaneIndication.straightAhead.ranked(favoring: nil),
                       .init(primary: .straightAhead, secondary: nil))
        XCTAssertEqual(LaneIndication.straightAhead.ranked(favoring: .straightAhead),
                       .init(primary: .straightAhead, secondary: nil))
        XCTAssertEqual(LaneIndication.straightAhead.ranked(favoring: .right),
                       .init(primary: .straightAhead, secondary: nil))
        XCTAssertEqual(LaneIndication.straightAhead.ranked(favoring: .uTurn),
                       .init(primary: .straightAhead, secondary: nil))
        
        XCTAssertEqual(LaneIndication.uTurn.ranked(favoring: nil),
                       .init(primary: .uTurn, secondary: nil))
        XCTAssertEqual(LaneIndication.uTurn.ranked(favoring: .uTurn),
                       .init(primary: .uTurn, secondary: nil))
        XCTAssertEqual(LaneIndication.uTurn.ranked(favoring: .straightAhead),
                       .init(primary: .uTurn, secondary: nil))
        
        XCTAssertEqual(LaneIndication.sharpLeft.ranked(favoring: nil),
                       .init(primary: .left, secondary: nil))
        XCTAssertEqual(LaneIndication.sharpLeft.ranked(favoring: .sharpLeft),
                       .init(primary: .left, secondary: nil))
        XCTAssertEqual(LaneIndication.sharpLeft.ranked(favoring: .left),
                       .init(primary: .left, secondary: nil))
        XCTAssertEqual(LaneIndication.sharpLeft.ranked(favoring: .right),
                       .init(primary: .left, secondary: nil))
        
        XCTAssertEqual(LaneIndication.sharpRight.ranked(favoring: nil),
                       .init(primary: .right, secondary: nil))
        XCTAssertEqual(LaneIndication.sharpRight.ranked(favoring: .sharpRight),
                       .init(primary: .right, secondary: nil))
        XCTAssertEqual(LaneIndication.sharpRight.ranked(favoring: .right),
                       .init(primary: .right, secondary: nil))
        XCTAssertEqual(LaneIndication.sharpRight.ranked(favoring: .left),
                       .init(primary: .right, secondary: nil))
        
        XCTAssertEqual(LaneIndication.left.ranked(favoring: nil),
                       .init(primary: .left, secondary: nil))
        XCTAssertEqual(LaneIndication.left.ranked(favoring: .left),
                       .init(primary: .left, secondary: nil))
        XCTAssertEqual(LaneIndication.left.ranked(favoring: .sharpLeft),
                       .init(primary: .left, secondary: nil))
        XCTAssertEqual(LaneIndication.left.ranked(favoring: .slightLeft),
                       .init(primary: .left, secondary: nil))
        XCTAssertEqual(LaneIndication.left.ranked(favoring: .straightAhead),
                       .init(primary: .left, secondary: nil))
        
        XCTAssertEqual(LaneIndication.right.ranked(favoring: nil),
                       .init(primary: .right, secondary: nil))
        XCTAssertEqual(LaneIndication.right.ranked(favoring: .right),
                       .init(primary: .right, secondary: nil))
        XCTAssertEqual(LaneIndication.right.ranked(favoring: .sharpRight),
                       .init(primary: .right, secondary: nil))
        XCTAssertEqual(LaneIndication.right.ranked(favoring: .slightRight),
                       .init(primary: .right, secondary: nil))
        XCTAssertEqual(LaneIndication.right.ranked(favoring: .straightAhead),
                       .init(primary: .right, secondary: nil))
        
        XCTAssertEqual(LaneIndication.slightLeft.ranked(favoring: nil),
                       .init(primary: .slightLeft, secondary: nil))
        XCTAssertEqual(LaneIndication.slightLeft.ranked(favoring: .slightLeft),
                       .init(primary: .slightLeft, secondary: nil))
        XCTAssertEqual(LaneIndication.slightLeft.ranked(favoring: .left),
                       .init(primary: .slightLeft, secondary: nil))
        XCTAssertEqual(LaneIndication.slightLeft.ranked(favoring: .sharpLeft),
                       .init(primary: .slightLeft, secondary: nil))
        XCTAssertEqual(LaneIndication.slightLeft.ranked(favoring: .uTurn),
                       .init(primary: .slightLeft, secondary: nil))
        
        XCTAssertEqual(LaneIndication.slightRight.ranked(favoring: nil),
                       .init(primary: .slightRight, secondary: nil))
        XCTAssertEqual(LaneIndication.slightRight.ranked(favoring: .slightRight),
                       .init(primary: .slightRight, secondary: nil))
        XCTAssertEqual(LaneIndication.slightRight.ranked(favoring: .right),
                       .init(primary: .slightRight, secondary: nil))
        XCTAssertEqual(LaneIndication.slightRight.ranked(favoring: .sharpRight),
                       .init(primary: .slightRight, secondary: nil))
        XCTAssertEqual(LaneIndication.slightRight.ranked(favoring: .uTurn),
                       .init(primary: .slightRight, secondary: nil))
        
        XCTAssertEqual(([.straightAhead, .left] as LaneIndication).ranked(favoring: nil),
                       .init(primary: .straightAhead, secondary: .left))
        XCTAssertEqual(([.straightAhead, .left] as LaneIndication).ranked(favoring: .right),
                       .init(primary: .straightAhead, secondary: .left))
        XCTAssertEqual(([.straightAhead, .left] as LaneIndication).ranked(favoring: .left),
                       .init(primary: .left, secondary: .straightAhead))
        XCTAssertEqual(([.straightAhead, .left] as LaneIndication).ranked(favoring: .sharpLeft),
                       .init(primary: .left, secondary: .straightAhead))
        XCTAssertEqual(([.straightAhead, .left] as LaneIndication).ranked(favoring: .slightLeft),
                       .init(primary: .left, secondary: .straightAhead))
        
        XCTAssertEqual(([.straightAhead, .slightLeft] as LaneIndication).ranked(favoring: nil),
                       .init(primary: .straightAhead, secondary: .left))
        XCTAssertEqual(([.straightAhead, .slightLeft] as LaneIndication).ranked(favoring: .right),
                       .init(primary: .straightAhead, secondary: .left))
        XCTAssertEqual(([.straightAhead, .slightLeft] as LaneIndication).ranked(favoring: .left),
                       .init(primary: .straightAhead, secondary: .left))
        XCTAssertEqual(([.straightAhead, .slightLeft] as LaneIndication).ranked(favoring: .sharpLeft),
                       .init(primary: .straightAhead, secondary: .left))
        XCTAssertEqual(([.straightAhead, .slightLeft] as LaneIndication).ranked(favoring: .slightLeft),
                       .init(primary: .left, secondary: .straightAhead))
        
        XCTAssertEqual(([.straightAhead, .right] as LaneIndication).ranked(favoring: nil),
                       .init(primary: .straightAhead, secondary: .right))
        XCTAssertEqual(([.straightAhead, .right] as LaneIndication).ranked(favoring: .left),
                       .init(primary: .straightAhead, secondary: .right))
        XCTAssertEqual(([.straightAhead, .right] as LaneIndication).ranked(favoring: .right),
                       .init(primary: .right, secondary: .straightAhead))
        XCTAssertEqual(([.straightAhead, .right] as LaneIndication).ranked(favoring: .sharpRight),
                       .init(primary: .right, secondary: .straightAhead))
        XCTAssertEqual(([.straightAhead, .right] as LaneIndication).ranked(favoring: .slightRight),
                       .init(primary: .right, secondary: .straightAhead))
        
        XCTAssertEqual(([.straightAhead, .slightRight] as LaneIndication).ranked(favoring: nil),
                       .init(primary: .straightAhead, secondary: .right))
        XCTAssertEqual(([.straightAhead, .slightRight] as LaneIndication).ranked(favoring: .left),
                       .init(primary: .straightAhead, secondary: .right))
        XCTAssertEqual(([.straightAhead, .slightRight] as LaneIndication).ranked(favoring: .right),
                       .init(primary: .straightAhead, secondary: .right))
        XCTAssertEqual(([.straightAhead, .slightRight] as LaneIndication).ranked(favoring: .sharpRight),
                       .init(primary: .straightAhead, secondary: .right))
        XCTAssertEqual(([.straightAhead, .slightRight] as LaneIndication).ranked(favoring: .slightRight),
                       .init(primary: .right, secondary: .straightAhead))
        
        XCTAssertEqual(([.left, .uTurn] as LaneIndication).ranked(favoring: nil),
                       .init(primary: .left, secondary: nil))
        XCTAssertEqual(([.left, .uTurn] as LaneIndication).ranked(favoring: .left),
                       .init(primary: .left, secondary: nil))
        XCTAssertEqual(([.left, .uTurn] as LaneIndication).ranked(favoring: .uTurn),
                       .init(primary: .uTurn, secondary: nil))
        
        XCTAssertEqual(([.straightAhead, .uTurn] as LaneIndication).ranked(favoring: nil),
                       .init(primary: .straightAhead, secondary: nil))
        XCTAssertEqual(([.straightAhead, .uTurn] as LaneIndication).ranked(favoring: .straightAhead),
                       .init(primary: .straightAhead, secondary: nil))
        XCTAssertEqual(([.straightAhead, .uTurn] as LaneIndication).ranked(favoring: .uTurn),
                       .init(primary: .uTurn, secondary: nil))
        
        XCTAssertEqual(([.left, .right] as LaneIndication).ranked(favoring: nil),
                       .init(primary: .left, secondary: nil))
        XCTAssertEqual(([.left, .right] as LaneIndication).ranked(favoring: .left),
                       .init(primary: .left, secondary: nil))
        XCTAssertEqual(([.left, .right] as LaneIndication).ranked(favoring: .right),
                       .init(primary: .right, secondary: nil))
        XCTAssertEqual(([.left, .right] as LaneIndication).ranked(favoring: .slightRight),
                       .init(primary: .right, secondary: nil))
        
        XCTAssertEqual(([.left, .slightRight] as LaneIndication).ranked(favoring: nil),
                       .init(primary: .slightRight, secondary: nil))
        XCTAssertEqual(([.left, .slightRight] as LaneIndication).ranked(favoring: .left),
                       .init(primary: .left, secondary: nil))
        XCTAssertEqual(([.left, .slightRight] as LaneIndication).ranked(favoring: .slightRight),
                       .init(primary: .slightRight, secondary: nil))
        XCTAssertEqual(([.left, .slightRight] as LaneIndication).ranked(favoring: .right),
                       .init(primary: .slightRight, secondary: nil))
    }
    
    func testLaneConfiguration() {
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .uTurn, secondary: nil), drivingSide: .right),
                       .uTurnOnly(side: .left))
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .uTurn, secondary: nil), drivingSide: .left),
                       .uTurnOnly(side: .right))
        XCTAssertNil(LaneConfiguration(rankedIndications: .init(primary: .uTurn, secondary: .left), drivingSide: .right))
        
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .straightAhead, secondary: nil), drivingSide: .right),
                       .straightOnly)
        XCTAssertNil(LaneConfiguration(rankedIndications: .init(primary: .straightAhead, secondary: .slightLeft), drivingSide: .right))
        
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .slightLeft, secondary: nil), drivingSide: .right),
                       .slightTurnOnly(side: .left))
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .slightRight, secondary: nil), drivingSide: .right),
                       .slightTurnOnly(side: .right))
        XCTAssertNil(LaneConfiguration(rankedIndications: .init(primary: .slightLeft, secondary: .straightAhead), drivingSide: .right))
        
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .left, secondary: nil), drivingSide: .right),
                       .turnOnly(side: .left))
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .right, secondary: nil), drivingSide: .right),
                       .turnOnly(side: .right))
        XCTAssertNil(LaneConfiguration(rankedIndications: .init(primary: .left, secondary: .right), drivingSide: .right))
        
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .left, secondary: .straightAhead), drivingSide: .right),
                       .straightOrTurn(side: .left, straight: false, turn: true))
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .right, secondary: .straightAhead), drivingSide: .right),
                       .straightOrTurn(side: .right, straight: false, turn: true))
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .straightAhead, secondary: .left), drivingSide: .right),
                       .straightOrTurn(side: .left, straight: true, turn: false))
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .straightAhead, secondary: .right), drivingSide: .right),
                       .straightOrTurn(side: .right, straight: true, turn: false))
    }
}
