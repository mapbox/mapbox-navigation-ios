import MapboxMaps

extension VectorSource {
    static func preferredMapboxStreetsLanguage(for preferences: [String]) -> String? {
        return nil
    }
}

extension Expression {
    
    static func routeLineWidthExpression(_ multiplier: Double = 1.0) -> Expression {
        return Exp(.interpolate) {
            Exp(.linear)
            Exp(.zoom)
            RouteLineWidthByZoomLevel.multiplied(by: multiplier)
        }
    }
    
    static func routeLineGradientExpression(_ gradientStops: [Double: UIColor]) -> Expression {
        return Exp(.interpolate) {
            Exp(.linear)
            Exp(.lineProgress)
            gradientStops
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
    
    func localized(into locale: Locale?) -> Expression {
        switch elements.first {
        case .op(.literal):
            return self
        case .op(.get):
            guard elements.count == 2,
                  case let .argument(argument) = elements[1],
                  case let .string(propertyName) = argument else {
                break
            }
            
            if propertyName == "name" || propertyName.starts(with: "name_") {
                var localizedPropertyName = "name"
                if locale?.identifier != "mul" {
                    let preferences: [String]
                    if let identifier = locale?.identifier {
                        preferences = [identifier]
                    } else {
                        preferences = Locale.preferredLanguages
                    }
                    if let preferredLanguage = VectorSource.preferredMapboxStreetsLanguage(for: preferences) {
                        localizedPropertyName = "name_\(preferredLanguage)"
                    }
                }
                // If the keypath is `name`, no need to fallback
                guard localizedPropertyName != "name" else {
                    return Exp(.get) { localizedPropertyName }
                }
                // If the keypath is `name_zh-Hans`, fallback to `name_zh` to `name`.
                // CN tiles might using `name_zh-CN` for Simplified Chinese.
                guard localizedPropertyName != "name_zh-Hans" else {
                    return Exp(.coalesce) {
                        localizedPropertyName
                        "name_zh-CN"
                        "name_zh"
                        "name"
                    }
                }
                // Mapbox Streets v8 has `name_zh-Hant`, we should fallback to Simplified Chinese if the field has no value.
                guard localizedPropertyName != "name_zh-Hant" else {
                    return Exp(.coalesce) {
                        localizedPropertyName
                        "name_zh-Hans"
                        "name_zh-CN"
                        "name_zh"
                        "name"
                    }
                }
                // Other keypath fallback to `name`
                return Exp(.coalesce) {
                    localizedPropertyName
                    "name"
                }
            }
        case .op(let op):
            let arguments = elements.suffix(from: 1).map { (element) -> Element in
                switch element {
                case .argument(.option(let options)):
                    if var options = options as? NumberFormatOptions {
                        options.locale = locale?.identifier ?? options.locale
                        return .argument(.option(options))
                    } else if var options = options as? CollatorOptions {
                        options.locale = locale?.identifier ?? options.locale
                        return .argument(.option(options))
                    } else {
                        return .argument(.option(options))
                    }
                case .argument(.expression(let expr)):
                    return .argument(.expression(expr.localized(into: locale)))
                default:
                    return element
                }
            }
            var exp = Exp(op)
            exp.elements = [.op(op)] + arguments
            return exp
        case .none, .argument(_):
            return self
        }
        return self
    }
}
