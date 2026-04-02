//
//  WatchProgress.swift
//  Netflix
//

import Foundation

struct WatchProgress: Codable, Identifiable {
    let id: UUID
    let tmdbId: Int             // matches Movie.tmdbId — primary lookup key
    let profileId: UUID
    var positionSeconds: Double
    var durationSeconds: Double
    var lastWatchedAt: Date
    let movieTitle: String
    let moviePosterURL: String

    var percentComplete: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(positionSeconds / durationSeconds, 1.0)
    }

    /// True when the user has seen 90%+ of the content
    var isComplete: Bool { percentComplete >= 0.9 }

    var minutesRemaining: Int {
        let remaining = max(0, durationSeconds - positionSeconds)
        return Int(remaining / 60)
    }
}
