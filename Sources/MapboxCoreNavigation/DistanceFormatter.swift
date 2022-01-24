import CoreLocation
import MapboxDirections

/**
 :nodoc:
 An object responsible for the rounding behavior of distances according to locale.
 */
public struct RoundingTable {
    /**
     :nodoc:
     `Threshold` supplies rounding behavior for a given maximum distance.
     */
    public struct Threshold {
        /**
         :nodoc:
         The maximum distance that the `Threshold` is applicable.
         */
        public let maximumDistance: Measurement<UnitLength>
        
        /**
         :nodoc:
         The increment that a given distance with be rounded to.
         */
        public let roundingIncrement: Double
        
        /**
         :nodoc:
         The maximum number of digits following the decimal point.
         */
        public let maximumFractionDigits: Int
        
        /**
         :nodoc:
         Initializes a `Threshold` object with a given maximum distance, rounding increment, and maximum fraction of digits.
         */
        public init(maximumDistance: Measurement<UnitLength>, roundingIncrement: Double, maximumFractionDigits: Int) {
            self.maximumDistance = maximumDistance
            self.roundingIncrement = roundingIncrement
            self.maximumFractionDigits = maximumFractionDigits
        }
        
        /**
         :nodoc:
         Returns a rounded `Measurement<UnitLength>` for a given distance.
         */
        public func measurement(of distance: CLLocationDistance) -> Measurement<UnitLength> {
            var measurement = Measurement(value: distance, unit: .meters).converted(to: maximumDistance.unit)
            measurement.value.round(roundingIncrement: roundingIncrement)
            measurement.value.round(precision: pow(10, Double(maximumFractionDigits)))
            return measurement
        }
    }
    
    /**
     :nodoc:
     An array of `Threshold`s that detail the rounding behavior.
     */
    public let thresholds: [Threshold]
    
    /**
     Returns the most applicable threshold for the given distance, falling back to the last threshold.
     */
    public func threshold(for distance: CLLocationDistance) -> Threshold {
        return thresholds.first {
            distance < $0.maximumDistance.distance
        } ?? thresholds.last!
    }
    
    /**
     :nodoc:
     Initializes a `RoundingTable` with the given thresholds.
     - parameter thresholds: An array of `Threshold`s that dictate rounding behavior.
     */
    public init(thresholds: [Threshold]) {
        self.thresholds = thresholds
    }

    /**
     :nodoc:
     The rounding behavior for locales where the metric system is used.
     */
    public static var metric: RoundingTable = RoundingTable(thresholds: [
        .init(maximumDistance: Measurement(value: 25, unit: .meters), roundingIncrement: 5, maximumFractionDigits: 0),
        .init(maximumDistance: Measurement(value: 100, unit: .meters), roundingIncrement: 25, maximumFractionDigits: 0),
        .init(maximumDistance: Measurement(value: 999, unit: .meters), roundingIncrement: 50, maximumFractionDigits: 0),
        // The rounding increment is a small value rather than 0 because of floating-point imprecision that causes 0.5 to round down.
        .init(maximumDistance: Measurement(value: 3, unit: .kilometers), roundingIncrement: 0.0001, maximumFractionDigits: 1),
        .init(maximumDistance: Measurement(value: 5, unit: .kilometers), roundingIncrement: 0.0001, maximumFractionDigits: 0)
    ])
    
    /**
     :nodoc:
     The rounding behavior used by the UK.
     */
    public static var uk: RoundingTable = RoundingTable(thresholds: [
        .init(maximumDistance: Measurement(value: 20, unit: .yards), roundingIncrement: 10, maximumFractionDigits: 0),
        .init(maximumDistance: Measurement(value: 100, unit: .yards), roundingIncrement: 25, maximumFractionDigits: 0),
        .init(maximumDistance: Measurement(value: 0.1, unit: .miles).converted(to: .yards), roundingIncrement: 50, maximumFractionDigits: 1),
        .init(maximumDistance: Measurement(value: 3, unit: .miles), roundingIncrement: 0.1, maximumFractionDigits: 1),
        .init(maximumDistance: Measurement(value: 5, unit: .miles), roundingIncrement: 0.0001, maximumFractionDigits: 0)
    ])
    
