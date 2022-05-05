import UIKit

extension BottomBannerViewController {
    
    func setupBottomBanner() {
        let children = [bottomBannerView, bottomPaddingView]
        view.addSubviews(children)
        
        let timeRemainingLabel: TimeRemainingLabel = .forAutoLayout()
        bottomBannerView.addSubview(timeRemainingLabel)
        self.timeRemainingLabel = timeRemainingLabel
        
        let distanceRemainingLabel: DistanceRemainingLabel = .forAutoLayout()
        bottomBannerView.addSubview(distanceRemainingLabel)
        self.distanceRemainingLabel = distanceRemainingLabel
        
        let arrivalTimeLabel: ArrivalTimeLabel = .forAutoLayout()
        bottomBannerView.addSubview(arrivalTimeLabel)
        self.arrivalTimeLabel = arrivalTimeLabel
        
        let cancelButton = CancelButton(type: .system)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.clipsToBounds = true
        cancelButton.imageView?.contentMode = .scaleAspectFit
        cancelButton.imageEdgeInsets = UIEdgeInsets(top: 12.0,
                                                    left: 0.0,
                                                    bottom: 12.0,
                                                    right: 0.0)
        
        let dismissImage = UIImage(named: "dismiss", in: .mapboxNavigation, compatibleWith: nil)
        cancelButton.setImage(dismissImage, for: .normal)
        cancelButton.addTarget(self,
                               action: #selector(BottomBannerViewController.cancel(_:)),
                               for: .touchUpInside)
        bottomBannerView.addSubview(cancelButton)
        self.cancelButton = cancelButton
        
        // TODO: Consider deprecation of vertical divider view.
        let verticalDividerView: SeparatorView = .forAutoLayout()
        bottomBannerView.addSubview(verticalDividerView)
        verticalDividerView.isHidden = true
        self.verticalDividerView = verticalDividerView
        
        let horizontalDividerView: SeparatorView = .forAutoLayout()
        bottomBannerView.addSubview(horizontalDividerView)
        self.horizontalDividerView = horizontalDividerView
        
        let grabberView: GrabberView = .forAutoLayout()
        grabberView.backgroundColor = #colorLiteral(red: 0.804, green: 0.816, blue: 0.816, alpha: 1)
        grabberView.cornerRadius = 2.5
        bottomBannerView.addSubview(grabberView)
        self.grabberView = grabberView
        
        let destinationLabel: DestinationLabel = .forAutoLayout()
        destinationLabel.normalTextColor = #colorLiteral(red: 0.216, green: 0.212, blue: 0.454, alpha: 1)
        destinationLabel.normalFont = UIFont.systemFont(ofSize: 18.0)
        destinationLabel.numberOfLines = 1
        bottomBannerView.addSubview(destinationLabel)
        self.destinationLabel = destinationLabel
        
        setupRootViewConstraints()
        setupConstraints()
    }
    
    func setupRootViewConstraints() {
        let constraints = [
            bottomBannerView.topAnchor.constraint(equalTo: view.topAnchor),
            bottomBannerView.bottomAnchor.constraint(equalTo: bottomPaddingView.topAnchor),
            bottomBannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            bottomPaddingView.topAnchor.constraint(equalTo: view.safeBottomAnchor),
            bottomPaddingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomPaddingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPaddingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    fileprivate func setupConstraints() {
        setupVerticalCompactLayout(&verticalCompactConstraints)
        setupVerticalRegularLayout(&verticalRegularConstraints)
        reinstallConstraints()
    }
    
    fileprivate func setupVerticalCompactLayout(_ layoutConstraints: inout [NSLayoutConstraint]) {
        let bottomBannerViewHeight = 150.0 + view.safeAreaInsets.bottom
        layoutConstraints.append(view.heightAnchor.constraint(equalToConstant: bottomBannerViewHeight))
        
        layoutConstraints.append(timeRemainingLabel.heightAnchor.constraint(equalToConstant: 30.0))
        layoutConstraints.append(timeRemainingLabel.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor,
                                                                             constant: 10.0))
        layoutConstraints.append(timeRemainingLabel.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor,
                                                                              constant: -10.0))
        layoutConstraints.append(timeRemainingLabel.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                                                         constant: 20.0))
        
