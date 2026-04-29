import Foundation
import Turf

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif

/// Options for calculating contours from the Mapbox Isochrone service.
public struct IsochroneOptions: Equatable, Sendable {
    public init(
        centerCoordinate: LocationCoordinate2D,
        contours: Contours,
        profileIdentifier: ProfileIdentifier = .automobile
    ) {
        self.centerCoordinate = centerCoordinate
        self.contours = contours
        self.profileIdentifier = profileIdentifier
    }

    // MARK: Configuring the Contour

    /// Contours GeoJSON format.
    public enum ContourFormat: Equatable, Sendable {
        /// Requested contour will be presented as GeoJSON LineString.
        case lineString
        /// Requested contour will be presented as GeoJSON Polygon.
        case polygon
    }

    /// A string specifying the primary mode of transportation for the contours.
    ///
    /// The default value of this property is ``ProfileIdentifier/automobile``, which specifies driving directions.
    public var profileIdentifier: ProfileIdentifier
    /// A coordinate around which to center the isochrone lines.
    public var centerCoordinate: LocationCoordinate2D
    /// Contours bounds and color sheme definition.
    public var contours: Contours

    /// Specifies the format of output contours.
    ///
    /// Defaults to ``ContourFormat/lineString`` which represents contours as linestrings.
    public var contoursFormat: ContourFormat = .lineString

    /// Removes contours which are ``denoisingFactor`` times smaller than the biggest one.
    ///
    /// The default is 1.0. A value of 1.0 will only return the largest contour for a given value. A value of 0.5 drops
    /// any contours that are less than half the area of the largest contour in the set of contours for that same value.
    public var denoisingFactor: Float?

    /// Douglas-Peucker simplification tolerance.
    ///
    /// Higher means simpler geometries and faster performance. There is no upper bound. If no value is specified in the
    /// request, the Isochrone API will choose the most optimized value to use for the request.
    ///
    /// - Note: Simplification of contours can lead to self-intersections, as well as intersections of adjacent
    /// contours.
    public var simplificationTolerance: LocationDistance?

    // MARK: Getting the Request URL

    /// The path of the request URL, specifying service name, version and profile.
    var abridgedPath: String {
        return "isochrone/v1/\(profileIdentifier.rawValue)"
    }

    /// The path of the request URL, not including the hostname or any parameters.
    var path: String {
        return "\(abridgedPath)/\(centerCoordinate.requestDescription)"
    }

    /// An array of URL query items (parameters) to include in an HTTP request.
    public var urlQueryItems: [URLQueryItem] {
        var queryItems: [URLQueryItem] = []

        switch contours {
        case .byDistances(let definitions):
            let fallbackColor = definitions.allSatisfy { $0.color != nil } ? nil : Color.fallbackColor

            queryItems.append(URLQueryItem(
                name: "contours_meters",
                value: definitions.map { $0.queryValueDescription(roundingTo: .meters) }
                    .joined(separator: ",")
            ))

            let colors = definitions.compactMap { $0.queryColorDescription(fallbackColor: fallbackColor) }
                .joined(separator: ",")
            if !colors.isEmpty {
                queryItems.append(URLQueryItem(name: "contours_colors", value: colors))
            }
        case .byExpectedTravelTimes(let definitions):
            let fallbackColor = definitions.allSatisfy { $0.color != nil } ? nil : Color.fallbackColor

            queryItems.append(URLQueryItem(
                name: "contours_minutes",
                value: definitions.map { $0.queryValueDescription(roundingTo: .minutes) }
                    .joined(separator: ",")
            ))

            let colors = definitions.compactMap { $0.queryColorDescription(fallbackColor: fallbackColor) }
                .joined(separator: ",")
            if !colors.isEmpty {
                queryItems.append(URLQueryItem(name: "contours_colors", value: colors))
            }
        }

        if contoursFormat == .polygon {
            queryItems.append(URLQueryItem(name: "polygons", value: "true"))
        }

        if let denoise = denoisingFactor {
            queryItems.append(URLQueryItem(name: "denoise", value: String(denoise)))
        }

        if let tolerance = simplificationTolerance {
            queryItems.append(URLQueryItem(name: "generalize", value: String(tolerance)))
        }

        return queryItems
    }
}

