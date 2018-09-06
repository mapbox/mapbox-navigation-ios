import UIKit
import MapboxDirections
import MapboxCoreNavigation
import Turf

@objc(MBStepsBackgroundView)
open class StepsBackgroundView: UIView { }


/**
 `StepsViewControllerDelegate` provides methods for user interactions in a `StepsViewController`.
 */
@objc public protocol StepsViewControllerDelegate: class {
    
    /**
     Called when the user selects a step in a `StepsViewController`.
     */
    @objc optional func stepsViewController(_ viewController: StepsViewController, didSelect legIndex: Int, stepIndex: Int, cell: StepTableViewCell)
    
    /**
     Called when the user dismisses the `StepsViewController`.
     */
    @objc func didDismissStepsViewController(_ viewController: StepsViewController)
}

/// :nodoc:
@objc(MBStepsViewController)
open class StepsViewController: UIViewController {
    
    weak var tableView: UITableView!
    weak var backgroundView: UIView!
    weak var bottomView: UIView!
    weak var separatorBottomView: SeparatorView!
    weak var dismissButton: DismissButton!
    public weak var delegate: StepsViewControllerDelegate?
    
    let cellId = "StepTableViewCellId"
    var routeProgress: RouteProgress!
    
    typealias StepSection = [RouteStep]
    var sections = [StepSection]()
    
    var previousLegIndex: Int = NSNotFound
    var previousStepIndex: Int = NSNotFound
    
    /**
     Initializes StepsViewController with a RouteProgress object.
     
     - parameter routeProgress: The user's current route progress.
     - SeeAlso: [RouteProgress](https://www.mapbox.com/mapbox-navigation-ios/navigation/0.14.1/Classes/RouteProgress.html)
     */
    public convenience init(routeProgress: RouteProgress) {
        self.init()
        self.routeProgress = routeProgress
    }
    
    @discardableResult
    func rebuildDataSourceIfNecessary() -> Bool {
        
        let legIndex = routeProgress.legIndex
        let stepIndex = routeProgress.currentLegProgress.stepIndex
        let didProcessCurrentStep = previousLegIndex == legIndex && previousStepIndex == stepIndex
        
        guard !didProcessCurrentStep else { return false }
        
        sections.removeAll()
        
        let currentLeg = routeProgress.currentLeg
        
        // Add remaining steps for current leg
        var section = [RouteStep]()
        for (index, step) in currentLeg.steps.enumerated() {
            guard index > stepIndex else { continue }
            // Don't include the last step, it includes nothing
            guard index < currentLeg.steps.count - 1 else { continue }
            section.append(step)
        }
        
        if !section.isEmpty {
            sections.append(section)
        }
        
        // Include all steps on any future legs
        if !routeProgress.isFinalLeg {
            routeProgress.route.legs.suffix(from: routeProgress.legIndex + 1).forEach {
                var steps = $0.steps
                // Don't include the last step, it includes nothing
                _ = steps.popLast()
                sections.append(steps)
            }
        }
        
        previousStepIndex = stepIndex
        previousLegIndex = legIndex
        
        return true
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        rebuildDataSourceIfNecessary()
        
        NotificationCenter.default.addObserver(self, selector: #selector(StepsViewController.progressDidChange(_:)), name: .routeControllerProgressDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: nil)
    }
    
    @objc func progressDidChange(_ notification: Notification) {
    
        if rebuildDataSourceIfNecessary() {
            tableView.reloadData()
        }
    }
    
    func setupViews() {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let backgroundView = StepsBackgroundView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        self.backgroundView = backgroundView
        
        backgroundView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.separatorColor = .clear
        tableView.backgroundColor = .clear
        tableView.backgroundView = nil
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        self.tableView = tableView
        
        let dismissButton = DismissButton(type: .custom)
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        let title = NSLocalizedString("DISMISS_STEPS_TITLE", bundle: .mapboxNavigation, value: "Close", comment: "Dismiss button title on the steps view")
        dismissButton.setTitle(title, for: .normal)
        dismissButton.addTarget(self, action: #selector(StepsViewController.tappedDismiss(_:)), for: .touchUpInside)
        view.addSubview(dismissButton)
        self.dismissButton = dismissButton
        
        let bottomView = UIView()
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        bottomView.backgroundColor = DismissButton.appearance().backgroundColor
        view.addSubview(bottomView)
        self.bottomView = bottomView
        
        let separatorBottomView = SeparatorView()
        separatorBottomView.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.addSubview(separatorBottomView)
        self.separatorBottomView = separatorBottomView

        dismissButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
        dismissButton.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        dismissButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor).isActive = true
        dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        bottomView.topAnchor.constraint(equalTo: dismissButton.bottomAnchor).isActive = true
        bottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        bottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        separatorBottomView.topAnchor.constraint(equalTo: dismissButton.topAnchor).isActive = true
        separatorBottomView.leadingAnchor.constraint(equalTo: dismissButton.leadingAnchor).isActive = true
        separatorBottomView.trailingAnchor.constraint(equalTo: dismissButton.trailingAnchor).isActive = true
        separatorBottomView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: dismissButton.topAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        tableView.register(StepTableViewCell.self, forCellReuseIdentifier: cellId)
    }
    
    
    /**
     Shows and animates the `StepsViewController` down.
     */
    public func dropDownAnimation() {
        var frame = view.frame
        frame.origin.y -= frame.height
        view.frame = frame
        
        UIView.animate(withDuration: 0.35, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
            var frame = self.view.frame
            frame.origin.y += frame.height
            self.view.frame = frame
        }, completion: nil)
    }
    
    
    /**
     Dismisses and animates the `StepsViewController` up.
     */
    public func slideUpAnimation(completion: CompletionHandler? = nil) {
        UIView.animate(withDuration: 0.35, delay: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
            var frame = self.view.frame
            frame.origin.y -= frame.height
            self.view.frame = frame
        }) { (completed) in
            completion?()
        }
    }
    
    @IBAction func tappedDismiss(_ sender: Any) {
        delegate?.didDismissStepsViewController(self)
    }
    
    /**
     Dismisses the `StepsViewController`.
     */
    public func dismiss(completion: CompletionHandler? = nil) {
        slideUpAnimation {
            self.willMove(toParentViewController: nil)
            self.view.removeFromSuperview()
            self.removeFromParentViewController()
            completion?()
        }
    }
}

