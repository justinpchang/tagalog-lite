import SwiftUI

struct PracticeView: View {
    var body: some View {
        ZStack {
            Theme.pageGradient.ignoresSafeArea()

            VStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(Theme.accent)

                Text("Practice")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))

                Text("Coming soon.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .tropicalCard()
            .padding(16)
        }
    }
}

