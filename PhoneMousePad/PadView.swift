import SwiftUI

struct PadView: View {
    @EnvironmentObject private var peerClient: PeerClient
    @StateObject private var volumeBridge = VolumeButtonBridge()

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(peerClient.isConnected ? Color.green : Color.orange)
                        .frame(width: 10, height: 10)

                    Text(peerClient.isConnected ? "Connected" : "Searching")
                        .font(.headline)
                }

                Text(peerClient.statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.white)
            .padding(20)

            TrackpadSurface(
                onMove: { dx, dy in
                    peerClient.send(.move(dx: dx, dy: dy))
                },
                onClick: {
                    peerClient.send(.click(kind: .start))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.045) {
                        peerClient.send(.click(kind: .end))
                    }
                },
                onScroll: { dx, dy in
                    peerClient.send(.scroll(dx: dx, dy: dy))
                }
            )
            .ignoresSafeArea()

            HiddenVolumeView(volumeBridge: volumeBridge)
                .frame(width: 1, height: 1)
                .opacity(0.01)
        }
        .onAppear {
            volumeBridge.onVolumeDelta = { delta in
                peerClient.send(.volume(delta: delta))
            }
            volumeBridge.start()
        }
        .onDisappear {
            volumeBridge.stop()
        }
    }
}
