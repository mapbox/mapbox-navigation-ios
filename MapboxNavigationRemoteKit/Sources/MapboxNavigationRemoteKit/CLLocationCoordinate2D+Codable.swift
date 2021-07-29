import CoreLocation

extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .lat)
        try container.encode(longitude, forKey: .lon)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            latitude: try container.decode(CLLocationDegrees.self, forKey: .lat),
            longitude: try container.decode(CLLocationDegrees.self, forKey: .lon)
        )
    }

    private enum CodingKeys: String, CodingKey {
        case lat
        case lon
    }
}
