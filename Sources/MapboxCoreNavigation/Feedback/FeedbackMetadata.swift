import Foundation
import CoreLocation
import MapboxNavigationNative
@_implementationOnly import MapboxNavigationNative_Private

/// :nodoc:
@_spi(MapboxInternal)
public struct FeedbackMetadata {
    private let userFeedbackHandle: NativeUserFeedbackHandle?
    private var calculatedUserFeedbackMetadata: UserFeedbackMetadata? = nil

    var userFeedbackMetadata: UserFeedbackMetadata? {
        calculatedUserFeedbackMetadata ?? userFeedbackHandle?.getMetadata()
    }

    public let screenshot: String?
    public var contents: [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
              let dictionary = try? JSONSerialization.jsonObject(
                with: data, options: .allowFragments) as? [String: Any] else {
            Log.warning("Unable to encode feedback event details", category: .navigation)
            return [:]
        }
        return dictionary
    }

    init(userFeedbackHandle: NativeUserFeedbackHandle?,
         screenshot: String?,
         userFeedbackMetadata: UserFeedbackMetadata? = nil) {
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
        screenshot = try container.decodeIfPresent(String.self, forKey: .screenshot)
        calculatedUserFeedbackMetadata = try? UserFeedbackMetadata(from: decoder)
        userFeedbackHandle = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(screenshot, forKey: .screenshot)
        try userFeedbackMetadata?.encode(to: encoder)
    }
}

/// :nodoc:
@_spi(MapboxInternal)
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

        self.init(locationsBefore: locationsBefore.map { FixLocation($0) },
                  locationsAfter: locationsAfter.map { FixLocation($0) },
                  step: Step(eventStep))
    }
}
