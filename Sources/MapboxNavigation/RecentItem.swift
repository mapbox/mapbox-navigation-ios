import Foundation
import CarPlay

/**
 Struct, which represents recently found search item on CarPlay. When storing recent items in an array
 use dedicated methods for addition: `[RecentItem].add(_:)`, and removal: `[RecentItem].remove(_:)`.
 */
public struct RecentItem: Equatable, Codable {
    
    /**
     Property, which contains information regarding geocoder result.
     */
    public private(set) var navigationGeocodedPlacemark: NavigationGeocodedPlacemark

    var timestamp: Date
    
    static var recentItemsPathUrl: URL? {
        get {
            guard let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
                return nil
            }
            
            let url = URL(fileURLWithPath: documentsDirectory)
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
     Loads a list of `RecentItem`s, which is serialized into a file stored in `recentItemsPathUrl`.
     */
    public static func loadDefaults() -> [RecentItem] {
        guard let recentItemsPathUrl = RecentItem.recentItemsPathUrl else { return [] }
        
        if let data = try? Data(contentsOf: recentItemsPathUrl),
           let recentItems = try? JSONDecoder().decode([RecentItem].self, from: data) {
            return recentItems.sorted(by: { $0.timestamp > $1.timestamp })
        }

        return []
    }

    /**
     Method, which allows to verify, whether current `RecentItem` instance contains data, which is
     similar to data provided in `searchText` parameter.
     
     - parameter searchText: Text, which will be used for performing search.
     */
    public func matches(_ searchText: String) -> Bool {
        return navigationGeocodedPlacemark.title.contains(searchText) ||
            navigationGeocodedPlacemark.subtitle?.contains(searchText) ?? false
    }
    
    public static func ==(lhs: RecentItem, rhs: RecentItem) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
            lhs.navigationGeocodedPlacemark == rhs.navigationGeocodedPlacemark
    }
}

extension Array where Element == RecentItem {
    
    /**
     Method, which allows to save an array of `RecentItem`s into file stored in `recentItemsPathUrl`.
     */
    @discardableResult public func save() -> Bool {
        guard let recentItemsPathUrl = RecentItem.recentItemsPathUrl else { return false }
        
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: recentItemsPathUrl)
        } catch {
            NSLog("Failed to save recent items with error: \(error.localizedDescription)")
            return false
        }
        
        return true
    }
    
    /**
     Method, which adds `RecentItem` to the collection. In case if similar `RecentItem` already exists
     in collection, `timestamp` of its first occurrence will be updated.
     
     - parameter recentItem: `RecentItem` instance, which will be added to the collection.
     */
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
    
    /**
     Method, which removes from the collection first occurrence of a `RecentItem`.
     
     - parameter recentItem: `RecentItem` instance, which will be removed from the collection.
     */
    public mutating func remove(_ recentItem: RecentItem) {
        if let index = firstIndex(of: recentItem) {
            remove(at: index)
        }
    }
}
