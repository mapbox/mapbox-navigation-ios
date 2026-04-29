import Foundation
import Turf

/// A type with a customized Quick Look representation in the Xcode debugger.
protocol CustomQuickLookConvertible {
    /// Returns a [Quick Look–compatible](https://developer.apple.com/library/archive/documentation/IDEs/Conceptual/CustomClassDisplay_in_QuickLook/CH02-std_objects_support/CH02-std_objects_support.html#//apple_ref/doc/uid/TP40014001-CH3-SW19)
    /// representation for display in the Xcode debugger.
    func debugQuickLookObject() -> Any?
}

/// Returns a URL to an image representation of the given coordinates via the [Mapbox Static Images
/// API](https://docs.mapbox.com/api/maps/#static-images).
func debugQuickLookURL(
    illustrating shape: LineString,
    profileIdentifier: ProfileIdentifier = .automobile,
    accessToken: String? = defaultAccessToken
) -> URL? {
    guard let accessToken else {
        return nil
    }

    let styleIdentifier: String
    let identifierOfLayerAboveOverlays: String
    switch profileIdentifier {
    case .automobileAvoidingTraffic:
        styleIdentifier = "mapbox/navigation-preview-day-v4"
        identifierOfLayerAboveOverlays = "waterway-label"
    case .cycling, .walking:
        styleIdentifier = "mapbox/outdoors-v11"
        identifierOfLayerAboveOverlays = "contour-label"
    default:
        styleIdentifier = "mapbox/streets-v11"
        identifierOfLayerAboveOverlays = "building-number-label"
    }
    let styleIdentifierComponent = "/\(styleIdentifier)/static"

    var allowedCharacterSet = CharacterSet.urlPathAllowed
    allowedCharacterSet.remove(charactersIn: "/)")
    let encodedPolyline = shape.polylineEncodedString(precision: 1e5)
        .addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
    let overlaysComponent = "/path-10+3802DA-0.6(\(encodedPolyline))"

    let path = "/styles/v1\(styleIdentifierComponent)\(overlaysComponent)/auto/680x360@2x"

    var components = URLComponents()
    components.queryItems = [
        URLQueryItem(name: "before_layer", value: identifierOfLayerAboveOverlays),
        URLQueryItem(name: "access_token", value: accessToken),
    ]

    return URL(
        string: "\(defaultApiEndPointURLString ?? "https://api.mapbox.com")\(path)?\(components.percentEncodedQuery!)"
    )
}
