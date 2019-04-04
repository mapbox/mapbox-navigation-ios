import UIKit

/**
 A protocol for listening in on changed mades made to a `StatusView`.
 */
@objc public protocol StatusViewDelegate: class {
    /**
     Indicates a value in the status view has changed by the user interacting with it.
     */
    @objc optional func statusView(_ statusView: StatusView, valueChangedTo value: Double)
}

/// :nodoc:
@IBDesignable
@objc(MBStatusView)
public class StatusView: UIView {
    
    weak var activityIndicatorView: UIActivityIndicatorView!
    weak var textLabel: UILabel!
    @objc public weak var delegate: StatusViewDelegate?
    var panStartPoint: CGPoint?
    
    var isCurrentlyVisible: Bool = false
    @objc public var canChangeValue = false
    var value: Double = 0 {
        didSet {
            delegate?.statusView?(self, valueChangedTo: value)
        }
    }
    
    @objc public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    @objc public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        let activityIndicatorView = UIActivityIndicatorView(style: .white)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicatorView)
        self.activityIndicatorView = activityIndicatorView
        
        let textLabel = UILabel()
        textLabel.contentMode = .bottom
        textLabel.text = NSLocalizedString("REROUTING", bundle: .mapboxNavigation, value: "Rerouting…", comment: "Indicates that rerouting is in progress")
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        textLabel.textColor = .white
        addSubview(textLabel)
        self.textLabel = textLabel
        
        let heightConstraint = heightAnchor.constraint(equalToConstant: 30)
        heightConstraint.priority = UILayoutPriority(rawValue: 999)
        heightConstraint.isActive = true
        textLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        textLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        activityIndicatorView.rightAnchor.constraint(equalTo: safeRightAnchor, constant: -10).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(StatusView.pan(_:)))
        addGestureRecognizer(recognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(StatusView.tap(_:)))
        addGestureRecognizer(tapRecognizer)
    }
    
    @objc func pan(_ sender: UIPanGestureRecognizer) {
        guard canChangeValue else { return }
        
        let location = sender.location(in: self)
        
        if sender.state == .began {
            panStartPoint = location
        } else if sender.state == .changed {
            guard let startPoint = panStartPoint else { return }
            let offsetX = location.x - startPoint.x
            let coefficient = (offsetX / bounds.width) / 20.0
            value = Double(min(max(CGFloat(value) + coefficient, 0), 1))
        }
    }
    
    @objc func tap(_ sender: UITapGestureRecognizer) {
        guard canChangeValue else { return }
        
        let location = sender.location(in: self)
        
        if sender.state == .ended {
            let incrementer: Double
            switch UIApplication.shared.userInterfaceLayoutDirection {
            case .leftToRight:
                incrementer = location.x > bounds.midX ? 0.1 : -0.1
            case .rightToLeft:
                incrementer = location.x < bounds.midX ? 0.1 : -0.1
            }
            value = min(max(value + incrementer, 0), 1)
        }
    }
    
    /**
     Shows the status view with an optional spinner.
     */
    public func show(_ title: String, showSpinner: Bool, interactive: Bool = false) {
        canChangeValue = interactive
        textLabel.text = title
        activityIndicatorView.hidesWhenStopped = true
        if (!showSpinner) { activityIndicatorView.stopAnimating() }

        guard isCurrentlyVisible == false, isHidden == true else { return }
                
        let show = {
            self.isHidden = false
            self.textLabel.alpha = 1
            if (showSpinner) { self.activityIndicatorView.isHidden = false }
            self.superview?.layoutIfNeeded()
        }
        
        UIView.defaultAnimation(0.3, animations:show, completion:{ _ in
            self.isCurrentlyVisible = true
            guard showSpinner else { return }
            self.activityIndicatorView.startAnimating()
        })
    }
    
    /**
     Hides the status view.
     */
    public func hide(delay: TimeInterval = 0, animated: Bool = true) {
        
        let hide = {
            self.isHidden = true
            self.textLabel.alpha = 0
            self.activityIndicatorView.isHidden = true
        }
        
        let animate = {
            guard self.isHidden == false else { return }
            
            let fireTime = DispatchTime.now() + delay
            DispatchQueue.main.asyncAfter(deadline: fireTime, execute: {
                self.activityIndicatorView.stopAnimating()
                UIView.defaultAnimation(0.3, delay: 0, animations: hide, completion: { _ in
                    self.isCurrentlyVisible = false
                })
            })
        }
        
        animated ? animate() : hide()
    }
}
