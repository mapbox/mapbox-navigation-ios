import Foundation
import MapboxDirections
import OSRMTextInstructions

@objc(MBRouteStepFormatter)
public class RouteStepFormatter: Formatter {
    let instructions = OSRMInstructionFormatter(version: "v5")
    
    /**
     Return an instruction as a `String`.
     */
    @objc public override func string(for obj: Any?) -> String? {
        return string(for: obj, legIndex: nil, numberOfLegs: nil, markUpWithSSML: false)
    }
    
    /**
     Returns an instruction as a `String`. Setting `markUpWithSSML` to `true` will return a string containing [SSML](https://www.w3.org/TR/speech-synthesis/) tag information around appropriate strings.
     */
    public func string(for obj: Any?, legIndex: Int?, numberOfLegs: Int?, markUpWithSSML: Bool) -> String? {
        guard let step = obj as? RouteStep else {
            return nil
        }
        
        let modifyValueByKey = { (key: OSRMTextInstructions.TokenType, value: String) -> String in
            if key == .wayName || key == .rotaryName, let phoneticName = step.phoneticNames?.first {
                return value.withSSMLPhoneme(ipaNotation: phoneticName)
            }
            
            switch key {
            case .wayName, .destination, .rotaryName, .code:
                var value = value
                value.enumerateSubstrings(in: value.wholeRange, options: [.byWords, .reverse]) { (substring, substringRange, enclosingRange, stop) in
                    guard var substring = substring?.addingXMLEscapes else {
                        return
                    }
                    
                    if substring.containsDecimalDigit {
                        substring = substring.asSSMLAddress
                    }
                    value.replaceSubrange(substringRange, with: substring)
                }
                return value
            default:
                return value
            }
        }
        
        return instructions.string(for: step, legIndex: legIndex, numberOfLegs: numberOfLegs, roadClasses: step.intersections?.first?.outletRoadClasses, modifyValueByKey: markUpWithSSML ? modifyValueByKey : nil)
        
    }
    
    @objc public override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        return false
    }
}
