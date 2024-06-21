import Foundation
import Turf

/// An instruction about an upcoming ``RouteStep``’s maneuver, optimized for speech synthesis.
///
/// The instruction is provided in two formats: plain text and text marked up according to the [Speech Synthesis Markup
/// Language](https://en.wikipedia.org/wiki/Speech_Synthesis_Markup_Language) (SSML). Use a speech synthesizer such as
/// `AVSpeechSynthesizer` or Amazon Polly to read aloud the instruction.
///
/// The ``SpokenInstruction/distanceAlongStep`` property is measured from the beginning of the step associated with this
/// object. By contrast, the `text` and `ssmlText` properties refer to the details in the following step. It is also
/// possible for the instruction to refer to two following steps simultaneously when needed for safe navigation.
public struct SpokenInstruction: Codable, ForeignMemberContainer, Equatable, Sendable {
    public var foreignMembers: JSONObject = [:]

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case distanceAlongStep = "distanceAlongGeometry"
        case text = "announcement"
        case ssmlText = "ssmlAnnouncement"
    }

    // MARK: Creating a Spoken Instruction

    /// Initialize a spoken instruction.
    /// - Parameters:
    ///   - distanceAlongStep: A distance along the associated ``RouteStep`` at which to read the instruction aloud.
    ///   - text: A plain-text representation of the speech-optimized instruction.
    ///   - ssmlText: A formatted representation of the speech-optimized instruction.
    public init(distanceAlongStep: LocationDistance, text: String, ssmlText: String) {
        self.distanceAlongStep = distanceAlongStep
        self.text = text
        self.ssmlText = ssmlText
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.distanceAlongStep = try container.decode(LocationDistance.self, forKey: .distanceAlongStep)
        self.text = try container.decode(String.self, forKey: .text)
        self.ssmlText = try container.decode(String.self, forKey: .ssmlText)

        try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(distanceAlongStep, forKey: .distanceAlongStep)
        try container.encode(text, forKey: .text)
        try container.encode(ssmlText, forKey: .ssmlText)

        try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
    }

    // MARK: Timing When to Say the Instruction

    /// A distance along the associated ``RouteStep`` at which to read the instruction aloud.
    ///
    /// The distance is measured in meters from the beginning of the associated step.
    public let distanceAlongStep: LocationDistance

    // MARK: Getting the Instruction to Say

    /// A plain-text representation of the speech-optimized instruction.
    /// This representation is appropriate for speech synthesizers that lack support for the [Speech Synthesis Markup
    /// Language](https://en.wikipedia.org/wiki/Speech_Synthesis_Markup_Language) (SSML), such as `AVSpeechSynthesizer`.
    /// For speech synthesizers that support SSML, use the ``ssmlText`` property instead.
    public let text: String

    /// A formatted representation of the speech-optimized instruction.
    ///
    /// This representation is appropriate for speech synthesizers that support the [Speech Synthesis Markup
    /// Language](https://en.wikipedia.org/wiki/Speech_Synthesis_Markup_Language) (SSML), such as [Amazon
    /// Polly](https://aws.amazon.com/polly/). Numbers and names are marked up to ensure correct pronunciation. For
    /// speech synthesizers that lack SSML support, use the ``text`` property instead.
    public let ssmlText: String
}

extension SpokenInstruction {
    public static func == (lhs: SpokenInstruction, rhs: SpokenInstruction) -> Bool {
        return lhs.distanceAlongStep == rhs.distanceAlongStep &&
            lhs.text == rhs.text &&
            lhs.ssmlText == rhs.ssmlText
    }
}
