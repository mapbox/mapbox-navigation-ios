import UIKit
import MapboxDirections
import MapboxCoreNavigation
import Turf

@objc(MBStepsBackgroundView)
open class StepsBackgroundView: UIView { }

protocol StepsViewControllerDelegate: class {
    func stepsViewController(_ viewController: StepsViewController, didSelect step: RouteStep, cell: StepTableViewCell)
    func didDismissStepsViewController(_ viewController: StepsViewController)
}

/// :nodoc:
@objc(MBStepsViewController)
open class StepsViewController: UIViewController {
    
    weak var tableView: UITableView!
    weak var backgroundView: UIView!
    weak var bottomView: UIView!
    weak var dismissButton: DismissButton!
    weak var delegate: StepsViewControllerDelegate?
    
    typealias CompletionHandler = () -> Void
    
    let cellId = "StepTableViewCellId"
    var routeProgress: RouteProgress!
    
    typealias StepSection = [RouteStep]
    var sections = [StepSection]()
    
    convenience init(routeProgress: RouteProgress) {
        self.init()
        self.routeProgress = routeProgress
    }
    
    func rebuildDataSource() {
        sections.removeAll()
        
        let legIndex = routeProgress.legIndex
        // Don't include the current step in the list
        let stepIndex = routeProgress.currentLegProgress.stepIndex + 1
        let legs = routeProgress.route.legs
        
        for (index, leg) in legs.enumerated() {
            guard index >= legIndex else { continue }
            
            var section = [RouteStep]()
            for (index, step) in leg.steps.enumerated() {
                guard index > stepIndex else { continue }
                section.append(step)
            }
            
            if !section.isEmpty {
                sections.append(section)
            }
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        rebuildDataSource()
        
        NotificationCenter.default.addObserver(self, selector: #selector(StepsViewController.progressDidChange(_:)), name: .routeControllerProgressDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: nil)
    }
    
    @objc func progressDidChange(_ notification: Notification) {
        rebuildDataSource()
        tableView.reloadData()
    }
    
    func setupViews() {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let backgroundView = StepsBackgroundView()
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundView)
        self.backgroundView = backgroundView
        
        backgroundView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backgroundView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        backgroundView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
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

        dismissButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
        dismissButton.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        dismissButton.bottomAnchor.constraint(equalTo: view.safeBottomAnchor).isActive = true
        dismissButton.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        bottomView.topAnchor.constraint(equalTo: dismissButton.bottomAnchor).isActive = true
        bottomView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        bottomView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        bottomView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: dismissButton.topAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        tableView.register(StepTableViewCell.self, forCellReuseIdentifier: cellId)
    }
    
    func dropDownAnimation() {
        var frame = view.frame
        frame.origin.y -= frame.height
        view.frame = frame
        
        UIView.animate(withDuration: 0.35, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
            var frame = self.view.frame
            frame.origin.y += frame.height
            self.view.frame = frame
        }, completion: nil)
    }
    
    func slideUpAnimation(completion: CompletionHandler? = nil) {
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
    
    func dismiss(completion: CompletionHandler? = nil) {
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
        let step = sections[indexPath.section][indexPath.row]
        let cell = tableView.cellForRow(at: indexPath) as! StepTableViewCell
        delegate?.stepsViewController(self, didSelect: step, cell: cell)
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
        updateCell(cell, at: indexPath)
        return cell
    }
    
    func updateCell(_ cell: StepTableViewCell, at indexPath: IndexPath) {
        let step = sections[indexPath.section][indexPath.row]
        
        cell.instructionsView.maneuverView.step = step
       
        let usePreviousLeg = indexPath.section != 0 && indexPath.row == 0
        let leg = routeProgress.route.legs[indexPath.section]
        let arrivalSecondaryInstruction = leg.destination.name
        
        if usePreviousLeg {
            let leg = routeProgress.route.legs[indexPath.section-1]
            let stepBefore = leg.steps[leg.steps.count-1]
            if let instructions = stepBefore.instructionsDisplayedAlongStep?.last {
                let secondaryInstruction = step.maneuverType == .arrive && arrivalSecondaryInstruction != nil ? [VisualInstructionComponent(type: .destination, text: arrivalSecondaryInstruction, imageURL: nil)] : instructions.secondaryTextComponents
                cell.instructionsView.set(instructions.primaryTextComponents, secondaryInstruction: secondaryInstruction)
            }
            cell.instructionsView.distance = stepBefore.distance
        } else {
            let leg = routeProgress.route.legs[indexPath.section]
            if let stepBefore = leg.steps.stepBefore(step) {
                if let instructions = stepBefore.instructionsDisplayedAlongStep?.last {
                    let secondaryInstruction = step.maneuverType == .arrive && arrivalSecondaryInstruction != nil ? [VisualInstructionComponent(type: .destination, text: arrivalSecondaryInstruction, imageURL: nil)] : instructions.secondaryTextComponents
                    cell.instructionsView.set(instructions.primaryTextComponents, secondaryInstruction: secondaryInstruction)
                }
                cell.instructionsView.distance = stepBefore.distance
            } else {
                cell.instructionsView.distance = nil
                if let instructions = step.instructionsDisplayedAlongStep?.last {
                    let secondaryInstruction = step.maneuverType == .arrive && arrivalSecondaryInstruction != nil ? [VisualInstructionComponent(type: .destination, text: arrivalSecondaryInstruction, imageURL: nil)] : instructions.secondaryTextComponents
                    cell.instructionsView.set(instructions.primaryTextComponents, secondaryInstruction: secondaryInstruction)
                }
            }
        }
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
        instructionsView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        instructionsView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        instructionsView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        let separatorView = SeparatorView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorView)
        self.separatorView = separatorView
        
        separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        separatorView.leftAnchor.constraint(equalTo: instructionsView.primaryLabel.leftAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: instructionsView.bottomAnchor).isActive = true
        separatorView.rightAnchor.constraint(equalTo: rightAnchor, constant: -18).isActive = true
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
