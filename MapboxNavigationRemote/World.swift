import Foundation
import MultipeerKit
import MapboxNavigationRemoteKit
import MapboxNavigationRemoteMultipeerKit
import Combine

struct World {
    internal init(transceiver: MultipeerTransceiver, dataSource: MultipeerDataSource, responses: World.Responses) {
        self.transceiver = transceiver
        self.dataSource = dataSource
        self.responses = responses
    }

    let transceiver: MultipeerTransceiver
    let dataSource: MultipeerDataSource
    let responses: Responses
    let currentLocationVM: CurrentLocationView.VM = .init()
    let peersListVM: PeersListView.VM = .init()
    private var _peers: [Peer] = []
    var peers: [Peer] {
        get {
            let available = Set(transceiver.availablePeers)
            var validSelected: [Peer] = []
            for p in _peers {
                if available.contains(p) {
                    validSelected.append(p)
                }
            }
            return validSelected
        }
        set {
            let available = Set(transceiver.availablePeers)
            var validSelected: [Peer] = []
            for p in newValue {
                if available.contains(p) {
                    validSelected.append(p)
                }
            }

            _peers = validSelected
        }
    }

    struct Responses {
        let currentLocation: PassthroughSubject<PeerPayload<CurrentLocationResponse>, Never>
    }

    func setupRemoteCli() {
        transceiver.receive(CurrentLocationResponse.self) { payload, sender in
            Current.responses.currentLocation.send(.init(payload: payload, sender: sender))
        }
        transceiver.resume()
    }
}

var Current: World = {
    let transceiver = MultipeerTransceiver()
    let datasource = MultipeerDataSource(transceiver: transceiver)
    return .init(
        transceiver: transceiver,
        dataSource: datasource,
        responses: .init(
            currentLocation: .init()
        )
    )
}()
