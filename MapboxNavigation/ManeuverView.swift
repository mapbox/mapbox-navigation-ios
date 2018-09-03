import UIKit
import MapboxDirections
import MapboxCoreNavigation
import Turf

/// :nodoc:
@IBDesignable
@objc(MBManeuverView)
open class ManeuverView: UIView {

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

    /**
     The current instruction displayed in the maneuver view.
     */
    @objc public var visualInstruction: VisualInstruction? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /**
     This indicates the side of the road currently driven on.
     */
    @objc public var drivingSide: DrivingSide = .right {
        didSet {
            setNeedsDisplay()
        }
    }

    override open func draw(_ rect: CGRect) {
        super.draw(rect)

        transform = .identity
        let resizing: ManeuversStyleKit.ResizingBehavior = .aspectFit

        #if TARGET_INTERFACE_BUILDER
            ManeuversStyleKit.drawFork(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor)
            return
        #endif

        guard let visualInstruction = visualInstruction else {
            if isStart {
                ManeuversStyleKit.drawStarting(frame: bounds, resizing: resizing, primaryColor: primaryColor)
            } else if isEnd {
                ManeuversStyleKit.drawDestination(frame: bounds, resizing: resizing, primaryColor: primaryColor)
            }
            return
        }

        var flip: Bool = false
        let maneuverType = visualInstruction.maneuverType
        let maneuverDirection = visualInstruction.maneuverDirection
        
        let type = maneuverType != .none ? maneuverType : .turn
        let direction = maneuverDirection != .none ? maneuverDirection : .straightAhead

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
            ManeuversStyleKit.drawRoundabout(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor, roundabout_angle: CGFloat(visualInstruction.finalHeading))
            flip = drivingSide == .left
            
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
                flip = drivingSide == .right // 180 turn is turning clockwise so we flip it if it's right-hand rule of the road
            default:
                ManeuversStyleKit.drawArrowstraight(frame: bounds, resizing: resizing, primaryColor: primaryColor)
            }
        }

        transform = CGAffineTransform(scaleX: flip ? -1 : 1, y: 1)
    }
}
