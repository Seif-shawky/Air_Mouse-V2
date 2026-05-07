import SwiftUI

@main
struct PhoneMousePadApp: App {
    @StateObject private var peerClient = PeerClient()

    var body: some Scene {
        WindowGroup {
            PadView()
                .environmentObject(peerClient)
        }
    }
}
