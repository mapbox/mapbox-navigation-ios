import CarPlay
import MapboxGeocoder
import MapboxDirections

public struct NavigationGeocodedPlacemark: Equatable, Codable {
    
    public var title: String
    public var address: String?
    public var location: CLLocation?
    public var routableLocations: [CLLocation]?
    
    enum CodingKeys: String, CodingKey {
        case title
        case address = "subtitle"
        case location
        case routableLocations
    }
    
    public init (from geocodedPlacemark: GeocodedPlacemark, subtitle: String?) {
        title = geocodedPlacemark.formattedName
        address = subtitle
        location = geocodedPlacemark.location
        routableLocations = geocodedPlacemark.routableLocations
    }
    
    public init (from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        title = try container.decode(String.self, forKey: .title)
        address = try container.decode(String.self, forKey: .address)
        if let locationHolder = try container.decodeIfPresent(CLLocationModel.self, forKey: .location) {
            location = CLLocation(model: locationHolder)
        }
        if let routableLocationsHolder = try container.decodeIfPresent([CLLocationModel].self, forKey: .routableLocations) {
            routableLocations = routableLocationsHolder.map { CLLocation(model: $0) }
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(routableLocations, forKey: .routableLocations)
    }
    
    public static func == (lhs: NavigationGeocodedPlacemark, rhs: NavigationGeocodedPlacemark) -> Bool {
        return lhs.title == rhs.title &&
            lhs.address == rhs.address
    }
    
    @available(iOS 12.0, *)
    public func listItem() -> CPListItem {
        let item = CPListItem(text: title, detailText: address, image: nil, showsDisclosureIndicator: true)
        item.userInfo = [CarPlaySearchController.CarPlayGeocodedPlacemarkKey: self]
        return item
    }
}

extension CLLocation: Encodable {
    
    public enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case altitude
        case horizontalAccuracy
        case verticalAccuracy
        case speed
        case course
        case timestamp
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(altitude, forKey: .altitude)
        try container.encode(horizontalAccuracy, forKey: .horizontalAccuracy)
        try container.encode(verticalAccuracy, forKey: .verticalAccuracy)
        try container.encode(speed, forKey: .speed)
        try container.encode(course, forKey: .course)
        try container.encode(timestamp, forKey: .timestamp)
    }
    
    convenience init(latitude: CLLocationDegrees,
                     longitude: CLLocationDegrees,
                     altitude: CLLocationDistance,
                     horizontalAccuracy: CLLocationAccuracy,
                     verticalAccuracy: CLLocationAccuracy,
                     course: CLLocationDirection,
                     speed: CLLocationSpeed,
                     timestamp: Date) {
        self.init(coordinate: CLLocationCoordinate2DMake(latitude, longitude),
                  altitude: altitude,
                  horizontalAccuracy: horizontalAccuracy,
                  verticalAccuracy: verticalAccuracy,
                  course: course,
                  speed: speed,
                  timestamp: timestamp)
    }
    
    convenience init(model: CLLocationModel) {
        self.init(coordinate: CLLocationCoordinate2DMake(model.latitude, model.longitude),
                  altitude: model.altitude,
                  horizontalAccuracy: model.horizontalAccuracy,
                  verticalAccuracy: model.verticalAccuracy,
                  course: model.course,
                  speed: model.speed,
                  timestamp: model.timestamp)
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

/**
 `CarPlaySearchController` is the main object responsible for managing the search feature on CarPlay.
 
 Messages declared in the `CPApplicationDelegate` protocol should be sent to this object in the containing application's application delegate. Implement `CarPlaySearchControllerDelegate` in the containing application and assign an instance to the `delegate` property of your `CarPlaySearchController` instance.
 
 - note: It is very important you have a single `CarPlaySearchController` instance at any given time. 
 */
@available(iOS 12.0, *)
public class CarPlaySearchController: NSObject {
    /**
     The completion handler that will process the list of search results initiated on CarPlay.
     */
    var searchCompletionHandler: (([CPListItem]) -> Void)?
    
    /**
     The `CarPlaySearchController` delegate.
     */
    public weak var delegate: CarPlaySearchControllerDelegate?
}
