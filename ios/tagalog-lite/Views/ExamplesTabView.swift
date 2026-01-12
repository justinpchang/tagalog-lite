import SwiftUI

struct ExamplesTabView: View {
    let items: [BilingualItem]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    ExampleRow(item: item)
                }
            }
            .padding(16)
        }
    }
}

private struct ExampleRow: View {
    @EnvironmentObject private var audio: AudioPlayerManager
    let item: BilingualItem

    @State private var showError = false
    @State private var errorMessage = ""

    private var key: String? { item.audioKey }
    private var isActive: Bool {
        guard let key else { return false }
        return audio.currentKey == key && audio.isPlaying
    }

    var body: some View {
        Group {
            if let key {
                Button {
                    audio.togglePlay(key: key)
                    if let msg = audio.lastErrorMessage, !msg.isEmpty {
                        errorMessage = msg
                        showError = true
                    }
                } label: {
                    rowContents
                }
                .buttonStyle(.plain)
            } else {
                rowContents
            }
        }
        .alert("Audio", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

private extension ExampleRow {
    var rowContents: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.tagalog)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text(item.english)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.9))
            }

            Spacer(minLength: 8)

            if key != nil {
                Image(systemName: isActive ? "pause.fill" : "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(isActive ? Theme.tropicalTeal : Theme.accent))
                    .accessibilityHidden(true)
            }
        }
        .tropicalCard()
    }
}


