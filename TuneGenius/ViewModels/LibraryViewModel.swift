//
//  LibraryViewModel.swift
//  TuneGenius
//
//  Manages audio library: import, search, delete
//

import Foundation
import SwiftUI
import SwiftData
import AVFoundation
import MediaPlayer
import UniformTypeIdentifiers

@MainActor
@Observable
final class LibraryViewModel {

    var searchText = ""
    var isImporting = false
    var importError: String?

    // MARK: - Import from Files

    func importFile(url: URL, context: ModelContext) {
        guard url.startAccessingSecurityScopedResource() else {
            importError = "Permission denied for file."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let bookmark = try url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil, relativeTo: nil)
            let asset = AVURLAsset(url: url)
            let meta  = extractMetadata(from: asset)

            let track = AudioTrack(
                title:        meta.title ?? url.deletingPathExtension().lastPathComponent,
                artist:       meta.artist ?? "Unknown Artist",
                duration:     asset.duration.seconds,
                fileURL:      url.absoluteString,
                bookmarkData: bookmark,
                artworkData:  meta.artwork,
                fileSize:     (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).flatMap { Int64($0) } ?? 0,
                format:       url.pathExtension.lowercased()
            )
            context.insert(track)
            try context.save()
        } catch {
            importError = "Import failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Delete track
    func delete(track: AudioTrack, context: ModelContext) {
        context.delete(track)
        try? context.save()
    }

    // MARK: - Metadata extraction
    private struct TrackMeta {
        var title: String?
        var artist: String?
        var artwork: Data?
    }

    private func extractMetadata(from asset: AVURLAsset) -> TrackMeta {
        var meta = TrackMeta()
        for item in asset.commonMetadata {
            switch item.commonKey {
            case .commonKeyTitle:   meta.title   = item.value as? String
            case .commonKeyArtist:  meta.artist  = item.value as? String
            case .commonKeyArtwork:
                if let data = item.value as? Data { meta.artwork = data }
            default: break
            }
        }
        return meta
    }

    // MARK: - Filter tracks
    func filtered(_ tracks: [AudioTrack]) -> [AudioTrack] {
        guard !searchText.isEmpty else { return tracks }
        return tracks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }
}
