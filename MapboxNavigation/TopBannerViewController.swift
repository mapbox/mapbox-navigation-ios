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
    
    lazy var stepsContainer: UIView = .forAutoLayout()
    var stepsViewController: StepsViewController?
    
    var routeProgress: RouteProgress?
    
    lazy var stepsContainerConstraints: [NSLayoutConstraint] = {
       let constraints = [
        stepsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        stepsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        return constraints
    }()
    
    lazy var stepsContainerShow: [NSLayoutConstraint] = {
        let constraints = [
        stepsContainer.topAnchor.constraint(equalTo: instructionsBannerView.bottomAnchor),
        view.bottomAnchor.constraint(equalTo: self.parent!.view.bottomAnchor),
        view.bottomAnchor.constraint(equalTo: stepsContainer.bottomAnchor)
        ]
        return constraints
    }()
    
    lazy var stepsContainerHide: [NSLayoutConstraint] = {
       let constraints = [
        stepsContainer.bottomAnchor.constraint(equalTo: instructionsBannerView.topAnchor),
        informationStackBottomPin
        ]
        return constraints
    }()
    
    lazy var informationStackBottomPin: NSLayoutConstraint = view.bottomAnchor.constraint(equalTo: informationStackView.bottomAnchor)

    lazy var informationStackView = UIStackView(orientation: .vertical, autoLayout: true)
    
    lazy var instructionsBannerView: InstructionsBannerView = {
        let banner: InstructionsBannerView = .forAutoLayout()
        banner.heightAnchor.constraint(equalToConstant: 100.0).isActive = true
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
    
    
    private var informationChildren: [UIView] {
        return [instructionsBannerView] + secondaryChildren
    }
    private var secondaryChildren: [UIView] {
        return  [lanesView, nextBannerView, statusView]
    }
    
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
        let children = [stepsContainer, topPaddingView, informationStackView]
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
        let bottom = informationStackBottomPin
        
        NSLayoutConstraint.activate([top, leading, trailing, bottom])
    }
    
    private func setupInformationStackView() {
        
        informationStackView.addArrangedSubviews(informationChildren)
        for child in informationChildren {
            child.leadingAnchor.constraint(equalTo: informationStackView.leadingAnchor).isActive = true
            child.trailingAnchor.constraint(equalTo: informationStackView.trailingAnchor).isActive = true
        }
    }
    
    public func displayStepsTable() {
        dismissStepsTable()
        
        guard let progress = routeProgress, let parent = parent else {
            return
        }
        
        let controller = StepsViewController(routeProgress: progress)
        controller.delegate = self
        
        embed(controller, in: stepsContainer) { (parent, child) -> [NSLayoutConstraint] in
            child.view.translatesAutoresizingMaskIntoConstraints = false
            let pinningConstraints = child.view.constraintsForPinning(to: self.stepsContainer)
            let hideConstraints = self.stepsContainerHide
            
            return pinningConstraints + hideConstraints + self.stepsContainerConstraints
        }
        stepsViewController = controller
        
        parent.view.layoutIfNeeded()
        
    
        
        
        
 
        
        
        let stepsInAnimation = {
            NSLayoutConstraint.deactivate(self.stepsContainerHide)
            NSLayoutConstraint.activate(self.stepsContainerShow)
            
            UIView.animate(withDuration: 0.35, delay: 0.0, options: [.curveEaseOut], animations: parent.view.layoutIfNeeded)
        }
        UIView.animate(withDuration: 0.20, delay: 0.0, options: [.curveEaseIn], animations: {
            for child in self.secondaryChildren {
                child.alpha = 0.0
            }
        }) { _ in
            stepsInAnimation()
            for child in self.secondaryChildren {
                child.isHidden = true
            }
        }
        
        
    }
    
    public func dismissStepsTable() {
        guard let parent = parent, let steps = stepsViewController  else { return }
        parent.view.layoutIfNeeded()
        
        statusView.isHidden = !statusView.isCurrentlyVisible
        lanesView.isHidden = !lanesView.isCurrentlyVisible
        nextBannerView.isHidden = !nextBannerView.isCurrentlyVisible
        
        let secondaryChildrenInAnimation = {
            UIView.animate(withDuration: 0.20, delay: 0.0, options: [.curveEaseOut], animations: {
                for child in self.informationChildren {
                    child.alpha = 1.0
                }
            })
        }

        NSLayoutConstraint.deactivate(stepsContainerShow)
        NSLayoutConstraint.activate(stepsContainerHide)
        
        UIView.animate(withDuration: 0.35, delay: 0.0, options: [.curveEaseInOut], animations: parent.view.layoutIfNeeded, completion: { _ in
            secondaryChildrenInAnimation()
            self.stepsViewController = nil
            steps.dismiss()
        })
        

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
        routeProgress = progress
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
        
        dismissStepsTable()
        if service.simulationMode == .always {
            let localized = String.Localized.simulationStatus(speed: Int(service.simulationSpeedMultiplier))
            statusView.showStatus(title: localized, for: .infinity, animated: true, interactive: true)
        } else {
            statusView.hide(delay: 2, animated: true)
        }
        
        if (proactive) {
            let title = NSLocalizedString("FASTER_ROUTE_FOUND", bundle: .mapboxNavigation, value: "Faster Route Found", comment: "Indicates a faster route was found")
            statusView.showStatus(title: title, withSpinner: true, for: 3)
        }
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
    
    private func embed(_ child: UIViewController, in container: UIView, constrainedBy constraints: ((UIViewController, UIViewController) -> [NSLayoutConstraint])? = nil) {
        child.willMove(toParent: self)
        addChild(child)
        container.addSubview(child.view)
        if let childConstraints: [NSLayoutConstraint] = constraints?(self, child) {
            view.addConstraints(childConstraints)
        }
        child.didMove(toParent: self)
    }
}

// MARK: InstructionsBannerViewDelegate Conformance
extension TopBannerViewController: InstructionsBannerViewDelegate {
    public func didTapInstructionsBanner(_ sender: BaseInstructionsBannerView) {
        if isDisplayingSteps {
            dismissStepsTable()
        } else {
            displayStepsTable()
        }
        
        if currentPreviewStep != nil {
            //TODO: FIX ME -- RECENTER(self)
        }
    }
    
    public func didSwipeInstructionsBanner(_ sender: BaseInstructionsBannerView, swipeDirection direction: UISwipeGestureRecognizer.Direction) {
        delegate?.topBanner?(self, didSwipeInDirection: direction)
    }
}

extension TopBannerViewController: StepsViewControllerDelegate {
    public func stepsViewController(_ viewController: StepsViewController, didSelect legIndex: Int, stepIndex: Int, cell: StepTableViewCell) {
        
    }
    public func didDismissStepsViewController(_ viewController: StepsViewController) {
        dismissStepsTable()
        instructionsBannerView.showStepIndicator = true
    }
}
