import Foundation
import MapboxCoreNavigation
import MapboxDirections

class TopBannerViewController: ContainerViewController, InstructionsBannerViewDelegate {
    
    var delegate: Any? = nil

    lazy var topPaddingView: TopBannerView = .forAutoLayout()

    lazy var informationStackView = UIStackView(orientation: .vertical, autoLayout: true)
    
    lazy var instructionsBannerView: InstructionsBannerView = {
        let banner: InstructionsBannerView = .forAutoLayout()
        banner.delegate = self
        return banner
    }()
    
    lazy var lanesView: LanesView = .forAutoLayout(hidden: true)
    lazy var nextBannerView: NextBannerView = .forAutoLayout(hidden: true)
    lazy var statusView: StatusView = {
        let view: StatusView = .forAutoLayout()
        //        view.delegate = delegate // TODO: Sim Speed
        view.isHidden = true
        return view
    }()
    
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    func commonInit() {
        view.backgroundColor = .clear
        setupViews()
        addConstraints()
        setupInformationStackView()
    }
    
    
    
    private func setupViews() {
        topPaddingView.accessibilityIdentifier = "topPaddingView"
        let children = [topPaddingView, informationStackView]
        children.forEach(view.addSubview(_:))
    }
    
    private func addConstraints() {
        addTopPaddingConstraints()
        addStackConstraints()
    }
    
    private func addTopPaddingConstraints() {
        let top = topPaddingView.topAnchor.constraint(equalTo: view.topAnchor)
        let leading = topPaddingView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor)
        let trailing = topPaddingView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor)
        let bottom = topPaddingView.bottomAnchor.constraint(equalTo: view.safeTopAnchor)
        
        NSLayoutConstraint.activate([top, leading, trailing, bottom])
    }
    
    private func addStackConstraints() {
        let top = informationStackView.topAnchor.constraint(equalTo: view.safeTopAnchor)
        let leading = informationStackView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor)
        let trailing = informationStackView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor)
        let bottom = informationStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        
        NSLayoutConstraint.activate([top, leading, trailing, bottom])
    }
    
    private func setupInformationStackView() {
        let children = [instructionsBannerView, lanesView, nextBannerView, statusView]
        informationStackView.addArrangedSubviews(children)
        for child in children {
            child.leadingAnchor.constraint(equalTo: informationStackView.leadingAnchor).isActive = true
            child.trailingAnchor.constraint(equalTo: informationStackView.trailingAnchor).isActive = true
        }
    }
    
    func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        instructionsBannerView.updateDistance(for: progress.currentLegProgress.currentStepProgress)
        
    }
    
    func navigationService(_ service: NavigationService, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress) {
        instructionsBannerView.update(for: instruction)
        lanesView.update(for: instruction)
        nextBannerView.update(for: instruction)
    }
    
    func navigationService(_ service: NavigationService, willRerouteFrom location: CLLocation) {
        let title = NSLocalizedString("REROUTING", bundle: .mapboxNavigation, value: "Rerouting…", comment: "Indicates that rerouting is in progress")
        lanesView.hide()
        statusView.show(title, showSpinner: true)
    }
    
    func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        instructionsBannerView.updateDistance(for: service.routeProgress.currentLegProgress.currentStepProgress)
    }
    
    func navigationService(_ service: NavigationService, willBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        guard reason == .manual else { return }
        let localized = String.Localized.simulationStatus(speed: 1)
        statusView.show(localized, showSpinner: false, interactive: true)
    }
    
    func navigationService(_ service: NavigationService, willEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        guard reason == .manual else { return }
        statusView.hide(delay: 0, animated: true)
    }
}
