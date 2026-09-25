import MapboxDirections
import Turf
import UIKit

/// A view that contains a simple image indicating a type of maneuver.
@IBDesignable
open class ManeuverView: UIView {
    // MARK: Color Setup

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

    @objc public dynamic var primaryColorHighlighted: UIColor = .defaultTurnArrowPrimaryHighlighted {
        didSet {
            setNeedsDisplay()
        }
    }

    @objc public dynamic var secondaryColorHighlighted: UIColor = .defaultTurnArrowSecondaryHighlighted {
        didSet {
            setNeedsDisplay()
        }
    }

    public var shouldShowHighlightedColors: Bool = false {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: Drawing Customization

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

    /// The current instruction displayed in the maneuver view.
    public var visualInstruction: VisualInstruction? {
        didSet {
            setNeedsDisplay()
        }
    }

    /// This indicates the side of the road currently driven on.
    public var drivingSide: DrivingSide = .right {
        didSet {
            setNeedsDisplay()
        }
    }

    override open func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.saveGState()
        defer { context.restoreGState() }

        let currentPrimaryColor = shouldShowHighlightedColors ? primaryColorHighlighted : primaryColor
        let currentSecondaryColor = shouldShowHighlightedColors ? secondaryColorHighlighted : secondaryColor
        let resizing: ManeuversStyleKit.ResizingBehavior = .aspectFit

#if TARGET_INTERFACE_BUILDER
        ManeuversStyleKit.drawFork(
            frame: bounds,
            resizing: resizing,
            primaryColor: currentPrimaryColor,
            secondaryColor: currentSecondaryColor
        )
        return
#endif

        guard let visualInstruction else {
            if isStart {
                ManeuversStyleKit.drawStarting(frame: bounds, resizing: resizing, primaryColor: currentPrimaryColor)
            } else if isEnd {
                ManeuversStyleKit.drawDestination(frame: bounds, resizing: resizing, primaryColor: currentPrimaryColor)
            }
            return
        }

        let maneuverType = visualInstruction.maneuverType
        let maneuverDirection = visualInstruction.maneuverDirection

        let type = maneuverType ?? .turn
        let direction = maneuverDirection ?? .straightAhead

        if shouldFlip(type: type, direction: direction) {
            context.translateBy(x: bounds.width, y: 0)
            context.scaleBy(x: -1, y: 1)
        }

        switch type {
        case .merge:
            ManeuversStyleKit.drawMerge(
                frame: bounds,
                resizing: resizing,
                primaryColor: currentPrimaryColor,
                secondaryColor: currentSecondaryColor
            )
        case .takeOffRamp:
            ManeuversStyleKit.drawOfframp(
                frame: bounds,
                resizing: resizing,
                primaryColor: currentPrimaryColor,
                secondaryColor: currentSecondaryColor
            )
        case .reachFork:
            ManeuversStyleKit.drawFork(
                frame: bounds,
                resizing: resizing,
                primaryColor: currentPrimaryColor,
                secondaryColor: currentSecondaryColor
            )
        case .takeRoundabout, .turnAtRoundabout, .takeRotary, .exitRotary, .exitRoundabout:
            let angle = normalizedRoundaboutAngle(visualInstruction.finalHeading ?? 180)
            ManeuversStyleKit.drawRoundabout(
                frame: bounds,
                resizing: resizing,
                primaryColor: currentPrimaryColor,
                secondaryColor: currentSecondaryColor,
                roundabout_angle: angle
            )
        case .arrive:
            switch direction {
            case .right, .left:
                ManeuversStyleKit.drawArriveright(frame: bounds, resizing: resizing, primaryColor: currentPrimaryColor)
            default:
                ManeuversStyleKit.drawArrive(frame: bounds, resizing: resizing, primaryColor: currentPrimaryColor)
            }
        default:
            switch direction {
            case .right, .left:
                ManeuversStyleKit.drawArrowright(frame: bounds, resizing: resizing, primaryColor: currentPrimaryColor)
            case .slightRight, .slightLeft:
                ManeuversStyleKit.drawArrowslightright(
                    frame: bounds,
                    resizing: resizing,
                    primaryColor: currentPrimaryColor
                )
            case .sharpRight, .sharpLeft:
                ManeuversStyleKit.drawArrowsharpright(
                    frame: bounds,
                    resizing: resizing,
                    primaryColor: currentPrimaryColor
                )
            case .uTurn:
                ManeuversStyleKit.drawArrow180right(
                    frame: bounds,
                    resizing: resizing,
                    primaryColor: currentPrimaryColor
                )
            default:
                ManeuversStyleKit.drawArrowstraight(
                    frame: bounds,
                    resizing: resizing,
                    primaryColor: currentPrimaryColor
                )
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    @objc
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        // Explicitly mark the view as non-opaque.
        // This is needed to obtain correct compositing since we implement our own draw function that includes
        // transparency.
        isOpaque = false
    }

    private func shouldFlip(type: ManeuverType, direction: ManeuverDirection) -> Bool {
        switch type {
        case .merge, .takeOffRamp, .reachFork:
            return [.left, .slightLeft, .sharpLeft].contains(direction)
        case .takeRoundabout, .turnAtRoundabout, .takeRotary, .exitRotary, .exitRoundabout:
            return drivingSide == .left
        case .arrive:
            return direction == .left
        default:
            switch direction {
            case .left, .slightLeft, .sharpLeft:
                return true
            case .uTurn:
                // 180 turn is turning clockwise so we flip it if it's right-hand rule of the road
                return drivingSide == .right
            default:
                return false
            }
        }
    }

    private func normalizedRoundaboutAngle(_ angle: LocationDegrees) -> CGFloat {
        if angle == 0 { return angle }

        let minimumDistinguishAngle = 50.0
        let maximumDistinguishAngle = 310.0
        return max(min(maximumDistinguishAngle, angle), minimumDistinguishAngle)
    }
}
