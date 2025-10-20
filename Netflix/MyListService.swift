//
//  MyListService.swift
//  Netflix
//
//  Created by Chirag Dodia on 9/2/25.
//

import Foundation
import SwiftUI

struct MyListItem: Identifiable, Codable {
    let id = UUID()
    let movieTitle: String
    let moviePosterURL: String
    let movieBackdropURL: String
    let movieReleaseYear: Int
    let movieRating: String
    let movieDuration: Int
    let movieGenre: String
    let movieIsMovie: Bool
    let movieIsTrending: Bool
    let movieIsFeatured: Bool
    let movieDescription: String
    let profileId: UUID
    let addedAt: Date
    
    // Convert to Movie object
    func toMovie() -> Movie {
        return Movie(
            title: movieTitle,
            posterURL: moviePosterURL,
            backdropURL: movieBackdropURL,
            releaseYear: movieReleaseYear,
            rating: movieRating,
            duration: movieDuration,
            genre: movieGenre,
            isMovie: movieIsMovie,
            isTrending: movieIsTrending,
            isFeatured: movieIsFeatured,
            description: movieDescription
        )
    }
}

class MyListService: ObservableObject {
    static let shared = MyListService()
    
    @Published var myListItems: [Movie] = []
    
    private let myListKey = "my_list_items"
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Public Methods
    
    func loadMyList(for profileId: UUID, allMovies: [Movie] = []) {
        debugPrintStorage() // Debug all stored items
        
        let items = getAllMyListItems()
        let profileItems = items.filter { $0.profileId == profileId }
        
        print("🔍 Loading My List for profile: \(profileId)")
        print("   Total items in storage: \(items.count)")
        print("   Items for this profile: \(profileItems.count)")
        
        // Convert stored items to Movie objects
        myListItems = profileItems.map { $0.toMovie() }
        
        print("   Final myListItems count: \(myListItems.count)")
        print("   Titles: \(myListItems.map { $0.title })")
    }
    
    func isInMyList(movieTitle: String, profileId: UUID) -> Bool {
        let items = getAllMyListItems()
        return items.contains { $0.movieTitle == movieTitle && $0.profileId == profileId }
    }
    
    func addToMyList(movie: Movie, profileId: UUID) {
        // Check if already in list
        guard !isInMyList(movieTitle: movie.title, profileId: profileId) else {
            return
        }
        
        var items = getAllMyListItems()
        let newItem = MyListItem(
            movieTitle: movie.title,
            moviePosterURL: movie.posterURL,
            movieBackdropURL: movie.backdropURL,
            movieReleaseYear: movie.releaseYear,
            movieRating: movie.rating,
            movieDuration: movie.duration,
            movieGenre: movie.genre,
            movieIsMovie: movie.isMovie,
            movieIsTrending: movie.isTrending,
            movieIsFeatured: movie.isFeatured,
            movieDescription: movie.description,
            profileId: profileId,
            addedAt: Date()
        )
        items.append(newItem)
        saveAllMyListItems(items)
        
        print("➕ Added to My List - Movie: \(movie.title), Profile: \(profileId)")
        print("   Total items in storage after save: \(items.count)")
        
        // Verify it was saved
        let verifyItems = getAllMyListItems()
        print("   Verification - items in storage: \(verifyItems.count)")
        for item in verifyItems {
            print("     - \(item.movieTitle) for profile \(item.profileId)")
        }
        
        // Update the published list
        myListItems.append(movie)
        print("   Published myListItems count: \(myListItems.count)")
    }
    
    func removeFromMyList(movieTitle: String, profileId: UUID) {
        var items = getAllMyListItems()
        items.removeAll { $0.movieTitle == movieTitle && $0.profileId == profileId }
        saveAllMyListItems(items)
        
        print("➖ Removed from My List - Movie: \(movieTitle), Profile: \(profileId)")
        print("   Total items in storage: \(items.count)")
        
        // Update the published list
        myListItems.removeAll { $0.title == movieTitle }
    }
    
    func clearMyList() {
        myListItems = []
    }
    
    // MARK: - Private Methods
    
    private func getAllMyListItems() -> [MyListItem] {
        print("📖 Reading from UserDefaults key: \(myListKey)")
        
        guard let data = userDefaults.data(forKey: myListKey) else {
            print("   ❌ No data found in UserDefaults")
            return []
        }
        
        print("   ✅ Data found, size: \(data.count) bytes")
        
        guard let items = try? JSONDecoder().decode([MyListItem].self, from: data) else {
            print("   ❌ Failed to decode data")
            return []
        }
        
        print("   ✅ Decoded \(items.count) items")
        return items
    }
    
    private func saveAllMyListItems(_ items: [MyListItem]) {
        print("💾 Attempting to save \(items.count) items...")
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(items)
            print("   ✅ Encoded successfully, size: \(data.count) bytes")
            
            userDefaults.set(data, forKey: myListKey)
            userDefaults.synchronize() // Force immediate save
            
            // Verify the save
            if let savedData = userDefaults.data(forKey: myListKey) {
                print("   ✅ Saved to UserDefaults, verified size: \(savedData.count) bytes")
            } else {
                print("   ❌ Save verification failed - data not in UserDefaults!")
            }
        } catch {
            print("   ❌ Failed to encode items: \(error)")
        }
    }
    
    // Debug function to check what's in storage
    func debugPrintStorage() {
        let items = getAllMyListItems()
        print("📦 My List Storage Debug:")
        print("   Total items: \(items.count)")
        for item in items {
            print("   - \(item.movieTitle) (Profile: \(item.profileId))")
        }
    }
}

