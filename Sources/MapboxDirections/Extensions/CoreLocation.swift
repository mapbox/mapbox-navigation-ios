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
        return "\(longitude.rounded(to: 1e6)),\(latitude.rounded(to: 1e6))"
    }
}
