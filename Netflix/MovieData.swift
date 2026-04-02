//
//  MovieData.swift
//  Netflix
//
//  Created by Chirag Dodia on 9/2/25.
//

import Foundation

struct Movie: Identifiable {
    let id = UUID()
    let tmdbId: Int          // 0 for hardcoded fallback items
    let title: String
    let posterURL: String
    let backdropURL: String
    let releaseYear: Int
    let rating: String
    let duration: Int
    let genre: String
    let isMovie: Bool
    let isTrending: Bool
    let isFeatured: Bool
    let description: String
}

// MARK: - MovieService

class MovieService: ObservableObject {
    static let shared = MovieService()

    @Published var movies: [Movie] = []
    @Published var trendingMovies: [Movie] = []
    @Published var popularMovies: [Movie] = []
    @Published var popularTV: [Movie] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {
        Task {
            await fetchFromTMDB()
        }
    }

    // MARK: - TMDB fetch

    func fetchFromTMDB() async {
        await MainActor.run { isLoading = true; errorMessage = nil }

        do {
            async let trending = TMDBService.shared.fetchTrending()
            async let popularM = TMDBService.shared.fetchPopularMovies()
            async let popularT = TMDBService.shared.fetchPopularTV()

            let (trendingItems, moviesItems, tvItems) = try await (trending, popularM, popularT)

            let mappedTrending = trendingItems.prefix(10).enumerated().map { idx, item in
                TMDBService.shared.toMovie(item, isTrending: true, isFeatured: idx == 0)
            }
            let mappedMovies = moviesItems.prefix(20).map { TMDBService.shared.toMovie($0) }
            let mappedTV = tvItems.prefix(20).map { TMDBService.shared.toMovie($0) }

            let all = Array(mappedTrending) + mappedMovies + mappedTV

            await MainActor.run {
                self.trendingMovies = Array(mappedTrending)
                self.popularMovies = mappedMovies
                self.popularTV = mappedTV
                self.movies = all
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.movies = self.fallbackMovies
                self.trendingMovies = self.fallbackMovies.filter { $0.isTrending }
                self.popularMovies = self.fallbackMovies.filter { $0.isMovie }
                self.popularTV = self.fallbackMovies.filter { !$0.isMovie }
                self.isLoading = false
                self.errorMessage = "Offline mode — showing sample content"
            }
        }
    }

    func refreshMovies() {
        Task { await fetchFromTMDB() }
    }

    // MARK: - Fallback (offline)

    let fallbackMovies: [Movie] = [
        Movie(tmdbId: 0, title: "Stranger Things",
              posterURL: "https://image.tmdb.org/t/p/w500/49WJfeN0moxb9IPfGn8AIqMGskD.jpg",
              backdropURL: "https://image.tmdb.org/t/p/w1280/56v2KjBlU4XaOv9rVYEQypROD7P.jpg",
              releaseYear: 2016, rating: "TV-14", duration: 50, genre: "Sci-Fi, Horror",
              isMovie: false, isTrending: true, isFeatured: true,
              description: "When a young boy vanishes, a small town uncovers a mystery involving secret experiments, terrifying supernatural forces, and one strange little girl."),
        Movie(tmdbId: 0, title: "The Witcher",
              posterURL: "https://image.tmdb.org/t/p/w500/7vjaCdMw15FEbXyLQTVa04URsPm.jpg",
              backdropURL: "https://image.tmdb.org/t/p/w1280/7vjaCdMw15FEbXyLQTVa04URsPm.jpg",
              releaseYear: 2019, rating: "TV-MA", duration: 60, genre: "Fantasy, Action",
              isMovie: false, isTrending: true, isFeatured: false,
              description: "Geralt of Rivia, a solitary monster hunter, struggles to find his place in a world where people often prove more wicked than beasts."),
        Movie(tmdbId: 0, title: "Extraction",
              posterURL: "https://image.tmdb.org/t/p/w500/7W0G3YECgDAfnui7UOqOuR0zH4h.jpg",
              backdropURL: "https://image.tmdb.org/t/p/w1280/7W0G3YECgDAfnui7UOqOuR0zH4h.jpg",
              releaseYear: 2020, rating: "R", duration: 116, genre: "Action, Thriller",
              isMovie: true, isTrending: false, isFeatured: true,
              description: "A hardened mercenary's mission becomes a soul-searing race to survive and protect one boy's innocence against overwhelming odds."),
        Movie(tmdbId: 0, title: "The Queen's Gambit",
              posterURL: "https://image.tmdb.org/t/p/w500/zU0htwkhNvBQdVSIKB9s6hgVeFK.jpg",
              backdropURL: "https://image.tmdb.org/t/p/w1280/zU0htwkhNvBQdVSIKB9s6hgVeFK.jpg",
              releaseYear: 2020, rating: "TV-MA", duration: 60, genre: "Drama",
              isMovie: false, isTrending: true, isFeatured: false,
              description: "In a 1950s orphanage, a young girl reveals an astonishing talent for chess and begins an unlikely journey to stardom while grappling with addiction."),
        Movie(tmdbId: 0, title: "Bird Box",
              posterURL: "https://image.tmdb.org/t/p/w500/rGfGfgL2pEPCfhIvqHXieXFn7gp.jpg",
              backdropURL: "https://image.tmdb.org/t/p/w1280/rGfGfgL2pEPCfhIvqHXieXFn7gp.jpg",
              releaseYear: 2018, rating: "R", duration: 124, genre: "Horror, Thriller",
              isMovie: true, isTrending: false, isFeatured: false,
              description: "Five years after an invisible presence drives most of society to suicide, a survivor and her two children make a desperate bid to reach safety."),
        Movie(tmdbId: 0, title: "Ozark",
              posterURL: "https://image.tmdb.org/t/p/w500/mY7SeH4HFFxW1hiI6cWuwCRKptN.jpg",
              backdropURL: "https://image.tmdb.org/t/p/w1280/mY7SeH4HFFxW1hiI6cWuwCRKptN.jpg",
              releaseYear: 2017, rating: "TV-MA", duration: 60, genre: "Crime, Drama",
              isMovie: false, isTrending: true, isFeatured: false,
              description: "A financial advisor drags his family from Chicago to the Missouri Ozarks, where he must launder $500 million to appease a Mexican drug cartel."),
        Movie(tmdbId: 0, title: "Squid Game",
              posterURL: "https://image.tmdb.org/t/p/w500/dDlEmu3EZ0Pgg93K2SVNLCjCSvE.jpg",
              backdropURL: "https://image.tmdb.org/t/p/w1280/dDlEmu3EZ0Pgg93K2SVNLCjCSvE.jpg",
              releaseYear: 2021, rating: "TV-MA", duration: 60, genre: "Drama, Thriller",
              isMovie: false, isTrending: true, isFeatured: false,
              description: "Hundreds of cash-strapped players accept a strange invitation to compete in children's games. Inside, a tempting prize awaits with deadly high stakes.")
    ]
}
