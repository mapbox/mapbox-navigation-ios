import Foundation

enum SpeedLimitDescriptor: Equatable {
    enum UnitDescriptor: String, Codable {
        case milesPerHour = "mph"
        case kilometersPerHour = "km/h"

        init?(unit: UnitSpeed) {
            switch unit {
            case .milesPerHour:
                self = .milesPerHour
            case .kilometersPerHour:
                self = .kilometersPerHour
            default:
                return nil
            }
        }

        var describedUnit: UnitSpeed {
            switch self {
            case .milesPerHour:
                return .milesPerHour
            case .kilometersPerHour:
                return .kilometersPerHour
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case none
        case speed
        case unknown
        case unit
    }

    case none
    case some(speed: Measurement<UnitSpeed>)
    case unknown

    init(speed: Measurement<UnitSpeed>?) {
        guard let speed else {
            self = .unknown
            return
        }

        if speed.value.isInfinite {
            self = .none
        } else {
            self = .some(speed: speed)
        }
    }
}

extension SpeedLimitDescriptor: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if try (container.decodeIfPresent(Bool.self, forKey: .none)) ?? false {
            self = .none
        } else if try (container.decodeIfPresent(Bool.self, forKey: .unknown)) ?? false {
            self = .unknown
        } else {
            let unitDescriptor = try container.decode(UnitDescriptor.self, forKey: .unit)
            let unit = unitDescriptor.describedUnit
            let value = try container.decode(Double.self, forKey: .speed)
            self = .some(speed: .init(value: value, unit: unit))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .none:
            try container.encode(true, forKey: .none)
        case .some(var speed):
            let unitDescriptor = UnitDescriptor(unit: speed.unit) ?? {
                speed = speed.converted(to: .kilometersPerHour)
                return .kilometersPerHour
            }()
            try container.encode(unitDescriptor, forKey: .unit)
            try container.encode(speed.value, forKey: .speed)
        case .unknown:
            try container.encode(true, forKey: .unknown)
        }
    }
}

extension Measurement where UnitType == UnitSpeed {
    init?(speedLimitDescriptor: SpeedLimitDescriptor) {
        switch speedLimitDescriptor {
        case .none:
            self = .init(value: .infinity, unit: .kilometersPerHour)
        case .some(let speed):
            self = speed
        case .unknown:
            return nil
        }
    }
}
