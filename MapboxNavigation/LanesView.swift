import UIKit
import MapboxCoreNavigation
import MapboxDirections

/// :nodoc:
@IBDesignable
@objc(MBLanesView)
open class LanesView: UIView {
    weak var stackView: UIStackView!
    weak var separatorView: SeparatorView!
    
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
    
    /**
     Updates the tertiary instructions banner info with a given `VisualInstructionBanner`.
     */
    @objc(updateForVisualInstructionBanner:)
    public func update(for visualInstruction: VisualInstructionBanner?) {
        clearLaneViews()
        
        guard let tertiaryInstruction = visualInstruction?.tertiaryInstruction,
                  tertiaryInstruction.containsLaneIndications else {
                    hide()
                    return
        }
        
        let laneIndications: [LaneIndicationComponent]? = tertiaryInstruction.components.compactMap({ $0 as? LaneIndicationComponent })
        
        guard let lanes = laneIndications, !lanes.isEmpty else {
            hide()
            return
        }
        
        let subviews = lanes.map { LaneView(component: $0) }
        stackView.addArrangedSubviews(subviews)
        show()
    }
    
    public func show(animated: Bool = true) {
        guard isHidden == true else { return }
        if animated {
            UIView.defaultAnimation(0.3, animations: {
                self.isHidden = false
            }, completion: nil)
        } else {
            self.isHidden = false
        }
    }
    
    public func hide() {
        guard isHidden == false else { return }
        UIView.defaultAnimation(0.3, animations: {
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
