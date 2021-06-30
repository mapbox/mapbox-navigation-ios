import UIKit

class DismissAnimator: NSObject { }

extension DismissAnimator: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to) else { return }
        
        let height = fromViewController.view.bounds.height - toViewController.view.frame.minY
        let finalFrame = CGRect(x: 0,
                                y: UIScreen.main.bounds.size.height,
                                width: fromViewController.view.bounds.width,
                                height: height)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: {
                        fromViewController.view.frame = finalFrame
                        transitionContext.containerView.backgroundColor = .clear
                       }) { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

class PresentAnimator: NSObject { }

extension PresentAnimator: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to),
              let toViewController = transitionContext.viewController(forKey: .to) else { return }
        
        let containerView = transitionContext.containerView
        containerView.backgroundColor = .clear
        toView.frame = CGRect(x: 0,
                              y: containerView.bounds.height,
                              width: containerView.bounds.width,
                              height: containerView.bounds.midY)
        
        containerView.addSubview(toView)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: toViewController,
                                                          action: #selector(FeedbackViewController.handleDismissTap(sender:)))
        if let responder = toViewController as? UIGestureRecognizerDelegate {
            tapGestureRecognizer.delegate = responder
        }
        containerView.addGestureRecognizer(tapGestureRecognizer)
        
        var height = toViewController.view.bounds.height
        if let draggable = toViewController as? DismissDraggable {
            height = draggable.draggableHeight
        }
        
        // To correctly present `FeedbackViewController` with certain presentation styles on iPad,
        // `UIScreen` size is used instead of `UIViewController` size from which transition
        // is being performed.
        let finalFrame = CGRect(x: 0,
                                y: UIScreen.main.bounds.size.height - height,
                                width: UIScreen.main.bounds.size.width,
                                height: height)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       options: [.curveEaseInOut],
                       animations: {
                        toView.frame = finalFrame
                        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
                       }) { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

class Interactor: UIPercentDrivenInteractiveTransition {
    
    var hasStarted = false
    var shouldFinish = false
}

protocol DismissDraggable: UIViewControllerTransitioningDelegate {
    
    var interactor: Interactor { get }
    var draggableHeight: CGFloat { get }
}

fileprivate extension Selector {
    
    static let handleDismissDrag = #selector(UIViewController.handleDismissPan(_:))
}

extension DismissDraggable where Self: UIViewController {
    
    func enableDraggableDismiss() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self,
                                                          action: .handleDismissDrag)
        view.addGestureRecognizer(panGestureRecognizer)
    }
}

fileprivate extension UIViewController {
    
    @objc func handleDismissPan(_ sender: UIPanGestureRecognizer) {
        self.handlePan(sender)
    }
    
    func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let viewController = self as? DismissDraggable else { return }
        let interactor = viewController.interactor
        
        let finishThreshold: CGFloat = 0.4
        let translation = sender.translation(in: view)
        let progress = translation.y / view.bounds.height
        
        switch sender.state {
        case .began:
            interactor.hasStarted = true
            dismiss(animated: true, completion: nil)
        case .changed:
            interactor.shouldFinish = progress > finishThreshold
            interactor.update(progress)
        case .cancelled:
            interactor.hasStarted = false
            interactor.cancel()
        case .ended:
            interactor.hasStarted = false
            interactor.shouldFinish ? interactor.finish() : interactor.cancel()
        default:
            break
        }
    }
}
