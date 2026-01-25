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
    @AppStorage("srsDailyNewLimit") private var srsDailyNewLimit: Int = 20
    @AppStorage("srsDailyReviewLimit") private var srsDailyReviewLimit: Int = 200
    @AppStorage("srsAllowReviewAhead") private var srsAllowReviewAhead: Bool = false
  @EnvironmentObject private var srs: SRSStateStore
  @EnvironmentObject private var completion: LessonCompletionStore

  @State private var showResetSrsConfirm: Bool = false
  @State private var showResetLessonsConfirm: Bool = false

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

                    Section("SRS") {
                        Stepper(value: $srsDailyNewLimit, in: 0...200, step: 5) {
                            HStack {
                                Text("Daily new limit")
                                Spacer()
                                Text("\(srsDailyNewLimit)")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Stepper(value: $srsDailyReviewLimit, in: 0...1000, step: 10) {
                            HStack {
                                Text("Daily review limit")
                                Spacer()
                                Text("\(srsDailyReviewLimit)")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Toggle("Allow review ahead", isOn: $srsAllowReviewAhead)
                    }

                    Section("Danger Zone") {
                        Button(role: .destructive) {
                            showResetSrsConfirm = true
                        } label: {
                            Text("Reset flashcard progress")
                        }
                        .alert("Reset flashcard progress?", isPresented: $showResetSrsConfirm) {
                            Button("Cancel", role: .cancel) {}
                            Button("Reset", role: .destructive) {
                                srs.removeAll()
                            }
                        } message: {
                            Text("This will delete all SRS scheduling data on this device. This cannot be undone.")
                        }

                        Button(role: .destructive) {
                            showResetLessonsConfirm = true
                        } label: {
                            Text("Reset lesson progress")
                        }
                        .alert("Reset lesson progress?", isPresented: $showResetLessonsConfirm) {
                            Button("Cancel", role: .cancel) {}
                            Button("Reset", role: .destructive) {
                                completion.removeAll()
                            }
                        } message: {
                            Text("This will mark all lessons as incomplete on this device. This cannot be undone.")
                        }
                    }

                    Section("Credits") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Tagalog Lite is an original web app by LanguageCrush. This iOS app is an independent adaptation created with permission. All lesson content and audio are © LanguageCrush, used here by consent; all rights in the content remain with LanguageCrush.")
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

