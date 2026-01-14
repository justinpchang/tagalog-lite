import Foundation

struct Lesson: Decodable, Identifiable, Equatable {
  let schemaVersion: Int
  let id: String
  let title: String
  let vocabulary: [BilingualItem]
  let contents: [LessonBlock]
  let exampleSentences: [BilingualItem]

  var numericOrder: Int? {
    // Prefer "lessonN" pattern from id, fallback to first number in title.
    if let n = Self.extractLessonNumber(from: id) { return n }
    if let n = Self.extractLessonNumber(from: title) { return n }
    return nil
  }

  static func extractLessonNumber(from s: String) -> Int? {
    // Matches "lesson2", "Lesson 2", "lesson-2", "lesson2 – ..."
    let lower = s.lowercased()
    if let range = lower.range(of: #"lesson\D*(\d+)"#, options: .regularExpression) {
      let sub = String(lower[range])
      if let digitsRange = sub.range(of: #"\d+"#, options: .regularExpression) {
        return Int(sub[digitsRange])
      }
    }

    // Fallback: first number anywhere
    if let digitsRange = lower.range(of: #"\d+"#, options: .regularExpression) {
      return Int(lower[digitsRange])
    }
    return nil
  }
}

extension Lesson {
  /// Study deck: vocab (in order) then examples (in order).
  var flashcards: [Flashcard] {
    var out: [Flashcard] = []
    out.reserveCapacity(vocabulary.count + exampleSentences.count)

    for (i, v) in vocabulary.enumerated() {
      out.append(
        Flashcard(
          id: "\(id)-vocab-\(i)",
          kind: .vocab,
          frontText: v.english,
          backText: v.tagalog,
          audioKey: v.audioKey,
          showsOptionalNotice: !v.required
        )
      )
    }

    for (i, e) in exampleSentences.enumerated() {
      out.append(
        Flashcard(
          id: "\(id)-example-\(i)",
          kind: .example,
          frontText: e.english,
          backText: e.tagalog,
          audioKey: e.audioKey,
          showsOptionalNotice: false
        )
      )
    }

    return out
  }
}

struct BilingualItem: Decodable, Equatable {
  let tagalog: String
  let english: String
  let required: Bool
  let audioPath: String?

  var audioKey: String? {
    let trimmed = audioPath?.trimmingCharacters(in: .whitespacesAndNewlines)
    return (trimmed?.isEmpty == false) ? trimmed : nil
  }
}

enum TextBlockType: String, Decodable, Equatable {
  case p
  case h1
  case h2
  case h3
}

struct TextBlock: Decodable, Equatable {
  let type: TextBlockType
  let markdown: String
}

struct SentenceBlock: Decodable, Equatable {
  let type: String  // "sentence"
  let item: BilingualItem
}

enum LessonBlock: Decodable, Equatable {
  case text(TextBlock)
  case sentence(SentenceBlock)

  private enum CodingKeys: String, CodingKey {
    case type
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)
    if type == "sentence" {
      self = .sentence(try SentenceBlock(from: decoder))
    } else {
      self = .text(try TextBlock(from: decoder))
    }
  }
}
