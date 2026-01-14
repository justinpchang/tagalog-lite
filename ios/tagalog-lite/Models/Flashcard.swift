import Foundation

enum FlashcardKind: String, Equatable, Codable {
    case vocab
    case example
}

struct Flashcard: Identifiable, Equatable {
    let id: String
    let kind: FlashcardKind
    let frontText: String
    let backText: String
    let audioKey: String?
    let showsOptionalNotice: Bool
}

