import SwiftUI

struct LessonTabView: View {
  let blocks: [LessonBlock]

  @Environment(\.colorScheme) private var colorScheme

  private enum Chunk: Equatable {
    case h1Group([TextBlock])
    case bodyGroup([TextBlock])  // includes h2/h3/p together
    case sentence(BilingualItem)
  }

  private var chunks: [Chunk] {
    var out: [Chunk] = []
    var buf: [TextBlock] = []
    var bufIsH1: Bool?

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
        if let cur = bufIsH1, cur != isH1 {
          flush()
        }
        bufIsH1 = isH1
        buf.append(tb)
      case .sentence(let sb):
        flush()
        out.append(.sentence(sb.item))
      }
    }
    flush()
    return out
  }

  var body: some View {
    // NOTE: This view is no longer used in the main lesson flow (we render a single linear
    // scroll in LessonDetailView), but we keep it around for now.
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        ForEach(Array(chunks.enumerated()), id: \.offset) { _, chunk in
          switch chunk {
          case .h1Group(let group):
            H1Card(blocks: group)
          case .bodyGroup(let group):
            BodyCard(blocks: group)
          case .sentence(let item):
            SentenceCard(item: item)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 10)
      .padding(.horizontal, 14)
    }
  }
}

private struct H1Card: View {
  @Environment(\.colorScheme) private var colorScheme
  let blocks: [TextBlock]

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
        switch block.type {
        case .h1:
          InlineMarkdownText(markdown: block.markdown, style: .title1)
            .padding(.top, 2)
        case .h2:
          InlineMarkdownText(markdown: block.markdown, style: .title2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
          .padding(.top, 6)
        case .h3:
          InlineMarkdownText(markdown: block.markdown, style: .title3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
          .padding(.top, 4)
        case .p:
          InlineMarkdownText(markdown: block.markdown, style: .body)
            .foregroundStyle(.primary.opacity(0.92))
            .lineSpacing(4)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14))
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Theme.accent.opacity(colorScheme == .dark ? 0.18 : 0.10))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .strokeBorder(Theme.accent.opacity(colorScheme == .dark ? 0.30 : 0.18), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.22 : 0.08), radius: 10, x: 0, y: 6)
  }
}

private struct BodyCard: View {
  @Environment(\.colorScheme) private var colorScheme
  let blocks: [TextBlock]

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
        switch block.type {
        case .h1:
          // Shouldn't happen (grouping), but fall back gracefully.
          InlineMarkdownText(markdown: block.markdown, style: .title1)
            .padding(.top, 2)
        case .h2:
          InlineMarkdownText(markdown: block.markdown, style: .title2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
          .padding(.top, 6)
        case .h3:
          InlineMarkdownText(markdown: block.markdown, style: .title3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
          .padding(.top, 4)
        case .p:
          InlineMarkdownText(markdown: block.markdown, style: .body)
            .foregroundStyle(.primary.opacity(0.92))
            .lineSpacing(4)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    // Less top/left padding for big text cards to improve readability.
    .padding(EdgeInsets(top: 10, leading: 12, bottom: 12, trailing: 12))
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Theme.cardBackground(colorScheme))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .strokeBorder(Theme.accent.opacity(colorScheme == .dark ? 0.22 : 0.12), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.06), radius: 10, x: 0, y: 6)
  }
}

private struct SentenceCard: View {
  @EnvironmentObject private var audio: AudioPlayerManager
  let item: BilingualItem

  @State private var showError = false
  @State private var errorMessage = ""

  private var key: String? { item.audioKey }
  private var isActive: Bool {
    guard let key else { return false }
    return audio.currentKey == key && audio.isPlaying
  }

  var body: some View {
    Group {
      if let key {
        Button {
          audio.togglePlay(key: key)
          if let msg = audio.lastErrorMessage, !msg.isEmpty {
            errorMessage = msg
            showError = true
          }
        } label: {
          rowContents
        }
        .buttonStyle(.plain)
      } else {
        rowContents
      }
    }
    .alert("Audio", isPresented: $showError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage)
    }
  }
}

extension SentenceCard {
  fileprivate var rowContents: some View {
    HStack(alignment: .top, spacing: 12) {
      VStack(alignment: .leading, spacing: 8) {
        Text(item.tagalog)
          .font(.system(size: 18, weight: .bold, design: .rounded))
        Text(item.english)
          .font(.system(size: 18, weight: .semibold, design: .rounded))
          .foregroundStyle(.primary.opacity(0.9))
      }

      Spacer(minLength: 8)

      if key != nil {
        Image(systemName: isActive ? "pause.fill" : "play.fill")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 34, height: 34)
          .background(Circle().fill(isActive ? Theme.tropicalTeal : Theme.accent))
          .accessibilityHidden(true)
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 14)
    .background(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .fill(Theme.tropicalTeal.opacity(0.10))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18, style: .continuous)
        .strokeBorder(Theme.tropicalTeal.opacity(0.22), lineWidth: 1)
    )
  }
}
