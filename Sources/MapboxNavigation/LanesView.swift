import UIKit
import MapboxCoreNavigation
import MapboxDirections

/// :nodoc:
@IBDesignable
open class LanesView: UIView, NavigationComponent {
    
    // MARK: Displaying the Lanes
    
    public var isCurrentlyVisible: Bool = false
    
    /**
     A vertical separator for the trailing side of the view.
     */
    var trailingSeparatorView: SeparatorView!
    
    /**
     A closure that is called after either presenting or dismissing lanes view.
     
     - parameter completed: Boolean value that indicates whether or not the animation actually
     finished before the completion handler was called.
     */
    public typealias CompletionHandler = (_ completed: Bool) -> Void
    
    /**
     Updates the tertiary instructions banner info with a given `VisualInstructionBanner`.
     
     - parameter visualInstruction: Current instruction, which will be displayed in the lanes view.
     - parameter animated: If `true`, lanes view presentation or dismissal is animated.
     - parameter duration: Duration of the animation (in seconds). In case if `animated` parameter
     is set to `false` this value is ignored.
     - parameter completion: A completion handler that will be called once lanes view is either shown or hidden.
     */
    public func update(for visualInstruction: VisualInstructionBanner?,
                       animated: Bool = true,
                       duration: TimeInterval = 0.5,
                       completion: CompletionHandler? = nil) {
        clearLaneViews()
        
        guard let tertiaryInstruction = visualInstruction?.tertiaryInstruction else {
            hide(animated: animated,
                 duration: duration) { completed in
                completion?(completed)
            }
            return
        }
        
        let subviews = tertiaryInstruction.components.compactMap { (component) -> LaneView? in
            if case let .lane(indications: indications,
                              isUsable: isUsable,
                              preferredDirection: preferredDirection) = component {
                let maneuverDirection = preferredDirection ?? visualInstruction?.primaryInstruction.maneuverDirection
                return LaneView(indications: indications,
                                isUsable: isUsable,
                                direction: maneuverDirection)
            } else {
                return nil
            }
        }
        
        guard !subviews.isEmpty && subviews.contains(where: { !$0.isValid }) else {
            hide(animated: animated,
                 duration: duration) { completed in
                completion?(completed)
            }
            return
        }
        
        stackView.addArrangedSubviews(subviews)
        show(animated: animated,
             duration: duration) { completed in
            completion?(completed)
        }
    }
    
    /**
     Shows lanes view.
     
     - parameter animated: If `true`, lanes view presentation is animated. Defaults to `true`.
     - parameter duration: Duration of the animation (in seconds). In case if `animated` parameter
     is set to `false` this value is ignored.
     - parameter completion: A completion handler that will be called once lanes view is shown.
     */
    public func show(animated: Bool = true,
                     duration: TimeInterval = 0.5,
                     completion: CompletionHandler? = nil) {
        guard isHidden else {
            completion?(true)
            return
        }
        
        if animated {
            UIView.defaultAnimation(duration, animations: {
                self.isCurrentlyVisible = true
                self.isHidden = false
            }) { completed in
                completion?(completed)
            }
        } else {
            isHidden = false
            completion?(true)
        }
    }
    
    /**
     Hides lanes view.
     
     - parameter animated: If `true`, lanes view dismissal is animated. Defaults to `true`.
     - parameter duration: Duration of the animation (in seconds). In case if `animated` parameter
     is set to `false` this value is ignored.
     - parameter completion: A completion handler that will be called after lanes view dismissal.
     */
    public func hide(animated: Bool = true,
                     duration: TimeInterval = 0.5,
                     completion: CompletionHandler? = nil) {
        guard !isHidden else {
            completion?(true)
            return
        }
        
        if animated {
            UIView.defaultAnimation(duration, animations: {
                self.isCurrentlyVisible = false
                self.isHidden = true
            }) { completed in
                completion?(completed)
            }
        } else {
            isHidden = true
            completion?(true)
        }
    }
    
    fileprivate func clearLaneViews() {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
    
    // MARK: NavigationComponent Implementation
    
    public func navigationService(_ service: NavigationService,
                                  didPassVisualInstructionPoint instruction: VisualInstructionBanner,
                                  routeProgress: RouteProgress) {
        update(for: instruction)
    }
    
    // MARK: View Display
    
    weak var stackView: UIStackView!
    weak var separatorView: SeparatorView!
    
    func laneArrowView() -> LaneView {
        let view = LaneView(frame: CGRect(origin: .zero, size: CGSize(width: 30, height: 30)))
        view.backgroundColor = .clear
        return view
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()

        for _ in 0...4 {
            let laneView = laneArrowView()
            stackView.addArrangedSubview(laneView)
        }
    }
    
    func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        
        let heightConstraint = heightAnchor.constraint(equalToConstant: 40)
        heightConstraint.priority = UILayoutPriority(rawValue: 999)
        heightConstraint.isActive = true
        
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.axis = .horizontal
        stackView.semanticContentAttribute = .spatial
        stackView.spacing = 4
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        self.stackView = stackView
        
        stackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        stackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        let separatorView = SeparatorView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorView)
        self.separatorView = separatorView
        
        separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        separatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        let trailingSeparatorView = SeparatorView()
        trailingSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(trailingSeparatorView)
        self.trailingSeparatorView = trailingSeparatorView
        
        trailingSeparatorView.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        trailingSeparatorView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        trailingSeparatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        trailingSeparatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection == traitCollection { return }
        
        // Do not show trailing separator view in case of regular layout.
        if traitCollection.verticalSizeClass == .regular {
            trailingSeparatorView.isHidden = true
        } else {
            trailingSeparatorView.isHidden = false
        }
    }
}
