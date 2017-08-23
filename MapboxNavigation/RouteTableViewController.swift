import UIKit
import Pulley
import MapboxCoreNavigation
import MapboxDirections

class RouteTableViewController: UIViewController {
    
    let RouteTableViewCellIdentifier = "RouteTableViewCellId"
    let dateFormatter = DateFormatter()
    let dateComponentsFormatter = DateComponentsFormatter()
    let distanceFormatter = DistanceFormatter(approximate: true)
    let routeStepFormatter = RouteStepFormatter()
    
    weak var routeController: RouteController!
    
    @IBOutlet var headerView: RouteTableViewHeaderView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupTableView()
        dateFormatter.timeStyle = .short
        dateComponentsFormatter.allowedUnits = [.hour, .minute]
        dateComponentsFormatter.unitsStyle = .abbreviated
        distanceFormatter.numberFormatter.locale = .nationalizedCurrent
    }
    
    func setupTableView() {
        tableView.tableHeaderView = headerView
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
    }
    
    func showETA(routeProgress: RouteProgress) {
        let arrivalDate = NSCalendar.current.date(byAdding: .second, value: Int(routeProgress.durationRemaining), to: Date())
        headerView.arrivalTimeLabel.text = dateFormatter.string(from: arrivalDate!)
        
        if routeProgress.durationRemaining < 5 {
            headerView.distanceRemaining.text = nil
        } else {
            headerView.distanceRemaining.text = distanceFormatter.string(from: routeProgress.distanceRemaining)
        }
        
        dateComponentsFormatter.unitsStyle = routeProgress.durationRemaining < 3600 ? .short : .abbreviated
        
        if routeProgress.durationRemaining < 60 {
            headerView.timeRemaining.text = String.localizedStringWithFormat(NSLocalizedString("LESS_THAN", bundle: .mapboxNavigation, value: "<%@", comment: "Format string for a short distance or time less than a minimum threshold; 1 = duration remaining"), dateComponentsFormatter.string(from: 61)!)
        } else {
            headerView.timeRemaining.text = dateComponentsFormatter.string(from: routeProgress.durationRemaining)
            
            let coordinatesLeftOnStepCount = Int(floor((Double(routeProgress.currentLegProgress.currentStepProgress.step.coordinateCount)) * routeProgress.currentLegProgress.currentStepProgress.fractionTraveled))
            
            guard coordinatesLeftOnStepCount >= 0 else {
                headerView.timeRemaining.textColor = TimeRemainingLabel.appearance(for: traitCollection).textColor
                return
            }
            
            
            let congestionTimesForStep = routeProgress.congestionTravelTimesSegmentsByStep[routeProgress.legIndex][routeProgress.currentLegProgress.stepIndex]
            guard coordinatesLeftOnStepCount <= congestionTimesForStep.count else { return }
            
            let remainingCongestionTimesForStep = congestionTimesForStep.suffix(from: coordinatesLeftOnStepCount)
            let remainingCongestionTimesForRoute = routeProgress.congestionTimesPerStep[routeProgress.legIndex].suffix(from: routeProgress.currentLegProgress.stepIndex + 1)
            
            var remainingStepCongestionTotals: [CongestionLevel: TimeInterval] = [:]
            for stepValues in remainingCongestionTimesForRoute {
                for (key, value) in stepValues {
                    remainingStepCongestionTotals[key] = (remainingStepCongestionTotals[key] ?? 0) + value
                }
            }

            for (segmentCongestion, segmentTime) in remainingCongestionTimesForStep {
                remainingStepCongestionTotals[segmentCongestion] = (remainingStepCongestionTotals[segmentCongestion] ?? 0) + segmentTime
            }
            
            if let max = remainingStepCongestionTotals.max(by: { a, b in a.value < b.value }) {
                switch max.key {
                case .unknown:
                    headerView.timeRemaining.textColor = TimeRemainingLabel.appearance(for: traitCollection).textColor
                case .low:
                    headerView.timeRemaining.textColor = .trafficAlternateLow
                case .moderate:
                    headerView.timeRemaining.textColor = .trafficModerate
                case .heavy:
                    headerView.timeRemaining.textColor = .trafficHeavy
                case .severe:
                    headerView.timeRemaining.textColor = .trafficSevere
                }
            }
        }
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
