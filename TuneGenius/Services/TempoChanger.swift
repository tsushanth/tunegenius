//
//  TempoChanger.swift
//  TuneGenius
//
//  Convenience wrapper for tempo-change (time-stretching) operations
//

import Foundation

/// Maps UI-friendly tempo percentage/multiplier to AVAudioUnitTimePitch rate parameter
struct TempoChanger {

    static let rateRange: ClosedRange<Double> = 0.25 ... 4.0

    /// Display string for a given rate
    static func label(for rate: Double) -> String {
        let pct = Int(rate * 100)
        switch rate {
        case ..<0.5:        return "\(pct)% – Very Slow"
        case 0.5..<0.75:    return "\(pct)% – Slow"
        case 0.75..<0.95:   return "\(pct)% – Slightly Slow"
        case 0.95...1.05:   return "Original"
        case 1.05..<1.25:   return "\(pct)% – Slightly Fast"
        case 1.25..<1.75:   return "\(pct)% – Fast"
        default:            return "\(pct)% – Very Fast"
        }
    }

    /// BPM string given original BPM and a rate
    static func bpm(original: Double, rate: Double) -> String {
        let result = original * rate
        return String(format: "%.0f BPM", result)
    }

    static func clampedRate(_ v: Double) -> Double {
        min(rateRange.upperBound, max(rateRange.lowerBound, v))
    }

    /// Snap rate to nearest 5% step
    static func snapped(_ v: Double, step: Double = 0.05) -> Double {
        (v / step).rounded() * step
    }
}
