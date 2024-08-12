import Foundation
import MapboxDirections
import MapboxNavigationNative

extension NavigationStatus {
    private static let nameSeparator = " / "

    func localizedRoadName(locale: Locale = .nationalizedCurrent) -> RoadName {
        let roadNames = localizedRoadNames(locale: locale)

        let name = roadNames.first { $0.shield == nil } ?? nonLocalizedRoadName
        let shield = localizedShield(locale: locale).map(RoadShield.init)
        return .init(text: name.text, language: name.language, shield: shield)
    }

    private var nonLocalizedRoadName: MapboxNavigationNative.RoadName {
        let text = roads
            .filter { $0.shield == nil }
            .map(\.text)
            .joined(separator: NavigationStatus.nameSeparator)
        return .init(text: text, language: "", imageBaseUrl: nil, shield: nil)
    }

    private func localizedShield(locale: Locale) -> Shield? {
        let roadNames = localizedRoadNames(locale: locale)
        return roadNames.compactMap(\.shield).first ?? shield
    }

    private func localizedRoadNames(locale: Locale) -> [MapboxNavigationNative.RoadName] {
        roads.filter { $0.language == locale.languageCode }
    }

    private var shield: Shield? {
        roads.compactMap(\.shield).first
    }
}
