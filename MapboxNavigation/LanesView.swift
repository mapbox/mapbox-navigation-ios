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
    
    func update(for currentLegProgress: RouteLegProgress) {
        guard let step = currentLegProgress.upComingStep else { return }
        guard !currentLegProgress.userHasArrivedAtWaypoint else { return }
        let durationRemaining = currentLegProgress.currentStepProgress.durationRemaining
        
        clearLaneViews()
        
        if let allLanes = step.intersections?.first?.approachLanes,
            let usableLanes = step.intersections?.first?.usableApproachLanes,
            durationRemaining < RouteControllerMediumAlertInterval {
            
            for (i, lane) in allLanes.enumerated() {
                let laneView = laneArrowView()
                laneView.lane = lane
                laneView.maneuverDirection = step.maneuverDirection
                laneView.isValid = usableLanes.contains(i as Int)
                stackView.addArrangedSubview(laneView)
            }
        }
        
        if stackView.arrangedSubviews.count > 0 {
            show()
        } else {
            hide()
        }
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
