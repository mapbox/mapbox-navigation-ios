import UIKit
import MapboxCoreNavigation
import MapboxDirections

protocol BottomBannerViewDelegate: class {
    func didCancel()
}

@IBDesignable
@objc(MBBottomBannerView)
class BottomBannerView: UIView {
    
    weak var timeRemainingLabel: TimeRemainingLabel!
    weak var distanceRemainingLabel: DistanceRemainingLabel!
    weak var arrivalTimeLabel: ArrivalTimeLabel!
    weak var cancelButton: CancelButton!
    weak var separatorView: SeparatorView!
    
    let dateFormatter = DateFormatter()
    let dateComponentsFormatter = DateComponentsFormatter()
    let distanceFormatter = DistanceFormatter(approximate: true)
    let routeStepFormatter = RouteStepFormatter()
    weak var routeController: RouteController!
    
    weak var delegate: BottomBannerViewDelegate?
    
    var congestionLevel: CongestionLevel = .unknown {
        didSet {
            switch congestionLevel {
            case .unknown:
                timeRemainingLabel.textColor = timeRemainingLabel.trafficUnknownColor
            case .low:
                timeRemainingLabel.textColor = timeRemainingLabel.trafficLowColor
            case .moderate:
                timeRemainingLabel.textColor = timeRemainingLabel.trafficModerateColor
            case .heavy:
                timeRemainingLabel.textColor = timeRemainingLabel.trafficHeavyColor
            case .severe:
                timeRemainingLabel.textColor = timeRemainingLabel.trafficSevereColor
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        distanceFormatter.numberFormatter.locale = .nationalizedCurrent
        dateFormatter.timeStyle = .short
        dateComponentsFormatter.allowedUnits = [.hour, .minute]
        dateComponentsFormatter.unitsStyle = .abbreviated
        
        setupViews()
        setupLayout()
        
        cancelButton.addTarget(self, action: #selector(BottomBannerView.cancel(_:)), for: .touchUpInside)
    }
    
    @IBAction func cancel(_ sender: Any) {
        delegate?.didCancel()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        separatorView.backgroundColor = .red
        timeRemainingLabel.text = "22 min"
        distanceRemainingLabel.text = "4 mi"
        arrivalTimeLabel.text = "10:09"
    }
    
    func updateETA(routeProgress: RouteProgress) {
        let arrivalDate = NSCalendar.current.date(byAdding: .second, value: Int(routeProgress.durationRemaining), to: Date())
        arrivalTimeLabel.text = dateFormatter.string(from: arrivalDate!)

        if routeProgress.durationRemaining < 5 {
            distanceRemainingLabel.text = nil
        } else {
            distanceRemainingLabel.text = distanceFormatter.string(from: routeProgress.distanceRemaining)
        }

        dateComponentsFormatter.unitsStyle = routeProgress.durationRemaining < 3600 ? .short : .abbreviated

        if routeProgress.durationRemaining < 60 {
            timeRemainingLabel.text = String.localizedStringWithFormat(NSLocalizedString("LESS_THAN", bundle: .mapboxNavigation, value: "<%@", comment: "Format string for a short distance or time less than a minimum threshold; 1 = duration remaining"), dateComponentsFormatter.string(from: 61)!)
        } else {
            timeRemainingLabel.text = dateComponentsFormatter.string(from: routeProgress.durationRemaining)
        }

        let coordinatesLeftOnStepCount = Int(floor((Double(routeProgress.currentLegProgress.currentStepProgress.step.coordinateCount)) * routeProgress.currentLegProgress.currentStepProgress.fractionTraveled))

        guard coordinatesLeftOnStepCount >= 0 else {
            timeRemainingLabel.textColor = TimeRemainingLabel.appearance(for: traitCollection).textColor
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
            congestionLevel = .unknown
        } else {
            if let max = remainingStepCongestionTotals.max(by: { a, b in a.value < b.value }) {
                congestionLevel = max.key
            } else {
                congestionLevel = .unknown
            }
        }
    }
}


