import SwiftUI

struct LessonTabView: View {
    let blocks: [LessonBlock]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    switch block {
                    case .text(let tb):
                        TextBlockView(block: tb)
                    case .sentence(let sb):
                        SentenceRow(item: sb.item)
                    }
                }
            }
            .padding(16)
        }
    }
}

private struct TextBlockView: View {
    let block: TextBlock

    var body: some View {
        Group {
            switch block.type {
            case .h1:
                InlineMarkdownText(markdown: block.markdown, style: .title1)
            case .h2:
                InlineMarkdownText(markdown: block.markdown, style: .title2)
            case .h3:
                InlineMarkdownText(markdown: block.markdown, style: .title3)
            case .p:
                InlineMarkdownText(markdown: block.markdown, style: .body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .tropicalCard()
    }
}

private struct SentenceRow: View {
    let item: BilingualItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.tagalog)
                    .font(.system(.headline, design: .rounded))
                Text(item.english)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if let key = item.audioKey {
                PlayButton(audioKey: key)
            }
        }
        .tropicalCard()
    }
}


