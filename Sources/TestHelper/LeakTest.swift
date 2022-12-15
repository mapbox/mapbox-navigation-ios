import UIKit

public typealias LeakTestConstructor = () -> AnyObject

public struct LeakTest {
    let constructor: LeakTestConstructor
    
    public init(constructor: @escaping LeakTestConstructor) {
        self.constructor = constructor
    }
    
    public func isLeaking() -> Bool {
        weak var leaked : AnyObject? = nil
        
        autoreleasepool {
            var evaluated : AnyObject? = self.constructor()
            
            if let vc = evaluated as? UIViewController{
                _ = vc.view
            }
            
            leaked = evaluated
            evaluated = nil
        }
        
        return leaked != nil
    }
}
