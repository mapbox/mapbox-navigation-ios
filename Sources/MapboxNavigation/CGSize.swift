import Foundation
import UIKit

extension CGSize: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double
    
    public init(size: Double) {
        self.init(width: size, height: size)
    }
    
    public init(floatLiteral value: FloatLiteralType) {
        self.init(size: value)
    }
    
    var aspectRatio: CGFloat {
        return width / height
    }
}
