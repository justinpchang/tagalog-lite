import SwiftUI

struct VocabTabView: View {
    let items: [BilingualItem]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    VocabCard(item: item)
                }
            }
            .padding(16)
        }
    }
}

private struct VocabCard: View {
    let item: BilingualItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(item.tagalog)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))

                Spacer(minLength: 8)

                HStack(spacing: 8) {
                    RequiredPill(required: item.required)
                    if let key = item.audioKey {
                        PlayButton(audioKey: key)
                    }
                }
            }

            Text(item.english)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .tropicalCard()
    }
}

private struct RequiredPill: View {
    let required: Bool

    var body: some View {
        Text(required ? "required" : "optional")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundStyle(required ? Color.white : Theme.deepLeaf)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule().fill(required ? Theme.deepLeaf : Theme.accent.opacity(0.22))
            )
    }
}


