import AVFoundation
import MediaPlayer
import SwiftUI
import UIKit

final class VolumeButtonBridge: NSObject, ObservableObject {
    var onVolumeDelta: ((Double) -> Void)?

    private let audioSession = AVAudioSession.sharedInstance()
    private var observation: NSKeyValueObservation?
    private weak var volumeSlider: UISlider?
    private let neutralVolume: Float = 0.5
    private var lastVolume: Float = 0.5
    private var suppressNextChange = false
    private var attachAttempts = 0

    func attach(volumeView: MPVolumeView) {
        DispatchQueue.main.async { [weak self, weak volumeView] in
            guard let self, let volumeView else {
                return
            }

            self.volumeSlider = volumeView.subviews.compactMap { $0 as? UISlider }.first
            if self.volumeSlider == nil, self.attachAttempts < 8 {
                self.attachAttempts += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.attach(volumeView: volumeView)
                }
            } else {
                self.resetPhoneVolumeToNeutral()
            }
        }
    }

    func start() {
        try? audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? audioSession.setActive(true)

        resetPhoneVolumeToNeutral()
        observation = audioSession.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
            guard let self, let newValue = change.newValue else {
                return
            }

            let rawDelta = newValue - self.lastVolume
            guard !self.suppressNextChange, abs(rawDelta) > 0.001 else {
                self.suppressNextChange = false
                self.lastVolume = newValue
                return
            }

            let delta = Double(rawDelta > 0 ? 1 : -1)
            self.lastVolume = newValue

            DispatchQueue.main.async {
                self.resetPhoneVolumeToNeutral()
                self.onVolumeDelta?(delta)
            }
        }
    }

    func stop() {
        observation?.invalidate()
        observation = nil
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func resetPhoneVolumeToNeutral() {
        suppressNextChange = true
        lastVolume = neutralVolume
        volumeSlider?.setValue(neutralVolume, animated: false)
        volumeSlider?.sendActions(for: .valueChanged)
        volumeSlider?.sendActions(for: .touchUpInside)
    }
}

struct HiddenVolumeView: UIViewRepresentable {
    let volumeBridge: VolumeButtonBridge

    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.showsVolumeSlider = true
        view.showsRouteButton = false
        volumeBridge.attach(volumeView: view)
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {
        volumeBridge.attach(volumeView: uiView)
    }
}
