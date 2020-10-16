import MapboxCommon

/**
 `OfflineDataItem` model holds information which is presented to the user regarding offline regions downloaded via Offline Service.
 */
public struct OfflineDataItem {
    
    /**
     Metadata for an offline region. Metadata contains useful information (e.g. name, description) for specific region.
     */
    var dataRegionMetadata: OfflineDataRegionMetadata
    
    /**
     Metadata record for Maps offline pack. In case if pack wasn't downloaded or not present property is assigned to `nil`.
     */
    var mapPackMetadata: OfflineDataPackMetadata? = nil
    
    /**
     Metadata record for Navigation offline pack. In case if pack wasn't downloaded or not present property is assigned to `nil`.
     */
    var navigationPackMetadata: OfflineDataPackMetadata? = nil
    
    /**
     Domain of an offline pack (either for Maps or Navigation). This property is `nil` by default and set to either `.maps` or
     `.navigation` whenever new pack or region was downloaded, deleted or available.
     */
    var domain: OfflineDataDomain? = nil
    
    /**
     Actual data pack for specific `domain`. `offlineDataPack` is providing information regarding
     current status of an offline pack that is being downloaded.
     */
    var offlineDataPack: OfflineDataPack? = nil
}
