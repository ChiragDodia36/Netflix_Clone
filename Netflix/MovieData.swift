//
//  MovieData.swift
//  Netflix
//
//  Created by Chirag Dodia on 9/2/25.
//

import Foundation
import CoreData

struct Movie: Identifiable {
    let id = UUID()
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

class MovieService: ObservableObject {
    static let shared = MovieService()
    
    @Published var movies: [Movie] = []
    private let persistenceController = PersistenceController.shared
    
    init() {
        loadMoviesFromDatabase()
    }
    
    private func loadMoviesFromDatabase() {
        let context = persistenceController.container.viewContext
        let fetchRequest: NSFetchRequest<Content> = Content.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Content.popularity, ascending: false)]
        
        do {
            let content = try context.fetch(fetchRequest)
            movies = content.compactMap { content in
                Movie(
                    title: content.title ?? "",
                    posterURL: content.posterURL ?? "",
                    backdropURL: content.backdropURL ?? "",
                    releaseYear: Int(content.releaseYear),
                    rating: content.rating ?? "TV-14",
                    duration: Int(content.duration),
                    genre: content.genre ?? "Drama",
                    isMovie: content.isMovie,
                    isTrending: content.isTrending,
                    isFeatured: content.isFeatured,
                    description: content.contentDescription ?? ""
                )
            }
        } catch {
            print("Error loading movies from database: \(error)")
            // Fallback to sample data if database is empty
            if movies.isEmpty {
                movies = sampleMovies
            }
        }
    }
    
    func refreshMovies() {
        loadMoviesFromDatabase()
    }
    
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
            title: "The Witcher",
            posterURL: "https://image.tmdb.org/t/p/w500/7vjaCdMw15FEbXyLQTVa04URsPm.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/7vjaCdMw15FEbXyLQTVa04URsPm.jpg",
            releaseYear: 2019,
            rating: "TV-MA",
            duration: 60,
            genre: "Fantasy, Action",
            isMovie: false,
            isTrending: true,
            isFeatured: false,
            description: "Geralt of Rivia, a solitary monster hunter, struggles to find his place in a world where people often prove more wicked than beasts."
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
            title: "Bird Box",
            posterURL: "https://image.tmdb.org/t/p/w500/rGfGfgL2pEPCfhIvqHXieXFn7gp.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/rGfGfgL2pEPCfhIvqHXieXFn7gp.jpg",
            releaseYear: 2018,
            rating: "R",
            duration: 124,
            genre: "Horror, Thriller",
            isMovie: true,
            isTrending: false,
            isFeatured: false,
            description: "Five years after an invisible presence drives most of society to suicide, a survivor and her two children make a desperate bid to reach safety."
        ),
        Movie(
            title: "Ozark",
            posterURL: "https://image.tmdb.org/t/p/w500/mY7SeH4HFFxW1hiI6cWuwCRKptN.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/mY7SeH4HFFxW1hiI6cWuwCRKptN.jpg",
            releaseYear: 2017,
            rating: "TV-MA",
            duration: 60,
            genre: "Crime, Drama",
            isMovie: false,
            isTrending: true,
            isFeatured: false,
            description: "A financial advisor drags his family from Chicago to the Missouri Ozarks, where he must launder $500 million to appease a Mexican drug cartel."
        ),
        Movie(
            title: "The Crown",
            posterURL: "https://image.tmdb.org/t/p/w500/1M876Kj8FgGcKqQm4f7lZ5KzQjH.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/1M876Kj8FgGcKqQm4f7lZ5KzQjH.jpg",
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
            title: "Money Heist",
            posterURL: "https://image.tmdb.org/t/p/w500/reEMJA1uzscCbkpeRJeTT2bjqUp.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/reEMJA1uzscCbkpeRJeTT2bjqUp.jpg",
            releaseYear: 2017,
            rating: "TV-MA",
            duration: 70,
            genre: "Crime, Thriller",
            isMovie: false,
            isTrending: true,
            isFeatured: false,
            description: "An unusual group of robbers attempt to carry out the most perfect robbery in Spanish history - stealing 2.4 billion euros from the Royal Mint of Spain."
        ),
        Movie(
            title: "Dark",
            posterURL: "https://image.tmdb.org/t/p/w500/5VzcdjqF8lcdstQtnyX4Or4BA0b.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/5VzcdjqF8lcdstQtnyX4Or4BA0b.jpg",
            releaseYear: 2017,
            rating: "TV-MA",
            duration: 60,
            genre: "Sci-Fi, Thriller",
            isMovie: false,
            isTrending: true,
            isFeatured: false,
            description: "A family saga with a supernatural twist, set in a German town, where the disappearance of two young children exposes the relationships among four families."
        ),
        Movie(
            title: "Bridgerton",
            posterURL: "https://image.tmdb.org/t/p/w500/luoKpgphD0s4NsGk6k7iKtGl3B1.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/luoKpgphD0s4NsGk6k7iKtGl3B1.jpg",
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
            title: "The Umbrella Academy",
            posterURL: "https://image.tmdb.org/t/p/w500/4C2e6a2XU5QzVfH9xUb5w9YQzN2.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/4C2e6a2XU5QzVfH9xUb5w9YQzN2.jpg",
            releaseYear: 2019,
            rating: "TV-14",
            duration: 60,
            genre: "Action, Comedy",
            isMovie: false,
            isTrending: true,
            isFeatured: false,
            description: "A dysfunctional family of superheroes comes together to solve the mystery of their father's death, the threat of the apocalypse and more."
        ),
        Movie(
            title: "Squid Game",
            posterURL: "https://image.tmdb.org/t/p/w500/dDlEmu3EZ0Pgg93K2SVNLCjCSvE.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/dDlEmu3EZ0Pgg93K2SVNLCjCSvE.jpg",
            releaseYear: 2021,
            rating: "TV-MA",
            duration: 60,
            genre: "Drama, Thriller",
            isMovie: false,
            isTrending: true,
            isFeatured: false,
            description: "Hundreds of cash-strapped players accept a strange invitation to compete in children's games. Inside, a tempting prize awaits with deadly high stakes."
        )
    ]
}
