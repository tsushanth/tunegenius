//
//  PlayerView.swift
//  TuneGenius
//
//  Full-screen player with waveform, transport, pitch/tempo, EQ, effects, export
//

import SwiftUI
import SwiftData

struct PlayerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreKitManager.self) private var store

    let track: AudioTrack

    @State private var playerVM = PlayerViewModel()
    @State private var editorVM = EditorViewModel()
    @State private var exporter = AudioExporter()
    @State private var selectedTab: PlayerTab = .pitch
    @State private var showExport = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                TGGradientBackground()
                VStack(spacing: 0) {
                    trackHeader
                    waveformSection
                    transportControls
                    Divider().background(Color.white.opacity(0.1))
                    editorTabBar
                    editorContent
                    Spacer(minLength: 4)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .sheet(isPresented: $showExport) {
                ExportView(track: track, settings: playerVM.settings, exporter: exporter)
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .onAppear {
                playerVM.load(track: track)
                editorVM.settings = playerVM.settings
                playerVM.startLoopMonitor()
            }
            .onDisappear {
                playerVM.engine.pause()
                playerVM.stopLoopMonitor()
                playerVM.saveCurrentSettings(to: track)
                try? context.save()
            }
            .onChange(of: editorVM.settings) { _, newVal in
                playerVM.settings = newVal
            }
        }
    }

    // MARK: - Header
    private var trackHeader: some View {
        HStack(spacing: 14) {
            artworkView
            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var artworkView: some View {
        if let data = track.artworkData, let img = UIImage(data: data) {
            Image(uiImage: img).resizable().scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.purple.opacity(0.25))
                .frame(width: 56, height: 56)
                .overlay(Image(systemName: "music.note").foregroundColor(.purple))
        }
    }

    // MARK: - Waveform
    private var waveformSection: some View {
        WaveformView(
            samples:     playerVM.waveform.samples,
            progress:    playerVM.progress,
            loopStart:   playerVM.loopEnabled ? playerVM.loopStart / max(1, playerVM.engine.duration) : nil,
            loopEnd:     playerVM.loopEnabled ? playerVM.loopEnd   / max(1, playerVM.engine.duration) : nil
        ) { fraction in
            playerVM.seek(to: fraction)
        }
        .frame(height: 80)
        .padding(.horizontal)
        .padding(.bottom, 4)
    }

    // MARK: - Transport
    private var transportControls: some View {
        VStack(spacing: 6) {
            // Progress slider
            VStack(spacing: 2) {
                Slider(value: Binding(
                    get: { playerVM.progress },
                    set: { playerVM.seek(to: $0) }
                ))
                .tint(.purple)
                .padding(.horizontal)
                HStack {
                    Text(playerVM.formattedCurrentTime)
                    Spacer()
                    Text(playerVM.formattedDuration)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }

            // Buttons
            HStack(spacing: 36) {
                Button { playerVM.skipBackward() } label: {
                    Image(systemName: "gobackward.10")
                        .font(.title2).foregroundColor(.white)
                }
                Button { playerVM.playPause() } label: {
                    Image(systemName: playerVM.engine.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(LinearGradient(colors: [.purple, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                Button { playerVM.skipForward() } label: {
                    Image(systemName: "goforward.10")
                        .font(.title2).foregroundColor(.white)
                }
            }
            .padding(.bottom, 10)
        }
    }

    // MARK: - Editor Tab Bar
    enum PlayerTab: String, CaseIterable {
        case pitch   = "Pitch"
        case tempo   = "Tempo"
        case eq      = "EQ"
        case effects = "Effects"
        case loop    = "Loop"

        var icon: String {
            switch self {
            case .pitch:   return "waveform"
            case .tempo:   return "speedometer"
            case .eq:      return "slider.horizontal.3"
            case .effects: return "sparkles"
            case .loop:    return "repeat"
            }
        }
    }

    private var editorTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(PlayerTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedTab = tab }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.icon).font(.caption)
                            Text(tab.rawValue).font(.caption.bold())
                        }
                        .foregroundColor(selectedTab == tab ? .white : .secondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selectedTab == tab ? Color.purple : Color.white.opacity(0.07))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Editor Content
    @ViewBuilder
    private var editorContent: some View {
        ScrollView {
            Group {
                switch selectedTab {
                case .pitch:
                    PitchControlView(settings: $editorVM.settings)
                case .tempo:
                    TempoControlView(settings: $editorVM.settings)
                case .eq:
                    EQControlView(settings: $editorVM.settings, isPremium: store.isPremium) {
                        showPaywall = true
                    }
                case .effects:
                    EffectsView(settings: $editorVM.settings, isPremium: store.isPremium) {
                        showPaywall = true
                    }
                case .loop:
                    LoopControlView(
                        loopEnabled: $playerVM.loopEnabled,
                        loopStart:   $playerVM.loopStart,
                        loopEnd:     $playerVM.loopEnd,
                        duration:    playerVM.engine.duration,
                        currentTime: playerVM.engine.currentTime
                    )
                }
            }
            .padding()
        }
        .frame(maxHeight: 240)
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down").foregroundColor(.white)
            }
        }
        ToolbarItem(placement: .principal) {
            Text("Now Playing")
                .font(.subheadline.bold())
                .foregroundColor(.white)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 14) {
                Button { editorVM.reset() } label: {
                    Image(systemName: "arrow.counterclockwise").foregroundColor(.secondary)
                }
                Button { showExport = true } label: {
                    Image(systemName: "square.and.arrow.up").foregroundColor(.purple)
                }
            }
        }
    }
}
