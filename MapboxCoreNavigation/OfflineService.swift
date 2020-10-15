import Foundation
import MapboxCommon

private typealias CommonOfflineService = MapboxCommon.OfflineService

public struct OfflineServiceUser {
    private enum Constants {
        static let username = "1tap-nav"
        static let baseURL = "https://api.mapbox.com"
    }

    let username: String
    let accessToken: String?
    let baseUrl: String

    init(username: String = Constants.username, accessToken: String? = nil, baseUrl: String = Constants.baseURL) {
        self.username = username
        if accessToken == nil, let accessToken = Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAccessToken") as? String {
            self.accessToken = accessToken
        } else {
            self.accessToken = accessToken
            if accessToken == nil {
                assertionFailure("`accessToken` must be set in the Info.plist as `MGLMapboxAccessToken`.")
            }
        }
        self.baseUrl = baseUrl
    }
}

/**
 A singleton class that allows querying the server for available offline regions, as well as downloading offline packs to
 disk. Observers attached to this object get notified when the status of an offline pack changes (e.g. when a new one is
 downloaded).
 */
public class OfflineService {
    private var instance: CommonOfflineService?

    public static let shared = OfflineService(user: OfflineServiceUser())

    private var _regions: [String: OfflineRegion] = [:]

    public var regions: [OfflineRegion] {
        Array(_regions.values)
    }

    private var observers: [OfflineServiceObserver] = []

    public var peer: MBXPeerWrapper?

    init(user: OfflineServiceUser) {
        if let outputDirectory = Bundle.mapboxCoreNavigation.suggestedTileURL?.path {
            if !Bundle.mapboxCoreNavigation.ensureSuggestedTileURLExists() {
                print("Failed to create tiles directory")
                return
            }
            guard let accessToken = user.accessToken else {
                assertionFailure("`accessToken` should be provided.")
                return
            }
            instance = CommonOfflineService.getInstanceForPath(
                outputDirectory,
                options: OfflineServiceOptions(
                    username: user.username,
                    accessToken: accessToken,
                    baseURL: user.baseUrl
                )
            )
            CommonOfflineService.registerObserver(for: self)
        }
    }

    /**
     @brief Queries the Offline Data API and lists all available regions

     Only lists regions that are compatible with the current format.

     @param callback Callback function that will be called with the result.
     */
    public func fetchAvailableRegions(_ callback:  (([OfflineRegion]) -> Void)?) {
        instance?.listAvailableRegions { [weak self] (expected) in
            guard let self = self else { return }
            if let error = expected?.error as? OfflineDataError {
                print(error.message)
                callback?([])
                return
            }

            guard let offlineDataRegions = expected?.value as? Array<Any> else { return }

            var regionIDsToStay: Set<String> = []

            for regionMetadata in offlineDataRegions {
                if let metadata = regionMetadata as? OfflineDataRegionMetadata {
                    if self._regions[metadata.id] == nil {
                        self._regions[metadata.id] = OfflineRegion(region: metadata)
                    }
                    regionIDsToStay.insert(metadata.id)
                }
            }
            let regionKeysToRemove = self._regions.keys
            for key in regionKeysToRemove {
                if !regionIDsToStay.contains(key), let region = self._regions[key], !region.isDownloaded {
                    self._regions.removeValue(forKey: key)
                }
            }
            callback?(self.regions)
        }
    }

    /**
     @brief Deletes a region

     Cancels active region downloads and deletes existing regions with this id.

     @param domain A flag indicating whether the Maps or Navigation pack should be deleted.
     If no value or nil is provided, packs for both domains will be deleted
     @param metadata The offline region to be deleted
     */
    public func remove(region: OfflineRegion, forDomain domain: OfflineRegionDomain? = nil) {
        if let domainToRemove = domain {
            instance?.deletePack(for: domainToRemove.commonDomain, metadata: region.region)
        } else {
            if region.mapsPack != nil {
                instance?.deletePack(for: .maps, metadata: region.region)
            }
            if region.navigationPack != nil {
                instance?.deletePack(for: .navigation, metadata: region.region)
            }
        }
    }

    /**
     @brief Cancels a pack download

     Cancellation is done via the string ID because downloads can be started from multiple places.

     @param domain A flag indicating whether the Maps or Navigation pack should be canceled.
     @param region The offline region to be canceled
     */
    public func cancelDownload(for region: OfflineRegion, domain: OfflineRegionDomain) {
        instance?.cancelPackDownload(for: domain.commonDomain, metadata: region.region)
    }

    /**
     @brief Starts the download of a pack

     If a pack with the same metadata is already being downloaded, nothing will happen. If the metadata is different,
     that download will be canceled, and a new download will be started. If the downloaded pack with this ID is
     already complete, a new download will be started if the revision is different.

     @param domain A flag indicating whether the Maps or Navigation pack should be downloaded.
     If no value or nil is provided, packs for both domains will be downloaded
     @param region The offline region to be downloaded
     */
    public func download(region: OfflineRegion, forDomain domain: OfflineRegionDomain? = nil) {
        if let domainToDownload = domain {
            instance?.downloadPack(for: domainToDownload.commonDomain, metadata: region.region)
        } else {
            if region.mapsPack != nil {
                instance?.downloadPack(for: .maps, metadata: region.region)
            }
            if region.navigationPack != nil {
                instance?.downloadPack(for: .navigation, metadata: region.region)
            }
        }
    }

