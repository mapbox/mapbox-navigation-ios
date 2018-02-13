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

class FeedbackViewController: UIViewController, DismissDraggable, UIGestureRecognizerDelegate {
    
    typealias SendFeedbackHandler = (FeedbackItem) -> Void
    
    var sendFeedbackHandler: SendFeedbackHandler?
    var dismissFeedbackHandler: (() -> Void)?
    var sections = [FeedbackSection]()
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
    }
    
    func enableAutoDismiss() {
        abortAutodismiss()
        perform(#selector(dismissFeedback), with: nil, afterDelay: autoDismissInterval)
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
    
    @objc func dismissFeedback() {
        abortAutodismiss()
        dismissFeedbackHandler?()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only respond to touches outside/behind the view
        let isDescendant = touch.view?.isDescendant(of: view) ?? true
        return !isDescendant
    }
    
    @objc func handleDismissTap(sender: UITapGestureRecognizer) {
        dismissFeedback()
    }
}

extension FeedbackViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! FeedbackCollectionViewCell
        let item = sections[indexPath.section][indexPath.row]
        
        cell.titleLabel.text = item.title
        cell.imageView.tintColor = .clear
        cell.imageView.image = item.image
        
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
    
    var longPress: UILongPressGestureRecognizer?
    var originalTransform: CGAffineTransform?
    
    override func awakeFromNib() {
        super.awakeFromNib()
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
}
