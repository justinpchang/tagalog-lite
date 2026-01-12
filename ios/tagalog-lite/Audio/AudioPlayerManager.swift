import AVFoundation
import Foundation
import Combine

@MainActor
final class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var currentKey: String?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var lastErrorMessage: String?

    private var player: AVAudioPlayer?

    func togglePlay(key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if currentKey == trimmed, let player {
            if player.isPlaying {
                player.pause()
                isPlaying = false
            } else {
                do {
                    try configureSession()
                    player.play()
                    isPlaying = true
                } catch {
                    lastErrorMessage = error.localizedDescription
                    isPlaying = false
                }
            }
            return
        }

        // Switch tracks.
        stop()
        currentKey = trimmed

        guard let url = Self.resolveBundledAudioUrl(for: trimmed) else {
            lastErrorMessage = "Could not find audio for \(trimmed). Make sure `audio/` is added to the app bundle."
            currentKey = nil
            isPlaying = false
            return
        }

        do {
            try configureSession()
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = self
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer
            isPlaying = true
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = error.localizedDescription
            currentKey = nil
            isPlaying = false
        }
    }

    func stop() {
        player?.stop()
        player = nil
        currentKey = nil
        isPlaying = false
    }

    private func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        // .playback: ignores the silent switch so lesson audio always plays.
        // Keep mixWithOthers so we don't rudely stop background audio.
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true, options: [])
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentKey = nil
        }
    }

    static func resolveBundledAudioUrl(for key: String) -> URL? {
        let candidates: [(ext: String, subdir: String?)] = [
            ("m4a", "raw/audio"),
            ("mp3", "raw/audio"),
            ("mp4", "raw/audio"),
            ("m4a", "audio"),
            ("mp3", "audio"),
            ("mp4", "audio"),
            ("m4a", nil),
            ("mp3", nil),
            ("mp4", nil)
        ]
        for c in candidates {
            if let url = Bundle.main.url(forResource: key, withExtension: c.ext, subdirectory: c.subdir) {
                return url
            }
        }
        return nil
    }
}


