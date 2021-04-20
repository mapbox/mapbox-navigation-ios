import MapboxCoreNavigation

extension ElectronicHorizon.Edge {
    var mpp: [ElectronicHorizon.Edge]? {

        guard level == 0 else { return nil }

        var mostProbablePath = [self]

        for child in outletEdges {
            if let childMPP = child.mpp {
                mostProbablePath.append(contentsOf: childMPP)
            }
        }

        return mostProbablePath
    }
    
    func edgeNames(roadGraph: RoadGraph) -> [String] {
        guard let metadata = roadGraph.edgeMetadata(edgeIdentifier: identifier) else {
            return []
        }
        let names = metadata.names.map { name -> String in
            switch name {
            case .name(let name):
                return name
            case .code(let code):
                return "(\(code))"
            }
        }

        // If the road is unnamed, fall back to the road class.
        if names.isEmpty {
            return ["\(metadata.mapboxStreetsRoadClass.rawValue)"]
        }
        return names
    }
}
