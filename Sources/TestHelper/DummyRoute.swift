import Foundation
import MapboxCoreNavigation
import MapboxDirections

public class DummyRoute: Route {

    public init(description: String) {
        let leg = RouteLeg(steps: [],
                           name: description,
                           distance: 0,
                           expectedTravelTime: 0,
                           typicalTravelTime: nil,
                           profileIdentifier: .automobile)
        super.init(legs: [leg], shape: nil, distance: 0, expectedTravelTime: 0, typicalTravelTime: nil)
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}
