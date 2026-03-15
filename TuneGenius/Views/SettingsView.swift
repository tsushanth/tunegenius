//
//  SettingsView.swift
//  TuneGenius
//
//  App settings: premium status, defaults, about
//

import SwiftUI

struct SettingsView: View {
    @Environment(StoreKitManager.self) private var store
    @State private var showPaywall = false
    @State private var defaultTempo: Double = UserDefaults.standard.double(forKey: "tg_default_tempo") == 0 ? 1.0 : UserDefaults.standard.double(forKey: "tg_default_tempo")
    @State private var highQualityWaveform = UserDefaults.standard.bool(forKey: "tg_hq_waveform")

    var body: some View {
        NavigationStack {
            ZStack {
                TGGradientBackground()
                List {
                    // Premium Section
                    Section {
                        if store.isPremium {
                            HStack {
                                Image(systemName: "crown.fill").foregroundColor(.yellow)
                                Text("TuneGenius Pro – Active")
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            }
                        } else {
                            Button { showPaywall = true } label: {
                                HStack {
                                    Image(systemName: "crown.fill").foregroundColor(.yellow)
                                    VStack(alignment: .leading) {
                                        Text("Upgrade to Pro").foregroundColor(.white).font(.headline)
                                        Text("Unlock all features").font(.caption).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(.secondary)
                                }
                            }
                        }

                        Button { Task { await store.restorePurchases() } } label: {
                            Label("Restore Purchases", systemImage: "arrow.counterclockwise")
                                .foregroundColor(.purple)
                        }
                    } header: { Text("Subscription") }

                    // Defaults
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Default Tempo")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(Int(defaultTempo * 100))%")
                                    .foregroundColor(.purple)
                                    .monospacedDigit()
                            }
                            Slider(value: $defaultTempo, in: 0.5 ... 2.0, step: 0.05)
                                .tint(.purple)
                                .onChange(of: defaultTempo) { _, v in
                                    UserDefaults.standard.set(v, forKey: "tg_default_tempo")
                                }
                        }

                        Toggle(isOn: $highQualityWaveform) {
                            Label("High-Quality Waveform", systemImage: "waveform.path.ecg.rectangle.fill")
                                .foregroundColor(.white)
                        }
                        .tint(.purple)
                        .onChange(of: highQualityWaveform) { _, v in
                            UserDefaults.standard.set(v, forKey: "tg_hq_waveform")
                        }
                    } header: { Text("Defaults") }

                    // About
                    Section {
                        LabeledContent("Version", value: appVersion)
                        LabeledContent("Build", value: appBuild)
                        Link(destination: URL(string: "https://tunegenius.app/privacy")!) {
                            Label("Privacy Policy", systemImage: "hand.raised.fill")
                                .foregroundColor(.purple)
                        }
                        Link(destination: URL(string: "https://tunegenius.app/terms")!) {
                            Label("Terms of Service", systemImage: "doc.text.fill")
                                .foregroundColor(.purple)
                        }
                    } header: { Text("About") }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
