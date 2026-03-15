//
//  TuneGeniusApp.swift
//  TuneGenius
//
//  Main app entry point – SwiftData + StoreKit 2 + AVAudioEngine
//

import SwiftUI
import SwiftData

@main
struct TuneGeniusApp: App {

    let modelContainer: ModelContainer
    @State private var storeKit = StoreKitManager()

    init() {
        do {
            let schema = Schema([
                AudioTrack.self,
                LoopMarker.self,
                EffectPreset.self,
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(storeKit)
        }
        .modelContainer(modelContainer)
    }
}
