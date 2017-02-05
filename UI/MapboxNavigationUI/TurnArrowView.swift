import UIKit
import MapboxDirections
import MapboxNavigation
import SDWebImage

@IBDesignable
class TurnArrowView: UIView {
    var imageView: UIImageView!
    
    var showsShield = true
    var step: RouteStep? {
        didSet {
            imageView.isHidden = true
            /* TODO: Fix Shields.plist
            if showsShield, let components = step?.codes?.first?.components(separatedBy: " "), components.count > 1 {
                let network = components[0]
                let number = components[1]
                if var imageName = ShieldImageNamesByPrefix[network] {
                    imageName = imageName.replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "{ref}", with: number)
                    let url = URL(string: "https://commons.wikimedia.org/w/thumb.php?f=\(imageName)&w=\(imageView.bounds.width * UIScreen.main.scale)")
                    imageView.sd_setImage(with: url) { [weak self] (image, error, cacheType, url) in
                        self?.setNeedsDisplay()
                        self?.imageView.isHidden = false
                    }
                }
            }*/
            setNeedsDisplay()
        }
    }
    var isStart = false {
        didSet {
            setNeedsDisplay()
        }
    }
    var isEnd = false {
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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView = UIImageView(frame: bounds.insetBy(dx: 8, dy: 8))
        imageView.translatesAutoresizingMaskIntoConstraints = true
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
    }
    
    override func draw(_ rect: CGRect) {
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
        
        guard imageView.isHidden else {
            return
        }
        
        var flip: Bool = false
        let type: ManeuverType = step.maneuverType ?? .turn
        let angle: Int = Int(wrap((step.finalHeading ?? CLLocationDirection.abs(0)) - (step.initialHeading ?? CLLocationDirection.abs(0)), min: -180, max: 180))
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
            default:
                StyleKitArrows.drawArrow0(scale: scale)
            }
        }
        
        transform = CGAffineTransform(scaleX: flip ? -1 : 1, y: 1)
    }
}
