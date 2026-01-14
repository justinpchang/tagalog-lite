import SwiftUI

struct GlassHeaderBar<Leading: View, Trailing: View>: View {
  @Environment(\.colorScheme) private var colorScheme

  let leading: Leading
  let trailing: Trailing

  init(
    @ViewBuilder leading: () -> Leading,
    @ViewBuilder trailing: () -> Trailing
  ) {
    self.leading = leading()
    self.trailing = trailing()
  }

  var body: some View {
    HStack(alignment: .center, spacing: 12) {
      leading
      Spacer(minLength: 8)
      trailing
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .background(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .fill(.ultraThinMaterial)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 22, style: .continuous)
        .strokeBorder(
          (colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.06)),
          lineWidth: 1
        )
    )
    .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.30 : 0.10), radius: 14, x: 0, y: 10)
  }
}
