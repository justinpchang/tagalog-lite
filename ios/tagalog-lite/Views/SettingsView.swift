import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue

    private var selectedTheme: Binding<AppTheme> {
        Binding(
            get: { AppTheme(rawValue: appThemeRaw) ?? .system },
            set: { appThemeRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.pageGradient.ignoresSafeArea()

                List {
                    Section("Appearance") {
                        Picker("Theme", selection: selectedTheme) {
                            ForEach(AppTheme.allCases) { t in
                                Text(t.title).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Section("Credits") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Course content and audio are from Tagalog Lite (LanguageCrush).")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 10) {
                                Link("languagecrush.com", destination: URL(string: "https://languagecrush.com")!)
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text("Tagalog Lite")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.system(.subheadline, design: .rounded))
                        }
                        .padding(.vertical, 6)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

