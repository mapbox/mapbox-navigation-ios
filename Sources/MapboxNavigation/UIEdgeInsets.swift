import Foundation
import UIKit

extension UIEdgeInsets {
    public static func +(left: UIEdgeInsets, right: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: left.top + right.top,
                            left: left.left + right.left,
                            bottom: left.bottom + right.bottom,
                            right: left.right + right.right )
    }

    static func +=(lhs: inout UIEdgeInsets, rhs: UIEdgeInsets) {
        lhs.top += rhs.top
        lhs.left += rhs.left
        lhs.bottom += rhs.bottom
        lhs.right += rhs.right
    }
    
    func rectValue(_ rect: CGRect) -> CGRect {
        return CGRect(x: rect.origin.x + self.left,
                      y: rect.origin.y + self.top,
                      width: rect.size.width - self.left - self.right,
                      height: rect.size.height - self.top - self.bottom)
    }
    
    static var centerEdgeInsets: UIEdgeInsets {
        return UIEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
    }
}

extension UIEdgeInsets: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double
    
    public init(floatLiteral value: FloatLiteralType) {
        let padding = CGFloat(value)
        self.init(top: padding, left: padding, bottom: padding, right: padding)
    }
}
