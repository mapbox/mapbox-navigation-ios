import Foundation
import MapboxCommon

/**
 `OfflineServiceManager` wraps `OfflineService` object to use only one instance of it and
 prevent usage of multiple users within single application.
 */
class OfflineServiceManager {
    
    private let offlineService: OfflineService = {
        guard let outputDirectory = Bundle.mapboxCoreNavigation.suggestedTileURL?.path else {
            preconditionFailure("suggestedTileURL is not valid.")
        }
        
        if !Bundle.mapboxCoreNavigation.ensureSuggestedTileURLExists() {
            preconditionFailure("Failed to create output directory.")
        }
        
        return OfflineService.getInstanceForPath(outputDirectory,
                                                 options: OfflineServiceOptions(username: OfflineServiceConstants.username,
                                                                                accessToken: OfflineServiceConstants.accessToken,
                                                                                baseURL: OfflineServiceConstants.baseURL))
    }()
    
    public static let instance = OfflineServiceManager()
    
    public static func register(_ observer: OfflineServiceObserver) {
        OfflineService.registerObserver(for: observer)
    }
    
    public static func unregister(_ observer: OfflineServiceObserver) {
        OfflineService.unregisterObserver(for: observer)
    }
    
    public func listAvailableRegions(_ callback: @escaping OfflineServiceListAvailableRegionsCallback) {
        offlineService.listAvailableRegions(forCallback: callback)
    }
    
    public func downloadPack(_ domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata) {
        offlineService.downloadPack(for: domain, metadata: metadata)
    }
    
    public func cancelPackDownload(_ domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata) {
        offlineService.cancelPackDownload(for: domain, metadata: metadata)
    }
    
    public func deletePack(_ domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata) {
        offlineService.deletePack(for: domain, metadata: metadata)
    }
}
