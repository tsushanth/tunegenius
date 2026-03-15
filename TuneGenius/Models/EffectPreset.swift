//
//  EffectPreset.swift
//  TuneGenius
//
//  Named preset bundling AudioSettings parameters
//

import Foundation
import SwiftData

@Model
final class EffectPreset {
    var id: UUID
    var name: String
    var isBuiltIn: Bool
    var dateCreated: Date

    // Stored as JSON
    private var settingsData: Data

    init(
        id: UUID = UUID(),
        name: String,
        settings: AudioSettings = .default,
        isBuiltIn: Bool = false,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.isBuiltIn = isBuiltIn
        self.dateCreated = dateCreated
        self.settingsData = (try? JSONEncoder().encode(settings)) ?? Data()
    }

    var settings: AudioSettings {
        get { (try? JSONDecoder().decode(AudioSettings.self, from: settingsData)) ?? .default }
        set { settingsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    // MARK: – Factory Presets

    static var builtInPresets: [EffectPreset] {
        [
            EffectPreset(name: "Default", settings: .default, isBuiltIn: true),
            EffectPreset(name: "Chipmunk", settings: {
                var s = AudioSettings()
                s.pitchSemitones = 5
                s.tempoRate = 1.1
                return s
            }(), isBuiltIn: true),
            EffectPreset(name: "Deep Voice", settings: {
                var s = AudioSettings()
                s.pitchSemitones = -4
                s.bassGain = 3
                return s
            }(), isBuiltIn: true),
            EffectPreset(name: "Slow Practice", settings: {
                var s = AudioSettings()
                s.tempoRate = 0.7
                return s
            }(), isBuiltIn: true),
            EffectPreset(name: "Fast Practice", settings: {
                var s = AudioSettings()
                s.tempoRate = 1.3
                return s
            }(), isBuiltIn: true),
            EffectPreset(name: "Concert Hall", settings: {
                var s = AudioSettings()
                s.reverbMix = 0.45
                s.midGain = 2
                return s
            }(), isBuiltIn: true),
            EffectPreset(name: "Echo Chamber", settings: {
                var s = AudioSettings()
                s.echoDelay = 0.3
                s.echoFeedback = 0.4
                s.echoMix = 0.35
                return s
            }(), isBuiltIn: true),
            EffectPreset(name: "Vocal Boost", settings: {
                var s = AudioSettings()
                s.midGain = 4
                s.trebleGain = 2
                s.bassGain = -2
                return s
            }(), isBuiltIn: true),
        ]
    }
}
