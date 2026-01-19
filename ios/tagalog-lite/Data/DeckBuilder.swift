import Foundation

enum DeckBuilder {
  /// Returns a stable, deterministic deck of flashcards across all completed lessons.
  /// Order: lesson numeric order (ascending) then the existing `Lesson.flashcards` order.
  static func buildEligibleDeck(
    lessons: [Lesson],
    completedLessonIds: Set<String>
  ) -> [Flashcard] {
    let completedLessons =
      lessons
      .filter { completedLessonIds.contains($0.id) }
      .sorted { a, b in
        let an = a.numericOrder ?? Int.max
        let bn = b.numericOrder ?? Int.max
        if an != bn { return an < bn }
        return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
      }

    var out: [Flashcard] = []
    out.reserveCapacity(completedLessons.reduce(0) { $0 + $1.flashcards.count })
    for lesson in completedLessons {
      out.append(contentsOf: lesson.flashcards)
    }
    return out
  }
}

