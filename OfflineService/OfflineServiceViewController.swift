import UIKit
import MapboxCommon
import MapboxCoreNavigation
import MapboxDirections
import Mapbox

class OfflineServiceViewController: UITableViewController, OfflineServiceObserver {
    
    var offlineDataItems = [OfflineDataItem]()
    let tilesUnpackingLock = NSLock()
    
    // MARK: - OfflineServiceObserver methods
    
    public func onPending(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        print("[OfflineServiceObserver] \(#function), identifier: \(metadata.id)")
    }
    
    public func onDownloading(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        print("[OfflineServiceObserver] \(#function), identifier: \(metadata.id), progress: \(pack.bytes) bytes")
        
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
        print("[OfflineServiceObserver] \(#function), identifier: \(metadata.id)")
    }
    
    public func onVerifying(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        print("[OfflineServiceObserver] \(#function), identifier: \(metadata.id)")
    }
    
    public func onAvailable(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        print("[OfflineServiceObserver] \(#function), identifier: \(metadata.id)")

        updateOfflineDataRegions(for: domain, metadata: metadata)
        
        switch domain {
        case .maps:
            // Maps SDK will automatically pick up downloaded offline pack
            break
        case .navigation:
            tilesUnpackingLock.lock()
            
            do {
                guard let outputDirectoryURL = Bundle.mapboxCoreNavigation.suggestedTileURL?.appendingPathComponent("unpacked") else { return }
                guard let packName = URL(string: pack.path)?.lastPathComponent else { return }
                guard let packData = FileManager.default.contents(atPath: pack.path) else { return }
                
                try FileManager.default.createDirectory(at: outputDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                let temporaryPackURL = outputDirectoryURL.appendingPathComponent(packName).appendingPathExtension("tar")
                try packData.write(to: temporaryPackURL)
                
                NavigationDirections.unpackTilePack(at: temporaryPackURL, outputDirectoryURL: outputDirectoryURL, progressHandler: { (totalBytes, unpackedBytes) in
                    print("Unpacked \(unpackedBytes) of \(totalBytes) bytes")
                }) { [weak self] (numberOfTiles, error) in
                    do {
                        if FileManager.default.fileExists(atPath: temporaryPackURL.path) {
                            try FileManager.default.removeItem(at: temporaryPackURL)
                        }
                    } catch {
                        self?.tilesUnpackingLock.unlock()
                        
                        print("Failed to remove temporary pack archive. Error: \(error)")
                        self?.presentAlert(OfflineServiceConstants.title, message: error.localizedDescription)
                    }
                    
                    self?.tilesUnpackingLock.unlock()
                    print("Finished unpacking \(numberOfTiles) tiles")
                }
            } catch {
                tilesUnpackingLock.unlock()
                
                print("Error occured while unpacking navigation tiles: \(error)")
                presentAlert(OfflineServiceConstants.title, message: error.localizedDescription)
            }
        }
    }
    
    public func onExpired(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        print("[OfflineServiceObserver] \(#function), identifier: \(metadata.id)")
    }
    
    public func onErrored(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        print("[OfflineServiceObserver] \(#function), identifier: \(metadata.id)")
    }
    
    public func onDeleting(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack, callback: @escaping OfflineDataPackAcknowledgeCallback) {
        print("[OfflineServiceObserver] \(#function), identifier: \(metadata.id)")
        
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
        
        presentAlert(OfflineServiceConstants.title, message: message)
    }
    
    public var peer: MBXPeerWrapper?
    
    // MARK: - UIViewController delegate methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        listAvailableRegions()
    }
    
    deinit {
        OfflineServiceManager.unregister(self)
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
    
    private func listAvailableRegions() {
        OfflineServiceManager.register(self)
        
        removeUnpackedTilesDirectory()

        OfflineServiceManager.instance.listAvailableRegions { [weak self] (expected) in
            guard let self = self else { return }
            
            if let error = expected?.error as? OfflineDataError {
                self.presentAlert(OfflineServiceConstants.title, message: error.message)

                return
            }

            let offlineDataRegions = expected?.value as? Array<Any>
            offlineDataRegions?.forEach {
                if let metadata = $0 as? OfflineDataRegionMetadata {
                    self.updateOfflineDataRegions(metadata: metadata)
                }
            }
        }
    }
    
    private func removeUnpackedTilesDirectory() {
        guard let unpackedTilesDirectoryURL = Bundle.mapboxCoreNavigation.suggestedTileURL?.appendingPathComponent("unpacked") else { return }
        try? FileManager.default.removeItem(at: unpackedTilesDirectoryURL)
    }
    
    private func updateOfflineDataRegions(for domain: OfflineDataDomain? = nil, metadata: OfflineDataRegionMetadata, delete: Bool = false) {
        DispatchQueue.main.async {
            var indexPaths = [IndexPath]()
            var found = false
            
            // In case if OfflineDataItem was found in list - update existing item with available pack for either map or navigation.
            for index in 0 ..< self.offlineDataItems.count {
                if self.offlineDataItems[index].dataRegionMetadata.id != metadata.id { continue }
                found = true
                
                guard let domain = domain else { continue }
                switch domain {
                case .maps:
                    self.offlineDataItems[index].mapPackMetadata = delete ? nil : metadata.mapPack
                case .navigation:
                    self.offlineDataItems[index].navigationPackMetadata = delete ? nil : metadata.navigationPack
                }
                
                indexPaths.append(IndexPath(row: index, section: 0))
            }
            
            // In case if OfflineDataItem wasn't found (e.g. in case if there is no internet connection) - add it to list and refresh UITableView.
            if !found {
                self.offlineDataItems.append(OfflineDataItem(dataRegionMetadata: metadata,
                                                             mapPackMetadata: domain == .maps ? metadata.mapPack : nil,
                                                             navigationPackMetadata: domain == .navigation ? metadata.mapPack : nil))
                
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: [IndexPath(row: self.offlineDataItems.count - 1, section: 0)], with: .automatic)
                self.tableView.endUpdates()
                
                return
            }
            
            self.tableView.reloadRows(at: indexPaths, with: .automatic)
        }
    }
    
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
