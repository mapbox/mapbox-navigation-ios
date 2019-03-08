import Foundation
import MapboxDirections


extension Array where Element: MapboxDirections.Route {
    func mostSimilar(to route: Route) -> Route? {
        let target = route.description
        return self.min { (left, right) -> Bool in
            let leftDistance = left.description.minimumEditDistance(to: target)
            let rightDistance = right.description.minimumEditDistance(to: target)
            return leftDistance < rightDistance
        }
    }
}
