import Foundation
import Turf

extension CodingUserInfoKey {
    static let drivingSide = CodingUserInfoKey(rawValue: "drivingSide")!
}

/// A visual instruction banner contains all the information necessary for creating a visual cue about a given
/// ``RouteStep``.
public struct VisualInstructionBanner: Codable, ForeignMemberContainer, Equatable, Sendable {
    public var foreignMembers: JSONObject = [:]

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case distanceAlongStep = "distanceAlongGeometry"
        case primaryInstruction = "primary"
        case secondaryInstruction = "secondary"
        case tertiaryInstruction = "sub"
        case quaternaryInstruction = "view"
        case drivingSide
    }

    // MARK: Creating a Visual Instruction Banner

    /// Initializes a visual instruction banner with the given instructions.
    public init(
        distanceAlongStep: LocationDistance,
        primary: VisualInstruction,
        secondary: VisualInstruction?,
        tertiary: VisualInstruction?,
        quaternary: VisualInstruction?,
        drivingSide: DrivingSide
    ) {
        self.distanceAlongStep = distanceAlongStep
        self.primaryInstruction = primary
        self.secondaryInstruction = secondary
        self.tertiaryInstruction = tertiary
        self.quaternaryInstruction = quaternary
        self.drivingSide = drivingSide
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(distanceAlongStep, forKey: .distanceAlongStep)
        try container.encode(primaryInstruction, forKey: .primaryInstruction)
        try container.encodeIfPresent(secondaryInstruction, forKey: .secondaryInstruction)
        try container.encodeIfPresent(tertiaryInstruction, forKey: .tertiaryInstruction)
        try container.encodeIfPresent(quaternaryInstruction, forKey: .quaternaryInstruction)
        try container.encode(drivingSide, forKey: .drivingSide)

        try encodeForeignMembers(notKeyedBy: CodingKeys.self, to: encoder)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.distanceAlongStep = try container.decode(LocationDistance.self, forKey: .distanceAlongStep)
        self.primaryInstruction = try container.decode(VisualInstruction.self, forKey: .primaryInstruction)
        self.secondaryInstruction = try container.decodeIfPresent(VisualInstruction.self, forKey: .secondaryInstruction)
        self.tertiaryInstruction = try container.decodeIfPresent(VisualInstruction.self, forKey: .tertiaryInstruction)
        self.quaternaryInstruction = try container.decodeIfPresent(
            VisualInstruction.self,
            forKey: .quaternaryInstruction
        )
        if let directlyEncoded = try container.decodeIfPresent(DrivingSide.self, forKey: .drivingSide) {
            self.drivingSide = directlyEncoded
        } else {
            self.drivingSide = .default
        }

        try decodeForeignMembers(notKeyedBy: CodingKeys.self, with: decoder)
    }

    // MARK: Timing When to Display the Banner

    /// The distance at which the visual instruction should be shown, measured in meters from the beginning of the step.
    public let distanceAlongStep: LocationDistance

    // MARK: Getting the Instructions to Display

    /// The most important information to convey to the user about the ``RouteStep``.
    public let primaryInstruction: VisualInstruction

    /// Less important details about the ``RouteStep``.
    public let secondaryInstruction: VisualInstruction?

    /// A visual instruction that is presented simultaneously to provide information about an additional maneuver that
    /// occurs in rapid succession.
    ///
    /// This instruction could either contain the visual layout information or the lane information about the upcoming
    /// maneuver.
    public let tertiaryInstruction: VisualInstruction?

    /// A visual instruction that is presented to provide information about the incoming junction.
    ///
    /// This instruction displays a zoomed image of incoming junction.
    public let quaternaryInstruction: VisualInstruction?

    // MARK: Respecting Regional Driving Rules

    /// Which side of a bidirectional road the driver should drive on, also known as the rule of the road.
    public var drivingSide: DrivingSide
}

extension VisualInstructionBanner {
    public static func == (lhs: VisualInstructionBanner, rhs: VisualInstructionBanner) -> Bool {
        return lhs.distanceAlongStep == rhs.distanceAlongStep &&
            lhs.primaryInstruction == rhs.primaryInstruction &&
            lhs.secondaryInstruction == rhs.secondaryInstruction &&
            lhs.tertiaryInstruction == rhs.tertiaryInstruction &&
            lhs.quaternaryInstruction == rhs.quaternaryInstruction &&
            lhs.drivingSide == rhs.drivingSide
    }
}
