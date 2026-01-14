import SwiftUI

struct FlashcardView: View {
    @EnvironmentObject private var audio: AudioPlayerManager
    let flashcard: Flashcard
    @Binding var isFlipped: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Text(flashcard.kind == .vocab ? "Vocab" : "Example")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Theme.accent.opacity(0.14)))

                if flashcard.showsOptionalNotice {
                    Text("optional")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "hand.tap.fill")
                    .foregroundStyle(.secondary.opacity(0.8))
                    .font(.system(size: 13, weight: .semibold))
                    .accessibilityHidden(true)
            }

            VStack(spacing: 14) {
                Text(isFlipped ? flashcard.backText : flashcard.frontText)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.65)
                    .lineLimit(nil)

                // On the Tagalog side, show a big audio button.
                if isFlipped, let key = flashcard.audioKey {
                    Button {
                        audio.togglePlay(key: key)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("Play audio")
                                .fontWeight(.bold)
                        }
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Capsule().fill(Theme.accent)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 18)

            Spacer(minLength: 0)

            Text(isFlipped ? "Tap to see English" : "Tap to reveal Tagalog")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 340, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .onTapGesture {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                isFlipped.toggle()
            }
        }
    }
}

