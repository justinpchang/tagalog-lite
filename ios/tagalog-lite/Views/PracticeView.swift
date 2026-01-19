import SwiftUI

struct PracticeView: View {
  @EnvironmentObject private var store: LessonStore
  @EnvironmentObject private var completion: LessonCompletionStore
  @EnvironmentObject private var audio: AudioPlayerManager
  @EnvironmentObject private var srs: SRSStateStore

  @AppStorage("srsDailyNewLimit") private var dailyNewLimit: Int = 20
  @AppStorage("srsDailyReviewLimit") private var dailyReviewLimit: Int = 200
  @AppStorage("srsAllowReviewAhead") private var allowReviewAhead: Bool = false

  @State private var session: [Flashcard] = []
  @State private var index: Int = 0
  @State private var isRevealed: Bool = false
  @State private var history: [HistoryEntry] = []

  private struct SessionSnapshot: Equatable {
    var session: [Flashcard]
    var index: Int
    var isRevealed: Bool
  }

  private struct HistoryEntry: Equatable {
    var snapshot: SessionSnapshot
    var cardId: String
    var previousState: SRSStateStore.CardState?
  }

  private var now: Date { Date() }

  private var eligibleDeck: [Flashcard] {
    DeckBuilder.buildEligibleDeck(
      lessons: store.lessons,
      completedLessonIds: completion.completedLessonIds
    )
  }

  private var dueCount: Int {
    eligibleDeck.reduce(0) { partial, card in
      guard let st = srs.states[card.id] else { return partial }
      return partial + (st.dueAt <= now ? 1 : 0)
    }
  }

  private var totalNewCount: Int {
    eligibleDeck.reduce(0) { partial, card in
      partial + (srs.states[card.id] == nil ? 1 : 0)
    }
  }

  private var dueTodayCount: Int {
    min(dueCount, max(0, dailyReviewLimit))
  }

  private var newTodayCount: Int {
    min(totalNewCount, max(0, dailyNewLimit))
  }

  private var isEligibleEmpty: Bool { eligibleDeck.isEmpty }

  private var currentCard: Flashcard? {
    guard index >= 0, index < session.count else { return nil }
    return session[index]
  }

  private var canUndo: Bool { !history.isEmpty }

  var body: some View {
    ZStack {
      Theme.pageGradient.ignoresSafeArea()

      VStack(spacing: 12) {
        header

        if isEligibleEmpty {
          emptyEligibleState
        } else if session.isEmpty || currentCard == nil {
          readyState
        } else {
          reviewState
        }
      }
      .padding(16)
    }
    .onAppear {
      // Make sure lessons are available even if user lands on Practice first.
      if store.lessons.isEmpty {
        store.loadFromBundle()
      }
    }
  }

  private var header: some View {
    GlassHeaderBar {
      VStack(alignment: .leading, spacing: 4) {
        Text("Practice")
          .font(.system(size: 24, weight: .heavy, design: .rounded))
        Text("\(dueTodayCount) due • \(newTodayCount) new • \(eligibleDeck.count) total")
          .font(.system(.subheadline, design: .rounded).weight(.semibold))
          .foregroundStyle(.secondary)
      }
    } trailing: {
      Button {
        undo()
      } label: {
        Image(systemName: "arrow.uturn.left")
          .font(.system(size: 16, weight: .bold))
          .foregroundStyle(.primary.opacity(canUndo ? 1 : 0.35))
          .frame(width: 36, height: 36)
      }
      .buttonStyle(.plain)
      .disabled(!canUndo)
      .accessibilityLabel("Undo")
    }
  }

  private var emptyEligibleState: some View {
    VStack(spacing: 10) {
      Image(systemName: "checkmark.circle")
        .font(.system(size: 30, weight: .heavy, design: .rounded))
        .foregroundStyle(Theme.accent)

      Text("No cards yet")
        .font(.system(.title3, design: .rounded).weight(.heavy))

      Text(
        "Mark a lesson as completed to add its vocab and example sentences to your Practice deck."
      )
      .font(.system(.subheadline, design: .rounded))
      .foregroundStyle(.secondary)
      .multilineTextAlignment(.center)
    }
    .tropicalCard()
  }