    /**
     :nodoc:
     The rounding behavior for locales where the imperial system is used.
     */
    public static var us: RoundingTable = RoundingTable(thresholds: [
        .init(maximumDistance: Measurement(value: 0.1, unit: .miles).converted(to: .feet), roundingIncrement: 50, maximumFractionDigits: 0),
        .init(maximumDistance: Measurement(value: 3, unit: .miles), roundingIncrement: 0.1, maximumFractionDigits: 1),
        .init(maximumDistance: Measurement(value: 5, unit: .miles), roundingIncrement: 0.0001, maximumFractionDigits: 0)
    ])
}

extension Measurement where UnitType == UnitLength {
    /**
     Initializes a measurement from the given distance.
     
     - parameter distance: The distance being measured.
     */
    public init(distance: CLLocationDistance) {
        self.init(value: distance, unit: .meters)
    }
    
    /**
     The distance in meters.
     */
    public var distance: CLLocationDistance {
        return converted(to: .meters).value
    }
    
    /**
     Returns a length measurement equivalent to the receiver but converted to the most appropriate unit based on the given locale and rounded based on the unit.
     
     - parameter locale: The locale that determines the chosen unit.
     */
    public func localized(into locale: Locale = .nationalizedCurrent) -> Measurement<UnitLength> {
        let threshold: RoundingTable
        if MeasurementSystem(NavigationSettings.shared.distanceUnit) == .metric {
            threshold = .metric
        } else if locale.languageCode == "en" && locale.regionCode == "GB" {
            threshold = .uk
        } else {
            threshold = .us
        }
        return threshold.threshold(for: distance).measurement(of: distance)
    }
}

extension NSAttributedString.Key {
    /**
     An `NSNumber` containing the numeric quantity represented by the localized substring.
     */
    public static let quantity = NSAttributedString.Key(rawValue: "MBQuantity")
}

/**
 A formatter that provides localized representations of distance units and measurements.
 
 This class is limited to `UnitLength` and its behavior is more specific to distances than `MeasurementFormatter`. By default, the class automatically localizes and rounds the measurement using `Measurement.localized(into:)` and `Locale.nationalizedCurrent`. Measurements can be formatted into either strings or attributed strings.
 */
open class DistanceFormatter: Formatter, NSSecureCoding {
    
    // MARK: Configuring the Formatting
    
    public static var supportsSecureCoding = true
    
    /**
     Options for choosing and formatting the unit.
     
     - seealso: `MeasurementFormatter.unitOptions`
     */
    open var unitOptions: MeasurementFormatter.UnitOptions {
        get {
            return measurementFormatter.unitOptions
        }
        set {
            measurementFormatter.unitOptions = newValue
        }
    }
    
    /**
     The unit style.
     
     - seealso: `MeasurementFormatter.unitStyle`
     */
    open var unitStyle: Formatter.UnitStyle {
        get {
            return measurementFormatter.unitStyle
        }
        set {
            measurementFormatter.unitStyle = newValue
        }
    }
    
    /**
     The locale that determines the chosen unit, name of the unit, and number formatting.
     
     - seealso: `MeasurementFormatter.locale`
     */
    open var locale: Locale {
        get {
            return measurementFormatter.locale
        }
        set {
            measurementFormatter.locale = newValue
        }
    }
    
    /**
     The underlying measurement formatter.
     */
    @NSCopying open var measurementFormatter = MeasurementFormatter()
    
    public override init() {
        super.init()
        unitOptions = .providedUnit
        locale = .nationalizedCurrent
    }
    
    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    // MARK: Getting String Representation of Values
    
    /**
     Creates and returns a localized, formatted string representation of the given distance in meters.
     
     The distance is converted from meters to the most appropriate unit based on the locale and quantity.
     
     - parameter distance: The distance, measured in meters, to localize and format.
     - returns: A localized, formatted representation of the distance.
     - seealso: `MeasurementFormatter.string(from:)`
     */
    open func string(from distance: CLLocationDistance) -> String {
        return string(from: Measurement(distance: distance))
    }
    
