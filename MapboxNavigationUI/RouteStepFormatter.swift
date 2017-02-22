import Foundation
import Mapbox
import MapboxDirections
import OSRMTextInstructions

class RouteStepFormatter: Formatter {
    let instructions = OSRMInstructionFormatter(version: "v5")
    
    override func string(for obj: Any?) -> String? {
        guard let step = obj as? RouteStep else {
            return nil
        }
        
        return instructions.string(for: step)
    }
    
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        return false
    }
}
