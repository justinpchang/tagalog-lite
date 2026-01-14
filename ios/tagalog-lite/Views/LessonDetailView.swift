import SwiftUI

struct LessonDetailView: View {
  @Environment(\.dismiss) private var dismiss

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
      .padding(.top, 6)
    }
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .safeAreaInset(edge: .top) {
      headerBar
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }
  }

  private var headerBar: some View {
    GlassHeaderBar {
      HStack(alignment: .center, spacing: 12) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(.primary)
            .frame(width: 36, height: 36)
            .background(
              Circle().fill(Color.white.opacity(0.10))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")

        VStack(alignment: .leading, spacing: 4) {
          Text(lesson.title)
            .font(.system(.headline, design: .rounded))
            .lineLimit(1)

          HStack(spacing: 10) {
            Label("\(lesson.vocabulary.count)", systemImage: "book.fill")
            Label("\(lesson.exampleSentences.count)", systemImage: "quote.bubble.fill")
          }
          .font(.system(size: 12, weight: .semibold, design: .rounded))
          .foregroundStyle(.secondary)
          .labelStyle(.titleAndIcon)
        }
      }
    } trailing: {
      NavigationLink {
        StudyModeView(lesson: lesson)
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "sparkles")
          Text("Study")
        }
        .font(.system(size: 13, weight: .bold, design: .rounded))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
          Capsule().fill(Theme.accent)
        )
      }
      .buttonStyle(.plain)
    }
  }
}
