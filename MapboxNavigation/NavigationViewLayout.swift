import UIKit

extension NavigationView {
    
    func setupViews() {
        let mapView = NavigationMapView(frame: .zero)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mapView)
        self.mapView = mapView
        
        let instructionsBannerContentView = InstructionsBannerContentView()
        instructionsBannerContentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(instructionsBannerContentView)
        self.instructionsBannerContentView = instructionsBannerContentView
        
        let instructionsBannerView = InstructionsBannerView()
        instructionsBannerView.translatesAutoresizingMaskIntoConstraints = false
        instructionsBannerContentView.addSubview(instructionsBannerView)
        self.instructionsBannerView = instructionsBannerView
        
        let informationStackView = UIStackView()
        informationStackView.axis = .vertical
        informationStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(informationStackView)
        self.informationStackView = informationStackView
        
        let lanesView = LanesView(frame: .zero)
        informationStackView.addArrangedSubview(lanesView)
        self.lanesView = lanesView
        
        let nextBannerView = NextBannerView(frame: .zero)
        informationStackView.addArrangedSubview(nextBannerView)
        self.nextBannerView = nextBannerView
        
        let statusView = StatusView(frame: .zero)
        informationStackView.addArrangedSubview(statusView)
        self.statusView = statusView
        
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
    }
    
    func setupConstraints() {
        mapView.topAnchor.constraint(equalTo: instructionsBannerView.bottomAnchor).isActive = true
        mapView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: bottomBannerContentView.topAnchor).isActive = true
        mapView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        instructionsBannerContentView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        instructionsBannerContentView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        instructionsBannerContentView.bottomAnchor.constraint(equalTo: instructionsBannerView.bottomAnchor).isActive = true
        instructionsBannerContentView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        instructionsBannerView.topAnchor.constraint(equalTo: safeTopAnchor).isActive = true
        instructionsBannerView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        instructionsBannerView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        instructionsBannerView.heightAnchor.constraint(equalToConstant: 96).isActive = true
        
        informationStackView.topAnchor.constraint(equalTo: instructionsBannerView.bottomAnchor).isActive = true
        informationStackView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        informationStackView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
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

