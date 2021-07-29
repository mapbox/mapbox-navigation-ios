import SwiftUI
import MapboxNavigationRemoteKit

struct HistoryRecorderView: View {
    var body: some View {
        Form {
            Button("Start History Recorder") {
                Current.transceiver.send(StartHistoryRecordingAction(), to: Current.peers)
            }
            Button("Stop History Recorder") {
                Current.transceiver.send(StopHistoryRecordingAction(), to: Current.peers)
            }
            Button("List all Files") {
                Current.transceiver.send(HistoryFilesRequest(), to: Current.peers)
            }
            HistoryFilesView()
        }
    }
}
