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
        
        let controlRoute3 = Item(name: "Denver Union Station to IKEA Centennial",
                                 route: Fixture.route(from: "Denver-Ikea"))
        
        let controlRoute4 = Item(name: "Downington to Westchester, PA (Truck Route)",
                                 route: Fixture.route(from: "Downington-Westchester"))
        
        let controlRoute5 = Item(name: "St. Petersburg to Orlando, FL",
                                 route: Fixture.route(from: "StPetersburg-Orlando"))
        
        let temporaryControlRoute = Item(name: "Temporary Control Route",
                                         route: Fixture.route(from: "short-route"))
        
        let controlRoutes = [controlRoute1, controlRoute2, controlRoute3, controlRoute4, controlRoute5]
        let section = Section(title: "Control Routes", items: controlRoutes + [temporaryControlRoute])
        
        dataSource = [section]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        parseCommandLineArguments()
    }
    
    func parseCommandLineArguments() {
        let arguments = CommandLine.arguments
        let controlRoute = "MBControlRoute"
        
        for arg in arguments {
            if arg.contains(controlRoute),
                let routeIndex = Int(arg.components(separatedBy: "=")[1]) {
                let indexPath = IndexPath(row: routeIndex, section: 0)
                tableView(tableView, didSelectRowAt: indexPath)
            }
        }
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
        
        let locationManager = SimulatedLocationManager(route: route)
        locationManager.speedMultiplier = 9
        let viewController = controlRouteViewController(route: route, locationManager: locationManager)
        
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    func controlRouteViewController(route: Route, locationManager: NavigationLocationManager) -> NavigationViewController {
        
        let speechAPI = SpeechAPISpy(accessToken: "foo")
        let voiceController = MapboxVoiceController(speechClient: speechAPI, audioPlayerType: AudioPlayerDummy.self)
        let directions = DirectionsSpy(accessToken: "foo")
        let service = MapboxNavigationService(route: route,
                                              directions: directions,
                                              locationSource: locationManager,
                                              eventsManagerType: NavigationEventsManagerSpy.self,
                                              simulating: .onPoorGPS,
                                              routerType: PortableRouteController.self)
        
        return ControlRouteViewController(for: route, navigationService: service, voiceController: voiceController)
    }
}

extension BenchViewController: NavigationViewControllerDelegate {
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        navigationController?.popViewController(animated: true)
    }
    
    func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
        exit(0)
    }
}
