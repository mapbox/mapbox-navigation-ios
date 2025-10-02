import CoreLocation
import Foundation
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
    private enum CodingKeys: String, CodingKey {
        case screenshot
        case userFeedbackMetadata
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.screenshot = try container.decodeIfPresent(String.self, forKey: .screenshot)

        if let userFeedbackMetadataModel = try? container.decodeIfPresent(
            UserFeedbackMetadataModel.self,
            forKey: .screenshot
        ) {
            self.userFeedbackMetadata = UserFeedbackMetadata(userFeedbackMetadataModel)
        } else {
            self.userFeedbackMetadata = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(screenshot, forKey: .screenshot)
        try container.encodeIfPresent(userFeedbackMetadata?.model, forKey: .userFeedbackMetadata)
    }
}

protocol NativeUserFeedbackHandle: Sendable {
    func getMetadata() -> UserFeedbackMetadata
}

extension UserFeedbackMetadata: @unchecked Sendable {}

struct UserFeedbackMetadataModel {
    var feedbackId: String
    var locationsBefore: [FixLocation]
    var locationsAfter: [FixLocation]
    var step: Step?
}

extension UserFeedbackMetadataModel: Codable {
    private enum CodingKeys: String, CodingKey {
        case locationsBefore
        case locationsAfter
        case step
        case feedbackId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let eventStep = step.map { EventStep($0) }
        try container.encode(feedbackId, forKey: .feedbackId)
        try container.encode(locationsAfter.map(EventFixLocation.init), forKey: .locationsAfter)
        try container.encode(locationsBefore.map(EventFixLocation.init), forKey: .locationsBefore)
        try container.encodeIfPresent(eventStep, forKey: .step)
    }
}

extension UserFeedbackMetadata {
    convenience init(_ model: UserFeedbackMetadataModel) {
        self.init(
            feedbackId: model.feedbackId,
            locationsBefore: model.locationsBefore,
            locationsAfter: model.locationsAfter,
            step: model.step
        )
    }

    var model: UserFeedbackMetadataModel {
        UserFeedbackMetadataModel(
            feedbackId: feedbackId,
            locationsBefore: locationsBefore,
            locationsAfter: locationsAfter,
            step: step
        )
    }
}
