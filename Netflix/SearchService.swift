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
    
    var hasActiveFilters: Bool {
        return currentFilters.hasActiveFilters
    }
    
    // private let movieService = MovieService.shared
    private var searchCancellable: AnyCancellable?
    
    // Sample movies for demo
    private let sampleMovies: [Movie] = [
        Movie(
            title: "Stranger Things",
            posterURL: "https://image.tmdb.org/t/p/w500/49WJfeN0moxb9IPfGn8AIqMGskD.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/56v2KjBlU4XaOv9rVYEQypROD7P.jpg",
            releaseYear: 2016,
            rating: "TV-14",
            duration: 50,
            genre: "Sci-Fi, Horror",
            isMovie: false,
            isTrending: true,
            isFeatured: true,
            description: "When a young boy vanishes, a small town uncovers a mystery involving secret experiments, terrifying supernatural forces, and one strange little girl."
        ),
        Movie(
            title: "The Crown",
            posterURL: "https://image.tmdb.org/t/p/w500/1M876Kj8FgGzfSJkXhgdXz5QrZ5.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/1M876Kj8FgGzfSJkXhgdXz5QrZ5.jpg",
            releaseYear: 2016,
            rating: "TV-MA",
            duration: 60,
            genre: "Drama, History",
            isMovie: false,
            isTrending: true,
            isFeatured: false,
            description: "Follows the political rivalries and romance of Queen Elizabeth II's reign and the events that shaped the second half of the 20th century."
        ),
        Movie(
            title: "Ozark",
            posterURL: "https://image.tmdb.org/t/p/w500/mi4y7l7s7f0G4VZ9U2K9Q9Q9Q9Q9.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/mi4y7l7s7f0G4VZ9U2K9Q9Q9Q9Q9.jpg",
            releaseYear: 2017,
            rating: "TV-MA",
            duration: 60,
            genre: "Crime, Drama, Thriller",
            isMovie: false,
            isTrending: true,
            isFeatured: false,
            description: "A financial advisor drags his family from Chicago to the Missouri Ozarks, where he must launder money to appease a Mexican drug cartel."
        ),
        Movie(
            title: "The Witcher",
            posterURL: "https://image.tmdb.org/t/p/w500/7vjaCdMw15FEbXyLQTVa04URsPm.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/7vjaCdMw15FEbXyLQTVa04URsPm.jpg",
            releaseYear: 2019,
            rating: "TV-MA",
            duration: 60,
            genre: "Action, Adventure, Drama",
            isMovie: false,
            isTrending: true,
            isFeatured: false,
            description: "Geralt of Rivia, a solitary monster hunter, struggles to find his place in a world where people often prove more wicked than beasts."
        ),
        Movie(
            title: "Bridgerton",
            posterURL: "https://image.tmdb.org/t/p/w500/ke0xV7s7k9V9Q9Q9Q9Q9Q9Q9Q9Q9.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/ke0xV7s7k9V9Q9Q9Q9Q9Q9Q9Q9Q9.jpg",
            releaseYear: 2020,
            rating: "TV-MA",
            duration: 60,
            genre: "Drama, Romance",
            isMovie: false,
            isTrending: true,
            isFeatured: false,
            description: "Wealth, lust, and betrayal set in the backdrop of Regency era England, seen through the eyes of the powerful Bridgerton family."
        ),
        Movie(
            title: "Extraction",
            posterURL: "https://image.tmdb.org/t/p/w500/7W0G3YECgDAfnui7UOqOuR0zH4h.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/7W0G3YECgDAfnui7UOqOuR0zH4h.jpg",
            releaseYear: 2020,
            rating: "R",
            duration: 116,
            genre: "Action, Thriller",
            isMovie: true,
            isTrending: false,
            isFeatured: true,
            description: "A hardened mercenary's mission becomes a soul-searing race to survive and protect one boy's innocence against overwhelming odds."
        ),
        Movie(
            title: "The Queen's Gambit",
            posterURL: "https://image.tmdb.org/t/p/w500/zU0htwkhNvBQdVSIKB9s6hgVeFK.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/zU0htwkhNvBQdVSIKB9s6hgVeFK.jpg",
            releaseYear: 2020,
            rating: "TV-MA",
            duration: 60,
            genre: "Drama",
            isMovie: false,
            isTrending: true,
            isFeatured: false,
            description: "In a 1950s orphanage, a young girl reveals an astonishing talent for chess and begins an unlikely journey to stardom while grappling with addiction."
        ),
        Movie(
            title: "Money Heist",
            posterURL: "https://image.tmdb.org/t/p/w500/reEMJA1uzscCbkpeRJeTT2bjqUp.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/reEMJA1uzscCbkpeRJeTT2bjqUp.jpg",
            releaseYear: 2017,
            rating: "TV-MA",
            duration: 70,
            genre: "Crime, Drama, Thriller",
            isMovie: false,
            isTrending: true,
            isFeatured: false,
            description: "An unusual group of robbers attempt to carry out the most perfect robbery in Spanish history - stealing 2.4 billion euros from the Royal Mint of Spain."
        )
    ]
    
    private init() {
        loadSearchHistory()
    }
    
    // MARK: - Search Methods
    
    func search(query: String, filters: SearchFilters = SearchFilters()) {
        // Store current filters
        currentFilters = filters
        
        // Allow filtering even without a search query
        let hasQuery = !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasFilters = filters.hasActiveFilters
        
        guard hasQuery || hasFilters else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        // Simulate network delay for realistic search experience
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.performSearch(query: query, filters: filters)
        }
    }
    
    private func performSearch(query: String, filters: SearchFilters) {
        let lowercaseQuery = query.lowercased()
        let hasQuery = !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        // Filter movies based on search query and filters
        var filteredMovies = sampleMovies.filter { movie in
            // Text search (only if there's a query)
            let matchesText = hasQuery ? (
                movie.title.lowercased().contains(lowercaseQuery) ||
                movie.description.lowercased().contains(lowercaseQuery) ||
                movie.genre.lowercased().contains(lowercaseQuery)
            ) : true
            
            // Apply filters
            let matchesFilters = applyFilters(movie: movie, filters: filters)
            
            return matchesText && matchesFilters
        }
        
        // Sort results by relevance
        filteredMovies = sortSearchResults(filteredMovies, query: query)
        
        searchResults = filteredMovies
        isSearching = false
        
        // Add to search history
        addToSearchHistory(query)
    }
    
    private func applyFilters(movie: Movie, filters: SearchFilters) -> Bool {
        // Genre filter
        if !filters.selectedGenres.isEmpty {
            let movieGenres = movie.genre.lowercased().components(separatedBy: ", ")
            let hasMatchingGenre = filters.selectedGenres.contains { selectedGenre in
                movieGenres.contains { movieGenre in
                    movieGenre.contains(selectedGenre.lowercased())
                }
            }
            if !hasMatchingGenre { return false }
        }
        
        // Content type filter
        if filters.contentType != .all {
            switch filters.contentType {
            case .movies:
                if !movie.isMovie { return false }
            case .tvShows:
                if movie.isMovie { return false }
            case .all:
                break
            }
        }
        
        // Rating filter
        if !filters.selectedRatings.isEmpty {
            if !filters.selectedRatings.contains(movie.rating) { return false }
        }
        
        // Year range filter
        if let minYear = filters.minYear {
            if movie.releaseYear < minYear { return false }
        }
        if let maxYear = filters.maxYear {
            if movie.releaseYear > maxYear { return false }
        }
        
        // Duration filter
        if let minDuration = filters.minDuration {
            if movie.duration < minDuration { return false }
        }
        if let maxDuration = filters.maxDuration {
            if movie.duration > maxDuration { return false }
        }
        
        
        return true
    }
    
    private func sortSearchResults(_ movies: [Movie], query: String) -> [Movie] {
        return movies.sorted { movie1, movie2 in
            let queryLower = query.lowercased()
            
            // Exact title match gets highest priority
            let title1Exact = movie1.title.lowercased() == queryLower
            let title2Exact = movie2.title.lowercased() == queryLower
            
            if title1Exact && !title2Exact { return true }
            if !title1Exact && title2Exact { return false }
            
            // Title starts with query gets second priority
            let title1Starts = movie1.title.lowercased().hasPrefix(queryLower)
            let title2Starts = movie2.title.lowercased().hasPrefix(queryLower)
            
            if title1Starts && !title2Starts { return true }
            if !title1Starts && title2Starts { return false }
            
            // Trending content gets priority
            if movie1.isTrending && !movie2.isTrending { return true }
            if !movie1.isTrending && movie2.isTrending { return false }
            
            // Featured content gets priority
            if movie1.isFeatured && !movie2.isFeatured { return true }
            if !movie1.isFeatured && movie2.isFeatured { return false }
            
            // Sort by release year (newer first)
            return movie1.releaseYear > movie2.releaseYear
        }
    }
    
    // MARK: - Search History Management
    
    private func addToSearchHistory(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        // Remove if already exists
        searchHistory.removeAll { $0.lowercased() == trimmedQuery.lowercased() }
        
        // Add to beginning
        searchHistory.insert(trimmedQuery, at: 0)
        
        // Keep only last 20 searches
        if searchHistory.count > 20 {
            searchHistory = Array(searchHistory.prefix(20))
        }
        
        // Update recent searches (last 5)
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
    
    // MARK: - Persistence
    
    private func saveSearchHistory() {
        UserDefaults.standard.set(searchHistory, forKey: "search_history")
    }
    
    private func loadSearchHistory() {
        if let savedHistory = UserDefaults.standard.array(forKey: "search_history") as? [String] {
            searchHistory = savedHistory
            recentSearches = Array(searchHistory.prefix(5))
        }
    }
    
    // MARK: - Quick Search Methods
    
    func getTrendingMovies() -> [Movie] {
        return sampleMovies.filter { $0.isTrending }
    }
    
    func getFeaturedMovies() -> [Movie] {
        return sampleMovies.filter { $0.isFeatured }
    }
    
    func getMoviesByGenre(_ genre: String) -> [Movie] {
        return sampleMovies.filter { movie in
            movie.genre.lowercased().contains(genre.lowercased())
        }
    }
    
    func getMoviesByYear(_ year: Int) -> [Movie] {
        return sampleMovies.filter { $0.releaseYear == year }
    }
    
    func getMoviesByRating(_ rating: String) -> [Movie] {
        return sampleMovies.filter { $0.rating == rating }
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
        return !selectedGenres.isEmpty ||
               contentType != .all ||
               !selectedRatings.isEmpty ||
               minYear != nil ||
               maxYear != nil ||
               minDuration != nil ||
               maxDuration != nil
    }
    
    mutating func reset() {
        selectedGenres = []
        contentType = .all
        selectedRatings = []
        minYear = nil
        maxYear = nil
        minDuration = nil
        maxDuration = nil
    }
}

enum ContentType: String, CaseIterable {
    case all = "All"
    case movies = "Movies"
    case tvShows = "TV Shows"
}

// MARK: - Available Filter Options

extension SearchService {
    static let availableGenres = [
        "Action", "Comedy", "Drama", "Horror", "Sci-Fi", 
        "Romance", "Thriller", "Fantasy", "Adventure", "Crime"
    ]
    
    static let availableRatings = [
        "G", "PG", "PG-13", "R", "TV-G", "TV-PG", "TV-14", "TV-MA"
    ]
    
    static let yearRange = 1950...2024
    static let durationRange = 30...300 // minutes
}
