//
//  WatchPartyModels.swift
//  Netflix
//

import Foundation

struct WatchPartyRoom: Codable, Identifiable {
    let id: UUID
    let roomCode: String
    let hostId: String
    let movieTmdbId: Int
    let movieTitle: String
    let moviePosterUrl: String
    var isActive: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case roomCode = "room_code"
        case hostId = "host_id"
        case movieTmdbId = "movie_tmdb_id"
        case movieTitle = "movie_title"
        case moviePosterUrl = "movie_poster_url"
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}

struct WatchPartyChatMessage: Identifiable {
    let id: UUID
    let profileName: String
    let text: String
    let timestamp: Date
    var isSelf: Bool = false
}

enum WatchPartyError: LocalizedError {
    case roomCreationFailed
    case roomNotFound
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .roomCreationFailed: return "Failed to create watch party room. Check Supabase configuration."
        case .roomNotFound:       return "Room not found or no longer active."
        case .notConfigured:      return "Supabase credentials not configured in Info.plist."
        }
    }
}

enum WatchPartyConnectionState {
    case disconnected, connecting, connected
}
