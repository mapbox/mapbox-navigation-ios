import UIKit
import MapboxDirections

/// :nodoc:
open class LaneView: UIView {

    var indications: LaneIndication? {
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
        super.init(frame: frame)
        commonInit()
    }

    @objc public required init?(coder aDecoder: NSCoder) {
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
        
        let resizing: LanesStyleKit.ResizingBehavior = .aspectFit
        
        if let indications = indications {
            if indications.isSuperset(of: [.straightAhead, .sharpRight]) || indications.isSuperset(of: [.straightAhead, .right]) || indications.isSuperset(of: [.straightAhead, .slightRight]) {
                if !isValid {
                    if indications == .slightRight {
                        LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriateSecondaryColor)
                    } else {
                        LanesStyleKit.drawLaneStraightRight(frame: bounds, resizing: resizing, primaryColor: appropriateSecondaryColor)
                    }
                } else if maneuverDirection == .straightAhead {
                    LanesStyleKit.drawLaneStraightOnly(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor)
                } else if maneuverDirection == .sharpLeft || maneuverDirection == .left || maneuverDirection == .slightLeft {
                    if indications == .slightLeft {
                        LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, flipHorizontally: true)
                    } else {
                        LanesStyleKit.drawLaneRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, flipHorizontally: true)
                    }
                } else {
                    // pick the color of the two parts (straight & turn) depending on which direction is being suggested
                    let turnArrowColor = (self.maneuverDirection != ManeuverDirection.straightAhead) ? appropriatePrimaryColor : appropriateSecondaryColor
                    let straightArrowColor = (self.maneuverDirection == ManeuverDirection.straightAhead) ? appropriatePrimaryColor : appropriateSecondaryColor
                    LanesStyleKit.drawLaneRightOnly(frame: bounds, resizing: resizing, turnArrowColor: turnArrowColor, straightArrowColor: straightArrowColor)
                }
            } else if indications.isSuperset(of: [.straightAhead, .sharpLeft]) || indications.isSuperset(of: [.straightAhead, .left]) || indications.isSuperset(of: [.straightAhead, .slightLeft]) {
                if !isValid {
                    if indications == .slightLeft {
                        LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriateSecondaryColor, flipHorizontally: true)
                    } else {
                        LanesStyleKit.drawLaneStraightRight(frame: bounds, resizing: resizing, primaryColor: appropriateSecondaryColor, flipHorizontally: true)
                    }
                } else if maneuverDirection == .straightAhead {
                    LanesStyleKit.drawLaneStraightOnly(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, secondaryColor: appropriateSecondaryColor, flipHorizontally: true)
                } else if maneuverDirection == .sharpRight || maneuverDirection == .right {
                    LanesStyleKit.drawLaneRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
                } else if maneuverDirection == .slightRight {
                    LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
                } else {
                    // pick the color of the two parts (straight & turn) depending on which direction is being suggested
                    let turnArrowColor = (self.maneuverDirection != ManeuverDirection.straightAhead) ? appropriatePrimaryColor : appropriateSecondaryColor
                    let straightArrowColor = (self.maneuverDirection == ManeuverDirection.straightAhead) ? appropriatePrimaryColor : appropriateSecondaryColor
                    LanesStyleKit.drawLaneRightOnly(frame: bounds, resizing: resizing, turnArrowColor: turnArrowColor, straightArrowColor: straightArrowColor, flipHorizontally: true)
                }
            } else if indications.description.components(separatedBy: ",").count >= 2 {
                // Hack:
                // Account for a configuation where there is no straight lane
                // but there are at least 2 indications.
                // In this situation, just draw a left/right arrow
                if maneuverDirection == .sharpRight || maneuverDirection == .right {
                    LanesStyleKit.drawLaneRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
                } else if maneuverDirection == .slightRight {
                    LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
                } else {
                    LanesStyleKit.drawLaneRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, flipHorizontally: true)
                }
            } else if indications.isSuperset(of: [.sharpRight]) || indications.isSuperset(of: [.right]) || indications.isSuperset(of: [.slightRight]) {
                if indications == .slightRight {
                    LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
                } else {
                    LanesStyleKit.drawLaneRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
                }
            } else if indications.isSuperset(of: [.sharpLeft]) || indications.isSuperset(of: [.left]) || indications.isSuperset(of: [.slightLeft]) {
                if indications == .slightLeft {
                    LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, flipHorizontally: true)
                } else {
                    LanesStyleKit.drawLaneRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, flipHorizontally: true)
                }
            } else if indications.isSuperset(of: [.straightAhead]) {
                LanesStyleKit.drawLaneStraight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
            } else if indications.isSuperset(of: [.uTurn]) {
                let flip = !(drivingSide == .left)
                LanesStyleKit.drawLaneUturn(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, flipHorizontally: flip)
            } else if indications.isEmpty && isValid {
                // If the lane indication is `none` and the maneuver modifier has a turn in it,
                // show the turn in the lane image.
                if maneuverDirection == .sharpRight || maneuverDirection == .right || maneuverDirection == .slightRight {
                    if maneuverDirection == .slightRight {
                        LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
                    } else {
                        LanesStyleKit.drawLaneRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
                    }
                } else if maneuverDirection == .sharpLeft || maneuverDirection == .left || maneuverDirection == .slightLeft {
                    if maneuverDirection == .slightLeft {
                        LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, flipHorizontally: true)
                    } else {
                        LanesStyleKit.drawLaneRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, flipHorizontally: true)
                    }
                } else {
                    LanesStyleKit.drawLaneStraight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
                }
            } else {
                LanesStyleKit.drawLaneStraight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
            }
        }
        
        #if TARGET_INTERFACE_BUILDER
        isValid = true
        LanesStyleKit.drawLaneRightOnly(turnArrowColor: appropriatePrimaryColor, straightArrowColor: appropriateSecondaryColor)
        #endif
    }
}
