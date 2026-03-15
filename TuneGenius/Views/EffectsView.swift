//
//  EffectsView.swift
//  TuneGenius
//
//  EQ + Reverb + Echo controls (premium gated)
//

import SwiftUI

// MARK: - EQ Control
struct EQControlView: View {
    @Binding var settings: AudioSettings
    let isPremium: Bool
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Text("3-Band EQ")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if !isPremium {
                    ProBadge(action: onUpgrade)
                }
            }

            HStack(spacing: 24) {
                EQBand(label: "Bass", value: $settings.bassGain,   color: .orange, locked: !isPremium, onUpgrade: onUpgrade)
                EQBand(label: "Mid",  value: $settings.midGain,    color: .yellow, locked: !isPremium, onUpgrade: onUpgrade)
                EQBand(label: "Treble", value: $settings.trebleGain, color: .cyan, locked: !isPremium, onUpgrade: onUpgrade)
            }

            Button("Reset EQ") {
                settings.bassGain = 0; settings.midGain = 0; settings.trebleGain = 0
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .disabled(!isPremium)
        }
    }
}

struct EQBand: View {
    let label: String
    @Binding var value: Float
    let color: Color
    let locked: Bool
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(gainLabel)
                .font(.caption.bold())
                .foregroundColor(color)
                .monospacedDigit()
            Slider(value: $value, in: -12 ... 12, step: 0.5)
                .tint(color)
                .rotationEffect(.degrees(-90))
                .frame(width: 100, height: 24)
                .rotationEffect(.degrees(90))
                .frame(width: 24, height: 100)
                .disabled(locked)
                .opacity(locked ? 0.4 : 1)
                .overlay(locked ? lockedOverlay : nil)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var gainLabel: String {
        let v = Int(value)
        return v == 0 ? "0 dB" : (v > 0 ? "+\(v) dB" : "\(v) dB")
    }

    @ViewBuilder
    private var lockedOverlay: some View {
        Button(action: onUpgrade) {
            Image(systemName: "lock.fill")
                .foregroundColor(.yellow)
        }
    }
}

// MARK: - Effects (Reverb + Echo)
struct EffectsView: View {
    @Binding var settings: AudioSettings
    let isPremium: Bool
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Reverb
            VStack(spacing: 10) {
                HStack {
                    Label("Reverb", systemImage: "waveform.path.ecg")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(settings.reverbMix * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(.purple)
                    if !isPremium { ProBadge(action: onUpgrade) }
                }
                Slider(value: $settings.reverbMix, in: 0 ... 1)
                    .tint(.purple)
                    .disabled(!isPremium)
                    .opacity(!isPremium ? 0.4 : 1)
            }

            // Echo
            VStack(spacing: 10) {
                HStack {
                    Label("Echo / Delay", systemImage: "arrow.trianglehead.2.counterclockwise.rotate.90")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(settings.echoMix * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                    if !isPremium { ProBadge(action: onUpgrade) }
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text("Delay: \(String(format: "%.2f", settings.echoDelay))s").font(.caption).foregroundColor(.secondary)
                        Slider(value: $settings.echoDelay, in: 0 ... 1)
                            .tint(.orange)
                            .disabled(!isPremium)
                            .opacity(!isPremium ? 0.4 : 1)
                    }
                    VStack(alignment: .leading) {
                        Text("Mix").font(.caption).foregroundColor(.secondary)
                        Slider(value: $settings.echoMix, in: 0 ... 1)
                            .tint(.orange)
                            .disabled(!isPremium)
                            .opacity(!isPremium ? 0.4 : 1)
                    }
                }
            }

            // Master Volume
            VStack(spacing: 8) {
                HStack {
                    Label("Master Volume", systemImage: "speaker.wave.3.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(settings.masterVolume * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
                Slider(value: $settings.masterVolume, in: 0 ... 2)
                    .tint(.green)
            }

            Button("Reset Effects") {
                settings.reverbMix = 0
                settings.echoDelay = 0; settings.echoFeedback = 0; settings.echoMix = 0
                settings.masterVolume = 1
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - Shared Pro Badge
struct ProBadge: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label("PRO", systemImage: "crown.fill")
                .font(.caption2.bold())
                .foregroundColor(.yellow)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.yellow.opacity(0.15))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