extension StepsViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let cell = tableView.cellForRow(at: indexPath) as! StepTableViewCell
        // Since as we progress, steps are removed from the list, we need to map the row the user tapped to the actual step on the leg.
        // If the user selects a step on future leg, all steps are going to be there.
        var stepIndex: Int
        if indexPath.section > 0 {
            stepIndex = indexPath.row
        } else {
            stepIndex = indexPath.row + routeProgress.currentLegProgress.stepIndex
            // For the current leg, we need to know the upcoming step.
            stepIndex += indexPath.row + 1 > sections[indexPath.section].count ? 0 : 1
        }
        delegate?.stepsViewController?(self, didSelect: indexPath.section, stepIndex: stepIndex, cell: cell)
    }
}

extension StepsViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let steps = sections[section]
        return steps.count
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! StepTableViewCell
        return cell
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        updateCell(cell as! StepTableViewCell, at: indexPath)
    }
    
    func updateCell(_ cell: StepTableViewCell, at indexPath: IndexPath) {
        cell.instructionsView.primaryLabel.viewForAvailableBoundsCalculation = cell
        cell.instructionsView.secondaryLabel.viewForAvailableBoundsCalculation = cell
        
        let step = sections[indexPath.section][indexPath.row]
        
        if let instructions = step.instructionsDisplayedAlongStep?.last {
            cell.instructionsView.update(for: instructions)
            cell.instructionsView.secondaryLabel.instruction = instructions.secondaryInstruction
        }
        cell.instructionsView.distance = step.distance
        
        cell.instructionsView.stepListIndicatorView.isHidden = true
        
        // Hide cell separator if it’s the last row in a section
        let isLastRowInSection = indexPath.row == sections[indexPath.section].count - 1
        cell.separatorView.isHidden = isLastRowInSection
    }
    
    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return nil
        }
        
        let leg = routeProgress.route.legs[section]
        let sourceName = leg.source.name
        let destinationName = leg.destination.name
        let majorWays = leg.name.components(separatedBy: ", ")
        
        if let destinationName = destinationName?.nonEmptyString, majorWays.count > 1 {
            let summary = String.localizedStringWithFormat(NSLocalizedString("LEG_MAJOR_WAYS_FORMAT", bundle: .mapboxNavigation, value: "%@ and %@", comment: "Format for displaying the first two major ways"), majorWays[0], majorWays[1])
            return String.localizedStringWithFormat(NSLocalizedString("WAYPOINT_DESTINATION_VIA_WAYPOINTS_FORMAT", bundle: .mapboxNavigation, value: "%@, via %@", comment: "Format for displaying destination and intermediate waypoints; 1 = source ; 2 = destinations"), destinationName, summary)
        } else if let sourceName = sourceName?.nonEmptyString, let destinationName = destinationName?.nonEmptyString {
            return String.localizedStringWithFormat(NSLocalizedString("WAYPOINT_SOURCE_DESTINATION_FORMAT", bundle: .mapboxNavigation, value: "%@ and %@", comment: "Format for displaying start and endpoint for leg; 1 = source ; 2 = destination"), sourceName, destinationName)
        } else {
            return leg.name
        }
    }
}

/// :nodoc:
@objc(MBStepInstructionsView)
open class StepInstructionsView: BaseInstructionsBannerView { }

/// :nodoc:
@objc(MBStepTableViewCell)
open class StepTableViewCell: UITableViewCell {
    
    weak var instructionsView: StepInstructionsView!
    weak var separatorView: SeparatorView!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        selectionStyle = .none
        
        let instructionsView = StepInstructionsView()
        instructionsView.translatesAutoresizingMaskIntoConstraints = false
        instructionsView.separatorView.isHidden = true
        instructionsView.isUserInteractionEnabled = false
        addSubview(instructionsView)
        self.instructionsView = instructionsView
        
        instructionsView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        instructionsView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        instructionsView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        instructionsView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        let separatorView = SeparatorView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorView)
        self.separatorView = separatorView
        
        separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        separatorView.leadingAnchor.constraint(equalTo: instructionsView.primaryLabel.leadingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: instructionsView.bottomAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18).isActive = true
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        instructionsView.update(for:nil)
    }
}

extension Array where Element == RouteStep {
    
    fileprivate func stepBefore(_ step: RouteStep) -> RouteStep? {
        guard let index = self.index(of: step) else {
            return nil
        }
        
        if index > 0 {
            return self[index-1]
        }
        
        return nil
    }
}
