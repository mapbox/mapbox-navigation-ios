import Foundation
import MapboxDirections

extension RouteLeg {
    /**
     Returns the last step in a leg, which is indicitive of a user approaching their destination.
     */
    open var lastTurn: RouteStep? {
        let turns = steps.filter {$0.maneuverType == .turn }
        return turns.last
    }
}
