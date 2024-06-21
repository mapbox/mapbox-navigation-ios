import Foundation

#if canImport(CoreGraphics)
import CoreGraphics
#if os(macOS)
import Cocoa
#elseif os(watchOS)
import WatchKit
#else
import UIKit
#endif
#endif

#if canImport(CoreGraphics)
/// An image scale factor.
public typealias Scale = CGFloat
#else
/// An image scale factor.
public typealias Scale = Double
#endif

extension VisualInstruction {
    /// A unit of information displayed to the user as part of a ``VisualInstruction``.
    public enum Component: Equatable, Sendable {
        /// The component separates two other destination components.
        ///
        /// If the two adjacent components are both displayed as images, you can hide this delimiter component.
        case delimiter(text: TextRepresentation)

        /// The component bears the name of a place or street.
        case text(text: TextRepresentation)

        /// The component is an image, such as a [route marker](https://en.wikipedia.org/wiki/Highway_shield), with a
        /// fallback text representation.
        ///
        /// - Parameter image: The component’s preferred image representation.
        /// - Parameter alternativeText: The component’s alternative text representation. Use this representation if the
        /// image representation is unavailable or unusable, but consider formatting the text in a special way to
        /// distinguish it from an ordinary ``VisualInstruction/Component/text(text:)`` component.
        case image(image: ImageRepresentation, alternativeText: TextRepresentation)

        /// The component is an image of a zoomed junction, with a fallback text representation.
        case guidanceView(image: GuidanceViewImageRepresentation, alternativeText: TextRepresentation)

        /// The component contains the localized word for “Exit”.
        ///
        /// This component may appear before or after an ``VisualInstruction/Component/exitCode(text:)`` component,
        /// depending on the language. You can hide this component if the adjacent
        /// ``VisualInstruction/Component/exitCode(text:)`` component has an obvious exit-number appearance, for example
        /// with an accompanying [motorway exit
        /// icon](https://commons.wikimedia.org/wiki/File:Sinnbild_Autobahnausfahrt.svg).
        case exit(text: TextRepresentation)

        /// The component contains an exit number.
        ///
        /// You can hide the adjacent ``VisualInstruction/Component/exit(text:)`` component in favor of giving this
        /// component an obvious exit-number appearance, for example by pairing it with a [motorway exit
        /// icon](https://commons.wikimedia.org/wiki/File:Sinnbild_Autobahnausfahrt.svg).
        case exitCode(text: TextRepresentation)

        /// A component that represents a turn lane or through lane at the approach to an intersection.
        ///
        /// - parameter indications: The direction or directions of travel that the lane is reserved for.
        /// - parameter isUsable: Whether the user can use this lane to continue along the current route.
        /// - parameter preferredDirection: Which of the `indications` is applicable to the current route when there is
        /// more than one
        case lane(indications: LaneIndication, isUsable: Bool, preferredDirection: ManeuverDirection?)
    }
}

extension VisualInstruction.Component {
    /// A textual representation of a visual instruction component.
    public struct TextRepresentation: Equatable, Sendable {
        /// Initializes a text representation bearing the given abbreviatable text.
        public init(text: String, abbreviation: String?, abbreviationPriority: Int?) {
            self.text = text
            self.abbreviation = abbreviation
            self.abbreviationPriority = abbreviationPriority
        }

        /// The plain text representation of this component.
        public let text: String

        /// An abbreviated representation of the `text` property.
        public let abbreviation: String?

        /// The priority for which the component should be abbreviated.
        ///
        /// A component with a lower abbreviation priority value should be abbreviated before a component with a higher
        /// abbreviation priority value.
        public let abbreviationPriority: Int?
    }

    /// An image representation of a visual instruction component.
    public struct ImageRepresentation: Equatable, Sendable {
        /// File formats of visual instruction component images.
        public enum Format: String, Sendable {
            /// Portable Network Graphics (PNG)
            case png
            /// Scalable Vector Graphics (SVG)
            case svg
        }

        /// Initializes an image representation bearing the image at the given base URL.
        public init(imageBaseURL: URL?, shield: ShieldRepresentation? = nil) {
            self.imageBaseURL = imageBaseURL
            self.shield = shield
        }

        /// The URL whose path is the prefix of all the possible URLs returned by `imageURL(scale:format:)`.
        public let imageBaseURL: URL?

