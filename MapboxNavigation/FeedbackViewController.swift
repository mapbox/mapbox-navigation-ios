import UIKit
import MapboxCoreNavigation
import AVFoundation

extension FeedbackViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentAnimator()
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}

/**
 The `FeedbackViewControllerDelegate` protocol provides methods for responding to feedback events.
 */
public protocol FeedbackViewControllerDelegate: class, UnimplementedLogging {
    /**
     Called when the user opens the feedback form.
     */
    func feedbackViewControllerDidOpen(_ feedbackViewController: FeedbackViewController)
    
    /**
     Called when the user submits a feedback event.
     */
    func feedbackViewController(_ feedbackViewController: FeedbackViewController, didSend feedbackItem: FeedbackItem, uuid: UUID)
    
    /**
     Called when a `FeedbackViewController` is dismissed for any reason without giving explicit feedback.
     */
    func feedbackViewControllerDidCancel(_ feedbackViewController: FeedbackViewController)
}

public extension FeedbackViewControllerDelegate {
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func feedbackViewControllerDidOpen(_ feedbackViewController: FeedbackViewController) {
        logUnimplemented(protocolType: FeedbackViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func feedbackViewController(_ feedbackViewController: FeedbackViewController, didSend feedbackItem: FeedbackItem, uuid: UUID) {
        logUnimplemented(protocolType: FeedbackViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func feedbackViewControllerDidCancel(_ feedbackViewController: FeedbackViewController) {
        logUnimplemented(protocolType: FeedbackViewControllerDelegate.self, level: .debug)
    } 
}

/**
 A view controller containing a grid of buttons the user can use to denote an issue their current navigation experience.
 */
public class FeedbackViewController: UIViewController, DismissDraggable, UIGestureRecognizerDelegate {
    var activeFeedbackItem: FeedbackItem?
    
    static let sceneTitle = NSLocalizedString("FEEDBACK_TITLE", value: "Report Problem", comment: "Title of view controller for sending feedback")
    static let cellReuseIdentifier = "collectionViewCellId"
    static let autoDismissInterval: TimeInterval = 10
    static let verticalCellPadding: CGFloat = 20.0
    static let titleHeaderHeight: CGFloat = 30.0
    static let contentInset: UIEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
    
    let interactor = Interactor()
    /**
     The feedback items that are visible and selectable by the user.
     */
    public var sections: [FeedbackItem] =  [FeedbackType.incorrectVisual(subtype: nil),
                                            FeedbackType.confusingAudio(subtype: nil),
                                            FeedbackType.illegalRoute(subtype: nil),
                                            FeedbackType.roadClosure(subtype: nil),
                                            FeedbackType.routeQuality(subtype: nil)].map { $0.generateFeedbackItem() }
    
    public weak var delegate: FeedbackViewControllerDelegate?
    
    lazy var collectionView: UICollectionView = {
        let view: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.delegate = self
        view.dataSource = self
        view.contentInset = FeedbackViewController.contentInset
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
    
    var draggableHeight: CGFloat {
        let numberOfRows = collectionView.numberOfRows(using: self)
        let padding = (flowLayout.sectionInset.top + flowLayout.sectionInset.bottom) * CGFloat(numberOfRows)
        let indexPath = IndexPath(row: 0, section: 0)
        let collectionViewHeight = collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath).height * CGFloat(numberOfRows) + padding + view.safeArea.bottom
        let fullHeight = reportIssueLabel.bounds.height+collectionViewHeight + FeedbackViewController.titleHeaderHeight + FeedbackViewController.contentInset.top
        return fullHeight
    }
    
    /**
     The events manager used to send feedback events.
     */
    public weak var eventsManager: NavigationEventsManager?
    
    var uuid: UUID? {
        return eventsManager?.recordFeedback()
    }
    
    /**
     Initialize a new FeedbackViewController from a `NavigationEventsManager`.
     */
    public init(eventsManager: NavigationEventsManager) {
        self.eventsManager = eventsManager
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }

    public override func encode(with aCoder: NSCoder) {
        aCoder.encode(eventsManager, forKey: "NavigationEventsManager")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        eventsManager = aDecoder.decodeObject(of: [NavigationEventsManager.self], forKey: "NavigationEventsManager") as? NavigationEventsManager
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = self
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        view.layoutIfNeeded()
        transitioningDelegate = self
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
        }
        enableDraggableDismiss()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.feedbackViewControllerDidOpen(self)
    }
    
    override public func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        
        // Dismiss the feedback view when switching between landscape and portrait mode.
        if traitCollection.verticalSizeClass != newCollection.verticalSizeClass {
            dismissFeedback()
        }
    }
    
    func presentError(_ message: String) {
        let controller = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            controller.dismiss(animated: true, completion: nil)
        }
        
        controller.addAction(action)
        present(controller, animated: true, completion: nil)
    }
    
    /**
     Instantly dismisses the FeedbackViewController if it is currently presented.
     */
    @objc public func dismissFeedback() {
        dismissFeedbackItem()
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only respond to touches outside/behind the view
        let isDescendant = touch.view?.isDescendant(of: view) ?? true
        return !isDescendant
    }
    
    @objc func handleDismissTap(sender: UITapGestureRecognizer) {
        dismissFeedback()
    }
    
    private func setupViews() {
        let children = [reportIssueLabel, collectionView]
        view.addSubviews(children)
    }
    
    private func setupConstraints() {
        let labelTop = reportIssueLabel.topAnchor.constraint(equalTo: view.topAnchor)
        let labelHeight = reportIssueLabel.heightAnchor.constraint(equalToConstant: FeedbackViewController.titleHeaderHeight)
        let labelLeading = reportIssueLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let labelTrailing = reportIssueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let collectionLabelSpacing = collectionView.topAnchor.constraint(equalTo: reportIssueLabel.bottomAnchor)
        let collectionLeading = collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let collectionTrailing = collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let collectionBarSpacing = collectionView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        
        let constraints = [labelTop, labelHeight, labelLeading, labelTrailing,
                           collectionLabelSpacing, collectionLeading, collectionTrailing, collectionBarSpacing]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    func send(_ item: FeedbackItem) {
        if let uuid = self.uuid {
            delegate?.feedbackViewController(self, didSend: item, uuid: uuid)
            eventsManager?.updateFeedback(uuid: uuid, type: item.feedbackType, source: .user, description: nil)
        }
        
        guard let parent = presentingViewController else {
            dismiss(animated: true)
            return
        }
        
        dismiss(animated: true) {
            DialogViewController().present(on: parent)
        }
    }
    
    func dismissFeedbackItem() {
        delegate?.feedbackViewControllerDidCancel(self)
        if let uuid = self.uuid {
            eventsManager?.cancelFeedback(uuid: uuid)
        }
        dismiss(animated: true, completion: nil)
    }
}

extension FeedbackViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedbackCollectionViewCell.defaultIdentifier, for: indexPath) as! FeedbackCollectionViewCell
        let item = sections[indexPath.row]
        
        cell.titleLabel.text = item.title
        cell.imageView.tintColor = .white
        cell.imageView.image = item.image
        
        return cell
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections.count
    }
}

extension FeedbackViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = sections[indexPath.row]
        send(item)
    }
}

extension FeedbackViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = collectionView.bounds.width
        // 3 columns and 2 rows in portrait mode.
        // 6 columns and 1 row in landscape mode.
        let width = traitCollection.verticalSizeClass == .compact
            ? floor(availableWidth / CGFloat(sections.count))
            : floor(availableWidth / CGFloat(sections.count / 2))
        let item = sections[indexPath.row]
        let titleHeight = item.title.height(constrainedTo: width, font: FeedbackCollectionViewCell.Constants.titleFont)
        let cellHeight: CGFloat = FeedbackCollectionViewCell.Constants.circleSize.height
            + FeedbackCollectionViewCell.Constants.padding
            + titleHeight
            + FeedbackViewController.verticalCellPadding
        return CGSize(width: width, height: cellHeight )
    }
}

extension String {
    func height(constrainedTo width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.height)
    }
}
