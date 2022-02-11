import CoreLocation
import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxDirections

/**
 A view controller that displays the current maneuver instruction as a “banner” flush with the edges of the containing view. The user swipes to one side to preview a subsequent maneuver.
 
 This class is the default top banner view controller used by `NavigationOptions` and `NavigationViewController`. `InstructionsCardViewController` provides an alternative, user notification–like interface.
 */
open class TopBannerViewController: UIViewController {
    
    // MARK: Displaying Instructions
    
    weak var delegate: TopBannerViewControllerDelegate? = nil
    
    lazy var topPaddingView: TopBannerView = .forAutoLayout()
    
    var routeProgress: RouteProgress?
    
    lazy var informationStackBottomPinConstraint: NSLayoutConstraint = view.bottomAnchor.constraint(equalTo: informationStackView.bottomAnchor)
    
    lazy var informationStackView = UIStackView(orientation: .vertical, autoLayout: true)
    
    lazy var instructionsBannerView: InstructionsBannerView = {
        let banner: InstructionsBannerView = .forAutoLayout()
        banner.heightAnchor.constraint(equalToConstant: instructionsBannerHeight).isActive = true
        banner.delegate = self
        banner.swipeable = true
        return banner
    }()
    
    /**
     A view that contains one or more images indicating which lanes of road the user should take to complete the maneuver.
     */
    public var lanesView: LanesView = .forAutoLayout(hidden: true)
    
    /**
     A view that indicates the instruction for next step.
     */
    public var nextBannerView: NextBannerView = .forAutoLayout(hidden: true)
    
    /**
     A translucent bar that indicates the navigation status.
     */
    public var statusView: StatusView = .forAutoLayout(hidden: true)
    
    /**
     A view that indicates the layout of a highway junction.
     */
    public var junctionView: JunctionView = .forAutoLayout(hidden: true)
    
    private let instructionsBannerHeight: CGFloat = 100.0
    
