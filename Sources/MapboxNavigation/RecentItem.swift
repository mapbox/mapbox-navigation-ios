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
    
    static var recentItemsPathURL: URL? {
        get {
            guard let documentsDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
                return nil
            }
            
            return documentsDirectory.appendingPathComponent("RecentItems.data")
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
     Loads a list of `RecentItem`s, which is serialized into a file stored in `recentItemsPathURL`.
     */
    public static func loadDefaults() -> [RecentItem] {
        guard let recentItemsPathURL = RecentItem.recentItemsPathURL,
              FileManager.default.fileExists(atPath: recentItemsPathURL.path)
        else { return [] }

        do {
            let data = try Data(contentsOf: recentItemsPathURL)
            let recentItems = try JSONDecoder().decode([RecentItem].self, from: data)
            
            return recentItems.sorted(by: { $0.timestamp > $1.timestamp })
        } catch {
            NSLog("Failed to load recent items with error: \(error.localizedDescription)")
            return []
        }
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
     Saves an array of `RecentItem`s to a file at the path specified by `recentItemsPathURL`.
     */
    @discardableResult public func save() -> Bool {
        guard let recentItemsPathURL = RecentItem.recentItemsPathURL else { return false }
        
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: recentItemsPathURL)
        } catch {
            NSLog("Failed to save recent items with error: \(error.localizedDescription)")
            return false
        }
        
        return true
    }
    
    /**
     Adds a recent item to the collection. If a similar recent item is already in the collection, this method updates the `timestamp` of that item instead of adding a redundant item.
     
     - parameter recentItem: A recent item to add to the collection.
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
     Removes the first matching recent item from the collection.
     
     - parameter recentItem: A recent item to remove from the collection.
     */
    public mutating func remove(_ recentItem: RecentItem) {
        if let index = firstIndex(of: recentItem) {
            remove(at: index)
        }
    }
}
