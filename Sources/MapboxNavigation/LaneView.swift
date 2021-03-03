import UIKit
import MapboxDirections

extension LaneIndication {
    static let lefts: LaneIndication = [.sharpLeft, .left, .slightLeft]
    static let rights: LaneIndication = [.sharpRight, .right, .slightRight]
    
    struct Ranking: Equatable {
        let primary: LaneIndication
        let secondary: LaneIndication?
    }
    
    /**
     Separates the indication into primary and secondary indications with a bias toward the given maneuver direction.
     
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
        } else if (indications.contains(.left) && maneuverDirection?.isLeft ?? true) ||
                    // No assets for sharp turns; treat them as normal turns.
                    (indications.contains(.sharpLeft) && maneuverDirection ?? .sharpLeft == .sharpLeft) {
            primaryIndication = .left
        } else if (indications.contains(.right) && maneuverDirection?.isRight ?? true) ||
                    // No assets for sharp turns; treat them as normal turns.
                    (indications.contains(.sharpRight) && maneuverDirection ?? .sharpRight == .sharpRight) {
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
            } else if !indications.isDisjoint(with: .lefts) {
                primaryIndication = .left
            } else if !indications.isDisjoint(with: .rights) {
                primaryIndication = .right
            } else if indications.contains(.uTurn) {
                primaryIndication = .uTurn
            } else {
                // No indications to draw.
                return Ranking(primary: [], secondary: nil)
            }
        }
        
        indications.remove(primaryIndication)
        
        // Some dual-use configurations are supported.
        let secondaryIndication: LaneIndication?
        if !primaryIndication.isSubset(of: [.straightAhead, .uTurn]) && indications.contains(.straightAhead) {
            secondaryIndication = .straightAhead
            
            // No asset for dual-use slight turn, so use normal turn instead.
            if primaryIndication == .slightLeft {
                primaryIndication = .left
            } else if primaryIndication == .slightRight {
                primaryIndication = .right
            }
        } else if primaryIndication == .straightAhead && !indications.isDisjoint(with: .lefts) {
            secondaryIndication = .left
        } else if primaryIndication == .straightAhead && !indications.isDisjoint(with: .rights) {
            secondaryIndication = .right
        } else {
            secondaryIndication = nil
        }
        
        return Ranking(primary: primaryIndication, secondary: secondaryIndication)
    }
}

/**
 A generalized representation of the drawing methods available in LanesStyleKit.
 */
enum LaneConfiguration: Equatable {
    case straightOnly
    case slightTurnOnly(side: DrivingSide)
    case turnOnly(side: DrivingSide)
    case uTurnOnly(side: DrivingSide)
    
    case straightOrTurn(side: DrivingSide, straight: Bool, turn: Bool)
    
    init?(rankedIndications: LaneIndication.Ranking, drivingSide: DrivingSide) {
        switch (rankedIndications.primary, rankedIndications.secondary) {
        // Single-use lanes
        case (.straightAhead, .none):
            self = .straightOnly
        case (.slightLeft, .none):
            self = .slightTurnOnly(side: .left)
        case (.slightRight, .none):
            self = .slightTurnOnly(side: .right)
        case (.left, .none):
            self = .turnOnly(side: .left)
        case (.right, .none):
            self = .turnOnly(side: .right)
        case (.uTurn, .none):
            // When you drive on the right, you U-turn to the left and vice versa.
            self = .uTurnOnly(side: drivingSide == .right ? .left : .right)
        
        // Dual-use lanes
        case (.straightAhead, .some(.left)):
            self = .straightOrTurn(side: .left, straight: true, turn: false)
        case (.straightAhead, .some(.right)):
            self = .straightOrTurn(side: .right, straight: true, turn: false)
        case (.left, .some(.straightAhead)):
            self = .straightOrTurn(side: .left, straight: false, turn: true)
        case (.right, .some(.straightAhead)):
            self = .straightOrTurn(side: .right, straight: false, turn: true)
            
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
        case .straightOnly:
            LanesStyleKit.drawLaneStraight(frame: bounds, resizing: resizing, primaryColor: appropriateColor)
        case .slightTurnOnly(side: let side):
            LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriateColor,
                                              flipHorizontally: side == .left)
        case .turnOnly(side: let side):
            LanesStyleKit.drawLaneRight(frame: bounds, resizing: resizing, primaryColor: appropriateColor,
                                        flipHorizontally: side == .left)
        case .uTurnOnly(side: let side):
            LanesStyleKit.drawLaneUturn(frame: bounds, resizing: resizing, primaryColor: appropriateColor,
                                        flipHorizontally: side == .left)
        case .straightOrTurn(side: let side, straight: let straight, turn: let turn):
            if isValid && straight && !turn {
                LanesStyleKit.drawLaneStraightOnly(frame: bounds, resizing: resizing,
                                                   primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                   flipHorizontally: side == .left)
            } else if isValid && !straight && turn {
                LanesStyleKit.drawLaneRightOnly(frame: bounds, resizing: resizing,
                                                primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor,
                                                flipHorizontally: side == .left)
            } else {
                LanesStyleKit.drawLaneStraightRight(frame: bounds, resizing: resizing, primaryColor: appropriateColor,
                                                    flipHorizontally: side == .left)
            }
        }
    }
}
