import UIKit
import MapboxCoreNavigation
import MapboxDirections

/// :nodoc:
@IBDesignable
open class LanesView: UIView, NavigationComponent {
    weak var stackView: UIStackView!
    weak var separatorView: SeparatorView!
    public var isCurrentlyVisible: Bool = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
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
    
    func laneArrowView() -> LaneView {
        let view = LaneView(frame: CGRect(origin: .zero, size: CGSize(width: 30, height: 30)))
        view.backgroundColor = .clear
        return view
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
        
        let separatorView = SeparatorView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorView)
        self.separatorView = separatorView
        
        stackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        stackView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        
        separatorView.heightAnchor.constraint(equalToConstant: 2).isActive = true
        separatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
    
    public func navigationService(_ service: NavigationService, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress) {
        update(for: instruction)
    }
    
    /**
     Updates the tertiary instructions banner info with a given `VisualInstructionBanner`.
     */
    public func update(for visualInstruction: VisualInstructionBanner?) {
        clearLaneViews()
        
        guard let tertiaryInstruction = visualInstruction?.tertiaryInstruction else {
            hide()
            return
        }
        
        let subviews = tertiaryInstruction.components.compactMap { (component) -> LaneView? in
            if case let .lane(indications: indications, isUsable: isUsable) = component {
                return LaneView(indications: indications, isUsable: isUsable)
            } else {
                return nil
            }
        }
        
        guard !subviews.isEmpty && subviews.contains(where: { !$0.isValid }) else {
            hide()
            return
        }
        
        stackView.addArrangedSubviews(subviews)
        show()
    }
    
    public func show(animated: Bool = true) {
        guard isHidden == true else { return }
        if animated {
            UIView.defaultAnimation(0.3, animations: {
                self.isCurrentlyVisible = true
                self.isHidden = false
            }, completion: nil)
        } else {
            self.isHidden = false
        }
    }
    
    public func hide() {
        guard isHidden == false else { return }
        UIView.defaultAnimation(0.3, animations: {
            self.isCurrentlyVisible = false
            self.isHidden = true
        }, completion: nil)
    }
    
    fileprivate func clearLaneViews() {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
}
