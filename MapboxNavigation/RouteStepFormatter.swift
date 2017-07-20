import Foundation
import MapboxDirections
import OSRMTextInstructions

@objc(MBRouteStepFormatter)
public class RouteStepFormatter: Formatter {
    let instructions = OSRMInstructionFormatter(version: "v5")
    
    /**
     Return an instruction as a `String`.
     */
    public override func string(for obj: Any?) -> String? {
        return string(for: obj, legIndex: nil, numberOfLegs: nil, markUpWithSSML: false)
    }
    
    /**
     Returns an instruction as a `String`. Setting `markUpWithSSML` to `true` will return a string containing [SSML](https://www.w3.org/TR/speech-synthesis/) tag information around appropriate strings.
     */
    public func string(for obj: Any?, legIndex: Int?, numberOfLegs: Int?, markUpWithSSML: Bool) -> String? {
        guard let step = obj as? RouteStep else {
            return nil
        }
        
        guard markUpWithSSML else {
            return instructions.string(for: step)
        }
        
        return instructions.string(for: step, legIndex: legIndex, numberOfLegs: numberOfLegs, roadClasses: step.intersections?.first?.outletRoadClasses, modifyValueByKey: { (key, value) -> String in
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
