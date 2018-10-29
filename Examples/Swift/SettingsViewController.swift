import UIKit
import MapboxDirections

typealias Payload = () -> ()

struct Item {
    let title: String
    let viewControllerType: UIViewController.Type? // View controller to present on SettingsViewController.tableView(_:didSelectRowAt:)
    let payload: Payload? // Closure to call on SettingsViewController.tableView(_:didSelectRowAt:)
}

typealias Section = [Item]

class SettingsViewController: UITableViewController {
    
    let cellIdentifier = "cellId"
    var dataSource: [Section]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        dataSource = sections()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(close))
    }
    
    @IBAction func close() {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let item = dataSource[indexPath.section][indexPath.row]
        
        cell.textLabel?.text = item.title
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = dataSource[indexPath.section][indexPath.row]
        
        if let viewController = item.viewControllerType?.init() {
            navigationController?.pushViewController(viewController, animated: true)
        }
        
        if let payload = item.payload {
            payload()
        }
    }
}
