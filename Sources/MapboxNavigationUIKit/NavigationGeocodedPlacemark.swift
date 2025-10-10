import CarPlay
import CoreLocation

/// A struct that represents the result of a geocoding request, containing information for display to the user and
/// locations for navigation.
public struct NavigationGeocodedPlacemark: Equatable, Codable {
    /// The placemark’s title.
    public var title: String

    /// The placemark’s subtitle, such as its formatted address.
    public var subtitle: String?

    /// The placemark’s geographic center.
    public var location: CLLocation?

    /// An array of locations that serve as hints for navigating to the placemark.
    ///
    /// For the placemark’s geographic center, use the ``location`` property.
    /// The routable locations may differ from the geographic center. For example, if a house’s driveway leads to a
    /// street other than the nearest street (by straight-line distance), then this property may contain the location
    /// where the driveway meets the street. A route to the placemark’s geographic center may be impassable, but a route
    /// to the routable location would end on the correct street with access to the house.
    public var routableLocations: [CLLocation]?

    enum CodingKeys: String, CodingKey {
        case title
        case subtitle
        case location
        case routableLocations
    }

    /// Creates a geocoded placemark with the given titles and locations.
    /// - Parameters:
    ///   - title: The title of the placemark.
    ///   - subtitle: A subtitle with additional information about the placemark, such as its formatted address.
    ///   - location: The location of the placemark.
    ///   - routableLocations: The locations to which the user should travel to arrive at the placemark.
    public init(title: String, subtitle: String?, location: CLLocation?, routableLocations: [CLLocation]?) {
        self.title = title
        self.location = location
        self.routableLocations = routableLocations
        self.subtitle = subtitle
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decode(String.self, forKey: .title)
        self.subtitle = try container.decode(String.self, forKey: .subtitle)
        if let locationHolder = try container.decodeIfPresent(CLLocationModel.self, forKey: .location) {
            self.location = CLLocation(locationHolder)
        }
        if let routableLocationsHolder = try container.decodeIfPresent(
            [CLLocationModel].self,
            forKey: .routableLocations
        ) {
            self.routableLocations = routableLocationsHolder.map { CLLocation($0) }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encodeIfPresent(location?.locationModel, forKey: .location)
        try container.encodeIfPresent(routableLocations?.map(CLLocationModel.init), forKey: .routableLocations)
    }

    public static func == (lhs: NavigationGeocodedPlacemark, rhs: NavigationGeocodedPlacemark) -> Bool {
        return lhs.title == rhs.title &&
            lhs.subtitle == rhs.subtitle
    }

    /// Method, which returns `CPListItem`, which can be later used in list of search results inside `CPListTemplate`.
    /// `CPListItem` shows destination's title and its subtitle.
    ///
    /// - Returns: A `CPListItem` instance.
    public func listItem() -> CPListItem {
        let item = CPListItem(
            text: title,
            detailText: subtitle,
            image: nil,
            accessoryImage: nil,
            accessoryType: .disclosureIndicator
        )

        item.userInfo = [CarPlaySearchController.CarPlayGeocodedPlacemarkKey: self]

        return item
    }
}

extension CLLocation {
    convenience init(_ model: CLLocationModel) {
        self.init(
            coordinate: CLLocationCoordinate2DMake(model.latitude, model.longitude),
            altitude: model.altitude,
            horizontalAccuracy: model.horizontalAccuracy,
            verticalAccuracy: model.verticalAccuracy,
            course: model.course,
            speed: model.speed,
            timestamp: model.timestamp
        )
    }

    var locationModel: CLLocationModel {
        CLLocationModel(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            speed: speed,
            course: course,
            timestamp: timestamp
        )
    }
}

struct CLLocationModel: Codable {
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let altitude: CLLocationDistance
    let horizontalAccuracy: CLLocationAccuracy
    let verticalAccuracy: CLLocationAccuracy
    let speed: CLLocationSpeed
    let course: CLLocationDirection
    let timestamp: Date
}

extension CLLocationModel {
    init(_ location: CLLocation) {
        self = location.locationModel
    }
}
