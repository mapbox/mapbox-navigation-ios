import MapboxMaps
import UIKit

extension MapboxMaps.Expression {
    static func routeLineWidthExpression(_ multiplier: Double = 1.0) -> MapboxMaps.Expression {
        return Exp(.interpolate) {
            Exp(.linear)
            Exp(.zoom)
            RouteLineWidthByZoomLevel.multiplied(by: multiplier)
        }
    }

    static func routeCasingLineWidthExpression(_ multiplier: Double = 1.0) -> MapboxMaps.Expression {
        routeLineWidthExpression(multiplier * 1.5)
    }

    static func routeLineGradientExpression(
        _ gradientStops: [Double: UIColor],
        lineBaseColor: UIColor,
        isSoft: Bool = false
    ) -> MapboxMaps.Expression {
        if isSoft {
            return Exp(.interpolate) {
                Exp(.linear)
                Exp(.lineProgress)
                gradientStops
            }
        } else {
            return Exp(.step) {
                Exp(.lineProgress)
                lineBaseColor
                gradientStops
            }
        }
    }

    static func buildingExtrusionHeightExpression(_ hightProperty: String) -> MapboxMaps.Expression {
        return Exp(.interpolate) {
            Exp(.linear)
            Exp(.zoom)
            13
            0
            13.25
            Exp(.get) {
                hightProperty
            }
        }
    }
}

extension [Double: Double] {
    /// Returns a copy of the stop dictionary with each value multiplied by the given factor.
    public func multiplied(by factor: Double) -> Dictionary {
        var newCameraStop: [Double: Double] = [:]
        for stop in self {
            let newValue = stop.value * factor
            newCameraStop[stop.key] = newValue
        }
        return newCameraStop
    }
}
