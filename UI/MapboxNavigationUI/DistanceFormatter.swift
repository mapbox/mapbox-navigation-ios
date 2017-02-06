import CoreLocation

let metersPerMile: CLLocationDistance = 1_609.344
let secondsPerHour = 60.0 * 60.0
let yardsPerMile = 1_760.0
let feetPerMile = yardsPerMile * 3.0

/// Provides appropriately formatted, localized descriptions of linear distances.
class DistanceFormatter: LengthFormatter {
    /// True to favor brevity over precision.
    var approximate: Bool
    /// True to insert hints for text-to-speech.
    var forVoiceUse: Bool
    let nonFractionalLengthFormatter = LengthFormatter()
    
    init(approximate: Bool = false, forVoiceUse: Bool = false) {
        self.approximate = approximate
        self.forVoiceUse = forVoiceUse
        super.init()
    }
    
    required init?(coder decoder: NSCoder) {
        approximate = decoder.decodeBool(forKey: "approximate")
        forVoiceUse = decoder.decodeBool(forKey: "forVoiceUse")
        super.init(coder: decoder)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(approximate, forKey: "approximate")
        aCoder.encode(forVoiceUse, forKey: "forVoiceUse")
    }
    
    func string(from distance: CLLocationDistance) -> String {
        let miles = distance / metersPerMile
        let feet = miles * feetPerMile
        
        var unit: LengthFormatter.Unit = .millimeter
        unitString(fromMeters: distance, usedUnit: &unit)
        let replacesYardsWithMiles = unit == .yard && miles > 0.2
        let showsMixedFraction = (unit == .mile && miles < 10) || replacesYardsWithMiles
        
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
        
        if approximate && !showsMixedFraction {
            numberFormatter.usesSignificantDigits = true
            numberFormatter.maximumSignificantDigits = 2
        } else {
            numberFormatter.usesSignificantDigits = false
            numberFormatter.maximumFractionDigits = showsMixedFraction ? 2 : 0
        }
        numberFormatter.roundingIncrement = 0.25
        
        var formattedDistance: String
        if unit == .yard {
            if miles > 0.2 {
                unit = .mile
                formattedDistance = string(fromValue: miles, unit: unit)
            } else {
                unit = .foot
                numberFormatter.roundingIncrement = 50
                formattedDistance = string(fromValue: feet, unit: unit)
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
                    if forVoiceUse && Locale.current.languageCode == "en" {
                        vulgarFractions = ["", "a quarter", "a half", "3 quarters"]
                        if numberParts[0].isEmpty {
                            parts[2] = " \(unitString(fromValue: 1, unit: unit)) "
                            if fourths == 3 {
                                parts[2] = " of a\(parts[2])"
                            }
                        }
                    }
                    numberParts[1] = vulgarFractions[fourths]
                    if forVoiceUse && !numberParts[0].isEmpty && !numberParts[1].isEmpty {
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
