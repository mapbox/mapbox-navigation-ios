import UIKit
import MapboxDirections
import MapboxCoreNavigation
import MapboxGeocoder

//MARK: - View Reuse Identifier Enum
enum ReuseIdentifier: String {
    case arrived, feedback
}

class FeedbackOverviewTableViewController: UIViewController {
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - Models
    var route: Route?
    var feedbacks: [FeedbackEvent]?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0) // Do not extend table view under status bar.
        tableView.reloadData()
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

// MARK: - Table view data source and delegate

extension FeedbackOverviewTableViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let feedbacks = feedbacks else { return 1 } // If we have no feedbacks, show only the arrival cell.
        return feedbacks.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 300
        default:
            return feedbacks != nil ? 70 : 0
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row >= 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            return arrivedCell(for: tableView, indexPath: indexPath)
        default:
            return feedbackCell(for: tableView, indexPath: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "FeedbackEventTableViewController", sender: nil)
    }
    
    private func arrivedCell(for tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.arrived.rawValue, for: indexPath) as! ArrivedTableViewCell
        cell.route = route
        cell.feedbacks = feedbacks
        return cell
    }
    
    private func feedbackCell(for tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ReuseIdentifier.feedback.rawValue, for: indexPath) as! FeedbackTableViewCell
        cell.feedback = feedbacks![indexPath.row - 1]
        return cell
    }
}
