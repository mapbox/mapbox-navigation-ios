import UIKit
import MapboxDirections

extension LaneIndication {
    static let lefts: LaneIndication = [.sharpLeft, .left, .slightLeft]
    static let rights: LaneIndication = [.sharpRight, .right, .slightRight]
    
    struct Ranking: Equatable {
        let primary: LaneIndication
        let secondary: LaneIndication?
        let tertiary: LaneIndication?
    }
    
    /**
     Separates the indication into primary, secondary, and tertiary indications with a bias toward the given maneuver direction.
     
     The return values are influenced by the set of available drawing methods in LanesStyleKit.
     */
    func ranked(favoring maneuverDirection: ManeuverDirection?) -> Ranking {
        var indications = self
        
        // There are only assets for the most common configurations, so prioritize the indication that matches the maneuver direction.
        var primaryIndication: LaneIndication
        // Prioritize matches with the maneuver direction.
        if indications.contains(.straightAhead) && maneuverDirection ?? .straightAhead == .straightAhead {
            primaryIndication = .straightAhead
        } else if indications.contains(.slightLeft) && maneuverDirection ?? .slightLeft == .slightLeft {
            primaryIndication = .slightLeft
        } else if indications.contains(.slightRight) && maneuverDirection ?? .slightRight == .slightRight {
            primaryIndication = .slightRight
        } else if indications.isSubset(of: [.left, .straightAhead]) && maneuverDirection ?? .slightLeft == .slightLeft {
            primaryIndication = .left
        } else if indications.isSubset(of: [.right, .straightAhead]) && maneuverDirection ?? .slightRight == .slightRight {
            primaryIndication = .right
        } else if indications.contains(.left) && maneuverDirection ?? .left == .left {
            primaryIndication = .left
        } else if indications.contains(.right) && maneuverDirection ?? .right == .right {
            primaryIndication = .right
        } else if indications.contains(.sharpLeft) && maneuverDirection ?? .sharpLeft == .sharpLeft {
            primaryIndication = .sharpLeft
        } else if indications.contains(.sharpRight) && maneuverDirection ?? .sharpRight == .sharpRight {
            primaryIndication = .sharpRight
        } else if indications.contains(.left) && !indications.contains(.sharpLeft) && !indications.contains(.uTurn) && maneuverDirection ?? .sharpLeft == .sharpLeft {
            primaryIndication = .left
        } else if indications.contains(.right) && !indications.contains(.sharpRight) && !indications.contains(.uTurn) && maneuverDirection ?? .sharpRight == .sharpRight {
            primaryIndication = .right
        } else if !indications.isDisjoint(with: .lefts) && !indications.isDisjoint(with: .rights) && maneuverDirection?.isLeft ?? false {
            primaryIndication = .left
        } else if !indications.isDisjoint(with: .lefts) && !indications.isDisjoint(with: .rights) && maneuverDirection?.isRight ?? false {
            primaryIndication = .right
        } else if indications.contains(.uTurn) && maneuverDirection ?? .uTurn == .uTurn {
            primaryIndication = .uTurn
        } else {
            // The lane doesn’t match the maneuver direction, so choose the least extreme indication.
            // Most likely the lane will appear unhighlighted anyways.
            if indications.contains(.straightAhead) {
                primaryIndication = .straightAhead
            } else if indications.contains(.slightLeft) {
                primaryIndication = .slightLeft
            } else if indications.contains(.slightRight) {
                primaryIndication = .slightRight
            } else if indications.contains(.left) {
                primaryIndication = .left
            } else if indications.contains(.right) {
                primaryIndication = .right
            } else if indications.contains(.sharpLeft) {
                primaryIndication = .sharpLeft
            } else if indications.contains(.sharpRight) {
                primaryIndication = .sharpRight
            } else if indications.contains(.uTurn) {
                primaryIndication = .uTurn
            } else {
                // No indications to draw.
                return Ranking(primary: [], secondary: nil, tertiary: nil)
            }
        }
        
        indications.remove(primaryIndication)
        
        // Some dual-use configurations are supported.
        let secondaryIndication: LaneIndication?
        if indications.contains(.straightAhead) {
            secondaryIndication = .straightAhead
        } else if !primaryIndication.isDisjoint(with: .rights) && indications.contains(.slightLeft) {
            // No assets for slight or sharp opposite turns.
            secondaryIndication = .left
        } else if !primaryIndication.isDisjoint(with: .lefts) && indications.contains(.slightRight) {
            // No assets for slight or sharp opposite turns.
            secondaryIndication = .right
        } else if indications.contains(.left) {
            secondaryIndication = .left
            // No assets for slight or sharp opposite turns.
            if primaryIndication == .slightRight || primaryIndication == .sharpRight {
                primaryIndication = .right
            }
        } else if indications.contains(.right) {
            secondaryIndication = .right
            // No assets for slight or sharp opposite turns.
            if primaryIndication == .slightLeft || primaryIndication == .sharpLeft {
                primaryIndication = .left
            }
        } else if !primaryIndication.isDisjoint(with: .rights) && indications.contains(.sharpLeft) {
            // No assets for slight or sharp opposite turns.
            secondaryIndication = .left
        } else if !primaryIndication.isDisjoint(with: .lefts) && indications.contains(.sharpRight) {
            // No assets for slight or sharp opposite turns.
            secondaryIndication = .right
        } else if indications.contains(.uTurn) {
            secondaryIndication = .uTurn
            // No asset for sharp turn or U-turn.
            if primaryIndication == .sharpLeft {
                primaryIndication = .left
            } else if primaryIndication == .sharpRight {
                primaryIndication = .right
            }
        } else if !primaryIndication.isDisjoint(with: .rights) && !indications.isDisjoint(with: .lefts) {
            secondaryIndication = .left
        } else if !primaryIndication.isDisjoint(with: .lefts) && !indications.isDisjoint(with: .rights) {
            secondaryIndication = .right
        } else if primaryIndication == .straightAhead && indications == .slightLeft {
            secondaryIndication = .slightLeft
        } else if primaryIndication == .straightAhead && indications == .slightRight {
            secondaryIndication = .slightRight
        } else {
            secondaryIndication = nil
        }
        
        if let secondaryIndication = secondaryIndication {
            indications.remove(secondaryIndication)
            
            // Some triple-use configurations are supported.
            let tertiaryIndication: LaneIndication?
            if !primaryIndication.isSubset(of: [.straightAhead, .uTurn]) && !secondaryIndication.isSubset(of: [.straightAhead, .uTurn]) &&
                indications.contains(.straightAhead) {
                tertiaryIndication = .straightAhead
            } else if (primaryIndication == .straightAhead && !secondaryIndication.isDisjoint(with: .rights) ||
                        !primaryIndication.isDisjoint(with: .rights) && secondaryIndication == .straightAhead) &&
                        !indications.isDisjoint(with: .lefts) {
                tertiaryIndication = .left
            } else if (primaryIndication == .straightAhead && !secondaryIndication.isDisjoint(with: .lefts) ||
                        !primaryIndication.isDisjoint(with: .lefts) && secondaryIndication == .straightAhead) &&
                        !indications.isDisjoint(with: .rights) {
                tertiaryIndication = .right
            } else if (primaryIndication == .straightAhead && !secondaryIndication.isSubset(of: [.straightAhead, .uTurn]) ||
                        !primaryIndication.isSubset(of: [.straightAhead, .uTurn]) && secondaryIndication == .straightAhead) &&
                        indications == .uTurn {
                tertiaryIndication = .uTurn
            } else {
                tertiaryIndication = nil
            }
            return Ranking(primary: primaryIndication, secondary: secondaryIndication, tertiary: tertiaryIndication)
        } else {
            // No secondary indication to draw.
            return Ranking(primary: primaryIndication, secondary: nil, tertiary: nil)
        }
    }
}

