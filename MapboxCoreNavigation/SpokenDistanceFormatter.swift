import CoreLocation

/// Provides appropriately formatted, localized descriptions of linear distances for voice use.
@objc(MBSpokenDistanceFormatter)
public class SpokenDistanceFormatter: DistanceFormatter {
    
    
    /**
     Returns a more human readable `String` from a given `CLLocationDistance`.
     
     The user’s `Locale` is used here to set the units.
     */
    public override func string(from distance: CLLocationDistance) -> String {
        // British roads are measured in miles, yards, and feet. Simulate this idiosyncrasy using the U.S. locale.
        let localeIdentifier = numberFormatter.locale.identifier
        if localeIdentifier == "en-GB" || localeIdentifier == "en_GB" {
            numberFormatter.locale = Locale(identifier: "en-US")
        }
        
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
        numberFormatter.roundingIncrement = roundingIncrement(for: distance, unit: unit) as NSNumber
        
        var distanceString = formattedDistance(distance, modify: &unit)
        
        // Elaborate hack continued.
        if showsMixedFraction {
            var parts = distanceString.components(separatedBy: "|")
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
            distanceString = parts.joined(separator: "")
        }
        
        return distanceString
    }
    
    
}
