import UIKit
import MapboxDirections
import MapboxCoreNavigation

class StepsViewController: UIViewController {
    
    weak var tableView: UITableView!
    weak var closeButton: UIButton!
    
    let cellId = "StepTableViewCellId"
    var steps: [RouteStep]!
    let instructionFormatter = VisualInstructionFormatter()
    
    convenience init(steps: [RouteStep]) {
        self.init()
        self.steps = steps
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    func setupViews() {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.separatorColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        self.tableView = tableView
        
        let closeButton = UIButton(type: .custom)
        closeButton.backgroundColor = .black
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self, action: #selector(StepsViewController.close(_:)), for: .touchUpInside)
        view.addSubview(closeButton)
        self.closeButton = closeButton
        
        closeButton.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        closeButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        closeButton.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: closeButton.topAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        tableView.register(StepTableViewCell.self, forCellReuseIdentifier: cellId)
    }
    
    func present() {
        // TODO
    }
    
    func dismiss() {
        // TODO
    }
    
    @IBAction func close(_ sender: Any) {
        willMove(toParentViewController: nil)
        // TODO: Dismiss animation
        view.removeFromSuperview()
        removeFromParentViewController()
    }
}

extension StepsViewController: UITableViewDelegate {
}

extension StepsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return steps.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 96
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! StepTableViewCell
        cell.step = steps[indexPath.row]
        return cell
    }
}

open class StepInstructionsView: BaseInstructionsBannerView { }

class StepTableViewCell: UITableViewCell {
    
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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = #colorLiteral(red: 0.103291966, green: 0.1482483149, blue: 0.2006777823, alpha: 1)
        let instructionsView = StepInstructionsView()
        instructionsView.translatesAutoresizingMaskIntoConstraints = false
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
