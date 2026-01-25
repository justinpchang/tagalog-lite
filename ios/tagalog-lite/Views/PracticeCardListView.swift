import SwiftUI

struct PracticeCardListView: View {
  @Environment(\.dismiss) private var dismiss

  let lessons: [Lesson]
  let states: [String: SRSStateStore.CardState]
  let now: Date

  private var lessonsWithCards: [Lesson] {
    lessons.filter { !$0.flashcards.isEmpty }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Theme.pageGradient.ignoresSafeArea()

        ScrollView {
          VStack(alignment: .leading, spacing: 14) {
            if lessonsWithCards.isEmpty {
              emptyState
            } else {
              lessonList
            }
          }
          .padding(16)
        }
      }
      .navigationTitle("All Cards")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { dismiss() }
        }
      }
    }
  }

  private var lessonList: some View {
    VStack(spacing: 12) {
      ForEach(lessonsWithCards) { lesson in
        NavigationLink {
          PracticeLessonCardsView(
            lesson: lesson,
            states: states,
            now: now
          )
        } label: {
          PracticeLessonRow(lesson: lesson)
        }
        .buttonStyle(.plain)
      }
    }
  }

  private var emptyState: some View {
    VStack(spacing: 10) {
      Image(systemName: "rectangle.stack")
        .font(.system(size: 30, weight: .heavy, design: .rounded))
        .foregroundStyle(Theme.accent)

      Text("No completed lessons")
        .font(.system(.title3, design: .rounded).weight(.heavy))

      Text("Mark lessons as completed to add their cards to your Practice deck.")
        .font(.system(.subheadline, design: .rounded))
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }
    .tropicalCard()
  }
}

private struct PracticeLessonRow: View {
  @Environment(\.colorScheme) private var colorScheme
  let lesson: Lesson

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text(lessonLabel)
          .font(.system(.subheadline, design: .rounded).weight(.semibold))
          .foregroundStyle(.secondary)
        Text(lessonTitle)
          .font(.system(.title3, design: .rounded).weight(.heavy))
          .foregroundStyle(.primary)
          .multilineTextAlignment(.leading)
          .lineLimit(nil)
        Text("\(lesson.flashcards.count) cards")
          .font(.system(.subheadline, design: .rounded))
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 8)

      Image(systemName: "chevron.right")
        .foregroundStyle(.secondary)
        .font(.system(size: 16, weight: .semibold))
    }
    .padding(14)
    .background(Theme.cardBackground(colorScheme))
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .strokeBorder(
          colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06),
          lineWidth: 1
        )
    )
    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.20 : 0.08), radius: 10, x: 0, y: 6)
  }

  private var lessonLabel: String {
    lesson.numericOrder.map { "Lesson \($0)" } ?? "Lesson"
  }

  private var lessonTitle: String {
    lesson.title
      .replacingOccurrences(
        of: lesson.numericOrder.map { "Lesson \($0) - " } ?? "",
        with: ""
      )
      .replacingOccurrences(
        of: lesson.numericOrder.map { "Lesson \($0) – " } ?? "",
        with: ""
      )
  }
}

private struct PracticeLessonCardsView: View {
  @Environment(\.colorScheme) private var colorScheme
  let lesson: Lesson
  let states: [String: SRSStateStore.CardState]
  let now: Date

  var body: some View {
    ZStack {
      Theme.pageGradient.ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          header

          VStack(spacing: 10) {
            ForEach(lesson.flashcards) { card in
              PracticeCardRow(
                card: card,
                state: states[card.id],
                now: now
              )
            }
          }
        }
        .padding(16)
      }
    }
    .navigationTitle(lessonLabel)
    .navigationBarTitleDisplayMode(.inline)
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(lessonLabel)
        .font(.system(.subheadline, design: .rounded).weight(.semibold))
        .foregroundStyle(.secondary)
      Text(lessonTitle)
        .font(.system(.title3, design: .rounded).weight(.heavy))
        .foregroundStyle(.primary)
        .lineLimit(nil)
    }
    .padding(14)
    .background(Theme.cardBackground(colorScheme))
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .strokeBorder(Theme.accent.opacity(colorScheme == .dark ? 0.30 : 0.18), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.20 : 0.08), radius: 10, x: 0, y: 6)
  }

  private var lessonLabel: String {
    lesson.numericOrder.map { "Lesson \($0)" } ?? "Lesson"
  }

  private var lessonTitle: String {
    lesson.title
      .replacingOccurrences(
        of: lesson.numericOrder.map { "Lesson \($0) - " } ?? "",
        with: ""
      )
      .replacingOccurrences(
        of: lesson.numericOrder.map { "Lesson \($0) – " } ?? "",
        with: ""
      )
  }
}

