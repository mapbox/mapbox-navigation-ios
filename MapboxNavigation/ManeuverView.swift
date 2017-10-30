import UIKit
import MapboxDirections
import MapboxCoreNavigation
import SDWebImage
import Turf

@IBDesignable
@objc(MBManeuverView)
public class ManeuverView: UIView {
    
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
        let resizing: ManeuversStyleKit.ResizingBehavior = .aspectFill
        
        guard let step = step else {
            if isStart {
                ManeuversStyleKit.drawStarting(frame: bounds, resizing: resizing, primaryColor: primaryColor, size: bounds.size)
            } else if isEnd {
                ManeuversStyleKit.drawDestination(frame: bounds, resizing: resizing, primaryColor: primaryColor, size: bounds.size)
            }
            return
        }
        
        var flip: Bool = false
        let type: ManeuverType = step.maneuverType ?? .turn
        let angle = ((step.finalHeading ?? 0) - (step.initialHeading ?? 0)).wrap(min: -180, max: 180)
        let direction: ManeuverDirection = step.maneuverDirection ?? ManeuverDirection(angle: Int(angle))

        switch type {
        case .merge:
            ManeuversStyleKit.drawMerge(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor, size: bounds.size)
            flip = [.right, .slightRight, .sharpRight].contains(direction)
        case .takeOffRamp:
            ManeuversStyleKit.drawOfframp(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor, size: bounds.size)
            flip = [.right, .slightRight, .sharpRight].contains(direction)
        case .reachFork:
            ManeuversStyleKit.drawFork(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor, size: bounds.size)
            flip = [.right, .slightRight, .sharpRight].contains(direction)
        case .takeRoundabout, .turnAtRoundabout, .takeRotary:
            switch direction {
            case .straightAhead:
                ManeuversStyleKit.drawRoundabout(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor, size: bounds.size, roundabout_angle: 180)
            case .left, .slightLeft, .sharpLeft:
                ManeuversStyleKit.drawRoundabout(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor, size: bounds.size, roundabout_angle: 275)
            default:
                ManeuversStyleKit.drawRoundabout(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor, size: bounds.size, roundabout_angle: 90)
            }
        case .arrive:
            switch direction {
            case .right:
                ManeuversStyleKit.drawArrowright(frame: bounds, resizing: resizing, primaryColor: primaryColor, size: bounds.size)
            case .left:
                ManeuversStyleKit.drawArriveright(frame: bounds, resizing: resizing, primaryColor: primaryColor, size: bounds.size)
                flip = true
            default:
                ManeuversStyleKit.drawArrive(frame: bounds, resizing: resizing, primaryColor: primaryColor, size: bounds.size)
            }
        default:
            switch direction {
            case .right:
                ManeuversStyleKit.drawArrowright(frame: bounds, resizing: resizing, primaryColor: primaryColor, size: bounds.size)
                flip = false
            case .slightRight:
                ManeuversStyleKit.drawArrowslightright(frame: bounds, resizing: resizing, primaryColor: primaryColor, size: bounds.size)
                flip = false
            case .sharpRight:
                ManeuversStyleKit.drawArrowsharpright(frame: bounds, resizing: resizing, primaryColor: primaryColor, size: bounds.size)
                flip = false
            case .left:
                ManeuversStyleKit.drawArrowright(frame: bounds, resizing: resizing, primaryColor: primaryColor, size: bounds.size)
                flip = true
            case .slightLeft:
                ManeuversStyleKit.drawArrowslightright(frame: bounds, resizing: resizing, primaryColor: primaryColor, size: bounds.size)
                flip = true
            case .sharpLeft:
                ManeuversStyleKit.drawArrowsharpright(frame: bounds, resizing: resizing, primaryColor: primaryColor, size: bounds.size)
                flip = true
            case .uTurn:
                ManeuversStyleKit.drawArrow180right(frame: bounds, resizing: resizing, primaryColor: primaryColor, size: bounds.size)
                flip = angle < 0
            default:
                ManeuversStyleKit.drawArrowstraight(frame: bounds, resizing: resizing, primaryColor: primaryColor, size: bounds.size)
            }
        }
        
        transform = CGAffineTransform(scaleX: flip ? -1 : 1, y: 1)
    }
}
