import UIKit
import MapboxDirections
import MapboxCoreNavigation
import SDWebImage

@IBDesignable
@objc(MBTurnArrowView)
public class TurnArrowView: UIView {
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
                StyleKitArrows.drawStarting(scale: scale)
            } else if isEnd {
                StyleKitArrows.drawDestination(scale: scale)
            }
            return
        }
        
        var flip: Bool = false
        let type: ManeuverType = step.maneuverType ?? .turn
        let angle: Int = Int(wrap((step.finalHeading ?? abs(0)) - (step.initialHeading ?? abs(0)), min: -180, max: 180))
        let direction: ManeuverDirection = step.maneuverDirection ?? ManeuverDirection(angle: angle)

        switch type {
        case .merge:
            StyleKitArrows.drawMerge(scale: scale)
            flip = [.right, .slightRight, .sharpRight].contains(direction)
        case .takeOffRamp:
            StyleKitArrows.drawOfframp(scale: scale)
            flip = [.right, .slightRight, .sharpRight].contains(direction)
        case .reachFork:
            StyleKitArrows.drawFork(scale: scale)
            flip = [.right, .slightRight, .sharpRight].contains(direction)
        case .takeRoundabout, .turnAtRoundabout:
            StyleKitArrows.drawRoundabout(scale: scale)
        case .arrive:
            switch direction {
            case .right:
                StyleKitArrows.drawArriveright(scale: scale)
            case .left:
                StyleKitArrows.drawArriveright(scale: scale)
                flip = true
            default:
                StyleKitArrows.drawArrive(scale: scale)
            }
        default:
            switch direction {
            case .right:
                StyleKitArrows.drawArrow45(scale: scale)
                flip = false
            case .slightRight:
                StyleKitArrows.drawArrow30(scale: scale)
                flip = false
            case .sharpRight:
                StyleKitArrows.drawArrow75(scale: scale)
                flip = false
            case .left:
                StyleKitArrows.drawArrow45(scale: scale)
                flip = true
            case .slightLeft:
                StyleKitArrows.drawArrow30(scale: scale)
                flip = true
            case .sharpLeft:
                StyleKitArrows.drawArrow75(scale: scale)
                flip = true
            case .uTurn:
                StyleKitArrows.drawArrow180(scale: scale)
                flip = angle < 0
            default:
                StyleKitArrows.drawArrow0(scale: scale)
            }
        }
        
        transform = CGAffineTransform(scaleX: flip ? -1 : 1, y: 1)
    }
}
