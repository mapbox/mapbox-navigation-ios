import UIKit
import MapboxDirections

/**
 A workaround for the fact that `LaneIndication` is an `OptionSet` and thus cannot be exhaustively switched on.
 */
enum SingularLaneIndication: Equatable {
    case sharpRight
    case right
    case slightRight
    case straightAhead
    case slightLeft
    case left
    case sharpLeft
    case uTurn
    
    /// Converts the maneuver direction to a lane indication.
    init?(_ maneuverDirection: ManeuverDirection) {
        switch maneuverDirection {
        case .sharpRight:
            self = .sharpRight
        case .right:
            self = .right
        case .slightRight:
            self = .slightRight
        case .straightAhead:
            self = .straightAhead
        case .slightLeft:
            self = .slightLeft
        case .left:
            self = .left
        case .sharpLeft:
            self = .sharpLeft
        case .uTurn:
            self = .uTurn
        }
    }
}

/**
 The classification of a maneuver direction relative to a dominant side.
 */
enum TurnClassification: Equatable {
    case oppositeUTurn
    case oppositeSharpTurn
    case oppositeTurn
    case oppositeSlightTurn
    case straightAhead
    case slightTurn
    case turn
    case sharpTurn
    case uTurn
    
    /**
     Classifies the given lane indication relative to the dominant side.
     */
    init(laneIndication: SingularLaneIndication, dominantSide: DrivingSide, drivingSide: DrivingSide) {
        switch (laneIndication, dominantSide, drivingSide) {
        case (.straightAhead, _, _):
            self = .straightAhead
        case (.slightLeft, .left, _),
             (.slightRight, .right, _):
            self = .slightTurn
        case (.slightLeft, .right, _),
             (.slightRight, .left, _):
            self = .oppositeSlightTurn
        case (.left, .left, _),
             (.right, .right, _):
            self = .turn
        case (.left, .right, _),
             (.right, .left, _):
            self = .oppositeTurn
        case (.sharpLeft, .left, _),
             (.sharpRight, .right, _):
            self = .sharpTurn
        case (.sharpLeft, .right, _),
             (.sharpRight, .left, _):
            self = .oppositeSharpTurn
        case (.uTurn, .left, .right),
             (.uTurn, .right, .left):
            self = .uTurn
        case (.uTurn, .right, .right),
             (.uTurn, .left, .left):
            self = .oppositeUTurn
        }
    }
}

extension LaneIndication {
    /// The component lane indications in a fixed order.
    var singularLaneIndications: [SingularLaneIndication] {
        return [
            contains(.sharpLeft) ? .sharpLeft : nil,
            contains(.left) ? .left : nil,
            contains(.slightLeft) ? .slightLeft : nil,
            contains(.straightAhead) ? .straightAhead : nil,
            contains(.slightRight) ? .slightRight : nil,
            contains(.right) ? .right : nil,
            contains(.sharpRight) ? .sharpRight : nil,
            contains(.uTurn) ? .uTurn : nil,
        ].compactMap { $0 }
    }
    
    /// The side of the road that the user would maneuver toward.
    func dominantSide(maneuverDirection: ManeuverDirection?, drivingSide: DrivingSide) -> DrivingSide {
        let hasLeftwardIndication = !isDisjoint(with: .lefts) || (contains(.uTurn) && drivingSide == .right)
        let hasRightwardIndication = !isDisjoint(with: .rights) || (contains(.uTurn) && drivingSide == .left)
        if let maneuverDirection = maneuverDirection, hasLeftwardIndication && hasRightwardIndication {
            let hasLeftwardManeuver = maneuverDirection.isLeft || (maneuverDirection == .uTurn && drivingSide == .right)
            return hasLeftwardManeuver ? .left : .right
        }
        return hasLeftwardIndication ? .left : .right
    }
}

extension LanesStyleKit {
    /**
     A generic classification of this class’s drawing methods by argument list.
     
     Asymmetric methods have a Boolean parameter to control horizontal flipping. Mixed methods have an extra parameter for the secondary color.
     */
    enum Method {
        case symmetricOff((CGRect, LanesStyleKit.ResizingBehavior, UIColor, CGSize) -> Void)
        case symmetricOn((CGRect, LanesStyleKit.ResizingBehavior, UIColor, CGSize) -> Void)
        case asymmetricOff((CGRect, LanesStyleKit.ResizingBehavior, UIColor, CGSize, Bool) -> Void)
        case asymmetricMixed((CGRect, LanesStyleKit.ResizingBehavior, UIColor, UIColor, CGSize, Bool) -> Void)
        case asymmetricOn((CGRect, LanesStyleKit.ResizingBehavior, UIColor, CGSize, Bool) -> Void)
    }
    
