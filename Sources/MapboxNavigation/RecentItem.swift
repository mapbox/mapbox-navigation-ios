import Foundation
import CarPlay

/**
 Struct, which represents recently found search item on CarPlay.
 */
public struct RecentItem: Equatable, Codable {
    
    /**
     Property, which contains information regarding geocoder result.
     */
    public var navigationGeocodedPlacemark: NavigationGeocodedPlacemark

    var timestamp: Date
    
    static var filePathUrl: URL {
        get {
            let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let url = URL(fileURLWithPath: documents)
            return url.appendingPathComponent("RecentItems.data")
        }
    }
    
    /**
     Initializes a newly created `RecentItem` instance, with a geocoded data stored in
     `NavigationGeocodedPlacemark`.
     
     - parameter navigationGeocodedPlacemark: A `NavigationGeocodedPlacemark` instance, which contains
     information regarding geocoder result.
     */
    public init(_ navigationGeocodedPlacemark: NavigationGeocodedPlacemark) {
        self.navigationGeocodedPlacemark = navigationGeocodedPlacemark
        self.timestamp = Date()
    }

    /**
     Loads a list of `RecentItem`s, which is serialized into a file stored in `filePathUrl`.
     */
    static public func loadDefaults() -> [RecentItem] {
        let data = try? Data(contentsOf: RecentItem.filePathUrl)
        let decoder = JSONDecoder()
        if let data = data,
           let recentItems = try? decoder.decode([RecentItem].self, from: data) {
            return recentItems.sorted(by: { $0.timestamp > $1.timestamp })
        }

        return [RecentItem]()
    }

    /**
     Method, which allows to verify, whether current `RecentItem` instance contains data, which is
     similar to data provided in `searchText` parameter.
     
     - parameter searchText: Text, which will be used for performing search.
     */
    public func matches(_ searchText: String) -> Bool {
        return navigationGeocodedPlacemark.title.contains(searchText) ||
            navigationGeocodedPlacemark.address?.contains(searchText) ?? false
    }
    
    public static func ==(lhs: RecentItem, rhs: RecentItem) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
            lhs.navigationGeocodedPlacemark == rhs.navigationGeocodedPlacemark
    }
}

extension Array where Element == RecentItem {
    
    public func save() {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(self)
        (try? data?.write(to: RecentItem.filePathUrl)) as ()??
    }

    public mutating func add(_ recentItem: RecentItem) {
        let existingNavigationGeocodedPlacemark = lazy.filter {
            $0.navigationGeocodedPlacemark == recentItem.navigationGeocodedPlacemark
        }.first

        guard let validNavigationGeocodedPlacemark = existingNavigationGeocodedPlacemark else {
            insert(recentItem, at: 0)
            return
        }

        var updatedNavigationGeocodedPlacemark = validNavigationGeocodedPlacemark
        updatedNavigationGeocodedPlacemark.timestamp = Date()
        remove(validNavigationGeocodedPlacemark)
        add(updatedNavigationGeocodedPlacemark)
    }

    mutating func remove(_ recentItem: RecentItem) {
        if let index = firstIndex(of: recentItem) {
            remove(at: index)
        }
    }
}
