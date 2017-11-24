import UIKit

extension UIView {
    class func defaultAnimation(_ duration: TimeInterval, delay: TimeInterval = 0, animations: @escaping () -> Void, completion: ((_ completed: Bool) -> Void)?) {
        UIView.animate(withDuration: duration, delay: delay, options: .curveEaseInOut, animations: animations, completion: completion)
    }
    
    class func defaultSpringAnimation(_ duration: TimeInterval, delay: TimeInterval = 0, animations: @escaping () -> Void, completion: ((_ completed: Bool) -> Void)?) {
        UIView.animate(withDuration: duration, delay: delay, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.6, options: [.beginFromCurrentState], animations: animations, completion: completion)
    }
    
    func applyDefaultCornerRadiusShadow(cornerRadius: CGFloat? = 4, shadowOpacity: CGFloat? = 0.1) {
        layer.cornerRadius = cornerRadius!
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 4
        layer.shadowOpacity = Float(shadowOpacity!)
    }
    
    func applyDefaultShadow(shadowOpacity: CGFloat? = 0.1) {
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 4
        layer.shadowOpacity = Float(shadowOpacity!)
    }
    
    func startRippleAnimation() {
        layer.masksToBounds = true
        let rippleLayer = RippleLayer()
        rippleLayer.rippleRadius = bounds.midX
        rippleLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        layer.addSublayer(rippleLayer)
        rippleLayer.startAnimation()
    }
    
    class func fromNib<T : UIView>() -> T? {
        let nibName = String(describing: T.self)
        return Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)?[0] as? T
    }
    
    func pinInSuperview() {
        guard let superview = superview else { return }
        topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
        leftAnchor.constraint(equalTo: superview.leftAnchor).isActive = true
        bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
        rightAnchor.constraint(equalTo: superview.rightAnchor).isActive = true
    }
    
    var safeTopAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.topAnchor
        }
        return topAnchor
    }
    
    var safeLeftAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.leftAnchor
        }
        return leftAnchor
    }
    
    var safeBottomAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.bottomAnchor
        }
        return bottomAnchor
    }
    
    var safeRightAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.rightAnchor
        }
        return rightAnchor
    }
    
    var safeTrailingAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide.trailingAnchor
        }
        return trailingAnchor
    }
}

protocol AdaptiveElement {
    var traitCollection: UITraitCollection { get }
    func update(for incomingTraitCollection: UITraitCollection)
}

struct AdaptiveConstraintContainer: AdaptiveElement {
    
    let traitCollection: UITraitCollection
    let constraints: [NSLayoutConstraint]
    
    func update(for incomingTraitCollection: UITraitCollection) {
        if incomingTraitCollection.containsTraits(in: traitCollection) {
            NSLayoutConstraint.activate(constraints)
        } else {
            NSLayoutConstraint.deactivate(constraints)
        }
    }
}

protocol AdaptiveView: class, AdaptiveElement {
    var adaptiveElements: [AdaptiveElement] { get set }
}

extension AdaptiveView {
    func addConstraints(for traitCollections: [UITraitCollection], constraints: NSLayoutConstraint...) {
        let container = AdaptiveConstraintContainer(traitCollection: traitCollection, constraints: constraints)
        adaptiveElements.append(container)
    }
}

extension AdaptiveView {
    func update(for incomingTraitCollection: UITraitCollection) {
        adaptiveElements.filter { incomingTraitCollection.containsTraits(in: $0.traitCollection) == false }.forEach {
            $0.update(for: incomingTraitCollection)
        }
        adaptiveElements.filter { incomingTraitCollection.containsTraits(in: $0.traitCollection) == true }.forEach {
            $0.update(for: incomingTraitCollection)
        }
    }
}

class RippleLayer: CAReplicatorLayer {
    var animationGroup: CAAnimationGroup? {
        didSet {
            animationGroup?.delegate = self
        }
    }
    var rippleRadius: CGFloat = 100
    var rippleColor: UIColor = .red
    var rippleRepeatCount: Float = .greatestFiniteMagnitude
    var rippleWidth: CGFloat = 10
    
    fileprivate var rippleEffect: CALayer?
    
    override init() {
        super.init()
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        setupRippleEffect()
        repeatCount = Float(rippleRepeatCount)
    }
    
    override func layoutSublayers() {
        super.layoutSublayers()
        
        rippleEffect?.bounds = CGRect(x: 0, y: 0, width: rippleRadius*2, height: rippleRadius*2)
        rippleEffect?.cornerRadius = rippleRadius
        instanceCount = 3
        instanceDelay = 0.4
    }
    
    func setupRippleEffect() {
        rippleEffect = CALayer()
        rippleEffect?.borderWidth = CGFloat(rippleWidth)
        rippleEffect?.borderColor = rippleColor.cgColor
        rippleEffect?.opacity = 0
        
        addSublayer(rippleEffect!)
    }
    
    func startAnimation() {
        animationGroup = rippleAnimationGroup()
        rippleEffect?.add(animationGroup!, forKey: "ripple")
    }
    
    func stopAnimation() {
        rippleEffect?.removeAnimation(forKey: "ripple")
    }
    
    func rippleAnimationGroup() -> CAAnimationGroup {
        let duration: CFTimeInterval = 3
        
        let group = CAAnimationGroup()
        group.duration = duration
        group.repeatCount = self.repeatCount
        group.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale.xy")
        scaleAnimation.fromValue = 0.0;
        scaleAnimation.toValue = 1.0;
        scaleAnimation.duration = duration
        
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.duration = duration
        let fromAlpha = 1.0
        opacityAnimation.values = [fromAlpha, (fromAlpha * 0.5), 0];
        opacityAnimation.keyTimes = [0, 0.2, 1];
        
        group.animations = [scaleAnimation, opacityAnimation]
        
        return group
    }
}

extension RippleLayer: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let count = rippleEffect?.animationKeys()?.count , count > 0 {
            rippleEffect?.removeAllAnimations()
        }
    }
}
