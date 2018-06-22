import Foundation
import UIKit
import MapboxDirections

public extension UIEdgeInsets {
    public static func +(left: UIEdgeInsets, right: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets(top: left.top + right.top,
                            left: left.left + right.left,
                            bottom: left.bottom + right.bottom,
                            right: left.right + right.right )
    }
    
    public func carPlayInsets(for sideOfRoad: DrivingSide) -> UIEdgeInsets {
        let paddingTop: CGFloat = 10, paddingBottom: CGFloat = 10
        if sideOfRoad == .right {
            return UIEdgeInsets(top: paddingTop, left: 140, bottom: paddingBottom, right: 10)
        } else {
            return UIEdgeInsets(top: paddingTop, left: 10, bottom: paddingBottom, right: 140)
        }
    }
}

extension UIEdgeInsets: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double
    
    public init(floatLiteral value: FloatLiteralType) {
        let padding = CGFloat(value)
        self.init(top: padding, left: padding, bottom: padding, right: padding)
    }
}
