import SwiftUI

struct LessonDetailView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case vocab = "Vocab"
        case lesson = "Lesson"
        case examples = "Examples"

        var id: String { rawValue }
    }

    let lesson: Lesson
    @State private var tab: Tab = .vocab

    var body: some View {
        ZStack {
            Theme.pageGradient.ignoresSafeArea()

            VStack(spacing: 12) {
                titleCard

                Picker("Section", selection: $tab) {
                    ForEach(Tab.allCases) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                TabView(selection: $tab) {
                    VocabTabView(items: lesson.vocabulary)
                        .tag(Tab.vocab)

                    LessonTabView(blocks: lesson.contents)
                        .tag(Tab.lesson)

                    ExamplesTabView(items: lesson.exampleSentences)
                        .tag(Tab.examples)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .padding(.top, 10)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var titleCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(lesson.title)
                .font(.system(size: 24, weight: .heavy, design: .rounded))

            HStack(spacing: 10) {
                Label("\(lesson.vocabulary.count) vocab", systemImage: "book.fill")
                Label("\(lesson.exampleSentences.count) examples", systemImage: "quote.bubble.fill")
            }
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tropicalCard()
        .padding(.horizontal, 16)
    }
}


