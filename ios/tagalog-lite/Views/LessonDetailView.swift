import SwiftUI

struct LessonDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(\.colorScheme) private var colorScheme
  @EnvironmentObject private var store: LessonStore

  let lesson: Lesson

  // Global visibility controls
  @State private var showTagalog: Bool = true

  // Per-item overrides (when global visibility is off)
  @State private var revealedTagalogKeys: Set<String> = []
  @State private var selectedAppendix: Lesson?

  var body: some View {
    ZStack {
      Theme.pageGradient.ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          if !lesson.vocabulary.isEmpty {
            VocabularySection(
              lessonId: lesson.id,
              items: lesson.vocabulary,
              showTagalog: showTagalog,
              revealedTagalogKeys: $revealedTagalogKeys
            )
            .padding(.horizontal, 16)
          }

          GrammarSection(
            lessonId: lesson.id,
            blocks: lesson.contents,
            showTagalog: showTagalog,
            revealedTagalogKeys: $revealedTagalogKeys,
            appendixKeys: availableAppendixKeys
          )
          .padding(.horizontal, 16)

          if !lesson.exampleSentences.isEmpty {
            ExamplesSection(
              lessonId: lesson.id,
              items: lesson.exampleSentences,
              showTagalog: showTagalog,
              revealedTagalogKeys: $revealedTagalogKeys
            )
            .padding(.horizontal, 16)
          }
        }
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
          Text(
            lesson.title
              .replacingOccurrences(
                of: lesson.numericOrder.map { "Lesson \($0) - " } ?? "",
                with: ""
              )
              .replacingOccurrences(
                of: lesson.numericOrder.map { "Lesson \($0) – " } ?? "",
                with: ""
              )
          )
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
        Text(lesson.numericOrder.map { "Lesson \($0)" } ?? "Lesson")
          .font(.system(.subheadline, design: .rounded).weight(.semibold))
          .foregroundStyle(.secondary)
        Spacer(minLength: 0)
        TagalogVisibilityPill(
          isOn: $showTagalog,
          onToggle: {
            revealedTagalogKeys.removeAll()
          }
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

  private var availableAppendixKeys: Set<String> {
    Set(appendixIndex.keys)
  }

  private var appendixIndex: [String: Lesson] {
    store.lessons.reduce(into: [:]) { dict, lesson in
      guard isAppendix(lesson), let key = appendixKey(for: lesson) else { return }
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

  private func appendixKey(for lesson: Lesson) -> String? {
    if let key = appendixKey(in: lesson.id) { return key }
    if let key = appendixKey(in: lesson.title) { return key }
    return nil
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
              : (colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06)),
            lineWidth: 1
          )
      )
      .shadow(
        color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.06), radius: 10, x: 0, y: 6)
    }
    .buttonStyle(.plain)
  }
}

private struct BilingualRevealCard: View {
  @Environment(\.colorScheme) private var colorScheme
  let tagalog: String
  let english: String
  let audioKey: String?
  let showTagalog: Bool
  let isTagalogRevealed: Bool
  let onToggleReveal: () -> Void

  private var effectiveShowTagalog: Bool { showTagalog || isTagalogRevealed }
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {  // less spacing overall
      HStack(alignment: .top, spacing: 8) {  // tighter spacing
        VStack(alignment: .leading, spacing: 4) {  // less vertical gap between lines
          Text(effectiveShowTagalog ? tagalog : "Tap to reveal Tagalog")
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .foregroundStyle(effectiveShowTagalog ? .primary : .secondary)
            .fixedSize(horizontal: false, vertical: true)

          Text(english)
            .font(.system(size: 14, weight: .regular, design: .rounded))  // a bit smaller, not bold
            .foregroundStyle(effectiveShowTagalog ? .secondary : .primary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Spacer(minLength: 4)

        if let audioKey {
          SpeakerButton(audioKey: audioKey)
        }
      }

    }
    .padding(10)  // less padding for a smaller card
    .background(
      RoundedRectangle(cornerRadius: 14, style: .continuous)  // smaller corner radius
        .fill(Theme.cardBackground(colorScheme))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .strokeBorder(
          colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06), lineWidth: 1
        )
    )
    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.20 : 0.06), radius: 8, x: 0, y: 5)  // smaller shadow
    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .gesture(
      TapGesture().onEnded {
        guard !showTagalog else { return }
        onToggleReveal()
      },
      including: .gesture
    )
  }
}

