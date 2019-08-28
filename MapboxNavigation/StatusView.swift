import UIKit

/// :nodoc:
@objc public protocol DeprecatedStatusViewDelegate: class {}

/**
 A protocol for listening in on changes made to a `StatusView`.
 */
@available(*, deprecated, message: "Add a target to StatusView for UIControl.Event.valueChanged instead.")
@objc public protocol StatusViewDelegate: DeprecatedStatusViewDelegate {
    /**
     Indicates a value in the status view has changed by the user interacting with it.
     */
    @available(*, deprecated, message: "Add a target to StatusView for UIControl.Event.valueChanged instead.")
    @objc optional func statusView(_ statusView: StatusView, valueChangedTo value: Double)
}

/// :nodoc:
@objc private protocol StatusViewDelegateDeprecations {
    @objc optional func statusView(_ statusView: StatusView, valueChangedTo value: Double)
}

/**
 :nodoc:
 
 A translucent bar that responds to tap and swipe gestures, similar to a scrubber or stepper control, and expands and collapses to maximize screen real estate.
 */
@IBDesignable
@objc(MBStatusView)
public class StatusView: UIControl {
    
    weak var activityIndicatorView: UIActivityIndicatorView!
    weak var textLabel: UILabel!
    @objc public weak var delegate: DeprecatedStatusViewDelegate?
    var panStartPoint: CGPoint?
    
    var isCurrentlyVisible: Bool = false
    
    @available(*, deprecated, renamed: "isEnabled")
    @objc public var canChangeValue: Bool {
        get {
            return isEnabled
        }
        set {
            isEnabled = newValue
        }
    }
    
    var value: Double = 0 {
        didSet {
            sendActions(for: .valueChanged)
            (delegate as? StatusViewDelegateDeprecations)?.statusView?(self, valueChangedTo: value)
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
        guard isEnabled else { return }
        
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
        guard isEnabled else { return }
        
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
    

    public func showStatus(title: String, spinner spin: Bool = false, duration: TimeInterval, animated: Bool = true, interactive: Bool = false) {
        show(title, showSpinner: spin, interactive: interactive)
        guard duration < .infinity else { return }
        hide(delay: duration, animated: animated)
    }
    
    func showSimulationStatus(speed: Int) {
        let format = NSLocalizedString("USER_IN_SIMULATION_MODE", bundle: .mapboxNavigation, value: "Simulating Navigation at %@×", comment: "The text of a banner that appears during turn-by-turn navigation when route simulation is enabled.")
        let title = String.localizedStringWithFormat(format, NumberFormatter.localizedString(from: speed as NSNumber, number: .decimal))
        showStatus(title: title, duration: .infinity, interactive: true)
    }

    
    /**
     Shows the status view with an optional spinner.
     */
    public func show(_ title: String, showSpinner: Bool, interactive: Bool = false) {
        isEnabled = interactive
        textLabel.text = title
        activityIndicatorView.hidesWhenStopped = true
        if (!showSpinner) { activityIndicatorView.stopAnimating() }

        guard !isCurrentlyVisible, isHidden else { return }
                
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
            let fireTime = DispatchTime.now() + delay
            DispatchQueue.main.asyncAfter(deadline: fireTime, execute: {
                guard !self.isHidden, self.isCurrentlyVisible else { return }
                
                self.activityIndicatorView.stopAnimating()
                UIView.defaultAnimation(0.3, delay: 0, animations: hide, completion: { _ in
                    self.isCurrentlyVisible = false
                })
            })
        }
        
        if animated {
            animate()
        } else {
            hide()
        }
    }
}
