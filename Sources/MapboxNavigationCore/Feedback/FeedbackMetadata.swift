import CoreLocation
import Foundation
import MapboxNavigationNative
import MapboxNavigationNative_Private

public struct FeedbackMetadata: Sendable, Equatable {
    public static func == (lhs: FeedbackMetadata, rhs: FeedbackMetadata) -> Bool {
        let handlesAreEqual: Bool = switch (lhs.userFeedbackHandle, rhs.userFeedbackHandle) {
        case (let lhsHandle as UserFeedbackHandle, let rhsHandle as UserFeedbackHandle):
            lhsHandle == rhsHandle
        default:
            true
        }
        return handlesAreEqual &&
            lhs.calculatedUserFeedbackMetadata == rhs.calculatedUserFeedbackMetadata &&
            lhs.screenshot == rhs.screenshot
    }

    private let userFeedbackHandle: (any NativeUserFeedbackHandle)?
    private let calculatedUserFeedbackMetadata: UserFeedbackMetadata?

    var userFeedbackMetadata: UserFeedbackMetadata? {
        calculatedUserFeedbackMetadata ?? userFeedbackHandle?.getMetadata()
    }

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
        userFeedbackHandle: (any NativeUserFeedbackHandle)?,
        screenshot: String?,
        userFeedbackMetadata: UserFeedbackMetadata? = nil
    ) {
        self.userFeedbackHandle = userFeedbackHandle
        self.screenshot = screenshot
        self.calculatedUserFeedbackMetadata = userFeedbackMetadata
    }
}

extension FeedbackMetadata: Codable {
    fileprivate enum CodingKeys: String, CodingKey {
        case screenshot
        case locationsBefore
        case locationsAfter
        case step
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.screenshot = try container.decodeIfPresent(String.self, forKey: .screenshot)
        self.calculatedUserFeedbackMetadata = try? UserFeedbackMetadata(from: decoder)
        self.userFeedbackHandle = nil
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

extension UserFeedbackHandle: NativeUserFeedbackHandle, @unchecked Sendable {}

extension UserFeedbackMetadata: @unchecked Sendable {}

extension UserFeedbackMetadata: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: FeedbackMetadata.CodingKeys.self)
        let eventLocationsAfter: [EventFixLocation] = locationsAfter.map { .init($0) }
        let eventLocationsBefore: [EventFixLocation] = locationsBefore.map { .init($0) }
        let eventStep = step.map { EventStep($0) }
        try container.encode(eventLocationsAfter, forKey: .locationsAfter)
        try container.encode(eventLocationsBefore, forKey: .locationsBefore)
        try container.encodeIfPresent(eventStep, forKey: .step)
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: FeedbackMetadata.CodingKeys.self)
        let locationsBefore = try container.decode([EventFixLocation].self, forKey: .locationsBefore)
        let locationsAfter = try container.decode([EventFixLocation].self, forKey: .locationsAfter)
        let eventStep = try container.decodeIfPresent(EventStep.self, forKey: .step)

        self.init(
            locationsBefore: locationsBefore.map { FixLocation($0) },
            locationsAfter: locationsAfter.map { FixLocation($0) },
            step: Step(eventStep)
        )
    }
}
