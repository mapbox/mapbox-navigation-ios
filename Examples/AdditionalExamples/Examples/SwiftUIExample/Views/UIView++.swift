import UIKit

extension UIView {
    func addConstrained(child: UIView, padding: CGFloat = 0, add: Bool = true) {
        child.translatesAutoresizingMaskIntoConstraints = false
        if add {
            addSubview(child)
        }
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            child.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            child.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            child.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
        ])
    }
}
