import UIKit
import MapboxDirections
import MapboxCoreNavigation
import Turf

/// :nodoc:
open class StepsBackgroundView: UIView { }

/// :nodoc:
public class StepsViewController: UIViewController {
    weak var tableView: UITableView!
    weak var backgroundView: StepsBackgroundView!
    weak var bottomView: StepsBackgroundView!
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
     - seealso: RouteProgress
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

        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_:)), name: .routeControllerProgressDidChange, object: nil)
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

        let bottomView = StepsBackgroundView()
        bottomView.translatesAutoresizingMaskIntoConstraints = false
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

    @IBAction func tappedDismiss(_ sender: Any) {
        delegate?.didDismissStepsViewController(self)
    }

    /**
     Dismisses the `StepsViewController`.
     */
    public func dismiss(completion: CompletionHandler? = nil) {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
        completion?()
    }
}

extension StepsViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let legIndex = indexPath.section
        let cell = tableView.cellForRow(at: indexPath) as! StepTableViewCell
        // Since as we progress, steps are removed from the list, we need to map the row the user tapped to the actual step on the leg.
        // If the user selects a step on future leg, all steps are going to be there.
        var stepIndex: Int
        if legIndex > 0 {
            stepIndex = indexPath.row
        } else {
            stepIndex = indexPath.row + routeProgress.currentLegProgress.stepIndex
            // For the current leg, we need to know the upcoming step.
            if sections[legIndex].indices.contains(indexPath.row) {
                stepIndex += 1
            }
        }
        
        guard routeProgress.route.containsStep(at: legIndex, stepIndex: stepIndex) else { return }
        delegate?.stepsViewController(self, didSelect: legIndex, stepIndex: stepIndex, cell: cell)
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

    func titleForHeader(in section: Int) -> String? {
        if section == 0 {
            return nil
        }

        let leg = routeProgress.route.legs[section]
        let sourceName = leg.source?.name
        let destinationName = leg.destination?.name
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
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return (section == 0) ? 0.0 : tableView.sectionHeaderHeight
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section != 0 else { return nil }
        let view = StepsTableHeaderView()
        view.textLabel?.text = titleForHeader(in: section)
        return view
    }
}

class StepsTableHeaderView: UITableViewHeaderFooterView {
    @objc dynamic var normalTextColor: UIColor = .black {
        didSet {
            self.textLabel?.textColor = normalTextColor
        }
    }
}
