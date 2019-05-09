import Foundation
import MapboxCoreNavigation
import MapboxDirections


@objc protocol TopBannerViewControllerDelegate: StatusViewDelegate {
    @objc optional func topBanner(_ banner: TopBannerViewController, didSwipeInDirection direction: UISwipeGestureRecognizer.Direction)

}

@objc open class TopBannerViewController: ContainerViewController, StatusViewDelegate {
    
    weak var delegate: TopBannerViewControllerDelegate? = nil {
        didSet {
            statusView.delegate = delegate
        }
    }

    lazy var topPaddingView: TopBannerView = .forAutoLayout()

    lazy var informationStackView = UIStackView(orientation: .vertical, autoLayout: true)
    
    lazy var instructionsBannerView: InstructionsBannerView = {
        let banner: InstructionsBannerView = .forAutoLayout()
        banner.delegate = self
        banner.swipeable = true
        return banner
    }()
    
    lazy var lanesView: LanesView = .forAutoLayout(hidden: true)
    lazy var nextBannerView: NextBannerView = .forAutoLayout(hidden: true)
    lazy var statusView: StatusView = {
        let view: StatusView = .forAutoLayout()
        view.delegate = delegate
        view.isHidden = true
        return view
    }()
    
    public var isDisplayingPreviewInstructions: Bool {
        return previewInstructionsView != nil
    }
    
    private(set) public var isDisplayingSteps: Bool = false
    
    private(set) var previewSteps: [RouteStep]?
    private(set) var currentPreviewStep: (RouteStep, Int)?
    
    private(set) var previewInstructionsView: StepInstructionsView?

    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }
    
    convenience init(delegate: TopBannerViewControllerDelegate) {
        self.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        statusView.delegate = delegate
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
    
    public func displayStepsTable() {
        
    }
    
    public func dismissStepsTable() {
        
    }
    
    public func preview(step stepOverride: RouteStep? = nil, maneuverStep: RouteStep, distance: CLLocationDistance, steps: [RouteStep]) {
        guard !steps.isEmpty, let step = stepOverride ?? steps.first, let index = steps.index(of: step) else {
            return // do nothing if there are no steps provided to us.
        }
        //this must happen before the preview steps are set
        stopPreviewing()
        
        previewSteps = steps
        currentPreviewStep = (step, index)
        
        
        
        guard let instructions = step.instructionsDisplayedAlongStep?.last else { return }
        
        let instructionsView = StepInstructionsView(frame: instructionsBannerView.frame)
        let backgroundColor = StepInstructionsView.appearance().backgroundColor
        topPaddingView.backgroundColor = backgroundColor
        instructionsView.backgroundColor = backgroundColor
        instructionsView.delegate = self
        instructionsView.distance = distance
        instructionsView.swipeable = true
        informationStackView.removeArrangedSubview(instructionsBannerView)
        instructionsBannerView.removeFromSuperview()
        informationStackView.insertArrangedSubview(instructionsView, at: 0)
        instructionsView.update(for: instructions)
        previewInstructionsView = instructionsView
    }
    
    public func stopPreviewing() {
        guard let view = previewInstructionsView else {
            return
        }
        
        previewSteps = nil
        currentPreviewStep = nil
        
        informationStackView.removeArrangedSubview(view)
        view.removeFromSuperview()
        informationStackView.insertArrangedSubview(instructionsBannerView, at: 0)
        topPaddingView.backgroundColor = InstructionsBannerView.appearance().backgroundColor
        
        instructionsBannerView.delegate = self
        instructionsBannerView.swipeable = true
        previewInstructionsView = nil
    }
}

// MARK: - NavigationComponent Conformance
extension TopBannerViewController /* NavigationComponent */ {
    public func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        instructionsBannerView.updateDistance(for: progress.currentLegProgress.currentStepProgress)
        
    }
    
    public func navigationService(_ service: NavigationService, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress) {
        instructionsBannerView.update(for: instruction)
        lanesView.update(for: instruction)
        nextBannerView.update(for: instruction)
    }
    
    public func navigationService(_ service: NavigationService, willRerouteFrom location: CLLocation) {
        let title = NSLocalizedString("REROUTING", bundle: .mapboxNavigation, value: "Rerouting…", comment: "Indicates that rerouting is in progress")
        lanesView.hide()
        statusView.show(title, showSpinner: true)
    }
    
    public func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        instructionsBannerView.updateDistance(for: service.routeProgress.currentLegProgress.currentStepProgress)
    }
    
    public func navigationService(_ service: NavigationService, willBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        guard reason == .manual else { return }
        let localized = String.Localized.simulationStatus(speed: 1)
        statusView.show(localized, showSpinner: false, interactive: true)
    }
    
    public func navigationService(_ service: NavigationService, willEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        guard reason == .manual else { return }
        statusView.hide(delay: 0, animated: true)
    }
    
    public func navigationViewController(_ controller: NavigationViewController, didRecenterAt location: CLLocation) {
        stopPreviewing()
    }
}

// MARK: InstructionsBannerViewDelegate Conformance
extension TopBannerViewController: InstructionsBannerViewDelegate {
    public func didSwipeInstructionsBanner(_ sender: BaseInstructionsBannerView, swipeDirection direction: UISwipeGestureRecognizer.Direction) {
        delegate?.topBanner?(self, didSwipeInDirection: direction)
    }
}