extension IsochroneOptions {
    /// Definition of contours limits.
    public enum Contours: Equatable, Sendable {
        /// Describes Individual contour bound and color.
        public struct Definition<Unt: Dimension & Sendable>: Equatable, Sendable {
            /// Bound measurement value.
            public var value: Measurement<Unt>
            /// Contour fill color.
            ///
            /// If this property is unspecified, the contour is colored gray. If this property is not specified for any
            /// contour, the contours are rainbow-colored.
            public var color: Color?

            /// Initializes new contour Definition.
            public init(value: Measurement<Unt>, color: Color? = nil) {
                self.value = value
                self.color = color
            }

            /// Initializes new contour Definition.
            ///
            /// Convenience initializer for encapsulating `Measurement` initialization.
            public init(value: Double, unit: Unt, color: Color? = nil) {
                self.init(
                    value: Measurement(value: value, unit: unit),
                    color: color
                )
            }

            func queryValueDescription(roundingTo unit: Unt) -> String {
                return String(Int(value.converted(to: unit).value.rounded()))
            }

            func queryColorDescription(fallbackColor: Color?) -> String? {
                return (color ?? fallbackColor)?.queryDescription
            }
        }

        /// The desired travel times to use for each isochrone contour.
        ///
        /// This value will be rounded to minutes.
        case byExpectedTravelTimes([Definition<UnitDuration>])

        /// The distances to use for each isochrone contour.
        ///
        /// Will be rounded to meters.
        case byDistances([Definition<UnitLength>])
    }
}

extension IsochroneOptions {
#if canImport(UIKit)
    /// RGB-based color representation for Isochrone contour.
    public typealias Color = UIColor
#elseif canImport(AppKit)
    /// RGB-based color representation for Isochrone contour.
    public typealias Color = NSColor
#else
    /// sRGB color space representation for Isochrone contour.
    ///
    /// This is a compatibility shim to keep the library’s public interface consistent between Apple and non-Apple
    /// platforms that lack `UIKit` or `AppKit`. On Apple platforms, you can use `UIColor` or `NSColor` respectively
    /// anywhere you see this type.
    public struct Color {
        /// Red color component.
        ///
        /// Value ranged from `0` up to `255`.
        public var red: Int
        /// Green color component.
        ///
        /// Value ranged from `0` up to `255`.
        public var green: Int
        /// Blue color component.
        ///
        /// Value ranged from `0` up to `255`.
        public var blue: Int

        /// Creates new `Color` instance.
        public init(red: Int, green: Int, blue: Int) {
            self.red = red
            self.green = green
            self.blue = blue
        }
    }
#endif
}

extension IsochroneOptions.Color {
    var queryDescription: String {
        let hexFormat = "%02X%02X%02X"

#if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0

        getRed(
            &red,
            green: &green,
            blue: &blue,
            alpha: nil
        )

        return String(
            format: hexFormat,
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
#elseif canImport(AppKit)
        var convertedColor = self
        if colorSpace != .sRGB {
            guard let converted = usingColorSpace(.sRGB) else {
                assertionFailure("Failed to convert Isochrone contour color to RGB space.")
                return "000000"
            }

            convertedColor = converted
        }

        return String(
            format: hexFormat,
            Int(convertedColor.redComponent * 255),
            Int(convertedColor.greenComponent * 255),
            Int(convertedColor.blueComponent * 255)
        )
#else
        return String(
            format: hexFormat,
            red,
            green,
            blue
        )
#endif
    }

    static var fallbackColor: IsochroneOptions.Color {
#if canImport(UIKit)
        return gray
#elseif canImport(AppKit)
        return gray
#else
        return IsochroneOptions.Color(red: 128, green: 128, blue: 128)
#endif
    }
}
