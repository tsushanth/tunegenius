//
//  WaveformView.swift
//  TuneGenius
//
//  Canvas-based waveform with playhead and optional loop region overlay
//

import SwiftUI

struct WaveformView: View {
    let samples: [Float]
    let progress: Double
    var loopStart: Double?
    var loopEnd: Double?
    var onSeek: ((Double) -> Void)?

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Loop region highlight
                if let ls = loopStart, let le = loopEnd, le > ls {
                    Rectangle()
                        .fill(Color.purple.opacity(0.18))
                        .frame(
                            width: geo.size.width * CGFloat(le - ls),
                            height: geo.size.height
                        )
                        .offset(x: geo.size.width * CGFloat(ls))
                }

                // Waveform bars
                Canvas { ctx, size in
                    guard !samples.isEmpty else { return }
                    let barWidth = size.width / CGFloat(samples.count)
                    let midY = size.height / 2
                    let playheadX = size.width * progress

                    for (i, sample) in samples.enumerated() {
                        let x = CGFloat(i) * barWidth
                        let barH = CGFloat(sample) * midY * 0.9
                        let rect = CGRect(
                            x: x,
                            y: midY - barH,
                            width: max(barWidth - 0.5, 0.5),
                            height: barH * 2
                        )
                        let color: Color = x <= playheadX ? .purple : .white.opacity(0.3)
                        ctx.fill(Path(roundedRect: rect, cornerRadius: barWidth / 2), with: .color(color))
                    }
                }

                // Playhead line
                Rectangle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 2, height: geo.size.height)
                    .offset(x: geo.size.width * CGFloat(progress) - 1)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let fraction = Double(value.location.x / geo.size.width).clamped(0...1)
                        onSeek?(fraction)
                    }
            )
        }
    }
}

private extension Double {
    func clamped(_ range: ClosedRange<Double>) -> Double {
        min(range.upperBound, max(range.lowerBound, self))
    }
}
