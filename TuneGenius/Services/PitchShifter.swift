//
//  PitchShifter.swift
//  TuneGenius
//
//  Convenience wrapper for pitch-shift operations
//

import Foundation
import AVFoundation

/// Thin helper that translates semitone/cent values into AVAudioUnitTimePitch parameters
struct PitchShifter {

    // MARK: - Constants
    static let semitoneRange: ClosedRange<Double> = -12 ... 12
    static let centRange: ClosedRange<Double>     = -50 ... 50

    // MARK: - Conversion helpers

    /// Total shift in cents (AVAudioUnitTimePitch.pitch is in cents)
    static func toCents(semitones: Double, cents: Double) -> Float {
        Float(semitones * 100 + cents)
    }

    /// Human-readable label for a cents value
    static func label(semitones: Double, cents: Double) -> String {
        let total = semitones * 100 + cents
        if abs(total) < 1 { return "Original" }
        let sign = total > 0 ? "+" : ""
        if cents == 0 {
            return "\(sign)\(Int(semitones)) st"
        }
        return "\(sign)\(Int(semitones)) st \(Int(cents)) ¢"
    }

    /// Clamps semitones to valid range
    static func clampedSemitones(_ v: Double) -> Double {
        v.clamped(to: semitoneRange)
    }

    /// Clamps cents to valid range
    static func clampedCents(_ v: Double) -> Double {
        v.clamped(to: centRange)
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(range.upperBound, max(range.lowerBound, self))
    }
}
