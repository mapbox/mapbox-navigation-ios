import Foundation
import Mapbox
import MapboxDirections
import OSRMTextInstructions

public class RouteStepFormatter: Formatter {
    let instructions = OSRMInstructionFormatter(version: "v5")
    
    override public func string(for obj: Any?) -> String? {
        guard let step = obj as? RouteStep else {
            return nil
        }
        
        return instructions.string(for: step)
    }
    
    override public func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        return false
    }
}
