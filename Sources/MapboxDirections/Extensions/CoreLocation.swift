import Foundation
#if canImport(CoreLocation)
import CoreLocation
#endif
import Turf

#if canImport(CoreLocation)
/// The velocity (measured in meters per second) at which the device is moving.
///
/// This is a compatibility shim to keep the library’s public interface consistent between Apple and non-Apple platforms
/// that lack Core Location. On Apple platforms, you can use `CLLocationSpeed` anywhere you see this type.
public typealias LocationSpeed = CLLocationSpeed

/// The accuracy of a geographical coordinate.
///
/// This is a compatibility shim to keep the library’s public interface consistent between Apple and non-Apple platforms
/// that lack Core Location. On Apple platforms, you can use `CLLocationAccuracy` anywhere you see this type.
public typealias LocationAccuracy = CLLocationAccuracy
#else
/// The velocity (measured in meters per second) at which the device is moving.
public typealias LocationSpeed = Double

/// The accuracy of a geographical coordinate.
public typealias LocationAccuracy = Double
#endif

extension LocationCoordinate2D {
    var requestDescription: String {
        return "\(longitude.roundedForWKT),\(latitude.roundedForWKT)"
    }

    /// The coordinate formatted as a WKT `point(longitude latitude)` literal, as expected by the Directions API's
    /// `exclude` parameter for excluding custom locations from routing.
    var wktPointDescription: String {
        return "point(\(longitude.roundedForWKT) \(latitude.roundedForWKT))"
    }

    /// Creates a coordinate from a WKT `point(longitude latitude)` literal, as produced by ``wktPointDescription``.
    ///
    /// Surrounding whitespace is ignored,
    /// Returns `nil` if the string isn't a well-formed WKT point.
    init?(wktPointDescription: some StringProtocol) {
        let literal = wktPointDescription.trimmingCharacters(in: .whitespaces)
        let keyword = "point("
        guard literal.prefix(keyword.count).lowercased() == keyword, literal.hasSuffix(")") else {
            return nil
        }
        let inner = literal.dropFirst(keyword.count).dropLast()
        let components = inner.split(separator: " ")
        guard components.count == 2,
              let longitude = LocationDegrees(components[0]),
              let latitude = LocationDegrees(components[1])
        else {
            return nil
        }
        self.init(latitude: latitude, longitude: longitude)
    }
}

extension Double {
    fileprivate var roundedForWKT: Double {
        rounded(to: 1e6)
    }
}
