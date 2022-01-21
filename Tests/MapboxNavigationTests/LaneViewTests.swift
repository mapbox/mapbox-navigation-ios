import XCTest
import MapboxDirections
import TestHelper
@testable import MapboxNavigation

extension LanesStyleKit.Method {
    var isSymmetric: Bool {
        switch self {
        case .symmetricOn, .symmetricOff:
            return true
        default:
            return false
        }
    }
    
    var isOn: Bool {
        switch self {
        case .symmetricOn, .asymmetricOn:
            return true
        default:
            return false
        }
    }
    
    var isMixed: Bool {
        switch self {
        case .asymmetricMixed:
            return true
        default:
            return false
        }
    }
    
    var isOff: Bool {
        switch self {
        case .symmetricOff, .asymmetricOff:
            return true
        default:
            return false
        }
    }
}

class LaneViewTests: TestCase {
    func testSingularLaneIndication() {
        XCTAssertEqual(LaneIndication([.uTurn, .sharpLeft, .left, .slightLeft, .straightAhead, .slightRight, .right, .sharpRight]).singularLaneIndications,
                       [.sharpLeft, .left, .slightLeft, .straightAhead, .slightRight, .right, .sharpRight, .uTurn] as [SingularLaneIndication])
        XCTAssertEqual(LaneIndication([.right, .left, .left, .right]).singularLaneIndications,
                       [.left, .right] as [SingularLaneIndication])
        XCTAssertEqual(LaneIndication([.straightAhead, .sharpRight]).singularLaneIndications,
                       [.straightAhead, .sharpRight] as [SingularLaneIndication])
        
        XCTAssertEqual(SingularLaneIndication(.uTurn), .uTurn)
        XCTAssertEqual(SingularLaneIndication(.sharpLeft), .sharpLeft)
        XCTAssertEqual(SingularLaneIndication(.left), .left)
        XCTAssertEqual(SingularLaneIndication(.slightLeft), .slightLeft)
        XCTAssertEqual(SingularLaneIndication(.straightAhead), .straightAhead)
        XCTAssertEqual(SingularLaneIndication(.slightRight), .slightRight)
        XCTAssertEqual(SingularLaneIndication(.right), .right)
        XCTAssertEqual(SingularLaneIndication(.sharpRight), .sharpRight)
    }
    
    func testDominantSide() {
        XCTAssertEqual(LaneIndication([.left]).dominantSide(maneuverDirection: nil, drivingSide: .right), .left)
        XCTAssertEqual(LaneIndication([.right]).dominantSide(maneuverDirection: nil, drivingSide: .right), .right)
        XCTAssertEqual(LaneIndication([.left]).dominantSide(maneuverDirection: nil, drivingSide: .left), .left)
        XCTAssertEqual(LaneIndication([.right]).dominantSide(maneuverDirection: nil, drivingSide: .left), .right)
        XCTAssertEqual(LaneIndication([.uTurn]).dominantSide(maneuverDirection: nil, drivingSide: .right), .left)
        XCTAssertEqual(LaneIndication([.uTurn]).dominantSide(maneuverDirection: nil, drivingSide: .left), .right)
        XCTAssertEqual(LaneIndication([.left, .right]).dominantSide(maneuverDirection: nil, drivingSide: .left), .left)
        XCTAssertEqual(LaneIndication([.left, .right]).dominantSide(maneuverDirection: nil, drivingSide: .right), .left)
        XCTAssertEqual(LaneIndication([.left, .right]).dominantSide(maneuverDirection: .left, drivingSide: .left), .left)
        XCTAssertEqual(LaneIndication([.left, .right]).dominantSide(maneuverDirection: .left, drivingSide: .right), .left)
        XCTAssertEqual(LaneIndication([.left, .right]).dominantSide(maneuverDirection: .right, drivingSide: .left), .right)
        XCTAssertEqual(LaneIndication([.left, .right]).dominantSide(maneuverDirection: .right, drivingSide: .right), .right)
        XCTAssertEqual(LaneIndication([.uTurn, .left]).dominantSide(maneuverDirection: nil, drivingSide: .right), .left)
        XCTAssertEqual(LaneIndication([.right, .uTurn]).dominantSide(maneuverDirection: nil, drivingSide: .left), .right)
        
        // Backwards U-turns (opposite the local driving side) are unsupported, but test them anyways.
        XCTAssertEqual(LaneIndication([.uTurn, .left]).dominantSide(maneuverDirection: .uTurn, drivingSide: .left), .right)
        XCTAssertEqual(LaneIndication([.right, .uTurn]).dominantSide(maneuverDirection: .uTurn, drivingSide: .right), .left)
    }
    
