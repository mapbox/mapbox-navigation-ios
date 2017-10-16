import UIKit
import MapboxCoreNavigation
import AVFoundation

struct FeedbackItem {
    var title: String
    var image: UIImage
    var feedbackType: FeedbackType
    var backgroundColor: UIColor
    var audio: Data?
}

class FeedbackViewController: UIViewController, UIGestureRecognizerDelegate, AVAudioRecorderDelegate {
    
    typealias FeedbackSection = [FeedbackItem]
    
    var sections = [FeedbackSection]()
    let cellReuseIdentifier = "collectionViewCellId"
    
    typealias SendFeedbackHandler = (FeedbackItem) -> ()
    
    var sendFeedbackHandler: SendFeedbackHandler?
    var dismissFeedbackHandler: (() -> ())?
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var recordingAudioLabel: UILabel!
    
    var recordingSession: AVAudioSession?
    var audioRecorder: AVAudioRecorder? {
        didSet {
            recordingAudioLabel.isHidden = !recordingAudioLabel.isHidden
        }
    }
    
    var pulsingAnimation:CABasicAnimation {
        let pulseAnimation:CABasicAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1
        pulseAnimation.fromValue = 1
        pulseAnimation.toValue = 1.2
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .greatestFiniteMagnitude
        return pulseAnimation
    }
    
    var currentAudioFile: URL?
    
    class func loadFromStoryboard() -> FeedbackViewController {
        let storyboard = UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
        return storyboard.instantiateViewController(withIdentifier: "FeedbackViewController") as! FeedbackViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        containerView.applyDefaultCornerRadiusShadow(cornerRadius: 16)
        
        recordingSession = AVAudioSession.sharedInstance()
        
        recordingSession?.requestRecordPermission() { [unowned self] allowed in
            if allowed {
                let lpgr : UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.didTapCell(_:)))
                lpgr.minimumPressDuration = 0.5
                lpgr.delegate = self
                lpgr.delaysTouchesBegan = true
                self.collectionView?.addGestureRecognizer(lpgr)
            }
        }
        
        let accidentImage       = Bundle.mapboxNavigation.image(named: "feedback_car_crash")!.withRenderingMode(.alwaysTemplate)
        let hazardImage         = Bundle.mapboxNavigation.image(named: "feedback_hazard")!.withRenderingMode(.alwaysTemplate)
        let roadClosedImage     = Bundle.mapboxNavigation.image(named: "feedback_road_closed")!.withRenderingMode(.alwaysTemplate)
        let unallowedTurnImage  = Bundle.mapboxNavigation.image(named: "feedback_turn_not_allowed")!.withRenderingMode(.alwaysTemplate)
        let routingImage        = Bundle.mapboxNavigation.image(named: "feedback_routing")!.withRenderingMode(.alwaysTemplate)
        let otherImage          = Bundle.mapboxNavigation.image(named: "feedback_other")!.withRenderingMode(.alwaysTemplate)
        
        let accidentTitle       = NSLocalizedString("FEEDBACK_ACCIDENT", bundle: .mapboxNavigation, value: "Accident", comment: "Feedback type for Accident")
        let hazardTitle         = NSLocalizedString("FEEDBACK_HAZARD", bundle: .mapboxNavigation, value: "Hazard", comment: "Feedback type for Hazard")
        let closureTitle        = NSLocalizedString("FEEDBACK_CLOSURE", bundle: .mapboxNavigation, value: "Closure", comment: "Feedback type for Closure")
        let unallowedTurnTitle  = NSLocalizedString("FEEDBACK_UNALLOWED_TURN", bundle: .mapboxNavigation, value: "Not Allowed", comment: "Feedback type for Unallowed Turn")
        let confusingTitle      = NSLocalizedString("FEEDBACK_CONFUSING", bundle: .mapboxNavigation, value: "Confusing", comment: "Feedback type for Confusing")
        let otherIssueTitle     = NSLocalizedString("FEEDBACK_OTHER", bundle: .mapboxNavigation, value: "Other Issue", comment: "Feedback type for Other Issue")
        
        let accident        = FeedbackItem(title: accidentTitle,        image: accidentImage,       feedbackType: .accident,        backgroundColor: #colorLiteral(red: 0.9347146749, green: 0.5047877431, blue: 0.1419634521, alpha: 1), audio:  nil)
        let hazard          = FeedbackItem(title: hazardTitle,          image: hazardImage,         feedbackType: .hazard,          backgroundColor: #colorLiteral(red: 0.9347146749, green: 0.5047877431, blue: 0.1419634521, alpha: 1), audio:  nil)
        let roadClosed      = FeedbackItem(title: closureTitle,         image: roadClosedImage,     feedbackType: .roadClosed,      backgroundColor: #colorLiteral(red: 0.9823123813, green: 0.6965931058, blue: 0.1658670604, alpha: 1), audio:  nil)
        let unallowedTurn   = FeedbackItem(title: unallowedTurnTitle,   image: unallowedTurnImage,  feedbackType: .unallowedTurn,   backgroundColor: #colorLiteral(red: 0.9823123813, green: 0.6965931058, blue: 0.1658670604, alpha: 1), audio:  nil)
        let routingError    = FeedbackItem(title: confusingTitle,       image: routingImage,        feedbackType: .routingError,    backgroundColor: #colorLiteral(red: 0.9823123813, green: 0.6965931058, blue: 0.1658670604, alpha: 1), audio:  nil)
        let other           = FeedbackItem(title: otherIssueTitle,      image: otherImage,          feedbackType: .general,         backgroundColor: #colorLiteral(red: 0.9823123813, green: 0.6965931058, blue: 0.1658670604, alpha: 1), audio:  nil)
        
        sections = [
            [accident, hazard],
            [roadClosed, unallowedTurn],
            [routingError, other]
        ]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        perform(#selector(dismissFeedback), with: nil, afterDelay: 5)
    }
    
    @IBAction func cancel(_ sender: Any) {
        dismissFeedback()
    }
    
    func stopAnimations(feedbackItem: FeedbackItem) {
        
        sendFeedbackHandler?(feedbackItem)
        
        for view in collectionView.visibleCells {
            view.layer.removeAllAnimations()
        }
        
        abortAutodismiss()
    }
    
    func didTapCell(_ sender: UIGestureRecognizer) {
        guard sender.state == .began || sender.state == .ended else { return }
        
        abortAutodismiss()
        
        let touchLocation = sender.location(in: self.collectionView)
        
        if let indexPath = self.collectionView.indexPathForItem(at: touchLocation) {
            // get the cell at indexPath (the one you long pressed)
            let cell = self.collectionView.cellForItem(at: indexPath) as! FeedbackCollectionViewCell
            cell.layer.add(pulsingAnimation, forKey: "animateOpacity")
            
            var item = sections[indexPath.section][indexPath.row]
            
            if audioRecorder == nil {
                startRecording(type: item.feedbackType)
            }
            
            guard sender.state != .ended else {
                finishRecording()
                if let path = currentAudioFile, let fileData = NSData(contentsOfFile: path.path) as Data? {
                    item.audio = fileData
                }
                stopAnimations(feedbackItem: item)
                return
            }
        }
    }
    
    
    func startRecording(type: FeedbackType) {
        currentAudioFile = getDocumentsDirectory().appendingPathComponent("recording-\(type)-\(Date()).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: currentAudioFile!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func finishRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
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
        let width = collectionView.bounds.midX
        return CGSize(width: width, height: 134)
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

