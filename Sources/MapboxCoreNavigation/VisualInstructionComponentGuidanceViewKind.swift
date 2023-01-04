import MapboxDirections
import MapboxNavigationNative

extension VisualInstruction.Component.GuidanceViewKind {
    
    init(_ native: MapboxNavigationNative.BannerComponentSubType) {
        switch native {
        case .JCT:
            self = .fork
        case .signboard:
            self = .signboard
        case .sapaguidemap:
            self = .serviceAreaGuideMap
        case .sapa:
            self = .serviceArea
        case .aftertoll:
            self = .afterToll
        case .cityreal:
            self = .realisticUrbanIntersection
        case .ent:
            self = .motorwayEntrance
        case .exit:
            self = .motorwayExit
        case .tollbranch:
            self = .tollBranch
        case .directionboard:
            self = .directionBoard
        @unknown default:
            fatalError("Unknown BannerComponentSubType value.")
        }
    }
}