    /**
     Creates and returns a localized, formatted attributed string representation of the given distance in meters.
     
     The distance is converted from meters to the most appropriate unit based on the locale and quantity. `NSAttributedString.Key.quantity` is applied to the range representing the quantity. For example, the “5” in “5 km” has a quantity attribute set to 5.
     
     - parameter distance: The distance, measured in meters, to localize and format.
     - parameter defaultAttributes: The default attributes to apply to the resulting attributed string.
     - returns: A localized, formatted representation of the distance.
     */
    open func attributedString(from distance: CLLocationDistance, defaultAttributes attributes: [NSAttributedString.Key: Any]? = nil) -> NSAttributedString {
        return attributedString(from: Measurement(distance: distance), defaultAttributes: attributes)
    }
    
    /**
     Creates and returns a localized, formatted string representation of the given measurement.
     
     - parameter measurement: The measurement to localize and format.
     - returns: A localized, formatted representation of the measurement.
     - seealso: `MeasurementFormatter.string(from:)`
     */
    open func string(from measurement: Measurement<UnitLength>) -> String {
        return measurementFormatter.string(from: measurement.localized(into: locale))
    }
    
    /**
     Creates and returns a localized, formatted attributed string representation of the given measurement.
     
     `NSAttributedString.Key.quantity` is applied to the range representing the quantity. For example, the “5” in “5 km” has a quantity attribute set to 5.
     
     - parameter measurement: The measurement to localize and format.
     - parameter defaultAttributes: The default attributes to apply to the resulting attributed string.
     - returns: A localized, formatted representation of the measurement.
     */
    open func attributedString(from measurement: Measurement<UnitLength>, defaultAttributes attributes: [NSAttributedString.Key: Any]? = nil) -> NSAttributedString {
        let string = self.string(from: measurement)
        let localizedMeasurement = measurement.localized(into: locale)
        
        let attributedString = NSMutableAttributedString(string: string, attributes: attributes)
        if let quantityString = measurementFormatter.numberFormatter.string(from: localizedMeasurement.value as NSNumber) {
            // NSMutableAttributedString methods accept NSRange, not Range.
            let quantityRange = (string as NSString).range(of: quantityString)
            if quantityRange.location != NSNotFound {
                attributedString.addAttribute(.quantity, value: localizedMeasurement.value as NSNumber, range: quantityRange)
            }
        }
        return attributedString
    }
    
    open override func string(for obj: Any?) -> String? {
        if let distanceFromObj = obj as? CLLocationDistance {
            return self.string(from: distanceFromObj)
        } else if let measurementFromObj = obj as? Measurement<UnitLength> {
            return self.string(from: measurementFromObj)
        } else {
            return nil
        }
    }
    
    open override func attributedString(for obj: Any, withDefaultAttributes attrs: [NSAttributedString.Key : Any]? = nil) -> NSAttributedString? {
        if let distanceFromObj = obj as? CLLocationDistance {
            return self.attributedString(from: distanceFromObj, defaultAttributes: attrs)
        } else if let measurementFromObj = obj as? Measurement<UnitLength> {
            return self.attributedString(from: measurementFromObj, defaultAttributes: attrs)
        } else {
            return nil
        }
    }
}

extension Double {
    func rounded(precision: Double) -> Double {
        if precision == 0 {
            return Double(Int(rounded()))
        }
        
        return (self * precision).rounded() / precision
    }
    
    mutating func round(precision: Double) {
        self = rounded(precision: precision)
    }
    
    func rounded(roundingIncrement: Double) -> Double {
        if roundingIncrement == 0 {
            return self
        }
        
        return (self / roundingIncrement).rounded() * roundingIncrement
    }
    
    mutating func round(roundingIncrement: Double) {
        self = rounded(roundingIncrement: roundingIncrement)
    }
}
