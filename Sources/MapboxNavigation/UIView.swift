import UIKit

extension UIView {
    
    func addSubviews(_ subviews: [UIView]) {
        subviews.forEach(addSubview(_:))
    }
    
    var imageRepresentation: UIImage? {
        let size = CGSize(width: frame.size.width, height: frame.size.height)
        UIGraphicsBeginImageContextWithOptions(size, false, (window?.screen ?? UIScreen.main).scale)
        guard let currentContext = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in:currentContext)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        // Check the transform property to see if the view was flipped.
        // If it was then we need to apply a flip transform here as well since layer.render() ignores the view's transform when it is rendered
        let isFlipped = transform.a == -1
        return isFlipped ? image?.withHorizontallyFlippedOrientation() : image
    }
    
    // MARK: Animating
    
    class func defaultAnimation(_ duration: TimeInterval,
                                delay: TimeInterval = 0,
                                animations: @escaping () -> Void,
                                completion: ((_ completed: Bool) -> Void)?) {
        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: .curveEaseInOut,
                       animations: animations,
                       completion: completion)
    }
    
    class func defaultSpringAnimation(_ duration: TimeInterval,
                                      delay: TimeInterval = 0,
                                      animations: @escaping () -> Void,
                                      completion: ((_ completed: Bool) -> Void)?) {
        UIView.animate(withDuration: duration,
                       delay: delay,
                       usingSpringWithDamping: 0.6,
                       initialSpringVelocity: 0.6,
                       options: [.beginFromCurrentState],
                       animations: animations,
                       completion: completion)
    }
    
    // MARK: Layer Styling
    
    func applyGradient(colors: [UIColor], locations: [NSNumber]? = nil) {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = colors.map { $0.cgColor }
        gradient.locations = locations
        
        if let sublayers = layer.sublayers, !sublayers.isEmpty, let sublayer = sublayers.first {
            layer.replaceSublayer(sublayer, with: gradient)
        } else {
            layer.addSublayer(gradient)
        }
    }
    
    // MARK: Constraining the View
    
    func constraints(affecting view: UIView?) -> [NSLayoutConstraint]? {
        guard let view = view else { return nil }
        return constraints.filter { constraint in
            if let first = constraint.firstItem as? UIView, first == view {
                return true
            }
            if let second = constraint.secondItem as? UIView, second == view {
                return true
            }
            return false
        }
    }
    
    func constraintsForPinning(to parentView: UIView, respectingMargins margins: Bool = false) -> [NSLayoutConstraint] {
        let guide: Anchorable = (margins) ? parentView.layoutMarginsGuide : parentView
        
        let constraints = [
            topAnchor.constraint(equalTo: guide.topAnchor),
            leftAnchor.constraint(equalTo: guide.leftAnchor),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor),
            rightAnchor.constraint(equalTo: guide.rightAnchor)
        ]
        return constraints
    }
    
    func pinTo(parentView parent: UIView, respectingMargins margins: Bool = false) {
        let constraints = constraintsForPinning(to: parent, respectingMargins: margins)
        NSLayoutConstraint.activate(constraints)
    }
    
    func pinInSuperview(respectingMargins margins: Bool = false) {
        guard let superview = superview else { return }
        pinTo(parentView: superview, respectingMargins: margins)
    }
    
    class func forAutoLayout<ViewType: UIView>(frame: CGRect = .zero, hidden: Bool = false) -> ViewType {
        let view = ViewType.init(frame: frame)
        view.isHidden = hidden
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }
    
    // MARK: Anchors Access
    
    var safeArea: UIEdgeInsets {
        return safeAreaInsets
    }
    
    var safeTopAnchor: NSLayoutYAxisAnchor {
        return safeAreaLayoutGuide.topAnchor
    }
    
    var safeLeadingAnchor: NSLayoutXAxisAnchor {
        return safeAreaLayoutGuide.leadingAnchor
    }
    
    var safeBottomAnchor: NSLayoutYAxisAnchor {
        return safeAreaLayoutGuide.bottomAnchor
    }
    
    var safeRightAnchor: NSLayoutXAxisAnchor {
        return safeAreaLayoutGuide.rightAnchor
    }
    
    var safeTrailingAnchor: NSLayoutXAxisAnchor {
        return safeAreaLayoutGuide.trailingAnchor
    }
    
    var safeWidthAnchor: NSLayoutDimension {
        return safeAreaLayoutGuide.widthAnchor
    }
    
    var safeHeightAnchor: NSLayoutDimension {
        return safeAreaLayoutGuide.heightAnchor
    }
    
    var safeCenterXAnchor: NSLayoutXAxisAnchor {
        return safeAreaLayoutGuide.centerXAnchor
    }
    
    var safeCenterYAnchor: NSLayoutYAxisAnchor {
        return safeAreaLayoutGuide.centerYAnchor
    }
}

protocol Anchorable {
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var leftAnchor: NSLayoutXAxisAnchor { get }
    var rightAnchor: NSLayoutXAxisAnchor { get }
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
}

extension UIView: Anchorable {}
extension UILayoutGuide: Anchorable {}
