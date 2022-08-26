import MultipeerConnectivity
import os

@available(iOS 14.0, *)
class MultipeerSession: NSObject, ObservableObject {
    
    let session: MCSession
    let peerIdentifier = MCPeerID(displayName: UIDevice.current.name)
    let serviceAdvertiser: MCNearbyServiceAdvertiser
    let serviceBrowser: MCNearbyServiceBrowser
    let log = Logger()
    
    @Published var connectedPeers: [MCPeerID] = []
    
    override init() {
        session = MCSession(peer: peerIdentifier)
        
        let serviceType = "carplay-logger"
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: peerIdentifier,
                                                      discoveryInfo: nil,
                                                      serviceType: serviceType)
        
        serviceBrowser = MCNearbyServiceBrowser(peer: peerIdentifier,
                                                serviceType: serviceType)
        
        super.init()
        
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
        
        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
    }
    
    func send(_ data: Data) {
        if session.connectedPeers.isEmpty {
            return
        }
        
        do {
            try session.send(data,
                             toPeers: session.connectedPeers,
                             with: .reliable)
        } catch {
            log.error("Error occured while sending data: \(error.localizedDescription)")
        }
    }
    
    func send(_ connectionState: ConnectionState) {
        if session.connectedPeers.isEmpty {
            return
        }
        
        do {
            try session.send(connectionState.rawValue.data(using: .utf8)!,
                             toPeers: session.connectedPeers,
                             with: .reliable)
        } catch {
            log.error("Error occured while sending data: \(error.localizedDescription)")
        }
    }
}

@available(iOS 14.0, *)
extension MultipeerSession: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didNotStartAdvertisingPeer error: Error) {
        log.error("ServiceAdvertiser didNotStartAdvertisingPeer: \(String(describing: error))")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        log.info("didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, session)
    }
}

@available(iOS 14.0, *)
extension MultipeerSession: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 didNotStartBrowsingForPeers error: Error) {
        log.error("ServiceBrowser didNotStartBrowsingForPeers: \(String(describing: error))")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {
        log.info("ServiceBrowser found peer: \(peerID)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser,
                 lostPeer peerID: MCPeerID) {
        log.info("ServiceBrowser lost peer: \(peerID)")
    }
}

@available(iOS 14.0, *)
extension MultipeerSession: MCSessionDelegate {
    
    func session(_ session: MCSession,
                 peer peerID: MCPeerID,
                 didChange state: MCSessionState) {
        log.info("peer \(peerID) didChangeState: \(state.debugDescription)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.connectedPeers = session.connectedPeers
        }
    }
    
    func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {
        
    }
    
    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) {
        
    }
}

enum ConnectionState: String, CaseIterable {
    
    case connected
    case disconnected
}
