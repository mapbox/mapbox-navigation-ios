import UIKit
import MapboxCoreNavigation
import MapboxDirections

class LanesContainerView: LanesView {
    var stackView: UIStackView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func laneArrowView() -> LaneArrowView {
        let view = LaneArrowView(frame: CGRect(origin: .zero, size: CGSize(width: 30, height: 30)))
        view.backgroundColor = .clear
        return view
    }
    
    func commonInit() {
        stackView = UIStackView(arrangedSubviews: [])
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[stackView]-0-|", options: [], metrics: nil, views: ["stackView": stackView]))
        addConstraint(NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: stackView, attribute: .centerX, multiplier: 1, constant: 0))
    }
    
    func updateLaneViews(step: RouteStep, alertLevel: AlertLevel) {
        clearLaneViews()
        
        if let allLanes = step.intersections?.first?.approachLanes,
            let usableLanes = step.intersections?.first?.usableApproachLanes,
            (alertLevel == .high || alertLevel == .medium) {
            
            for (i, lane) in allLanes.enumerated() {
                let laneView = laneArrowView()
                laneView.lane = lane
                laneView.maneuverDirection = step.maneuverDirection
                laneView.isValid = usableLanes.contains(i as Int)
                stackView.addArrangedSubview(laneView)
            }
        }
    }
    
    fileprivate func clearLaneViews() {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
    }
}
