import SwiftUI

enum Theme {
    static let accent = Color("AccentColor")
    static let tropicalTeal = Color(red: 0.05, green: 0.72, blue: 0.67)
    static let sunnyYellow = Color(red: 0.99, green: 0.86, blue: 0.30)
    static let deepLeaf = Color(red: 0.10, green: 0.55, blue: 0.22)

    static let pageGradient = LinearGradient(
        colors: [
            accent.opacity(0.18),
            tropicalTeal.opacity(0.12),
            sunnyYellow.opacity(0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func cardBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.white
    }
}

struct TropicalCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(Theme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.accent.opacity(colorScheme == .dark ? 0.30 : 0.18), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.25 : 0.10), radius: 10, x: 0, y: 6)
    }
}

extension View {
    func tropicalCard() -> some View {
        modifier(TropicalCardStyle())
    }
}


