import Foundation

extension Dictionary where Key == Float, Value == NSExpression {
    func localized(into locale: Locale?, replacingTokens replacesTokens: Bool) -> [Float: NSExpression] {
        var localizedStops = self
        var hasLocalizedValue = false
        for (zoomLevel, value) in localizedStops {
            let localizedValue = value.localized(into: locale, replacingTokens: replacesTokens)
            if localizedValue != value {
                localizedStops[zoomLevel] = localizedValue
                hasLocalizedValue = true
            }
        }
        return hasLocalizedValue ? localizedStops : self
    }
}

extension NSExpression {
    func localized(into locale: Locale?, replacingTokens replacesTokens: Bool) -> NSExpression {
        let localizedKeyPath: String
        if let locale = locale {
            localizedKeyPath = "name_\(locale.identifier)"
        } else {
            localizedKeyPath = "name"
        }
        
        switch expressionType {
        case .constantValue:
            if replacesTokens, let value = constantValue as? String, value.contains("{name") {
                return NSExpression(forKeyPath: localizedKeyPath)
            }
            if let stops = constantValue as? [Float: NSExpression] {
                let localizedStops = stops.localized(into: locale, replacingTokens: replacesTokens)
                if localizedStops != stops {
                    return NSExpression(forConstantValue: localizedStops)
                }
            }
            return self
        case .keyPath:
            if keyPath.contains("name") {
                return NSExpression(forKeyPath: localizedKeyPath)
            }
            return self
        case .function:
            let localizedOperand = operand.localized(into: locale, replacingTokens: false)
            let tokenizedFunctions = [
                "mgl_interpolateWithCurveType:parameters:stops:",
                "mgl_interpolate:withCurveType:parameters:stops:",
                "mgl_stepWithMinimum:stops:",
                "mgl_step:from:stops:",
            ]
            let replacesTokens = replacesTokens && tokenizedFunctions.contains(function)
            if let localizedArguments = arguments?.map({ $0.localized(into: locale, replacingTokens: replacesTokens) }),
                localizedArguments != arguments {
                return NSExpression(forFunction: localizedOperand, selectorName: function, arguments: localizedArguments)
            }
            if localizedOperand != operand {
                return NSExpression(forFunction: localizedOperand, selectorName: function, arguments: arguments)
            }
            return self
        case .conditional:
            let localizedTrue = self.true.localized(into: locale, replacingTokens: false)
            let localizedFalse = self.false.localized(into: locale, replacingTokens: false)
            if localizedTrue != self.true || localizedFalse != self.false {
                return NSExpression(forConditional: predicate, trueExpression: localizedTrue, falseExpression: localizedFalse)
            }
            return self
        case .aggregate:
            if let collection = collection as? [NSExpression] {
                let localizedCollection = collection.map { $0.localized(into: locale, replacingTokens: false) }
                if localizedCollection != collection {
                    return NSExpression(forAggregate: localizedCollection)
                }
            }
            return self
        default:
            return self
        }
    }
}
