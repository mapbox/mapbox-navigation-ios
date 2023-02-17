import Foundation
import MapboxNavigationNative

/// Road object information, like interchange name.
public struct LocalizedRoadObjectName: Equatable {
    /// 2 letters language code, e.g. en or ja.
    public let language: String

    /// The name of the road object.
    public let text: String

    /// Initializes a new `LocalizedRoadObjectName` object.
    /// - Parameters:
    ///   - language: 2 letters language code, e.g. en or ja.
    ///   - text: The name of the road object.
    public init(language: String, text: String) {
        self.language = language
        self.text = text
    }

    init(_ localizedString: LocalizedString) {
        self.init(language: localizedString.language, text: localizedString.value)
    }
}
