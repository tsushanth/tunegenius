//
//  PitchControlView.swift
//  TuneGenius
//
//  Semitone + cents pitch controls
//

import SwiftUI

struct PitchControlView: View {
    @Binding var settings: AudioSettings

    var body: some View {
        VStack(spacing: 20) {

            // Semitones
            VStack(spacing: 8) {
                HStack {
                    Text("Semitones")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Text(semitonesLabel)
                        .font(.subheadline.bold())
                        .foregroundColor(.purple)
                        .monospacedDigit()
                }

                HStack(spacing: 12) {
                    StepButton(icon: "minus", tint: .purple) {
                        settings.pitchSemitones = PitchShifter.clampedSemitones(settings.pitchSemitones - 1)
                    }
                    Slider(
                        value: $settings.pitchSemitones,
                        in: -12 ... 12, step: 1
                    )
                    .tint(.purple)
                    StepButton(icon: "plus", tint: .purple) {
                        settings.pitchSemitones = PitchShifter.clampedSemitones(settings.pitchSemitones + 1)
                    }
                }
            }

            // Cents fine-tune
            VStack(spacing: 8) {
                HStack {
                    Text("Fine Tune (cents)")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Text(centsLabel)
                        .font(.subheadline.bold())
                        .foregroundColor(.cyan)
                        .monospacedDigit()
                }
                Slider(
                    value: $settings.pitchCents,
                    in: -50 ... 50, step: 1
                )
                .tint(.cyan)
            }

            // Description pill
            Text(settings.pitchDescription)
                .font(.caption.bold())
                .foregroundColor(.purple)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.15))
                .clipShape(Capsule())

            // Reset button
            Button("Reset Pitch") {
                settings.pitchSemitones = 0
                settings.pitchCents = 0
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    private var semitonesLabel: String {
        let v = Int(settings.pitchSemitones)
        return v == 0 ? "0" : (v > 0 ? "+\(v)" : "\(v)")
    }
    private var centsLabel: String {
        let v = Int(settings.pitchCents)
        return v == 0 ? "0 ¢" : (v > 0 ? "+\(v) ¢" : "\(v) ¢")
    }
}
