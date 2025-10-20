//
//  ContentService.swift
//  Netflix
//
//  Created by Chirag Dodia on 9/2/25.
//

import Foundation
import CoreData
import SwiftUI

class ContentService: ObservableObject {
    static let shared = ContentService()
    
    private init() {}
    
    // Sample content data
    let sampleContent = [
        ContentData(
            title: "Stranger Things",
            contentDescription: "When a young boy vanishes, a small town uncovers a mystery involving secret experiments, terrifying supernatural forces, and one strange little girl.",
            posterURL: "https://image.tmdb.org/t/p/w500/49WJfeN0moxb9IPfGn8AIqMGskD.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/56v2KjBlU4XaOv9rVYEQypROD7P.jpg",
            releaseYear: 2016,
            rating: "TV-14",
            duration: 50,
            genre: "Sci-Fi, Horror",
            isMovie: false,
            isTrending: true,
            isFeatured: true
        ),
        ContentData(
            title: "The Witcher",
            contentDescription: "Geralt of Rivia, a solitary monster hunter, struggles to find his place in a world where people often prove more wicked than beasts.",
            posterURL: "https://image.tmdb.org/t/p/w500/7vjaCdMw15FEbXyLQTVa04URsPm.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/7vjaCdMw15FEbXyLQTVa04URsPm.jpg",
            releaseYear: 2019,
            rating: "TV-MA",
            duration: 60,
            genre: "Fantasy, Action",
            isMovie: false,
            isTrending: true,
            isFeatured: false
        ),
        ContentData(
            title: "Extraction",
            contentDescription: "A hardened mercenary's mission becomes a soul-searing race to survive and protect one boy's innocence against overwhelming odds.",
            posterURL: "https://image.tmdb.org/t/p/w500/7W0G3YECgDAfnui7UOqOuR0zH4h.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/7W0G3YECgDAfnui7UOqOuR0zH4h.jpg",
            releaseYear: 2020,
            rating: "R",
            duration: 116,
            genre: "Action, Thriller",
            isMovie: true,
            isTrending: false,
            isFeatured: true
        ),
        ContentData(
            title: "The Queen's Gambit",
            contentDescription: "In a 1950s orphanage, a young girl reveals an astonishing talent for chess and begins an unlikely journey to stardom while grappling with addiction.",
            posterURL: "https://image.tmdb.org/t/p/w500/zU0htwkhNvBQdVSIKB9s6hgVeFK.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/zU0htwkhNvBQdVSIKB9s6hgVeFK.jpg",
            releaseYear: 2020,
            rating: "TV-MA",
            duration: 60,
            genre: "Drama",
            isMovie: false,
            isTrending: true,
            isFeatured: false
        ),
        ContentData(
            title: "Bird Box",
            contentDescription: "Five years after an invisible presence drives most of society to suicide, a survivor and her two children make a desperate bid to reach safety.",
            posterURL: "https://image.tmdb.org/t/p/w500/rGfGfgL2pEPCfhIvqHXieXFn7gp.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/rGfGfgL2pEPCfhIvqHXieXFn7gp.jpg",
            releaseYear: 2018,
            rating: "R",
            duration: 124,
            genre: "Horror, Thriller",
            isMovie: true,
            isTrending: false,
            isFeatured: false
        ),
        ContentData(
            title: "Ozark",
            contentDescription: "A financial advisor drags his family from Chicago to the Missouri Ozarks, where he must launder $500 million to appease a Mexican drug cartel.",
            posterURL: "https://image.tmdb.org/t/p/w500/mY7SeH4HFFxW1hiI6cWuwCRKptN.jpg",
            backdropURL: "https://image.tmdb.org/t/p/w1280/mY7SeH4HFFxW1hiI6cWuwCRKptN.jpg",
            releaseYear: 2017,
            rating: "TV-MA",
            duration: 60,
            genre: "Crime, Drama",
            isMovie: false,
            isTrending: true,
            isFeatured: false
        )
    ]
    
    func populateSampleData(context: NSManagedObjectContext) {
        for contentData in sampleContent {
            let content = Content(context: context)
            content.id = UUID()
            content.title = contentData.title
            content.contentDescription = contentData.contentDescription
            content.posterURL = contentData.posterURL
            content.backdropURL = contentData.backdropURL
            content.releaseYear = contentData.releaseYear
            content.rating = contentData.rating
            content.duration = contentData.duration
            content.genre = contentData.genre
            content.isMovie = contentData.isMovie
            content.isTrending = contentData.isTrending
            content.isFeatured = contentData.isFeatured
            content.createdAt = Date()
        }
        
        do {
            try context.save()
        } catch {
            print("Error saving sample data: \(error)")
        }
    }
}

struct ContentData {
    let title: String
    let contentDescription: String
    let posterURL: String
    let backdropURL: String
    let releaseYear: Int16
    let rating: String
    let duration: Int16
    let genre: String
    let isMovie: Bool
    let isTrending: Bool
    let isFeatured: Bool
}
