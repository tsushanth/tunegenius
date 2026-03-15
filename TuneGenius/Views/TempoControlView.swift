//
//  TempoControlView.swift
//  TuneGenius
//
//  Tempo (rate) controls with half/double shortcuts
//

import SwiftUI

struct TempoControlView: View {
    @Binding var settings: AudioSettings

    var body: some View {
        VStack(spacing: 20) {

            // Big percentage display
            Text("\(settings.tempoPercentage)%")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing)
                )

            // Slider
            HStack(spacing: 12) {
                StepButton(icon: "minus", tint: .cyan) {
                    settings.tempoRate = TempoChanger.clampedRate(settings.tempoRate - 0.05)
                }
                Slider(value: $settings.tempoRate, in: 0.25 ... 4.0, step: 0.01)
                    .tint(.cyan)
                StepButton(icon: "plus", tint: .cyan) {
                    settings.tempoRate = TempoChanger.clampedRate(settings.tempoRate + 0.05)
                }
            }

            // Description
            Text(settings.tempoDescription)
                .font(.caption.bold())
                .foregroundColor(.cyan)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.cyan.opacity(0.12))
                .clipShape(Capsule())

            // Shortcut buttons
            HStack(spacing: 12) {
                ForEach([0.5, 0.75, 1.0, 1.25, 1.5, 2.0], id: \.self) { rate in
                    Button {
                        withAnimation { settings.tempoRate = rate }
                    } label: {
                        Text("\(Int(rate * 100))%")
                            .font(.caption.bold())
                            .foregroundColor(abs(settings.tempoRate - rate) < 0.01 ? .white : .secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(abs(settings.tempoRate - rate) < 0.01 ? Color.cyan : Color.white.opacity(0.07))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            Button("Reset Tempo") { settings.tempoRate = 1.0 }
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
