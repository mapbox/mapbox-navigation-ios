import SwiftUI
import Combine
import MapboxNavigationRemoteKit
import MapboxNavigationRemoteMultipeerKit
import MultipeerKit

struct HistoryFilesView: View {
    final class VM: ObservableObject {
        private var subscriptions: [AnyCancellable] = []

        @Published
        var historyFiles: [Peer: [HistoryFile]] = [:]

        func startIfNeeded() {
            guard subscriptions.isEmpty else { return }

            Current.responses.stopHistoryRecording
                .receive(on: DispatchQueue.main)
                .sink { [weak self] peerPayload in
                    guard let self = self else { return }
                    guard let file = peerPayload.payload.file else { return }
                    var filesForPeer = self.historyFiles[peerPayload.sender] ?? []
                    filesForPeer.append(file)
                    self.historyFiles[peerPayload.sender] = filesForPeer
                }
                .store(in: &subscriptions)

            Current.responses.listHistoryFiles
                .receive(on: DispatchQueue.main)
                .sink { [weak self] peerPayload in
                    self?.historyFiles[peerPayload.sender] = peerPayload.payload.files.sorted(by: { f1, f2 in
                        f1.name <= f2.name
                    })
                }
                .store(in: &subscriptions)
        }
    }
    @ObservedObject private var vm: VM = Current.historyFilesVM

    var body: some View {
        NavigationView {
            List {
                ForEach(vm.historyFiles.keys.sorted(by: { $0.name <= $1.name } )) { peer in
                    Section(peer.name) {
                        ForEach(vm.historyFiles[peer]!) { historyFile in
                            NavigationLink(destination: HistoryFileView(peer: peer, file: historyFile)) {
                                HStack {
                                    if let date = historyFile.date,
                                       let size = historyFile.size {
                                        Text(date, format: .dateTime)
                                        Text(ByteCountFormatStyle.FormatInput(size), format: ByteCountFormatStyle())
                                    }
                                    else {
                                        Text(historyFile.name)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(minWidth: 300)
        }
        .onAppear {
            vm.startIfNeeded()
        }
    }
}
