import UIKit
import MapboxDirections
import MapboxCoreNavigation

@objc(MBStepsBackgroundView)
open class StepsBackgroundView: UIView { }

protocol StepsViewControllerDelegate: class {
    func stepsViewController(_ viewController: StepsViewController, didSelect step: RouteStep)
    func didDismissStepsViewController(_ viewController: StepsViewController)
}

class StepsViewController: UIViewController {
    
    weak var tableView: UITableView!
    weak var backgroundView: UIView!
    weak var dismissButton: DismissButton!
    weak var delegate: StepsViewControllerDelegate?
    
    typealias CompletionHandler = () -> ()
    
    let cellId = "StepTableViewCellId"
    var routeProgress: RouteProgress!
    let instructionFormatter = VisualInstructionFormatter()
    
    typealias StepSection = [RouteStep]
    var sections = [StepSection]()
    
    convenience init(routeProgress: RouteProgress) {
        self.init()
        self.routeProgress = routeProgress
        
        let legIndex = routeProgress.legIndex
        let stepIndex = routeProgress.currentLegProgress.stepIndex
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
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

        dismissButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
        dismissButton.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        dismissButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        dismissButton.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
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
        
        UIView.animate(withDuration: 0.4, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
            var frame = self.view.frame
            frame.origin.y += frame.height
            self.view.frame = frame
        }, completion: nil)
    }
    
    func slideUpAnimation(completion: CompletionHandler? = nil) {
        UIView.animate(withDuration: 0.4, delay: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
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
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let step = sections[indexPath.section][indexPath.row]
        delegate?.stepsViewController(self, didSelect: step)
    }
}

extension StepsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let steps = sections[section]
        return steps.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! StepTableViewCell
        cell.step = sections[indexPath.section][indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let leg = routeProgress.route.legs[section]
        return sections.count <= 1 ? nil : leg.destination.name ?? "\(section)"
    }
}

open class StepInstructionsView: BaseInstructionsBannerView { }

/// :nodoc:
open class StepTableViewCell: UITableViewCell {
    
    weak var instructionsView: StepInstructionsView!
    weak var separatorView: SeparatorView!
    static let formatter = VisualInstructionFormatter()
    
    var step: RouteStep? {
        didSet {
            guard let step = step else { return }
            let instructions = StepTableViewCell.formatter.instructions(leg: nil, step: step)
            instructionsView.set(instructions.0, secondaryInstruction: instructions.1)
            instructionsView.maneuverView.step = step
            instructionsView.distance = step.distance
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
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
