import Foundation
import MapboxDirections

extension Waypoint {
    var location: CLLocation {
        return CLLocation.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    var instructionComponent: VisualInstructionComponent? {
        guard let name = name else { return nil }
        return VisualInstructionComponent(text: name, imageURL: nil)
    }
    
    var instructionComponents: [VisualInstructionComponent]? {
        return (instructionComponent != nil) ? [instructionComponent!] : nil
    }
}
