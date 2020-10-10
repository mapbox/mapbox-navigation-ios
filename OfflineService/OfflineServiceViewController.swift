import UIKit
import MapboxCommon
import MapboxCoreNavigation
import MapboxDirections
import Mapbox

class OfflineServiceViewController: UITableViewController, OfflineServiceDataSourceDelegate {

    var offlineDataItems = [OfflineDataItem]()
    var offlineServiceDataSource: OfflineServiceDataSource? = nil
    
    // MARK: - UIViewController delegate methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        offlineServiceDataSource = OfflineServiceDataSource()
        offlineServiceDataSource?.delegate = self
        offlineServiceDataSource?.startObservingAvailableRegions()
    }

    // MARK: - Setting-up methods
    
    func setupUI() {
        tableView.register(UINib(nibName: OfflineDataRegionTableViewCell.identifier, bundle: nil),
                           forCellReuseIdentifier: OfflineDataRegionTableViewCell.identifier)
        
        tableView.separatorInset = .zero
        tableView.allowsSelection = true
        
        title = OfflineServiceConstants.title
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: OfflineServiceConstants.close,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissViewController))
    }
    
    // MARK: - Action handler methods
    
    @IBAction func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - OfflineServiceDataSourceDelegate methods
    
    func offlineServiceDataSource(_ dataSource: OfflineServiceDataSource, didUpdate offlineDataItems: [OfflineDataItem]) {
        DispatchQueue.main.async {
            offlineDataItems.forEach {
                var indexPaths = [IndexPath]()
                var found = false
                let metadata = $0.dataRegionMetadata
                
                // In case if OfflineDataItem was found in list - update existing item with available pack for either map or navigation.
                for index in 0 ..< self.offlineDataItems.count {
                    if self.offlineDataItems[index].dataRegionMetadata.id != metadata.id { continue }
                    found = true
                    
                    guard let domain = $0.domain else { continue }
                    
                    if let pack = $0.offlineDataPack {
                        let indexPath = IndexPath(row: index, section: 0)
                        let cell = self.tableView.cellForRow(at: indexPath) as? OfflineDataRegionTableViewCell
                        cell?.showDownloadProgress(for: domain, dataPack: pack, metadata: metadata)
                        
                        continue
                    }
                    
                    switch domain {
                    case .maps:
                        self.offlineDataItems[index].mapPackMetadata = $0.mapPackMetadata
                    case .navigation:
                        self.offlineDataItems[index].navigationPackMetadata = $0.navigationPackMetadata
                    }
                    
                    indexPaths.append(IndexPath(row: index, section: 0))
                }
                
                // In case if OfflineDataItem wasn't found (e.g. in case if there is no internet connection) - add it to list and refresh UITableView.
                if !found {
                    self.offlineDataItems.append($0)
                    
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: [IndexPath(row: self.offlineDataItems.count - 1, section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                    
                    return
                }
                
                self.tableView.reloadRows(at: indexPaths, with: .automatic)
            }
        }
    }
    
    func offlineServiceDataSource(_ dataSource: OfflineServiceDataSource, didFail error: OfflineServiceError) {
        switch error {
        case .genericError(message: let message):
            self.presentAlert(OfflineServiceConstants.title, message: message)
        }
    }

    // MARK: - UITableView delegate methods
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OfflineDataRegionTableViewCell.identifier, for: indexPath) as! OfflineDataRegionTableViewCell
        cell.presentUI(for: offlineDataItems[indexPath.row])

        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return offlineDataItems.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let offlineDataRegion = offlineDataItems[indexPath.row]
        presentActionsAlertController(offlineDataRegion)
    }
    
    // MARK: - Private methods

    private func presentActionsAlertController(_ offlineDataRegion: OfflineDataItem) {
        let alertController = UIAlertController(title: OfflineServiceConstants.title,
                                                message: "Please select appropriate action.",
                                                preferredStyle: .alert)

        var mapsPackTitle = "Download Maps Pack"
        var mapsActionHandler: ActionHandler = { _ in
            OfflineServiceManager.instance.downloadPack(.maps, metadata: offlineDataRegion.dataRegionMetadata)
        }
        
        if offlineDataRegion.mapPackMetadata != nil {
            mapsPackTitle = "Delete Maps Pack"
            mapsActionHandler = { _ in
                OfflineServiceManager.instance.deletePack(.maps, metadata: offlineDataRegion.dataRegionMetadata)
            }
        }
        
        var navigationPackTitle = "Download Navigation Pack"
        var navigationActionHandler: ActionHandler = { _ in
            OfflineServiceManager.instance.downloadPack(.navigation, metadata: offlineDataRegion.dataRegionMetadata)
        }
        
        if offlineDataRegion.navigationPackMetadata != nil {
            navigationPackTitle = "Delete Navigation Pack"
            navigationActionHandler = { _ in
                OfflineServiceManager.instance.deletePack(.navigation, metadata: offlineDataRegion.dataRegionMetadata)
            }
        }
        
        typealias ActionHandler = (UIAlertAction) -> Void
        
        let actionPayloads: [(String, UIAlertAction.Style, ActionHandler?)] = [
            (mapsPackTitle, .default, mapsActionHandler),
            (navigationPackTitle, .default, navigationActionHandler),
            (OfflineServiceConstants.cancel, .cancel, nil)
        ]
        
        actionPayloads
            .map({ payload in UIAlertAction(title: payload.0, style: payload.1, handler: payload.2) })
            .forEach(alertController.addAction(_:))

        present(alertController, animated: true, completion: nil)
    }
}
