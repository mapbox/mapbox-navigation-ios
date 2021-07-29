import Foundation
import MultipeerKit
import MapboxNavigationRemoteKit
import Combine
import MapboxNavigationRemoteMultipeerKit

struct World {
    let transceiver: MultipeerTransceiver
    let actions: Actions

    struct Actions {
        let startNavigation: PassthroughSubject<PeerPayload<StartNavigationAction>, Never> = .init()
        let currentLocation: PassthroughSubject<PeerPayload<CurrentLocationRequest>, Never> = .init()
    }

    func setupRemoteCli() {
        transceiver.receive(StartNavigationAction.self) { payload, sender in
            Current.actions.startNavigation.send(.init(payload: payload, sender: sender))
        }
        transceiver.receive(CurrentLocationRequest.self) { payload, sender in
            Current.actions.currentLocation.send(.init(payload: payload, sender: sender))
        }
        transceiver.resume()
    }
}

var Current: World = .init(
    transceiver: .init(),
    actions: .init()
)
