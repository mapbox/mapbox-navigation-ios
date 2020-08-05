import UIKit
import MapboxDirections
import MapboxCoreNavigation

class SettingsViewController: UITableViewController {
    let cellIdentifier = "cellId"
    var dataSource: [Section]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = sections()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(close))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        dataSource = sections()
        tableView.reloadData()
    }
    
    @IBAction func close() {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
        }
        
        let item = dataSource[indexPath.section].items[indexPath.row]
        
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.subtitle
        
        if let item = item as? OfflineVersionItem {
            let toggle = OfflineSwitch(frame: .zero)
            toggle.item = item
            toggle.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
            toggle.isOn = item.title == Settings.selectedOfflineVersion
            cell.accessoryView = toggle
        }
        
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].items.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource[section].title
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return dataSource[indexPath.section].items[indexPath.row].canEditRow
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let item = dataSource[indexPath.section].items[indexPath.row]
        
        guard let url = Bundle.mapboxCoreNavigation.suggestedTileURL(version: item.title) else { return }
        try? FileManager.default.removeItem(atPath: url.path)
        
        dataSource = sections()
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = dataSource[indexPath.section].items[indexPath.row]
        
        if let viewController = item.viewControllerType?.init() {
            navigationController?.pushViewController(viewController, animated: true)
        }
        
        if let payload = item.payload {
            payload()
        }
    }
    
    @objc func switchValueChanged(_ toggle: OfflineSwitch) {
        Settings.selectedOfflineVersion = toggle.isOn ? toggle.item?.title : nil
        
        if let selectedOfflineVersion = Settings.selectedOfflineVersion {
            let tilesURL = Bundle.mapboxCoreNavigation.suggestedTileURL(version: selectedOfflineVersion)
            
            Settings.directions.configureRouter(tilesURL: tilesURL!) { [weak self] (numberOfTiles) in
                let message = NSLocalizedString("ROUTER_CONFIGURED_MSG", value: "Router configured.", comment: "Alert message when a router has been configured")
                self?.presentAlert(message: message)
            }
        }
    }
}
