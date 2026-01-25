import SwiftUI

struct OnboardingView: View {
  @Environment(\.colorScheme) private var colorScheme
  let onDone: () -> Void

  @State private var index: Int = 0

  var body: some View {
    ZStack {
      Theme.pageGradient.ignoresSafeArea()

      VStack(spacing: 14) {
        Spacer(minLength: 12)

        TabView(selection: $index) {
          OnboardingCard(
            title: "Welcome to Tagalog Lite",
            message: "Learn step-by-step lessons, then reinforce with Practice."
          )
          .tag(0)

          OnboardingCard(
            title: "Learn Tab",
            message: "Read lessons and mark them completed when you finish. Completed lessons unlock their cards for Practice."
          )
          .tag(1)

          OnboardingCard(
            title: "Practice Tab",
            message: "Review flashcards using spaced repetition. Due cards show first, then new ones."
          )
          .tag(2)

          OnboardingCard(
            title: "Extras Tab",
            message: "Find the Intro guides and Appendix references here."
          )
          .tag(3)

          OnboardingCard(
            title: "Quick Tip",
            message: "Tap Appendix links inside lessons to preview them without leaving your place."
          )
          .tag(4)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))

        PageDots(count: 5, index: index)

        controls
      }
      .padding(16)
    }
  }

  private var controls: some View {
    HStack(spacing: 12) {
      Button {
        if index > 0 { index -= 1 }
      } label: {
        Text("Back")
          .font(.system(.headline, design: .rounded).weight(.semibold))
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .fill(Theme.cardBackground(colorScheme))
          )
          .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.10), lineWidth: 1)
          )
      }
      .buttonStyle(.plain)
      .disabled(index == 0)

      Button {
        if index < 4 {
          index += 1
        } else {
          onDone()
        }
      } label: {
        Text(index < 4 ? "Next" : "Get Started")
          .font(.system(.headline, design: .rounded).weight(.bold))
          .foregroundStyle(.primary)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .fill(Theme.accent)
          )
      }
      .buttonStyle(.plain)
    }
  }
}

private struct OnboardingCard: View {
  @Environment(\.colorScheme) private var colorScheme
  let title: String
  let message: String

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.system(size: 26, weight: .heavy, design: .rounded))
        .foregroundStyle(.primary)

      Text(message)
        .font(.system(.title3, design: .rounded))
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(18)
    .background(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .fill(Theme.cardBackground(colorScheme))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 24, style: .continuous)
        .strokeBorder(Theme.accent.opacity(colorScheme == .dark ? 0.30 : 0.18), lineWidth: 1)
    )
    .shadow(color: Color.primary.opacity(colorScheme == .dark ? 0.20 : 0.08), radius: 12, x: 0, y: 8)
  }
}

private struct PageDots: View {
  @Environment(\.colorScheme) private var colorScheme
  let count: Int
  let index: Int

  var body: some View {
    HStack(spacing: 8) {
      ForEach(0..<count, id: \.self) { i in
        Circle()
          .fill(i == index ? Theme.accent : Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.10))
          .frame(width: 8, height: 8)
      }
    }
  }
}

