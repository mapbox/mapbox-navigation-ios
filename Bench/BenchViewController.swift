import UIKit
import MapboxDirections
import MapboxNavigation
import TestHelper

typealias Payload = (_ item: Item) -> ()

struct Section {
    let title: String
    let items: [Item]
}

struct Item {
    let name: String
    let viewControllerType: NavigationViewController.Type?
    let payload: Payload?
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
        
        let item = Item(name: "Test")
        
        let payload: Payload = { [weak self] item in
            let navigationViewController = NavigationViewController(for: item.route!)
            self!.navigationController!.pushViewController(navigationViewController, animated: true)
        }
        
        let routeItem = Item(name: "DCA-Arboretum-Tunnels-1",
                             viewControllerType: ControlRouteViewController.self,
                             payload: payload,
                             route: Fixture.route(from: "DCA-Arboretum-Tunnels-1"))
        
        let section = Section(title: "Control Routes", items: [routeItem, item])
        
        dataSource = [section]
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
        
        if let payload = item.payload {
            payload(item)
        }
    }
}