/**
 A generalized representation of the drawing methods available in LanesStyleKit.
 */
enum LaneConfiguration: Equatable {
    case straight
    case slightTurn(side: DrivingSide)
    case turn(side: DrivingSide)
    case sharpTurn(side: DrivingSide)
    case uTurn(side: DrivingSide)
    
    case straightOrSlightTurn(side: DrivingSide, straight: Bool, slightTurn: Bool)
    case straightOrTurn(side: DrivingSide, straight: Bool, turn: Bool)
    case straightOrSharpTurn(side: DrivingSide, straight: Bool, sharpTurn: Bool)
    case straightOrUTurn(side: DrivingSide, straight: Bool, uTurn: Bool)
    
    case slightTurnOrTurn(side: DrivingSide, slightTurn: Bool, turn: Bool)
    case slightTurnOrSharpTurn(side: DrivingSide, slightTurn: Bool, sharpTurn: Bool)
    case slightTurnOrUTurn(side: DrivingSide, slightTurn: Bool, uTurn: Bool)
    
    case turnOrSharpTurn(side: DrivingSide, turn: Bool, sharpTurn: Bool)
    case turnOrUTurn(side: DrivingSide, turn: Bool, uTurn: Bool)
    case turnOrOppositeTurn(side: DrivingSide)
    
