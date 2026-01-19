import Foundation
import Combine

/// Persistent per-card SRS state (stored in UserDefaults as JSON).
@MainActor
final class SRSStateStore: ObservableObject {
  struct CardState: Codable, Equatable {
    var dueAt: Date
    var intervalSeconds: Double
    var easeFactor: Double
    var repetitions: Int
    var lapses: Int
    var lastReviewedAt: Date?

    static func new(now: Date) -> CardState {
      CardState(
        dueAt: now,
        intervalSeconds: 0,
        easeFactor: 2.5,
        repetitions: 0,
        lapses: 0,
        lastReviewedAt: nil
      )
    }
  }

  private let storageKey = "srsCardStates_v1"
  private let userDefaults: UserDefaults

  @Published private(set) var states: [String: CardState] = [:]

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
    load()
  }

  func state(for cardId: String) -> CardState? {
    states[cardId]
  }

  func upsert(cardId: String, state: CardState) {
    states[cardId] = state
    persist()
  }

  func remove(cardId: String) {
    states.removeValue(forKey: cardId)
    persist()
  }

  func removeAll() {
    states.removeAll()
    persist()
  }

  private func load() {
    guard let data = userDefaults.data(forKey: storageKey) else {
      states = [:]
      return
    }
    do {
      let decoded = try JSONDecoder().decode([String: CardState].self, from: data)
      states = decoded
    } catch {
      // If decoding fails (schema changes / corrupted data), fail safe to empty.
      states = [:]
    }
  }

  private func persist() {
    do {
      let data = try JSONEncoder().encode(states)
      userDefaults.set(data, forKey: storageKey)
    } catch {
      // Non-fatal: leave last persisted value intact.
    }
  }
}

