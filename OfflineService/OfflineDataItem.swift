import MapboxCommon

public struct OfflineDataItem {
    
    var dataRegionMetadata: OfflineDataRegionMetadata
    var mapPackMetadata: OfflineDataPackMetadata? = nil
    var navigationPackMetadata: OfflineDataPackMetadata? = nil
    var domain: OfflineDataDomain? = nil
    var offlineDataPack: OfflineDataPack? = nil
}
