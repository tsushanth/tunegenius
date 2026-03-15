//
//  LoopControlView.swift
//  TuneGenius
//
//  Loop region configuration UI
//

import SwiftUI

struct LoopControlView: View {
    @Binding var loopEnabled: Bool
    @Binding var loopStart: Double
    @Binding var loopEnd: Double
    let duration: Double
    let currentTime: Double

    var body: some View {
        VStack(spacing: 18) {

            // Toggle
            HStack {
                Label("Loop Region", systemImage: "repeat")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: $loopEnabled)
                    .tint(.purple)
                    .labelsHidden()
            }

            if duration > 0 {
                // Start
                VStack(spacing: 6) {
                    HStack {
                        Text("Start")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatTime(loopStart))
                            .font(.subheadline.bold())
                            .foregroundColor(.purple)
                            .monospacedDigit()
                        Button("Set to Now") { loopStart = min(currentTime, loopEnd - 0.1) }
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                    Slider(value: $loopStart, in: 0 ... max(0.1, duration - 0.1), step: 0.1)
                        .tint(.purple)
                        .onChange(of: loopStart) { _, newVal in
                            if newVal >= loopEnd { loopEnd = min(newVal + 1, duration) }
                        }
                }

                // End
                VStack(spacing: 6) {
                    HStack {
                        Text("End")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatTime(loopEnd))
                            .font(.subheadline.bold())
                            .foregroundColor(.cyan)
                            .monospacedDigit()
                        Button("Set to Now") { loopEnd = max(currentTime, loopStart + 0.1) }
                            .font(.caption)
                            .foregroundColor(.cyan)
                    }
                    Slider(value: $loopEnd, in: 0.1 ... duration, step: 0.1)
                        .tint(.cyan)
                        .onChange(of: loopEnd) { _, newVal in
                            if newVal <= loopStart { loopStart = max(0, newVal - 1) }
                        }
                }

                // Duration badge
                let loopDur = max(0, loopEnd - loopStart)
                HStack {
                    Text("Loop duration: \(formatTime(loopDur))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Reset") {
                        loopStart = 0
                        loopEnd = duration
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            } else {
                Text("Load a track to set loop points")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .disabled(!loopEnabled && duration > 0)
        .opacity(!loopEnabled && duration > 0 ? 0.5 : 1)
        .animation(.easeInOut, value: loopEnabled)
    }

    private func formatTime(_ t: Double) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        let ms = Int((t.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%01d", m, s, ms)
    }
}
