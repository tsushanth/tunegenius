//
//  LoopMarker.swift
//  TuneGenius
//
//  Loop region model – persisted as SwiftData entity
//

import Foundation
import SwiftData

@Model
final class LoopMarker {
    var id: UUID
    var trackID: UUID
    var label: String
    var startTime: Double      // seconds
    var endTime: Double        // seconds
    var isActive: Bool
    var colorHex: String       // hex string e.g. "#FF5733"
    var dateCreated: Date

    init(
        id: UUID = UUID(),
        trackID: UUID,
        label: String = "Loop",
        startTime: Double,
        endTime: Double,
        isActive: Bool = false,
        colorHex: String = "#5E5CE6",
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.trackID = trackID
        self.label = label
        self.startTime = startTime
        self.endTime = endTime
        self.isActive = isActive
        self.colorHex = colorHex
        self.dateCreated = dateCreated
    }

    var duration: Double { max(0, endTime - startTime) }

    var formattedRange: String {
        "\(formatTime(startTime)) – \(formatTime(endTime))"
    }

    private func formatTime(_ t: Double) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        let ms = Int((t.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%01d", m, s, ms)
    }
}
