import SwiftUI

struct PlayButton: View {
    @EnvironmentObject private var audio: AudioPlayerManager
    let audioKey: String

    @State private var showError = false
    @State private var errorMessage = ""

    private var isActive: Bool {
        audio.currentKey == audioKey && audio.isPlaying
    }

    var body: some View {
        Button {
            audio.togglePlay(key: audioKey)
            if let msg = audio.lastErrorMessage, !msg.isEmpty {
                errorMessage = msg
                showError = true
            }
        } label: {
            Image(systemName: isActive ? "pause.fill" : "play.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(
                    Circle().fill(isActive ? Theme.tropicalTeal : Theme.accent)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isActive ? "Pause audio" : "Play audio")
        .alert("Audio", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}


