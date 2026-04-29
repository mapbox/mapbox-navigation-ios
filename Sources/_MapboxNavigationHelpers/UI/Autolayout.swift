import UIKit

extension UIView {
    /// Switches translatesAutoresizingMaskIntoConstraints to false and returns self.
    public func autoresizing() -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }

    public func pinEdgesToSuperview(padding: CGFloat = 0, respectingSafeArea safeArea: Bool = false) {
        guard let superview else { return }
        let guide: Anchorable = safeArea ? superview.safeAreaLayoutGuide : superview
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: guide.topAnchor, constant: padding),
            leftAnchor.constraint(equalTo: guide.leftAnchor, constant: padding),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -padding),
            rightAnchor.constraint(equalTo: guide.rightAnchor, constant: -padding),
        ])
    }
}

extension NSLayoutConstraint {
    @discardableResult
    public func assign(to variable: inout NSLayoutConstraint!) -> Self {
        variable = self
        return self
    }
}

@_documentation(visibility: internal)
public protocol Anchorable {
    @MainActor var topAnchor: NSLayoutYAxisAnchor { get }
    @MainActor var bottomAnchor: NSLayoutYAxisAnchor { get }
    @MainActor var leftAnchor: NSLayoutXAxisAnchor { get }
    @MainActor var rightAnchor: NSLayoutXAxisAnchor { get }
    @MainActor var leadingAnchor: NSLayoutXAxisAnchor { get }
    @MainActor var trailingAnchor: NSLayoutXAxisAnchor { get }
}

extension UIView: Anchorable {}
extension UILayoutGuide: Anchorable {}