private struct SpeakerButton: View {
  @EnvironmentObject private var audio: AudioPlayerManager
  @Environment(\.colorScheme) private var colorScheme
  let audioKey: String

  @State private var showError = false
  @State private var errorMessage = ""

  private var isActive: Bool {
    audio.currentKey == audioKey && audio.isPlaying
  }

  var body: some View {
    Button {
      audio.togglePlay(key: audioKey)
      if let msg = audio.lastErrorMessage, !msg.isEmpty {
        errorMessage = msg
        showError = true
      }
    } label: {
      ZStack {
        Circle()
          .fill(isActive ? Theme.tropicalTeal : Theme.cardBackground(colorScheme))
          .overlay(
            Circle()
              .strokeBorder(
                isActive
                  ? Theme.tropicalTeal.opacity(colorScheme == .dark ? 0.45 : 0.35)
                  : (colorScheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.10)),
                lineWidth: 1
              )
          )

        Image(systemName: isActive ? "pause.fill" : "speaker.wave.2.fill")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(isActive ? .white : Theme.tropicalTeal)
      }
      .frame(width: 36, height: 36)
      .accessibilityLabel(isActive ? "Pause audio" : "Play audio")
    }
    .buttonStyle(.plain)
    .alert("Audio", isPresented: $showError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage)
    }
  }
}

private struct VocabularySection: View {
  let lessonId: String
  let items: [BilingualItem]
  let showTagalog: Bool
  @Binding var revealedTagalogKeys: Set<String>

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .firstTextBaseline, spacing: 10) {
        Text("Vocabulary")
          .font(.system(size: 28, weight: .heavy, design: .rounded))
        Text("(\(items.count) words)")
          .font(.system(.headline, design: .rounded))
          .foregroundStyle(.secondary)
      }
      .padding(.top, 6)

      VStack(spacing: 12) {
        ForEach(Array(items.enumerated()), id: \.offset) { i, item in
          let key = "\(lessonId)-vocab-\(i)"
          BilingualRevealCard(
            tagalog: item.tagalog,
            english: item.english,
            audioKey: item.audioKey,
            showTagalog: showTagalog,
            isTagalogRevealed: revealedTagalogKeys.contains(key),
            onToggleReveal: {
              if !showTagalog { toggleKey(key, in: &revealedTagalogKeys) }
            }
          )
        }
      }
    }
  }

  private func toggleKey(_ key: String, in set: inout Set<String>) {
    if set.contains(key) { set.remove(key) } else { set.insert(key) }
  }
}

private struct ExamplesSection: View {
  let lessonId: String
  let items: [BilingualItem]
  let showTagalog: Bool
  @Binding var revealedTagalogKeys: Set<String>

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Example Sentences")
        .font(.system(.title2, design: .rounded).weight(.heavy))
        .padding(.top, 6)

      VStack(spacing: 12) {
        ForEach(Array(items.enumerated()), id: \.offset) { i, item in
          let key = "\(lessonId)-example-\(i)"
          BilingualRevealCard(
            tagalog: item.tagalog,
            english: item.english,
            audioKey: item.audioKey,
            showTagalog: showTagalog,
            isTagalogRevealed: revealedTagalogKeys.contains(key),
            onToggleReveal: {
              if !showTagalog { toggleKey(key, in: &revealedTagalogKeys) }
            }
          )
        }
      }
    }
  }

  private func toggleKey(_ key: String, in set: inout Set<String>) {
    if set.contains(key) { set.remove(key) } else { set.insert(key) }
  }
}

struct GrammarSection: View {
  @Environment(\.colorScheme) private var colorScheme
  let lessonId: String
  let blocks: [LessonBlock]
  let showTagalog: Bool
  @Binding var revealedTagalogKeys: Set<String>
  var showsHeader: Bool = true
  var appendixKeys: Set<String> = []

  private enum Chunk: Equatable {
    case h1Group([TextBlock])
    case bodyGroup([TextBlock])
    case sentence(key: String, item: BilingualItem)
  }

