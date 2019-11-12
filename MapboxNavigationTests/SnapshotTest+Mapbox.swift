import Foundation
import SnappyShrimp

extension SnapshotTest {
    enum Side {
        case top, bottom
    }
    
    func constrain(_ child: UIView, to parent: UIView, side: Side = .top) {
        let childSideAnchor = side == .top ? child.topAnchor : child.bottomAnchor
        let parentSideAnchor = side == .top ? parent.topAnchor : parent.bottomAnchor
        let constraints = [
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
            childSideAnchor.constraint(equalTo: parentSideAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func embed(parent:UIViewController, child: UIViewController, in container: UIView, constrainedBy constraints: ((UIViewController, UIViewController) -> [NSLayoutConstraint])?) {
        child.willMove(toParent: parent)
        parent.addChild(child)
        container.addSubview(child.view)
        if let childConstraints: [NSLayoutConstraint] = constraints?(parent, child) {
            parent.view.addConstraints(childConstraints)
        }
        child.didMove(toParent: parent)
    }
}
