import CoreLocation

struct RoundingTable {
    struct Threshold {
        let maximumDistance: Measurement<UnitLength>
        let roundingIncrement: Double
        let maximumFractionDigits: Int
        
        func measurement(of distance: CLLocationDistance) -> Measurement<UnitLength> {
            var measurement = Measurement(value: distance, unit: .meters).converted(to: maximumDistance.unit)
            measurement.value.round(roundingIncrement: roundingIncrement)
            measurement.value.round(precision: pow(10, Double(maximumFractionDigits)))
            return measurement
        }
    }
    
    let thresholds: [Threshold]
    
    /**
     Returns the most applicable threshold for the given distance, falling back to the last threshold.
     */
    func threshold(for distance: CLLocationDistance) -> Threshold {
        return thresholds.first {
            distance < $0.maximumDistance.converted(to: .meters).value
        } ?? thresholds.last!
    }
    
    static var metric: RoundingTable = RoundingTable(thresholds: [
        .init(maximumDistance: Measurement(value: 25, unit: .meters), roundingIncrement: 5, maximumFractionDigits: 0),
        .init(maximumDistance: Measurement(value: 100, unit: .meters), roundingIncrement: 25, maximumFractionDigits: 0),
        .init(maximumDistance: Measurement(value: 999, unit: .meters), roundingIncrement: 50, maximumFractionDigits: 0),
        .init(maximumDistance: Measurement(value: 3, unit: .kilometers), roundingIncrement: 0, maximumFractionDigits: 1),
        .init(maximumDistance: Measurement(value: 5, unit: .kilometers), roundingIncrement: 0, maximumFractionDigits: 0)
    ])
    
    static var uk: RoundingTable = RoundingTable(thresholds: [
        .init(maximumDistance: Measurement(value: 20, unit: .yards), roundingIncrement: 10, maximumFractionDigits: 0),
        .init(maximumDistance: Measurement(value: 100, unit: .yards), roundingIncrement: 25, maximumFractionDigits: 0),
        .init(maximumDistance: Measurement(value: 0.1, unit: .miles).converted(to: .yards), roundingIncrement: 50, maximumFractionDigits: 1),
        .init(maximumDistance: Measurement(value: 3, unit: .miles), roundingIncrement: 0.1, maximumFractionDigits: 1),
        .init(maximumDistance: Measurement(value: 5, unit: .miles), roundingIncrement: 0, maximumFractionDigits: 0)
    ])
    
    static var us: RoundingTable = RoundingTable(thresholds: [
        .init(maximumDistance: Measurement(value: 0.1, unit: .miles).converted(to: .feet), roundingIncrement: 50, maximumFractionDigits: 0),
        .init(maximumDistance: Measurement(value: 3, unit: .miles), roundingIncrement: 0.1, maximumFractionDigits: 1),
        .init(maximumDistance: Measurement(value: 5, unit: .miles), roundingIncrement: 0, maximumFractionDigits: 0)
    ])
}

extension Locale {
    func threshold(for distance: CLLocationDistance) -> RoundingTable.Threshold {
        if NavigationSettings.shared.usesMetric {
            return RoundingTable.metric.threshold(for: distance)
        } else if languageCode == "en" && regionCode == "GB" {
            return RoundingTable.uk.threshold(for: distance)
        } else {
            return RoundingTable.us.threshold(for: distance)
        }
    }
}

extension NSAttributedString.Key {
    public static let quantity = NSAttributedString.Key(rawValue: "MBQuantity")
}

/// Provides appropriately formatted, localized descriptions of linear distances.
@objc(MBDistanceFormatter)
open class DistanceFormatter: LengthFormatter {
    let measurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.locale = .nationalizedCurrent
        formatter.unitOptions = .providedUnit
        return formatter
    }()
    
    var locale: Locale {
        get {
            return measurementFormatter.locale
        }
        set {
            measurementFormatter.locale = newValue
            measurementFormatter.numberFormatter.locale = newValue
            numberFormatter.locale = newValue
        }
    }
    
    /**
     Intializes a new distance formatter.
     */
    @objc public override init() {
        super.init()
    }
    
    /**
     Intializes a new distance formatter.
     
     - parameter approximate: approximates the distances.
     */
    @available(*, deprecated, message: "The approximate argument is deprecated. Use init() instead.")
    @objc public init(approximate: Bool) {
        super.init()
    }
    
    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    open override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
    }
    
    /**
     Returns a more human readable `String` from a given `CLLocationDistance`.
     
     The user’s `Locale` is used here to set the units.
    */
    @objc public func string(from distance: CLLocationDistance) -> String {
        let threshold = locale.threshold(for: distance)
        let measurement = threshold.measurement(of: distance)
        measurementFormatter.numberFormatter.maximumFractionDigits = threshold.maximumFractionDigits
        measurementFormatter.numberFormatter.roundingIncrement = threshold.roundingIncrement as NSNumber
        measurementFormatter.numberFormatter.locale = locale
        return measurementFormatter.string(from: measurement)
    }
    
    @objc open override func string(fromMeters numberInMeters: Double) -> String {
        return self.string(from: numberInMeters)
    }
    
    @objc(measurementOfDistance:)
    public func measurement(of distance: CLLocationDistance) -> Measurement<UnitLength> {
        let threshold = locale.threshold(for: distance)
        return threshold.measurement(of: distance)
    }
    
    /**
     Returns an attributed string containing the formatted, converted distance.
     
     `NSAttributedStringKey.quantity` is applied to the numeric quantity.
     */
    @objc open override func attributedString(for obj: Any, withDefaultAttributes attrs: [NSAttributedString.Key : Any]? = nil) -> NSAttributedString? {
        guard let distance = obj as? CLLocationDistance else {
            return nil
        }
        
        let string = self.string(from: distance)
        let attributedString = NSMutableAttributedString(string: string, attributes: attrs)
        let convertedDistance = measurement(of: distance).value
        if let quantityString = measurementFormatter.numberFormatter.string(from: convertedDistance as NSNumber) {
            // NSMutableAttributedString methods accept NSRange, not Range.
            let quantityRange = (string as NSString).range(of: quantityString)
            if quantityRange.location != NSNotFound {
                attributedString.addAttribute(.quantity, value: distance as NSNumber, range: quantityRange)
            }
        }
        return attributedString
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
