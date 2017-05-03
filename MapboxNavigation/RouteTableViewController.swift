import UIKit
import Pulley
import MapboxCoreNavigation

class RouteTableViewController: StaticTableViewController {
    
    let dateFormatter = DateFormatter()
    let dateComponentsFormatter = DateComponentsFormatter()
    let distanceFormatter = DistanceFormatter(approximate: true)
    let routeStepFormatter = RouteStepFormatter()
    
    weak var routeController: RouteController!
    
    @IBOutlet var headerView: RouteTableViewHeaderView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dateFormatter.timeStyle = .short
        dateComponentsFormatter.maximumUnitCount = 2
        dateComponentsFormatter.allowedUnits = [.day, .hour, .minute]
        dateComponentsFormatter.unitsStyle = .short
        distanceFormatter.numberFormatter.locale = .nationalizedCurrent
        headerView.progress = CGFloat(routeController.routeProgress.fractionTraveled)
    }
    
    func setupTableView() {
        tableView.tableHeaderView = headerView
        // TODO: Are we gonna use a progress bar?
        //headerView.progress = CGFloat(routeController.routeProgress.fractionTraveled)
        let satellite = TableViewItem(NSLocalizedString("SATELLITE", value: "Satellite", comment: "Satellite table view item"))
        let traffic = TableViewItem(NSLocalizedString("LIVE_TRAFFIC", value: "Live Traffic", comment: "Live Traffic table view item"))
        let sound = TableViewItem(NSLocalizedString("SOUND", value: "Sound", comment: "Sound table view item"))
        let steps = TableViewItem("Steps")
        
        satellite.image = UIImage(named: "satellite", in: Bundle.navigationUI, compatibleWith: nil)
        traffic.image = UIImage(named: "traffic", in: Bundle.navigationUI, compatibleWith: nil)
        sound.image = UIImage(named: "volume-up", in: Bundle.navigationUI, compatibleWith: nil)
        steps.image = UIImage(named: "list", in: Bundle.navigationUI, compatibleWith: nil)
        
        satellite.toggledStateHandler = { (sender: UISwitch) in
            if let showsSatellite = NavigationDefaults.shared?.bool(forKey: NavigationSettings.showsSatellite) {
                return showsSatellite
            }
            return false
        }
        
        traffic.toggledStateHandler = { (sender: UISwitch) in
            if let showsTraffic = NavigationDefaults.shared?.bool(forKey: NavigationSettings.showsSatellite) {
                return showsTraffic
            }
            return false
        }
        
        sound.toggledStateHandler = { (sender: UISwitch) in
            return true // TODO: Return sound state
        }
        
        satellite.didToggleHandler = { (sender: UISwitch) in
            guard let controller = self.parent as? NavigationViewController else { return }
            NavigationDefaults.shared?.set(sender.isOn, forKey: NavigationSettings.showsSatellite)
            controller.mapView?.styleURL = NavigationSettings.styleURL
        }
        
        traffic.didToggleHandler = { (sender: UISwitch) in
            NavigationDefaults.shared?.set(sender.isOn, forKey: NavigationSettings.showsTraffic)
        }
        
        sound.didToggleHandler = { (sender: UISwitch) in
            // TODO: toggle sound
        }
        
        data.append([TableViewItem.separator, satellite, traffic])
        data.append([TableViewItem.separator, sound, steps])
        
        tableView.reloadData()
    }
    
    func showETA(routeProgress: RouteProgress) {
        if let arrivalDate = NSCalendar.current.date(byAdding: .second, value: Int(routeProgress.durationRemaining), to: Date()) {
            headerView.etaLabel.text = dateFormatter.string(from: arrivalDate)
        }
        
        if routeProgress.durationRemaining < 5 {
            headerView.distanceRemainingLabel.text = nil
        } else {
            headerView.distanceRemainingLabel.text = distanceFormatter.string(from: routeProgress.distanceRemaining)
        }
        
        if routeProgress.durationRemaining < 60 {
            headerView.timeRemainingLabel.text = String.localizedStringWithFormat(NSLocalizedString("LESS_THAN", value: "<%@", comment: "Format string for less than; 1 = duration remaining"), dateComponentsFormatter.string(from: 61)!)
        } else {
            headerView.timeRemainingLabel.text = dateComponentsFormatter.string(from: routeProgress.durationRemaining)
        }
        
        // TODO: Get from system settings
        headerView.etaUnitLabel.text = "hh:mm"
        headerView.distanceUnitLabel.text = "miles"
        headerView.timeUnitLabel.text = "PM"
    }
    
    func notifyDidChange(routeProgress: RouteProgress) {
        // TODO: Update progress?
//        headerView.progress = routeProgress.currentLegProgress.alertUserLevel == .arrive ? 1 : CGFloat(routeProgress.fractionTraveled)
        showETA(routeProgress: routeProgress)
    }
    
    func notifyDidReroute() {
        tableView.reloadData()
    }
    
    func notifyAlertLevelDidChange() {
        if let visibleIndexPaths = tableView.indexPathsForVisibleRows {
            tableView.reloadRows(at: visibleIndexPaths, with: .fade)
        }
    }
}

/* // TODO: Populate steps in a new table view
extension RouteTableViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routeController.routeProgress.currentLeg.steps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RouteTableViewCellIdentifier, for: indexPath) as! RouteTableViewCell
        let leg = routeController.routeProgress.currentLeg
        
        cell.step = leg.steps[indexPath.row]
        
        if routeController.routeProgress.currentLegProgress.stepIndex + 1 > indexPath.row {
            cell.contentView.alpha = 0.4
        }
        
        return cell
    }
}*/

extension RouteTableViewController: PulleyDrawerViewControllerDelegate {
    
    /**
     Returns an array of `PulleyPosition`. The array contains the view positions the bottom bar supports.
     */
    public func supportedDrawerPositions() -> [PulleyPosition] {
        return [
            .collapsed,
            .partiallyRevealed,
            .open,
            .closed
        ]
    }
    
    func collapsedDrawerHeight() -> CGFloat {
        return headerView.intrinsicContentSize.height
    }
    
    func partialRevealDrawerHeight() -> CGFloat {
        return UIScreen.main.bounds.height * 0.60
    }
}
