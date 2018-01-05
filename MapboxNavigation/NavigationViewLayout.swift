import UIKit

extension NavigationView {
    
    func setupViews() {
        let mapView = NavigationMapView(frame: .zero)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mapView)
        self.mapView = mapView
        
        let wayNameLabel = WayNameLabel()
        wayNameLabel.textInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        wayNameLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(wayNameLabel)
        self.wayNameLabel = wayNameLabel
        
        let bottomBannerContentView = BottomBannerContentView()
        bottomBannerContentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomBannerContentView)
        self.bottomBannerContentView = bottomBannerContentView
        
        let bottomBannerView = BottomBannerView()
        bottomBannerView.translatesAutoresizingMaskIntoConstraints = false
        bottomBannerContentView.addSubview(bottomBannerView)
        self.bottomBannerView = bottomBannerView
        
        let instructionsBannerContentView = InstructionsBannerContentView()
        instructionsBannerContentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(instructionsBannerContentView)
        self.instructionsBannerContentView = instructionsBannerContentView
        
        let instructionsBannerView = InstructionsBannerView()
        instructionsBannerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(instructionsBannerView)
        self.instructionsBannerView = instructionsBannerView
        
        setupConstraints()
    }
    
    func setupConstraints() {
        mapView.topAnchor.constraint(equalTo: instructionsBannerView.bottomAnchor).isActive = true
        mapView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: bottomBannerContentView.topAnchor).isActive = true
        mapView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        instructionsBannerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        instructionsBannerView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        instructionsBannerView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        instructionsBannerView.heightAnchor.constraint(equalToConstant: 96).isActive = true
        
        bottomBannerContentView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        bottomBannerContentView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        bottomBannerContentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        bottomBannerContentView.topAnchor.constraint(equalTo: bottomBannerView.topAnchor).isActive = true
        
        bottomBannerView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        bottomBannerView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        bottomBannerView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        bottomBannerView.bottomAnchor.constraint(equalTo: safeBottomAnchor).isActive = true
        
        wayNameLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        wayNameLabel.bottomAnchor.constraint(equalTo: bottomBannerView.topAnchor, constant: -10).isActive = true
    }
}

