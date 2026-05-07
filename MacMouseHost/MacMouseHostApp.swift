import SwiftUI

@main
struct MacMouseHostApp: App {
    @StateObject private var peerHost = PeerHost()

    var body: some Scene {
        WindowGroup {
            HostView()
                .environmentObject(peerHost)
        }
        .windowResizability(.contentSize)
    }
}
