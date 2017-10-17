import UIKit
import MapboxCoreNavigation

extension FeedbackViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        abortAutodismiss()
        return DismissAnimator()
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentAnimator(height: 310)
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}

struct FeedbackItem {
    var title: String
    var image: UIImage
    var feedbackType: FeedbackType
    var backgroundColor: UIColor
}

class FeedbackViewController: UIViewController, DismissDraggable {

    typealias FeedbackSection = [FeedbackItem]
    typealias SendFeedbackHandler = (FeedbackItem) -> ()
    
    var sendFeedbackHandler: SendFeedbackHandler?
    var dismissFeedbackHandler: (() -> ())?
    var sections = [FeedbackSection]()
    
    let cellReuseIdentifier = "collectionViewCellId"
    let interactor = Interactor()
    
    let autodismissInterval: TimeInterval = 5
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var progressBar: ProgressBar!
    
    class func loadFromStoryboard() -> FeedbackViewController {
        let storyboard = UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
        return storyboard.instantiateViewController(withIdentifier: "FeedbackViewController") as! FeedbackViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        transitioningDelegate = self
        progressBar.progress = 1
        enableDraggableDismiss()
        
        let instructionTimingImage      = Bundle.mapboxNavigation.image(named: "feedback_routing")!.withRenderingMode(.alwaysTemplate)
        let confusingInstructionImage   = Bundle.mapboxNavigation.image(named: "feedback_hazard")!.withRenderingMode(.alwaysTemplate)
        let notAllowedImage             = Bundle.mapboxNavigation.image(named: "feedback_turn_not_allowed")!.withRenderingMode(.alwaysTemplate)
        let gpsInaccurateImage          = Bundle.mapboxNavigation.image(named: "feedback_other")!.withRenderingMode(.alwaysTemplate)
        let badRouteImage               = Bundle.mapboxNavigation.image(named: "feedback_road_closed")!.withRenderingMode(.alwaysTemplate)
        let reportTrafficImage          = Bundle.mapboxNavigation.image(named: "feedback_car_crash")!.withRenderingMode(.alwaysTemplate)
        
        let instructionTimingTitle      = NSLocalizedString("FEEDBACK_INSTRUCTION_TIMING", bundle: .mapboxNavigation, value: "Instruction \nTiming", comment: "Feedback type for Instruction Timing")
        let confusingInstructionTitle   = NSLocalizedString("FEEDBACK_CONFUSING_INSTRUCTION", bundle: .mapboxNavigation, value: "Confusing \nInstruction", comment: "Feedback type for Confusing Instruction")
        let notAllowedTitle             = NSLocalizedString("FEEDBACK_NOT_ALLOWED", bundle: .mapboxNavigation, value: "Not \nAllowed", comment: "Feedback type for turn not allowed")
        let gpsInaccurateTitle          = NSLocalizedString("FEEDBACK_GPS_INACCURATE", bundle: .mapboxNavigation, value: "GPS \nInaccurate", comment: "Feedback type for inaccurate GPS")
        let badRouteTitle               = NSLocalizedString("FEEDBACK_BAD_ROUTE", bundle: .mapboxNavigation, value: "Bad \nRoute", comment: "Feedback type for Bad Route")
        let reportTrafficTitle          = NSLocalizedString("FEEDBACK_REPORT_TRAFFIC", bundle: .mapboxNavigation, value: "Report \nTraffic", comment: "Feedback type for Report Traffic")
        
        let instructionTiming       = FeedbackItem(title: instructionTimingTitle,       image: instructionTimingImage,      feedbackType: .instructionTiming,       backgroundColor: #colorLiteral(red: 0.9347146749, green: 0.5047877431, blue: 0.1419634521, alpha: 1))
        let confusingInstruction    = FeedbackItem(title: confusingInstructionTitle,    image: confusingInstructionImage,   feedbackType: .confusingInstruction,    backgroundColor: #colorLiteral(red: 0.9347146749, green: 0.5047877431, blue: 0.1419634521, alpha: 1))
        let notAllowed              = FeedbackItem(title: notAllowedTitle,              image: notAllowedImage,             feedbackType: .unallowedTurn,           backgroundColor: #colorLiteral(red: 0.9347146749, green: 0.5047877431, blue: 0.1419634521, alpha: 1))
        let gpsInaccurate           = FeedbackItem(title: gpsInaccurateTitle,           image: gpsInaccurateImage,          feedbackType: .inaccurateGPS,           backgroundColor: #colorLiteral(red: 0.9823123813, green: 0.6965931058, blue: 0.1658670604, alpha: 1))
        let badRoute                = FeedbackItem(title: badRouteTitle,                image: badRouteImage,               feedbackType: .badRoute,                backgroundColor: #colorLiteral(red: 0.9823123813, green: 0.6965931058, blue: 0.1658670604, alpha: 1))
        let reportTraffic           = FeedbackItem(title: reportTrafficTitle,           image: reportTrafficImage,          feedbackType: .reportTraffic,           backgroundColor: #colorLiteral(red: 0.9823123813, green: 0.6965931058, blue: 0.1658670604, alpha: 1))
        
        progressBar.barColor = #colorLiteral(red: 0.9347146749, green: 0.5047877431, blue: 0.1419634521, alpha: 1)
        
        sections = [
            [instructionTiming, confusingInstruction, notAllowed],
            [gpsInaccurate, badRoute, reportTraffic]
        ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        progressBar.progress = 1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        perform(#selector(dismissFeedback), with: nil, afterDelay: autodismissInterval)
        UIView.animate(withDuration: autodismissInterval, delay: 0, options: [.curveLinear], animations: {
            self.progressBar.progress = 0
        }, completion: nil)
    }
    
    func presentError(_ message: String) {
        let controller = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            controller.dismiss(animated: true, completion: nil)
        }
        
        controller.addAction(action)
        present(controller, animated: true, completion: nil)
    }
    
    func abortAutodismiss() {
        progressBar.progress = 0
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(dismissFeedback), object: nil)
    }
    
    func dismissFeedback() {
        abortAutodismiss()
        dismissFeedbackHandler?()
    }
}

extension FeedbackViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! FeedbackCollectionViewCell
        let item = sections[indexPath.section][indexPath.row]
        
        cell.titleLabel.text = item.title
        cell.imageView.tintColor = .white
        cell.imageView.image = item.image
        cell.circleView.backgroundColor = item.backgroundColor
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        abortAutodismiss()
    }
}

extension FeedbackViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        abortAutodismiss()
        let item = sections[indexPath.section][indexPath.row]
        sendFeedbackHandler?(item)
    }
}

extension FeedbackViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = floor(collectionView.bounds.width / 3)
        return CGSize(width: width, height: width+5)
    }
}

class FeedbackCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        circleView.layer.cornerRadius = circleView.bounds.midY
    }
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 0.6015074824) : .clear
            imageView.tintColor = isHighlighted ? .lightGray : .white
        }
    }
}

