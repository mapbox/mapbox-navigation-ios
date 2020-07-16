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
        
        let firstRouteOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 38.853108, longitude: -77.043331),
            CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906)
        ])
        let firstControlRoute = Item(name: "DCA to Arboretum",
                                     route: Fixture.route(from: "DCA-Arboretum", options: firstRouteOptions))
        
        let secondRouteOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 42.361634, longitude: -71.12852),
            CLLocationCoordinate2D(latitude: 42.352396, longitude: -71.068719)
        ])
        let secondControlRoute = Item(name: "Pipe Fitters Union to Four Seasons Boston",
                                      route: Fixture.route(from: "PipeFittersUnion-FourSeasonsBoston", options: secondRouteOptions))
        
        let section = Section(title: "Control Routes", items: [firstControlRoute, secondControlRoute])
        
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
        guard let leg = route.legs.first else { return }
        guard let source = leg.source else { return }
        guard let destination = leg.destination else { return }
        
        let routeOptions = NavigationRouteOptions(coordinates: [
            source.coordinate,
            destination.coordinate
        ])
        
        let viewController = ControlRouteViewController(for: route, routeOptions: routeOptions)
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension BenchViewController: NavigationViewControllerDelegate {
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        navigationController?.popViewController(animated: true)
    }
}
