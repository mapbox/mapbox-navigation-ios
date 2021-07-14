import XCTest
import MapboxDirections
import TestHelper
@testable import MapboxNavigation

class LaneViewTests: TestCase {
    func testRankedIndications() {
        XCTAssertEqual(LaneIndication.straightAhead.ranked(favoring: nil),
                       .init(primary: .straightAhead, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.straightAhead.ranked(favoring: .straightAhead),
                       .init(primary: .straightAhead, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.straightAhead.ranked(favoring: .right),
                       .init(primary: .straightAhead, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.straightAhead.ranked(favoring: .uTurn),
                       .init(primary: .straightAhead, secondary: nil, tertiary: nil))
        
        XCTAssertEqual(LaneIndication.uTurn.ranked(favoring: nil),
                       .init(primary: .uTurn, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.uTurn.ranked(favoring: .uTurn),
                       .init(primary: .uTurn, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.uTurn.ranked(favoring: .straightAhead),
                       .init(primary: .uTurn, secondary: nil, tertiary: nil))
        
        XCTAssertEqual(LaneIndication.sharpLeft.ranked(favoring: nil),
                       .init(primary: .sharpLeft, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.sharpLeft.ranked(favoring: .sharpLeft),
                       .init(primary: .sharpLeft, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.sharpLeft.ranked(favoring: .left),
                       .init(primary: .sharpLeft, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.sharpLeft.ranked(favoring: .right),
                       .init(primary: .sharpLeft, secondary: nil, tertiary: nil))
        
        XCTAssertEqual(LaneIndication.sharpRight.ranked(favoring: nil),
                       .init(primary: .sharpRight, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.sharpRight.ranked(favoring: .sharpRight),
                       .init(primary: .sharpRight, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.sharpRight.ranked(favoring: .right),
                       .init(primary: .sharpRight, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.sharpRight.ranked(favoring: .left),
                       .init(primary: .sharpRight, secondary: nil, tertiary: nil))
        
        XCTAssertEqual(LaneIndication.left.ranked(favoring: nil),
                       .init(primary: .left, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.left.ranked(favoring: .left),
                       .init(primary: .left, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.left.ranked(favoring: .sharpLeft),
                       .init(primary: .left, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.left.ranked(favoring: .slightLeft),
                       .init(primary: .left, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.left.ranked(favoring: .straightAhead),
                       .init(primary: .left, secondary: nil, tertiary: nil))
        
        XCTAssertEqual(LaneIndication.right.ranked(favoring: nil),
                       .init(primary: .right, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.right.ranked(favoring: .right),
                       .init(primary: .right, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.right.ranked(favoring: .sharpRight),
                       .init(primary: .right, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.right.ranked(favoring: .slightRight),
                       .init(primary: .right, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.right.ranked(favoring: .straightAhead),
                       .init(primary: .right, secondary: nil, tertiary: nil))
        
        XCTAssertEqual(LaneIndication.slightLeft.ranked(favoring: nil),
                       .init(primary: .slightLeft, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.slightLeft.ranked(favoring: .slightLeft),
                       .init(primary: .slightLeft, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.slightLeft.ranked(favoring: .left),
                       .init(primary: .slightLeft, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.slightLeft.ranked(favoring: .sharpLeft),
                       .init(primary: .slightLeft, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.slightLeft.ranked(favoring: .uTurn),
                       .init(primary: .slightLeft, secondary: nil, tertiary: nil))
        
        XCTAssertEqual(LaneIndication.slightRight.ranked(favoring: nil),
                       .init(primary: .slightRight, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.slightRight.ranked(favoring: .slightRight),
                       .init(primary: .slightRight, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.slightRight.ranked(favoring: .right),
                       .init(primary: .slightRight, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.slightRight.ranked(favoring: .sharpRight),
                       .init(primary: .slightRight, secondary: nil, tertiary: nil))
        XCTAssertEqual(LaneIndication.slightRight.ranked(favoring: .uTurn),
                       .init(primary: .slightRight, secondary: nil, tertiary: nil))
        
        XCTAssertEqual(([.straightAhead, .left] as LaneIndication).ranked(favoring: nil),
                       .init(primary: .straightAhead, secondary: .left, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .left] as LaneIndication).ranked(favoring: .right),
                       .init(primary: .straightAhead, secondary: .left, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .left] as LaneIndication).ranked(favoring: .left),
                       .init(primary: .left, secondary: .straightAhead, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .left] as LaneIndication).ranked(favoring: .sharpLeft),
                       .init(primary: .left, secondary: .straightAhead, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .left] as LaneIndication).ranked(favoring: .slightLeft),
                       .init(primary: .left, secondary: .straightAhead, tertiary: nil))
        
        XCTAssertEqual(([.straightAhead, .slightLeft] as LaneIndication).ranked(favoring: nil),
                       .init(primary: .straightAhead, secondary: .slightLeft, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .slightLeft] as LaneIndication).ranked(favoring: .right),
                       .init(primary: .straightAhead, secondary: .slightLeft, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .slightLeft] as LaneIndication).ranked(favoring: .left),
                       .init(primary: .straightAhead, secondary: .slightLeft, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .slightLeft] as LaneIndication).ranked(favoring: .sharpLeft),
                       .init(primary: .straightAhead, secondary: .slightLeft, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .slightLeft] as LaneIndication).ranked(favoring: .slightLeft),
                       .init(primary: .slightLeft, secondary: .straightAhead, tertiary: nil))
        
        XCTAssertEqual(([.straightAhead, .right] as LaneIndication).ranked(favoring: nil),
                       .init(primary: .straightAhead, secondary: .right, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .right] as LaneIndication).ranked(favoring: .left),
                       .init(primary: .straightAhead, secondary: .right, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .right] as LaneIndication).ranked(favoring: .right),
                       .init(primary: .right, secondary: .straightAhead, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .right] as LaneIndication).ranked(favoring: .sharpRight),
                       .init(primary: .right, secondary: .straightAhead, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .right] as LaneIndication).ranked(favoring: .slightRight),
                       .init(primary: .right, secondary: .straightAhead, tertiary: nil))
        
        XCTAssertEqual(([.straightAhead, .slightRight] as LaneIndication).ranked(favoring: nil),
                       .init(primary: .straightAhead, secondary: .slightRight, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .slightRight] as LaneIndication).ranked(favoring: .left),
                       .init(primary: .straightAhead, secondary: .slightRight, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .slightRight] as LaneIndication).ranked(favoring: .right),
                       .init(primary: .straightAhead, secondary: .slightRight, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .slightRight] as LaneIndication).ranked(favoring: .sharpRight),
                       .init(primary: .straightAhead, secondary: .slightRight, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .slightRight] as LaneIndication).ranked(favoring: .slightRight),
                       .init(primary: .slightRight, secondary: .straightAhead, tertiary: nil))
        
        XCTAssertEqual(([.left, .uTurn] as LaneIndication).ranked(favoring: nil),
                       .init(primary: .left, secondary: .uTurn, tertiary: nil))
        XCTAssertEqual(([.left, .uTurn] as LaneIndication).ranked(favoring: .left),
                       .init(primary: .left, secondary: .uTurn, tertiary: nil))
        XCTAssertEqual(([.left, .uTurn] as LaneIndication).ranked(favoring: .uTurn),
                       .init(primary: .uTurn, secondary: .left, tertiary: nil))
        
        XCTAssertEqual(([.straightAhead, .uTurn] as LaneIndication).ranked(favoring: nil),
                       .init(primary: .straightAhead, secondary: .uTurn, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .uTurn] as LaneIndication).ranked(favoring: .straightAhead),
                       .init(primary: .straightAhead, secondary: .uTurn, tertiary: nil))
        XCTAssertEqual(([.straightAhead, .uTurn] as LaneIndication).ranked(favoring: .uTurn),
                       .init(primary: .uTurn, secondary: .straightAhead, tertiary: nil))
        
        XCTAssertEqual(([.left, .right] as LaneIndication).ranked(favoring: nil),
                       .init(primary: .left, secondary: .right, tertiary: nil))
        XCTAssertEqual(([.left, .right] as LaneIndication).ranked(favoring: .left),
                       .init(primary: .left, secondary: .right, tertiary: nil))
        XCTAssertEqual(([.left, .right] as LaneIndication).ranked(favoring: .right),
                       .init(primary: .right, secondary: .left, tertiary: nil))
        XCTAssertEqual(([.left, .right] as LaneIndication).ranked(favoring: .slightRight),
                       .init(primary: .right, secondary: .left, tertiary: nil))
        
        XCTAssertEqual(([.left, .slightRight] as LaneIndication).ranked(favoring: nil),
                       .init(primary: .right, secondary: .left, tertiary: nil))
        XCTAssertEqual(([.left, .slightRight] as LaneIndication).ranked(favoring: .left),
                       .init(primary: .left, secondary: .right, tertiary: nil))
        XCTAssertEqual(([.left, .slightRight] as LaneIndication).ranked(favoring: .slightRight),
                       .init(primary: .right, secondary: .left, tertiary: nil))
        XCTAssertEqual(([.left, .slightRight] as LaneIndication).ranked(favoring: .right),
                       .init(primary: .right, secondary: .left, tertiary: nil))
    }
    
    func testLaneConfiguration() {
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .uTurn, secondary: nil, tertiary: nil), drivingSide: .right),
                       .uTurn(side: .left))
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .uTurn, secondary: nil, tertiary: nil), drivingSide: .left),
                       .uTurn(side: .right))
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .uTurn, secondary: .left, tertiary: nil), drivingSide: .right),
                       .turnOrUTurn(side: .left, turn: false, uTurn: true))
        
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .straightAhead, secondary: nil, tertiary: nil), drivingSide: .right),
                       .straight)
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .straightAhead, secondary: .slightLeft, tertiary: nil), drivingSide: .right),
                       .straightOrSlightTurn(side: .left, straight: true, slightTurn: false))
        
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .slightLeft, secondary: nil, tertiary: nil), drivingSide: .right),
                       .slightTurn(side: .left))
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .slightRight, secondary: nil, tertiary: nil), drivingSide: .right),
                       .slightTurn(side: .right))
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .slightLeft, secondary: .straightAhead, tertiary: nil), drivingSide: .right),
                       .straightOrSlightTurn(side: .left, straight: false, slightTurn: true))
        
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .left, secondary: nil, tertiary: nil), drivingSide: .right),
                       .turn(side: .left))
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .right, secondary: nil, tertiary: nil), drivingSide: .right),
                       .turn(side: .right))
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .left, secondary: .right, tertiary: nil), drivingSide: .right),
                       .turnOrOppositeTurn(side: .left))
        
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .left, secondary: .straightAhead, tertiary: nil), drivingSide: .right),
                       .straightOrTurn(side: .left, straight: false, turn: true))
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .right, secondary: .straightAhead, tertiary: nil), drivingSide: .right),
                       .straightOrTurn(side: .right, straight: false, turn: true))
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .straightAhead, secondary: .left, tertiary: nil), drivingSide: .right),
                       .straightOrTurn(side: .left, straight: true, turn: false))
        XCTAssertEqual(LaneConfiguration(rankedIndications: .init(primary: .straightAhead, secondary: .right, tertiary: nil), drivingSide: .right),
                       .straightOrTurn(side: .right, straight: true, turn: false))
    }
}
