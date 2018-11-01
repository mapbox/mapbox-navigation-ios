import UIKit
import MapboxDirections


extension SettingsViewController {
    
    func sections() -> [Section] {
        
        let offlineItem = Item(title: "Download arbitrary region", viewControllerType: OfflineViewController.self, payload: nil)
        let downloadSFItem = Item(title: "Download SF region", viewControllerType: nil, payload: {
            
            Directions.shared.availableOfflineVersions(completionHandler: { (versions, error) in
                guard let version = versions?.first else { return }
                let sfBoundingBox = BoundingBox([CLLocationCoordinate2D(latitude: 37.7890, longitude: -122.4337),
                                                 CLLocationCoordinate2D(latitude: 37.7881, longitude: -122.4318)])
                
                Directions.shared.downloadTiles(for: sfBoundingBox, version: version, completionHandler: { (url, response, error) in
                    guard let url = url else { return }
                    print("Downloaded \(url)")
                }).resume()
            }).resume()
        })
        
        let offlineSection = Section(title: "Offline Examples", items: [offlineItem, downloadSFItem])
        let versionSection = Section(title: "Downloaded versions", items: versionDirectories())
        
        return [offlineSection, versionSection]
    }
    
    func versionDirectories() -> [Item] {
        
        var versions = [Item]()
        
        let directories = try? FileManager.default.contentsOfDirectory(atPath: Bundle.mapboxCoreNavigation.suggestedTilePath!.path)
        
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = .useMB
        byteCountFormatter.countStyle = .file
        
        let filteredDirectories = directories?.filter { $0 != ".DS_Store" }
        
        filteredDirectories?.forEach {
            var subtitle: String? = nil
            let path = Bundle.mapboxCoreNavigation.suggestedTilePath!.appendingPathComponent($0)
            if let sizeOfDirectory = sizeOfDirectory(at: path) {
                subtitle = byteCountFormatter.string(fromByteCount: Int64(sizeOfDirectory))
            }
            versions.append(Item(title: $0, subtitle: subtitle, canEditRow: true))
        }
        
        return versions
    }
    
    func sizeOfDirectory(at path: URL) -> Int? {
        guard ((try? path.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != nil) else { return nil }
        var directorySize = 0
        
        (FileManager.default.enumerator(at: path, includingPropertiesForKeys: nil)?.allObjects as? [URL])?.lazy.forEach {
            directorySize += (try? $0.resourceValues(forKeys: [.totalFileAllocatedSizeKey]))?.totalFileAllocatedSize ?? 0
        }
        
        return directorySize
    }
}

