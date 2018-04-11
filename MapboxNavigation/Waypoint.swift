import Foundation
import MapboxDirections

extension Waypoint {
    var location: CLLocation {
        return CLLocation.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    var instructionComponent: VisualInstructionComponent? {
        guard let name = name else { return nil }
        return VisualInstructionComponent(type: .text, text: name, imageURL: nil, abbreviation: nil, abbreviationPriority: NSNotFound)
    }
    
    var instructionComponents: [VisualInstructionComponent]? {
        return (instructionComponent != nil) ? [instructionComponent!] : nil
    }
}
