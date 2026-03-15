//
//  AudioEngineService.swift
//  TuneGenius
//
//  Core AVAudioEngine graph – pitch, tempo, EQ, reverb, delay
//

import Foundation
import AVFoundation
import Combine

@MainActor
@Observable
final class AudioEngineService {

    // MARK: – Public State
    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var isEngineReady = false
    private(set) var errorMessage: String?

    // MARK: – Engine Graph
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let timePitchNode = AVAudioUnitTimePitch()
    private let eqNode = AVAudioUnitEQ(numberOfBands: 3)
    private let reverbNode = AVAudioUnitReverb()
    private let delayNode = AVAudioUnitDelay()

    // MARK: – File / Buffer state
    private var audioFile: AVAudioFile?
    private var currentFileURL: URL?
    private var sampleRate: Double = 44100
    private var totalFrames: AVAudioFramePosition = 0
    private var seekFrame: AVAudioFramePosition = 0
    private var pauseFrame: AVAudioFramePosition = 0

    // MARK: – Timer
    private var progressTimer: Timer?

    // MARK: – Settings snapshot
    private(set) var settings = AudioSettings.default

    // MARK: – Init

    init() {
        buildGraph()
        configureAudioSession()
    }

    // MARK: – Graph

    private func buildGraph() {
        engine.attach(playerNode)
        engine.attach(timePitchNode)
        engine.attach(eqNode)
        engine.attach(reverbNode)
        engine.attach(delayNode)

        engine.connect(playerNode,     to: timePitchNode, format: nil)
        engine.connect(timePitchNode,  to: eqNode,        format: nil)
        engine.connect(eqNode,         to: reverbNode,    format: nil)
        engine.connect(reverbNode,     to: delayNode,     format: nil)
        engine.connect(delayNode,      to: engine.mainMixerNode, format: nil)

        configureEQ()
        configureReverb()
        configureDelay()

        do {
            try engine.start()
            isEngineReady = true
        } catch {
            errorMessage = "Audio engine failed to start: \(error.localizedDescription)"
        }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowAirPlay])
            try session.setActive(true)
        } catch {
            errorMessage = "Audio session error: \(error.localizedDescription)"
        }
    }

    private func configureEQ() {
        // Bass ~80 Hz
        eqNode.bands[0].filterType = .lowShelf
        eqNode.bands[0].frequency = 80
        eqNode.bands[0].gain = 0
        eqNode.bands[0].bypass = false

        // Mid ~1 kHz
        eqNode.bands[1].filterType = .parametric
        eqNode.bands[1].frequency = 1000
        eqNode.bands[1].bandwidth = 1.0
        eqNode.bands[1].gain = 0
        eqNode.bands[1].bypass = false

        // Treble ~8 kHz
        eqNode.bands[2].filterType = .highShelf
        eqNode.bands[2].frequency = 8000
        eqNode.bands[2].gain = 0
        eqNode.bands[2].bypass = false
    }

    private func configureReverb() {
        reverbNode.loadFactoryPreset(.mediumHall)
        reverbNode.wetDryMix = 0
    }

    private func configureDelay() {
        delayNode.delayTime = 0
        delayNode.feedback = 0
        delayNode.wetDryMix = 0
    }

    // MARK: – Load File

    func loadFile(url: URL) {
        stop()
        do {
            audioFile = try AVAudioFile(forReading: url)
            currentFileURL = url
            sampleRate = audioFile!.processingFormat.sampleRate
            totalFrames = audioFile!.length
            duration = Double(totalFrames) / sampleRate
            seekFrame = 0
            pauseFrame = 0
            currentTime = 0
            errorMessage = nil
            scheduleFile()
        } catch {
            errorMessage = "Failed to load file: \(error.localizedDescription)"
        }
    }

    private func scheduleFile() {
        guard let file = audioFile else { return }
        playerNode.stop()
        file.framePosition = seekFrame
        playerNode.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handlePlaybackCompletion()
            }
        }
    }

    // MARK: – Transport

    func play() {
        guard isEngineReady, audioFile != nil else { return }
        if !engine.isRunning {
            try? engine.start()
        }
        playerNode.play()
        isPlaying = true
        startProgressTimer()
    }

    func pause() {
        playerNode.pause()
        isPlaying = false
        pauseFrame = currentFrame
        stopProgressTimer()
    }

    func stop() {
        playerNode.stop()
        isPlaying = false
        seekFrame = 0
        pauseFrame = 0
        currentTime = 0
        stopProgressTimer()
        scheduleFile()
    }

    func seek(to time: TimeInterval) {
        let wasPlaying = isPlaying
        if isPlaying { playerNode.pause() }

        seekFrame = AVAudioFramePosition(time * sampleRate)
        seekFrame = max(0, min(seekFrame, totalFrames))
        currentTime = time

        scheduleFile()
        if wasPlaying { playerNode.play() }
    }

    // MARK: – Apply Settings

    func apply(settings: AudioSettings) {
        self.settings = settings

        timePitchNode.pitch = settings.avPitch
        timePitchNode.rate  = settings.avRate
        timePitchNode.overlap = 8.0   // quality

        eqNode.bands[0].gain = settings.bassGain
        eqNode.bands[1].gain = settings.midGain
        eqNode.bands[2].gain = settings.trebleGain

        reverbNode.wetDryMix = settings.reverbMix * 100   // 0–100

        if settings.echoMix > 0 {
            delayNode.delayTime = Double(settings.echoDelay)
            delayNode.feedback  = settings.echoFeedback * 100   // %
            delayNode.wetDryMix = settings.echoMix * 100
        } else {
            delayNode.wetDryMix = 0
        }

        engine.mainMixerNode.outputVolume = settings.masterVolume
    }

    // MARK: – Progress

    private var currentFrame: AVAudioFramePosition {
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
            return pauseFrame
        }
        return seekFrame + playerTime.sampleTime
    }

    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateProgress()
            }
        }
    }

    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }

    private func updateProgress() {
        let frame = currentFrame
        currentTime = Double(frame) / sampleRate
        if currentTime >= duration { handlePlaybackCompletion() }
    }

    private func handlePlaybackCompletion() {
        isPlaying = false
        currentTime = 0
        seekFrame = 0
        pauseFrame = 0
        stopProgressTimer()
        scheduleFile()
    }

    // MARK: – PCM Buffer for waveform

    func readPCMBuffer(url: URL, maxSamples: Int = 2048) -> [Float] {
        guard let file = try? AVAudioFile(forReading: url) else { return [] }
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                   sampleRate: file.processingFormat.sampleRate,
                                   channels: 1, interleaved: false)!
        let frameCount = AVAudioFrameCount(file.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              (try? file.read(into: buffer)) != nil,
              let channelData = buffer.floatChannelData?[0] else { return [] }

        let totalSamples = Int(buffer.frameLength)
        let stride = max(1, totalSamples / maxSamples)
        var result: [Float] = []
        var i = 0
        while i < totalSamples && result.count < maxSamples {
            result.append(abs(channelData[i]))
            i += stride
        }
        return result
    }
}
