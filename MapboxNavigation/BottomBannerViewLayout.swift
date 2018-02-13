import UIKit

extension BottomBannerView {
    
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
        
        let cancelButton = CancelButton(type: .custom)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setImage(UIImage(named: "close", in: .mapboxNavigation, compatibleWith: nil), for: .normal)
        addSubview(cancelButton)
        self.cancelButton = cancelButton
        
        let dividerView = SeparatorView()
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dividerView)
        self.dividerView = dividerView
        
        setupConstraints()
    }
    
    fileprivate func setupConstraints() {
        setupVerticalCompactLayout(&verticalCompactConstraints)
        setupVerticalRegularLayout(&verticalRegularConstraints)
    }
    
    fileprivate func setupVerticalCompactLayout(_ c: inout [NSLayoutConstraint]) {
        c.append(heightAnchor.constraint(equalToConstant: 50))
        
        c.append(cancelButton.widthAnchor.constraint(equalTo: heightAnchor))
        c.append(cancelButton.topAnchor.constraint(equalTo: topAnchor))
        c.append(cancelButton.rightAnchor.constraint(equalTo: rightAnchor))
        c.append(cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor))
        
        c.append(timeRemainingLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 10))
        c.append(timeRemainingLabel.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor))
        
        c.append(distanceRemainingLabel.leftAnchor.constraint(equalTo: timeRemainingLabel.rightAnchor, constant: 10))
        c.append(distanceRemainingLabel.lastBaselineAnchor.constraint(equalTo: timeRemainingLabel.lastBaselineAnchor))
        
        c.append(dividerView.widthAnchor.constraint(equalToConstant: 1))
        c.append(dividerView.heightAnchor.constraint(equalToConstant: 40))
        c.append(dividerView.centerYAnchor.constraint(equalTo: centerYAnchor))
        c.append(dividerView.rightAnchor.constraint(equalTo: cancelButton.leftAnchor))
        
        c.append(arrivalTimeLabel.rightAnchor.constraint(equalTo: dividerView.leftAnchor, constant: -10))
        c.append(arrivalTimeLabel.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor))
    }
    
    fileprivate func setupVerticalRegularLayout(_ c: inout [NSLayoutConstraint]) {
        c.append(heightAnchor.constraint(equalToConstant: 80))
        
        c.append(timeRemainingLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 10))
        c.append(timeRemainingLabel.lastBaselineAnchor.constraint(equalTo: centerYAnchor, constant: 0))
        
        c.append(distanceRemainingLabel.leftAnchor.constraint(equalTo: timeRemainingLabel.leftAnchor))
        c.append(distanceRemainingLabel.topAnchor.constraint(equalTo: timeRemainingLabel.bottomAnchor, constant: 0))
        
        c.append(cancelButton.widthAnchor.constraint(equalToConstant: 80))
        c.append(cancelButton.topAnchor.constraint(equalTo: topAnchor))
        c.append(cancelButton.rightAnchor.constraint(equalTo: rightAnchor))
        c.append(cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor))
        
        c.append(dividerView.widthAnchor.constraint(equalToConstant: 1))
        c.append(dividerView.heightAnchor.constraint(equalToConstant: 40))
        c.append(dividerView.centerYAnchor.constraint(equalTo: centerYAnchor))
        c.append(dividerView.rightAnchor.constraint(equalTo: cancelButton.leftAnchor))
        
        c.append(arrivalTimeLabel.centerYAnchor.constraint(equalTo: centerYAnchor))
        c.append(arrivalTimeLabel.rightAnchor.constraint(equalTo: dividerView.leftAnchor, constant: -10))
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        verticalCompactConstraints.forEach { $0.isActive = traitCollection.verticalSizeClass == .compact }
        verticalRegularConstraints.forEach { $0.isActive = traitCollection.verticalSizeClass != .compact }
    }
}
