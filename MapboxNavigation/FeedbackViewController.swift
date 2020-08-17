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
    public var sections: [FeedbackItem] {
        [FeedbackType.incorrectVisual(subtype: nil),
        FeedbackType.confusingAudio(subtype: nil),
        FeedbackType.illegalRoute(subtype: nil),
        FeedbackType.roadClosure(subtype: nil),
        FeedbackType.routeQuality(subtype: nil)].map { $0.generateFeedbackItem() }
    }

    /**
     Controls whether or not the feedback view controller shows a second level of detail for feedback items.
     When disabled, feedback will be submitted on a single tap of a top level category.
     When enabled, a first tap reveals an instance of FeedbackSubtypeViewController. A second tap on an item there will submit a feedback.
    */
    public var detailedFeedbackEnabled: Bool = false
    
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
    
    fileprivate func setupViews() {
        let children = [reportIssueLabel, collectionView]
        view.addSubviews(children)
    }
    
    fileprivate func setupConstraints() {
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

        if detailedFeedbackEnabled, eventsManager != nil {
            let feedbackViewController = FeedbackSubtypeViewController(eventsManager: eventsManager!, feedbackType: item.feedbackType)

            guard let parent = presentingViewController else {
                dismiss(animated: true)
                return
            }

            dismiss(animated: true) {
                parent.present(feedbackViewController, animated: true, completion: nil)
            }
        } else {
            send(item)
        }
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

public class FeedbackSubtypeViewController: FeedbackViewController {

    public var activeFeedbackType: FeedbackType?

    private let reportButtonContainer = UIView()
    private let reportButtonSeparator = UIView()
    private let reportButton = UIButton()

    private var selectedItems = [FeedbackItem]()

    /**
     Initialize a new FeedbackSubtypeViewController from a `NavigationEventsManager`.
     */
    public init(eventsManager: NavigationEventsManager, feedbackType: FeedbackType) {
        super.init(eventsManager: eventsManager)
        self.activeFeedbackType = feedbackType
        reportButton.backgroundColor = UIColor.defaultRouteLayer
        reportButton.layer.cornerRadius = 24
        reportButton.clipsToBounds = true
        reportButton.setTitle(NSLocalizedString("NAVIGATION_REPORT_CANCEL", comment: "Title for button that cancels user's submission of feedback on navigation session issues."), for: .normal)
        reportButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)

        collectionView.register(FeedbackSubtypeCollectionViewCell.self, forCellWithReuseIdentifier: FeedbackSubtypeCollectionViewCell.defaultIdentifier)
        collectionView.allowsMultipleSelection = true

        reportIssueLabel.text = feedbackType.title
    }

    @objc private func reportButtonTapped(_ sender: UIButton) {
        sendReport()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var sections: [FeedbackItem]  {
        get {
            guard let activeFeedbackType = activeFeedbackType else { return [] }
            switch activeFeedbackType {
            case .general:
                return []
            case .incorrectVisual(_):
                return [FeedbackType.incorrectVisual(subtype: .turnIconIncorrect),
                        FeedbackType.incorrectVisual(subtype: .streetNameIncorrect),
                        FeedbackType.incorrectVisual(subtype: .instructionUnnecessary),
                        FeedbackType.incorrectVisual(subtype: .instructionMissing),
                        FeedbackType.incorrectVisual(subtype: .maneuverIncorrect),
                        FeedbackType.incorrectVisual(subtype: .exitInfoIncorrect),
                        FeedbackType.incorrectVisual(subtype: .laneGuidanceIncorrect),
                        FeedbackType.incorrectVisual(subtype: .roadKnownByDifferentName),
                        FeedbackType.incorrectVisual(subtype: .other)].map { $0.generateFeedbackItem() }
            case .confusingAudio(_):
                return [FeedbackType.confusingAudio(subtype: .guidanceTooEarly),
                        FeedbackType.confusingAudio(subtype: .guidanceTooLate),
                        FeedbackType.confusingAudio(subtype: .pronunciationIncorrect),
                        FeedbackType.confusingAudio(subtype: .roadNameRepeated),
                        FeedbackType.confusingAudio(subtype: .other)].map { $0.generateFeedbackItem() }
            case .routeQuality(_):
                return [FeedbackType.routeQuality(subtype: .routeNonDrivable),
                        FeedbackType.routeQuality(subtype: .routeNotPreferred),
                        FeedbackType.routeQuality(subtype: .alternativeRouteNotExpected),
                        FeedbackType.routeQuality(subtype: .routeIncludedMissingRoads),
                        FeedbackType.routeQuality(subtype: .other)].map { $0.generateFeedbackItem() }
            case .illegalRoute(_):
                return [FeedbackType.illegalRoute(subtype: .routedDownAOneWay),
                        FeedbackType.illegalRoute(subtype: .turnWasNotAllowed),
                        FeedbackType.illegalRoute(subtype: .carsNotAllowedOnStreet),
                        FeedbackType.illegalRoute(subtype: .turnAtIntersectionUnprotected),
                        FeedbackType.illegalRoute(subtype: .other)].map { $0.generateFeedbackItem() }
            case .roadClosure(_):
                return [FeedbackType.roadClosure(subtype: .streetPermanentlyBlockedOff),
                        FeedbackType.roadClosure(subtype: .roadMissingFromMap),
                        FeedbackType.roadClosure(subtype: .other)].map { $0.generateFeedbackItem() }
            }
        }
    }

    override var draggableHeight: CGFloat {
        return 400
    }

    public override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableWidth = collectionView.bounds.width
        return CGSize(width: availableWidth, height: 80 )
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedbackSubtypeCollectionViewCell.defaultIdentifier, for: indexPath) as! FeedbackSubtypeCollectionViewCell
        let item = sections[indexPath.row]

        cell.titleLabel.text = item.title

        if indexPath.row == sections.count - 1 {
            cell.separatorColor = .clear
        } else {
            if #available(iOS 13.0, *) {
                cell.separatorColor = .separator
            } else {
                cell.separatorColor = UIColor(white: 0.95, alpha: 1.0)
            }
        }

        return cell
    }

    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        reportButton.setTitle(NSLocalizedString("NAVIGATION_REPORT_ISSUE", comment: "Title for button that submits user's feedback on navigation session issues."), for: .normal)

        let cell = collectionView.cellForItem(at: indexPath) as! FeedbackSubtypeCollectionViewCell
        if #available(iOS 13.0, *) {
            cell.circleColor = .systemBlue
        } else {
            cell.circleColor = .lightGray
        }
        cell.circleOutlineColor = cell.circleColor

        let item = sections[indexPath.row]
        selectedItems.append(item)
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! FeedbackSubtypeCollectionViewCell
        if #available(iOS 13.0, *) {
            cell.circleColor = .systemBackground
            cell.circleOutlineColor = .label
        } else {
            cell.circleColor = .white
            cell.circleOutlineColor = .darkText
        }

        let item = sections[indexPath.row]
        selectedItems.removeAll { existingItem -> Bool in
            return existingItem.feedbackType.title == item.feedbackType.title
        }

        if selectedItems.count == 0 {
            reportButton.setTitle(NSLocalizedString("NAVIGATION_REPORT_CANCEL", comment: "Title for button that cancels user's submission of feedback on navigation session issues."), for: .normal)
        }
    }

    private func sendReport() {
        if selectedItems.count > 0 {
            selectedItems.forEach { item in
                if let uuid = self.uuid {
                    delegate?.feedbackViewController(self, didSend: item, uuid: uuid)
                    eventsManager?.updateFeedback(uuid: uuid, type: item.feedbackType, source: .user, description: nil)
                }
            }

            guard let parent = presentingViewController else {
                dismiss(animated: true)
                return
            }

            dismiss(animated: true) {
                DialogViewController().present(on: parent)
            }
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    fileprivate override func setupViews() {
        super.setupViews()
        reportButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        reportButton.translatesAutoresizingMaskIntoConstraints = false
        reportButtonContainer.addSubview(reportButton)
        reportButtonContainer.addSubview(reportButtonSeparator)
        reportButtonSeparator.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            reportButtonSeparator.backgroundColor = .separator
        } else {
            reportButtonSeparator.backgroundColor = .lightGray
        }
        view.addSubview(reportButtonContainer)
    }

    fileprivate override func setupConstraints() {
        let labelTop = reportIssueLabel.topAnchor.constraint(equalTo: view.topAnchor)
        let labelHeight = reportIssueLabel.heightAnchor.constraint(equalToConstant: FeedbackViewController.titleHeaderHeight)
        let labelLeading = reportIssueLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let labelTrailing = reportIssueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let collectionLabelSpacing = collectionView.topAnchor.constraint(equalTo: reportIssueLabel.bottomAnchor)
        let collectionLeading = collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let collectionTrailing = collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let collectionBarSpacing = collectionView.bottomAnchor.constraint(equalTo: reportButtonContainer.topAnchor)

        let reportButtonContainerLeading = reportButtonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let reportButtonContainerTrailing = reportButtonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let reportButtonContainerBottom = reportButtonContainer.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        let reportButtonContainerHeight = reportButtonContainer.heightAnchor.constraint(equalToConstant: 96)

        let reportButtonSeparatorLeading = reportButtonSeparator.leadingAnchor.constraint(equalTo: reportButtonContainer.leadingAnchor)
        let reportButtonSeparatorTrailing = reportButtonSeparator.trailingAnchor.constraint(equalTo: reportButtonContainer.trailingAnchor)
        let reportButtonSeparatorTop = reportButtonSeparator.bottomAnchor.constraint(equalTo: reportButtonContainer.topAnchor)
        let reportButtonSeparatorHeight = reportButtonSeparator.heightAnchor.constraint(equalToConstant: 0.5)

        let reportButtonCenterX = reportButton.centerXAnchor.constraint(equalTo: reportButtonContainer.centerXAnchor)
        let reportButtonCenterY = reportButton.centerYAnchor.constraint(equalTo: reportButtonContainer.centerYAnchor)
        let reportButtonWidth = reportButton.widthAnchor.constraint(equalToConstant: 165)
        let reportButtonHeight = reportButton.heightAnchor.constraint(equalToConstant: 48)

        let constraints = [labelTop, labelHeight, labelLeading, labelTrailing,
                           collectionLabelSpacing, collectionLeading, collectionTrailing, collectionBarSpacing,
                           reportButtonContainerLeading, reportButtonContainerTrailing, reportButtonContainerBottom, reportButtonContainerHeight, reportButtonCenterX, reportButtonCenterY, reportButtonWidth, reportButtonHeight, reportButtonSeparatorLeading, reportButtonSeparatorTrailing, reportButtonSeparatorTop, reportButtonSeparatorHeight]

        NSLayoutConstraint.activate(constraints)
    }
}

