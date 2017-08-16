import Foundation
import MapboxDirections

/**
 Formatter for creating visual instructions.
 */
@objc(MBVisualInstructionFormatter)
public class VisualInstructionFormatter: NSObject {
    
    let routeStepFormatter = RouteStepFormatter()
    
    /**
     Creates the optimal text to be displayed given a `RouteLeg` and `RouteStep`.
     */
    public func string(leg: RouteLeg?, step: RouteStep?) -> String? {
        if let currentLeg = leg, let destinationName = currentLeg.destination.name, let step = step, step.maneuverType == .arrive {
            return destinationName
        } else if let destinations = step?.destinations {
            return destinations.joined(separator: NSLocalizedString("DESTINATION_DELIMITER", bundle: .mapboxCoreNavigation, value: " / ", comment: "Delimiter between multiple destinations"))
        } else if let step = step, step.isNumberedMotorway, let codes = step.codes {
            return codes.joined(separator: NSLocalizedString("REF_DELIMITER", bundle: .mapboxCoreNavigation, value: " / ", comment: "Delimiter between route numbers in a road concurrency"))
        } else if let name = step?.names?.first {
            return name
        } else if let step = step {
            return routeStepFormatter.string(for: step)
        } else {
            return nil
        }
    }
}
