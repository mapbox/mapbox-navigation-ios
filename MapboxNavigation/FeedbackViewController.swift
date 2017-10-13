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

class FeedbackViewController: UIViewController, DismissDraggable, UIGestureRecognizerDelegate, AVAudioRecorderDelegate {
    
    var allowRecordedAudioFeedback = false
    
    typealias SendFeedbackHandler = (FeedbackItem) -> ()
    
    var sendFeedbackHandler: SendFeedbackHandler?
    var dismissFeedbackHandler: (() -> ())?
    var sections = [FeedbackSection]()
    
    let cellReuseIdentifier = "collectionViewCellId"
    let interactor = Interactor()
    
    let autodismissInterval: TimeInterval = 5
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var recordingAudioLabel: UILabel!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var progressBar: ProgressBar!
    
    var recordingSession: AVAudioSession?
    var audioRecorder: AVAudioRecorder? {
        didSet {
            recordingAudioLabel.isHidden = !recordingAudioLabel.isHidden
        }
    }
    
    var activeFeedbackItem: FeedbackItem?
    
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
        
        UIView.animate(withDuration: autodismissInterval) {
            self.progressBar.progress = 0
        }
        
        perform(#selector(dismissFeedback), with: nil, afterDelay: autodismissInterval)
        
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
        recordingSession = AVAudioSession.sharedInstance()
        recordingSession?.requestRecordPermission() { [unowned self] allowed in
            guard allowed else { return }
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(self.didTapCell(_:)))
            longPress.minimumPressDuration = 0.5
            longPress.delegate = self
            longPress.delaysTouchesBegan = true
            self.collectionView?.addGestureRecognizer(longPress)
        }
    }
    
    func didTapCell(_ sender: UIGestureRecognizer) {
        guard sender.state == .began || sender.state == .ended else { return }
        
        abortAutodismiss()
        
        let touchLocation = sender.location(in: self.collectionView)
        
        if let indexPath = self.collectionView.indexPathForItem(at: touchLocation) {
            // get the cell at indexPath (the one you long pressed)
            let cell = self.collectionView.cellForItem(at: indexPath) as! FeedbackCollectionViewCell
            cell.layer.add(pulsingAnimation, forKey: "animateScale")

            activeFeedbackItem = sections[indexPath.section][indexPath.row]

            if audioRecorder == nil {
                startRecording()
            }

            if sender.state == .ended {
                finishRecording()
            }
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if let fileData = NSData(contentsOfFile: recorder.url.path) as Data? {
            activeFeedbackItem!.audio = fileData
            sendFeedbackHandler?(activeFeedbackItem!)
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

