import UIKit

extension BottomBannerView {
    
    //MARK: - View Setup
    func setupViews() {
        let timeRemainingLabel = TimeRemainingLabel()
        timeRemainingLabel.translatesAutoresizingMaskIntoConstraints = false
        timeRemainingLabel.font = .systemFont(ofSize: 28, weight: .medium)
        addSubview(timeRemainingLabel)
        self.timeRemainingLabel = timeRemainingLabel
        
        let distanceRemainingLabel = DistanceRemainingLabel()
        distanceRemainingLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceRemainingLabel.font = .systemFont(ofSize: 18, weight: .medium)
        addSubview(distanceRemainingLabel)
        self.distanceRemainingLabel = distanceRemainingLabel
        
        let arrivalTimeLabel = ArrivalTimeLabel()
        arrivalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(arrivalTimeLabel)
        self.arrivalTimeLabel = arrivalTimeLabel
        
        if isShowingCancelButton { addCancelButton() }
        updateLayout()
    }
    
    func addCancelButton() {
        let cancelButton = CancelButton(type: .custom)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setImage(UIImage(named: "close", in: .mapboxNavigation, compatibleWith: nil), for: .normal)
        addSubview(cancelButton)
        self.cancelButton = cancelButton
        
        let dividerView = SeparatorView()
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dividerView)
        self.dividerView = dividerView
    }
    
    func removeCancelButton() {
        let views: [UIView?] = [cancelButton, dividerView]
        views.forEach { (view) in
            view?.willMove(toSuperview: nil)
            view?.removeFromSuperview()
        }
    
        cancelButton = nil
        dividerView = nil
    }
    
    //MARK: - Computed Constraint Properties
    fileprivate var commonConstraints: [NSLayoutConstraint] {
        let constraints = [
            timeRemainingLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 10),
        ]
        return constraints
    }
    
    fileprivate var commonCompactConstraints: [NSLayoutConstraint] {
        let constraints = [
        heightAnchor.constraint(equalToConstant: 50),
        distanceRemainingLabel.leftAnchor.constraint(equalTo: timeRemainingLabel.rightAnchor, constant: 10),
        distanceRemainingLabel.lastBaselineAnchor.constraint(equalTo: timeRemainingLabel.lastBaselineAnchor),
        timeRemainingLabel.centerYAnchor.constraint(equalTo: cancelButton?.centerYAnchor ?? centerYAnchor)
        ]
        return constraints + commonConstraints
    }
    
    fileprivate var commonRegularConstraints: [NSLayoutConstraint] {
        let constraints = [
        heightAnchor.constraint(equalToConstant: 80),
        timeRemainingLabel.lastBaselineAnchor.constraint(equalTo: centerYAnchor, constant: 0),
        distanceRemainingLabel.leftAnchor.constraint(equalTo: timeRemainingLabel.leftAnchor),
        distanceRemainingLabel.topAnchor.constraint(equalTo: timeRemainingLabel.bottomAnchor, constant: 0)
        ]
        timeRemainingLabel.setContentCompressionResistancePriority(UILayoutPriority.required, for: .vertical)
        return constraints + commonConstraints
    }
    
    fileprivate var cancelButtonShowConstraints: [NSLayoutConstraint] {
        let constraints = [
            cancelButton!.widthAnchor.constraint(equalTo: heightAnchor),
            cancelButton!.topAnchor.constraint(equalTo: topAnchor),
            cancelButton!.rightAnchor.constraint(equalTo: rightAnchor),
            cancelButton!.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            dividerView!.widthAnchor.constraint(equalToConstant: 1),
            dividerView!.heightAnchor.constraint(equalToConstant: 40),
            dividerView!.centerYAnchor.constraint(equalTo: centerYAnchor),
            dividerView!.rightAnchor.constraint(equalTo: cancelButton!.leftAnchor),
            arrivalTimeLabel.rightAnchor.constraint(equalTo: dividerView!.leftAnchor, constant: -10),
            arrivalTimeLabel.centerYAnchor.constraint(equalTo: cancelButton!.centerYAnchor)
        ]
        return constraints
    }
    
    fileprivate var cancelButtonHideConstraints: [NSLayoutConstraint] {
        let constraints = [
            arrivalTimeLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -10),
            arrivalTimeLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]
        return constraints
    }
    
    //MARK: - Utility Methods
    func layoutConstraints(for traits: UITraitCollection, showingButton show: Bool) -> [NSLayoutConstraint] {
        let buttonConstraints = show ? cancelButtonShowConstraints : cancelButtonHideConstraints
        
        switch traits.verticalSizeClass {
        case .compact:
                return commonCompactConstraints + buttonConstraints
            default:
                return commonRegularConstraints + buttonConstraints
        
        }
    }
    
    func updateLayout(with traitCollection: UITraitCollection? = nil, showingButton: Bool? = nil) {
        let traits = traitCollection ?? self.traitCollection
        let isShowing = showingButton ?? isShowingCancelButton
        
        let newConstraints = layoutConstraints(for: traits, showingButton: isShowing)
        constraints.active.deactivate()
        newConstraints.activate()
    }
    
    //MARK: - UITraitEnvironment
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateLayout(with: traitCollection)
    }
}
