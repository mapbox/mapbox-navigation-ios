import Foundation
import MapboxGeocoder
#if canImport(CarPlay)
import CarPlay
#endif

struct RecentItem: Codable, Equatable {
    
    static func ==(lhs: RecentItem, rhs: RecentItem) -> Bool {
        return lhs.timestamp == rhs.timestamp && lhs.geocodedPlacemark == rhs.geocodedPlacemark
    }
    
    @available(iOS 12.0, *)
    func listItem() -> CPListItem {
        return CPListItem(text: geocodedPlacemark.formattedName, detailText: geocodedPlacemark.address, image: nil, showsDisclosureIndicator: true)
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
        if let data = data,
            let recentItems = try? decoder.decode([RecentItem].self, from: data) {
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
        try? data?.write(to: RecentItem.filePathUrl)
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
        if let index = index(of: recentItem) {
            remove(at: index)
        }
    }
    
    func contains(_ geocodedPlacemark: GeocodedPlacemark) -> Bool {
        let exists = filter { (recentItem) -> Bool in
            return recentItem.geocodedPlacemark == geocodedPlacemark
            }.first
        return (exists != nil)
    }
}
