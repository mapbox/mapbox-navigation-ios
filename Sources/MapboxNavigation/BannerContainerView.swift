import UIKit

// :nodoc:
@objc(MBBannerContainerView)
open class BannerContainerView: UIView {
    
    public enum `Type` {
        case top
        case bottom
    }
    
    var type: BannerContainerView.`Type`
    
    enum State {
        case expanded
        case collapsed
    }
    
    var isExpandable: Bool = false {
        didSet {
            guard let superview = superview else { return }
            setupConstraints(superview)
        }
    }
    
    var expansionOffset: CGFloat = 50.0
    
    var state: State = .collapsed {
        didSet {
            if oldValue == state { return }
            
            if state == .expanded {
                bottomConstraint.constant = 0.0
            } else {
                bottomConstraint.constant = expansionOffset
            }
        }
    }
    
    var bottomConstraint: NSLayoutConstraint!
    
    var initialBottomOffset: CGFloat = 0.0
    
    public init(_ type: BannerContainerView.`Type`, frame: CGRect = .zero) {
        self.type = type
        
        super.init(frame: frame)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        guard let superview = superview else { return }
        
        switch type {
        case .top:
            // TODO: Implement the ability to change top constraint.
            break
        case .bottom:
            setupConstraints(superview)
        }
    }
    
    public typealias CompletionHandler = (_ completed: Bool) -> Void
    
    func setupConstraints(_ superview: UIView) {
        if bottomConstraint != nil {
            NSLayoutConstraint.deactivate([bottomConstraint])
        }

        bottomConstraint = bottomAnchor.constraint(equalTo: superview.bottomAnchor)

        if isExpandable {
            if state == .expanded {
                bottomConstraint.constant = 0.0
            } else {
                bottomConstraint.constant = expansionOffset
            }

            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan))
            addGestureRecognizer(panGestureRecognizer)
        } else {
            bottomConstraint.constant = 0.0
        }

        bottomConstraint.isActive = true
    }
    
    @objc func didPan(_ recognizer: UIPanGestureRecognizer) {
        guard let view = recognizer.view else { return }
        
        if recognizer.state == .began {
            initialBottomOffset = bottomConstraint.constant
        }
        
        let translation = recognizer.translation(in: view)
        let currentOffset = initialBottomOffset + translation.y
        
        if currentOffset < 0.0 {
            bottomConstraint.constant = 0.0
        } else if currentOffset > expansionOffset {
            bottomConstraint.constant = expansionOffset
        } else {
            bottomConstraint.constant = currentOffset
        }
        
        if recognizer.state == .ended {
            let velocity = recognizer.velocity(in: view)
            
            if velocity.y <= 0 {
                state = .expanded
            } else {
                state = .collapsed
            }
            
            UIView.animate(withDuration: 0.2,
                           delay: 0.0,
                           options: [.allowUserInteraction],
                           animations: {
                self.superview?.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func show(animated: Bool = true,
              duration: TimeInterval = 0.5,
              completion: CompletionHandler? = nil) {
        guard isHidden else {
            completion?(true)
            return
        }
        
        if animated {
            bottomConstraint.constant = frame.height
            isHidden = false
            superview?.layoutIfNeeded()
            
            UIView.animate(withDuration: duration,
                           delay: 0.0,
                           options: [],
                           animations: {
                self.bottomConstraint.constant = 0.0
                self.superview?.layoutIfNeeded()
            }) { completed in
                completion?(completed)
            }
        } else {
            isHidden = false
            completion?(true)
        }
    }
    
    public func hide(animated: Bool = true,
                     duration: TimeInterval = 0.5,
                     completion: CompletionHandler? = nil) {
        guard !isHidden else {
            completion?(true)
            return
        }
        
        if animated {
            UIView.animate(withDuration: duration,
                           delay: 0.0,
                           options: [],
                           animations: {
                self.bottomConstraint.constant = self.frame.height
                self.superview?.layoutIfNeeded()
            }) { completed in
                self.isHidden = true
                completion?(completed)
            }
        } else {
            isHidden = true
            completion?(true)
        }
    }
}
