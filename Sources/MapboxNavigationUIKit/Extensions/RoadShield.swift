import Foundation
import MapboxDirections
import MapboxNavigationCore

extension RoadShield {
    var shieldRepresentation: VisualInstruction.Component.ShieldRepresentation? {
        guard let url = URL(string: baseUrl) else { return nil }
        return VisualInstruction.Component.ShieldRepresentation(
            baseURL: url,
            name: name,
            textColor: textColor,
            text: displayRef
        )
    }
}

extension RoadName {
    var routeShieldRepresentation: VisualInstruction.Component.ImageRepresentation? {
        if let representation = shield?.shieldRepresentation,
           let imageBaseUrl = shield?.baseUrl,
           let url = URL(string: imageBaseUrl)
        {
            return VisualInstruction.Component.ImageRepresentation(imageBaseURL: url, shield: representation)
        }
        return nil
    }
}
