//
//  AudioTrack.swift
//  TuneGenius
//
//  SwiftData model representing an imported audio track
//

import Foundation
import SwiftData

@Model
final class AudioTrack {
    var id: UUID
    var title: String
    var artist: String
    var duration: TimeInterval
    var fileURL: String          // stored as bookmark data string
    var bookmarkData: Data?
    var dateImported: Date
    var artworkData: Data?
    var fileSize: Int64
    var format: String           // e.g. "mp3", "m4a", "wav"

    // Current session settings (persisted per track)
    var savedPitchSemitones: Double
    var savedPitchCents: Double
    var savedTempoRate: Double
    var savedLoopStart: Double
    var savedLoopEnd: Double
    var savedLoopEnabled: Bool

    init(
        id: UUID = UUID(),
        title: String,
        artist: String = "Unknown Artist",
        duration: TimeInterval = 0,
        fileURL: String = "",
        bookmarkData: Data? = nil,
        dateImported: Date = Date(),
        artworkData: Data? = nil,
        fileSize: Int64 = 0,
        format: String = "m4a"
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.duration = duration
        self.fileURL = fileURL
        self.bookmarkData = bookmarkData
        self.dateImported = dateImported
        self.artworkData = artworkData
        self.fileSize = fileSize
        self.format = format
        self.savedPitchSemitones = 0
        self.savedPitchCents = 0
        self.savedTempoRate = 1.0
        self.savedLoopStart = 0
        self.savedLoopEnd = 0
        self.savedLoopEnabled = false
    }

    var formattedDuration: String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var formattedFileSize: String {
        let mb = Double(fileSize) / 1_048_576
        if mb < 1 { return String(format: "%.0f KB", mb * 1024) }
        return String(format: "%.1f MB", mb)
    }

    /// Resolve a security-scoped bookmark back to a URL
    func resolvedURL() -> URL? {
        if let data = bookmarkData {
            var isStale = false
            return try? URL(
                resolvingBookmarkData: data,
                options: .withoutUI,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        }
        return URL(string: fileURL)
    }
}
