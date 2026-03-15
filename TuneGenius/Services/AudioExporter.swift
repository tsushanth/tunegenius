//
//  AudioExporter.swift
//  TuneGenius
//
//  Offline render of the processed audio to a new file
//

import Foundation
import AVFoundation

enum ExportFormat: String, CaseIterable {
    case m4a = "m4a"
    case wav  = "wav"
    case aiff = "aiff"

    var fileType: AVFileType {
        switch self {
        case .m4a:  return .m4a
        case .wav:  return .wav
        case .aiff: return .aiff
        }
    }

    var displayName: String { rawValue.uppercased() }
}

enum ExportQuality: String, CaseIterable {
    case standard = "Standard (128 kbps)"
    case high     = "High (256 kbps)"
    case lossless = "Lossless (WAV)"

    var bitRate: Int {
        switch self {
        case .standard: return 128_000
        case .high:     return 256_000
        case .lossless: return 0
        }
    }
}

@MainActor
@Observable
final class AudioExporter {

    private(set) var isExporting = false
    private(set) var progress: Double = 0
    private(set) var errorMessage: String?

    /// Export a source URL with the given AudioSettings applied, writing to a temp file.
    func export(
        sourceURL: URL,
        settings: AudioSettings,
        format: ExportFormat = .m4a,
        quality: ExportQuality = .high,
        isPremium: Bool = false
    ) async throws -> URL {

        isExporting = true
        progress = 0
        errorMessage = nil
        defer { isExporting = false }

        // If not premium, cap to standard quality
        let effectiveQuality = isPremium ? quality : .standard
        let effectiveFormat  = isPremium ? format  : .m4a

        let outputURL = FileManager.default
            .temporaryDirectory
            .appendingPathComponent("tunegenius_export_\(UUID().uuidString).\(effectiveFormat.rawValue)")

        // Build an offline engine
        let engine       = AVAudioEngine()
        let playerNode   = AVAudioPlayerNode()
        let timePitch    = AVAudioUnitTimePitch()
        let eq           = AVAudioUnitEQ(numberOfBands: 3)
        let reverb        = AVAudioUnitReverb()
        let delay        = AVAudioUnitDelay()

        engine.attach(playerNode)
        engine.attach(timePitch)
        engine.attach(eq)
        engine.attach(reverb)
        engine.attach(delay)
        engine.connect(playerNode, to: timePitch, format: nil)
        engine.connect(timePitch,  to: eq,        format: nil)
        engine.connect(eq,         to: reverb,     format: nil)
        engine.connect(reverb,      to: delay,     format: nil)
        engine.connect(delay,      to: engine.mainMixerNode, format: nil)

        // Apply settings
        timePitch.pitch   = settings.avPitch
        timePitch.rate    = settings.avRate
        timePitch.overlap = 8.0
        eq.bands[0].filterType = .lowShelf;  eq.bands[0].frequency = 80;   eq.bands[0].gain = settings.bassGain;   eq.bands[0].bypass = false
        eq.bands[1].filterType = .parametric; eq.bands[1].frequency = 1000; eq.bands[1].bandwidth = 1; eq.bands[1].gain = settings.midGain; eq.bands[1].bypass = false
        eq.bands[2].filterType = .highShelf; eq.bands[2].frequency = 8000; eq.bands[2].gain = settings.trebleGain; eq.bands[2].bypass = false
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix  = settings.reverbMix * 100
        delay.delayTime   = Double(settings.echoDelay)
        delay.feedback    = settings.echoFeedback * 100
        delay.wetDryMix   = settings.echoMix * 100
        engine.mainMixerNode.outputVolume = settings.masterVolume

        let file = try AVAudioFile(forReading: sourceURL)
        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)

        try engine.enableManualRenderingMode(
            .offline,
            format: outputFormat,
            maximumFrameCount: 4096
        )
        try engine.start()

        playerNode.scheduleFile(file, at: nil)
        playerNode.play()

        // AVAudioFile for writing
        var settingsDict: [String: Any] = [
            AVFormatIDKey: effectiveFormat == .wav ? kAudioFormatLinearPCM : kAudioFormatMPEG4AAC,
            AVSampleRateKey: outputFormat.sampleRate,
            AVNumberOfChannelsKey: outputFormat.channelCount
        ]
        if effectiveQuality != .lossless {
            settingsDict[AVEncoderBitRateKey] = effectiveQuality.bitRate
        }
        let outputFile = try AVAudioFile(forWriting: outputURL, settings: settingsDict)
        let totalFrames = file.length
        var renderedFrames: AVAudioFramePosition = 0

        let buffer = AVAudioPCMBuffer(
            pcmFormat: engine.manualRenderingFormat,
            frameCapacity: 4096
        )!

        while engine.manualRenderingSampleTime < totalFrames {
            let framesToRender = AVAudioFrameCount(
                min(AVAudioFramePosition(buffer.frameCapacity),
                    totalFrames - engine.manualRenderingSampleTime)
            )
            let status = try engine.renderOffline(framesToRender, to: buffer)
            switch status {
            case .success:
                try outputFile.write(from: buffer)
                renderedFrames += AVAudioFramePosition(framesToRender)
                await MainActor.run {
                    self.progress = Double(renderedFrames) / Double(totalFrames)
                }
            case .error:
                throw NSError(domain: "TGExport", code: -1, userInfo: [NSLocalizedDescriptionKey: "Render error"])
            case .cannotDoInCurrentContext, .insufficientDataFromInputNode:
                break
            @unknown default: break
            }
        }

        engine.stop()
        engine.disableManualRenderingMode()
        progress = 1.0
        return outputURL
    }
}
