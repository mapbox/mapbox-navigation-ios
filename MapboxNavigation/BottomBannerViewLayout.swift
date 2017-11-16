import UIKit

extension BottomBannerView {
    
    func setupViews() {
        
        let timeRemainingLabel = TimeRemainingLabel()
        timeRemainingLabel.translatesAutoresizingMaskIntoConstraints = false
        timeRemainingLabel.font = .systemFont(ofSize: 28, weight: UIFontWeightMedium)
        addSubview(timeRemainingLabel)
        self.timeRemainingLabel = timeRemainingLabel
        
        let distanceRemainingLabel = DistanceRemainingLabel()
        distanceRemainingLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceRemainingLabel.font = .systemFont(ofSize: 18, weight: UIFontWeightMedium)
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
    }
    
    func setupLayout() {
        timeRemainingLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 10).isActive = true
        timeRemainingLabel.lastBaselineAnchor.constraint(equalTo: centerYAnchor, constant: 0).isActive = true
        
        distanceRemainingLabel.leftAnchor.constraint(equalTo: timeRemainingLabel.leftAnchor).isActive = true
        distanceRemainingLabel.topAnchor.constraint(equalTo: timeRemainingLabel.bottomAnchor, constant: 0).isActive = true
        
        cancelButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        cancelButton.topAnchor.constraint(equalTo: topAnchor).isActive = true
        cancelButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        dividerView.widthAnchor.constraint(equalToConstant: 1).isActive = true
        dividerView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        dividerView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        dividerView.rightAnchor.constraint(equalTo: cancelButton.leftAnchor).isActive = true
        
        arrivalTimeLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        arrivalTimeLabel.rightAnchor.constraint(equalTo: dividerView.leftAnchor, constant: -10).isActive = true
    }
}

