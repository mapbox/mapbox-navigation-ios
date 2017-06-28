import UIKit
import Pulley
import MapboxCoreNavigation

protocol RouteTableViewControllerDelegate: class {
    var voiceEnabled: Bool { get set }
    var showsSatellite: Bool { get set }
    var showsTraffic: Bool { get set }
}

class RouteTableViewController: StaticTableViewController {
    let routeStepFormatter = RouteStepFormatter()
    weak var delegate: RouteTableViewControllerDelegate!
    
    lazy var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    lazy var dateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.maximumUnitCount = 2
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .short
        return formatter
    }()
    
    lazy var distanceFormatter: DistanceFormatter = {
        let formatter = DistanceFormatter(approximate: true)
        formatter.numberFormatter.locale = .nationalizedCurrent
        formatter.unitStyle = .long
        return formatter
    }()
    
    var defaultSections: [TableViewSection] {
        get {
            var sections = [TableViewSection]()
            let satellite = TableViewItem(NSLocalizedString("SATELLITE", value: "Satellite", comment: "Satellite table view item"))
            let traffic = TableViewItem(NSLocalizedString("LIVE_TRAFFIC", value: "Live Traffic", comment: "Live Traffic table view item"))
            let sound = TableViewItem(NSLocalizedString("VOICE", value: "Voice", comment: "Voice table view item"))
            let steps = TableViewItem("Steps")
            
            satellite.image = UIImage(named: "satellite", in: Bundle.navigationUI, compatibleWith: nil)
            traffic.image = UIImage(named: "traffic", in: Bundle.navigationUI, compatibleWith: nil)
            sound.image = UIImage(named: "volume-up", in: Bundle.navigationUI, compatibleWith: nil)
            steps.image = UIImage(named: "list", in: Bundle.navigationUI, compatibleWith: nil)
            
            satellite.toggledStateHandler = { [unowned self] (sender: UISwitch) in
                return self.delegate.showsSatellite
            }
            
            satellite.didToggleHandler = { [unowned self] (sender: UISwitch) in
                self.delegate.showsSatellite = sender.isOn
            }
            
            traffic.toggledStateHandler = { [unowned self] (sender: UISwitch) in
                return self.delegate.showsTraffic
            }
            
            traffic.didToggleHandler = { [unowned self] (sender: UISwitch) in
                self.delegate.showsTraffic = sender.isOn
            }
            
            sound.toggledStateHandler = { [unowned self] (sender: UISwitch) in
                return self.delegate.voiceEnabled
            }
            
            sound.didToggleHandler = { [unowned self] (sender: UISwitch) in
                self.delegate.voiceEnabled = sender.isOn
            }
            
            sections.append([TableViewItem.separator, satellite, traffic])
            sections.append([TableViewItem.separator, sound, steps])
            
            return sections
        }
    }
    
    weak var routeController: RouteController!
    
    @IBOutlet var headerView: RouteTableViewHeaderView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
    }
    
    func setupTableView() {
        tableView.tableHeaderView = headerView
        sections = defaultSections
    }
    
    func showETA(routeProgress: RouteProgress) {
        guard let arrivalDate = NSCalendar.current.date(byAdding: .second, value: Int(routeProgress.durationRemaining), to: Date()) else {
            return
        }
        
        var subtitleComponents = [String]()
        var title = ""
        
        if routeProgress.durationRemaining < 60 {
            title = String.localizedStringWithFormat(NSLocalizedString("LESS_THAN", value: "<%@", comment: "Format string for less than; 1 = duration remaining"), dateComponentsFormatter.string(from: 61)!)
        } else {
            if let duration = dateComponentsFormatter.string(from: routeProgress.durationRemaining) {
                title = duration
            }
        }
        
        headerView.titleLabel.text = title
        
        subtitleComponents.append(timeFormatter.string(from: arrivalDate))
        
        if routeProgress.durationRemaining >= 5 {
            subtitleComponents.append(distanceFormatter.string(from: routeProgress.distanceRemaining))
        }
        
        headerView.subtitleLabel.text = subtitleComponents.joined(separator: ", ")
    }
    
    func notifyDidChange(routeProgress: RouteProgress) {
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
