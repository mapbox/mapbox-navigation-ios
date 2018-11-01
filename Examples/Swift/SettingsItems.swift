import UIKit
import MapboxDirections
import MapboxCoreNavigation


extension SettingsViewController {
    
    func sections() -> [Section] {
        
        let offlineItem = Item(title: "Download arbitrary region", viewControllerType: OfflineViewController.self, payload: nil)
        let offlineSection = Section(title: "Offline Examples", items: [offlineItem])
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