    /**
     Returns the method that draws the given lane configuration.
     
     - parameter lane: The lane configuration to draw.
     - parameter maneuverDirection: The direction that the user is expected to maneuver toward when using this lane.
     - parameter drivingSide: The side of the road that the user drives on.
     - returns: A `LanesStyleKit` method that draws the lane configuration.
     */
    static func styleKitMethod(lane: LaneIndication, maneuverDirection: ManeuverDirection?, drivingSide: DrivingSide) -> LanesStyleKit.Method {
        // https://github.com/mapbox/navigation-ui-resources/blob/4a287b92ddeeec502bca9da849e505dcdf73e1ef/docs/lanes.md
        let favoredIndication = maneuverDirection.flatMap { SingularLaneIndication($0) }
        var laneIndications = lane.singularLaneIndications
        if laneIndications.count > 3 {
            laneIndications = Array(laneIndications.prefix(3))
            if let favoredIndication = favoredIndication, !laneIndications.contains(favoredIndication) {
                laneIndications = laneIndications.dropLast() + [favoredIndication]
            }
        }
        let dominantSide = lane.dominantSide(maneuverDirection: maneuverDirection, drivingSide: drivingSide)
        let turnClassifications = Set(laneIndications.map {
            TurnClassification(laneIndication: $0, dominantSide: dominantSide, drivingSide: drivingSide)
        })
        let favoredTurnClassification = favoredIndication.map {
            TurnClassification(laneIndication: $0, dominantSide: dominantSide, drivingSide: drivingSide)
        }
        guard let method = styleKitMethod(turnClassifications: turnClassifications, favoredTurnClassification: favoredTurnClassification) ??
                favoredTurnClassification.flatMap({ styleKitMethod(turnClassifications: [$0], favoredTurnClassification: $0) }) ??
                styleKitMethod(turnClassifications: [.straightAhead], favoredTurnClassification: nil) else {
            preconditionFailure("No StyleKit method for straight ahead.")
        }
        return method
    }
    
