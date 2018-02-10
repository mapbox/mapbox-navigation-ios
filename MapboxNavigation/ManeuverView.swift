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
    
    var maneuverDirection: ManeuverDirection? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var maneuverType: ManeuverType? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var drivingSide: DrivingSide? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public func set(_ maneuverDirection: ManeuverDirection, maneuverType: ManeuverType, drivingSide: DrivingSide) {
        self.maneuverDirection = maneuverDirection
        self.maneuverType = maneuverType
        self.drivingSide = drivingSide
    }
    
    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        
        transform = CGAffineTransform.identity
        let resizing: ManeuversStyleKit.ResizingBehavior = .aspectFit
        
        #if TARGET_INTERFACE_BUILDER
            ManeuversStyleKit.drawFork(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor)
            return
        #endif
        
        guard let maneuverType = maneuverType, let maneuverDirection = maneuverDirection, let drivingSide = drivingSide else {
            if isStart {
                ManeuversStyleKit.drawStarting(frame: bounds, resizing: resizing, primaryColor: primaryColor)
            } else if isEnd {
                ManeuversStyleKit.drawDestination(frame: bounds, resizing: resizing, primaryColor: primaryColor)
            }
            return
        }
        
        var flip: Bool = false
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
            switch direction {
            case .straightAhead:
                ManeuversStyleKit.drawRoundabout(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor, roundabout_angle: 180)
                flip = drivingSide == .left
            case .left, .slightLeft, .sharpLeft:
                ManeuversStyleKit.drawRoundabout(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor, roundabout_angle: 275)
                flip = drivingSide == .left
            default:
                ManeuversStyleKit.drawRoundabout(frame: bounds, resizing: resizing, primaryColor: primaryColor, secondaryColor: secondaryColor, roundabout_angle: 90)
                flip = drivingSide == .left
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
                flip = drivingSide == .right
            default:
                ManeuversStyleKit.drawArrowstraight(frame: bounds, resizing: resizing, primaryColor: primaryColor)
            }
        }
        
        transform = CGAffineTransform(scaleX: flip ? -1 : 1, y: 1)
    }
}
