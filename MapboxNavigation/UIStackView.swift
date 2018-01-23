import Foundation

extension UIStackView {
    convenience init(orientation: UILayoutConstraintAxis, autoLayout: Bool = false) {
        self.init(frame: .zero)
        axis = orientation
        if (autoLayout) { translatesAutoresizingMaskIntoConstraints = false }
    }
    
    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach(addArrangedSubview(_:))
    }
}
