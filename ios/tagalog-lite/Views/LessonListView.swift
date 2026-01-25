import SwiftUI

struct LessonListView: View {
  @EnvironmentObject private var store: LessonStore
  @EnvironmentObject private var completion: LessonCompletionStore
  @Environment(\.colorScheme) private var colorScheme

  @State private var path: [String] = []

  var body: some View {
    NavigationStack(path: $path) {
      ZStack {
        Theme.pageGradient.ignoresSafeArea()

        ScrollView {
          VStack(alignment: .leading, spacing: 14) {
            header
            progressCard

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
                Text(
                  "In Xcode, add `normalized/` (and `audio/`) as folder references so they’re copied into the app."
                )
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
              }
              .tropicalCard()
              .padding(.top, 6)
            } else {
              LazyVStack(spacing: 12) {
                ForEach(store.lessons) { lesson in
                  LessonRow(
                    lesson: lesson,
                    isCompleted: completion.isCompleted(lesson.id),
                    onToggleCompleted: { completion.toggleCompleted(lesson.id) },
                    onOpen: { path.append(lesson.id) }
                  )
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
      .navigationDestination(for: String.self) { lessonId in
        if let lesson = store.lessons.first(where: { $0.id == lessonId }) {
          LessonDetailView(lesson: lesson)
        } else {
          Text("Lesson not found.")
            .font(.system(.body, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(16)
        }
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Tagalog Lite")
        .font(.system(size: 34, weight: .heavy, design: .rounded))
        .foregroundStyle(.primary)
      Text("Learn Tagalog grammar step by step")
        .font(.system(.title3, design: .rounded).weight(.medium))
        .foregroundStyle(.secondary)
    }
  }

  private var progressCard: some View {
    let total = max(store.lessons.count, 1)
    let done = store.lessons.reduce(0) { partial, lesson in
      partial + (completion.isCompleted(lesson.id) ? 1 : 0)
    }
    let progress = CGFloat(done) / CGFloat(total)

    return VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text("Progress")
          .font(.system(.headline, design: .rounded))
          .foregroundStyle(.secondary)
        Spacer()
        Text("\(done)/\(total) lessons")
          .font(.system(.headline, design: .rounded).weight(.bold))
          .foregroundStyle(.primary)
      }

      GeometryReader { geo in
        let w = max(0, min(1, progress)) * geo.size.width
        ZStack(alignment: .leading) {
          Capsule().fill(
            colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06))
          Capsule().fill(Theme.tropicalTeal).frame(width: w)
        }
      }
      .frame(height: 12)
    }
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Theme.cardBackground(colorScheme))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .strokeBorder(
          colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06), lineWidth: 1
        )
    )
    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.08), radius: 12, x: 0, y: 8)
  }
}

private struct LessonRow: View {
  @Environment(\.colorScheme) private var colorScheme
  let lesson: Lesson
  let isCompleted: Bool
  let onToggleCompleted: () -> Void
  let onOpen: () -> Void

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      Button(action: onToggleCompleted) {
        ZStack {
          Circle()
            .fill(
              isCompleted
                ? Theme.deepLeaf
                : Theme.tropicalTeal.opacity(0.12)
            )
          if isCompleted {
            Image(systemName: "checkmark")
              .font(.system(size: 18, weight: .heavy))
              .foregroundStyle(.white)
          } else {
            Text(lesson.numericOrder.map(String.init) ?? "–")
              .font(.system(size: 18, weight: .heavy, design: .rounded))
              .foregroundStyle(Theme.tropicalTeal)
          }
        }
        .frame(width: 48, height: 48)
        .accessibilityLabel(isCompleted ? "Mark lesson incomplete" : "Mark lesson completed")
      }
      .buttonStyle(.plain)

      VStack(alignment: .leading, spacing: 6) {
        Text(
          // Remove either "Lesson N - " or "Lesson N – " (with or without en/em dash)
          lesson.title
            .replacingOccurrences(
              of: lesson.numericOrder.map { "Lesson \($0) - " } ?? "",
              with: ""
            )
            .replacingOccurrences(
              of: lesson.numericOrder.map { "Lesson \($0) – " } ?? "",
              with: ""
            )
        )
        .font(.system(.title3, design: .rounded).weight(.heavy))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.leading)
        .lineLimit(nil)

        Text("\(lesson.vocabulary.count) words  •  \(lesson.exampleSentences.count) sentences")
          .font(.system(.subheadline, design: .rounded))
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 8)

      Image(systemName: "chevron.right")
        .foregroundStyle(.secondary)
        .font(.system(size: 16, weight: .semibold))
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(
          isCompleted
            ? Theme.deepLeaf.opacity(colorScheme == .dark ? 0.18 : 0.10)
            : Theme.cardBackground(colorScheme)
        )
    )
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .strokeBorder(
          isCompleted
            ? Theme.deepLeaf.opacity(colorScheme == .dark ? 0.40 : 0.25)
            : (colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06)),
          lineWidth: 1
        )
    )
    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.08), radius: 14, x: 0, y: 10)
    .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    .onTapGesture(perform: onOpen)
  }
}