    case straightOrTurnOrOppositeTurn(side: DrivingSide, straight: Bool, turn: Bool)
    case straightOrTurnOrUTurn(side: DrivingSide, straight: Bool, turn: Bool, uTurn: Bool)
    
    init?(rankedIndications: LaneIndication.Ranking, drivingSide: DrivingSide) {
        switch (rankedIndications.primary, rankedIndications.secondary, rankedIndications.tertiary) {
        // Single-use lanes
        case (.straightAhead, .none, .none):
            self = .straight
        case (.slightLeft, .none, .none):
            self = .slightTurn(side: .left)
        case (.slightRight, .none, .none):
            self = .slightTurn(side: .right)
        case (.left, .none, .none):
            self = .turn(side: .left)
        case (.right, .none, .none):
            self = .turn(side: .right)
        case (.sharpLeft, .none, .none):
            self = .sharpTurn(side: .left)
        case (.sharpRight, .none, .none):
            self = .sharpTurn(side: .right)
        case (.uTurn, .none, .none):
            // When you drive on the right, you U-turn to the left and vice versa.
            self = .uTurn(side: drivingSide == .right ? .left : .right)
        
        // Dual-use lanes
        case (.straightAhead, .some(.slightLeft), .none):
            self = .straightOrSlightTurn(side: .left, straight: true, slightTurn: false)
        case (.straightAhead, .some(.slightRight), .none):
            self = .straightOrSlightTurn(side: .right, straight: true, slightTurn: false)
        case (.slightLeft, .some(.straightAhead), .none):
            self = .straightOrSlightTurn(side: .left, straight: false, slightTurn: true)
        case (.slightRight, .some(.straightAhead), .none):
            self = .straightOrSlightTurn(side: .right, straight: false, slightTurn: true)
        case (.straightAhead, .some(.left), .none):
            self = .straightOrTurn(side: .left, straight: true, turn: false)
        case (.straightAhead, .some(.right), .none):
            self = .straightOrTurn(side: .right, straight: true, turn: false)
        case (.left, .some(.straightAhead), .none):
            self = .straightOrTurn(side: .left, straight: false, turn: true)
        case (.right, .some(.straightAhead), .none):
            self = .straightOrTurn(side: .right, straight: false, turn: true)
        case (.straightAhead, .some(.sharpLeft), .none):
            self = .straightOrSharpTurn(side: .left, straight: true, sharpTurn: false)
        case (.straightAhead, .some(.sharpRight), .none):
            self = .straightOrSharpTurn(side: .right, straight: true, sharpTurn: false)
        case (.sharpLeft, .some(.straightAhead), .none):
            self = .straightOrSharpTurn(side: .left, straight: false, sharpTurn: true)
        case (.sharpRight, .some(.straightAhead), .none):
            self = .straightOrSharpTurn(side: .right, straight: false, sharpTurn: true)
        case (.straightAhead, .some(.uTurn), .none):
            // When you drive on the right, you U-turn to the left and vice versa.
            self = .straightOrUTurn(side: drivingSide == .right ? .left : .right, straight: true, uTurn: false)
        case (.uTurn, .some(.straightAhead), .none):
            // When you drive on the right, you U-turn to the left and vice versa.
            self = .straightOrUTurn(side: drivingSide == .right ? .left : .right, straight: false, uTurn: true)
            
        case (.slightLeft, .some(.left), .none):
            self = .slightTurnOrTurn(side: .left, slightTurn: true, turn: false)
        case (.slightRight, .some(.right), .none):
            self = .slightTurnOrTurn(side: .right, slightTurn: true, turn: false)
        case (.left, .some(.slightLeft), .none):
            self = .slightTurnOrTurn(side: .left, slightTurn: false, turn: true)
        case (.right, .some(.slightRight), .none):
            self = .slightTurnOrTurn(side: .right, slightTurn: false, turn: true)
        case (.slightLeft, .some(.sharpLeft), .none):
            self = .slightTurnOrSharpTurn(side: .left, slightTurn: true, sharpTurn: false)
        case (.slightRight, .some(.sharpRight), .none):
            self = .slightTurnOrSharpTurn(side: .right, slightTurn: true, sharpTurn: false)
        case (.sharpLeft, .some(.slightLeft), .none):
            self = .slightTurnOrSharpTurn(side: .left, slightTurn: false, sharpTurn: true)
        case (.sharpRight, .some(.slightRight), .none):
            self = .slightTurnOrSharpTurn(side: .right, slightTurn: false, sharpTurn: true)
        case (.slightLeft, .some(.uTurn), .none) where drivingSide == .right:
            // When you drive on the right, you U-turn to the left.
            self = .slightTurnOrUTurn(side: .left, slightTurn: true, uTurn: false)
        case (.slightRight, .some(.uTurn), .none) where drivingSide == .left:
            // When you drive on the left, you U-turn to the right.
            self = .slightTurnOrUTurn(side: .right, slightTurn: true, uTurn: false)
        case (.uTurn, .some(.slightLeft), .none) where drivingSide == .right:
            // When you drive on the right, you U-turn to the left.
            self = .slightTurnOrUTurn(side: .left, slightTurn: false, uTurn: true)
        case (.uTurn, .some(.slightRight), .none) where drivingSide == .left:
            // When you drive on the left, you U-turn to the right.
            self = .slightTurnOrUTurn(side: .right, slightTurn: false, uTurn: true)
            
        case (.left, .some(.sharpLeft), .none):
            self = .turnOrSharpTurn(side: .left, turn: true, sharpTurn: false)
        case (.right, .some(.sharpRight), .none):
            self = .turnOrSharpTurn(side: .right, turn: true, sharpTurn: false)
        case (.sharpLeft, .some(.left), .none):
            self = .turnOrSharpTurn(side: .left, turn: false, sharpTurn: true)
        case (.sharpRight, .some(.right), .none):
            self = .turnOrSharpTurn(side: .right, turn: false, sharpTurn: true)
        case (.left, .some(.uTurn), .none) where drivingSide == .right:
            // When you drive on the right, you U-turn to the left.
            self = .turnOrUTurn(side: .left, turn: true, uTurn: false)
        case (.right, .some(.uTurn), .none) where drivingSide == .left:
            // When you drive on the left, you U-turn to the right.
            self = .turnOrUTurn(side: .right, turn: true, uTurn: false)
        case (.uTurn, .some(.left), .none) where drivingSide == .right:
            // When you drive on the right, you U-turn to the left.
            self = .turnOrUTurn(side: .left, turn: false, uTurn: true)
        case (.uTurn, .some(.right), .none) where drivingSide == .left:
            // When you drive on the left, you U-turn to the right.
            self = .turnOrUTurn(side: .right, turn: false, uTurn: true)
        case (.left, .some(.right), .none):
            self = .turnOrOppositeTurn(side: .left)
        case (.right, .some(.left), .none):
            self = .turnOrOppositeTurn(side: .right)
            
        case (.straightAhead, .some(.left), .some(.right)),
             (.straightAhead, .some(.right), .some(.left)):
            self = .straightOrTurnOrOppositeTurn(side: .left, straight: true, turn: false)
        case (.left, .some(.straightAhead), .some(.right)),
             (.left, .some(.right), .some(.straightAhead)):
            self = .straightOrTurnOrOppositeTurn(side: .left, straight: false, turn: true)
        case (.right, .some(.straightAhead), .some(.left)),
             (.right, .some(.left), .some(.straightAhead)):
            self = .straightOrTurnOrOppositeTurn(side: .right, straight: false, turn: true)
        case (.straightAhead, .some(.left), .some(.uTurn)) where drivingSide == .right,
             (.straightAhead, .some(.right), .some(.uTurn)) where drivingSide == .right:
            // When you drive on the right, you U-turn to the left.
            self = .straightOrTurnOrUTurn(side: .left, straight: true, turn: false, uTurn: false)
        case (.straightAhead, .some(.left), .some(.uTurn)) where drivingSide == .left,
             (.straightAhead, .some(.right), .some(.uTurn)) where drivingSide == .left:
            // When you drive on the left, you U-turn to the right.
            self = .straightOrTurnOrUTurn(side: .right, straight: true, turn: false, uTurn: false)
        case (.left, .some(.straightAhead), .some(.uTurn)) where drivingSide == .right,
             (.left, .some(.uTurn), .some(.straightAhead)) where drivingSide == .right:
            // When you drive on the right, you U-turn to the left.
            self = .straightOrTurnOrUTurn(side: .left, straight: false, turn: true, uTurn: false)
        case (.right, .some(.straightAhead), .some(.uTurn)) where drivingSide == .left,
             (.right, .some(.uTurn), .some(.straightAhead)) where drivingSide == .left:
            // When you drive on the left, you U-turn to the right.
            self = .straightOrTurnOrUTurn(side: .right, straight: false, turn: true, uTurn: false)
        case (.uTurn, .some(.straightAhead), .some(.left)) where drivingSide == .right,
             (.uTurn, .some(.left), .some(.straightAhead)) where drivingSide == .right:
            // When you drive on the right, you U-turn to the left.
            self = .straightOrTurnOrUTurn(side: .left, straight: false, turn: false, uTurn: true)
        case (.uTurn, .some(.straightAhead), .some(.right)) where drivingSide == .left,
             (.uTurn, .some(.right), .some(.straightAhead)) where drivingSide == .left:
            // When you drive on the left, you U-turn to the right.
            self = .straightOrTurnOrUTurn(side: .right, straight: false, turn: false, uTurn: true)
            
        default:
            return nil
        }
    }
}

