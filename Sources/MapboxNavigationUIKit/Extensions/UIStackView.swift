import UIKit

extension UIStackView {
    convenience init(
        orientation: NSLayoutConstraint.Axis,
        alignment: UIStackView.Alignment? = nil,
        distribution: UIStackView.Distribution? = nil,
        spacing: CGFloat? = nil,
        autoLayout: Bool = false
    ) {
        self.init(frame: .zero)

        axis = orientation
        if let alignment { self.alignment = alignment }
        if let distribution { self.distribution = distribution }
        if let spacing { self.spacing = spacing }
        if autoLayout { translatesAutoresizingMaskIntoConstraints = false }
    }

    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach(addArrangedSubview(_:))
    }
}
