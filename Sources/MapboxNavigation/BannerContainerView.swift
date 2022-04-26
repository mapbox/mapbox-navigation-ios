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
    
    var topSafeAreaInset: CGFloat = 0.0
    
    var bottomSafeAreaInset: CGFloat = 0.0
    
    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        
        topSafeAreaInset = safeAreaInsets.top
        bottomSafeAreaInset = safeAreaInsets.bottom
    }
    
    var state: State = .collapsed {
        didSet {
            if oldValue == state { return }
            
            switch type {
            case .top:
                if state == .expanded {
                    expansionConstraint.constant = 0.0
                } else {
                    expansionConstraint.constant = -expansionOffset
                }
            case .bottom:
                if state == .expanded {
                    expansionConstraint.constant = 0.0
                } else {
                    expansionConstraint.constant = expansionOffset
                }
            }
        }
    }
    
    var expansionConstraint: NSLayoutConstraint!
    
    var initialOffset: CGFloat = 0.0
    
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
        
        setupConstraints(superview)
    }
    
    public typealias CompletionHandler = (_ completed: Bool) -> Void
    
    func setupConstraints(_ superview: UIView) {
        if expansionConstraint != nil {
            NSLayoutConstraint.deactivate([expansionConstraint])
        }
        
        switch type {
        case .top:
            expansionConstraint = topAnchor.constraint(equalTo: superview.topAnchor)
        case .bottom:
            expansionConstraint = bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        }
        
        if isExpandable {
            if state == .expanded {
                expansionConstraint.constant = 0.0
            } else {
                switch type {
                case .top:
                    expansionConstraint.constant = -expansionOffset
                case .bottom:
                    expansionConstraint.constant = expansionOffset
                }
            }
            
            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPan))
            addGestureRecognizer(panGestureRecognizer)
        } else {
            expansionConstraint.constant = 0.0
        }
        
        expansionConstraint.isActive = true
    }
    
    @objc func didPan(_ recognizer: UIPanGestureRecognizer) {
        guard let view = recognizer.view else { return }
        
        if recognizer.state == .began {
            initialOffset = expansionConstraint.constant
        }
        
        let translation = recognizer.translation(in: view)
        let currentOffset = initialOffset + translation.y
        
        switch type {
        case .top:
            if currentOffset < -expansionOffset {
                expansionConstraint.constant = -expansionOffset
            } else if currentOffset > expansionOffset {
                expansionConstraint.constant = 0.0
            } else {
                expansionConstraint.constant = currentOffset
            }
        case .bottom:
            if currentOffset < 0.0 {
                expansionConstraint.constant = 0.0
            } else if currentOffset > expansionOffset {
                expansionConstraint.constant = expansionOffset
            } else {
                expansionConstraint.constant = currentOffset
            }
        }
        
        if recognizer.state == .ended {
            let velocity = recognizer.velocity(in: view)
            
            switch type {
            case .top:
                if velocity.y >= 0 {
                    state = .expanded
                } else {
                    state = .collapsed
                }
            case .bottom:
                if velocity.y <= 0 {
                    state = .expanded
                } else {
                    state = .collapsed
                }
            }
            
            UIView.animate(withDuration: 0.2,
                           delay: 0.0,
                           options: [.allowUserInteraction],
                           animations: {
                self.superview?.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    public func show(animated: Bool = true,
                     duration: TimeInterval = 0.2,
                     animations: (() -> Void)? = nil,
                     completion: CompletionHandler? = nil) {
        guard isHidden else {
            completion?(true)
            return
        }
        
        if let superview = superview, expansionConstraint == nil {
            switch type {
            case .top:
                expansionConstraint = topAnchor.constraint(equalTo: superview.topAnchor)
            case .bottom:
                expansionConstraint = bottomAnchor.constraint(equalTo: superview.bottomAnchor)
            }
            
            expansionConstraint.isActive = true
        }
        
        if animated {
            // TODO: Improve animation for devices with notch.
            switch type {
            case .top:
                expansionConstraint.constant = -frame.height //+ self.topSafeAreaInset
            case .bottom:
                expansionConstraint.constant = frame.height //- self.bottomSafeAreaInset
            }
            
            isHidden = false
            superview?.layoutIfNeeded()
            
            UIView.animate(withDuration: duration,
                           delay: 0.0,
                           options: [],
                           animations: {
                animations?()
                
                self.expansionConstraint.constant = 0.0
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
                     duration: TimeInterval = 0.2,
                     animations: (() -> Void)? = nil,
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
                animations?()
                
                switch self.type {
                case .top:
                    self.expansionConstraint.constant = -self.frame.height
                case .bottom:
                    self.expansionConstraint.constant = self.frame.height
                }
                
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