extension ManeuverDirection {
    var isLeft: Bool {
        return self == .sharpLeft || self == .left || self == .slightLeft
    }
    
    var isRight: Bool {
        return self == .sharpRight || self == .right || self == .slightRight
    }
}

/// :nodoc:
open class LaneView: UIView {
    var indications: LaneIndication {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var maneuverDirection: ManeuverDirection? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var isValid: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var drivingSide: DrivingSide = .right {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override open var intrinsicContentSize: CGSize {
        return bounds.size
    }
    
    @objc public dynamic var primaryColor: UIColor = .defaultLaneArrowPrimary {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @objc public dynamic var secondaryColor: UIColor = .defaultLaneArrowSecondary {
        didSet {
            setNeedsDisplay()
        }
    }

    @objc public dynamic var primaryColorHighlighted: UIColor = .defaultLaneArrowPrimaryHighlighted {
        didSet {
            setNeedsDisplay()
        }
    }

    @objc public dynamic var secondaryColorHighlighted: UIColor = .defaultLaneArrowSecondaryHighlighted {
        didSet {
            setNeedsDisplay()
        }
    }

    public var showHighlightedColors: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var appropriatePrimaryColor: UIColor {
        if isValid {
            return showHighlightedColors ? primaryColorHighlighted : primaryColor
        } else {
            return showHighlightedColors ? secondaryColorHighlighted : secondaryColor
        }
    }

    var appropriateSecondaryColor: UIColor {
        return showHighlightedColors ? secondaryColorHighlighted : secondaryColor
    }
    
    static let defaultFrame: CGRect = CGRect(origin: .zero, size: 30.0)
    
    convenience init(indications: LaneIndication, isUsable: Bool, direction: ManeuverDirection?) {
        self.init(frame: LaneView.defaultFrame)
        backgroundColor = .clear
        self.indications = indications
        maneuverDirection = direction ?? ManeuverDirection(rawValue: indications.description)
        isValid = isUsable
    }

    override init(frame: CGRect) {
        indications = []
        super.init(frame: frame)
        commonInit()
    }

    @objc public required init?(coder aDecoder: NSCoder) {
        indications = []
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        // Explicitly mark the view as non-opaque.
        // This is needed to obtain correct compositing since we implement our own draw function that includes transparency.
        isOpaque = false
    }
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        
        #if TARGET_INTERFACE_BUILDER
        isValid = true
        indications = [.straightAhead, .right]
        maneuverDirection = .right
        #endif
        
        let resizing = LanesStyleKit.ResizingBehavior.aspectFit
        let appropriateColor = isValid ? appropriatePrimaryColor : appropriateSecondaryColor
        
        let rankedIndications = indications.ranked(favoring: maneuverDirection)
        guard let laneConfiguration = LaneConfiguration(rankedIndications: rankedIndications, drivingSide: drivingSide) else {
            return
        }
        
        switch laneConfiguration {
        case .straight:
            LanesStyleKit.drawLaneStraight(frame: bounds, resizing: resizing, primaryColor: appropriateColor)
        case .slightTurn(side: let side):
            LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriateColor,
                                              flipHorizontally: side == .left)
        case .turn(side: let side):
            LanesStyleKit.drawLaneRight(frame: bounds, resizing: resizing, primaryColor: appropriateColor,
                                        flipHorizontally: side == .left)
        case .sharpTurn(side: let side):
            LanesStyleKit.drawLaneSharpRight(frame: bounds, resizing: resizing, primaryColor: appropriateColor, flipHorizontally: side == .left)
        case .uTurn(side: let side):
            LanesStyleKit.drawLaneUturn(frame: bounds, resizing: resizing, primaryColor: appropriateColor,
                                        flipHorizontally: side == .left)
        case .straightOrSlightTurn(side: let side, straight: let straight, slightTurn: let slightTurn):
            if isValid && straight && !slightTurn {
                LanesStyleKit.drawLaneStraightNotSlightRight(frame: bounds, resizing: resizing,
                                                             primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                             flipHorizontally: side == .left)
            } else if isValid && !straight && slightTurn {
                LanesStyleKit.drawLaneSlightRightNotStraight(frame: bounds, resizing: resizing,
                                                             primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                             flipHorizontally: side == .left)
            } else {
                // No dedicated asset for an unhighlighted dual use lane, so use the unhighlighted color as both primary and secondary colors.
                LanesStyleKit.drawLaneStraightNotSlightRight(frame: bounds, resizing: resizing,
                                                             primaryColor: appropriateColor, secondaryColor: appropriateColor,
                                                             flipHorizontally: side == .left)
            }
        case .straightOrTurn(side: let side, straight: let straight, turn: let turn):
            if isValid && straight && !turn {
                LanesStyleKit.drawLaneStraightNotRight(frame: bounds, resizing: resizing,
                                                       primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                       flipHorizontally: side == .left)
            } else if isValid && !straight && turn {
                LanesStyleKit.drawLaneRightNotStraight(frame: bounds, resizing: resizing,
                                                       primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                       flipHorizontally: side == .left)
            } else {
                // No dedicated asset for an unhighlighted dual use lane, so use the unhighlighted color as both primary and secondary colors.
                LanesStyleKit.drawLaneStraightNotRight(frame: bounds, resizing: resizing,
                                                       primaryColor: appropriateColor, secondaryColor: appropriateColor,
                                                       flipHorizontally: side == .left)
            }
        case .straightOrSharpTurn(side: let side, straight: let straight, sharpTurn: let sharpTurn):
            if isValid && straight && !sharpTurn {
                LanesStyleKit.drawLaneStraightNotSharpRight(frame: bounds, resizing: resizing,
                                                            primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                            flipHorizontally: side == .left)
            } else if isValid && !straight && sharpTurn {
                LanesStyleKit.drawLaneSharpRightNotStraight(frame: bounds, resizing: resizing,
                                                            primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                            flipHorizontally: side == .left)
            } else {
                // No dedicated asset for an unhighlighted dual use lane, so use the unhighlighted color as both primary and secondary colors.
                LanesStyleKit.drawLaneStraightNotSharpRight(frame: bounds, resizing: resizing,
                                                            primaryColor: appropriateColor, secondaryColor: appropriateColor,
                                                            flipHorizontally: side == .left)
            }
        case .straightOrUTurn(side: let side, straight: let straight, uTurn: let uTurn):
            if isValid && straight && !uTurn {
                LanesStyleKit.drawLaneStraightNotUturn(frame: bounds, resizing: resizing,
                                                       primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                       flipHorizontally: side == .left)
            } else if isValid && !straight && uTurn {
                LanesStyleKit.drawLaneUturnNotStraight(frame: bounds, resizing: resizing,
                                                       primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                       flipHorizontally: side == .left)
            } else {
                // No dedicated asset for an unhighlighted dual use lane, so use the unhighlighted color as both primary and secondary colors.
                LanesStyleKit.drawLaneStraightNotUturn(frame: bounds, resizing: resizing,
                                                       primaryColor: appropriateColor, secondaryColor: appropriateColor,
                                                       flipHorizontally: side == .left)
            }
        case .slightTurnOrTurn(side: let side, slightTurn: let slightTurn, turn: let turn):
            if isValid && slightTurn && !turn {
                LanesStyleKit.drawLaneSlightRightNotRight(frame: bounds, resizing: resizing,
                                                          primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                          flipHorizontally: side == .left)
            } else if isValid && !slightTurn && turn {
                LanesStyleKit.drawLaneRightNotSlightRight(frame: bounds, resizing: resizing,
                                                          primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                          flipHorizontally: side == .left)
            } else {
                // No dedicated asset for an unhighlighted dual use lane, so use the unhighlighted color as both primary and secondary colors.
                LanesStyleKit.drawLaneSlightRightNotRight(frame: bounds, resizing: resizing,
                                                          primaryColor: appropriateColor, secondaryColor: appropriateColor,
                                                          flipHorizontally: side == .left)
            }
        case .slightTurnOrSharpTurn(side: let side, slightTurn: let slightTurn, sharpTurn: let sharpTurn):
            if isValid && slightTurn && !sharpTurn {
                LanesStyleKit.drawLaneSlightRightNotSharpRight(frame: bounds, resizing: resizing,
                                                               primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                               flipHorizontally: side == .left)
            } else if isValid && !slightTurn && sharpTurn {
                LanesStyleKit.drawLaneSharpRightNotSlightRight(frame: bounds, resizing: resizing,
                                                               primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                               flipHorizontally: side == .left)
            } else {
                // No dedicated asset for an unhighlighted dual use lane, so use the unhighlighted color as both primary and secondary colors.
                LanesStyleKit.drawLaneSlightRightNotSharpRight(frame: bounds, resizing: resizing,
                                                               primaryColor: appropriateColor, secondaryColor: appropriateColor,
                                                               flipHorizontally: side == .left)
            }
        case .slightTurnOrUTurn(side: let side, slightTurn: let slightTurn, uTurn: let uTurn):
            if isValid && slightTurn && !uTurn {
                LanesStyleKit.drawLaneSlightRightNotUturn(frame: bounds, resizing: resizing,
                                                          primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                          flipHorizontally: side == .left)
            } else if isValid && !slightTurn && uTurn {
                LanesStyleKit.drawLaneUturnNotSlightRight(frame: bounds, resizing: resizing,
                                                          primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                          flipHorizontally: side == .left)
            } else {
                // No dedicated asset for an unhighlighted dual use lane, so use the unhighlighted color as both primary and secondary colors.
                LanesStyleKit.drawLaneSlightRightNotUturn(frame: bounds, resizing: resizing,
                                                          primaryColor: appropriateColor, secondaryColor: appropriateColor,
                                                          flipHorizontally: side == .left)
            }
        case .turnOrSharpTurn(side: let side, turn: let turn, sharpTurn: let sharpTurn):
            if isValid && turn && !sharpTurn {
                LanesStyleKit.drawLaneRightNotSharpRight(frame: bounds, resizing: resizing,
                                                         primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                         flipHorizontally: side == .left)
            } else if isValid && !turn && sharpTurn {
                LanesStyleKit.drawLaneRightNotSlightRight(frame: bounds, resizing: resizing,
                                                          primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                          flipHorizontally: side == .left)
            } else {
                // No dedicated asset for an unhighlighted dual use lane, so use the unhighlighted color as both primary and secondary colors.
                LanesStyleKit.drawLaneRightNotSharpRight(frame: bounds, resizing: resizing,
                                                         primaryColor: appropriateColor, secondaryColor: appropriateColor,
                                                         flipHorizontally: side == .left)
            }
        case .turnOrUTurn(side: let side, turn: let turn, uTurn: let uTurn):
            if isValid && turn && !uTurn {
                LanesStyleKit.drawLaneRightNotUturn(frame: bounds, resizing: resizing,
                                                    primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                    flipHorizontally: side == .left)
            } else if isValid && !turn && uTurn {
                LanesStyleKit.drawLaneUturnNotRight(frame: bounds, resizing: resizing,
                                                    primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                    flipHorizontally: side == .left)
            } else {
                // No dedicated asset for an unhighlighted dual use lane, so use the unhighlighted color as both primary and secondary colors.
                LanesStyleKit.drawLaneRightNotUturn(frame: bounds, resizing: resizing,
                                                    primaryColor: appropriateColor, secondaryColor: appropriateColor,
                                                    flipHorizontally: side == .left)
            }
        case .turnOrOppositeTurn(side: let side):
            LanesStyleKit.drawLaneRightNotLeft(frame: bounds, resizing: resizing, primaryColor: appropriateColor, secondaryColor: appropriateSecondaryColor, flipHorizontally: side == .left)
        case .straightOrTurnOrOppositeTurn(side: let side, straight: let straight, turn: let turn):
            if isValid && straight && !turn {
                LanesStyleKit.drawLaneStraightNotLeftOrRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor, flipHorizontally: side == .left)
            } else if isValid && !straight && turn {
                LanesStyleKit.drawLaneRightNotLeftOrStraight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor, flipHorizontally: side == .left)
            } else {
                // No dedicated asset for an unhighlighted triple use lane, so use the unhighlighted color as both primary and secondary colors.
                LanesStyleKit.drawLaneStraightNotLeftOrRight(frame: bounds, resizing: resizing, primaryColor: appropriateColor, secondaryColor: appropriateColor, flipHorizontally: side == .left)
            }
        case .straightOrTurnOrUTurn(side: let side, straight: let straight, turn: let turn, uTurn: let uTurn):
            if isValid && straight && !turn && !uTurn {
                LanesStyleKit.drawLaneStraightNotRightOrUturn(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor, flipHorizontally: side == .left)
            } else if isValid && !straight && turn && !uTurn {
                LanesStyleKit.drawLaneRightNotStraightOrUturn(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor, flipHorizontally: side == .left)
            } else if isValid && !straight && !turn && uTurn {
                LanesStyleKit.drawLaneUturnNotStraightOrRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor, flipHorizontally: side == .left)
            } else {
                // No dedicated asset for an unhighlighted triple use lane, so use the unhighlighted color as both primary and secondary colors.
                LanesStyleKit.drawLaneStraightNotRightOrUturn(frame: bounds, resizing: resizing, primaryColor: appropriateColor, secondaryColor: appropriateColor, flipHorizontally: side == .left)
            }
        }
    }
}
