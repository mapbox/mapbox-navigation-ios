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
    
    var kilometers: CLLocationDistance {
        return self / 1000
    }
}

/// Provides appropriately formatted, localized descriptions of linear distances.
@objc(MBDistanceFormatter)
public class DistanceFormatter: LengthFormatter {
    /// True to favor brevity over precision.
    var approx: Bool
    
    let nonFractionalLengthFormatter = LengthFormatter()
    
    /// Indicates the most recently used unit
    public private(set) var unit: LengthFormatter.Unit = .millimeter
    
    /**
     Intializes a new `DistanceFormatter`.
     
     - parameter approximate: approximates the distances.
     */
    @objc public init(approximate: Bool = false) {
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
        if numberFormatter.locale.usesMetric {
            return distance < 3_000 ? 1 : 0
        } else {
            return distance.miles < 3 ? 1 : 0
        }
    }
    
    func roundingIncrement(for distance: CLLocationDistance, unit: LengthFormatter.Unit) -> Double {
        if numberFormatter.locale.usesMetric {
            if distance < 25 {
                return 5
            } else if distance < 100 {
                return 25
            } else if distance < 1_000 {
                return 50
            }
            return distance < 3_000 ? 0 : 0.5
        } else {
            if unit == .yard {
                if distance.miles >= 0.1 {
                    return 0
                } else {
                    return 50
                }
            } else {
                return 0.1
            }
        }
    }
    
    /**
     Returns a more human readable `String` from a given `CLLocationDistance`.
     
     The user’s `Locale` is used here to set the units.
    */
    @objc public func string(from distance: CLLocationDistance) -> String {
        // British roads are measured in miles, yards, and feet. Simulate this idiosyncrasy using the U.S. locale.
        let localeIdentifier = numberFormatter.locale.identifier
        if localeIdentifier == "en-GB" || localeIdentifier == "en_GB" {
            numberFormatter.locale = Locale(identifier: "en-US")
        }
        
        numberFormatter.positivePrefix = ""
        numberFormatter.positiveSuffix = ""
        numberFormatter.decimalSeparator = nonFractionalLengthFormatter.numberFormatter.decimalSeparator
        numberFormatter.alwaysShowsDecimalSeparator = nonFractionalLengthFormatter.numberFormatter.alwaysShowsDecimalSeparator
        numberFormatter.usesSignificantDigits = false
        numberFormatter.maximumFractionDigits = maximumFractionDigits(for: distance)
        
        unitString(fromMeters: distance, usedUnit: &unit)
        
        numberFormatter.roundingIncrement = roundingIncrement(for: distance, unit: unit) as NSNumber
        
        return formattedDistance(distance, modify: &unit)
    }
    
    @objc public override func string(fromMeters numberInMeters: Double) -> String {
        return self.string(from: numberInMeters)
    }
    
    func formattedDistance(_ distance: CLLocationDistance, modify unit: inout LengthFormatter.Unit) -> String {
        var formattedDistance: String
        if numberFormatter.locale.usesMetric {
            let roundedDistance: CLLocationDistance = numberFormatter.number(from: numberFormatter.string(from: distance as NSNumber)!)?.doubleValue ?? distance
            numberFormatter.roundingIncrement = roundingIncrement(for: roundedDistance, unit: unit) as NSNumber
            
            if roundedDistance >= 1000 {
                unit = .kilometer
                formattedDistance = string(fromValue: roundedDistance.kilometers, unit: unit)
            } else {
                unit = .meter
                formattedDistance = string(fromValue: roundedDistance, unit: unit)
            }
        } else {
            if unit == .yard {
                if distance.miles >= 0.1 {
                    unit = .mile
                    formattedDistance = string(fromValue: distance.miles, unit: unit)
                } else {
                    unit = .foot
                    formattedDistance = string(fromValue: distance.feet, unit: unit)
                }
            } else {
                formattedDistance = super.string(fromMeters: distance)
            }
        }
        
        return formattedDistance
    }
}