private struct PracticeCardRow: View {
  @Environment(\.colorScheme) private var colorScheme
  let card: Flashcard
  let state: SRSStateStore.CardState?
  let now: Date

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        Text(card.kind == .vocab ? "Vocab" : "Example")
          .font(.system(size: 11, weight: .bold, design: .rounded))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Capsule().fill(Theme.accent.opacity(0.14)))

        if card.showsOptionalNotice {
          Text("optional")
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
        }

        if card.audioKey != nil {
          Image(systemName: "speaker.wave.2.fill")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
        }

        Spacer(minLength: 8)

        MetaBadge(text: statusText, tint: statusTint)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(card.frontText)
          .font(.system(.headline, design: .rounded).weight(.semibold))
          .foregroundStyle(.primary)

        Text(card.backText)
          .font(.system(.subheadline, design: .rounded))
          .foregroundStyle(.secondary)
      }

      if let state {
        HStack(spacing: 6) {
          MetaBadge(text: "Interval \(intervalText(state))", tint: Theme.tropicalTeal)
          MetaBadge(text: "Ease \(easeText(state))", tint: Theme.sunnyYellow)
          MetaBadge(text: "Reps \(state.repetitions)", tint: Theme.deepLeaf)
          MetaBadge(text: "Lapses \(state.lapses)", tint: Theme.accent)
        }
      } else {
        HStack(spacing: 6) {
          MetaBadge(text: "New card", tint: Theme.tropicalTeal)
        }
      }
    }
    .padding(12)
    .background(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .fill(Theme.cardBackground(colorScheme))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .strokeBorder(
          Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08),
          lineWidth: 1
        )
    )
  }

  private var statusText: String {
    guard let state else { return "New" }
    if state.dueAt <= now { return "Due" }
    let seconds = state.dueAt.timeIntervalSince(now)
    return "Due \(dueInText(seconds))"
  }

  private var statusTint: Color {
    guard let state else { return Theme.tropicalTeal }
    if state.dueAt <= now { return Theme.accent }
    return Theme.sunnyYellow
  }

  private func dueInText(_ seconds: TimeInterval) -> String {
    let clamped = max(0, seconds)
    let hour: Double = 60 * 60
    let day: Double = 24 * hour

    if clamped < hour {
      return "<1h"
    }
    if clamped < day {
      let hours = Int(ceil(clamped / hour))
      return "\(hours)h"
    }
    let days = Int(ceil(clamped / day))
    return "\(days)d"
  }

  private func intervalText(_ state: SRSStateStore.CardState) -> String {
    let seconds = max(0, state.intervalSeconds)
    let day: Double = 60 * 60 * 24
    let days = max(1, Int(round(seconds / day)))
    return "\(days)d"
  }

  private func easeText(_ state: SRSStateStore.CardState) -> String {
    String(format: "%.2f", state.easeFactor)
  }
}

private struct MetaBadge: View {
  @Environment(\.colorScheme) private var colorScheme
  let text: String
  let tint: Color

  var body: some View {
    Text(text)
      .font(.system(.caption2, design: .rounded).weight(.semibold))
      .foregroundStyle(.primary)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(
        Capsule()
          .fill(tint.opacity(colorScheme == .dark ? 0.25 : 0.16))
      )
      .overlay(
        Capsule()
          .strokeBorder(tint.opacity(colorScheme == .dark ? 0.45 : 0.30), lineWidth: 1)
      )
  }
}

