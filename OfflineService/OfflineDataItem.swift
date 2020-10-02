import MapboxCommon

struct OfflineDataItem {
    
    var dataRegionMetadata: OfflineDataRegionMetadata
    var mapPackMetadata: OfflineDataPackMetadata? = nil
    var navigationPackMetadata: OfflineDataPackMetadata? = nil
}
