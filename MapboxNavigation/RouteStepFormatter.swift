import Foundation
import MapboxDirections
import OSRMTextInstructions

public class RouteStepFormatter: Formatter {
    let instructions = OSRMInstructionFormatter(version: "v5")
    
    public override func string(for obj: Any?) -> String? {
        return string(for: obj, markUpWithSSML: false)
    }
    
    public func string(for obj: Any?, markUpWithSSML: Bool) -> String? {
        guard let step = obj as? RouteStep else {
            return nil
        }
        
        guard markUpWithSSML else {
            return instructions.string(for: step)
        }
        
        return instructions.string(for: step, modifyValueByKey: { (key, value) -> String in
            switch key {
            case .wayName, .destination, .rotaryName:
                return "<say-as interpret-as=\"address\">\(value.addingXMLEscapes)</say-as>"
            default:
                return value
            }
        })
        
    }
    
    public override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        return false
    }
}


public extension String {
    typealias Replacement = (of: String, with: String)
    
    func byReplacing(_ replacements: [Replacement]) -> String {
        return replacements.reduce(self) { $0.replacingOccurrences(of: $1.of, with: $1.with) }
    }
    
    var addingXMLEscapes: String {
        return byReplacing([
            ("&", "&amp;"),
            ("<", "&lt;"),
            ("\"", "&quot;"),
            ("'", "&apos;")
            ])
    }
}
