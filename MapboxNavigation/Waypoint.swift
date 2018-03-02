import Foundation
import MapboxDirections

extension Waypoint {
    var location: CLLocation {
        return CLLocation.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    var instructionComponent: VisualInstructionComponent? {
        guard let name = name else { return nil }
        return VisualInstructionComponent(type: .destination, text: name, imageURL: nil, maneuverType: .arrive, maneuverDirection: .none)
    }
    
    var instructionComponents: [VisualInstructionComponent]? {
        return (instructionComponent != nil) ? [instructionComponent!] : nil
    }
}
