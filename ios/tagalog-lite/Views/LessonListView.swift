import SwiftUI

struct LessonListView: View {
    @EnvironmentObject private var store: LessonStore

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.pageGradient.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        header

                        if let err = store.loadError {
                            Text("Couldn’t load lessons: \(err)")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.secondary)
                                .tropicalCard()
                                .padding(.top, 6)
                        } else if store.lessons.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("No lessons found in the app bundle.")
                                    .font(.system(.headline, design: .rounded))
                                Text("In Xcode, add `normalized/` (and `audio/`) as folder references so they’re copied into the app.")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            .tropicalCard()
                            .padding(.top, 6)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(store.lessons) { lesson in
                                    NavigationLink {
                                        LessonDetailView(lesson: lesson)
                                    } label: {
                                        LessonCard(lesson: lesson)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.top, 6)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { store.loadFromBundle() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(Theme.accent)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                Text("Tagalog Lite")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
            }
            Text("Grammar lessons, vocab, and sample sentences.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .tropicalCard()
    }
}

private struct LessonCard: View {
    let lesson: Lesson

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.accent.opacity(0.20))
                VStack(spacing: 2) {
                    Text(lesson.numericOrder.map(String.init) ?? "–")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.deepLeaf)
                    Text("Lesson")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
            .frame(width: 64, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Text("\(lesson.vocabulary.count) vocab • \(lesson.exampleSentences.count) examples")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.accent)
                .font(.system(size: 14, weight: .bold))
        }
        .tropicalCard()
    }
}


