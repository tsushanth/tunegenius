//
//  AudioSettings.swift
//  TuneGenius
//
//  Value-type holding all real-time processing parameters
//

import Foundation

struct AudioSettings: Equatable, Codable {
    // MARK: – Pitch
    var pitchSemitones: Double = 0      // -12 … +12
    var pitchCents: Double = 0          // -50 … +50

    // MARK: – Tempo
    var tempoRate: Double = 1.0         // 0.25 … 4.0  (1.0 = original speed)

    // MARK: – EQ
    var bassGain: Float = 0             // dB  -12 … +12
    var midGain: Float = 0
    var trebleGain: Float = 0

    // MARK: – Effects
    var reverbMix: Float = 0            // 0 … 1
    var echoDelay: Float = 0            // seconds  0 … 1
    var echoFeedback: Float = 0         // 0 … 1
    var echoMix: Float = 0              // 0 … 1

    // MARK: – Master
    var masterVolume: Float = 1.0       // 0 … 2

    // MARK: – Helpers

    /// Combined pitch shift in cents (semitones * 100 + cents)
    var totalPitchCents: Double {
        pitchSemitones * 100 + pitchCents
    }

    /// AVAudioUnitTimePitch pitch parameter (in cents)
    var avPitch: Float { Float(totalPitchCents) }

    /// AVAudioUnitTimePitch rate parameter
    var avRate: Float { Float(tempoRate) }

    static let `default` = AudioSettings()

    mutating func reset() {
        self = AudioSettings.default
    }
}

// MARK: - Tempo Display Helpers
extension AudioSettings {
    var tempoPercentage: Int { Int(tempoRate * 100) }

    var tempoDescription: String {
        switch tempoRate {
        case ..<0.5:  return "Very Slow"
        case 0.5..<0.75: return "Slow"
        case 0.75..<0.95: return "Slightly Slow"
        case 0.95...1.05: return "Original"
        case 1.05..<1.25: return "Slightly Fast"
        case 1.25..<1.75: return "Fast"
        default: return "Very Fast"
        }
    }

    var pitchDescription: String {
        let total = totalPitchCents
        if abs(total) < 1 { return "Original" }
        let sign = total > 0 ? "+" : ""
        if pitchCents == 0 {
            return "\(sign)\(Int(pitchSemitones)) semitone\(abs(pitchSemitones) == 1 ? "" : "s")"
        }
        return "\(sign)\(Int(pitchSemitones)) st \(Int(pitchCents)) ¢"
    }
}
