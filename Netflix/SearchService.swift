//
//  SearchService.swift
//  Netflix
//
//  Created by Chirag Dodia on 9/2/25.
//

import Foundation
import Combine

class SearchService: ObservableObject {
    static let shared = SearchService()

    @Published var searchResults: [Movie] = []
    @Published var isSearching = false
    @Published var searchHistory: [String] = []
    @Published var currentFilters = SearchFilters()
    @Published var recentSearches: [String] = []

    var hasActiveFilters: Bool { currentFilters.hasActiveFilters }

    private var searchTask: Task<Void, Never>?

    private init() {
        loadSearchHistory()
    }

    // MARK: - Search

    func search(query: String, filters: SearchFilters = SearchFilters()) {
        currentFilters = filters

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasQuery = !trimmed.isEmpty
        let hasFilters = filters.hasActiveFilters

        guard hasQuery || hasFilters else {
            searchResults = []
            return
        }

        searchTask?.cancel()
        isSearching = true

        searchTask = Task {
            if hasQuery {
                // Live TMDB search
                do {
                    try await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
                    guard !Task.isCancelled else { return }

                    let items = try await TMDBService.shared.searchMulti(query: trimmed)
                    let mapped = items.map { TMDBService.shared.toMovie($0) }
                    let filtered = applyLocalFilters(mapped, filters: filters)
                    let sorted = sortResults(filtered, query: trimmed)

                    await MainActor.run {
                        self.searchResults = sorted
                        self.isSearching = false
                        self.addToSearchHistory(trimmed)
                    }
                } catch {
                    guard !Task.isCancelled else { return }
                    // Fallback to local search on network error
                    let fallback = performLocalSearch(query: trimmed, filters: filters)
                    await MainActor.run {
                        self.searchResults = fallback
                        self.isSearching = false
                    }
                }
            } else {
                // Filter-only: search against all loaded movies
                let allMovies = MovieService.shared.movies
                let filtered = applyLocalFilters(allMovies, filters: filters)
                await MainActor.run {
                    self.searchResults = filtered
                    self.isSearching = false
                }
            }
        }
    }

    // MARK: - Local search (offline fallback / filter-only)

    private func performLocalSearch(query: String, filters: SearchFilters) -> [Movie] {
        let lower = query.lowercased()
        let pool = MovieService.shared.movies.isEmpty
            ? MovieService.shared.fallbackMovies
            : MovieService.shared.movies

        var results = pool.filter { movie in
            let matchesText = movie.title.lowercased().contains(lower) ||
                              movie.description.lowercased().contains(lower) ||
                              movie.genre.lowercased().contains(lower)
            return matchesText && applyLocalFilters([movie], filters: filters).count > 0
        }
        return sortResults(results, query: query)
    }

    private func applyLocalFilters(_ movies: [Movie], filters: SearchFilters) -> [Movie] {
        movies.filter { movie in
            if !filters.selectedGenres.isEmpty {
                let movieGenres = movie.genre.lowercased().components(separatedBy: ", ")
                let match = filters.selectedGenres.contains { sel in
                    movieGenres.contains { $0.contains(sel.lowercased()) }
                }
                if !match { return false }
            }
            if filters.contentType != .all {
                if filters.contentType == .movies && !movie.isMovie { return false }
                if filters.contentType == .tvShows && movie.isMovie { return false }
            }
            if !filters.selectedRatings.isEmpty, !filters.selectedRatings.contains(movie.rating) { return false }
            if let min = filters.minYear, movie.releaseYear < min { return false }
            if let max = filters.maxYear, movie.releaseYear > max { return false }
            if let min = filters.minDuration, movie.duration < min { return false }
            if let max = filters.maxDuration, movie.duration > max { return false }
            return true
        }
    }

    private func sortResults(_ movies: [Movie], query: String) -> [Movie] {
        let q = query.lowercased()
        return movies.sorted { a, b in
            let aExact = a.title.lowercased() == q
            let bExact = b.title.lowercased() == q
            if aExact != bExact { return aExact }

            let aStart = a.title.lowercased().hasPrefix(q)
            let bStart = b.title.lowercased().hasPrefix(q)
            if aStart != bStart { return aStart }

            if a.isTrending != b.isTrending { return a.isTrending }
            if a.isFeatured != b.isFeatured { return a.isFeatured }
            return a.releaseYear > b.releaseYear
        }
    }

    // MARK: - Search History

    private func addToSearchHistory(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        searchHistory.removeAll { $0.lowercased() == trimmed.lowercased() }
        searchHistory.insert(trimmed, at: 0)
        if searchHistory.count > 20 { searchHistory = Array(searchHistory.prefix(20)) }
        recentSearches = Array(searchHistory.prefix(5))
        saveSearchHistory()
    }

    func clearSearchHistory() {
        searchHistory = []
        recentSearches = []
        saveSearchHistory()
    }

    func removeFromSearchHistory(_ query: String) {
        searchHistory.removeAll { $0.lowercased() == query.lowercased() }
        recentSearches = Array(searchHistory.prefix(5))
        saveSearchHistory()
    }

    private func saveSearchHistory() {
        UserDefaults.standard.set(searchHistory, forKey: "search_history")
    }

    private func loadSearchHistory() {
        if let saved = UserDefaults.standard.array(forKey: "search_history") as? [String] {
            searchHistory = saved
            recentSearches = Array(searchHistory.prefix(5))
        }
    }

    // MARK: - Quick helpers (used by other views)

    func getTrendingMovies() -> [Movie] { MovieService.shared.trendingMovies }
    func getFeaturedMovies() -> [Movie] { MovieService.shared.movies.filter { $0.isFeatured } }
    func getMoviesByGenre(_ genre: String) -> [Movie] {
        MovieService.shared.movies.filter { $0.genre.lowercased().contains(genre.lowercased()) }
    }
    func getMoviesByYear(_ year: Int) -> [Movie] {
        MovieService.shared.movies.filter { $0.releaseYear == year }
    }
    func getMoviesByRating(_ rating: String) -> [Movie] {
        MovieService.shared.movies.filter { $0.rating == rating }
    }
}

// MARK: - Search Filters

struct SearchFilters {
    var selectedGenres: [String] = []
    var contentType: ContentType = .all
    var selectedRatings: [String] = []
    var minYear: Int?
    var maxYear: Int?
    var minDuration: Int?
    var maxDuration: Int?

    var hasActiveFilters: Bool {
        !selectedGenres.isEmpty || contentType != .all || !selectedRatings.isEmpty ||
        minYear != nil || maxYear != nil || minDuration != nil || maxDuration != nil
    }

    mutating func reset() {
        selectedGenres = []; contentType = .all; selectedRatings = []
        minYear = nil; maxYear = nil; minDuration = nil; maxDuration = nil
    }
}

enum ContentType: String, CaseIterable {
    case all = "All"
    case movies = "Movies"
    case tvShows = "TV Shows"
}

extension SearchService {
    static let availableGenres = [
        "Action", "Comedy", "Drama", "Horror", "Sci-Fi",
        "Romance", "Thriller", "Fantasy", "Adventure", "Crime"
    ]
    static let availableRatings = ["G", "PG", "PG-13", "R", "TV-G", "TV-PG", "TV-14", "TV-MA"]
    static let yearRange = 1950...2024
    static let durationRange = 30...300
}
