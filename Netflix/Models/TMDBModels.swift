//
//  TMDBModels.swift
//  Netflix
//

import Foundation

// MARK: - Paginated response wrapper

struct TMDBPageResponse<T: Codable>: Codable {
    let page: Int
    let results: [T]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

// MARK: - Media item (movies and TV shows share most fields)

struct TMDBMediaItem: Codable, Identifiable {
    let id: Int
    let title: String?           // movies
    let name: String?            // TV shows
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?     // movies
    let firstAirDate: String?    // TV shows
    let voteAverage: Double
    let genreIds: [Int]
    let mediaType: String?       // present in trending/multi results

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case genreIds = "genre_ids"
        case mediaType = "media_type"
    }

    var displayTitle: String { title ?? name ?? "Unknown" }
    var isMovie: Bool { (mediaType == "movie") || (title != nil && mediaType == nil) }

    var releaseYear: Int {
        let dateStr = releaseDate ?? firstAirDate ?? ""
        return Int(dateStr.prefix(4)) ?? 2020
    }
}

// MARK: - Genre

struct TMDBGenre: Codable {
    let id: Int
    let name: String
}

struct TMDBGenreResponse: Codable {
    let genres: [TMDBGenre]
}

// MARK: - Video (trailers)

struct TMDBVideo: Codable, Identifiable {
    let id: String
    let key: String
    let name: String
    let site: String
    let type: String
    let official: Bool

    var youtubeURL: URL? {
        guard site == "YouTube" else { return nil }
        return URL(string: "https://www.youtube.com/watch?v=\(key)")
    }
}

struct TMDBVideoResponse: Codable {
    let id: Int
    let results: [TMDBVideo]
}

// MARK: - Content details (movie runtime + TV episode runtime)

struct TMDBMovieDetail: Codable {
    let id: Int
    let runtime: Int?
    let genres: [TMDBGenre]
    let releaseDate: String?

    enum CodingKeys: String, CodingKey {
        case id, runtime, genres
        case releaseDate = "release_date"
    }
}

struct TMDBTVDetail: Codable {
    let id: Int
    let episodeRunTime: [Int]
    let genres: [TMDBGenre]
    let firstAirDate: String?

    enum CodingKeys: String, CodingKey {
        case id, genres
        case episodeRunTime = "episode_run_time"
        case firstAirDate = "first_air_date"
    }

    var averageRuntime: Int { episodeRunTime.first ?? 45 }
}

// MARK: - Genre ID → name mapping (TMDB standard IDs)

enum TMDBGenreMap {
    static let movies: [Int: String] = [
        28: "Action", 12: "Adventure", 16: "Animation", 35: "Comedy",
        80: "Crime", 99: "Documentary", 18: "Drama", 10751: "Family",
        14: "Fantasy", 36: "History", 27: "Horror", 10402: "Music",
        9648: "Mystery", 10749: "Romance", 878: "Sci-Fi", 10770: "TV Movie",
        53: "Thriller", 10752: "War", 37: "Western"
    ]

    static let tv: [Int: String] = [
        10759: "Action", 16: "Animation", 35: "Comedy", 80: "Crime",
        99: "Documentary", 18: "Drama", 10751: "Family", 10762: "Kids",
        9648: "Mystery", 10763: "News", 10764: "Reality", 10765: "Sci-Fi",
        10766: "Soap", 10767: "Talk", 10768: "War", 37: "Western"
    ]

    static func names(for ids: [Int], isMovie: Bool) -> String {
        let map = isMovie ? movies : tv
        let names = ids.compactMap { map[$0] }.prefix(3)
        return names.isEmpty ? "Drama" : names.joined(separator: ", ")
    }
}
