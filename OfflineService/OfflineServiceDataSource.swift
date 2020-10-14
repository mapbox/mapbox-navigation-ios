import Foundation
import MapboxCommon
import MapboxCoreNavigation

open class OfflineServiceDataSource: OfflineServiceObserver {
    
    public weak var delegate: OfflineServiceDataSourceDelegate?
    
    private var offlineDataItems = [OfflineDataItem]()
    
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
}

public protocol OfflineServiceDataSourceDelegate: class {

    func offlineServiceDataSource(_ dataSource: OfflineServiceDataSource, didUpdate offlineDataItems: [OfflineDataItem])
    
    func offlineServiceDataSource(_ dataSource: OfflineServiceDataSource, didFail error: OfflineServiceError)
}
