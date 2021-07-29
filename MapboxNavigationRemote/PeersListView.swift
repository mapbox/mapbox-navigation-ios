import Foundation
import SwiftUI
import MultipeerKit

struct PeersListView: View {
    final class VM: ObservableObject {
        @Published var selectedPeers: Set<Peer> = [] {
            didSet {
                Current.peers = Array(selectedPeers).sorted(by: { p1, p2 in
                    p1.id <= p1.id
                })
            }
        }

        func toggle(_ peer: Peer) {
            if selectedPeers.contains(peer) {
                selectedPeers.remove(peer)
            } else {
                selectedPeers.insert(peer)
            }
        }
    }

    @ObservedObject
    private var vm: VM = Current.peersListVM

    @EnvironmentObject var dataSource: MultipeerDataSource

    var body: some View {
        List {
            Section("Peers") {
                ForEach(dataSource.availablePeers) { peer in
                    HStack {
                        Circle()
                            .frame(width: 12, height: 12)
                            .foregroundColor(peer.isConnected ? .green : .gray)

                        Text(peer.name)

                        Spacer()

                        if vm.selectedPeers.contains(peer) {
                            Image(systemName: "checkmark.diamond.fill")
                        }
                        else {
                            Image(systemName: "diamond")
                        }
                    }
                    .onTapGesture {
                        vm.toggle(peer)
                    }
                }
            }
            Section("Actions") {
                NavigationLink("Start Navigation") {
                    StartNavigationView()
                        .navigationTitle("Start Navigation")
                        .padding()
                }
                NavigationLink("Current Locations") {
                    CurrentLocationView()
                        .padding()
                        .navigationTitle("Current Location")
                }
                NavigationLink("History Recorder") {
                    HistoryRecorderView()
                        .padding()
                        .navigationTitle("History Recorder")
                }
            }
        }
    }
}
