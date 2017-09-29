import UIKit
import MapboxDirections
import MapboxCoreNavigation
import SDWebImage
import Turf

@IBDesignable
@objc(MBTurnArrowView)
public class TurnArrowView: UIView {
    
    public dynamic var primaryColor: UIColor = .defaultTurnArrowPrimary {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public dynamic var secondaryColor: UIColor = .defaultTurnArrowSecondary {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var step: RouteStep? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var isStart = false {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public var isEnd = false {
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
        guard let step = step else {
            if isStart {
                StyleKitArrows.drawStarting(primaryColor: primaryColor, scale: scale)
            } else if isEnd {
                StyleKitArrows.drawDestination(primaryColor: primaryColor, scale: scale)
            }
            return
        }
        
        var flip: Bool = false
        let type: ManeuverType = step.maneuverType ?? .turn
        let angle = ((step.finalHeading ?? 0) - (step.initialHeading ?? 0)).wrap(min: -180, max: 180)
        let direction: ManeuverDirection = step.maneuverDirection ?? ManeuverDirection(angle: Int(angle))

        switch type {
        case .merge:
            StyleKitArrows.drawMerge(primaryColor: primaryColor, secondaryColor: secondaryColor, scale: scale)
            flip = [.right, .slightRight, .sharpRight].contains(direction)
        case .takeOffRamp:
            StyleKitArrows.drawOfframp(primaryColor: primaryColor, secondaryColor: secondaryColor, scale: scale)
            flip = [.right, .slightRight, .sharpRight].contains(direction)
        case .reachFork:
            StyleKitArrows.drawFork(primaryColor: primaryColor, secondaryColor: secondaryColor, scale: scale)
            flip = [.right, .slightRight, .sharpRight].contains(direction)
        case .takeRoundabout, .turnAtRoundabout, .takeRotary:
            switch direction {
            case .straightAhead:
                StyleKitArrows.drawRoundabout_180(primaryColor: primaryColor, secondaryColor: secondaryColor, scale: scale)
            case .left, .slightLeft, .sharpLeft:
                StyleKitArrows.drawRoundabout_275(primaryColor: primaryColor, secondaryColor: secondaryColor, scale: scale)
            default:
                StyleKitArrows.drawRoundabout(primaryColor: primaryColor, secondaryColor: secondaryColor, scale: scale)
            }
        case .arrive:
            switch direction {
            case .right:
                StyleKitArrows.drawArriveright(primaryColor: primaryColor, secondaryColor: secondaryColor, scale: scale)
            case .left:
                StyleKitArrows.drawArriveright(primaryColor: primaryColor, secondaryColor: secondaryColor, scale: scale)
                flip = true
            default:
                StyleKitArrows.drawArrive(primaryColor: primaryColor, scale: scale)
            }
        default:
            switch direction {
            case .right:
                StyleKitArrows.drawArrow45(primaryColor: primaryColor, scale: scale)
                flip = false
            case .slightRight:
                StyleKitArrows.drawArrow30(primaryColor: primaryColor, scale: scale)
                flip = false
            case .sharpRight:
                StyleKitArrows.drawArrow75(primaryColor: primaryColor, scale: scale)
                flip = false
            case .left:
                StyleKitArrows.drawArrow45(primaryColor: primaryColor, scale: scale)
                flip = true
            case .slightLeft:
                StyleKitArrows.drawArrow30(primaryColor: primaryColor, scale: scale)
                flip = true
            case .sharpLeft:
                StyleKitArrows.drawArrow75(primaryColor: primaryColor, scale: scale)
                flip = true
            case .uTurn:
                StyleKitArrows.drawArrow180(primaryColor: primaryColor, scale: scale)
                flip = angle < 0
            default:
                StyleKitArrows.drawArrow0(primaryColor: primaryColor, scale: scale)
            }
        }
        
        transform = CGAffineTransform(scaleX: flip ? -1 : 1, y: 1)
    }
}
