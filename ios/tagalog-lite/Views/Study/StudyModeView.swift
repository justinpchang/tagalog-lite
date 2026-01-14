import SwiftUI

struct StudyModeView: View {
    @EnvironmentObject private var audio: AudioPlayerManager

    let lesson: Lesson
    let deck: [Flashcard]

    @State private var index: Int = 0
    @State private var isFlipped: Bool = false

    init(lesson: Lesson) {
        self.lesson = lesson
        self.deck = lesson.flashcards
    }

    var body: some View {
        ZStack {
            Theme.pageGradient.ignoresSafeArea()

            VStack(spacing: 12) {
                header

                progressBar

                TabView(selection: $index) {
                    ForEach(Array(deck.enumerated()), id: \.element.id) { i, card in
                        FlashcardView(flashcard: card, isFlipped: $isFlipped)
                            .padding(.horizontal, 16)
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxWidth: .infinity)

                controls
            }
            .padding(.top, 8)
            .padding(.bottom, 14)
        }
        .navigationTitle("Study")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: index) { _, _ in
            isFlipped = false
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(lesson.title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                Text("\(index + 1) / \(max(deck.count, 1))")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            let total = max(deck.count, 1)
            let progress = CGFloat(index + 1) / CGFloat(total)
            let w = max(0, min(1, progress)) * geo.size.width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.10))
                Capsule()
                    .fill(Theme.accent)
                    .frame(width: w)
            }
        }
        .frame(height: 6)
        .padding(.horizontal, 16)
        .padding(.top, -2)
    }

    private var controls: some View {
        return HStack(spacing: 10) {
            Button {
                index = max(0, index - 1)
            } label: {
                Label("Prev", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .background(Circle().fill(Color.white.opacity(0.08)))

            Spacer(minLength: 8)

            Button {
                index = min(deck.count - 1, index + 1)
            } label: {
                Label("Next", systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .background(Circle().fill(Color.white.opacity(0.08)))
        }
        .padding(.horizontal, 16)
    }
}