    private var informationChildren: [UIView] {
        return [instructionsBannerView] + secondaryChildren
    }
    private var secondaryChildren: [UIView] {
        return [lanesView, nextBannerView, statusView, junctionView]
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override open func viewDidLoad() {
        view.backgroundColor = .clear
        super.viewDidLoad()
        setupViews()
        addConstraints()
        setupInformationStackView()
    }
    
    private func setupViews() {
        let children = [stepsContainer, topPaddingView, informationStackView]
        view.addSubviews(children)
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
        let leading = informationStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let trailing = informationStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let bottom = informationStackBottomPinConstraint
        //bottom is taken care of as part of steps TVC show/hide
        
        NSLayoutConstraint.activate([top, leading, trailing, bottom])
    }
    
    private func setupInformationStackView() {
        addInstructionsBanner()
        informationStackView.addArrangedSubviews(secondaryChildren)
        for child in informationChildren {
            child.leadingAnchor.constraint(equalTo: informationStackView.leadingAnchor).isActive = true
            child.trailingAnchor.constraint(equalTo: informationStackView.trailingAnchor).isActive = true
        }
    }
    
    
    private func showSecondaryChildren(completion: CompletionHandler? = nil) {
        statusView.isHidden = !statusView.isCurrentlyVisible
        junctionView.isHidden = !junctionView.isCurrentlyVisible
        lanesView.isHidden = !lanesView.isCurrentlyVisible
        nextBannerView.isHidden = !nextBannerView.isCurrentlyVisible
        
        UIView.animate(withDuration: 0.20, delay: 0.0, options: [.curveEaseOut], animations: { [weak self] in
            guard let children = self?.informationChildren else {
                return
            }
            
            for child in children {
                child.alpha = 1.0
            }
        }, completion: { _ in
            completion?()
        })
    }
    
    private func hideSecondaryChildren(completion: CompletionHandler? = nil) {
        UIView.animate(withDuration: 0.20, delay: 0.0, options: [.curveEaseIn], animations: { [weak self] in
            guard let children = self?.secondaryChildren else {
                return
            }
            
            for child in children {
                child.alpha = 0.0
            }
        }) { [weak self] _ in
            completion?()
            guard let children = self?.secondaryChildren else {
                return
            }
            
            for child in children {
                child.isHidden = true
            }
        }
    }
    
    private func addInstructionsBanner() {
        informationStackView.insertArrangedSubview(instructionsBannerView, at: 0)
        instructionsBannerView.delegate = self
        instructionsBannerView.swipeable = true
    }
    
    // MARK: Previewing Steps
    
    public var isDisplayingPreviewInstructions: Bool {
        return previewInstructionsView != nil
    }
    
    private(set) var previewSteps: [RouteStep]?
    private(set) var currentPreviewStep: (RouteStep, Int)?
    
    private(set) var previewInstructionsView: StepInstructionsView?
    
    public func preview(step stepOverride: RouteStep? = nil, maneuverStep: RouteStep, distance: CLLocationDistance, steps: [RouteStep], completion: CompletionHandler? = nil) {
        guard !steps.isEmpty, let step = stepOverride ?? steps.first, let index = steps.firstIndex(of: step) else {
            return // do nothing if there are no steps provided to us.
        }
        //this must happen before the preview steps are set
        stopPreviewing(showingSecondaryChildren: false)
        
        previewSteps = steps
        currentPreviewStep = (step, index)
        
        guard let instructions = step.instructionsDisplayedAlongStep?.last else { return }
        
        let instructionsView = StepInstructionsView(frame: instructionsBannerView.frame)
        instructionsView.heightAnchor.constraint(equalToConstant: instructionsBannerHeight).isActive = true
        
        instructionsView.delegate = self
        instructionsView.distance = distance
        instructionsView.swipeable = true
        informationStackView.removeArrangedSubview(instructionsBannerView)
        instructionsBannerView.removeFromSuperview()
        informationStackView.insertArrangedSubview(instructionsView, at: 0)
        instructionsView.update(for: instructions)
        previewInstructionsView = instructionsView
        
        hideSecondaryChildren(completion: completion)
    }
    
    public func stopPreviewing(showingSecondaryChildren: Bool = true) {
        guard let view = previewInstructionsView else {
            return
        }
        
        previewSteps = nil
        currentPreviewStep = nil
        
        informationStackView.removeArrangedSubview(view)
        view.removeFromSuperview()
        addInstructionsBanner()
        previewInstructionsView = nil
        
        if showingSecondaryChildren {
            showSecondaryChildren()
        }
    }
    
    // MARK: Viewing Steps the Table
    
    lazy var stepsContainer: UIView = .forAutoLayout()
    var stepsViewController: StepsViewController?
    
    lazy var stepsContainerConstraints: [NSLayoutConstraint] = {
        let constraints = [
            stepsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stepsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        return constraints
    }()
    
    lazy var stepsContainerShowConstraints: [NSLayoutConstraint] = {
        let constraints = [
            stepsContainer.topAnchor.constraint(equalTo: informationStackView.bottomAnchor),
            view.bottomAnchor.constraint(equalTo: self.parent!.view.bottomAnchor),
            view.bottomAnchor.constraint(equalTo: stepsContainer.bottomAnchor)
        ]
        return constraints
    }()
    
    lazy var stepsContainerHideConstraints: [NSLayoutConstraint] = {
        let constraints = [
            stepsContainer.bottomAnchor.constraint(equalTo: informationStackView.topAnchor),
            informationStackBottomPinConstraint
        ]
        return constraints
    }()
    
    private(set) public var isDisplayingSteps: Bool = false
    
    public func displayStepsTable() {
        dismissStepsTable()
        
        guard let progress = routeProgress, let parent = parent else {
            return
        }
        
        let controller = StepsViewController(routeProgress: progress)
        controller.delegate = self

        var stepsHeightPresizingConstraint: NSLayoutConstraint? = nil
        
        delegate?.topBanner(self, willDisplayStepsController: controller)
        embed(controller, in: stepsContainer) { (parent, child) -> [NSLayoutConstraint] in
            child.view.translatesAutoresizingMaskIntoConstraints = false
            
            let pinningConstraints = child.view.constraintsForPinning(to: self.stepsContainer)
            let hideConstraints = self.stepsContainerHideConstraints

            var constraints = pinningConstraints + hideConstraints + self.stepsContainerConstraints
            
            if let bannerHostHeight = self.view.superview?.superview?.frame.height {
                let inset = self.instructionsBannerHeight + self.view.safeArea.top
                stepsHeightPresizingConstraint = (child.view.heightAnchor.constraint(equalToConstant: bannerHostHeight - inset))
                constraints.append(stepsHeightPresizingConstraint!)
            }
            
            return constraints
        }
        stepsViewController = controller
        isDisplayingSteps = true
        
        parent.view.layoutIfNeeded()
        view.isUserInteractionEnabled = false
        
        let stepsInAnimation = {
            NSLayoutConstraint.deactivate(self.stepsContainerHideConstraints)
            stepsHeightPresizingConstraint?.isActive = false
            NSLayoutConstraint.activate(self.stepsContainerShowConstraints)
            
            let finally: (Bool) -> Void = { [weak self] _ in
                guard let self = self else {
                    return
                }
                
                self.view.isUserInteractionEnabled = true
                self.delegate?.topBanner(self, didDisplayStepsController: controller)
            }
            
            UIView.animate(withDuration: 0.35, delay: 0.0, options: [.curveEaseOut], animations: parent.view.layoutIfNeeded, completion: finally)
        }
        
        hideSecondaryChildren(completion: stepsInAnimation)
    }
    
    public func dismissStepsTable(completion: CompletionHandler? = nil) {
        guard let parent = parent, let steps = stepsViewController else { return }
        parent.view.layoutIfNeeded()
        
        delegate?.topBanner(self, willDismissStepsController: steps)
        
        NSLayoutConstraint.deactivate(stepsContainerShowConstraints)
        NSLayoutConstraint.activate(stepsContainerHideConstraints)
        
        let complete = { [weak self] in
            guard let self = self else {
                return
            }
            
            self.view.isUserInteractionEnabled = true
            self.delegate?.topBanner(self, didDismissStepsController: steps)
            completion?()
        }
        
        view.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.35, delay: 0.0, options: [.curveEaseInOut], animations: parent.view.layoutIfNeeded) { [weak self] _ in
            guard let self = self else {
                return
            }
            
            if !self.isDisplayingPreviewInstructions {
                self.showSecondaryChildren(completion: complete)
            } else {
                complete()
            }
            
            self.isDisplayingSteps = false
            steps.dismiss()
            self.stepsViewController = nil
        }
    }
}

// MARK: - NavigationComponent Conformance
extension TopBannerViewController: NavigationComponent {
    public func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        routeProgress = progress
        instructionsBannerView.updateDistance(for: progress.currentLegProgress.currentStepProgress)
        
