import Foundation

enum SRSGrade: String, CaseIterable {
  case again
  case good
  case easy
}

struct SRSQueue {
  var due: [Flashcard]
  var new: [Flashcard]

  var isEmpty: Bool { due.isEmpty && new.isEmpty }
}

enum SRSchedulerSM2 {
  /// Build a queue for the current session.
  ///
  /// - New cards are those with no existing state.
  /// - Due cards are those with state and `dueAt <= now`.
  static func buildQueue(
    eligibleDeck: [Flashcard],
    states: [String: SRSStateStore.CardState],
    now: Date,
    dailyNewLimit: Int,
    dailyReviewLimit: Int,
    allowReviewAhead: Bool
  ) -> SRSQueue {
    let clampedNew = max(0, dailyNewLimit)
    let clampedReview = max(0, dailyReviewLimit)

    var due: [Flashcard] = []
    var newCards: [Flashcard] = []

    for c in eligibleDeck {
      if let s = states[c.id] {
        if s.dueAt <= now {
          due.append(c)
        } else if allowReviewAhead {
          // Review-ahead mode: treat non-due as not in queue; we’ll only use it when due+new are empty.
        }
      } else {
        newCards.append(c)
      }
    }

    if due.isEmpty && newCards.isEmpty && allowReviewAhead {
      // No due/new: allow reviewing ahead by picking the next soonest due card.
      // Preserve stable order by scanning the eligible deck and picking the first non-due card.
      for c in eligibleDeck {
        if let s = states[c.id], s.dueAt > now {
          due = [c]
          break
        }
      }
    }

    if due.count > clampedReview {
      due = Array(due.prefix(clampedReview))
    }
    if newCards.count > clampedNew {
      newCards = Array(newCards.prefix(clampedNew))
    }

    return SRSQueue(due: due, new: newCards)
  }

  static func apply(
    grade: SRSGrade,
    previous: SRSStateStore.CardState?,
    now: Date
  ) -> SRSStateStore.CardState {
    var s = previous ?? .new(now: now)

    // SM-2 quality mapping (we only expose 3 buttons).
    let q: Double
    switch grade {
    case .again: q = 0
    case .good: q = 4
    case .easy: q = 5
    }

    // Ease factor update (SM-2).
    let efDelta = 0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02)
    s.easeFactor = max(1.3, s.easeFactor + efDelta)

    if grade == .again {
      s.repetitions = 0
      s.lapses += 1
      // Short relearn step (not pure SM-2, but makes Again behave like Anki).
      s.intervalSeconds = 10 * 60
      s.dueAt = now.addingTimeInterval(s.intervalSeconds)
      s.lastReviewedAt = now
      return s
    }

    // Successful review.
    s.repetitions += 1

    let oneDay: Double = 60 * 60 * 24
    if s.repetitions == 1 {
      s.intervalSeconds = oneDay
    } else if s.repetitions == 2 {
      s.intervalSeconds = 6 * oneDay
    } else {
      // If a card is somehow missing an interval, fall back to 6d.
      let base = max(s.intervalSeconds, 6 * oneDay)
      s.intervalSeconds = base * s.easeFactor
    }

    if grade == .easy {
      // Anki-style easy bonus.
      s.intervalSeconds *= 1.3
    }

    // Clamp to at least 1 day for successful grades.
    s.intervalSeconds = max(oneDay, s.intervalSeconds)
    s.dueAt = now.addingTimeInterval(s.intervalSeconds)
    s.lastReviewedAt = now
    return s
  }
}

