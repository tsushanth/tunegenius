//
//  ExportView.swift
//  TuneGenius
//
//  Export sheet – select format/quality, trigger offline render, share
//

import SwiftUI

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreKitManager.self) private var store

    let track: AudioTrack
    let settings: AudioSettings
    @Bindable var exporter: AudioExporter

    @State private var selectedFormat: ExportFormat = .m4a
    @State private var selectedQuality: ExportQuality = .high
    @State private var exportedURL: URL?
    @State private var showShare = false
    @State private var showPaywall = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                TGGradientBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        trackSummary

                        // Format picker
                        sectionCard(title: "Format") {
                            Picker("Format", selection: $selectedFormat) {
                                ForEach(ExportFormat.allCases, id: \.self) { f in
                                    Text(f.displayName).tag(f)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        // Quality picker (premium)
                        sectionCard(title: "Quality") {
                            VStack(spacing: 10) {
                                ForEach(ExportQuality.allCases, id: \.self) { q in
                                    HStack {
                                        Image(systemName: selectedQuality == q ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(.purple)
                                        Text(q.rawValue)
                                            .foregroundColor(.white)
                                        Spacer()
                                        if q != .standard && !store.isPremium {
                                            ProBadge { showPaywall = true }
                                        }
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if q != .standard && !store.isPremium {
                                            showPaywall = true
                                        } else {
                                            selectedQuality = q
                                        }
                                    }
                                }
                            }
                        }

                        // Settings summary
                        sectionCard(title: "Applied Settings") {
                            VStack(alignment: .leading, spacing: 6) {
                                infoRow("Pitch",  settings.pitchDescription)
                                infoRow("Tempo",  "\(settings.tempoPercentage)%")
                                infoRow("Reverb", "\(Int(settings.reverbMix * 100))%")
                                infoRow("Echo",   "\(Int(settings.echoMix * 100))%")
                            }
                        }

                        // Export button / progress
                        if exporter.isExporting {
                            VStack(spacing: 10) {
                                ProgressView(value: exporter.progress)
                                    .tint(.purple)
                                Text("Exporting \(Int(exporter.progress * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        } else if let url = exportedURL {
                            Button {
                                showShare = true
                            } label: {
                                Label("Share File", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .sheet(isPresented: $showShare) {
                                ShareSheet(items: [url])
                            }
                        } else {
                            Button {
                                Task { await performExport() }
                            } label: {
                                Label("Export Audio", systemImage: "arrow.down.circle.fill")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.purple)
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                        }

                        if let err = errorMessage {
                            Text(err).font(.caption).foregroundColor(.red)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    // MARK: - Export action
    private func performExport() async {
        guard let url = track.resolvedURL() else {
            errorMessage = "Cannot resolve track URL."
            return
        }
        do {
            exportedURL = try await exporter.export(
                sourceURL: url,
                settings: settings,
                format: selectedFormat,
                quality: selectedQuality,
                isPremium: store.isPremium
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers
    private var trackSummary: some View {
        HStack(spacing: 12) {
            Image(systemName: "music.note")
                .font(.title2).foregroundColor(.purple)
                .frame(width: 48, height: 48)
                .background(Color.purple.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading) {
                Text(track.title).font(.headline).foregroundColor(.white).lineLimit(1)
                Text(track.formattedDuration).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.subheadline.bold()).foregroundColor(.secondary)
            content()
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.caption.bold()).foregroundColor(.white)
        }
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
