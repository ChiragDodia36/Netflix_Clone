//
//  TMDBService.swift
//  Netflix
//

import Foundation

class TMDBService: ObservableObject {
    static let shared = TMDBService()

    private let baseURL = "https://api.themoviedb.org/3"
    static let posterBase = "https://image.tmdb.org/t/p/w500"
    static let backdropBase = "https://image.tmdb.org/t/p/w1280"

    private var apiKey: String {
        Bundle.main.object(forInfoDictionaryKey: "TMDBAPIKey") as? String ?? ""
    }

    private init() {}

    // MARK: - URL builder

    private func url(_ path: String, params: [String: String] = [:]) -> URL? {
        var components = URLComponents(string: "\(baseURL)\(path)")
        var queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        params.forEach { queryItems.append(URLQueryItem(name: $0.key, value: $0.value)) }
        components?.queryItems = queryItems
        return components?.url
    }

    // MARK: - Generic fetch

    private func fetch<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Endpoints

    func fetchTrending() async throws -> [TMDBMediaItem] {
        guard let url = url("/trending/all/week") else { throw URLError(.badURL) }
        let response: TMDBPageResponse<TMDBMediaItem> = try await fetch(url)
        return response.results
    }

    func fetchPopularMovies() async throws -> [TMDBMediaItem] {
        guard let url = url("/movie/popular") else { throw URLError(.badURL) }
        let response: TMDBPageResponse<TMDBMediaItem> = try await fetch(url)
        return response.results
    }

    func fetchPopularTV() async throws -> [TMDBMediaItem] {
        guard let url = url("/tv/popular") else { throw URLError(.badURL) }
        let response: TMDBPageResponse<TMDBMediaItem> = try await fetch(url)
        return response.results
    }

    func searchMulti(query: String) async throws -> [TMDBMediaItem] {
        guard let url = url("/search/multi", params: ["query": query]) else { throw URLError(.badURL) }
        let response: TMDBPageResponse<TMDBMediaItem> = try await fetch(url)
        return response.results.filter { $0.mediaType == "movie" || $0.mediaType == "tv" }
    }

    func fetchVideos(movieId: Int) async throws -> [TMDBVideo] {
        guard let url = url("/movie/\(movieId)/videos") else { throw URLError(.badURL) }
        let response: TMDBVideoResponse = try await fetch(url)
        return response.results
    }

    func fetchTVVideos(tvId: Int) async throws -> [TMDBVideo] {
        guard let url = url("/tv/\(tvId)/videos") else { throw URLError(.badURL) }
        let response: TMDBVideoResponse = try await fetch(url)
        return response.results
    }

    func fetchMovieRuntime(id: Int) async -> Int? {
        guard id != 0, let url = url("/movie/\(id)") else { return nil }
        let detail: TMDBMovieDetail? = try? await fetch(url)
        return detail?.runtime
    }

    func fetchTVRuntime(id: Int) async -> Int? {
        guard id != 0, let url = url("/tv/\(id)") else { return nil }
        let detail: TMDBTVDetail? = try? await fetch(url)
        return detail?.averageRuntime
    }

    // MARK: - Movie → App model mapping

    func toMovie(_ item: TMDBMediaItem, isTrending: Bool = false, isFeatured: Bool = false) -> Movie {
        let poster = item.posterPath.map { TMDBService.posterBase + $0 } ?? ""
        let backdrop = item.backdropPath.map { TMDBService.backdropBase + $0 } ?? poster
        let genre = TMDBGenreMap.names(for: item.genreIds ?? [], isMovie: item.isMovie)
        let rating = (item.voteAverage ?? 0) > 7 ? (item.isMovie ? "PG-13" : "TV-14") : (item.isMovie ? "R" : "TV-MA")

        return Movie(
            tmdbId: item.id,
            title: item.displayTitle,
            posterURL: poster,
            backdropURL: backdrop,
            releaseYear: item.releaseYear,
            rating: rating,
            duration: item.isMovie ? 110 : 45,
            genre: genre,
            isMovie: item.isMovie,
            isTrending: isTrending,
            isFeatured: isFeatured,
            description: item.overview ?? "Explore the incredible journey in this thrilling new title."
        )
    }
}
