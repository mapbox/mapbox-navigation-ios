import MapboxNavigationCore
import UIKit

/// The ``FeedbackViewControllerDelegate`` protocol provides methods for responding to feedback events.
public protocol FeedbackViewControllerDelegate: AnyObject, UnimplementedLogging {
    /// Called when the user opens the feedback form.
    /// - Parameters:
    ///   - feedbackViewController: The ``FeedbackViewController`` object.
    func feedbackViewControllerDidOpen(_ feedbackViewController: FeedbackViewController)

    /// Called when the user submits a feedback event.
    /// - Parameters:
    ///   - feedbackViewController: The ``FeedbackViewController`` object.
    ///   - feedbackItem: The selected ``FeedbackItem``.
    ///   - feedback: The sent feedback event.
    func feedbackViewController(
        _ feedbackViewController: FeedbackViewController,
        didSend feedbackItem: FeedbackItem,
        feedback: FeedbackEvent
    )

    /// Called when a `FeedbackViewController` is dismissed for any reason without giving explicit feedback.
    func feedbackViewControllerDidCancel(_ feedbackViewController: FeedbackViewController)
}

extension FeedbackViewControllerDelegate {
    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func feedbackViewControllerDidOpen(_ feedbackViewController: FeedbackViewController) {
        logUnimplemented(protocolType: FeedbackViewControllerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func feedbackViewController(
        _ feedbackViewController: FeedbackViewController,
        didSend feedbackItem: FeedbackItem,
        uuid: UUID
    ) {
        logUnimplemented(protocolType: FeedbackViewControllerDelegate.self, level: .info)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func feedbackViewControllerDidCancel(_ feedbackViewController: FeedbackViewController) {
        logUnimplemented(protocolType: FeedbackViewControllerDelegate.self, level: .info)
    }
}

/// A view controller containing a grid of buttons the user can use to denote an issue their current navigation
/// experience.
public class FeedbackViewController: UIViewController, DismissDraggable, UIGestureRecognizerDelegate {
    // MARK: UI Configuration

    static let sceneTitle = "FEEDBACK_TITLE".localizedString(
        value: "Report Problem",
        comment: "Title of view controller for sending feedback"
    )
    static let cellReuseIdentifier = "collectionViewCellId"
    static let autoDismissInterval: TimeInterval = 10
    static let verticalCellPadding: CGFloat = 20.0
    static let titleHeaderHeight: CGFloat = 30.0
    static let contentInset: UIEdgeInsets = .init(top: 12, left: 0, bottom: 12, right: 0)

    let interactor = Interactor()
    let type: FeedbackViewControllerType

    var sections: [FeedbackItem] {
        type.feedbackItems
    }

    lazy var collectionView: FeedbackCollectionView = {
        let view = FeedbackCollectionView(frame: .zero, collectionViewLayout: flowLayout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        view.dataSource = self
        view.contentInset = FeedbackViewController.contentInset
        view.register(
            FeedbackCollectionViewCell.self,
            forCellWithReuseIdentifier: FeedbackCollectionViewCell.defaultIdentifier
        )
        return view
    }()

    lazy var reportIssueLabel: UILabel = {
        let label: UILabel = .forAutoLayout()
        label.textAlignment = .center
        label.text = FeedbackViewController.sceneTitle
        return label
    }()

    lazy var bottomPaddingView: FeedbackStyleView = .forAutoLayout()

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
        let collectionViewHeight = collectionView(
            collectionView,
            layout: collectionView.collectionViewLayout,
            sizeForItemAt: indexPath
        ).height * CGFloat(numberOfRows) + padding + view.safeArea.bottom
        let fullHeight = reportIssueLabel.bounds.height + collectionViewHeight + FeedbackViewController
            .titleHeaderHeight + FeedbackViewController.contentInset.top
        return fullHeight
    }

    // MARK: Feedback Configuration

    /// The events manager used to send feedback events.
    public weak var eventsManager: NavigationEventsManager?

    /// View controller's delegate.
    public weak var delegate: FeedbackViewControllerDelegate?

    /// Instantly dismisses the ``FeedbackViewController`` if it is currently presented.
    @objc
    public func dismissFeedback() {
        dismissFeedbackItem()
    }

    func dismissFeedbackItem() {
        delegate?.feedbackViewControllerDidCancel(self)
        currentFeedback = nil
        dismiss(animated: true, completion: nil)
    }

    /// Current feedback.
    var currentFeedback: FeedbackEvent?

    /// Initialize a new ``FeedbackViewController`` from a `NavigationEventsManager`.
    /// - Parameters:
    ///   - eventsManager: The `NavigationEventsManager` object to sent feedback events.
    ///   - type: The feedback type that configures which categories will be displayed.
    public init(eventsManager: NavigationEventsManager, type: FeedbackViewControllerType = .activeNavigation) {
        self.eventsManager = eventsManager
        self.type = type
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }

    override public func encode(with aCoder: NSCoder) {
        aCoder.encode(eventsManager, forKey: "NavigationEventsManager")
    }

    public required init?(coder aDecoder: NSCoder) {
        self.eventsManager = aDecoder.decodeObject(
            of: [NavigationEventsManager.self],
            forKey: "NavigationEventsManager"
        ) as? NavigationEventsManager
        self.type = FeedbackViewControllerType.activeNavigation
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        modalPresentationStyle = .custom
        transitioningDelegate = self

        createFeedback()
    }

    func createFeedback() {
        Task {
            currentFeedback = await eventsManager?.createFeedback()
        }
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
        view.layoutIfNeeded()
        transitioningDelegate = self
        view.backgroundColor = .systemBackground
        enableDraggableDismiss()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.feedbackViewControllerDidOpen(self)
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Dismiss the feedback view when switching between landscape and portrait mode.
        dismissFeedback()
    }

    func presentError(_ message: String) {
        let controller = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            controller.dismiss(animated: true, completion: nil)
        }

        controller.addAction(action)
        present(controller, animated: true, completion: nil)
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Only respond to touches outside/behind the view
        let isDescendant = touch.view?.isDescendant(of: view) ?? true
        return !isDescendant
    }

    @objc
    func handleDismissTap(sender: UITapGestureRecognizer) {
        dismissFeedback()
    }

    func setupViews() {
        let children = [reportIssueLabel, collectionView, bottomPaddingView]
        view.addSubviews(children)
    }

    func setupConstraints() {
        let labelConstraints = [
            reportIssueLabel.topAnchor.constraint(equalTo: view.topAnchor),
            reportIssueLabel.heightAnchor.constraint(equalToConstant: FeedbackViewController.titleHeaderHeight),
            reportIssueLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            reportIssueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ]

        let collectionConstraints = [
            collectionView.topAnchor.constraint(equalTo: reportIssueLabel.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeBottomAnchor),
        ]

        let bottomPaddingConstraints = [
            bottomPaddingView.topAnchor.constraint(equalTo: view.safeBottomAnchor),
            bottomPaddingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPaddingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomPaddingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ]

        let layoutConstraints = labelConstraints + collectionConstraints + bottomPaddingConstraints
        NSLayoutConstraint.activate(layoutConstraints)
    }

    func send(_ item: FeedbackItem) {
        if let feedback = currentFeedback {
            delegate?.feedbackViewController(self, didSend: item, feedback: feedback)
            eventsManager?.sendFeedback(feedback, type: item.type)
        }
    }
}

extension FeedbackViewController: UICollectionViewDataSource {
    public func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: FeedbackCollectionViewCell.defaultIdentifier,
            for: indexPath
        ) as! FeedbackCollectionViewCell
        let item = sections[indexPath.row]

        cell.titleLabel.text = item.title
        cell.imageView.image = item.image.withRenderingMode(.alwaysTemplate)

        cell.titleLabel.textColor = self.collectionView.cellColor
        cell.circleColor = self.collectionView.cellColor
        cell.imageView.tintColor = self.collectionView.backgroundColor

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

        guard let parent = presentingViewController else {
            dismiss(animated: true)
            return
        }

        dismiss(animated: true) {
            DialogViewController().present(on: parent)
        }
    }
}

