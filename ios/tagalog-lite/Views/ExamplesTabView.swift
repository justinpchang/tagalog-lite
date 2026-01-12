import SwiftUI

struct ExamplesTabView: View {
    let items: [BilingualItem]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    ExampleRow(item: item)
                }
            }
            .padding(16)
        }
    }
}

private struct ExampleRow: View {
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


