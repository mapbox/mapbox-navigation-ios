import UIKit

// :nodoc:
public enum BannerPosition {
    case topLeading
    case bottomLeading
}

// :nodoc:
@objc(MBBannerContainerView)
open class BannerContainerView: UIView {
    
    var position: BannerPosition
    
    // :nodoc:
    public enum State {
        case expanded
        case collapsed
    }
    
    // :nodoc:
    public var isExpandable: Bool = false {
        didSet {
            guard let superview = superview else { return }
            setupConstraints(superview)
        }
    }
    
    // :nodoc:
    public var expansionOffset: CGFloat = 0.0
    
    // :nodoc:
    public private(set) var state: State = .collapsed {
        didSet {
            delegate?.bannerContainerView(self, stateWillChangeTo: state)
            
            if oldValue == state { return }
            
            switch position {
            case .topLeading:
                if state == .expanded {
                    expansionConstraint.constant = 0.0
                } else {
                    expansionConstraint.constant = -expansionOffset
                }
            case .bottomLeading:
                if state == .expanded {
                    expansionConstraint.constant = 0.0
                } else {
                    expansionConstraint.constant = expansionOffset
                }
            }
            
            delegate?.bannerContainerView(self, stateDidChangeTo: state)
        }
    }
    
    var expansionConstraint: NSLayoutConstraint!
    
    var initialOffset: CGFloat = 0.0
    
    // :nodoc:
    public weak var delegate: BannerContainerViewDelegate? {
        didSet {
            delegate?.bannerContainerView(self, stateDidChangeTo: state)
        }
    }
    
    // :nodoc:
    public init(_ position: BannerPosition, frame: CGRect = .zero) {
        self.position = position
        
        super.init(frame: frame)
        
        defer {
            state = .collapsed
        }
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        guard let superview = superview else { return }
        
        setupConstraints(superview)
    }
    
    // :nodoc:
    public typealias CompletionHandler = (_ completed: Bool) -> Void
    
    func setupConstraints(_ superview: UIView) {
        if expansionConstraint != nil {
            NSLayoutConstraint.deactivate([expansionConstraint])
        }
        
        switch position {
        case .topLeading:
            expansionConstraint = topAnchor.constraint(equalTo: superview.topAnchor)
        case .bottomLeading:
            expansionConstraint = bottomAnchor.constraint(equalTo: superview.bottomAnchor)
        }
        
        if isExpandable {
            if state == .expanded {
                expansionConstraint.constant = 0.0
            } else {
                switch position {
                case .topLeading:
                    expansionConstraint.constant = -expansionOffset
                case .bottomLeading:
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
        
        switch position {
        case .topLeading:
            if currentOffset < -expansionOffset {
                expansionConstraint.constant = -expansionOffset
            } else if currentOffset > expansionOffset {
                expansionConstraint.constant = 0.0
            } else {
                expansionConstraint.constant = currentOffset
            }
        case .bottomLeading:
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
            
            switch position {
            case .topLeading:
                if velocity.y >= 0.0 {
                    state = .expanded
                } else {
                    state = .collapsed
                }
            case .bottomLeading:
                if velocity.y <= 0.0 {
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
        
        let currentExpansionOffset = expansionConstraint.constant
        let maximumExpansionOffset = expansionOffset
        let expansionFranction = 1 - currentExpansionOffset / maximumExpansionOffset
        
        delegate?.bannerContainerView(self, didExpandTo: expansionFranction)
    }
    
    // :nodoc:
    public func show(animated: Bool = true,
                     duration: TimeInterval = 0.2,
                     animations: (() -> Void)? = nil,
                     completion: CompletionHandler? = nil) {
        guard isHidden else {
            completion?(true)
            return
        }
        
        if let superview = superview, expansionConstraint == nil {
            switch position {
            case .topLeading:
                expansionConstraint = topAnchor.constraint(equalTo: superview.topAnchor)
            case .bottomLeading:
                expansionConstraint = bottomAnchor.constraint(equalTo: superview.bottomAnchor)
            }
            
            expansionConstraint.isActive = true
        }
        
        setNeedsLayout()
        layoutIfNeeded()
        
        if animated {
            // TODO: Improve animation for devices with notch.
            switch position {
            case .topLeading:
                expansionConstraint.constant = -frame.height //+ safeAreaInsets.top
            case .bottomLeading:
                expansionConstraint.constant = frame.height //- safeAreaInsets.bottom
            }
            
            isHidden = false
            superview?.layoutIfNeeded()
            
            UIView.animate(withDuration: duration,
                           delay: 0.0,
                           options: [],
                           animations: { [weak self] in
                guard let self = self else { return }
                
                animations?()
                
                if self.isExpandable {
                    self.expansionConstraint.constant = self.expansionOffset
                } else {
                    self.expansionConstraint.constant = 0.0
                }
                
                self.superview?.layoutIfNeeded()
            }) { completed in
                completion?(completed)
            }
        } else {
            isHidden = false
            completion?(true)
        }
    }
    
    // :nodoc:
    public func hide(animated: Bool = true,
                     duration: TimeInterval = 0.2,
                     animations: (() -> Void)? = nil,
                     completion: CompletionHandler? = nil) {
        guard !isHidden else {
            state = .collapsed
            completion?(true)
            return
        }
        
        if animated {
            UIView.animate(withDuration: duration,
                           delay: 0.0,
                           options: [],
                           animations: { [weak self] in
                guard let self = self else { return }
                
                animations?()
                
                switch self.position {
                case .topLeading:
                    self.expansionConstraint.constant = -self.frame.height
                case .bottomLeading:
                    self.expansionConstraint.constant = self.frame.height
                }
                
                self.superview?.layoutIfNeeded()
            }) { [weak self] completed in
                guard let self = self else { return }
                
                self.isHidden = true
                self.state = .collapsed
                completion?(completed)
            }
        } else {
            isHidden = true
            state = .collapsed
            completion?(true)
        }
    }
}
