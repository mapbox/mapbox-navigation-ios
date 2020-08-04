import UIKit
import MapboxDirections
import MapboxCoreNavigation

typealias Payload = () -> ()

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

struct Section {
    let title: String
    let items: [ItemProtocol]
}

extension SettingsViewController {
    // The property is used to decide whether to show the settings button or not
    static let numberOfSections = 0

    func sections() -> [Section] {
        return []
    }
}

extension URL {
    var directorySize: Int? {
        guard (try? resourceValues(forKeys: [.isDirectoryKey]).isDirectory) as Bool?? != nil else { return nil }
        var directorySize = 0
        
        (FileManager.default.enumerator(at: self, includingPropertiesForKeys: nil)?.allObjects as? [URL])?.lazy.forEach {
            directorySize += (try? $0.resourceValues(forKeys: [.totalFileAllocatedSizeKey]))?.totalFileAllocatedSize ?? 0
        }
        
        return directorySize
    }
}
