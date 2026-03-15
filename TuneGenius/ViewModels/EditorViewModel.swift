//
//  EditorViewModel.swift
//  TuneGenius
//
//  Manages editor state: presets, undo history, export
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class EditorViewModel {

    var settings: AudioSettings = .default
    var selectedPresetName: String = "Default"

    private var history: [AudioSettings] = []
    private let maxHistory = 20

    // MARK: - Preset apply
    func apply(preset: EffectPreset) {
        pushHistory()
        settings = preset.settings
        selectedPresetName = preset.name
    }

    // MARK: - Reset
    func reset() {
        pushHistory()
        settings.reset()
        selectedPresetName = "Default"
    }

    // MARK: - Undo
    func undo() {
        guard let last = history.popLast() else { return }
        settings = last
    }

    var canUndo: Bool { !history.isEmpty }

    private func pushHistory() {
        history.append(settings)
        if history.count > maxHistory { history.removeFirst() }
    }

    // MARK: - Pitch helpers
    func adjustPitch(semitones delta: Double) {
        settings.pitchSemitones = PitchShifter.clampedSemitones(settings.pitchSemitones + delta)
    }

    // MARK: - Tempo helpers
    func adjustTempo(delta: Double) {
        settings.tempoRate = TempoChanger.clampedRate(settings.tempoRate + delta)
    }

    var pitchLabel: String { PitchShifter.label(semitones: settings.pitchSemitones, cents: settings.pitchCents) }
    var tempoLabel: String { TempoChanger.label(for: settings.tempoRate) }
}
