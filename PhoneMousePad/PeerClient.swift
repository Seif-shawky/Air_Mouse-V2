import Combine
import Foundation
import MultipeerConnectivity
import UIKit

@MainActor
final class PeerClient: NSObject, ObservableObject {
    @Published var statusText = "Open MacMouseHost on your MacBook."
    @Published var isConnected = false

    private let serviceType = "phone-mouse"
    private let peerID = MCPeerID(displayName: UIDevice.current.name)
    private lazy var session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
    private var browser: MCNearbyServiceBrowser?

    override init() {
        super.init()
        session.delegate = self

        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser.delegate = self
        browser.startBrowsingForPeers()
        self.browser = browser
    }

    func send(_ message: RemoteMessage) {
        guard !session.connectedPeers.isEmpty,
              let data = try? JSONEncoder().encode(message) else {
            return
        }

        let mode: MCSessionSendDataMode
        switch message {
        case .move, .scroll:
            mode = .unreliable
        case .click, .volume:
            mode = .reliable
        }

        try? session.send(data, toPeers: session.connectedPeers, with: mode)
    }
}

extension PeerClient: MCNearbyServiceBrowserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        Task { @MainActor in
            statusText = "Found \(peerID.displayName). Connecting..."
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 20)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        Task { @MainActor in
            statusText = "Lost \(peerID.displayName). Searching again..."
        }
    }
}

extension PeerClient: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                isConnected = true
                statusText = "\(peerID.displayName)"
            case .connecting:
                statusText = "Connecting to \(peerID.displayName)..."
            case .notConnected:
                isConnected = false
                statusText = "Disconnected. Searching..."
            @unknown default:
                isConnected = false
                statusText = "Unknown connection state."
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
