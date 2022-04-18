import UIKit
import CoreLocation

/**
 A protocol that represents a `UIView` which tracks the user’s location and course on a `NavigationMapView`.
 */
public protocol CourseUpdatable where Self: UIView {
    /**
     Updates the view to reflect the given location and other camera properties.
     */
    func update(location: CLLocation, pitch: CGFloat, direction: CLLocationDegrees, animated: Bool, navigationCameraState: NavigationCameraState)
}

public extension CourseUpdatable {
    /**
     Transforms the location of the user location indicator layer.
     */
    func update(location: CLLocation, pitch: CGFloat, direction: CLLocationDegrees, animated: Bool, navigationCameraState: NavigationCameraState) {
        let duration: TimeInterval = animated ? 1 : 0
        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .curveLinear], animations: {
            let angle = CGFloat(CLLocationDegrees(direction - location.course).toRadians())
            if !(self is UserHaloCourseView) {
                self.layer.setAffineTransform(CGAffineTransform.identity.rotated(by: -angle))
            }
            
            // `UserCourseView` pitch is changed only during transition to the overview mode.
            let pitch = CGFloat(navigationCameraState == .transitionToOverview ? 0.0 : CLLocationDegrees(pitch).toRadians())
            var transform = CATransform3DRotate(CATransform3DIdentity, pitch, 1.0, 0, 0)
            
            let states: [NavigationCameraState] = [.overview, .transitionToOverview]
            let isCameraInOverview = states.contains(navigationCameraState)
            let scale = CGFloat(isCameraInOverview ? 0.5 : 1.0)
            transform = CATransform3DScale(transform, scale, scale, 1)
            transform.m34 = -1.0 / 1000 // (-1 / distance to projection plane)
            self.layer.sublayerTransform = transform
        }, completion: nil)
    }
}

/**
 A view representing the user’s location on screen.
 */
open class UserPuckCourseView: UIView, CourseUpdatable {
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        isUserInteractionEnabled = false
        backgroundColor = .clear
        puckView = UserPuckStyleKitView(frame: bounds)
        puckView.backgroundColor = .clear
        addSubview(puckView)
    }
    
    // MARK: Styling the Puck
    
    // Sets the color on the user puck
    @objc public dynamic var puckColor: UIColor = #colorLiteral(red: 0.149, green: 0.239, blue: 0.341, alpha: 1) {
        didSet {
            puckView.puckColor = puckColor
        }
    }
    
    // Sets the color on the user puck in 'stale' state. Puck will gradually transition the color as long as location updates are missing
    @available(*, deprecated, message: "No stale status in active navigation anymore.")
    @objc public dynamic var stalePuckColor: UIColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)

    // Sets the fill color on the circle around the user puck
    @objc public dynamic var fillColor: UIColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1) {
        didSet {
            puckView.fillColor = fillColor
        }
    }
    
    // Sets the shadow color around the user puck
    @objc public dynamic var shadowColor: UIColor = #colorLiteral(red: 0.149, green: 0.239, blue: 0.341, alpha: 0.16) {
        didSet {
            puckView.shadowColor = shadowColor
        }
    }
    
    var puckView: UserPuckStyleKitView!
    
    // MARK: Tracking Stale State

    /// Time interval tick at which Puck view is transitioning into 'stale' state
    @available(*, deprecated, message: "No stale status in active navigation anymore.")
    public var staleRefreshInterval: TimeInterval = 1
    /// Time interval, after which Puck is considered 100% 'stale'
    @available(*, deprecated, message: "No stale status in active navigation anymore.")
    public var staleInterval: TimeInterval = 60
    
    /**
     Gives the ability to minimize `UserPuckCourseView` when `NavigationCameraState` is
     in the `.overview` mode.
     */
    public var minimizesInOverview: Bool = true
    
    // MARK: CourseUpdatable Methods
    
    /**
     Transforms the location of the user location indicator layer.
     */
    open func update(location: CLLocation, pitch: CGFloat, direction: CLLocationDegrees, animated: Bool, navigationCameraState: NavigationCameraState) {
        let duration: TimeInterval = animated ? 1 : 0
        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .curveLinear], animations: { [weak self] in
            guard let self = self else { return }
            
            let angle = CGFloat(CLLocationDegrees(direction - location.course).toRadians())
            self.puckView.layer.setAffineTransform(CGAffineTransform.identity.rotated(by: -angle))
            
            // `UserCourseView` pitch is changed only during transition to the overview mode.
            let pitch = CGFloat(navigationCameraState == .transitionToOverview ? 0.0 : CLLocationDegrees(pitch).toRadians())
            var transform = CATransform3DRotate(CATransform3DIdentity, pitch, 1.0, 0, 0)
            
            if self.minimizesInOverview {
                let states: [NavigationCameraState] = [.overview, .transitionToOverview]
                let isCameraInOverview = states.contains(navigationCameraState)
                let scale = CGFloat(isCameraInOverview ? 0.5 : 1.0)
                transform = CATransform3DScale(transform, scale, scale, 1)
            }
            
            transform.m34 = -1.0 / 1000 // (-1 / distance to projection plane)
            self.layer.sublayerTransform = transform
        }, completion: nil)
    }
}

class UserPuckStyleKitView: UIView {
    private typealias ColorComponents = (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat)
    
    var fillColor: UIColor = UIColor(red: 1.000, green: 1.000, blue: 1.000, alpha: 1.000) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var puckColor: UIColor = UIColor(red: 0.149, green: 0.239, blue: 0.341, alpha: 1.000) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var shadowColor: UIColor = UIColor(red: 0.149, green: 0.239, blue: 0.341, alpha: 0.160) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        UserPuckStyleKit.drawNavigationPuck(frame: rect, resizing: .aspectFit, fillColor: fillColor, puckColor: puckColor, shadowColor: shadowColor, circleColor: fillColor)
    }
}