  private var readyState: some View {
    VStack(alignment: .leading, spacing: 12) {
      if dueTodayCount == 0 && newTodayCount == 0 {
        Text("You’re all caught up.")
          .font(.system(.title3, design: .rounded).weight(.heavy))
        Text(
          allowReviewAhead
            ? "No cards are due right now, but you can review ahead."
            : "No cards are due right now."
        )
        .font(.system(.subheadline, design: .rounded))
        .foregroundStyle(.secondary)
      } else {
        Text("Ready to review")
          .font(.system(.title3, design: .rounded).weight(.heavy))
        Text("Tap start to begin. Reveal the Tagalog, then grade yourself.")
          .font(.system(.subheadline, design: .rounded))
          .foregroundStyle(.secondary)
      }

      Button {
        startSession()
      } label: {
        HStack(spacing: 10) {
          Image(systemName: "bolt.fill")
          Text("Start")
            .fontWeight(.bold)
        }
        .font(.system(.headline, design: .rounded))
        .foregroundStyle(.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.accent))
      }
      .buttonStyle(.plain)
    }
    .tropicalCard()
  }

  private var reviewState: some View {
    VStack(spacing: 12) {
      if let card = currentCard {
        reviewCard(card)

        if isRevealed {
          if let key = card.audioKey {
            Button {
              // Replay: if currently playing this key, toggle will pause; tapping again plays.
              audio.togglePlay(key: key)
            } label: {
              HStack(spacing: 10) {
                Image(systemName: "speaker.wave.2.fill")
                Text("Replay audio")
                  .fontWeight(.bold)
              }
              .font(.system(.headline, design: .rounded))
              .foregroundStyle(.white)
              .padding(.horizontal, 16)
              .padding(.vertical, 12)
              .frame(maxWidth: .infinity)
              .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.tropicalTeal))
            }
            .buttonStyle(.plain)
          }

          gradingRow(card: card)
        } else {
          Text("Tap to reveal Tagalog")
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(.secondary)
        }
      }
    }
  }

  private func reviewCard(_ card: Flashcard) -> some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 10) {
        Text(card.kind == .vocab ? "Vocab" : "Example")
          .font(.system(size: 12, weight: .bold, design: .rounded))
          .foregroundStyle(.secondary)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(Capsule().fill(Theme.accent.opacity(0.14)))

        if card.showsOptionalNotice {
          Text("optional")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
        }

        Spacer()

        Text("\(index + 1)/\(session.count)")
          .font(.system(.subheadline, design: .rounded).weight(.bold))
          .foregroundStyle(.secondary)
      }

      Spacer(minLength: 0)

      VStack(spacing: 14) {
        Text(card.frontText)
          .font(.system(size: 28, weight: .heavy, design: .rounded))
          .foregroundStyle(.primary)
          .frame(maxWidth: .infinity, alignment: .center)
          .multilineTextAlignment(.center)
          .minimumScaleFactor(0.65)
          .lineLimit(nil)

        if isRevealed {
          Divider().opacity(0.15)
          Text(card.backText)
            .font(.system(size: 30, weight: .heavy, design: .rounded))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.65)
            .lineLimit(nil)
        }
      }

      Spacer(minLength: 0)
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
      if !isRevealed {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
          isRevealed = true
        }
        autoplayAudioIfNeeded(for: card)
      }
    }
  }

  private func gradingRow(card: Flashcard) -> some View {
    HStack(spacing: 10) {
      gradeButton("Again", color: Color.red.opacity(0.90)) {
        grade(card: card, grade: .again)
      }
      gradeButton("Good", color: Theme.tropicalTeal) {
        grade(card: card, grade: .good)
      }
      gradeButton("Easy", color: Theme.deepLeaf) {
        grade(card: card, grade: .easy)
      }
    }
  }

  private func gradeButton(_ title: String, color: Color, action: @escaping () -> Void) -> some View
  {
    Button(action: action) {
      Text(title)
        .font(.system(.headline, design: .rounded).weight(.bold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
          RoundedRectangle(cornerRadius: 16, style: .continuous).fill(color)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 10, x: 0, y: 8)
    }
    .buttonStyle(.plain)
  }

  private func startSession() {
    let q = SRSchedulerSM2.buildQueue(
      eligibleDeck: eligibleDeck,
      states: srs.states,
      now: now,
      dailyNewLimit: dailyNewLimit,
      dailyReviewLimit: dailyReviewLimit,
      allowReviewAhead: allowReviewAhead
    )
    session = q.due + q.new
    index = 0
    isRevealed = false
    history.removeAll()
  }

  private func grade(card: Flashcard, grade: SRSGrade) {
    let prev = srs.state(for: card.id)
    history.append(
      HistoryEntry(
        snapshot: SessionSnapshot(session: session, index: index, isRevealed: isRevealed),
        cardId: card.id,
        previousState: prev
      )
    )
    let next = SRSchedulerSM2.apply(grade: grade, previous: prev, now: now)
    srs.upsert(cardId: card.id, state: next)

    // Anki-like session behavior:
    // - Remove the graded card from the queue
    // - If "Again", reinsert it a few cards later so it comes back in the same session.
    guard index >= 0, index < session.count else {
      session = []
      index = 0
      isRevealed = false
      return
    }

    var nextSession = session
    nextSession.remove(at: index)

    if grade == .again {
      // Put it back a bit later (feels like Anki's relearn without needing timers).
      let reinsertOffset = 6
      let insertAt = min(index + reinsertOffset, nextSession.count)
      nextSession.insert(card, at: insertAt)
    }

    session = nextSession
    isRevealed = false

    if session.isEmpty {
      index = 0
      return
    }
    if index >= session.count {
      // If we removed the last card, end the session.
      session = []
      index = 0
      isRevealed = false
    }
  }

  private func undo() {
    guard let last = history.popLast() else { return }

    // Revert SRS state.
    if let prev = last.previousState {
      srs.upsert(cardId: last.cardId, state: prev)
    } else {
      srs.remove(cardId: last.cardId)
    }

    // Restore session position.
    session = last.snapshot.session
    index = last.snapshot.index
    isRevealed = last.snapshot.isRevealed
  }

  private func autoplayAudioIfNeeded(for card: Flashcard) {
    guard let key = card.audioKey else { return }
    // Avoid pausing if the same key is already playing.
    if audio.currentKey == key && audio.isPlaying {
      return
    }
    audio.togglePlay(key: key)
  }
}
