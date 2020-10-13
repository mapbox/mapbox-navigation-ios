import Foundation
import MapboxCommon
import MapboxCoreNavigation

open class OfflineServiceDataSource: OfflineServiceObserver {
    
    public weak var delegate: OfflineServiceDataSourceDelegate?
    
    private var offlineDataItems = [OfflineDataItem]()
    private let tilesUnpackingLock = NSLock()
    
    // MARK: - OfflineServiceObserver methods
    
    public func onPending(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        NSLog("[OfflineServiceObserver] \(#function), identifier: \(metadata.id)")
    }
    
    public func onDownloading(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        NSLog("[OfflineServiceObserver] \(#function), identifier: \(metadata.id), progress: \(pack.bytes) bytes")
        
        let offlineDataItem = OfflineDataItem(dataRegionMetadata: metadata, domain: domain, offlineDataPack: pack)
        self.delegate?.offlineServiceDataSource(self, didUpdate: [offlineDataItem])
    }
    
    public func onIncomplete(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        NSLog("[OfflineServiceObserver] \(#function), identifier: \(metadata.id)")
    }
    
    public func onVerifying(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        NSLog("[OfflineServiceObserver] \(#function), identifier: \(metadata.id)")
    }
    
    public func onAvailable(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        NSLog("[OfflineServiceObserver] \(#function), domain: \(domain.rawValue) identifier: \(metadata.id)")

        let offlineDataItem = OfflineDataItem(dataRegionMetadata: metadata,
                                              mapPackMetadata: domain == .maps ? metadata.mapPack : nil,
                                              navigationPackMetadata: domain == .navigation ? metadata.navigationPack : nil,
                                              domain: domain)
        
        self.delegate?.offlineServiceDataSource(self, didUpdate: [offlineDataItem])
        
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
                    NSLog("Unpacked \(unpackedBytes) of \(totalBytes) bytes")
                }) { (numberOfTiles, error) in
                    do {
                        if FileManager.default.fileExists(atPath: temporaryPackURL.path) {
                            try FileManager.default.removeItem(at: temporaryPackURL)
                        }
                    } catch {
                        self.tilesUnpackingLock.unlock()
                        
                        NSLog("Failed to remove temporary pack archive. Error: \(error)")
                        self.delegate?.offlineServiceDataSource(self, didFail: OfflineServiceError.genericError(message: error.localizedDescription))
                    }
                    
                    self.tilesUnpackingLock.unlock()
                    NSLog("Finished unpacking \(numberOfTiles) tiles")
                }
            } catch {
                tilesUnpackingLock.unlock()
                
                NSLog("Error occured while unpacking navigation tiles: \(error)")
                delegate?.offlineServiceDataSource(self, didFail: OfflineServiceError.genericError(message: error.localizedDescription))
            }
        }
    }
    
    public func onExpired(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        NSLog("[OfflineServiceObserver] \(#function), identifier: \(metadata.id)")
    }
    
    public func onErrored(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        NSLog("[OfflineServiceObserver] \(#function), identifier: \(metadata.id)")
    }
    
    public func onDeleting(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack, callback: @escaping OfflineDataPackAcknowledgeCallback) {
        NSLog("[OfflineServiceObserver] \(#function), identifier: \(metadata.id)")
        callback()
    }
    
    public func onDeleted(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata) {
        NSLog("[OfflineServiceObserver] \(#function), identifier: \(metadata.id)")
        
        let offlineDataItem = OfflineDataItem(dataRegionMetadata: metadata, domain: domain)
        self.delegate?.offlineServiceDataSource(self, didUpdate: [offlineDataItem])
    }
    
    public func onInitialized() {
        NSLog("[OfflineServiceObserver] \(#function)")
    }
    
    public func onIdle() {
        NSLog("[OfflineServiceObserver] \(#function)")
    }
    
    public func onLogMessage(forMessage message: String) {
        NSLog("[OfflineServiceObserver] \(#function): \(message)")
    }
    
    public var peer: MBXPeerWrapper?
    
    deinit {
        OfflineServiceManager.unregister(self)
    }
    
    // MARK: - Public methods
    
    public func startObservingAvailableRegions() {
        OfflineServiceManager.register(self)
        
        removeUnpackedTilesDirectory()

        OfflineServiceManager.instance.listAvailableRegions { [weak self] (expected) in
            guard let self = self else { return }
            
            if let error = expected?.error as? OfflineDataError {
                self.delegate?.offlineServiceDataSource(self, didFail: OfflineServiceError.genericError(message: error.message))

                return
            }

            let offlineDataRegions = expected?.value as? Array<Any>
            var offlineDataItems = [OfflineDataItem]()
            offlineDataRegions?.forEach {
                if let metadata = $0 as? OfflineDataRegionMetadata {
                    offlineDataItems.append(OfflineDataItem(dataRegionMetadata: metadata))
                }
            }
            
            if !offlineDataItems.isEmpty {
                self.delegate?.offlineServiceDataSource(self, didUpdate: offlineDataItems)
            }
        }
    }
    
    // MARK: - Private methods
    
    private func removeUnpackedTilesDirectory() {
        guard let unpackedTilesDirectoryURL = Bundle.mapboxCoreNavigation.suggestedTileURL?.appendingPathComponent("unpacked") else { return }
        try? FileManager.default.removeItem(at: unpackedTilesDirectoryURL)
    }
}

public protocol OfflineServiceDataSourceDelegate: class {

    func offlineServiceDataSource(_ dataSource: OfflineServiceDataSource, didUpdate offlineDataItems: [OfflineDataItem])
    
    func offlineServiceDataSource(_ dataSource: OfflineServiceDataSource, didFail error: OfflineServiceError)
}
