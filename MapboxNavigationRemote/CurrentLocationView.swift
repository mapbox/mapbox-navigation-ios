import Foundation
import SwiftUI
import MapboxNavigationRemoteKit
import MultipeerKit
import Combine
import MapboxNavigationRemoteMultipeerKit

struct CurrentLocationView: View {
    final class VM: ObservableObject {
        @Published
        var receivedLocations: [PeerPayload<CurrentLocationResponse>] = []
        private var subscriptions: [AnyCancellable] = []

        init() {
        }

        func startIfNeeded() {
            guard subscriptions.isEmpty else { return }
            Current.responses.currentLocation
                .receive(on: DispatchQueue.main)
                .sink { [unowned self] peerPayload in
                    receivedLocations.append(peerPayload)
                }
                .store(in: &subscriptions)
        }
    }

    @ObservedObject var vm: VM = Current.currentLocationVM

    var body: some View {
        Form {
            List(vm.receivedLocations) { locationPayload in
                HStack {
                    Text(locationPayload.sender.name)
                    Text(locationPayload.payload.location.latitude.description)
                        .textSelection(.enabled)
                    Text(" - ")
                    Text(locationPayload.payload.location.longitude.description)
                        .textSelection(.enabled)
                }
            }
            .listStyle(.bordered)
            Button("Request Current Location") {
                Current.transceiver.send(CurrentLocationRequest(), to: Current.peers)
            }
        }
        .onAppear {
            vm.startIfNeeded()
        }
    }
}
