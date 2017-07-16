import CoreLocation

extension CLLocationDistance {
    var miles: CLLocationDistance {
        return self / metersPerMile
    }
    
    var feet: CLLocationDistance {
        return miles / feetPerMile
    }
}

/// Provides appropriately formatted, localized descriptions of linear distances for voice use.
@objc(MBSpokenDistanceFormatter)
public class SpokenDistanceFormatter: DistanceFormatter {
    
    
    /**
     Returns a more human readable `String` from a given `CLLocationDistance`.
     
     The user’s `Locale` is used here to set the units.
     */
    public override func string(from distance: CLLocationDistance) -> String {
        numberFormatter.locale = preferredLocale
        
        var unit: LengthFormatter.Unit = .millimeter
        unitString(fromMeters: distance, usedUnit: &unit)
        let replacesYardsWithMiles = unit == .yard && distance.miles > 0.2
        let showsMixedFraction = (unit == .mile && distance.miles < 10) || replacesYardsWithMiles
        
        // An elaborate hack to use vulgar fractions with miles regardless of
        // language.
        if showsMixedFraction {
            numberFormatter.positivePrefix = "|"
            numberFormatter.positiveSuffix = "|"
            numberFormatter.decimalSeparator = "!"
            numberFormatter.alwaysShowsDecimalSeparator = true
        } else {
            numberFormatter.positivePrefix = ""
            numberFormatter.positiveSuffix = ""
            numberFormatter.decimalSeparator = nonFractionalLengthFormatter.numberFormatter.decimalSeparator
            numberFormatter.alwaysShowsDecimalSeparator = nonFractionalLengthFormatter.numberFormatter.alwaysShowsDecimalSeparator
        }
        
        numberFormatter.usesSignificantDigits = false
        numberFormatter.maximumFractionDigits = maximumFractionDigits(for: distance)
        numberFormatter.roundingIncrement = 0.25
        
        var formattedDistance: String
        if unit == .yard {
            if distance.miles > 0.2 {
                unit = .mile
                formattedDistance = string(fromValue: distance.miles, unit: unit)
            } else {
                unit = .foot
                numberFormatter.roundingIncrement = 50
                formattedDistance = string(fromValue: distance.feet, unit: unit)
            }
        } else {
            formattedDistance = string(fromMeters: distance)
        }
        
        // Elaborate hack continued.
        if showsMixedFraction {
            var parts = formattedDistance.components(separatedBy: "|")
            assert(parts.count == 3, "Positive format should’ve inserted two pipe characters.")
            var numberParts = parts[1].components(separatedBy: "!")
            assert(numberParts.count == 2, "Decimal separator should be present.")
            let decimal = Int(numberParts[0])
            if let fraction = Double(".\(numberParts[1])0") {
                let fourths = Int(round(fraction * 4))
                if fourths == fourths % 4 {
                    if decimal == 0 && fourths != 0 {
                        numberParts[0] = ""
                    }
                    var vulgarFractions = ["", "¼", "½", "¾"]
                    if Locale.current.languageCode == "en" {
                        vulgarFractions = ["", "a quarter", "a half", "3 quarters"]
                        if numberParts[0].isEmpty {
                            parts[2] = " \(unitString(fromValue: 1, unit: unit)) "
                            if fourths == 3 {
                                parts[2] = " of a\(parts[2])"
                            }
                        }
                    }
                    numberParts[1] = vulgarFractions[fourths]
                    if !numberParts[0].isEmpty && !numberParts[1].isEmpty {
                        numberParts[0] += " & "
                    }
                    parts[1] = numberParts.joined(separator: "")
                } else {
                    parts[1] = numberParts.joined(separator: nonFractionalLengthFormatter.numberFormatter.decimalSeparator)
                }
            } else {
                parts[1] = numberParts.joined(separator: nonFractionalLengthFormatter.numberFormatter.decimalSeparator)
            }
            formattedDistance = parts.joined(separator: "")
        }
        
        return formattedDistance
    }
    
    
}
