import SwiftUI

struct HostView: View {
    @EnvironmentObject private var peerHost: PeerHost

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Circle()
                    .fill(peerHost.isConnected ? Color.green : Color.orange)
                    .frame(width: 12, height: 12)

                Text(peerHost.isConnected ? "iPhone connected" : "Waiting for iPhone")
                    .font(.headline)
            }

            Text(peerHost.statusText)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Text("Grant Accessibility permission when macOS asks so the app can move and click the pointer.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(width: 420, alignment: .leading)
    }
}
