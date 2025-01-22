import CoreLocation
import Foundation
import MapboxNavigationNative
import MapboxNavigationNative_Private

public struct FeedbackMetadata: Sendable, Equatable {
    public static func == (lhs: FeedbackMetadata, rhs: FeedbackMetadata) -> Bool {
        lhs.userFeedbackMetadata == rhs.userFeedbackMetadata &&
            lhs.screenshot == rhs.screenshot
    }

    let userFeedbackMetadata: UserFeedbackMetadata?

    public let screenshot: String?
    public var contents: [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dictionary = try? JSONSerialization.jsonObject(
                  with: data, options: .allowFragments
              ) as? [String: Any]
        else {
            Log.warning("Unable to encode feedback event details", category: .navigation)
            return [:]
        }
        return dictionary
    }

    init(
        userFeedbackMetadata: UserFeedbackMetadata,
        screenshot: String?
    ) {
        self.userFeedbackMetadata = userFeedbackMetadata
        self.screenshot = screenshot
    }
}

extension FeedbackMetadata: Codable {
    fileprivate enum CodingKeys: String, CodingKey {
        case screenshot
        case locationsBefore
        case locationsAfter
        case step
        case feedbackId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.screenshot = try container.decodeIfPresent(String.self, forKey: .screenshot)
        self.userFeedbackMetadata = try? UserFeedbackMetadata(from: decoder)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(screenshot, forKey: .screenshot)
        try userFeedbackMetadata?.encode(to: encoder)
    }
}

protocol NativeUserFeedbackHandle: Sendable {
    func getMetadata() -> UserFeedbackMetadata
}

extension UserFeedbackMetadata: @unchecked Sendable {}

extension UserFeedbackMetadata: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: FeedbackMetadata.CodingKeys.self)
        let eventLocationsAfter: [EventFixLocation] = locationsAfter.map { .init($0) }
        let eventLocationsBefore: [EventFixLocation] = locationsBefore.map { .init($0) }
        let eventStep = step.map { EventStep($0) }
        try container.encode(feedbackId, forKey: .feedbackId)
        try container.encode(eventLocationsAfter, forKey: .locationsAfter)
        try container.encode(eventLocationsBefore, forKey: .locationsBefore)
        try container.encodeIfPresent(eventStep, forKey: .step)
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: FeedbackMetadata.CodingKeys.self)
        let feedbackId = try container.decode(String.self, forKey: .feedbackId)
        let locationsBefore = try container.decode([EventFixLocation].self, forKey: .locationsBefore)
        let locationsAfter = try container.decode([EventFixLocation].self, forKey: .locationsAfter)
        let eventStep = try container.decodeIfPresent(EventStep.self, forKey: .step)

        self.init(
            feedbackId: feedbackId,
            locationsBefore: locationsBefore.map { FixLocation($0) },
            locationsAfter: locationsAfter.map { FixLocation($0) },
            step: Step(eventStep)
        )
    }
}