    /**
     @brief Add an observer that gets events as region state changes.

     @param observer An object implementing the observer interface.
     */
    public func register(observer: OfflineServiceObserver) {
        observers.append(observer)
        notifyAvailable(forObserver: observer)
    }

    /**
     @brief Removes an observer.

     @param observer The observer that should be removed.
     */
    public func unregister(observer: OfflineServiceObserver) {
        observers.removeAll {
            $0 === observer
        }
    }

    private func notifyAvailable(forObserver observer: OfflineServiceObserver) {
        DispatchQueue.main.async { [weak self] in
            self?.regions.forEach {
                if $0.mapsPack != nil {
                    observer.didBecomeAvailable(region: $0, forDomain: .maps)
                }
                if $0.navigationPack != nil {
                    observer.didBecomeAvailable(region: $0, forDomain: .navigation)
                }
            }
        }
    }
}

extension OfflineService: MapboxCommon.OfflineServiceObserver {
    public func onPending(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let region = self._regions[metadata.id] ?? OfflineRegion(region: metadata)
            self.observers.forEach {
                $0.didAddPending(region: region, forDomain: .common(domain: domain))
            }
        }
    }

    public func onDownloading(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let region = self._regions[metadata.id] ?? OfflineRegion(region: metadata)
            self.observers.forEach {
                $0.didStartDownloading(region: region, forDomain: .common(domain: domain))
            }
        }
    }

    public func onIncomplete(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let region = self._regions[metadata.id] ?? OfflineRegion(region: metadata)
            self.observers.forEach {
                $0.didBecomeIncomplete(region: region, forDomain: .common(domain: domain))
            }
        }
    }

    public func onVerifying(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let region = self._regions[metadata.id] ?? OfflineRegion(region: metadata)
            self.observers.forEach {
                $0.didBeginVerifying(region: region, forDomain: .common(domain: domain))
            }
        }
    }

    public func onAvailable(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        if let region = _regions[metadata.id] {
            if domain == .maps {
                _regions[metadata.id] = OfflineRegion(region: metadata, mapsPack: pack, navigationPack: region.navigationPack?.commonPack)
            } else {
                _regions[metadata.id] = OfflineRegion(region: metadata, mapsPack: region.mapsPack?.commonPack, navigationPack: pack)
            }
        } else {
            _regions[metadata.id] = OfflineRegion(
                region: metadata,
                mapsPack: domain == .maps ? pack : nil,
                navigationPack: domain == .navigation ? pack : nil
            )
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let region = self._regions[metadata.id] ?? OfflineRegion(region: metadata)
            self.observers.forEach {
                $0.didBecomeAvailable(region: region, forDomain: .common(domain: domain))
            }
        }
    }

    public func onExpired(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let region = self._regions[metadata.id] ?? OfflineRegion(region: metadata)
            self.observers.forEach {
                $0.didBecomeExpired(region: region, forDomain: .common(domain: domain))
            }
        }
    }

    public func onErrored(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let region = self._regions[metadata.id] ?? OfflineRegion(region: metadata)

            let error: OfflineRegionError?
            if let packError = pack.error {
                error = OfflineRegionError(packError)
            } else {
                error = nil
            }
            self.observers.forEach {
                $0.didBecomeErrored(region: region, forDomain: .common(domain: domain), withError: error)
            }
        }
    }

    public func onDeleting(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata, pack: OfflineDataPack, callback: @escaping OfflineDataPackAcknowledgeCallback) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let region = self._regions[metadata.id] ?? OfflineRegion(region: metadata)
            self.observers.forEach {
                if $0.shouldRemove(region: region, forDomain: .common(domain: domain)) {
                    callback()
                }
            }
        }
    }

    public func onDeleted(for domain: OfflineDataDomain, metadata: OfflineDataRegionMetadata) {
        if let region = _regions[metadata.id] {
            if domain == .maps {
                _regions[metadata.id] = OfflineRegion(region: metadata, mapsPack: nil, navigationPack: region.navigationPack?.commonPack)
            } else {
                _regions[metadata.id] = OfflineRegion(region: metadata, mapsPack: region.mapsPack?.commonPack, navigationPack: nil)
            }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let region = self._regions[metadata.id] ?? OfflineRegion(region: metadata)
            self.observers.forEach {
                $0.didDelete(region: region, forDomain: .common(domain: domain))
            }
        }
    }

    public func onInitialized() {
        DispatchQueue.main.async { [weak self] in
            self?.observers.forEach {
                $0.initialized()
            }
        }
    }

    public func onIdle() {
        DispatchQueue.main.async { [weak self] in
            self?.observers.forEach {
                $0.idle()
            }
        }
    }

    public func onLogMessage(forMessage message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.observers.forEach {
                $0.log(message: message)
            }
        }
    }
}
