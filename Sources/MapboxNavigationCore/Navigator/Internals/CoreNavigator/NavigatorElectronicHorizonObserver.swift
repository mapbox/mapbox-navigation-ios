import Foundation
import MapboxNavigationNative

class NavigatorElectronicHorizonObserver: ElectronicHorizonObserver {
    public func onPositionUpdated(
        for position: ElectronicHorizonPosition,
        distances: [MapboxNavigationNative.RoadObjectDistance]
    ) {
        let positionInfo = RoadGraph.Position(position.position())
        let treeInfo = RoadGraph.Edge(position.tree().start)
        let distancesInfo = distances.map(DistancedRoadObject.init)
        let updatesMPP = position.type() == .update

        Task { @MainActor in
            let userInfo: [RoadGraph.NotificationUserInfoKey: Any] = [
                .positionKey: positionInfo,
                .treeKey: treeInfo,
                .updatesMostProbablePathKey: updatesMPP,
                .distancesByRoadObjectKey: distancesInfo,
            ]

            NotificationCenter.default.post(
                name: .electronicHorizonDidUpdatePosition,
                object: nil,
                userInfo: userInfo
            )
        }
    }

    public func onRoadObjectEnter(for info: RoadObjectEnterExitInfo) {
        Task { @MainActor in
            let userInfo: [RoadGraph.NotificationUserInfoKey: Any] = [
                .roadObjectIdentifierKey: info.roadObjectId,
                .didTransitionAtEndpointKey: info.enterFromStartOrExitFromEnd,
            ]
            NotificationCenter.default.post(name: .electronicHorizonDidEnterRoadObject, object: nil, userInfo: userInfo)
        }
    }

    public func onRoadObjectExit(for info: RoadObjectEnterExitInfo) {
        Task { @MainActor in
            let userInfo: [RoadGraph.NotificationUserInfoKey: Any] = [
                .roadObjectIdentifierKey: info.roadObjectId,
                .didTransitionAtEndpointKey: info.enterFromStartOrExitFromEnd,
            ]
            NotificationCenter.default.post(name: .electronicHorizonDidExitRoadObject, object: nil, userInfo: userInfo)
        }
    }

    public func onRoadObjectPassed(for info: RoadObjectPassInfo) {
        Task { @MainActor in
            let userInfo: [RoadGraph.NotificationUserInfoKey: Any] = [
                .roadObjectIdentifierKey: info.roadObjectId,
            ]
            NotificationCenter.default.post(name: .electronicHorizonDidPassRoadObject, object: nil, userInfo: userInfo)
        }
    }
}
