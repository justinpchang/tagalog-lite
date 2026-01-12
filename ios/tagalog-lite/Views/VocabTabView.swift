import SwiftUI

struct VocabTabView: View {
    let items: [BilingualItem]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    VocabCard(item: item)
                }
            }
            .padding(16)
        }
    }
}

private struct VocabCard: View {
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
                    cardContents
                }
                .buttonStyle(.plain)
            } else {
                cardContents
            }
        }
        .alert("Audio", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
}

private extension VocabCard {
    var cardContents: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Text(item.tagalog)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))

                Spacer(minLength: 8)

                // Only show a subtle notice for NOT required items.
                if !item.required {
                    Text("optional")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(Theme.accent.opacity(0.16))
                        )
                }

                // The entire card is tappable; this is just an affordance/indicator.
                if key != nil {
                    Image(systemName: isActive ? "pause.fill" : "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(isActive ? Theme.tropicalTeal : Theme.accent))
                        .accessibilityHidden(true)
                }
            }

            Text(item.english)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.9))
        }
        .tropicalCard()
    }
}


