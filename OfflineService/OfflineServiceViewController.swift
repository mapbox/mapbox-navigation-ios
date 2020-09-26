import UIKit
import MapboxCommon
import MapboxCoreNavigation

struct OfflineDataItem {
    
    var dataRegionMetadata: OfflineDataRegionMetadata
    var mapPackMetadata: OfflineDataPackMetadata? = nil
    var navigationPackMetadata: OfflineDataPackMetadata? = nil
}

struct OfflineServiceConstants {
    
    static let title = NSLocalizedString("OFFLINE_SERVICE_TITLE", value: "Offline Service", comment: "Title for UIViewController and UIAlertController.")
    static let close = NSLocalizedString("CLOSE_TITLE", value: "Close", comment: "Close title.")
}

class OfflineServiceViewController: UITableViewController, OfflineServiceObserver {
    
    let cellIdentifier = NSStringFromClass(OfflineDataRegionTableViewCell.self)
    var offlineDataItems = [OfflineDataItem]()
    var offlineService: OfflineService?
    let tilesVersiom = "1.0"
    var username = "1tap-nav"
    var baseURL = "https://api.mapbox.com"
    var accessToken: String = {
        guard let accessToken = Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAccessToken") as? String else {
            assertionFailure("`accessToken` must be set in the Info.plist as `MGLMapboxAccessToken`.")
            return ""
        }