        layoutConstraints.append(distanceRemainingLabel.heightAnchor.constraint(equalToConstant: 25.0))
        layoutConstraints.append(distanceRemainingLabel.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor,
                                                                                 constant: 10.0))
        layoutConstraints.append(distanceRemainingLabel.topAnchor.constraint(equalTo: timeRemainingLabel.bottomAnchor,
                                                                             constant: 0.0))
        
        layoutConstraints.append(arrivalTimeLabel.heightAnchor.constraint(equalToConstant: 25.0))
        layoutConstraints.append(arrivalTimeLabel.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor,
                                                                            constant: -10.0))
        layoutConstraints.append(arrivalTimeLabel.leadingAnchor.constraint(equalTo: distanceRemainingLabel.trailingAnchor,
                                                                           constant: 10.0))
        layoutConstraints.append(arrivalTimeLabel.topAnchor.constraint(equalTo: timeRemainingLabel.bottomAnchor,
                                                                       constant: 0.0))
        
        layoutConstraints.append(cancelButton.widthAnchor.constraint(equalToConstant: 70.0))
        layoutConstraints.append(cancelButton.heightAnchor.constraint(equalToConstant: 50.0))
        layoutConstraints.append(cancelButton.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor,
                                                                        constant: -10.0))
        layoutConstraints.append(cancelButton.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                                                   constant: 20.0))
        
        layoutConstraints.append(verticalDividerView.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale))
        layoutConstraints.append(verticalDividerView.topAnchor.constraint(equalTo: bottomBannerView.topAnchor, constant: 10))
        layoutConstraints.append(verticalDividerView.bottomAnchor.constraint(equalTo: bottomBannerView.bottomAnchor, constant: -10))
        layoutConstraints.append(verticalDividerView.centerYAnchor.constraint(equalTo: bottomBannerView.centerYAnchor))
        layoutConstraints.append(verticalDividerView.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor))
        
        layoutConstraints.append(horizontalDividerView.heightAnchor.constraint(equalToConstant: 2.0))
        layoutConstraints.append(horizontalDividerView.topAnchor.constraint(equalTo: distanceRemainingLabel.bottomAnchor,
                                                                            constant: 5.0))
        layoutConstraints.append(horizontalDividerView.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor,
                                                                                constant: 10.0))
        layoutConstraints.append(horizontalDividerView.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor,
                                                                                 constant: -10.0))
        
        layoutConstraints.append(grabberView.widthAnchor.constraint(equalToConstant: 75))
        layoutConstraints.append(grabberView.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                                                  constant: 7.5))
        layoutConstraints.append(grabberView.centerXAnchor.constraint(equalTo: bottomBannerView.centerXAnchor))
        layoutConstraints.append(grabberView.heightAnchor.constraint(equalToConstant: 5.0))
        
        layoutConstraints.append(destinationLabel.topAnchor.constraint(equalTo: horizontalDividerView.bottomAnchor,
                                                                       constant: 10.0))
        layoutConstraints.append(destinationLabel.heightAnchor.constraint(equalToConstant: 25.0))
        layoutConstraints.append(destinationLabel.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor,
                                                                           constant: 10.0))
        layoutConstraints.append(destinationLabel.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor,
                                                                            constant: -10.0))
    }
    
    fileprivate func setupVerticalRegularLayout(_ layoutConstraints: inout [NSLayoutConstraint]) {
        let bottomBannerViewHeight = 150.0 + view.safeAreaInsets.bottom
        layoutConstraints.append(view.heightAnchor.constraint(equalToConstant: bottomBannerViewHeight))
        
        layoutConstraints.append(timeRemainingLabel.heightAnchor.constraint(equalToConstant: 30.0))
        layoutConstraints.append(timeRemainingLabel.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor,
                                                                             constant: 10.0))
        layoutConstraints.append(timeRemainingLabel.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor,
                                                                              constant: -10.0))
        layoutConstraints.append(timeRemainingLabel.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                                                         constant: 20.0))
        
        layoutConstraints.append(distanceRemainingLabel.heightAnchor.constraint(equalToConstant: 25.0))
        layoutConstraints.append(distanceRemainingLabel.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor,
                                                                                 constant: 10.0))
        layoutConstraints.append(distanceRemainingLabel.topAnchor.constraint(equalTo: timeRemainingLabel.bottomAnchor,
                                                                             constant: 0.0))
        
        layoutConstraints.append(arrivalTimeLabel.heightAnchor.constraint(equalToConstant: 25.0))
        layoutConstraints.append(arrivalTimeLabel.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor,
                                                                            constant: -10.0))
        layoutConstraints.append(arrivalTimeLabel.leadingAnchor.constraint(equalTo: distanceRemainingLabel.trailingAnchor,
                                                                           constant: 10.0))
        layoutConstraints.append(arrivalTimeLabel.topAnchor.constraint(equalTo: timeRemainingLabel.bottomAnchor,
                                                                       constant: 0.0))
        
        layoutConstraints.append(cancelButton.widthAnchor.constraint(equalToConstant: 70.0))
        layoutConstraints.append(cancelButton.heightAnchor.constraint(equalToConstant: 50.0))
        layoutConstraints.append(cancelButton.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor,
                                                                        constant: -10.0))
        layoutConstraints.append(cancelButton.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                                                   constant: 20.0))
        
        layoutConstraints.append(cancelButton.widthAnchor.constraint(equalToConstant: 70.0))
        layoutConstraints.append(cancelButton.heightAnchor.constraint(equalToConstant: 50.0))
        layoutConstraints.append(cancelButton.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor,
                                                                        constant: -10.0))
        layoutConstraints.append(cancelButton.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                                                   constant: 20.0))
        
        layoutConstraints.append(verticalDividerView.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale))
        layoutConstraints.append(verticalDividerView.topAnchor.constraint(equalTo: bottomBannerView.topAnchor, constant: 10))
        layoutConstraints.append(verticalDividerView.bottomAnchor.constraint(equalTo: bottomBannerView.bottomAnchor, constant: -10))
        layoutConstraints.append(verticalDividerView.centerYAnchor.constraint(equalTo: bottomBannerView.centerYAnchor))
        layoutConstraints.append(verticalDividerView.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor))
        
        layoutConstraints.append(horizontalDividerView.heightAnchor.constraint(equalToConstant: 2.0))
        layoutConstraints.append(horizontalDividerView.topAnchor.constraint(equalTo: distanceRemainingLabel.bottomAnchor,
                                                                            constant: 5.0))
        layoutConstraints.append(horizontalDividerView.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor,
                                                                                constant: 10.0))
        layoutConstraints.append(horizontalDividerView.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor,
                                                                                 constant: -10.0))
        
        layoutConstraints.append(grabberView.widthAnchor.constraint(equalToConstant: 75))
        layoutConstraints.append(grabberView.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                                                  constant: 7.5))
        layoutConstraints.append(grabberView.centerXAnchor.constraint(equalTo: bottomBannerView.centerXAnchor))
        layoutConstraints.append(grabberView.heightAnchor.constraint(equalToConstant: 5.0))
        
        layoutConstraints.append(destinationLabel.topAnchor.constraint(equalTo: horizontalDividerView.bottomAnchor,
                                                                       constant: 10.0))
        layoutConstraints.append(destinationLabel.heightAnchor.constraint(equalToConstant: 25.0))
        layoutConstraints.append(destinationLabel.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor,
                                                                           constant: 10.0))
        layoutConstraints.append(destinationLabel.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor,
                                                                            constant: -10.0))
    }
    
    open func reinstallConstraints() {
        NSLayoutConstraint.deactivate(verticalCompactConstraints)
        NSLayoutConstraint.deactivate(verticalRegularConstraints)
        
        verticalCompactConstraints.forEach { $0.isActive = traitCollection.verticalSizeClass == .compact }
        verticalRegularConstraints.forEach { $0.isActive = traitCollection.verticalSizeClass == .regular }
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
            setupConstraints()
        }
    }
}
