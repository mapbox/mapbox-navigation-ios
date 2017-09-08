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
        distanceFormatter.numberFormatter.locale = .nationalizedCurrent
        dateFormatter.timeStyle = .short
        dateComponentsFormatter.allowedUnits = [.hour, .minute]
        dateComponentsFormatter.unitsStyle = .abbreviated
        
        tableView.tableHeaderView = headerView
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
    }
    
    func updateETA(routeProgress: RouteProgress) {
        let arrivalDate = NSCalendar.current.date(byAdding: .second, value: Int(routeProgress.durationRemaining), to: Date())
        headerView.arrivalTimeLabel.text = dateFormatter.string(from: arrivalDate!)
        
        if routeProgress.durationRemaining < 5 {
            headerView.distanceRemainingLabel.text = nil
        } else {
            headerView.distanceRemainingLabel.text = distanceFormatter.string(from: routeProgress.distanceRemaining)
        }
        
        dateComponentsFormatter.unitsStyle = routeProgress.durationRemaining < 3600 ? .short : .abbreviated
        
        if routeProgress.durationRemaining < 60 {
            headerView.timeRemainingLabel.text = String.localizedStringWithFormat(NSLocalizedString("LESS_THAN", bundle: .mapboxNavigation, value: "<%@", comment: "Format string for a short distance or time less than a minimum threshold; 1 = duration remaining"), dateComponentsFormatter.string(from: 61)!)
        } else {
            headerView.timeRemainingLabel.text = dateComponentsFormatter.string(from: routeProgress.durationRemaining)
        }
            
        let coordinatesLeftOnStepCount = Int(floor((Double(routeProgress.currentLegProgress.currentStepProgress.step.coordinateCount)) * routeProgress.currentLegProgress.currentStepProgress.fractionTraveled))
        
        guard coordinatesLeftOnStepCount >= 0 else {
            headerView.timeRemainingLabel.textColor = TimeRemainingLabel.appearance(for: traitCollection).textColor
            return
        }
        
        guard routeProgress.legIndex < routeProgress.congestionTravelTimesSegmentsByStep.count,
            routeProgress.currentLegProgress.stepIndex < routeProgress.congestionTravelTimesSegmentsByStep[routeProgress.legIndex].count else { return }
        
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

        // Update text color on time remaining based on congestion level
        if routeProgress.durationRemaining < 60 {
            headerView.congestionLevel = .unknown
        } else {
            if let max = remainingStepCongestionTotals.max(by: { a, b in a.value < b.value }) {
                headerView.congestionLevel = max.key
            } else {
                headerView.congestionLevel = .unknown
            }
        }
    }
        
    func notifyAlertLevelDidChange() {
        if let visibleIndexPaths = tableView.indexPathsForVisibleRows {
            tableView.reloadRows(at: visibleIndexPaths, with: .fade)
        }
    }
}

extension RouteTableViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return routeController.routeProgress.route.legs.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Don't display section header if there is only one step
        guard routeController.routeProgress.route.legs.count > 1 else {
            return nil
        }
        let leg = routeController.routeProgress.route.legs[section]
        
        let sourceName = leg.source.name
        let destinationName = leg.destination.name
        let majorWays = leg.name.components(separatedBy: ", ")
        
        if let destinationName = destinationName?.nonEmptyString, majorWays.count > 1 {
            let summary = String.localizedStringWithFormat(NSLocalizedString("LEG_MAJOR_WAYS_FORMAT", bundle: .mapboxNavigation, value: "%@ and %@", comment: "Format for displaying the first two major ways"), majorWays[0], majorWays[1])
            return String.localizedStringWithFormat(NSLocalizedString("WAYPOINT_DESTINATION_VIA_WAYPOINTS_FORMAT", bundle: .mapboxNavigation, value: "%@, via %@", comment: "Format for displaying destination and intermediate waypoints; 1 = source ; 2 = destinations"), destinationName, summary)
        } else if let sourceName = sourceName?.nonEmptyString, let destinationName = destinationName?.nonEmptyString {
            return String.localizedStringWithFormat(NSLocalizedString("WAYPOINT_SOURCE_DESTINATION_FORMAT", bundle: .mapboxNavigation, value: "%@ and %@", comment: "Format for displaying start and endpoint for leg; 1 = source ; 2 = destination"), sourceName, destinationName)
        } else {
            return leg.name
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routeController.routeProgress.route.legs[section].steps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RouteTableViewCellIdentifier, for: indexPath) as! RouteTableViewCell
        let legs = routeController.routeProgress.route.legs
        
        
        cell.step = legs[indexPath.section].steps[indexPath.row]
        
        if indexPath.section < routeController.routeProgress.legIndex || (indexPath.section == routeController.routeProgress.legIndex && indexPath.row <= routeController.routeProgress.currentLegProgress.stepIndex) {
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
