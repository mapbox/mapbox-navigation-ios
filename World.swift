import Foundation
import MultipeerKit
import MapboxNavigationRemoteKit
import Combine
import MapboxNavigationRemoteMultipeerKit

struct World {
    let transceiver: MultipeerTransceiver
    let actions: Actions
    let historyUrl: URL = {
        let dirUrl = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("history")
        _ = try? FileManager.default.createDirectory(at: dirUrl, withIntermediateDirectories: false, attributes: nil)
        return dirUrl
    }()

    struct Actions {
        let startNavigation: PassthroughSubject<PeerPayload<StartNavigationAction>, Never> = .init()
        let currentLocation: PassthroughSubject<PeerPayload<CurrentLocationRequest>, Never> = .init()
        let startHistoryRecording: PassthroughSubject<PeerPayload<StartHistoryRecordingAction>, Never> = .init()
        let stopHistoryRecording: PassthroughSubject<PeerPayload<StopHistoryRecordingAction>, Never> = .init()
        let listHistoryFiles: PassthroughSubject<PeerPayload<HistoryFilesRequest>, Never> = .init()
        let downloadHistoryFile: PassthroughSubject<PeerPayload<DownloadHistoryFileRequest>, Never> = .init()
    }

    func setupRemoteCli() {
        transceiver.receive(StartNavigationAction.self) { payload, sender in
            Current.actions.startNavigation.send(.init(payload: payload, sender: sender))
        }
        transceiver.receive(CurrentLocationRequest.self) { payload, sender in
            Current.actions.currentLocation.send(.init(payload: payload, sender: sender))
        }
        transceiver.receive(StartHistoryRecordingAction.self) { payload, sender in
            Current.actions.startHistoryRecording.send(.init(payload: payload, sender: sender))
        }
        transceiver.receive(StopHistoryRecordingAction.self) { payload, sender in
            Current.actions.stopHistoryRecording.send(.init(payload: payload, sender: sender))
        }
        transceiver.receive(HistoryFilesRequest.self) { payload, sender in
            Current.actions.listHistoryFiles.send(.init(payload: payload, sender: sender))
        }
        transceiver.receive(DownloadHistoryFileRequest.self) { payload, sender in
            Current.actions.downloadHistoryFile.send(.init(payload: payload, sender: sender))
        }
        transceiver.resume()
    }
}

var Current: World = .init(
    transceiver: .init(),
    actions: .init()
)
