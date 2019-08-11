import UIKit
import MapboxDirections

/// :nodoc:
@objc(MBLaneView)
open class LaneView: UIView {
    
    let invalidAlpha: CGFloat = 0.4
    
    var lane: Lane? {
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
    
    var appropriatePrimaryColor: UIColor {
        return isValid ? primaryColor : secondaryColor
    }
    
    static let defaultFrame: CGRect = CGRect(origin: .zero, size: 30.0)
    
    convenience init(component: LaneIndicationComponent) {
        self.init(frame: LaneView.defaultFrame)
        backgroundColor = .clear
        lane = Lane(indications: component.indications)
        maneuverDirection = ManeuverDirection(description: component.indications.description)
        isValid = component.isUsable
    }
    
    override open func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let resizing: LanesStyleKit.ResizingBehavior = .aspectFit
        
        if let lane = lane {
            if lane.indications.isSuperset(of: [.straightAhead, .sharpRight]) || lane.indications.isSuperset(of: [.straightAhead, .right]) || lane.indications.isSuperset(of: [.straightAhead, .slightRight]) {
                
                if !isValid {
                    if lane.indications == .slightRight {
                        LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
                    } else {
                        LanesStyleKit.drawLaneStraightRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
                    }
                    alpha = invalidAlpha
                } else if maneuverDirection == .straightAhead {
                    LanesStyleKit.drawLaneStraightOnly(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, secondaryColor: secondaryColor)
                } else if maneuverDirection == .sharpLeft || maneuverDirection == .left || maneuverDirection == .slightLeft {
                    if lane.indications == .slightLeft {
                        LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, flipHorizontally: true)
                    } else {
                        LanesStyleKit.drawLaneRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, flipHorizontally: true)
                    }
                } else {
                    LanesStyleKit.drawLaneRightOnly(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, secondaryColor: secondaryColor)
                }
            } else if lane.indications.isSuperset(of: [.straightAhead, .sharpLeft]) || lane.indications.isSuperset(of: [.straightAhead, .left]) || lane.indications.isSuperset(of: [.straightAhead, .slightLeft]) {
                if !isValid {
                    if lane.indications == .slightLeft {
                        LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, flipHorizontally: true)
                    } else {
                        LanesStyleKit.drawLaneStraightRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, flipHorizontally: true)
                    }
                    
                    alpha = invalidAlpha
                } else if maneuverDirection == .straightAhead {
                    LanesStyleKit.drawLaneStraightOnly(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, secondaryColor: secondaryColor, flipHorizontally: true)
                } else if maneuverDirection == .sharpRight || maneuverDirection == .right {
                    LanesStyleKit.drawLaneRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
                } else if maneuverDirection == .slightRight {
                    LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
                } else {
                    LanesStyleKit.drawLaneRightOnly(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, secondaryColor: secondaryColor, flipHorizontally: true)
                }
            } else if lane.indications.description.components(separatedBy: ",").count >= 2 {
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
                alpha = isValid ? 1 : invalidAlpha
            } else if lane.indications.isSuperset(of: [.sharpRight]) || lane.indications.isSuperset(of: [.right]) || lane.indications.isSuperset(of: [.slightRight]) {
                if lane.indications == .slightRight {
                    LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
                } else {
                    LanesStyleKit.drawLaneRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
                }
                alpha = isValid ? 1 : invalidAlpha
            } else if lane.indications.isSuperset(of: [.sharpLeft]) || lane.indications.isSuperset(of: [.left]) || lane.indications.isSuperset(of: [.slightLeft]) {
                if lane.indications == .slightLeft {
                    LanesStyleKit.drawLaneSlightRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, flipHorizontally: true)
                } else {
                    LanesStyleKit.drawLaneRight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, flipHorizontally: true)
                }
                alpha = isValid ? 1 : invalidAlpha
            } else if lane.indications.isSuperset(of: [.straightAhead]) {
                LanesStyleKit.drawLaneStraight(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor)
                alpha = isValid ? 1 : invalidAlpha
            } else if lane.indications.isSuperset(of: [.uTurn]) {
                let flip = !(drivingSide == .left)
                LanesStyleKit.drawLaneUturn(frame: bounds, resizing: resizing, primaryColor: appropriatePrimaryColor, flipHorizontally: flip)
                alpha = isValid ? 1 : invalidAlpha
            } else if lane.indications.isEmpty && isValid {
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
                alpha = isValid ? 1 : invalidAlpha
            }
        }
        
        #if TARGET_INTERFACE_BUILDER
            isValid = true
            LanesStyleKit.drawLaneRightOnly(primaryColor: appropriatePrimaryColor, secondaryColor: secondaryColor)
        #endif
    }
}
