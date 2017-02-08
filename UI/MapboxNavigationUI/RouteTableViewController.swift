import UIKit
import Pulley
import MapboxNavigation

class RouteTableViewController: UIViewController {
    
    let RouteTableViewCellIdentifier = "RouteTableViewCellId"
    let dateFormatter = DateFormatter()
    let dateComponentsFormatter = DateComponentsFormatter()
    let distanceFormatter = DistanceFormatter(approximate: true)
    let routeStepFormatter = RouteStepFormatter()
    
    weak var routeController: RouteController!
    
    @IBOutlet var headerView: RouteTableViewHeaderView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        resumeNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dateFormatter.timeStyle = .short
        dateComponentsFormatter.maximumUnitCount = 2
        dateComponentsFormatter.allowedUnits = [.day, .hour, .minute]
        dateComponentsFormatter.unitsStyle = .short
        
        headerView.progress = CGFloat(routeController.routeProgress.fractionTraveled)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        suspendNotifications()
    }
    
    func setupTableView() {
        tableView.tableHeaderView = headerView
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 106
        tableView.reloadData()
    }
    
    func showETA(routeProgress: RouteProgress) {
        let arrivalDate = NSCalendar.current.date(byAdding: .second, value: Int(routeProgress.durationRemaining), to: Date())
        headerView.etaLabel.text = String.localizedStringWithFormat(NSLocalizedString("HEADER_SUBTITLE_FORMAT", value: "Arrive at %@", comment: "1 = estimated arrival time"), dateFormatter.string(from: arrivalDate!))
        
        if routeProgress.durationRemaining < 5 {
            headerView.distanceRemaining.text = nil
        } else {
            headerView.distanceRemaining.text = distanceFormatter.string(from: routeProgress.distanceRemaining)
        }
        
        if routeProgress.durationRemaining < 60 {
            headerView.timeRemaining.text = String.localizedStringWithFormat(NSLocalizedString("LESS_THAN", value: "<%@", comment: "Format string for less than; 1 = duration remaining"), dateComponentsFormatter.string(from: 61)!)
        } else {
            headerView.timeRemaining.text = dateComponentsFormatter.string(from: routeProgress.durationRemaining)
        }
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.progressDidChange(notification:)), name: RouteControllerProgressDidChange, object: routeController)
        NotificationCenter.default.addObserver(self, selector: #selector(self.reRoute(_:)), name: RouteControllerNotification.didReceiveNewRoute, object: routeController)
        NotificationCenter.default.addObserver(self, selector: #selector(self.alertLevelDidChange(_:)), name: RouteControllerNotification.didReceiveNewRoute, object: routeController)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: RouteControllerProgressDidChange, object: routeController)
        NotificationCenter.default.removeObserver(self, name: RouteControllerNotification.didReceiveNewRoute, object: routeController)
        NotificationCenter.default.removeObserver(self, name: RouteControllerAlertLevelDidChange, object: routeController)
    }
    
    func progressDidChange(notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
        headerView.progress = CGFloat(routeProgress.fractionTraveled)
        showETA(routeProgress: routeProgress)
    }
    
    func reRoute(_ notification: Notification) {
        tableView.reloadData()
    }
    
    func alertLevelDidChange( _ notifcation: Notification) {
        if let visibleIndexPaths = tableView.indexPathsForVisibleRows {
            tableView.reloadRows(at: visibleIndexPaths, with: .fade)
        }
    }
}

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
}

extension RouteTableViewController: PulleyDrawerViewControllerDelegate {
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
        return UIScreen.main.bounds.height * 0.75
    }
}
