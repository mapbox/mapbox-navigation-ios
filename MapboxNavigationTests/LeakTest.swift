import UIKit
import Quick
import Nimble

public typealias LeakTestConstructor = () -> AnyObject

public struct LeakTest {
    let constructor : LeakTestConstructor
    
    public init(constructor:@escaping LeakTestConstructor) {
        self.constructor = constructor
    }
    
    internal func isLeaking() -> Bool {
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
    
    internal func isLeaking<P>( when action : (P) -> Any) -> PredicateStatus where P:AnyObject {
        weak var leaked : AnyObject? = nil
        
        var failed = false
        var actionResult : Any? = nil
        
        autoreleasepool {
            
            var evaluated : P? = self.constructor() as? P
            
            if evaluated == nil {
                failed = true
            } else {
                actionResult = action(evaluated!)
                
                if let vc = evaluated as? UIViewController{
                    _ = vc.view
                    vc.view = nil
                }
                
                leaked = evaluated
                evaluated = nil
            }
        }
        
        if failed || actionResult == nil{
            return PredicateStatus.fail
        }
        
        return PredicateStatus.init(bool:  leaked != nil)
    }
}

public func leak() -> Predicate<LeakTest> {
    
    return Predicate.simple("leak") { expression in
        
        guard let leakTest = try expression.evaluate() else{
            return PredicateStatus.fail
        }
        
        return PredicateStatus(bool: leakTest.isLeaking())
    }
}

public func leakWhen<P>(_ action : @escaping (P) -> Any) -> Predicate<LeakTest> where P:AnyObject {
    
    return Predicate.simple("leak when") { expression in
        
        guard let leakTest = try expression.evaluate() else{
            return PredicateStatus.fail
        }
        
        return leakTest.isLeaking(when: action)
    }
}
