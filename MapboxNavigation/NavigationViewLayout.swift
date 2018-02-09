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
        
        let floatingStackView = UIStackView()
        floatingStackView.axis = .vertical
        floatingStackView.distribution = .equalSpacing
        floatingStackView.spacing = 8
        floatingStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(floatingStackView)
        self.floatingStackView = floatingStackView
        
        let buttonSize = CGSize(width: 50, height: 50)
        
        let overviewButton = FloatingButton(type: .custom)
        overviewButton.translatesAutoresizingMaskIntoConstraints = false
        overviewButton.constrainedSize = buttonSize
        overviewButton.backgroundColor = .white
        overviewButton.setImage(UIImage(named: "overview", in: .mapboxNavigation, compatibleWith: nil), for: .normal)
        overviewButton.applyDefaultCornerRadiusShadow(cornerRadius: buttonSize.width / 2)
        floatingStackView.addArrangedSubview(overviewButton)
        self.overviewButton = overviewButton
        
        let muteButton = FloatingButton(type: .custom)
        muteButton.translatesAutoresizingMaskIntoConstraints = false
        muteButton.constrainedSize = buttonSize
        muteButton.backgroundColor = .white
        muteButton.setImage(UIImage(named: "volume_up", in: .mapboxNavigation, compatibleWith: nil), for: .normal)
        muteButton.applyDefaultCornerRadiusShadow(cornerRadius: buttonSize.width / 2)
        floatingStackView.addArrangedSubview(muteButton)
        self.muteButton = muteButton
        
        let reportButton = FloatingButton(type: .custom)
        reportButton.translatesAutoresizingMaskIntoConstraints = false
        reportButton.constrainedSize = buttonSize
        reportButton.backgroundColor = .white
        reportButton.setImage(UIImage(named: "feedback", in: .mapboxNavigation, compatibleWith: nil), for: .normal)
        reportButton.applyDefaultCornerRadiusShadow(cornerRadius: buttonSize.width / 2)
        floatingStackView.addArrangedSubview(reportButton)
        self.reportButton = reportButton
        
        let separatorView = SeparatorView(frame: .zero)
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorView)
        self.separatorView = separatorView
        
        let lanesView = LanesView(frame: .zero)
        informationStackView.addArrangedSubview(lanesView)
        self.lanesView = lanesView
        
        let nextBannerView = NextBannerView(frame: .zero)
        informationStackView.addArrangedSubview(nextBannerView)
        self.nextBannerView = nextBannerView
        
        let statusView = StatusView(frame: .zero)
        informationStackView.addArrangedSubview(statusView)
        self.statusView = statusView
        
        let resumeButton = ResumeButton(frame: .zero)
        resumeButton.translatesAutoresizingMaskIntoConstraints = false
        resumeButton.backgroundColor = .white
        addSubview(resumeButton)
        self.resumeButton = resumeButton
        
        let wayNameLabel = WayNameLabel()
        wayNameLabel.translatesAutoresizingMaskIntoConstraints = false
        wayNameLabel.clipsToBounds = true
        wayNameLabel.layer.borderWidth = 1.0 / UIScreen.main.scale
        addSubview(wayNameLabel)
        self.wayNameLabel = wayNameLabel
        
        let rerouteReportButton = ReportButton(type: .custom)
        rerouteReportButton.translatesAutoresizingMaskIntoConstraints = false
        rerouteReportButton.applyDefaultCornerRadiusShadow(cornerRadius: 4)
        rerouteReportButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        rerouteReportButton.setTitle(NSLocalizedString("REROUTE_REPORT_TITLE", bundle: .mapboxNavigation, value: "Report Problem", comment: "Title on button that appears when a reroute occurs"), for: .normal)
        addSubview(rerouteReportButton)
        self.rerouteReportButton = rerouteReportButton
        
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
        
        separatorView.topAnchor.constraint(equalTo: instructionsBannerView.bottomAnchor).isActive = true
        separatorView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        separatorView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        separatorView.heightAnchor.constraint(equalToConstant: 2).isActive = true

        informationStackView.topAnchor.constraint(equalTo: instructionsBannerView.bottomAnchor).isActive = true
        informationStackView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        informationStackView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        floatingStackView.topAnchor.constraint(equalTo: informationStackView.bottomAnchor, constant: 10).isActive = true
        floatingStackView.rightAnchor.constraint(equalTo: safeRightAnchor, constant: -10).isActive = true
        
        resumeButton.leftAnchor.constraint(equalTo: safeLeftAnchor, constant: 10).isActive = true
        resumeButton.bottomAnchor.constraint(equalTo: bottomBannerView.topAnchor, constant: -10).isActive = true
        
        rerouteReportButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        rerouteReportButton.topAnchor.constraint(equalTo: informationStackView.bottomAnchor, constant: 10).isActive = true
        
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