        return accessToken
    }()
    
    // MARK: - OfflineServiceObserver methods
    
    public func onPending(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        print("[OfflineServiceObserver] \(#function)")
    }
    
    public func onDownloading(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        print("[OfflineServiceObserver] \(#function)")
        
        for index in (0 ..< offlineDataItems.count) {
            if offlineDataItems[index].dataRegionMetadata.id != metadata.id { continue }
                        
            DispatchQueue.main.async {
                let indexPath = IndexPath(row: index, section: 0)
                let cell = self.tableView.cellForRow(at: indexPath) as? OfflineDataRegionTableViewCell
                
                cell?.showDownloadProgress(for: domain, dataPack: pack, metadata: metadata)
            }
        }
    }
    
    public func onIncomplete(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        print("[OfflineServiceObserver] \(#function)")
    }
    
    public func onVerifying(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        print("[OfflineServiceObserver] \(#function)")
    }
    
    public func onAvailable(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        print("[OfflineServiceObserver] \(#function)")

        updateOfflineDataRegions(for: domain, metadata: metadata)
    }
    
    public func onExpired(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        print("[OfflineServiceObserver] \(#function)")
    }
    
    public func onErrored(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        print("[OfflineServiceObserver] \(#function)")
    }
    
    public func onDeleting(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack, callback: @escaping OfflineDataPackAcknowledgeCallback) {
        print("[OfflineServiceObserver] \(#function)")
        
        presentAlert(OfflineServiceConstants.title, message: "Would you like to remove \(metadata.id)?", handler: { _ in
            callback()
        })
    }
    
    public func onDeleted(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata) {
        print("[OfflineServiceObserver] \(#function)")
        
        updateOfflineDataRegions(for: domain, metadata: metadata, delete: true)
    }
    
    public func onInitialized() {
        print("[OfflineServiceObserver] \(#function)")
    }
    
    public func onIdle() {
        print("[OfflineServiceObserver] \(#function)")
    }
    
    public func onLogMessage(forMessage message: String) {
        print("[OfflineServiceObserver] \(#function): \(message)")
        
        presentAlert(title, message: message)
    }
    
    public var peer: MBXPeerWrapper?
    
    // MARK: - UIViewController delegate methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        listAvailableRegions()
    }
    
    deinit {
        // FIXME: In some cases this call might cause crash.
        OfflineService.unregisterObserver(for: self)
    }

    // MARK: - Setting-up methods
    
    func setupUI() {
        tableView.register(UINib(nibName: "OfflineDataRegionTableViewCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)
        tableView.separatorInset = .zero
        tableView.allowsSelection = true
        
        title = NSLocalizedString(OfflineServiceConstants.title, value: "", comment: "")
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: OfflineServiceConstants.close, style: .done, target: self, action: #selector(dismissViewController))
    }
    
    // MARK: - Action handler methods
    
    @IBAction func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITableView delegate methods
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! OfflineDataRegionTableViewCell
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
    
    func listAvailableRegions() {
        let outputDirectoryURL = Bundle.mapboxCoreNavigation.suggestedTileURL(version: tilesVersiom)
        do {
            try FileManager.default.createDirectory(at: outputDirectoryURL!, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create tiles folder with error: \(error)")
        }

        guard let outputDirectory = outputDirectoryURL?.path else { return }

        offlineService = OfflineService.getInstanceForPath(outputDirectory, options: OfflineServiceOptions(username: username,
                                                                                                           accessToken: accessToken,
                                                                                                           baseURL: baseURL))

        offlineService?.listAvailableRegions(forCallback: { [weak self] (expected) in
            guard let self = self else { return }
            if let error = expected?.error as? OfflineDataError {
                DispatchQueue.main.async {
                    self.presentAlert(OfflineServiceConstants.title, message: error.message)
                }

                return
            }

            let offlineDataRegions = expected?.value as? Array<Any>
            offlineDataRegions?.forEach({
                if let metadata = $0 as? OfflineDataRegionMetadata {
                    self.offlineDataItems.append(OfflineDataItem(dataRegionMetadata: metadata,
                                                                     mapPackMetadata: nil,
                                                                     navigationPackMetadata: nil))
                }
            })

            OfflineService.registerObserver(for: self)

            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        })
    }
    
    func updateOfflineDataRegions(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, delete: Bool = false) {
        var indexPaths = [IndexPath]()
        for index in 0 ..< offlineDataItems.count {
            if offlineDataItems[index].dataRegionMetadata.id != metadata.id { continue }
            
            switch domain {
            case .maps:
                offlineDataItems[index].mapPackMetadata = delete ? nil : metadata.mapPack
            case .navigation:
                offlineDataItems[index].navigationPackMetadata = delete ? nil : metadata.navigationPack
            }
            
            indexPaths.append(IndexPath(row: index, section: 0))
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadRows(at: indexPaths, with: .automatic)
        }
    }
    
    private func presentActionsAlertController(_ offlineDataRegion: OfflineDataItem) {
        let alertController = UIAlertController(title: title, message: "Please select appropriate action.", preferredStyle: .alert)

        var mapsPackTitle = "Download Maps Pack"
        var mapsActionHandler: ActionHandler = { _ in
            self.offlineService?.downloadPack(for: .maps, metadata: offlineDataRegion.dataRegionMetadata)
        }
        
        if offlineDataRegion.mapPackMetadata != nil {
            mapsPackTitle = "Delete Maps Pack"
            mapsActionHandler = { _ in
                self.offlineService?.deletePack(for: .maps, metadata: offlineDataRegion.dataRegionMetadata)
            }
        }
        
        var navigationPackTitle = "Download Navigation Pack"
        var navigationActionHandler: ActionHandler = { _ in
            self.offlineService?.downloadPack(for: .navigation, metadata: offlineDataRegion.dataRegionMetadata)
        }
        
        if offlineDataRegion.navigationPackMetadata != nil {
            navigationPackTitle = "Delete Navigation Pack"
            navigationActionHandler = { _ in
                self.offlineService?.deletePack(for: .navigation, metadata: offlineDataRegion.dataRegionMetadata)
            }
        }
        
        typealias ActionHandler = (UIAlertAction) -> Void
        
        let actionPayloads: [(String, UIAlertAction.Style, ActionHandler?)] = [
            (mapsPackTitle, .default, mapsActionHandler),
            (navigationPackTitle, .default, navigationActionHandler),
            ("Cancel", .cancel, nil)
        ]
        
        actionPayloads
            .map({ payload in UIAlertAction(title: payload.0, style: payload.1, handler: payload.2) })
            .forEach(alertController.addAction(_:))

        present(alertController, animated: true, completion: nil)
    }
}
