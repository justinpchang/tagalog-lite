import SwiftUI

struct ExtrasListView: View {
  @EnvironmentObject private var store: LessonStore
  @Environment(\.colorScheme) private var colorScheme

  @State private var path: [String] = []

  var body: some View {
    NavigationStack(path: $path) {
      ZStack {
        Theme.pageGradient.ignoresSafeArea()

        ScrollView {
          VStack(alignment: .leading, spacing: 14) {
            header

            if let err = store.loadError {
              Text("Couldn’t load appendices: \(err)")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .tropicalCard()
                .padding(.top, 6)
            } else if appendices.isEmpty {
              VStack(alignment: .leading, spacing: 10) {
                Text("No appendices found in the app bundle.")
                  .font(.system(.headline, design: .rounded))
                Text("Make sure `appendix*.json` files are included in the app bundle.")
                  .font(.system(.subheadline, design: .rounded))
                  .foregroundStyle(.secondary)
              }
              .tropicalCard()
              .padding(.top, 6)
            } else {
              LazyVStack(spacing: 12) {
                ForEach(appendices) { appendix in
                  NavigationLink(value: appendix.id) {
                    AppendixRow(appendix: appendix)
                  }
                  .buttonStyle(.plain)
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
      .navigationDestination(for: String.self) { appendixId in
        if let appendix = store.lessons.first(where: { $0.id == appendixId }) {
          AppendixDetailView(appendix: appendix)
        } else {
          Text("Appendix not found.")
            .font(.system(.body, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(16)
        }
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Extras")
        .font(.system(size: 34, weight: .heavy, design: .rounded))
        .foregroundStyle(.primary)
      Text("Appendix notes and references")
        .font(.system(.title3, design: .rounded).weight(.medium))
        .foregroundStyle(.secondary)
    }
  }

  private var appendices: [Lesson] {
    store.lessons
      .filter(isAppendix)
      .sorted { a, b in
        let ak = appendixKey(for: a)
        let bk = appendixKey(for: b)
        if ak != bk { return ak < bk }
        return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
      }
  }

  private func isAppendix(_ lesson: Lesson) -> Bool {
    let id = lesson.id.lowercased()
    let title = lesson.title.lowercased()
    return id.hasPrefix("appendix") || title.hasPrefix("appendix")
  }

  private func appendixKey(for lesson: Lesson) -> String {
    if let key = appendixKey(in: lesson.id) { return key }
    if let key = appendixKey(in: lesson.title) { return key }
    return lesson.title.lowercased()
  }

  private func appendixKey(in raw: String) -> String? {
    let lower = raw.lowercased()
    guard let range = lower.range(of: "appendix") else { return nil }
    let suffix = lower[range.upperBound...]
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let cleaned = suffix.trimmingCharacters(in: CharacterSet(charactersIn: "-–—"))
    guard !cleaned.isEmpty else { return nil }
    let key = cleaned.prefix { $0.isLetter || $0.isNumber }
    return key.isEmpty ? nil : String(key)
  }
}

private struct AppendixRow: View {
  @Environment(\.colorScheme) private var colorScheme
  let appendix: Lesson

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text(appendixLabel)
          .font(.system(.subheadline, design: .rounded).weight(.semibold))
          .foregroundStyle(.secondary)
        Text(appendixTitle)
          .font(.system(.title3, design: .rounded).weight(.heavy))
          .foregroundStyle(.primary)
          .multilineTextAlignment(.leading)
          .lineLimit(nil)
      }

      Spacer(minLength: 8)

      Image(systemName: "chevron.right")
        .foregroundStyle(.secondary)
        .font(.system(size: 16, weight: .semibold))
    }
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(Theme.cardBackground(colorScheme))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 1)
    )
    .shadow(color: Color.primary.opacity(colorScheme == .dark ? 0.20 : 0.06), radius: 12, x: 0, y: 8)
  }

  private var appendixLabel: String {
    if let key = appendixKey(in: appendix.id) ?? appendixKey(in: appendix.title) {
      return "Appendix \(key.uppercased())"
    }
    return "Appendix"
  }

  private var appendixTitle: String {
    appendix.title
      .replacingOccurrences(
        of: appendixLabel + " - ",
        with: ""
      )
      .replacingOccurrences(
        of: appendixLabel + " – ",
        with: ""
      )
  }

  private func appendixKey(in raw: String) -> String? {
    let lower = raw.lowercased()
    guard let range = lower.range(of: "appendix") else { return nil }
    let suffix = lower[range.upperBound...]
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let cleaned = suffix.trimmingCharacters(in: CharacterSet(charactersIn: "-–—"))
    guard !cleaned.isEmpty else { return nil }
    let key = cleaned.prefix { $0.isLetter || $0.isNumber }
    return key.isEmpty ? nil : String(key)
  }
}

struct AppendixDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme
  @EnvironmentObject private var store: LessonStore
  let appendix: Lesson

  @State private var showTagalog: Bool = true
  @State private var revealedTagalogKeys: Set<String> = []
  @State private var selectedAppendix: Lesson?

  var body: some View {
    ZStack {
      Theme.pageGradient.ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          GrammarSection(
            lessonId: appendix.id,
            blocks: appendix.contents,
            showTagalog: showTagalog,
            revealedTagalogKeys: $revealedTagalogKeys,
            showsHeader: false,
            appendixKeys: availableAppendixKeys
          )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 18)
      }
    }
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .navigationBar)
    .safeAreaInset(edge: .top) {
      header
    }
    .sheet(item: $selectedAppendix) { appendix in
      AppendixDetailView(appendix: appendix)
    }
    .environment(
      \.openURL,
      OpenURLAction { url in
        handleAppendixLink(url)
      }
    )
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top, spacing: 12) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.primary)
            .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")

        VStack(alignment: .leading, spacing: 4) {
          Text(appendixTitle)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundStyle(.primary)
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .lineSpacing(2)
        }
        .padding(.top, 2)

        Spacer(minLength: 0)
      }

      HStack(spacing: 12) {
        Text(appendixLabel)
          .font(.system(.subheadline, design: .rounded).weight(.semibold))
          .foregroundStyle(.secondary)
        Spacer(minLength: 0)
        TagalogVisibilityPill(
          isOn: $showTagalog,
          onToggle: { revealedTagalogKeys.removeAll() }
        )
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .padding(.bottom, 10)
    .background(
      Color(.systemBackground)
        .ignoresSafeArea(edges: .top)
    )
  }

  private var appendixLabel: String {
    if let key = appendixKey(in: appendix.id) ?? appendixKey(in: appendix.title) {
      return "Appendix \(key.uppercased())"
    }
    return "Appendix"
  }

  private var appendixTitle: String {
    appendix.title
      .replacingOccurrences(
        of: appendixLabel + " - ",
        with: ""
      )
      .replacingOccurrences(
        of: appendixLabel + " – ",
        with: ""
      )
  }

  private func appendixKey(in raw: String) -> String? {
    let lower = raw.lowercased()
    guard let range = lower.range(of: "appendix") else { return nil }
    let suffix = lower[range.upperBound...]
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let cleaned = suffix.trimmingCharacters(in: CharacterSet(charactersIn: "-–—"))
    guard !cleaned.isEmpty else { return nil }
    let key = cleaned.prefix { $0.isLetter || $0.isNumber }
    return key.isEmpty ? nil : String(key)
  }

  private var availableAppendixKeys: Set<String> {
    Set(appendixIndex.keys)
  }

  private var appendixIndex: [String: Lesson] {
    store.lessons.reduce(into: [:]) { dict, lesson in
      guard isAppendix(lesson), let key = appendixKey(in: lesson.id) ?? appendixKey(in: lesson.title) else { return }
      dict[key] = lesson
    }
  }

  private func handleAppendixLink(_ url: URL) -> OpenURLAction.Result {
    guard url.scheme == "appendix" else {
      return .systemAction
    }
    let key = (url.host?.isEmpty == false) ? url.host! : url.pathComponents.last
    guard let raw = key?.lowercased(), let appendix = appendixIndex[raw] else {
      return .discarded
    }
    selectedAppendix = appendix
    return .handled
  }

  private func isAppendix(_ lesson: Lesson) -> Bool {
    let id = lesson.id.lowercased()
    let title = lesson.title.lowercased()
    return id.hasPrefix("appendix") || title.hasPrefix("appendix")
  }
}

private struct TagalogVisibilityPill: View {
  @Environment(\.colorScheme) private var colorScheme
  @Binding var isOn: Bool
  let onToggle: () -> Void

  private var title: String {
    isOn ? "Hide Tagalog" : "Show Tagalog"
  }

  var body: some View {
    Button {
      isOn.toggle()
      onToggle()
    } label: {
      HStack(spacing: 8) {
        Image(systemName: isOn ? "eye" : "eye.slash")
        Text(title)
      }
      .font(.system(.subheadline, design: .rounded).weight(.semibold))
      .foregroundStyle(.primary)
      .padding(.horizontal, 14)
      .padding(.vertical, 9)
      .background(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(
            isOn
              ? Theme.tropicalTeal.opacity(colorScheme == .dark ? 0.22 : 0.14)
              : Theme.cardBackground(colorScheme)
          )
      )
      .overlay(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .strokeBorder(
            isOn
              ? Theme.tropicalTeal.opacity(colorScheme == .dark ? 0.35 : 0.22)
              : Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.10),
            lineWidth: 1
          )
      )
      .shadow(
        color: Color.primary.opacity(colorScheme == .dark ? 0.22 : 0.06), radius: 10, x: 0, y: 6)
    }
    .buttonStyle(.plain)
  }
}

