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
        tableView.translatesAutoresizingMaskIntoConstraints = false
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! StepTableViewCell
        let step = steps[indexPath.row]
        cell.textLabel?.text = step.instructions
        return cell
    }
}

class StepTableViewCell: UITableViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
        
        
    }
}
