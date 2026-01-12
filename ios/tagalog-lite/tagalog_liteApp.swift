//
//  tagalog_liteApp.swift
//  tagalog-lite
//
//  Created by Justin Chang on 1/11/26.
//

import SwiftUI

@main
struct tagalog_liteApp: App {
    @StateObject private var store = LessonStore()
    @StateObject private var audio = AudioPlayerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(audio)
        }
    }
}
