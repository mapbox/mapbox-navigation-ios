import UIKit
import MapboxDirections
import MapboxCoreNavigation

typealias Payload = () -> ()

let MBSelectedOfflineVersion = "MBSelectedOfflineVersion"

protocol ItemProtocol {
    var title: String { get }
    var subtitle: String? { get }
    // View controller to present on SettingsViewController.tableView(_:didSelectRowAt:)
    var viewControllerType: UIViewController.Type? { get }
    // Closure to call on SettingsViewController.tableView(_:didSelectRowAt:)
    var payload: Payload? { get }
    // SettingsViewController.tableView(_:canEditRowAt:)
    var canEditRow: Bool { get }
}

struct Item: ItemProtocol {
    let title: String
    let subtitle: String?
    let viewControllerType: UIViewController.Type?
    let payload: Payload?
    var canEditRow: Bool
    
    init(title: String, subtitle: String? = nil, viewControllerType: UIViewController.Type? = nil, payload: Payload? = nil, canEditRow: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.viewControllerType = viewControllerType
        self.payload = payload
        self.canEditRow = canEditRow
    }
}

struct OfflineVersionItem: ItemProtocol {
    var title: String
    var subtitle: String?
    var viewControllerType: UIViewController.Type?
    var payload: Payload?
    var canEditRow: Bool
    
    init(title: String, subtitle: String? = nil, viewControllerType: UIViewController.Type? = nil, payload: Payload? = nil, canEditRow: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.viewControllerType = viewControllerType
        self.payload = payload
        self.canEditRow = canEditRow
    }
}

class OfflineSwitch: UISwitch {
    var payload: Payload?
    var item: OfflineVersionItem?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct Section {
    let title: String
    let items: [ItemProtocol]
}

extension SettingsViewController {
    
    func sections() -> [Section] {
        
        let offlineItem = Item(title: NSLocalizedString("SETTINGS_ITEM_DOWNLOAD_REGION_TITLE", value: "Download Region", comment: "Title of table view item that downloads a new offline region"), viewControllerType: OfflineViewController.self, payload: nil)
        let offlineSection = Section(title: NSLocalizedString("SETTINGS_SECTION_OFFLINE_EXAMPLES", value: "Offline Examples", comment: "Section of offline settings table view"), items: [offlineItem])
        let versionSection = Section(title: NSLocalizedString("SETTINGS_SECTION_DOWNLOADED_VERSIONS", value: "Downloaded Versions", comment: "Section of offline settings table view"), items: versionDirectories())
        
        return [offlineSection, versionSection]
    }
    
    func versionDirectories() -> [ItemProtocol] {
        
        var versions = [OfflineVersionItem]()
        
        let directories = try? FileManager.default.contentsOfDirectory(atPath: Bundle.mapboxCoreNavigation.suggestedTileURL!.path)
        
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = .useMB
        byteCountFormatter.countStyle = .file
        
        let filteredDirectories = directories?.filter { $0 != ".DS_Store" }
        
        filteredDirectories?.forEach {
            var subtitle: String? = nil
            let path = Bundle.mapboxCoreNavigation.suggestedTileURL!.appendingPathComponent($0)
            if let directorySize = path.directorySize {
                subtitle = byteCountFormatter.string(fromByteCount: Int64(directorySize))
            }
            versions.append(OfflineVersionItem(title: $0, subtitle: subtitle, canEditRow: true))
        }
        
        return versions
    }
}

extension URL {
    var directorySize: Int? {
        guard ((try? resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != nil) else { return nil }
        var directorySize = 0
        
        (FileManager.default.enumerator(at: self, includingPropertiesForKeys: nil)?.allObjects as? [URL])?.lazy.forEach {
            directorySize += (try? $0.resourceValues(forKeys: [.totalFileAllocatedSizeKey]))?.totalFileAllocatedSize ?? 0
        }
        
        return directorySize
    }
}
