//
//  PlayerViewModel.swift
//  TuneGenius
//
//  Bridges AudioEngineService with the player UI
//

import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class PlayerViewModel {

    // MARK: - Dependencies
    let engine: AudioEngineService
    let waveform: WaveformRenderer
    private(set) var track: AudioTrack?

    // MARK: - Loop state
    var loopEnabled = false
    var loopStart: Double = 0
    var loopEnd: Double   = 0
    private var loopTimer: Timer?

    // MARK: - Settings
    var settings: AudioSettings = .default {
        didSet { engine.apply(settings: settings) }
    }

    // MARK: - Init
    init() {
        self.engine   = AudioEngineService()
        self.waveform = WaveformRenderer()
    }

    // MARK: - Load track
    func load(track: AudioTrack) {
        self.track = track
        guard let url = track.resolvedURL() else { return }
        engine.loadFile(url: url)

        // Restore saved state
        settings.pitchSemitones = track.savedPitchSemitones
        settings.pitchCents     = track.savedPitchCents
        settings.tempoRate      = track.savedTempoRate
        loopStart               = track.savedLoopStart
        loopEnd                 = track.savedLoopEnd
        loopEnabled             = track.savedLoopEnabled

        engine.apply(settings: settings)
        Task { await waveform.loadWaveform(url: url) }
    }

    // MARK: - Transport
    func playPause() {
        if engine.isPlaying { engine.pause() } else { engine.play() }
    }

    func seek(to fraction: Double) {
        engine.seek(to: fraction * engine.duration)
    }

    func skipBackward(seconds: Double = 10) {
        engine.seek(to: max(0, engine.currentTime - seconds))
    }

    func skipForward(seconds: Double = 10) {
        engine.seek(to: min(engine.duration, engine.currentTime + seconds))
    }

    // MARK: - Loop
    func startLoopMonitor() {
        loopTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.checkLoop() }
        }
    }

    func stopLoopMonitor() {
        loopTimer?.invalidate()
        loopTimer = nil
    }

    private func checkLoop() {
        guard loopEnabled, engine.isPlaying else { return }
        if engine.currentTime >= loopEnd && loopEnd > loopStart {
            engine.seek(to: loopStart)
        }
    }

    // MARK: - Save to track
    func saveCurrentSettings(to track: AudioTrack) {
        track.savedPitchSemitones = settings.pitchSemitones
        track.savedPitchCents     = settings.pitchCents
        track.savedTempoRate      = settings.tempoRate
        track.savedLoopStart      = loopStart
        track.savedLoopEnd        = loopEnd
        track.savedLoopEnabled    = loopEnabled
    }

    // MARK: - Convenience computed
    var progress: Double {
        guard engine.duration > 0 else { return 0 }
        return engine.currentTime / engine.duration
    }

    var formattedCurrentTime: String { formatTime(engine.currentTime) }
    var formattedDuration: String    { formatTime(engine.duration) }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }
}