    /**
     Returns the method that draws the given set of turn classifications, potentially highlighting the favored turn classification.
     
     - parameter turnClassifications: The turn classifications to draw.
     - parameter favoredTurnClassifications: The turn classification to highlight if possible.
     - returns: A `LanesStyleKit` method that draws the turn classifications.
     */
    static func styleKitMethod(turnClassifications: Set<TurnClassification>, favoredTurnClassification: TurnClassification?) -> LanesStyleKit.Method? {
        switch (turnClassifications, favoredTurnClassification) {
        // Single use
        case ([.straightAhead], .straightAhead):
            return .symmetricOn(drawLaneStraightUsingStraight)
        case ([.straightAhead], _):
            return .symmetricOff(drawLaneStraight)
        case ([.slightTurn], .slightTurn):
            return .asymmetricOn(drawLaneSlightTurnUsingSlightTurn)
        case ([.slightTurn], _):
            return .asymmetricOff(drawLaneSlightTurn)
        case ([.turn], .turn):
            return .asymmetricOn(drawLaneTurnUsingTurn)
        case ([.turn], _):
            return .asymmetricOff(drawLaneTurn)
        case ([.sharpTurn], .sharpTurn):
            return .asymmetricOn(drawLaneSharpTurnUsingSharpTurn)
        case ([.sharpTurn], _):
            return .asymmetricOff(drawLaneSharpTurn)
        case ([.uTurn], .uTurn):
            return .asymmetricOn(drawLaneUturnUsingUturn)
        case ([.uTurn], _):
            return .asymmetricOff(drawLaneUturn)

        // Dual use allowing straight ahead
        case ([.straightAhead, .slightTurn], .straightAhead):
            return .asymmetricMixed(drawLaneStraightOrSlightTurnUsingStraight)
        case ([.straightAhead, .slightTurn], .slightTurn):
            return .asymmetricMixed(drawLaneStraightOrSlightTurnUsingSlightTurn)
        case ([.straightAhead, .slightTurn], _):
            return .asymmetricOff(drawLaneStraightOrSlightTurn)
        case ([.straightAhead, .turn], .straightAhead):
            return .asymmetricMixed(drawLaneStraightOrTurnUsingStraight)
        case ([.straightAhead, .turn], .turn):
            return .asymmetricMixed(drawLaneStraightOrTurnUsingTurn)
        case ([.straightAhead, .turn], _):
            return .asymmetricOff(drawLaneStraightOrTurn)
        case ([.straightAhead, .sharpTurn], .straightAhead):
            return .asymmetricMixed(drawLaneStraightOrSharpTurnUsingStraight)
        case ([.straightAhead, .sharpTurn], .sharpTurn):
            return .asymmetricMixed(drawLaneStraightOrSharpTurnUsingSharpTurn)
        case ([.straightAhead, .sharpTurn], _):
            return .asymmetricOff(drawLaneStraightOrSharpTurn)
        case ([.straightAhead, .uTurn], .straightAhead):
            return .asymmetricMixed(drawLaneStraightOrUturnUsingStraight)
        case ([.straightAhead, .uTurn], .uTurn):
            return .asymmetricMixed(drawLaneStraightOrUturnUsingUturn)
        case ([.straightAhead, .uTurn], _):
            return .asymmetricOff(drawLaneStraightOrUturn)

        // Dual use allowing slight turn
        case ([.slightTurn, .turn], .slightTurn):
            return .asymmetricMixed(drawLaneSlightTurnOrTurnUsingSlightTurn)
        case ([.slightTurn, .turn], .turn):
            return .asymmetricMixed(drawLaneSlightTurnOrTurnUsingTurn)
        case ([.slightTurn, .turn], _):
            return .asymmetricOff(drawLaneSlightTurnOrTurn)
        case ([.slightTurn, .sharpTurn], .slightTurn):
            return .asymmetricMixed(drawLaneSlightTurnOrSharpTurnUsingSlightTurn)
        case ([.slightTurn, .sharpTurn], .sharpTurn):
            return .asymmetricMixed(drawLaneSlightTurnOrSharpTurnUsingSharpTurn)
        case ([.slightTurn, .sharpTurn], _):
            return .asymmetricOff(drawLaneSlightTurnOrSharpTurn)
        case ([.slightTurn, .uTurn], .slightTurn):
            return .asymmetricMixed(drawLaneSlightTurnOrUturnUsingSlightTurn)
        case ([.slightTurn, .uTurn], .uTurn):
            return .asymmetricMixed(drawLaneSlightTurnOrUturnUsingUturn)
        case ([.slightTurn, .uTurn], _):
            return .asymmetricOff(drawLaneSlightTurnOrUturn)

        // Dual use allowing turn
        case ([.turn, .sharpTurn], .turn):
            return .asymmetricMixed(drawLaneTurnOrSharpTurnUsingTurn)
        case ([.turn, .sharpTurn], .sharpTurn):
            return .asymmetricMixed(drawLaneTurnOrSharpTurnUsingSharpTurn)
        case ([.turn, .sharpTurn], _):
            return .asymmetricOff(drawLaneTurnOrSharpTurn)
        case ([.turn, .uTurn], .turn):
            return .asymmetricMixed(drawLaneTurnOrUturnUsingTurn)
        case ([.turn, .uTurn], .uTurn):
            return .asymmetricMixed(drawLaneTurnOrUturnUsingUturn)
        case ([.turn, .uTurn], _):
            return .asymmetricOff(drawLaneTurnOrUturn)

        // Dual use bilateral, asymmetric
        case ([.oppositeTurn, .slightTurn], .slightTurn):
            return .asymmetricMixed(drawLaneOppositeTurnOrSlightTurnUsingSlightTurn)
        case ([.oppositeTurn, .slightTurn], _):
            return .asymmetricOff(drawLaneOppositeTurnOrSlightTurn)
        case ([.oppositeSlightTurn, .turn], .turn):
            return .asymmetricMixed(drawLaneOppositeSlightTurnOrTurnUsingTurn)
        case ([.oppositeSlightTurn, .turn], _):
            return .asymmetricOff(drawLaneOppositeSlightTurnOrTurn)

        // Dual use bilateral, symmetric
        case ([.oppositeSlightTurn, .slightTurn], .slightTurn):
            return .asymmetricMixed(drawLaneOppositeSlightTurnOrSlightTurnUsingSlightTurn)
        case ([.oppositeSlightTurn, .slightTurn], _):
            return .asymmetricOff(drawLaneOppositeSlightTurnOrSlightTurn)
        case ([.oppositeTurn, .turn], .turn):
            return .asymmetricMixed(drawLaneOppositeTurnOrTurnUsingTurn)
        case ([.oppositeTurn, .turn], _):
            return .asymmetricOff(drawLaneOppositeTurnOrTurn)

        // Triple use unilateral
        case ([.straightAhead, .slightTurn, .turn], .straightAhead):
            return .asymmetricMixed(drawLaneStraightOrSlightTurnOrTurnUsingStraight)
        case ([.straightAhead, .slightTurn, .turn], .slightTurn):
            return .asymmetricMixed(drawLaneStraightOrSlightTurnOrTurnUsingSlightTurn)
        case ([.straightAhead, .slightTurn, .turn], .turn):
            return .asymmetricMixed(drawLaneStraightOrSlightTurnOrTurnUsingTurn)
        case ([.straightAhead, .slightTurn, .turn], _):
            return .asymmetricOff(drawLaneStraightOrSlightTurnOrTurn)
        case ([.straightAhead, .turn, .uTurn], .straightAhead):
            return .asymmetricMixed(drawLaneStraightOrTurnOrUturnUsingStraight)
        case ([.straightAhead, .turn, .uTurn], .turn):
            return .asymmetricMixed(drawLaneStraightOrTurnOrUturnUsingTurn)
        case ([.straightAhead, .turn, .uTurn], .uTurn):
            return .asymmetricMixed(drawLaneStraightOrTurnOrUturnUsingUturn)
        case ([.straightAhead, .turn, .uTurn], _):
            return .asymmetricOff(drawLaneStraightOrTurnOrUturn)

        // Triple use bilateral, asymmetric
        case ([.oppositeTurn, .straightAhead, .slightTurn], .straightAhead):
            return .asymmetricMixed(drawLaneOppositeTurnOrStraightOrSlightTurnUsingStraight)
        case ([.oppositeTurn, .straightAhead, .slightTurn], .slightTurn):
            return .asymmetricMixed(drawLaneOppositeTurnOrStraightOrSlightTurnUsingSlightTurn)
        case ([.oppositeTurn, .straightAhead, .slightTurn], _):
            return .asymmetricOff(drawLaneOppositeTurnOrStraightOrSlightTurn)
        case ([.oppositeSlightTurn, .straightAhead, .turn], .straightAhead):
            return .asymmetricMixed(drawLaneOppositeSlightTurnOrStraightOrTurnUsingStraight)
        case ([.oppositeSlightTurn, .straightAhead, .turn], .turn):
            return .asymmetricMixed(drawLaneOppositeSlightTurnOrStraightOrTurnUsingTurn)
        case ([.oppositeSlightTurn, .straightAhead, .turn], _):
            return .asymmetricOff(drawLaneOppositeSlightTurnOrStraightOrTurn)

        // Triple use bilateral, symmetric
        case ([.oppositeSlightTurn, .straightAhead, .slightTurn], .straightAhead):
            return .asymmetricMixed(drawLaneOppositeSlightTurnOrStraightOrSlightTurnUsingStraight)
        case ([.oppositeSlightTurn, .straightAhead, .slightTurn], .slightTurn):
            return .asymmetricMixed(drawLaneOppositeSlightTurnOrStraightOrSlightTurnUsingSlightTurn)
        case ([.oppositeSlightTurn, .straightAhead, .slightTurn], _):
            return .asymmetricOff(drawLaneOppositeSlightTurnOrStraightOrSlightTurn)
        case ([.oppositeTurn, .straightAhead, .turn], .straightAhead):
            return .asymmetricMixed(drawLaneOppositeTurnOrStraightOrTurnUsingStraight)
        case ([.oppositeTurn, .straightAhead, .turn], .turn):
            return .asymmetricMixed(drawLaneOppositeTurnOrStraightOrTurnUsingTurn)
        case ([.oppositeTurn, .straightAhead, .turn], _):
            return .asymmetricOff(drawLaneOppositeTurnOrStraightOrTurn)

        case (_, _):
            return nil
        }
    }
}

extension LaneIndication {
    static let lefts: LaneIndication = [.sharpLeft, .left, .slightLeft]
    static let rights: LaneIndication = [.sharpRight, .right, .slightRight]
}

extension ManeuverDirection {
    var isLeft: Bool {
        return self == .sharpLeft || self == .left || self == .slightLeft
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
        let size = CGSize(width: 32, height: 32)
        
        let isFlipped = indications.dominantSide(maneuverDirection: maneuverDirection, drivingSide: drivingSide) == .left
        let styleKitMethod = LanesStyleKit.styleKitMethod(lane: indications, maneuverDirection: maneuverDirection, drivingSide: drivingSide)
        
        switch styleKitMethod {
        case let .symmetricOff(method):
            method(bounds, resizing, appropriateColor, size)
        case let .symmetricOn(method):
            method(bounds, resizing, appropriateColor, size)
        case let .asymmetricOff(method):
            method(bounds, resizing, appropriateSecondaryColor, size, isFlipped)
        case let .asymmetricMixed(method):
            method(bounds, resizing, appropriatePrimaryColor, appropriateSecondaryColor, size, isFlipped)
        case let .asymmetricOn(method):
            method(bounds, resizing, appropriatePrimaryColor, size, isFlipped)
        }
    }
}
