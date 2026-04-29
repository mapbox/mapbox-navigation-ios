import Foundation

extension AlternativeRoute {
    /// Returns offset of the alternative route where it deviates from the main route.
    func deviationOffset() -> Double {
        guard let coordinates = route.shape?.coordinates,
              !coordinates.isEmpty
        else {
            return 0
        }

        let splitGeometryIndex = alternativeRouteIntersectionIndices.routeGeometryIndex

        var totalDistance = 0.0
        var pointDistance: Double? = nil
        for index in stride(from: coordinates.count - 1, to: 0, by: -1) {
            let currCoordinate = coordinates[index]
            let prevCoordinate = coordinates[index - 1]
            totalDistance += currCoordinate.projectedDistance(to: prevCoordinate)

            if index == splitGeometryIndex + 1 {
                pointDistance = totalDistance
            }
        }
        guard let pointDistance, totalDistance != 0 else { return 0 }

        return (totalDistance - pointDistance) / totalDistance
    }
}
