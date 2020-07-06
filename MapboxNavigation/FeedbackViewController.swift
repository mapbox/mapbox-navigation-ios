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
    
    let interactor = Interactor()

    public weak var delegate: FeedbackViewControllerDelegate?

    var draggableHeight: CGFloat {
        return topLevelFeedbackVC.draggableHeight
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

    var navController: UINavigationController!
    var topLevelFeedbackVC: TopLevelFeedbackViewController!
    var feedbackDetailsVC: FeedbackDetailsViewController!

    override public func viewDidLoad() {
        super.viewDidLoad()
        topLevelFeedbackVC = TopLevelFeedbackViewController(nibName: nil, bundle: nil)
        feedbackDetailsVC = FeedbackDetailsViewController(style: .plain)
        navController = UINavigationController(rootViewController: topLevelFeedbackVC)
        topLevelFeedbackVC.send = { (item: FeedbackItem) -> Void in
            self.feedbackDetailsVC.navigationItemTitle = item.title
            self.feedbackDetailsVC.feedbackSubTypes = item.feedbackType.subtypes
            self.navController.pushViewController(self.feedbackDetailsVC, animated: true)
        }

        self.view.addSubview(navController.view)

        view.layoutIfNeeded()
        transitioningDelegate = self
        view.backgroundColor = .white
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

extension String {
    func height(constrainedTo width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        return ceil(boundingBox.height)
    }
}
