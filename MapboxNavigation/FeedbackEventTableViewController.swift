import UIKit

let unwindSegueIdentifier = "unwind"

class FeedbackEventTableViewController: UIViewController {
    
    @IBOutlet weak var continueButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// MARK: - Table view data source and delegate

extension FeedbackEventTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    @IBAction func continueButtonPressed(_ sender: Any) {
        performSegue(withIdentifier: unwindSegueIdentifier, sender: self)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
        return cell
    }
}
