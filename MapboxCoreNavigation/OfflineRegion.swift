import Foundation
import MapboxCommon

public enum OfflineRegionStatus {
    case pending
    case downloading
    case available
    case incomplete
    case verifying
    case expired
    case errored(error: OfflineRegionError)
    case deleting
    case deleted
}

public enum OfflineRegionDomain {
    case maps
    case navigation

    static func common(domain: MapboxCommon.OfflineDataDomain) -> OfflineRegionDomain{
        return domain == .maps ? .maps : .navigation
    }

    var commonDomain: MapboxCommon.OfflineDataDomain {
        return self == .maps ? .maps : .navigation
    }
}

public struct OfflineRegionPack {
    let commonPack: OfflineDataPack



    init(pack: OfflineDataPack) {
        self.commonPack = pack
    }
}

public struct OfflineRegion: Equatable {
    private(set) var region: OfflineDataRegionMetadata
    public var mapsPack: OfflineRegionPack?
    public var navigationPack: OfflineRegionPack?

    public var isDownloaded: Bool {
        mapsPack != nil || navigationPack != nil
    }

    init(region: OfflineDataRegionMetadata, mapsPack: OfflineDataPack? = nil, navigationPack: OfflineDataPack? = nil) {
        self.region = region
        self.mapsPack = mapsPack != nil ? OfflineRegionPack(pack: mapsPack!) : nil
        self.navigationPack = navigationPack != nil ? OfflineRegionPack(pack: navigationPack!) : nil
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.region == rhs.region
    }
}
