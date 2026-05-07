import Combine
import Foundation
import MultipeerConnectivity

@MainActor
final class PeerHost: NSObject, ObservableObject {
    @Published var statusText = "Open PhoneMousePad on your iPhone XS. Nearby Wi-Fi or Bluetooth will be used automatically."
    @Published var isConnected = false

    private let serviceType = "phone-mouse"
    private let peerID = MCPeerID(displayName: Host.current().localizedName ?? "MacBook")
    private lazy var session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
    private var advertiser: MCNearbyServiceAdvertiser?
    private let mouseController = MouseController()
    private let volumeController = VolumeController()

    override init() {
        super.init()
        session.delegate = self

        let advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        self.advertiser = advertiser

        mouseController.requestAccessibilityIfNeeded()
    }

    private func handle(_ message: RemoteMessage) {
        switch message {
        case let .move(dx, dy):
            mouseController.moveBy(dx: dx, dy: dy)
        case let .click(kind):
            mouseController.leftClick(kind: kind)
        case let .scroll(dx, dy):
            mouseController.scroll(dx: dx, dy: dy)
        case let .volume(delta):
            volumeController.changeVolume(by: delta)
        }
    }
}

extension PeerHost: MCNearbyServiceAdvertiserDelegate {
    nonisolated func advertiser(
        _ advertiser: MCNearbyServiceAdvertiser,
        didReceiveInvitationFromPeer peerID: MCPeerID,
        withContext context: Data?,
        invitationHandler: @escaping (Bool, MCSession?) -> Void
    ) {
        Task { @MainActor in
            invitationHandler(true, session)
        }
    }
}

extension PeerHost: MCSessionDelegate {
    nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                isConnected = true
                statusText = "Connected to \(peerID.displayName). Your iPhone is now a wireless trackpad."
            case .connecting:
                statusText = "Connecting to \(peerID.displayName)..."
            case .notConnected:
                isConnected = false
                statusText = "Disconnected. Keep both apps open to reconnect."
            @unknown default:
                isConnected = false
                statusText = "Unknown connection state."
            }
        }
    }

    nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = try? JSONDecoder().decode(RemoteMessage.self, from: data) else {
            return
        }

        Task { @MainActor in
            handle(message)
        }
    }

    nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