extension FeedbackViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let availableWidth = collectionView.bounds.width
        // 3 columns and 2 rows in portrait mode.
        // 6 columns and 1 row in landscape mode.
        let width = traitCollection.verticalSizeClass == .compact
            ? floor(availableWidth / CGFloat(sections.count))
            : floor(availableWidth / CGFloat(sections.count / 2))
        let cellHeight: CGFloat = FeedbackCollectionViewCell.Constants.circleSize.height
            + FeedbackCollectionViewCell.Constants.padding
            + FeedbackCollectionViewCell.Constants.verticalPadding // top and bottom padding
            + FeedbackViewController.verticalCellPadding
        return CGSize(width: width, height: cellHeight)
    }
}

extension String {
    func height(constrainedTo width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        // swiftformat:disable redundantSelf
        let boundingBox = self.boundingRect(
            with: constraintRect,
            options: .usesLineFragmentOrigin,
            attributes: [.font: font],
            context: nil
        )
        return ceil(boundingBox.height)
    }
}

class FeedbackStyleView: UIView {}

class FeedbackCollectionView: UICollectionView {
    @objc dynamic var cellColor: UIColor = .black {
        didSet {
            reloadData()
        }
    }
}

extension FeedbackViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forDismissed dismissed: UIViewController)
    -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }

    public func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return PresentAnimator()
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning)
    -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
