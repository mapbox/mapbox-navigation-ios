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
    
    deinit {
        staleTimer.invalidate()
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: nil)
    }
    
    func commonInit() {
        isUserInteractionEnabled = false
        backgroundColor = .clear
        puckView = UserPuckStyleKitView(frame: bounds)
        puckView.backgroundColor = .clear
        addSubview(puckView)
        
        initTimer()
        
        NotificationCenter.default.addObserver(self, selector: #selector(locationDidUpdate(_ :)), name: .routeControllerProgressDidChange, object: nil)
    }
    
    // MARK: Styling the Puck
    
    // Sets the color on the user puck
    @objc public dynamic var puckColor: UIColor = #colorLiteral(red: 0.149, green: 0.239, blue: 0.341, alpha: 1) {
        didSet {
            puckView.puckColor = puckColor
        }
    }
    
    // Sets the color on the user puck in 'stale' state. Puck will gradually transition the color as long as location updates are missing
    @objc public dynamic var stalePuckColor: UIColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1) {
        didSet {
            puckView.stalePuckColor = stalePuckColor
        }
    }

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
    
    private var lastLocationUpdate: Date?
    private var staleTimer: Timer!

    /// Time interval tick at which Puck view is transitioning into 'stale' state
    public var staleRefreshInterval: TimeInterval = 1 {
        didSet {
            staleTimer.invalidate()
            initTimer()
        }
    }
    /// Time interval, after which Puck is considered 100% 'stale'
    public var staleInterval: TimeInterval = 60
    
    /**
     Gives the ability to minimize `UserPuckCourseView` when `NavigationCameraState` is
     in the `.overview` mode.
     */
    public var minimizesInOverview: Bool = true
    
    private func initTimer() {
        staleTimer = Timer(timeInterval: staleRefreshInterval,
                           repeats: true,
                           block: { [weak self] _ in
                            self?.refreshPuckStaleState()
                           })
        RunLoop.current.add(staleTimer, forMode: .common)
    }

    private func refreshPuckStaleState() {
        if let lastUpdate = lastLocationUpdate {
            let ratio = CGFloat(Date().timeIntervalSince(lastUpdate) / staleInterval)
            puckView.staleRatio = max(0.0, min(1.0, ratio))
        }
        else {
            puckView.staleRatio = 0.0
        }
    }
    
    @objc func locationDidUpdate(_ notification: NSNotification) {
        lastLocationUpdate = Date()
    }
    
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
            puckColorComponents = colorComponents(puckColor)
            setNeedsDisplay()
        }
    }
    lazy private var puckColorComponents: ColorComponents! = colorComponents(puckColor)
    
    var stalePuckColor: UIColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1) {
        didSet {
            stalePuckColorComponents = colorComponents(stalePuckColor)
            setNeedsDisplay()
        }
    }
    lazy private var stalePuckColorComponents: ColorComponents! = colorComponents(stalePuckColor)
    
    var staleRatio: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var shadowColor: UIColor = UIColor(red: 0.149, green: 0.239, blue: 0.341, alpha: 0.160) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    private func colorComponents(_ color: UIColor) -> ColorComponents {
        var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
        color.getHue(&hue,
                     saturation: &saturation,
                     brightness: &brightness,
                     alpha: &alpha)
        return (hue, saturation, brightness, alpha)
    }
    
    private func drawingPuckColor() -> UIColor {
        puckColorComponents = colorComponents(puckColor)
        stalePuckColorComponents = colorComponents(stalePuckColor)
        
        return UIColor(hue: puckColorComponents.hue + (stalePuckColorComponents.hue - puckColorComponents.hue) * staleRatio,
                       saturation: puckColorComponents.saturation + (stalePuckColorComponents.saturation - puckColorComponents.saturation) * staleRatio,
                       brightness: puckColorComponents.brightness + (stalePuckColorComponents.brightness - puckColorComponents.brightness) * staleRatio,
                       alpha: puckColorComponents.alpha + (stalePuckColorComponents.alpha - puckColorComponents.alpha) * staleRatio)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        UserPuckStyleKit.drawNavigationPuck(frame: rect, resizing: .aspectFit, fillColor: fillColor, puckColor: drawingPuckColor(), shadowColor: shadowColor, circleColor: fillColor)
    }
}
