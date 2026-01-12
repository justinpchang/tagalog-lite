import Combine
import Foundation
import SwiftUI

@MainActor
final class LessonStore: ObservableObject {
  @Published private(set) var lessons: [Lesson] = []
  @Published private(set) var loadError: String?

  func loadFromBundle() {
    do {
      loadError = nil
      lessons = try Self.loadLessons(bundle: .main)
    } catch {
      lessons = []
      loadError = error.localizedDescription
    }
  }

  private static func loadLessons(bundle: Bundle) throws -> [Lesson] {
    let urls = bundle.urls(forResourcesWithExtension: "json", subdirectory: "raw/normalized") ?? []

    // Helpful fallback if someone imported JSONs at the root of the bundle.
    let rootUrls = bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []

    let unique = Array(Set(urls + rootUrls))
      .filter { $0.lastPathComponent.lowercased().hasPrefix("lesson") }

    let decoder = JSONDecoder()
    var loaded: [(lesson: Lesson, url: URL)] = []

    for url in unique {
      let data = try Data(contentsOf: url)
      let lesson = try decoder.decode(Lesson.self, from: data)
      loaded.append((lesson, url))
    }

    return
      loaded
      .sorted { a, b in
        let an =
          a.lesson.numericOrder ?? Lesson.extractLessonNumber(from: a.url.lastPathComponent)
          ?? Int.max
        let bn =
          b.lesson.numericOrder ?? Lesson.extractLessonNumber(from: b.url.lastPathComponent)
          ?? Int.max
        if an != bn { return an < bn }
        return a.lesson.title.localizedCaseInsensitiveCompare(b.lesson.title) == .orderedAscending
      }
      .map(\.lesson)
  }
}
