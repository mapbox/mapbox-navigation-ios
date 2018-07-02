import MapboxDirections

extension VisualInstruction {
    
    var containsLaneIndications: Bool {
        return components.contains(where: { $0 is LaneIndicationComponent })
    }
}