        if progress.remainingSteps.count < 2 {
            if isDisplayingPreviewInstructions {
                stopPreviewing(showingSecondaryChildren: false)
            }
            if isDisplayingSteps {
                dismissStepsTable()
            }
            instructionsBannerView.showStepIndicator = false
        } else {
            instructionsBannerView.showStepIndicator = true
        }
    }
    
    public func navigationService(_ service: NavigationService, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress) {
        instructionsBannerView.update(for: instruction)
        lanesView.update(for: instruction)
        nextBannerView.navigationService(service, didPassVisualInstructionPoint: instruction, routeProgress: routeProgress)
        junctionView.update(for: instruction, service: service)
    }
    
    public func navigationService(_ service: NavigationService, willRerouteFrom location: CLLocation) {
        let title = NSLocalizedString("REROUTING", bundle: .mapboxNavigation, value: "Rerouting…", comment: "Indicates that rerouting is in progress")
        lanesView.hide()
        let reroutingStatus = StatusView.Status(identifier: "REROUTING", title: title, duration: 20, priority: 0)
        show(reroutingStatus)
    }
    
    public func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        instructionsBannerView.updateDistance(for: service.routeProgress.currentLegProgress.currentStepProgress)
        
        dismissStepsTable()
        if service.simulationMode == .always {
            statusView.showSimulationStatus(speed: Int(service.simulationSpeedMultiplier))
        } else {
            statusView.hide(delay: 2, animated: true)
        }
        
        if (proactive) {
            let title = NSLocalizedString("FASTER_ROUTE_FOUND", bundle: .mapboxNavigation, value: "Faster Route Found", comment: "Indicates a faster route was found")
            
            // create faster route status and append to array of statuses
            let fasterRouteStatus = StatusView.Status(identifier: "FASTER_ROUTE_FOUND", title: title, duration: 3, priority: 0)
            statusView.show(fasterRouteStatus)
        }
    }
    
    public func navigationService(_ service: NavigationService, didBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        guard reason == .manual else { return }
        statusView.showSimulationStatus(speed: Int(service.simulationSpeedMultiplier))
    }
    
    public func navigationService(_ service: NavigationService, willEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        guard reason == .manual else { return }
        statusView.hide(delay: 0, animated: true)
    }
    
    private func embed(_ child: UIViewController, in container: UIView, constrainedBy constraints: ((UIViewController, UIViewController) -> [NSLayoutConstraint])? = nil) {
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
    }
    
    public func didSwipeInstructionsBanner(_ sender: BaseInstructionsBannerView, swipeDirection direction: UISwipeGestureRecognizer.Direction) {
        delegate?.topBanner(self, didSwipeInDirection: direction)
    }
    
    public func label(_ label: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString? {
        delegate?.label(label, willPresent: instruction, as: presented)
    }
}

extension TopBannerViewController: StepsViewControllerDelegate {
    public func stepsViewController(_ viewController: StepsViewController, didSelect legIndex: Int, stepIndex: Int, cell: StepTableViewCell) {
        delegate?.topBanner(self, didSelect: legIndex, stepIndex: stepIndex, cell: cell)
    }
    
    public func didDismissStepsViewController(_ viewController: StepsViewController) {
        dismissStepsTable()
        if let stepCount = routeProgress?.remainingSteps.count, stepCount > 1 {
            instructionsBannerView.showStepIndicator = true
        }
    }
}

extension TopBannerViewController: CarPlayConnectionObserver {
    public func didConnectToCarPlay() {
        displayStepsTable()
    }
    
    public func didDisconnectFromCarPlay() {
        dismissStepsTable()
    }
}

extension TopBannerViewController: NavigationStatusPresenter {
    public func show(_ status: StatusView.Status) {
        statusView.show(status)
    }
    
    public func hide(_ status: StatusView.Status) {
        statusView.hide(status)
    }
}

extension TopBannerViewController: NavigationMapInteractionObserver {
    public func navigationViewController(didCenterOn location: CLLocation) {
        stopPreviewing()
    }
}