    func testTurnClassification() {
        XCTAssertEqual(TurnClassification(laneIndication: .straightAhead, dominantSide: .left, drivingSide: .left), .straightAhead)
        XCTAssertEqual(TurnClassification(laneIndication: .straightAhead, dominantSide: .left, drivingSide: .right), .straightAhead)
        XCTAssertEqual(TurnClassification(laneIndication: .straightAhead, dominantSide: .right, drivingSide: .left), .straightAhead)
        XCTAssertEqual(TurnClassification(laneIndication: .straightAhead, dominantSide: .right, drivingSide: .right), .straightAhead)
        
        XCTAssertEqual(TurnClassification(laneIndication: .slightLeft, dominantSide: .left, drivingSide: .left), .slightTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .slightLeft, dominantSide: .left, drivingSide: .right), .slightTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .slightLeft, dominantSide: .right, drivingSide: .left), .oppositeSlightTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .slightLeft, dominantSide: .right, drivingSide: .right), .oppositeSlightTurn)
        
        XCTAssertEqual(TurnClassification(laneIndication: .slightRight, dominantSide: .right, drivingSide: .left), .slightTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .slightRight, dominantSide: .right, drivingSide: .right), .slightTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .slightRight, dominantSide: .left, drivingSide: .left), .oppositeSlightTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .slightRight, dominantSide: .left, drivingSide: .right), .oppositeSlightTurn)
        
        XCTAssertEqual(TurnClassification(laneIndication: .left, dominantSide: .left, drivingSide: .left), .turn)
        XCTAssertEqual(TurnClassification(laneIndication: .left, dominantSide: .left, drivingSide: .right), .turn)
        XCTAssertEqual(TurnClassification(laneIndication: .left, dominantSide: .right, drivingSide: .left), .oppositeTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .left, dominantSide: .right, drivingSide: .right), .oppositeTurn)
        
        XCTAssertEqual(TurnClassification(laneIndication: .right, dominantSide: .right, drivingSide: .left), .turn)
        XCTAssertEqual(TurnClassification(laneIndication: .right, dominantSide: .right, drivingSide: .right), .turn)
        XCTAssertEqual(TurnClassification(laneIndication: .right, dominantSide: .left, drivingSide: .left), .oppositeTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .right, dominantSide: .left, drivingSide: .right), .oppositeTurn)
        
        XCTAssertEqual(TurnClassification(laneIndication: .sharpLeft, dominantSide: .left, drivingSide: .left), .sharpTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .sharpLeft, dominantSide: .left, drivingSide: .right), .sharpTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .sharpLeft, dominantSide: .right, drivingSide: .left), .oppositeSharpTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .sharpLeft, dominantSide: .right, drivingSide: .right), .oppositeSharpTurn)
        
        XCTAssertEqual(TurnClassification(laneIndication: .sharpRight, dominantSide: .right, drivingSide: .left), .sharpTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .sharpRight, dominantSide: .right, drivingSide: .right), .sharpTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .sharpRight, dominantSide: .left, drivingSide: .left), .oppositeSharpTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .sharpRight, dominantSide: .left, drivingSide: .right), .oppositeSharpTurn)
        
        XCTAssertEqual(TurnClassification(laneIndication: .uTurn, dominantSide: .left, drivingSide: .left), .oppositeUTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .uTurn, dominantSide: .left, drivingSide: .right), .uTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .uTurn, dominantSide: .right, drivingSide: .left), .uTurn)
        XCTAssertEqual(TurnClassification(laneIndication: .uTurn, dominantSide: .right, drivingSide: .right), .oppositeUTurn)
    }
    
    func testStyleKitMethodSingleUse() {
        // Swift offers no way to compare two methods, so test whether the method has the expected symmetry.
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead], favoredTurnClassification: nil)?.isSymmetric, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.sharpTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.uTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        
        // `LaneIndication.singularLaneIndications` wouldn’t return a sole opposite indication.
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSlightTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSharpTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeUTurn], favoredTurnClassification: nil))
        
        // Test whether the method has the expected active state.
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead], favoredTurnClassification: .straightAhead)?.isOn, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn], favoredTurnClassification: .slightTurn)?.isOn, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn], favoredTurnClassification: .turn)?.isOn, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.sharpTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.sharpTurn], favoredTurnClassification: .sharpTurn)?.isOn, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.uTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.uTurn], favoredTurnClassification: .uTurn)?.isOn, true)
        
        // Unrecognized turn indications show up as empty lanes in the Directions API response.
        // https://github.com/mapbox/mapbox-navigation-ios/issues/3596
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [], favoredTurnClassification: .straightAhead))
    }
    
    func testStyleKitMethodDoubleUseAllowingStraightAhead() {
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .slightTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .turn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .sharpTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .uTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        
        // `LaneIndication.singularLaneIndications` wouldn’t return an opposite indication without an indication on the dominant side.
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .oppositeSlightTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .oppositeTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .oppositeSharpTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .oppositeUTurn], favoredTurnClassification: nil))
        
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .slightTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .slightTurn], favoredTurnClassification: .straightAhead)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .slightTurn], favoredTurnClassification: .slightTurn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .turn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .turn], favoredTurnClassification: .straightAhead)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .turn], favoredTurnClassification: .turn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .sharpTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .sharpTurn], favoredTurnClassification: .straightAhead)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .sharpTurn], favoredTurnClassification: .sharpTurn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .uTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .uTurn], favoredTurnClassification: .straightAhead)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .uTurn], favoredTurnClassification: .uTurn)?.isMixed, true)
    }
    
    func testStyleKitMethodDoubleUseAllowingSlightTurn() {
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .turn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .sharpTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .uTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .oppositeSlightTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .oppositeTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        
        // Too rare to support: https://github.com/mapbox/navigation-ui-resources/pull/26#issue-993951098
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .oppositeSharpTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .oppositeUTurn], favoredTurnClassification: nil))
        
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .turn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .turn], favoredTurnClassification: .slightTurn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .turn], favoredTurnClassification: .turn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .sharpTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .sharpTurn], favoredTurnClassification: .slightTurn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .sharpTurn], favoredTurnClassification: .sharpTurn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .uTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .uTurn], favoredTurnClassification: .slightTurn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .uTurn], favoredTurnClassification: .uTurn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .oppositeSlightTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .oppositeSlightTurn], favoredTurnClassification: .slightTurn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .oppositeSlightTurn], favoredTurnClassification: .oppositeSlightTurn)?.isOff, true, "Shouldn’t favor opposite slight turn")
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .oppositeTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .oppositeTurn], favoredTurnClassification: .slightTurn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .oppositeTurn], favoredTurnClassification: .oppositeTurn)?.isOff, true, "Shouldn’t favor opposite turn")
    }
    
    func testStyleKitMethodDoubleUseAllowingTurn() {
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .sharpTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .uTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .oppositeSlightTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .oppositeTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        
        // Too rare to support: https://github.com/mapbox/navigation-ui-resources/pull/26#issue-993951098
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .oppositeSharpTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .oppositeUTurn], favoredTurnClassification: nil))
        
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .sharpTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .sharpTurn], favoredTurnClassification: .turn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .sharpTurn], favoredTurnClassification: .sharpTurn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .uTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .uTurn], favoredTurnClassification: .turn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .uTurn], favoredTurnClassification: .uTurn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .oppositeSlightTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .oppositeSlightTurn], favoredTurnClassification: .turn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .oppositeSlightTurn], favoredTurnClassification: .oppositeSlightTurn)?.isOff, true, "Shouldn’t favor opposite slight turn")
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .oppositeTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .oppositeTurn], favoredTurnClassification: .turn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.turn, .oppositeTurn], favoredTurnClassification: .oppositeTurn)?.isOff, true, "Shouldn’t favor opposite turn")
    }
    
    func testStyleKitMethodDoubleUseAllowingSharpTurn() {
        // Too rare to support: https://github.com/mapbox/navigation-ui-resources/pull/26#issue-993951098
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.sharpTurn, .uTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.sharpTurn, .oppositeSlightTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.sharpTurn, .oppositeTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.sharpTurn, .oppositeSlightTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.sharpTurn, .oppositeSharpTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.sharpTurn, .oppositeUTurn], favoredTurnClassification: nil))
    }
    
    func testStyleKitMethodDoubleUseAllowingUTurn() {
        // Too rare to support: https://github.com/mapbox/navigation-ui-resources/pull/26#issue-993951098
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.uTurn, .oppositeSlightTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.uTurn, .oppositeTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.uTurn, .oppositeSlightTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.uTurn, .oppositeSharpTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.uTurn, .oppositeUTurn], favoredTurnClassification: nil))
    }
    
    func testStyleKitMethodTripleUseAllowingStraightAhead() {
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .slightTurn, .turn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .turn, .uTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSlightTurn, .straightAhead, .slightTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeTurn, .straightAhead, .slightTurn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSlightTurn, .straightAhead, .turn], favoredTurnClassification: nil)?.isSymmetric, false)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeTurn, .straightAhead, .turn], favoredTurnClassification: nil)?.isSymmetric, false)
        
        // Too rare to support: https://github.com/mapbox/navigation-ui-resources/pull/26#issue-993951098
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .slightTurn, .sharpTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .slightTurn, .uTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSharpTurn, .straightAhead, .slightTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeUTurn, .straightAhead, .slightTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .turn, .sharpTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .sharpTurn, .uTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSharpTurn, .straightAhead, .turn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeUTurn, .straightAhead, .turn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSlightTurn, .straightAhead, .sharpTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeTurn, .straightAhead, .sharpTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSharpTurn, .straightAhead, .sharpTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeUTurn, .straightAhead, .sharpTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.slightTurn, .straightAhead, .uTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeTurn, .straightAhead, .uTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSharpTurn, .straightAhead, .uTurn], favoredTurnClassification: nil))
        XCTAssertNil(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeUTurn, .straightAhead, .uTurn], favoredTurnClassification: nil))
        
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .slightTurn, .turn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .slightTurn, .turn], favoredTurnClassification: .straightAhead)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .slightTurn, .turn], favoredTurnClassification: .slightTurn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .slightTurn, .turn], favoredTurnClassification: .turn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .turn, .uTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .turn, .uTurn], favoredTurnClassification: .straightAhead)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .turn, .uTurn], favoredTurnClassification: .turn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.straightAhead, .turn, .uTurn], favoredTurnClassification: .uTurn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSlightTurn, .straightAhead, .slightTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSlightTurn, .straightAhead, .slightTurn], favoredTurnClassification: .straightAhead)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSlightTurn, .straightAhead, .slightTurn], favoredTurnClassification: .slightTurn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSlightTurn, .straightAhead, .slightTurn], favoredTurnClassification: .oppositeSlightTurn)?.isMixed, false, "Shouldn’t favor opposite turn")
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeTurn, .straightAhead, .slightTurn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeTurn, .straightAhead, .slightTurn], favoredTurnClassification: .straightAhead)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeTurn, .straightAhead, .slightTurn], favoredTurnClassification: .slightTurn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeTurn, .straightAhead, .slightTurn], favoredTurnClassification: .oppositeTurn)?.isMixed, false, "Shouldn’t favor opposite turn")
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSlightTurn, .straightAhead, .turn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSlightTurn, .straightAhead, .turn], favoredTurnClassification: .straightAhead)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSlightTurn, .straightAhead, .turn], favoredTurnClassification: .turn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeSlightTurn, .straightAhead, .turn], favoredTurnClassification: .oppositeSlightTurn)?.isMixed, false, "Shouldn’t favor opposite turn")
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeTurn, .straightAhead, .turn], favoredTurnClassification: nil)?.isOff, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeTurn, .straightAhead, .turn], favoredTurnClassification: .straightAhead)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeTurn, .straightAhead, .turn], favoredTurnClassification: .turn)?.isMixed, true)
        XCTAssertEqual(LanesStyleKit.styleKitMethod(turnClassifications: [.oppositeTurn, .straightAhead, .turn], favoredTurnClassification: .oppositeTurn)?.isMixed, false, "Shouldn’t favor opposite turn")
    }
    
    func testStyleKitMethodByLaneIndication() {
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.straightAhead], maneuverDirection: nil, drivingSide: .right).isSymmetric)
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.straightAhead], maneuverDirection: nil, drivingSide: .right).isOff)
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.straightAhead], maneuverDirection: .left, drivingSide: .right).isOff)
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.straightAhead], maneuverDirection: .straightAhead, drivingSide: .right).isOn)
        
        XCTAssertFalse(LanesStyleKit.styleKitMethod(lane: [.sharpLeft, .sharpRight], maneuverDirection: .sharpLeft, drivingSide: .right).isSymmetric, "Unsupported configuration should fall back to maneuver direction")
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.sharpLeft, .sharpRight], maneuverDirection: .sharpLeft, drivingSide: .right).isOn, "Unsupported configuration should fall back to maneuver direction")
        
        XCTAssertFalse(LanesStyleKit.styleKitMethod(lane: [.left, .straightAhead, .right, .uTurn], maneuverDirection: nil, drivingSide: .right).isSymmetric, "Quadruple use should be simplified")
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.left, .straightAhead, .right, .uTurn], maneuverDirection: nil, drivingSide: .right).isOff, "Quadruple use should be simplified")
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.left, .straightAhead, .right, .uTurn], maneuverDirection: .left, drivingSide: .right).isMixed, "Quadruple use should be simplified")
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.left, .straightAhead, .right, .uTurn], maneuverDirection: .straightAhead, drivingSide: .right).isMixed, "Quadruple use should be simplified")
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.left, .straightAhead, .right, .uTurn], maneuverDirection: .right, drivingSide: .right).isMixed, "Quadruple use should be simplified")
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.left, .straightAhead, .right, .uTurn], maneuverDirection: .uTurn, drivingSide: .right).isMixed, "Quadruple use should be simplified")
        
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.straightAhead, .slightLeft, .left, .sharpLeft], maneuverDirection: nil, drivingSide: .right).isSymmetric, "Quadruple use should be simplified and fall back to maneuver direction")
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.straightAhead, .slightLeft, .left, .sharpLeft], maneuverDirection: nil, drivingSide: .right).isOff, "Quadruple use should be simplified and fall back to maneuver direction")
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.straightAhead, .slightLeft, .left, .sharpLeft], maneuverDirection: .straightAhead, drivingSide: .right).isOn, "Quadruple use should be simplified and fall back to maneuver direction")
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.straightAhead, .slightLeft, .left, .sharpLeft], maneuverDirection: .slightLeft, drivingSide: .right).isOn, "Quadruple use should be simplified and fall back to maneuver direction")
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.straightAhead, .slightLeft, .left, .sharpLeft], maneuverDirection: .left, drivingSide: .right).isOn, "Quadruple use should be simplified and fall back to maneuver direction")
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.straightAhead, .slightLeft, .left, .sharpLeft], maneuverDirection: .sharpLeft, drivingSide: .right).isOn, "Quadruple use should be simplified and fall back to maneuver direction")
        
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.sharpLeft, .sharpRight], maneuverDirection: nil, drivingSide: .right).isSymmetric, "Unsupported configuration should fall back to straight ahead")
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [.sharpLeft, .sharpRight], maneuverDirection: nil, drivingSide: .right).isOff, "Unsupported configuration should fall back to straight ahead")
        
        // Unrecognized turn indications show up as empty lanes in the Directions API response.
        // https://github.com/mapbox/mapbox-navigation-ios/issues/3596
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [], maneuverDirection: .left, drivingSide: .right).isSymmetric)
        XCTAssertTrue(LanesStyleKit.styleKitMethod(lane: [], maneuverDirection: .left, drivingSide: .right).isOff)
    }
}
