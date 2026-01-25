//
//  ContentView.swift
//  tagalog-lite
//
//  Created by Justin Chang on 1/11/26.
//

import SwiftUI

struct ContentView: View {
  @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
  @AppStorage("showOnboardingNow") private var showOnboardingNow: Bool = false

  private var isOnboardingPresented: Binding<Bool> {
    Binding(
      get: { !hasSeenOnboarding || showOnboardingNow },
      set: { newValue in
        if !newValue {
          hasSeenOnboarding = true
          showOnboardingNow = false
        }
      }
    )
  }

  var body: some View {
    TabView {
      LessonListView()
        .tabItem {
          Label("Learn", systemImage: "book.fill")
        }

      PracticeView()
        .tabItem {
          Label("Practice", systemImage: "bolt.fill")
        }

      ExtrasListView()
        .tabItem {
          Label("Extras", systemImage: "square.grid.2x2.fill")
        }

      SettingsView()
        .tabItem {
          Label("Settings", systemImage: "gearshape.fill")
        }
    }
    .sheet(isPresented: isOnboardingPresented) {
      OnboardingView {
        hasSeenOnboarding = true
        showOnboardingNow = false
      }
    }
  }
}

#Preview {
  ContentView()
}
