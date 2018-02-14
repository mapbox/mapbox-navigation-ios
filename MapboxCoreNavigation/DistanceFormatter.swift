import CoreLocation

extension CLLocationDistance {
    
    static let metersPerMile: CLLocationDistance = 1_609.344
    static let feetPerMeter: CLLocationDistance = 3.28084
    
    var miles: CLLocationDistance {
        return self / .metersPerMile
    }
    
    var feet: CLLocationDistance {
        return self * .feetPerMeter
    }
    
    var yards: CLLocationDistance {
        return feet / 3
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
        self.numberFormatter.locale = .nationalizedCurrent
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
        if NavigationSettings.shared.usesMetric {
            return distance < 3_000 ? 1 : 0
        } else if numberFormatter.locale.identifier == "en-GB" {
            return 0.1...3 ~= distance.miles ? 1 : 0
        } else {
            return distance.miles < 3 ? 1 : 0
        }
    }
    
    func roundingIncrement(for distance: CLLocationDistance, unit: LengthFormatter.Unit) -> Double {
        if NavigationSettings.shared.usesMetric {
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
        if NavigationSettings.shared.usesMetric {
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
            if numberFormatter.locale.identifier == "en-GB" {
                if distance.miles >= 0.1 {
                    unit = .mile
                    formattedDistance = string(fromValue: distance.miles, unit: unit)
                } else if distance.yards < 10 {
                    unit = .foot
                    formattedDistance = string(fromValue: distance.feet, unit: unit)
                } else {
                    unit = .yard
                    formattedDistance = string(fromValue: distance.yards, unit: unit)
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
        }
        
        return formattedDistance
    }
}
