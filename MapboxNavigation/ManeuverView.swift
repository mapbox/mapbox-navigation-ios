import UIKit
import MapboxDirections
import MapboxCoreNavigation
import SDWebImage
import Turf

/// :nodoc:
@IBDesignable
@objc(MBManeuverView)
public class ManeuverView: UIView {
    
    @objc public dynamic var primaryColor: UIColor = .defaultTurnArrowPrimary {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @objc public dynamic var secondaryColor: UIColor = .defaultTurnArrowSecondary {
        didSet {
            setNeedsDisplay()
        }
    }

    public var maneuverTypeModifier: (maneuverType: ManeuverType?, maneuverDirection: ManeuverDirection?) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @objc public var isStart = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @objc public var isEnd = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var scale: CGFloat = 1 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        
        transform = CGAffineTransform.identity
        let resizing: ManeuversStyleKit.ResizingBehavior = .aspectFit
        var flip: Bool = false
        let type = maneuverTypeModifier.maneuverType ?? .turn
        let direction = maneuverTypeModifier.maneuverDirection ?? .straightAhead

        switch type {
        case .merge:
            ManeuversStyleKit.drawMerge(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor)
            flip = [.left, .slightLeft, .sharpLeft].contains(direction)
        case .takeOffRamp:
            ManeuversStyleKit.drawOfframp(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor)
            flip = [.left, .slightLeft, .sharpLeft].contains(direction)
        case .reachFork:
            ManeuversStyleKit.drawFork(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor)
            flip = [.left, .slightLeft, .sharpLeft].contains(direction)
        case .takeRoundabout, .turnAtRoundabout, .takeRotary:
            switch direction {
            case .straightAhead:
                ManeuversStyleKit.drawRoundabout(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor, roundabout_angle: 180)
                flip = direction.isLeftSide
            case .left, .slightLeft, .sharpLeft:
                ManeuversStyleKit.drawRoundabout(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor, roundabout_angle: 275)
                flip = direction.isLeftSide
            default:
                ManeuversStyleKit.drawRoundabout(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor, roundabout_angle: 90)
                flip = direction.isLeftSide
            }
        case .arrive:
            switch direction {
            case .right:
                ManeuversStyleKit.drawArriveright(frame: bounds, resizing: resizing, primaryColor: primaryColor)
            case .left:
                ManeuversStyleKit.drawArriveright(frame: bounds, resizing: resizing, primaryColor: primaryColor)
                flip = true
            default:
                ManeuversStyleKit.drawArrive(frame: bounds, resizing: resizing, primaryColor: primaryColor)
            }
        default:
            switch direction {
            case .right:
                ManeuversStyleKit.drawArrowright(frame: bounds, resizing: resizing, primaryColor: primaryColor)
                flip = false
            case .slightRight:
                ManeuversStyleKit.drawArrowslightright(frame: bounds, resizing: resizing, primaryColor: primaryColor)
                flip = false
            case .sharpRight:
                ManeuversStyleKit.drawArrowsharpright(frame: bounds, resizing: resizing, primaryColor: primaryColor)
                flip = false
            case .left:
                ManeuversStyleKit.drawArrowright(frame: bounds, resizing: resizing, primaryColor: primaryColor)
                flip = true
            case .slightLeft:
                ManeuversStyleKit.drawArrowslightright(frame: bounds, resizing: resizing, primaryColor: primaryColor)
                flip = true
            case .sharpLeft:
                ManeuversStyleKit.drawArrowsharpright(frame: bounds, resizing: resizing, primaryColor: primaryColor)
                flip = true
            case .uTurn:
                ManeuversStyleKit.drawArrow180right(frame: bounds, resizing: resizing, primaryColor: primaryColor)
                flip = direction.isLeftSide
            default:
                ManeuversStyleKit.drawArrowstraight(frame: bounds, resizing: resizing, primaryColor: primaryColor)
            }
        }
        
        transform = CGAffineTransform(scaleX: flip ? -1 : 1, y: 1)
    }
}

extension ManeuverDirection {
    var isLeftSide: Bool {
        switch self {
        case .left, .slightLeft, .sharpLeft:
            return true
        default:
            return false
        }
    }
}
