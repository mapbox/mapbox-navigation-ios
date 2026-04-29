import UIKit

extension UIView {
    @inlinable
    @inline(__always)
    public func forEachSubview(action: @escaping (UIView) -> Void) {
        var queue: [UIView] = [self]

        while !queue.isEmpty {
            let view = queue.removeFirst()

            action(view)

            for subview in view.subviews {
                queue.append(subview)
            }
        }
    }
}
