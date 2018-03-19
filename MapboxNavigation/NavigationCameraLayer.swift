import Foundation
import CoreGraphics

class NavigationCameraLayer: CALayer {
    
    @NSManaged var pitch: CGFloat
    @NSManaged var altitude: CLLocationDistance
    @NSManaged var course: CLLocationDirection
    
    enum CustomAnimationKey: String {
        case altitude
        case pitch
        case course
        static let allKeys: [CustomAnimationKey] = [.altitude, .pitch, .course]
    }
    
    override init() {
        super.init()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        if let layer = layer as? NavigationCameraLayer {
            altitude = layer.altitude
            pitch = layer.pitch
            course = layer.course
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate class func isCustomAnimationKey(key: String) -> Bool {
        return !(CustomAnimationKey(rawValue: key) == nil)
    }
    
    override class func needsDisplay(forKey key: String) -> Bool {
        return self.isCustomAnimationKey(key: key) ? true : super.needsDisplay(forKey: key)
    }
    
    override func action(forKey event: String) -> CAAction? {
        guard NavigationCameraLayer.isCustomAnimationKey(key: event) else {
            return super.action(forKey: event)
        }
        
        guard let animation = super.action(forKey: "backgroundColor") as? CABasicAnimation else {
            setNeedsDisplay()
            return nil
        }
        
        guard let presentationLayer = presentation(),
              let customKey = CustomAnimationKey(rawValue: event) else {
            return super.action(forKey: event)
        }
        
        animation.keyPath = event
        
        switch customKey {
        case .altitude:
            animation.fromValue = presentationLayer.altitude
        case .pitch:
            animation.fromValue = presentationLayer.pitch
        case .course:
            animation.fromValue = presentationLayer.course
        }
        
        animation.toValue = nil
        return animation
    }
}








