//
//  ContentView.swift
//  TuneGenius
//
//  Root navigation shell
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: AppTab = .library
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "tg_onboarding_done")

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
            } else {
                MainTabView(selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.dark)
    }
}

enum AppTab: String, CaseIterable {
    case library = "Library"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .library:  return "music.note.list"
        case .settings: return "gearshape.fill"
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem { Label("Library", systemImage: "music.note.list") }
                .tag(AppTab.library)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(.purple)
    }
}
