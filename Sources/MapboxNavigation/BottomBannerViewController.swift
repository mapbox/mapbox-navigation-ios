import CoreLocation
import UIKit
import MapboxCoreNavigation
import MapboxDirections

/**
 `BottomBannerViewControllerDelegate` provides a method for reacting to the user tapping on the "cancel" button in the `BottomBannerViewController`.
 */
public protocol BottomBannerViewControllerDelegate: AnyObject {
    /**
     A method that is invoked when the user taps on the cancel button.
     - parameter sender: The button that originated the tap event.
     */
    func didTapCancel(_ sender: Any)
}

/**
 A user interface element designed to display the estimated arrival time, distance, and time remaining, as well as give the user a control the cancel the navigation session.
 */
@IBDesignable
open class BottomBannerViewController: UIViewController, NavigationComponent {
    
    var previousProgress: RouteProgress?
    var timer: DispatchTimer?
    
    let dateFormatter = DateFormatter()
    let dateComponentsFormatter = DateComponentsFormatter()
    let distanceFormatter = DistanceFormatter()
    
    var verticalCompactConstraints = [NSLayoutConstraint]()
    var verticalRegularConstraints = [NSLayoutConstraint]()
    
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
    
    // MARK: Child Views Configuration
    
    /**
     A padded spacer view that covers the bottom safe area of the device, if any.
     */
    lazy open var bottomPaddingView: BottomPaddingView = .forAutoLayout()
    
    /**
     The main bottom banner view that all UI components are added to.
     */
    lazy open var bottomBannerView: BottomBannerView = .forAutoLayout()
    
    /**
     The label that displays the estimated time until the user arrives at the final destination.
     */
    open var timeRemainingLabel: TimeRemainingLabel!
    
    /**
     The label that represents the user's remaining distance.
     */
    open var distanceRemainingLabel: DistanceRemainingLabel!
    
    /**
     The label that displays the user's estimate time of arrival.
     */
    open var arrivalTimeLabel: ArrivalTimeLabel!
    
    /**
     The button that, by default, allows the user to cancel the navigation session.
     */
    open var cancelButton: CancelButton!
    
    /**
     A vertical divider that seperates the cancel button and informative labels.
     */
    open var verticalDividerView: SeparatorView!
    
    /**
     A horizontal divider that adds visual separation between the bottom banner and its superview.
     */
    open var horizontalDividerView: SeparatorView!
    
    /**
     A vertical separator for the trailing side of the view.
     */
    var trailingSeparatorView: SeparatorView!
    
    // MARK: Setup and Initialization
    
    /**
     The delegate for the view controller.
     - seealso: BottomBannerViewControllerDelegate
     */
    open weak var delegate: BottomBannerViewControllerDelegate?
    
    /**
     Initializes a `BottomBannerViewController` that provides ETA, Distance to arrival, and Time to arrival.
     
     - parameter nibNameOrNil: Ignored.
     - parameter nibBundleOrNil: Ignored.
     */
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        commonInit()
    }

    /**
     Initializes a `BottomBannerViewController` that provides ETA, Distance to arrival, and Time to arrival.
     
     - parameter aDecoder: Ignored.
     */
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    deinit {
        removeTimer()
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeTimer()
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        setupRootViews()
        setupBottomBanner()
        cancelButton.addTarget(self, action: #selector(BottomBannerViewController.cancel(_:)), for: .touchUpInside)
    }
    
    private func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(removeTimer), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resetETATimer), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    func commonInit() {
        dateFormatter.timeStyle = .short
        dateComponentsFormatter.allowedUnits = [.hour, .minute]
        dateComponentsFormatter.unitsStyle = .abbreviated
    }
    
    @IBAction func cancel(_ sender: Any) {
        delegate?.didTapCancel(sender)
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        timeRemainingLabel.text = "22 min"
        distanceRemainingLabel.text = "4 mi"
        arrivalTimeLabel.text = "10:09"
    }
    
    // MARK: NavigationComponent support
    
    public func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        refreshETA()
    }
    
    public func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        resetETATimer()
        updateETA(routeProgress: progress)
        previousProgress = progress
    }
    
    @objc func removeTimer() {
        timer?.disarm()
        timer = nil
    }
    
    @objc func resetETATimer() {
        removeTimer()
        timer = MapboxCoreNavigation.DispatchTimer(countdown: .seconds(30), repeating: .seconds(30)) { [weak self] in
            self?.refreshETA()
        }
        timer?.arm()
    }
    
    func refreshETA() {
        guard let progress = previousProgress else { return }
        updateETA(routeProgress: progress)
    }
    
    func updateETA(routeProgress: RouteProgress) {
        guard let arrivalDate = NSCalendar.current.date(byAdding: .second, value: Int(routeProgress.durationRemaining), to: Date()) else { return }
        arrivalTimeLabel.text = dateFormatter.string(from: arrivalDate)

        if routeProgress.durationRemaining < 5 {
            distanceRemainingLabel.text = nil
        } else {
            distanceRemainingLabel.text = distanceFormatter.string(from: routeProgress.distanceRemaining)
        }

        dateComponentsFormatter.unitsStyle = routeProgress.durationRemaining < 3600 ? .short : .abbreviated

        if let hardcodedTime = dateComponentsFormatter.string(from: 61), routeProgress.durationRemaining < 60 {
            timeRemainingLabel.text = String.localizedStringWithFormat(NSLocalizedString("LESS_THAN", bundle: .mapboxNavigation, value: "<%@", comment: "Format string for a short distance or time less than a minimum threshold; 1 = duration remaining"), hardcodedTime)
        } else {
            timeRemainingLabel.text = dateComponentsFormatter.string(from: routeProgress.durationRemaining)
        }
        
        guard let congestionForRemainingLeg = routeProgress.averageCongestionLevelRemainingOnLeg else { return }
        congestionLevel = congestionForRemainingLeg
    }
}
