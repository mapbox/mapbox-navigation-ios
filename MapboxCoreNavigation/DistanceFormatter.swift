import CoreLocation

let metersPerMile: CLLocationDistance = 1_609.344
let secondsPerHour = 60.0 * 60.0
let yardsPerMile = 1_760.0
let feetPerMile = yardsPerMile * 3.0
let feetPerMeter = 3.28084

extension CLLocationDistance {
    var miles: CLLocationDistance {
        return self / metersPerMile
    }
    
    var feet: CLLocationDistance {
        return self * feetPerMeter
    }
}

/// Provides appropriately formatted, localized descriptions of linear distances.
@objc(MBDistanceFormatter)
public class DistanceFormatter: LengthFormatter {
    /// True to favor brevity over precision.
    var approx: Bool
    
    let nonFractionalLengthFormatter = LengthFormatter()
    
    var forcedLocale: Locale?
    
    var preferredLocale: Locale {
        // British roads are measured in miles, yards, and feet. Simulate this idiosyncrasy using the U.S. locale.
        let locale = forcedLocale ?? Locale.current
        return locale.identifier == "en-GB" || locale.identifier == "en_GB" ? Locale(identifier: "en-US") : locale
    }
    
    var usesMetric: Bool {
        let locale = preferredLocale as NSLocale
        guard let measurementSystem = locale.object(forKey: .measurementSystem) as? String else {
            return false
        }
        return measurementSystem == "Metric"
    }
    
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
    
    func maximumFractionDigits(for distance: CLLocationDistance) -> Int {
        if usesMetric {
            return distance < 3_000 ? 1 : 0
        } else {
            return distance.miles < 3 ? 1 : 0
        }
    }
    
    /**
     Returns a more human readable `String` from a given `CLLocationDistance`.
     
     The user’s `Locale` is used here to set the units.
    */
    public func string(from distance: CLLocationDistance) -> String {
        numberFormatter.locale = preferredLocale
        numberFormatter.positivePrefix = ""
        numberFormatter.positiveSuffix = ""
        numberFormatter.decimalSeparator = nonFractionalLengthFormatter.numberFormatter.decimalSeparator
        numberFormatter.alwaysShowsDecimalSeparator = nonFractionalLengthFormatter.numberFormatter.alwaysShowsDecimalSeparator
        numberFormatter.roundingIncrement = 0.25
        numberFormatter.usesSignificantDigits = false
        numberFormatter.maximumFractionDigits = maximumFractionDigits(for: distance)
        
        var unit: LengthFormatter.Unit = .millimeter
        unitString(fromMeters: distance, usedUnit: &unit)
        
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
        
        return formattedDistance
    }
}
