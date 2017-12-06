import UIKit

protocol StatusViewDelegate: class {
    func statusView(_ statusView: StatusView, sliderValueChangedTo value: Double)
}

/// :nodoc:
@IBDesignable
@objc(MBStatusView)
public class StatusView: UIView {
    weak var activityIndicatorView: UIActivityIndicatorView!
    weak var textLabel: UILabel!
    weak var delegate: StatusViewDelegate?
    var panStartPoint: CGPoint?
    
    var isSliderEnabled = false
    var sliderValue: Double = 0 {
        didSet {
            delegate?.statusView(self, sliderValueChangedTo: sliderValue)
        }
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
        let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
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
        
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(StatusView.handlePan(_:)))
        addGestureRecognizer(recognizer)
    }
    
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        guard isSliderEnabled else { return }
        
        let location = sender.location(in: self)
        
        if sender.state == .began {
            panStartPoint = location
        } else if sender.state == .changed {
            guard let startPoint = panStartPoint else { return }
            let offsetX = location.x - startPoint.x
            let coefficient = (offsetX / bounds.width) / 20.0
            sliderValue = Double(min(max(CGFloat(sliderValue) + coefficient, 0), 1))
        }
    }
    
    func show(_ title: String, showSpinner: Bool) {
        textLabel.text = title
        activityIndicatorView.hidesWhenStopped = true
        if showSpinner {
            activityIndicatorView.startAnimating()
        } else {
            activityIndicatorView.stopAnimating()
        }
        
        guard isHidden == true else { return }
        
        UIView.defaultAnimation(0.3, animations: {
            self.isHidden = false
            self.textLabel.alpha = 1
            self.superview?.layoutIfNeeded()
        }, completion: nil)
    }
    
    func hide(delay: TimeInterval = 0, animated: Bool = true) {
        
        if animated {
            guard isHidden == false else { return }
            
            UIView.defaultAnimation(0.3, delay: delay, animations: {
                self.isHidden = true
                self.textLabel.alpha = 0
                self.superview?.layoutIfNeeded()
            }, completion: { (completed) in
                self.activityIndicatorView.stopAnimating()
            })
        } else {
            activityIndicatorView.stopAnimating()
            isHidden = true
        }
    }
}
