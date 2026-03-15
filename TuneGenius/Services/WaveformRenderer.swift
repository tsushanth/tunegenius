//
//  WaveformRenderer.swift
//  TuneGenius
//
//  Reads an audio file and downsample to an array of normalized amplitude values
//

import Foundation
import AVFoundation

@MainActor
@Observable
final class WaveformRenderer {

    private(set) var samples: [Float] = []
    private(set) var isLoading = false

    func loadWaveform(url: URL, sampleCount: Int = 512) async {
        isLoading = true
        let result = await Task.detached(priority: .userInitiated) {
            Self.extractSamples(url: url, targetCount: sampleCount)
        }.value
        samples = result
        isLoading = false
    }

    private static func extractSamples(url: URL, targetCount: Int) -> [Float] {
        guard let file = try? AVAudioFile(forReading: url) else { return [] }

        let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: file.processingFormat.sampleRate,
            channels: 1,
            interleaved: false
        )!
        let frameCount = AVAudioFrameCount(file.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              (try? file.read(into: buffer)) != nil,
              let channelData = buffer.floatChannelData?[0] else { return [] }

        let total  = Int(buffer.frameLength)
        let stride = max(1, total / targetCount)
        var out: [Float] = []
        out.reserveCapacity(targetCount)

        var i = 0
        while i < total && out.count < targetCount {
            // RMS over the stride window
            var sum: Float = 0
            let end = min(i + stride, total)
            for j in i ..< end { sum += channelData[j] * channelData[j] }
            out.append(sqrt(sum / Float(end - i)))
            i += stride
        }

        // Normalize to 0-1
        if let maxVal = out.max(), maxVal > 0 {
            return out.map { $0 / maxVal }
        }
        return out
    }
}
