import CoreLocation
import Foundation
import MapboxDirections
import Turf

extension Route {
    public static func mock(
        legs: [RouteLeg] = [.mock()],
        shape: LineString? = nil,
        distance: LocationDistance = 300,
        expectedTravelTime: TimeInterval = 195,
        typicalTravelTime: TimeInterval? = 200
    ) -> Self {
        self.init(
            legs: legs,
            shape: shape,
            distance: distance,
            expectedTravelTime: expectedTravelTime,
            typicalTravelTime: typicalTravelTime
        )
    }
}

extension RouteLeg {
    public static func mock(
        steps: [RouteStep] = [
            .mock(maneuverType: .depart),
            .mock(maneuverType: .useLane),
            .mock(maneuverType: .continue),
            .mock(maneuverType: .arrive),
        ],
        name: String = "",
        distance: LocationDistance = 300,
        expectedTravelTime: TimeInterval = 195,
        profileIdentifier: ProfileIdentifier = .automobile
    ) -> Self {
        self.init(
            steps: steps,
            name: name,
            distance: distance,
            expectedTravelTime: expectedTravelTime,
            profileIdentifier: profileIdentifier
        )
    }
}

extension RouteStep {
    public static func mock(
        transportType: TransportType = .automobile,
        maneuverLocation: LocationCoordinate2D = .init(latitude: 1, longitude: 2),
        maneuverType: ManeuverType = .turn,
        instructions: String = "",
        drivingSide: DrivingSide = .right,
        distance: LocationDistance = 100,
        expectedTravelTime: TimeInterval = 65,
        instructionsDisplayedAlongStep: [VisualInstructionBanner]? = nil
    ) -> Self {
        var step = self.init(
            transportType: transportType,
            maneuverLocation: maneuverLocation,
            maneuverType: maneuverType,
            instructions: instructions,
            drivingSide: drivingSide,
            distance: distance,
            expectedTravelTime: expectedTravelTime,
            intersections: [.mock()],
            instructionsDisplayedAlongStep: instructionsDisplayedAlongStep,
            segmentIndicesByIntersection: [0]
        )
        step.shape = .init([maneuverLocation, maneuverLocation])
        return step
    }
}

extension Intersection {
    public static func mock() -> Self {
        return .init(
            location: .init(
                latitude: 1,
                longitude: 2
            ),
            headings: [90],
            approachIndex: 0,
            outletIndex: 0,
            outletIndexes: .init(integer: 0),
            approachLanes: nil,
            usableApproachLanes: nil,
            preferredApproachLanes: nil,
            usableLaneIndication: nil
        )
    }
}
