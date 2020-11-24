import UIKit

/// :nodoc:
public protocol DeprecatedStatusViewDelegate: class {}

/**
 A protocol for listening in on changes made to a `StatusView`.
 */
@available(*, deprecated, message: "Add a target to StatusView for UIControl.Event.valueChanged instead.")
public protocol StatusViewDelegate: DeprecatedStatusViewDelegate {
    /**
     Indicates a value in the status view has changed by the user interacting with it.
     */
    @available(*, deprecated, message: "Add a target to StatusView for UIControl.Event.valueChanged instead.")
    func statusView(_ statusView: StatusView, valueChangedTo value: Double)
}

/// :nodoc:
private protocol StatusViewDelegateDeprecations {
    func statusView(_ statusView: StatusView, valueChangedTo value: Double)
}

/**
 :nodoc:
 
 A translucent bar that responds to tap and swipe gestures, similar to a scrubber or stepper control, and expands and collapses to maximize screen real estate.
 */
@IBDesignable
public class StatusView: UIControl {
    weak var activityIndicatorView: UIActivityIndicatorView!
    weak var textLabel: UILabel!
    public weak var delegate: DeprecatedStatusViewDelegate?
    var panStartPoint: CGPoint?
    
    var isCurrentlyVisible: Bool = false
    
    @available(swift, obsoleted: 0.1, renamed: "isEnabled")
    public var canChangeValue: Bool {
        fatalError()
    }
    
    // TODO: find a way to handle values attached to Statuses
    var value: Double = 0 {
        didSet {
            sendActions(for: .valueChanged)
            (delegate as? StatusViewDelegateDeprecations)?.statusView(self, valueChangedTo: value)
        }
    }
    
    static var statuses: [StatusView.Status] = []

    public struct Status: Identifiable {
        public var id: String
//        let title: String
        var spinner: Bool = false
        let duration: TimeInterval
        var animated: Bool = true
        var interactive: Bool = false
        var priority: Priority
    }
    
    // TODO: define set of constants for priority
    struct Priority: RawRepresentable {
        public var rawValue: Int
//        — Highest Priority —
//            rerouting (rawValue = 0)
//            enable precise location (rawValue = 1)
//            simulation banner (rawValue = 2)
//        — Lowest Priority —
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
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
            if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                incrementer = location.x < bounds.midX ? 0.1 : -0.1
            } else {
                incrementer = location.x > bounds.midX ? 0.1 : -0.1
            }
            value = min(max(value + incrementer, 0), 1)
        }
    }
    
    // fix name (method to deal with hiding/showing status banners and updating statuses array)
    func manageStatuses(status: Status? = nil) {
        
//        if status != nil {
//            guard let row = StatusView.statuses.firstIndex(where: {$0.id == status?.id}) else { return }
//            StatusView.statuses.remove(at: row)
//        }
        
        // if we hide a Status and there are no Statuses left in the statuses array, we want to hide the status view entirely
        if StatusView.statuses.isEmpty {
            print("!!! statuses is empty")
            hide(delay: (status?.duration ?? 0), animated: (status?.animated ?? true))
        } else {
            // if we hide a Status and there are Statuses left in the statuses array, we want to show the Status with the highest priority
            // find status with "highest" priority
            guard let highestPriorityStatus = StatusView.statuses.min(by: {$0.priority.rawValue > $1.priority.rawValue}) else { return }
            print("!!! \(String(describing: highestPriorityStatus))")
            
            isEnabled = highestPriorityStatus.interactive
            textLabel.text = highestPriorityStatus.id
            activityIndicatorView.hidesWhenStopped = true
            if (!highestPriorityStatus.spinner) { activityIndicatorView.stopAnimating() }

            guard !isCurrentlyVisible, isHidden else { return }
                    
            let show = {
                self.isHidden = false
                self.textLabel.alpha = 1
                if (highestPriorityStatus.spinner) { self.activityIndicatorView.isHidden = false }
                self.superview?.layoutIfNeeded()
            }
            
            UIView.defaultAnimation(0.3, animations:show, completion:{ _ in
                self.isCurrentlyVisible = true
                guard highestPriorityStatus.spinner else { return }
                self.activityIndicatorView.startAnimating()
            })
            //guard highestPriorityStatus.duration < .infinity else { return }
            //hide(delay: highestPriorityStatus.duration, animated: highestPriorityStatus.animated)
        }
    }
    
    func hideStatus(banner: Status) {
        guard let row = StatusView.statuses.firstIndex(where: {$0.id == banner.id}) else { return }
        let removedStatus = StatusView.statuses.remove(at: row)
        manageStatuses(status: removedStatus)
    }
    
    public func showStatus(title: String, spinner spin: Bool = false, duration: TimeInterval, animated: Bool = true, interactive: Bool = false) {
        // show(title, showSpinner: spin, interactive: interactive)
        guard duration < .infinity else { return }
        hide(delay: duration, animated: animated)
    }
    
    func showSimulationStatus(speed: Int) {
        let format = NSLocalizedString("USER_IN_SIMULATION_MODE", bundle: .mapboxNavigation, value: "Simulating Navigation at %@×", comment: "The text of a banner that appears during turn-by-turn navigation when route simulation is enabled.")
        let title = String.localizedStringWithFormat(format, NumberFormatter.localizedString(from: speed as NSNumber, number: .decimal))
        
        // create simulation status and append to array of statuses
        let simulationStatus = Status(id: title, duration: .infinity, interactive: true, priority: StatusView.Priority(rawValue: 2))
        if let row = StatusView.statuses.firstIndex(where: {$0.id.contains("Simulating Navigation")}) {
            StatusView.statuses[row] = simulationStatus
        } else {
            StatusView.statuses.append(simulationStatus)
        }
        manageStatuses()
        // showStatus(title: title, duration: .infinity, interactive: true)
    }
    
    /**
     Shows the status view with an optional spinner.
     */
    public func show(status: Status) {
        isEnabled = status.interactive
        textLabel.text = status.id
        activityIndicatorView.hidesWhenStopped = true
        if (!status.spinner) { activityIndicatorView.stopAnimating() }

        guard !isCurrentlyVisible, isHidden else { return }
                
        let show = {
            self.isHidden = false
            self.textLabel.alpha = 1
            if (status.spinner) { self.activityIndicatorView.isHidden = false }
            self.superview?.layoutIfNeeded()
        }
        
        UIView.defaultAnimation(0.3, animations:show, completion:{ _ in
            self.isCurrentlyVisible = true
            guard status.spinner else { return }
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