  private var chunks: [Chunk] {
    var out: [Chunk] = []
    var buf: [TextBlock] = []
    var bufIsH1: Bool?
    var sentenceIndex: Int = 0

    func flush() {
      guard let isH1 = bufIsH1, !buf.isEmpty else { return }
      out.append(isH1 ? .h1Group(buf) : .bodyGroup(buf))
      buf.removeAll(keepingCapacity: true)
      bufIsH1 = nil
    }

    for b in blocks {
      switch b {
      case .text(let tb):
        let isH1 = (tb.type == .h1)
        if let cur = bufIsH1, cur != isH1 { flush() }
        bufIsH1 = isH1
        buf.append(tb)
      case .sentence(let sb):
        flush()
        let key = "\(lessonId)-grammar-sentence-\(sentenceIndex)"
        sentenceIndex += 1
        out.append(.sentence(key: key, item: sb.item))
      }
    }
    flush()
    return out
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      if showsHeader {
        Text("Grammar")
          .font(.system(.title2, design: .rounded).weight(.heavy))
          .padding(.top, 8)
      }

      VStack(alignment: .leading, spacing: 12) {
        ForEach(Array(chunks.enumerated()), id: \.offset) { _, chunk in
          switch chunk {
          case .h1Group(let group):
            GrammarTextGroup(blocks: group, appendixKeys: appendixKeys)
          case .bodyGroup(let group):
            GrammarTextGroup(blocks: group, appendixKeys: appendixKeys)
          case .sentence(let key, let item):
            GrammarEmbeddedRevealCard(
              tagalog: item.tagalog,
              english: item.english,
              audioKey: item.audioKey,
              showTagalog: showTagalog,
              isTagalogRevealed: revealedTagalogKeys.contains(key),
              onToggleReveal: {
                if !showTagalog { toggleKey(key, in: &revealedTagalogKeys) }
              }
            )
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(14)
      .background(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .fill(Theme.cardBackground(colorScheme))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .strokeBorder(Theme.accent.opacity(colorScheme == .dark ? 0.22 : 0.12), lineWidth: 1)
      )
      .shadow(
        color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.06), radius: 10, x: 0, y: 6)
    }
  }

  private func toggleKey(_ key: String, in set: inout Set<String>) {
    if set.contains(key) { set.remove(key) } else { set.insert(key) }
  }
}

private struct GrammarTextGroup: View {
  let blocks: [TextBlock]
  let appendixKeys: Set<String>

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
        switch block.type {
        case .h1:
          InlineMarkdownText(markdown: block.markdown, style: .title1, appendixKeys: appendixKeys)
            .padding(.top, 2)
        case .h2:
          InlineMarkdownText(markdown: block.markdown, style: .title2, appendixKeys: appendixKeys)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            .padding(.top, 6)
        case .h3:
          InlineMarkdownText(markdown: block.markdown, style: .title3, appendixKeys: appendixKeys)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            .padding(.top, 4)
        case .p:
          InlineMarkdownText(
            markdown: block.markdown,
            style: .body,
            appendixKeys: appendixKeys,
            baseColor: .primary.opacity(0.92)
          )
          .lineSpacing(4)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct GrammarEmbeddedRevealCard: View {
  @Environment(\.colorScheme) private var colorScheme
  let tagalog: String
  let english: String
  let audioKey: String?
  let showTagalog: Bool
  let isTagalogRevealed: Bool
  let onToggleReveal: () -> Void

  private var effectiveShowTagalog: Bool { showTagalog || isTagalogRevealed }

  var body: some View {
    HStack(alignment: .top, spacing: 10) {
      VStack(alignment: .leading, spacing: 4) {
        Text(effectiveShowTagalog ? tagalog : "Tap to reveal Tagalog")
          .font(.system(size: 16, weight: .regular, design: .rounded))
          .foregroundStyle(effectiveShowTagalog ? .primary : .secondary)
          .fixedSize(horizontal: false, vertical: true)

        Text(english)
          .font(.system(size: 14, weight: .regular, design: .rounded))
          .foregroundStyle(effectiveShowTagalog ? .secondary : .primary)
          .fixedSize(horizontal: false, vertical: true)
      }

      Spacer(minLength: 4)

      if let audioKey {
        SpeakerButton(audioKey: audioKey)
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Theme.accent.opacity(colorScheme == .dark ? 0.08 : 0.06))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(
          Theme.accent.opacity(colorScheme == .dark ? 0.25 : 0.16),
          lineWidth: 1
        )
    )
    .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .gesture(
      TapGesture().onEnded {
        guard !showTagalog else { return }
        onToggleReveal()
      },
      including: .gesture
    )
  }
}
