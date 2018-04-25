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
    
    static let sceneTitle = NSLocalizedString("FEEDBACK_TITLE", value: "Report Problem", comment: "Title of view controller for sending feedback")
    static let cellReuseIdentifier = "collectionViewCellId"
    static let autoDismissInterval: TimeInterval = 10
    static let verticalCellPadding: CGFloat = 20.0
    
    let interactor = Interactor()
    
    lazy var collectionView: UICollectionView = {
        let view: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.delegate = self
        view.dataSource = self
        view.register(FeedbackCollectionViewCell.self, forCellWithReuseIdentifier: FeedbackCollectionViewCell.defaultIdentifier)
        return view
    }()
    
    lazy var reportIssueLabel: UILabel = {
        let label: UILabel = .forAutoLayout()
        label.textAlignment = .center
        label.text = FeedbackViewController.sceneTitle
        return label
    }()
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = 0.0
        return layout
    }()
    
    lazy var progressBar: ProgressBar = .forAutoLayout()
    
    var draggableHeight: CGFloat {
        // V:|-0-recordingAudioLabel.height-collectionView.height-progressBar.height-0-|
        let padding = (flowLayout.sectionInset.top + flowLayout.sectionInset.bottom) * CGFloat(collectionView.numberOfRows)
        let collectionViewHeight = flowLayout.itemSize.height * CGFloat(collectionView.numberOfRows) + padding + view.safeArea.bottom
        let fullHeight = reportIssueLabel.bounds.height+collectionViewHeight+progressBar.bounds.height
        return fullHeight
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        view.layoutIfNeeded()
        //FIXME: This is a workaround to ensure that the FVC looks good on non 375pt width screens, as the dynamic sizing logic isn't currently working properly.
        flowLayout.itemSize = collectionView(collectionView, layout: flowLayout, sizeForItemAt: IndexPath(item: 0, section: 0))
        transitioningDelegate = self
        view.backgroundColor = .white
        progressBar.barColor = #colorLiteral(red: 0.9347146749, green: 0.5047877431, blue: 0.1419634521, alpha: 1)
        enableDraggableDismiss()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        progressBar.progress = 1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: FeedbackViewController.autoDismissInterval) {
            self.progressBar.progress = 0
        }
        
        enableAutoDismiss()
    }
    
    func enableAutoDismiss() {
        abortAutodismiss()
        perform(#selector(dismissFeedback), with: nil, afterDelay: FeedbackViewController.autoDismissInterval)
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
    
    private func setupViews() {
        [reportIssueLabel, collectionView, progressBar].forEach(view.addSubview(_:))
    }
    
    private func setupConstraints() {
        let labelTop = reportIssueLabel.topAnchor.constraint(equalTo: view.topAnchor)
        let labelHeight = reportIssueLabel.heightAnchor.constraint(equalToConstant: 30.0)
        let labelLeading = reportIssueLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let labelTrailing = reportIssueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let collectionLabelSpacing = collectionView.topAnchor.constraint(equalTo: reportIssueLabel.bottomAnchor)
        let collectionLeading = collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let collectionTrailing = collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let collectionBarSpacing = collectionView.bottomAnchor.constraint(equalTo: progressBar.topAnchor)
        let barHeight = progressBar.heightAnchor.constraint(equalToConstant: 6.0)
        let barLeading = progressBar.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let barTrailing = progressBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let barBottom = progressBar.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        
        let constraints = [labelTop, labelHeight, labelLeading, labelTrailing,
                           collectionLabelSpacing, collectionLeading, collectionTrailing, collectionBarSpacing,
                           barHeight, barLeading, barTrailing, barBottom]
      
        NSLayoutConstraint.activate(constraints)
    }
}

extension FeedbackViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedbackCollectionViewCell.defaultIdentifier, for: indexPath) as! FeedbackCollectionViewCell
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
        return CGSize(width: width, height: width + FeedbackViewController.verticalCellPadding)
    }
}
