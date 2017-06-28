import UIKit

@objc(MBTableViewItem)
public class TableViewItem: NSObject {
    public typealias ActionHandler = () -> ()
    public typealias ToggledHandler = (UISwitch) -> ()
    public typealias ToggledStateHandler = (UISwitch) -> (Bool)
    
    public var title: String
    public var image: UIImage?
    public var didSelectHandler: ActionHandler?
    public var didToggleHandler: ToggledHandler?
    public var toggledStateHandler: ToggledStateHandler?
    public var isSeparator: Bool = false
    public var isToggleable: Bool { return toggledStateHandler != nil }
    
    public static var separator: TableViewItem {
        let item = TableViewItem("")
        item.isSeparator = true
        return item
    }
    
    public init(_ title: String) {
        self.title = title
    }
}

public typealias TableViewSection = [TableViewItem]

class StaticTableViewController: UITableViewController {
    var sections = [TableViewSection]() {
        didSet {
            tableView.reloadData()
        }
    }
    
    let cellReuseIdentifier = "StaticTableViewCellId"
    let toggleCellReuseIdentifier = "StaticToggleTableViewCellId"
    let separatorReuseIdentifier = "StaticSeparatorTableViewCellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 50
        tableView.tableFooterView = UIView()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section][indexPath.row]
        
        if item.isSeparator {
            return separatorCell(forRowAt: indexPath)
        } else if item.isToggleable {
            return toggleCell(forRowAt: indexPath)
        } else {
            return tableViewCell(forRowAt: indexPath)
        }
    }
    
    func tableViewCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath) as! StaticTableViewCell
        let item = sections[indexPath.section][indexPath.row]
        configureTableViewCell(cell, for: item)
        return cell
    }
    
    func configureTableViewCell(_ cell: StaticTableViewCell, for item: TableViewItem) {
        cell.titleLabel.text = item.title
        cell.iconImageView.image = item.image
        cell.iconImageView.sizeToFit()
    }
    
    func separatorCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: separatorReuseIdentifier, for: indexPath) as! SeparatorTableViewCell
        return cell
    }
    
    func toggleCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: toggleCellReuseIdentifier, for: indexPath) as! StaticToggleTableViewCell
        let item = sections[indexPath.section][indexPath.row]
        
        configureTableViewCell(cell, for: item)
        
        cell.toggleView.removeTarget(self, action: #selector(didToggle(_:)), for: .valueChanged)
        cell.toggleView.addTarget(self, action: #selector(didToggle(_:)), for: .valueChanged)
        
        if let handler = item.toggledStateHandler {
            cell.toggleView.isOn = handler(cell.toggleView)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = sections[indexPath.section][indexPath.row]
        item.didSelectHandler?()
    }
    
    func didToggle(_ sender: UISwitch) {
        guard let cell = sender.superview?.superview as? StaticToggleTableViewCell else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let toggleView = cell.toggleView else { return }
        
        let item = sections[indexPath.section][indexPath.row]
        item.didToggleHandler?(toggleView)
    }
}
