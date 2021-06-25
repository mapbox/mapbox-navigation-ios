import Foundation
import CarPlay

public struct RecentItem: Equatable, Codable {
    
    public var navigationGeocodedPlacemark: NavigationGeocodedPlacemark

    var timestamp: Date
    
    static let persistenceKey = "RecentItems"

    static var filePathUrl: URL {
        get {
            let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let url = URL(fileURLWithPath: documents)
            return url.appendingPathComponent(persistenceKey.appending(".data"))
        }
    }

    static public func loadDefaults() -> [RecentItem] {
        let data = try? Data(contentsOf: RecentItem.filePathUrl)
        let decoder = JSONDecoder()
        if let data = data, let recentItems = try? decoder.decode([RecentItem].self, from: data) {
            return recentItems.sorted(by: { $0.timestamp > $1.timestamp })
        }

        return [RecentItem]()
    }

    public init(_ navigationGeocodedPlacemark: NavigationGeocodedPlacemark) {
        self.navigationGeocodedPlacemark = navigationGeocodedPlacemark
        self.timestamp = Date()
    }

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

        guard let existingNavigationGeocodedPlacemark = existingNavigationGeocodedPlacemark else {
            insert(recentItem, at: 0)
            return
        }

        var updatedNavigationGeocodedPlacemark = existingNavigationGeocodedPlacemark
        updatedNavigationGeocodedPlacemark.timestamp = Date()
        remove(existingNavigationGeocodedPlacemark)
        add(updatedNavigationGeocodedPlacemark)
    }

    mutating func remove(_ recentItem: RecentItem) {
        if let index = firstIndex(of: recentItem) {
            remove(at: index)
        }
    }
}
