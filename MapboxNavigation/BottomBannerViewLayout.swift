import UIKit

extension BottomBannerViewController {
    
    func setupRootViews() {

        [bottomBannerView, bottomPaddingView].forEach(view.addSubview(_:))
        setupRootViewConstraints()
    }
    
    func setupRootViewConstraints() {
        let constraints = [
        bottomBannerView.topAnchor.constraint(equalTo: view.topAnchor),
        bottomBannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        bottomBannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        bottomBannerView.bottomAnchor.constraint(equalTo: bottomPaddingView.topAnchor),
        
        bottomPaddingView.topAnchor.constraint(equalTo: view.safeBottomAnchor),
        bottomPaddingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        bottomPaddingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        bottomPaddingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    func setupBottomBanner() {
        
        let timeRemainingLabel = TimeRemainingLabel()
        timeRemainingLabel.translatesAutoresizingMaskIntoConstraints = false
        timeRemainingLabel.font = .systemFont(ofSize: 28, weight: .medium)
        bottomBannerView.addSubview(timeRemainingLabel)
        self.timeRemainingLabel = timeRemainingLabel
        
        let distanceRemainingLabel = DistanceRemainingLabel()
        distanceRemainingLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceRemainingLabel.font = .systemFont(ofSize: 18, weight: .medium)
        bottomBannerView.addSubview(distanceRemainingLabel)
        self.distanceRemainingLabel = distanceRemainingLabel
        
        let arrivalTimeLabel = ArrivalTimeLabel()
        arrivalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        bottomBannerView.addSubview(arrivalTimeLabel)
        self.arrivalTimeLabel = arrivalTimeLabel
        
        let cancelButton = CancelButton(type: .custom)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.setImage(UIImage(named: "close", in: .mapboxNavigation, compatibleWith: nil), for: .normal)
        bottomBannerView.addSubview(cancelButton)
        self.cancelButton = cancelButton
        
        let verticalDivider = SeparatorView()
        verticalDivider.translatesAutoresizingMaskIntoConstraints = false
        bottomBannerView.addSubview(verticalDivider)
        self.verticalDividerView = verticalDivider
        
        let horizontalDividerView = SeparatorView()
        horizontalDividerView.translatesAutoresizingMaskIntoConstraints = false
        bottomBannerView.addSubview(horizontalDividerView)
        self.horizontalDividerView = horizontalDividerView
        
        setupConstraints()
    }
    
    fileprivate func setupConstraints() {
        setupVerticalCompactLayout(&verticalCompactConstraints)
        setupVerticalRegularLayout(&verticalRegularConstraints)
    }
    
    fileprivate func setupVerticalCompactLayout(_ c: inout [NSLayoutConstraint]) {
        c.append(bottomBannerView.heightAnchor.constraint(equalToConstant: 50))
        
        c.append(cancelButton.widthAnchor.constraint(equalTo: bottomBannerView.heightAnchor))
        c.append(cancelButton.topAnchor.constraint(equalTo: bottomBannerView.topAnchor))
        c.append(cancelButton.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor))
        c.append(cancelButton.bottomAnchor.constraint(equalTo: bottomBannerView.bottomAnchor))
        
        c.append(timeRemainingLabel.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor, constant: 10))
        c.append(timeRemainingLabel.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor))
        
        c.append(distanceRemainingLabel.leadingAnchor.constraint(equalTo: timeRemainingLabel.trailingAnchor, constant: 10))
        c.append(distanceRemainingLabel.lastBaselineAnchor.constraint(equalTo: timeRemainingLabel.lastBaselineAnchor))
        
        c.append(verticalDividerView.widthAnchor.constraint(equalToConstant: 1))
        c.append(verticalDividerView.heightAnchor.constraint(equalToConstant: 40))
        c.append(verticalDividerView.centerYAnchor.constraint(equalTo: bottomBannerView.centerYAnchor))
        c.append(verticalDividerView.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor))
        
        c.append(horizontalDividerView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale))
        c.append(horizontalDividerView.topAnchor.constraint(equalTo: bottomBannerView.topAnchor))
        c.append(horizontalDividerView.leadingAnchor.constraint(equalTo:bottomBannerView.leadingAnchor))
        c.append(horizontalDividerView.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor))
        
        c.append(arrivalTimeLabel.trailingAnchor.constraint(equalTo: verticalDividerView.leadingAnchor, constant: -10))
        c.append(arrivalTimeLabel.centerYAnchor.constraint(equalTo: cancelButton.centerYAnchor))
    }
    
    fileprivate func setupVerticalRegularLayout(_ c: inout [NSLayoutConstraint]) {
        c.append(bottomBannerView.heightAnchor.constraint(equalToConstant: 80))
        
        c.append(timeRemainingLabel.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor, constant: 10))
        c.append(timeRemainingLabel.lastBaselineAnchor.constraint(equalTo: bottomBannerView.centerYAnchor, constant: 0))
        
        c.append(distanceRemainingLabel.leadingAnchor.constraint(equalTo: timeRemainingLabel.leadingAnchor))
        c.append(distanceRemainingLabel.topAnchor.constraint(equalTo: timeRemainingLabel.bottomAnchor, constant: 0))
        
        c.append(cancelButton.widthAnchor.constraint(equalToConstant: 80))
        c.append(cancelButton.topAnchor.constraint(equalTo: bottomBannerView.topAnchor))
        c.append(cancelButton.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor))
        c.append(cancelButton.bottomAnchor.constraint(equalTo: bottomBannerView.bottomAnchor))
        
        c.append(verticalDividerView.widthAnchor.constraint(equalToConstant: 1))
        c.append(verticalDividerView.heightAnchor.constraint(equalToConstant: 40))
        c.append(verticalDividerView.centerYAnchor.constraint(equalTo: bottomBannerView.centerYAnchor))
        c.append(verticalDividerView.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor))
        
        c.append(horizontalDividerView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale))
        c.append(horizontalDividerView.topAnchor.constraint(equalTo: bottomBannerView.topAnchor))
        c.append(horizontalDividerView.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor))
        c.append(horizontalDividerView.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor))
        
        c.append(arrivalTimeLabel.centerYAnchor.constraint(equalTo: bottomBannerView.centerYAnchor))
        c.append(arrivalTimeLabel.trailingAnchor.constraint(equalTo: verticalDividerView.leadingAnchor, constant: -10))
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        verticalCompactConstraints.forEach { $0.isActive = traitCollection.verticalSizeClass == .compact }
        verticalRegularConstraints.forEach { $0.isActive = traitCollection.verticalSizeClass != .compact }
    }
}
