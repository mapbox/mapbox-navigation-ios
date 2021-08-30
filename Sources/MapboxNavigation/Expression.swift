import MapboxMaps

extension Expression {
    
    static func routeLineWidthExpression(_ multiplier: Double = 1.0) -> Expression {
        return Exp(.interpolate) {
            Exp(.linear)
            Exp(.zoom)
            RouteLineWidthByZoomLevel.multiplied(by: multiplier)
        }
    }
    
    static func routeLineGradientExpression(_ gradientStops: [Double: UIColor], lineBaseColor: UIColor, isSoft: Bool = false) -> Expression {
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
    
    static func buildingExtrusionHeightExpression(_ hightProperty: String) -> Expression {
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
