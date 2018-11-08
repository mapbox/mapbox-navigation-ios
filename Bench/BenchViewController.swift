import UIKit
import MapboxDirections
import MapboxNavigation
import MapboxCoreNavigation
import TestHelper

typealias Payload = (_ item: Item) -> ()

struct Section {
    let title: String
    let items: [Item]
}

struct Item {
    let name: String
    let viewControllerType: NavigationViewController.Type?
    var payload: Payload?
    let route: Route?
    
    init(name: String, viewControllerType: NavigationViewController.Type? = nil, payload: Payload? = nil, route: Route? = nil) {
        self.name = name
        self.viewControllerType = viewControllerType
        self.payload = payload
        self.route = route
    }
}

class BenchViewController: UITableViewController {

    var dataSource = [Section]()
    let cellIdentifier = "cellId"
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        let controlRoute1 = Item(name: "DCA to Arboretum",
                                 route: Fixture.route(from: "DCA-Arboretum"))
        
        let controlRoute2 = Item(name: "Pipe Fitters Union to Four Seasons Boston",
                                 route: Fixture.route(from: "PipeFittersUnion-FourSeasonsBoston"))
        
        let section = Section(title: "Control Routes", items: [controlRoute1, controlRoute2])
        
        dataSource = [section]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let item = dataSource[indexPath.section].items[indexPath.row]
        
        cell.textLabel?.text = item.name
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = dataSource[indexPath.section].items[indexPath.row]
        
        guard let route = item.route else { return }
        
        let viewController = ControlRouteViewController(for: route)
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension BenchViewController: NavigationViewControllerDelegate {
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        navigationController?.popViewController(animated: true)
    }
}