        /// Optionally, a structured image representation for displaying a [highway
        /// shield](https://en.wikipedia.org/wiki/Highway_shield).
        public let shield: ShieldRepresentation?

        /// Returns a remote URL to the image file that represents the component.
        /// - Parameters:
        ///   - scale: The image’s scale factor. If this argument is unspecified, the current screen’s native scale
        /// factor is used. Only the values 1, 2, and 3 are currently supported.
        ///   - format: The file format of the image. If this argument is unspecified, PNG is used.
        /// - Returns: A remote URL to the image.
        public func imageURL(scale: Scale, format: Format = .png) -> URL? {
            guard let imageBaseURL,
                  var imageURLComponents = URLComponents(url: imageBaseURL, resolvingAgainstBaseURL: false)
            else {
                return nil
            }
            imageURLComponents.path += "@\(Int(scale))x.\(format)"
            return imageURLComponents.url
        }
    }

    /// A mapbox shield representation of a visual instruction component.
    public struct ShieldRepresentation: Equatable, Codable, Sendable {
        /// Initializes a mapbox shield with the given name, text color, and display ref.
        public init(baseURL: URL, name: String, textColor: String, text: String) {
            self.baseURL = baseURL
            self.name = name
            self.textColor = textColor
            self.text = text
        }

        /// Base URL to query the styles endpoint.
        public let baseURL: URL

        /// String indicating the name of the route shield.
        public let name: String

        /// String indicating the color of the text to be rendered on the route shield.
        public let textColor: String

        /// String indicating the route reference code that will be displayed on the shield.
        public let text: String

        private enum CodingKeys: String, CodingKey {
            case baseURL = "base_url"
            case name
            case textColor = "text_color"
            case text = "display_ref"
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.baseURL = try container.decode(URL.self, forKey: .baseURL)
            self.name = try container.decode(String.self, forKey: .name)
            self.textColor = try container.decode(String.self, forKey: .textColor)
            self.text = try container.decode(String.self, forKey: .text)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(baseURL, forKey: .baseURL)
            try container.encode(name, forKey: .name)
            try container.encode(textColor, forKey: .textColor)
            try container.encode(text, forKey: .text)
        }
    }
}

/// A guidance view image representation of a visual instruction component.
public struct GuidanceViewImageRepresentation: Equatable, Sendable {
    /// Initializes an image representation bearing the image at the given URL.
    public init(imageURL: URL?) {
        self.imageURL = imageURL
    }

    /// Returns a remote URL to the image file that represents the component.
    public let imageURL: URL?
}

extension VisualInstruction.Component: Codable {
    private enum CodingKeys: String, CodingKey {
        case kind = "type"
        case text
        case abbreviatedText = "abbr"
        case abbreviatedTextPriority = "abbr_priority"
        case imageBaseURL
        case imageURL
        case shield = "mapbox_shield"
        case directions
        case isActive = "active"
        case activeDirection = "active_direction"
    }

    enum Kind: String, Codable, Sendable {
        case delimiter
        case text
        case image = "icon"
        case guidanceView = "guidance-view"
        case exit
        case exitCode = "exit-number"
        case lane
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = (try? container.decode(Kind.self, forKey: .kind)) ?? .text

        if kind == .lane {
            let indications = try container.decode(LaneIndication.self, forKey: .directions)
            let isUsable = try container.decode(Bool.self, forKey: .isActive)
            let preferredDirection = try container.decodeIfPresent(ManeuverDirection.self, forKey: .activeDirection)
            self = .lane(indications: indications, isUsable: isUsable, preferredDirection: preferredDirection)
            return
        }

        let text = try container.decode(String.self, forKey: .text)
        let abbreviation = try container.decodeIfPresent(String.self, forKey: .abbreviatedText)
        let abbreviationPriority = try container.decodeIfPresent(Int.self, forKey: .abbreviatedTextPriority)
        let textRepresentation = TextRepresentation(
            text: text,
            abbreviation: abbreviation,
            abbreviationPriority: abbreviationPriority
        )

