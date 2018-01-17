import UIKit
import MapboxCoreNavigation
import MapboxDirections

class TopBannerViewController: UIViewController, StatusViewDelegate, InstructionsBannerViewDelegate {
    //MARK: - Class Constants
    static let lanesBackgroundColor: UIColor = UIColor(white: 247/255, alpha: 1.0)
    static let statusBackgroundColor: UIColor = UIColor.black.withAlphaComponent(2.0/3.0)
    
    //MARK: - Outlets
    @IBOutlet weak var instructionsBanner: InstructionsBannerView!
    @IBOutlet weak var laneGuidanceBanner: LanesView!
    @IBOutlet weak var nextBanner: NextBannerView!
    @IBOutlet weak var statusBanner: StatusView!
    
    //MARK: - Properties
    var delegate: TopBannerViewControllerDelegate?
    var isSimulatedNavigation = false
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setBackgroundColors()
    }
    
    // MARK: - Initial State
    private func setupUI() {
        instructionsBanner.delegate = self
        statusBanner.delegate = self
        [laneGuidanceBanner, nextBanner, statusBanner].forEach { $0.isHidden = true }
    }
    
    private func setBackgroundColors() {
        instructionsBanner.backgroundColor = .white
        laneGuidanceBanner.backgroundColor = TopBannerViewController.lanesBackgroundColor
        nextBanner.backgroundColor = .white
        statusBanner.backgroundColor = TopBannerViewController.statusBackgroundColor
    }

    // MARK: - Model Updating
    func update(progress: RouteProgress, location: CLLocation, secondsRemaining: TimeInterval) {
        //update banner
        instructionsBanner.update(progress: progress.currentLegProgress, location: location, secondsRemaining: secondsRemaining)
        
        //update lanes
        if let upcomingStep = progress.currentLegProgress?.upComingStep, !progress.currentLegProgress.userHasArrivedAtWaypoint {
            updateLaneGuidance(step: upcomingStep, durationRemaining: progress.currentLegProgress.currentStepProgress.durationRemaining)
        }
        
        //update next
        updateNextBanner(routeProgress: progress)
        
    }

    // MARK: - UI Manipulation
    func showStatus(text: String, for duration: TimeInterval, showingSpinner: Bool = false, animated: Bool = true) {
        statusBanner.show(text, showSpinner: showingSpinner, animated: animated)
        statusBanner.hide(delay: duration, animated: animated)
    }
    
    // MARK: Lane Views
    private func updateLaneGuidance(step: RouteStep, durationRemaining: TimeInterval) {
        laneGuidanceBanner.updateLaneViews(step: step, durationRemaining: durationRemaining)
        laneGuidanceBanner.hasLanes ? show(view: laneGuidanceBanner) : hide(view: laneGuidanceBanner)
    }
    
    // MARK: Next Banner
    private func updateNextBanner(routeProgress: RouteProgress) {
        //FIXME: Testing override - Remove this!
        let tooLong = Double.greatestFiniteMagnitude //RouteControllerHighAlertInterval * RouteControllerLinkedInstructionBufferMultiplier
        
        guard let progress = routeProgress.currentLegProgress,
            let upcoming = progress.upComingStep,
            let subsequent = progress.stepAfter(upcoming),
            laneGuidanceBanner.isHidden, //banner should not show if the lane view is visible
            upcoming.expectedTravelTime <= tooLong,  //banner should not show if the upcoming step is time-consuming.
            subsequent.expectedTravelTime <= tooLong, //banner should not show if the current step's completion is time-consuming.
            let instruction = upcoming.instructionsDisplayedAlongStep?.last else {  //banner should not show if the upcoming step contains no instructions.
                hide(view: nextBanner)
                return
        }
        
        nextBanner.update(step: subsequent, instruction: instruction)
        show(view: nextBanner)
    }
    
    
    //MARK: - Utility Functions
    private func show(view: UIView, animated: Bool = true) {
        guard view.isHidden else { return }
        let show = { view.isHidden = false }
        animated ? UIView.defaultAnimation(0.3, animations:show, completion: nil) : show()
    }
    
    private func hide(view: UIView, animated: Bool = true) {
        guard !view.isHidden else { return }
        let hide = { view.isHidden = true }
        animated ? UIView.defaultAnimation(0.3, animations:hide, completion: nil) : hide()
    }

    //MARK: - InstructionsBannerViewDelegate
    func didTapInstructionsBanner(_ sender: BaseInstructionsBannerView) {
        delegate?.didTapInstructionsBanner(sender)
    }

    //MARK: StatusViewDelegate
    func statusView(_ statusView: StatusView, valueChangedTo value: Double) {
        delegate?.statusView(statusView, valueChangedTo: value)
    }
}

//MARK: - TopBannerViewControllerDelegate
protocol TopBannerViewControllerDelegate: StatusViewDelegate, InstructionsBannerViewDelegate {}
