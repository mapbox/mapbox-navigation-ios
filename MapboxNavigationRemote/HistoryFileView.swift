import SwiftUI
import MultipeerKit
import MapboxNavigationRemoteKit
import MapboxNavigationRemoteMultipeerKit
import Combine

struct HistoryFileView: View {
    final class VM: ObservableObject {
        @Published var rawGpx: String?
        @Published var name: String?
        private var subscriptions: [AnyCancellable] = []
        @Published var showGpxViewer: Bool = false

        init() {
            Current.responses.downloadGpxHistoryFile
                .receive(on: DispatchQueue.main)
                .sink { [weak self] peerPayload in
                    self?.rawGpx = String(data: peerPayload.payload.data, encoding: .utf8)
                    self?.name = peerPayload.payload.name
                    if self?.rawGpx != nil {
                        self?.showGpxViewer = true
                    }
                }.store(in: &subscriptions)
        }
    }

    @StateObject
    private var vm: VM = .init()

    let peer: Peer
    let file: HistoryFile

    var body: some View {
        Form {
            HStack {
                Text("Peer:")
                Text(peer.name)
            }

            HStack {
                Text("File:")
                Text(file.name)
            }

            Button("Download Raw") {
                Current.transceiver.send(DownloadHistoryFileRequest(historyFile: file),
                                         to: [peer])
            }


            Button("Download Gpx for Xcode Converted") {
                Current.transceiver.send(DownloadGpxHistoryFileRequest(historyFile: file),
                                         to: [peer])
            }
        }
        .sheet(isPresented: $vm.showGpxViewer) {
            vm.showGpxViewer = false
        } content: {
            GpxViewer(rawGpx: vm.rawGpx ?? "", name: vm.name ?? "Error.gpx")
                .frame(minWidth: 800, minHeight: 500)
        }
    }
}