        switch kind {
        case .delimiter:
            self = .delimiter(text: textRepresentation)
        case .text:
            self = .text(text: textRepresentation)
        case .image:
            var imageBaseURL: URL?
            if let imageBaseURLString = try container.decodeIfPresent(String.self, forKey: .imageBaseURL) {
                imageBaseURL = URL(string: imageBaseURLString)
            }
            let shieldRepresentation = try container.decodeIfPresent(ShieldRepresentation.self, forKey: .shield)
            let imageRepresentation = ImageRepresentation(imageBaseURL: imageBaseURL, shield: shieldRepresentation)
            self = .image(image: imageRepresentation, alternativeText: textRepresentation)
        case .exit:
            self = .exit(text: textRepresentation)
        case .exitCode:
            self = .exitCode(text: textRepresentation)
        case .lane:
            preconditionFailure("Lane component should have been initialized before decoding text")
        case .guidanceView:
            var imageURL: URL?
            if let imageURLString = try container.decodeIfPresent(String.self, forKey: .imageURL) {
                imageURL = URL(string: imageURLString)
            }
            let guidanceViewImageRepresentation = GuidanceViewImageRepresentation(imageURL: imageURL)
            self = .guidanceView(image: guidanceViewImageRepresentation, alternativeText: textRepresentation)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let textRepresentation: TextRepresentation?
        switch self {
        case .delimiter(let text):
            try container.encode(Kind.delimiter, forKey: .kind)
            textRepresentation = text
        case .text(let text):
            try container.encode(Kind.text, forKey: .kind)
            textRepresentation = text
        case .image(let image, let alternativeText):
            try container.encode(Kind.image, forKey: .kind)
            textRepresentation = alternativeText
            try container.encodeIfPresent(image.imageBaseURL?.absoluteString, forKey: .imageBaseURL)
            try container.encodeIfPresent(image.shield, forKey: .shield)
        case .exit(let text):
            try container.encode(Kind.exit, forKey: .kind)
            textRepresentation = text
        case .exitCode(let text):
            try container.encode(Kind.exitCode, forKey: .kind)
            textRepresentation = text
        case .lane(let indications, let isUsable, let preferredDirection):
            try container.encode(Kind.lane, forKey: .kind)
            textRepresentation = .init(text: "", abbreviation: nil, abbreviationPriority: nil)
            try container.encode(indications, forKey: .directions)
            try container.encode(isUsable, forKey: .isActive)
            try container.encodeIfPresent(preferredDirection, forKey: .activeDirection)
        case .guidanceView(let image, let alternativeText):
            try container.encode(Kind.guidanceView, forKey: .kind)
            textRepresentation = alternativeText
            try container.encodeIfPresent(image.imageURL?.absoluteString, forKey: .imageURL)
        }

        if let textRepresentation {
            try container.encodeIfPresent(textRepresentation.text, forKey: .text)
            try container.encodeIfPresent(textRepresentation.abbreviation, forKey: .abbreviatedText)
            try container.encodeIfPresent(textRepresentation.abbreviationPriority, forKey: .abbreviatedTextPriority)
        }
    }
}

extension VisualInstruction.Component {
    public static func == (lhs: VisualInstruction.Component, rhs: VisualInstruction.Component) -> Bool {
        switch (lhs, rhs) {
        case (let .delimiter(lhsText), .delimiter(let rhsText)),
             (let .text(lhsText), .text(let rhsText)),
             (let .exit(lhsText), .exit(let rhsText)),
             (let .exitCode(lhsText), .exitCode(let rhsText)):
            return lhsText == rhsText
        case (
            let .image(lhsURL, lhsAlternativeText),
            .image(let rhsURL, let rhsAlternativeText)
        ):
            return lhsURL == rhsURL
                && lhsAlternativeText == rhsAlternativeText
        case (
            let .guidanceView(lhsURL, lhsAlternativeText),
            .guidanceView(let rhsURL, let rhsAlternativeText)
        ):
            return lhsURL == rhsURL
                && lhsAlternativeText == rhsAlternativeText
        case (
            let .lane(lhsIndications, lhsIsUsable, lhsPreferredDirection),
            .lane(let rhsIndications, let rhsIsUsable, let rhsPreferredDirection)
        ):
            return lhsIndications == rhsIndications
                && lhsIsUsable == rhsIsUsable
                && lhsPreferredDirection == rhsPreferredDirection
        case (.delimiter, _),
             (.text, _),
             (.image, _),
             (.exit, _),
             (.exitCode, _),
             (.guidanceView, _),
             (.lane, _):
            return false
        }
    }
}
