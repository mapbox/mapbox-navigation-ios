import UIKit
import MapboxCoreNavigation
import AVFoundation


extension FeedbackViewController: UIViewControllerTransitioningDelegate {
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        abortAutodismiss()
        return DismissAnimator()
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentAnimator()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}

typealias FeedbackSection = [FeedbackItem]

class FeedbackViewController: UIViewController, DismissDraggable, FeedbackCollectionViewCellDelegate, AVAudioRecorderDelegate {
    
    typealias SendFeedbackHandler = (FeedbackItem) -> ()
    
    var allowRecordedAudioFeedback = false
    var sendFeedbackHandler: SendFeedbackHandler?
    var dismissFeedbackHandler: (() -> ())?
    var sections = [FeedbackSection]()
    var recordingSession: AVAudioSession?
    var audioRecorder: AVAudioRecorder?
    var activeFeedbackItem: FeedbackItem?
    
    let cellReuseIdentifier = "collectionViewCellId"
    let interactor = Interactor()
    let autoDismissInterval: TimeInterval = 10
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var reportIssueLabel: UILabel!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var progressBar: ProgressBar!
    
    var draggableHeight: CGFloat {
        // V:|-0-recordingAudioLabel.height-collectionView.height-progressBar.height-0-|
        let padding = (flowLayout.sectionInset.top + flowLayout.sectionInset.bottom) * CGFloat(collectionView.numberOfRows)
        let collectionViewHeight = flowLayout.itemSize.height * CGFloat(collectionView.numberOfRows) + padding
        let fullHeight = reportIssueLabel.bounds.height+collectionViewHeight+progressBar.bounds.height
        return fullHeight
    }
    
    class func loadFromStoryboard() -> FeedbackViewController {
        let storyboard = UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
        return storyboard.instantiateViewController(withIdentifier: "FeedbackViewController") as! FeedbackViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        transitioningDelegate = self
        progressBar.progress = 1
        progressBar.barColor = #colorLiteral(red: 0.9347146749, green: 0.5047877431, blue: 0.1419634521, alpha: 1)
        enableDraggableDismiss()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: autoDismissInterval) {
            self.progressBar.progress = 0
        }
        
        enableAutoDismiss()
        
        if allowRecordedAudioFeedback {
            validateAudio()
            enableAudioRecording()
        }
    }
    
    func validateAudio() {
        guard Bundle.main.microphoneUsageDescription != nil else {
            assert(false, "If `allowRecordedAudioFeedback` is enabled, `NSMicrophoneUsageDescription` must be added in app plist")
            return
        }
    }
    
    func enableAudioRecording() {
        abortAutodismiss()
        recordingSession = AVAudioSession.sharedInstance()
        recordingSession?.requestRecordPermission() { [unowned self] allowed in
            self.enableAutoDismiss()
        }
    }
    
    func enableAutoDismiss() {
        abortAutodismiss()
        perform(#selector(dismissFeedback), with: nil, afterDelay: autoDismissInterval)
    }
    
    func didLongPress(on cell: FeedbackCollectionViewCell, sender: UILongPressGestureRecognizer) {
        guard sender.state == .began || sender.state == .ended else { return }
        let touchLocation = sender.location(in: self.collectionView)
        guard let indexPath = self.collectionView.indexPathForItem(at: touchLocation) else { return }
        
        abortAutodismiss()
        activeFeedbackItem = sections[indexPath.section][indexPath.row]
        
        if sender.state == .began {
            
            reportIssueLabel.text = NSLocalizedString("RECORDING_AUDIO", bundle: .mapboxNavigation, value: "Recording Audio", comment: "Recording audio for feedback")
            reportIssueLabel.textColor = .red
            
            reportIssueLabel.startRippleAnimation()
            
            if audioRecorder == nil {
                startRecording()
            }
        }
        
        if sender.state == .ended {
            finishRecording()
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if let fileData = NSData(contentsOfFile: recorder.url.path) as Data? {
            activeFeedbackItem!.audio = fileData
            sendFeedbackHandler?(activeFeedbackItem!)
        }
        do {
            try AVAudioSession.sharedInstance().setActive(false, with: [.notifyOthersOnDeactivation])
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func startRecording() {
        guard let audioFile = FileManager().cacheAudioFileLocation else { return }
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFile, settings: settings)
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
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only respond to touches outside/behind the view
        let isDescendant = touch.view?.isDescendant(of: view) ?? true
        return !isDescendant
    }
    
    func handleDismissTap(sender: UITapGestureRecognizer) {
        dismissFeedback()
    }
}

extension FileManager {
    var cacheAudioFileLocation: URL? {
        return self.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("recording-\(Date().timeIntervalSince1970).m4a")
    }
}

extension FeedbackViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! FeedbackCollectionViewCell
        let item = sections[indexPath.section][indexPath.row]
        
        cell.titleLabel.text = item.title
        cell.imageView.tintColor = .clear
        cell.imageView.image = item.image
        cell.delegate = self
        
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

protocol FeedbackCollectionViewCellDelegate: class {
    func didLongPress(on cell: FeedbackCollectionViewCell, sender: UILongPressGestureRecognizer)
}

class FeedbackCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
    
    weak var delegate: FeedbackCollectionViewCellDelegate?
    var longPress: UILongPressGestureRecognizer?
    var originalTransform: CGAffineTransform?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if longPress == nil {
            longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.didLongPress(_:)))
            longPress?.minimumPressDuration = 0.5
            addGestureRecognizer(longPress!)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        circleView.layer.cornerRadius = circleView.bounds.midY
    }
    
    override var isHighlighted: Bool {
        didSet {
            if originalTransform == nil {
                originalTransform = self.imageView.transform
            }
            
            UIView.defaultSpringAnimation(0.3, animations: {
                if self.isHighlighted {
                    self.imageView.transform = self.imageView.transform.scaledBy(x: 0.85, y: 0.85)
                } else {
                    guard let t = self.originalTransform else { return }
                    self.imageView.transform = t
                }
            }, completion: nil)
        }
    }
    
    func didLongPress(_ sender: UILongPressGestureRecognizer) {
        delegate?.didLongPress(on: self, sender: sender)
    }
}

