import SwiftUI
import MultipeerKit
import MapboxNavigationRemoteKit


struct HistoryFileView: View {
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

            Button("Download") {
                Current.transceiver.send(DownloadHistoryFileRequest(historyFile: file),
                                         to: [peer])
            }
        }
    }
}
