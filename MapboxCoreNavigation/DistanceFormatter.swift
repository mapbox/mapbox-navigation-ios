import CoreLocation

let metersPerMile: CLLocationDistance = 1_609.344
let secondsPerHour = 60.0 * 60.0
let yardsPerMile = 1_760.0
let feetPerMile = yardsPerMile * 3.0

/// Provides appropriately formatted, localized descriptions of linear distances.
@objc(MBDistanceFormatter)
public class DistanceFormatter: LengthFormatter {
    /// True to favor brevity over precision.
    var approx: Bool
    
    let nonFractionalLengthFormatter = LengthFormatter()
    
    /**
     Intializes a new `DistanceFormatter`.
     
     - parameter approximate: approximates the distances.
     */
    public init(approximate: Bool = false) {
        self.approx = approximate
        super.init()
    }
    
    public required init?(coder decoder: NSCoder) {
        approx = decoder.decodeBool(forKey: "approximate")
        super.init(coder: decoder)
    }
    
    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        aCoder.encode(approx, forKey: "approximate")
    }
    
    /**
     Returns a more human readable `String` from a given `CLLocationDistance`.
     
     The user’s `Locale` is used here to set the units.
    */
    public func string(from distance: CLLocationDistance) -> String {
        let miles = distance / metersPerMile
        let feet = miles * feetPerMile
        
        // British roads are measured in miles, yards, and feet. Simulate this idiosyncrasy using the U.S. locale.
        let isBritish = Locale.current.identifier == "en-GB"
        
        numberFormatter.locale = isBritish ? Locale(identifier: "en-US") : Locale.current
        numberFormatter.positivePrefix = ""
        numberFormatter.positiveSuffix = ""
        numberFormatter.decimalSeparator = nonFractionalLengthFormatter.numberFormatter.decimalSeparator
        numberFormatter.alwaysShowsDecimalSeparator = nonFractionalLengthFormatter.numberFormatter.alwaysShowsDecimalSeparator
        numberFormatter.roundingIncrement = 0.25
        
        if approx {
            numberFormatter.usesSignificantDigits = true
            numberFormatter.maximumSignificantDigits = 2
        } else {
            numberFormatter.usesSignificantDigits = false
            numberFormatter.maximumFractionDigits = 0
        }
        
        var unit: LengthFormatter.Unit = .millimeter
        unitString(fromMeters: distance, usedUnit: &unit)
        
        var formattedDistance: String
        if unit == .yard {
            if miles > 0.2 {
                unit = .mile
                formattedDistance = string(fromValue: miles, unit: unit)
            } else if !isBritish {
                unit = .foot
                numberFormatter.roundingIncrement = 50
                formattedDistance = string(fromValue: feet, unit: unit)
            } else {
                numberFormatter.roundingIncrement = 50
                formattedDistance = string(fromMeters: distance)
            }
        } else {
            formattedDistance = string(fromMeters: distance)
        }
        
        return formattedDistance
    }
}
