import Foundation

extension UIStackView {
    convenience init(orientation: UILayoutConstraintAxis, alignment: UIStackViewAlignment? = nil, distribution: UIStackViewDistribution? = nil, autoLayout: Bool = false) {
        self.init(frame: .zero)
        axis = orientation
        if let alignment = alignment { self.alignment = alignment }
        if let distribution = distribution { self.distribution = distribution }
        if (autoLayout) { translatesAutoresizingMaskIntoConstraints = false }
    }
    
    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach(addArrangedSubview(_:))
    }
}
