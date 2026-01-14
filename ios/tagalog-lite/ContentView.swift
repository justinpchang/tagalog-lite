//
//  ContentView.swift
//  tagalog-lite
//
//  Created by Justin Chang on 1/11/26.
//

import SwiftUI

struct ContentView: View {
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

      SettingsView()
        .tabItem {
          Label("Settings", systemImage: "gearshape.fill")
        }
    }
  }
}

#Preview {
  ContentView()
}
