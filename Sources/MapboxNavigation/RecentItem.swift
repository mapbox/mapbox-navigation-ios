#if canImport(MapboxGeocoder)
import Foundation
import MapboxGeocoder
import CarPlay

struct RecentItem: Codable, Equatable {
    static func ==(lhs: RecentItem, rhs: RecentItem) -> Bool {
        return lhs.timestamp == rhs.timestamp && lhs.geocodedPlacemark == rhs.geocodedPlacemark
    }
    
    var timestamp: Date
    var geocodedPlacemark: GeocodedPlacemark
    
    static let persistenceKey = "RecentItems"
    
    static var filePathUrl: URL {
        get {
            let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let url = URL(fileURLWithPath: documents)
            return url.appendingPathComponent(persistenceKey.appending(".data"))
        }
    }
    
    static func loadDefaults() -> [RecentItem] {
        let data = try? Data(contentsOf: RecentItem.filePathUrl)
        let decoder = JSONDecoder()
        if let data = data, let recentItems = try? decoder.decode([RecentItem].self, from: data) {
            return recentItems.sorted(by: { $0.timestamp > $1.timestamp })
        }
        
        return [RecentItem]()
    }
    
    init(_ geocodedPlacemark: GeocodedPlacemark) {
        self.geocodedPlacemark = geocodedPlacemark
        self.timestamp = Date()
    }
    
    func matches(_ searchText: String) -> Bool {
        return geocodedPlacemark.formattedName.contains(searchText) || geocodedPlacemark.address?.contains(searchText) ?? false
    }
}

extension Array where Element == RecentItem {
    func save() {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(self)
        (try? data?.write(to: RecentItem.filePathUrl)) as ()??
    }
    
    mutating func add(_ recentItem: RecentItem) {
        let existing = lazy.filter { $0.geocodedPlacemark == recentItem.geocodedPlacemark }.first
        
        guard let alreadyExisting = existing else {
            insert(recentItem, at: 0)
            return
        }
        
        var updated = alreadyExisting
        updated.timestamp = Date()
        remove(alreadyExisting)
        add(updated)
    }
    
    mutating func remove(_ recentItem: RecentItem) {
        if let index = firstIndex(of: recentItem) {
            remove(at: index)
        }
    }
}
#endif
