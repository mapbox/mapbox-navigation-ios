import Foundation
import MapboxDirections
import MapboxNavigationNative

public struct EHorizonObjectMetadata {

    /** type of road object */
    public let type: EHorizonObjectType

    /** provider of road object */
    public let provider: EHorizonObjectProvider

    /** will be filled only if `type` is `Incident` and `provider` is `Mapbox` */
    public let incident: Incident?

    /** will be filled only if `type` is `TunnelEntrance` and `provider` is `Mapbox` */
    public let tunnel: Tunnel?

    /** will be filled only if `type` is `BorderCrossing` and `provider` is `Mapbox` */
    public let borderCrossing: BorderCrossing?

    /** will be filled only if `type` is `TollCollectionPoint` and `provider` is `Mapbox` */
    public let tollCollection: TollCollection?

    /** will be filled only if `type` is `ServiceArea` and `provider` is `Mapbox` */
    public let serviceArea: RestStop?

    init(_ native: RoadObjectMetadata) {
        self.type = EHorizonObjectType(native.type)
        self.provider = EHorizonObjectProvider(native.provider)
        self.incident = native.incident != nil ? Incident(native.incident!) : nil
        self.tunnel = native.tunnelInfo != nil ? Tunnel(native.tunnelInfo!) : nil
        self.borderCrossing = native.borderCrossingInfo != nil
            ? BorderCrossing(native.borderCrossingInfo!) : nil
        self.tollCollection = native.tollCollectionInfo != nil
            ? TollCollection(native.tollCollectionInfo!) : nil
        self.serviceArea = native.serviceAreaInfo != nil
            ? RestStop.init(native.serviceAreaInfo!) : nil
    }
}
