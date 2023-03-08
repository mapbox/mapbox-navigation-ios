import Foundation
import MapboxNavigationNative
import MapboxDirections

extension NavigationStatus {
    private static let nameDelimeter = "/"

    /// Legacy `roadName` property that returns first road name based on the `roads` array.
    var roadName: String {
        var roadsWithoutShield = roads.filter { $0.shield == nil }
        if let firstRoad = roadsWithoutShield.first, firstRoad.text == NavigationStatus.nameDelimeter {
            roadsWithoutShield.removeFirst()
        }
        return roadsWithoutShield.map({ $0.text })
            .prefix(while: { $0 != NavigationStatus.nameDelimeter })
            .joined(separator: " ")
    }

    /// Returns the localized road name.
    /// - Parameter locale: The locale that determines the chosen language.
    /// - Returns: The localized road name.
    func localizedRoadName(locale: Locale = .nationalizedCurrent) -> String {
        let roadNames = localizedRoadNames(locale: locale)
        return roadNames.first { $0.shield == nil }?.text ?? roadName
    }

    // This `routeShieldRepresentation` property returns the image representation of current road shield based on the `roads` array as the `VisualInstruction.Component.ImageRepresentation`.
    var routeShieldRepresentation: VisualInstruction.Component.ImageRepresentation {
        return VisualInstruction.Component.ImageRepresentation(imageBaseURL: imageBaseUrl, shield: roadShild?.shieldRepresentation)
    }

    func localizedRouteShieldRepresentation(locale: Locale = .nationalizedCurrent) -> VisualInstruction.Component.ImageRepresentation {
        let shield = localizedRoadShield(locale: locale)?.shieldRepresentation
        let imageBaseUrl = localizedImageBaseUrl(locale: locale)

        return VisualInstruction.Component.ImageRepresentation(imageBaseURL: imageBaseUrl, shield: shield)
    }

    private func localizedImageBaseUrl(locale: Locale) -> URL? {
        let roadNames = localizedRoadNames(locale: locale)
        return roadNames.compactMap({ $0.imageBaseUrl })
            .filter({ !$0.isEmpty })
            .compactMap({ URL(string: $0) }).first ?? imageBaseUrl
    }

    private var imageBaseUrl: URL? {
        roads.compactMap({ $0.imageBaseUrl })
            .filter({ !$0.isEmpty })
            .compactMap({ URL(string: $0) })
            .first
    }

    private func localizedRoadShield(locale: Locale) -> Shield? {
        let roadNames = localizedRoadNames(locale: locale)
        return roadNames.compactMap({ $0.shield }).first ?? roadShild
    }

    private var roadShild: Shield? {
        roads.compactMap({ $0.shield }).first
    }

    private func localizedRoadNames(locale: Locale) -> [MapboxNavigationNative.RoadName] {
        roads.filter { $0.language == locale.languageCode }
    }
}

extension Shield {
    var shieldRepresentation: VisualInstruction.Component.ShieldRepresentation? {
        guard let url = URL(string: baseUrl) else { return nil }
        return VisualInstruction.Component.ShieldRepresentation(baseURL: url,
                                                                name: name,
                                                                textColor: textColor,
                                                                    text: displayRef)
        }
    }
