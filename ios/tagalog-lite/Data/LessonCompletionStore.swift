import Foundation
import Combine
import SwiftUI

/// Tracks which lessons are completed (persisted in UserDefaults).
@MainActor
final class LessonCompletionStore: ObservableObject {
  private let storageKey = "completedLessonIds"

  @Published private(set) var completedLessonIds: Set<String> = []

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
    load()
  }

  private let userDefaults: UserDefaults

  func isCompleted(_ lessonId: String) -> Bool {
    completedLessonIds.contains(lessonId)
  }

  func setCompleted(_ lessonId: String, completed: Bool) {
    if completed {
      completedLessonIds.insert(lessonId)
    } else {
      completedLessonIds.remove(lessonId)
    }
    persist()
  }

  func toggleCompleted(_ lessonId: String) {
    setCompleted(lessonId, completed: !isCompleted(lessonId))
  }

  private func load() {
    let ids = userDefaults.stringArray(forKey: storageKey) ?? []
    completedLessonIds = Set(ids)
  }

  private func persist() {
    userDefaults.set(Array(completedLessonIds).sorted(), forKey: storageKey)
  }
}

