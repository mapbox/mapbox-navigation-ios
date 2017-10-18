import UIKit
import Mapbox

let unwindSegueIdentifier = "unwind"

class FeedbackEventTableViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView() // Remove excessive separators
    }
    
    @IBAction func continueButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: unwindSegueIdentifier, sender: nil)
    }
}

// MARK: - Table view data source and delegate

extension FeedbackEventTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: FeedbackEventTableViewCell.self), for: indexPath)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: FeedbackTypeTableViewCell.self), for: indexPath)
            return cell
        }
    }
}
