//
//  WatchProgressService.swift
//  Netflix
//

import Foundation

class WatchProgressService: ObservableObject {
    static let shared = WatchProgressService()

    @Published var progressItems: [WatchProgress] = []

    private let key = "watch_progress_items"

    private init() { load() }

    // MARK: - Queries

    /// Items the user started but hasn't finished (>10s watched, <90% complete)
    func inProgress(for profileId: UUID) -> [WatchProgress] {
        progressItems
            .filter { $0.profileId == profileId && !$0.isComplete && $0.positionSeconds > 10 }
            .sorted { $0.lastWatchedAt > $1.lastWatchedAt }
    }

    /// All watched items for this profile, newest first (viewing history)
    func history(for profileId: UUID) -> [WatchProgress] {
        progressItems
            .filter { $0.profileId == profileId }
            .sorted { $0.lastWatchedAt > $1.lastWatchedAt }
    }

    // MARK: - Write

    func updateProgress(
        tmdbId: Int,
        profileId: UUID,
        title: String,
        posterURL: String,
        position: Double,
        duration: Double
    ) {
        if let idx = progressItems.firstIndex(where: {
            $0.tmdbId == tmdbId && $0.profileId == profileId
        }) {
            progressItems[idx].positionSeconds = position
            // Keep the largest known duration (runtime may arrive after first record)
            if duration > 0 {
                progressItems[idx].durationSeconds = max(progressItems[idx].durationSeconds, duration)
            }
            progressItems[idx].lastWatchedAt = Date()
        } else {
            progressItems.append(WatchProgress(
                id: UUID(),
                tmdbId: tmdbId,
                profileId: profileId,
                positionSeconds: position,
                durationSeconds: duration > 0 ? duration : 5400, // 90 min default
                lastWatchedAt: Date(),
                movieTitle: title,
                moviePosterURL: posterURL
            ))
        }
        save()
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(progressItems) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([WatchProgress].self, from: data)
        else { return }
        progressItems = items
    }
}
