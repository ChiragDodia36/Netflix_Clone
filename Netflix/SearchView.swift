//
//  SearchView.swift
//  Netflix
//
//  Created by Chirag Dodia on 9/2/25.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var searchService = SearchService.shared
    @Binding var searchText: String
    @State private var showFilters = false
    @State private var filters = SearchFilters()
    @State private var selectedMovie: Movie? = nil
    @State private var showMovieDetail = false
    
    let onMovieTap: (Movie) -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Small filter button
                HStack {
                    Button(action: {
                        showFilters = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.caption)
                            Text("Filters")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.red.opacity(0.8))
                        )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Content
                if searchText.isEmpty && !searchService.hasActiveFilters {
                    // Default search state
                    DefaultSearchView(
                        onMovieTap: onMovieTap,
                        onSearchTap: { query in
                            searchText = query
                            searchService.search(query: query, filters: filters)
                        }
                    )
                } else if searchService.isSearching {
                    // Loading state
                    SearchLoadingView()
                } else if searchService.searchResults.isEmpty {
                    // No results
                    NoResultsView(searchQuery: searchText)
                } else {
                    // Search results
                    SearchResultsView(
                        results: searchService.searchResults,
                        searchQuery: searchText,
                        onMovieTap: onMovieTap
                    )
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            NavigationView {
                SearchFiltersView(filters: $filters) {
                    // Apply filters - this will be called from SearchFiltersView
                    searchService.search(query: searchText, filters: filters)
                }
                .navigationTitle("Filters")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onChange(of: searchText) { newValue in
            searchService.search(query: newValue, filters: filters)
        }
        .onAppear {
            // Clear previous search when view appears
            searchText = ""
            searchService.searchResults = []
            searchService.currentFilters = SearchFilters()
        }
    }
}


// MARK: - Default Search View

struct DefaultSearchView: View {
    @StateObject private var searchService = SearchService.shared
    let onMovieTap: (Movie) -> Void
    let onSearchTap: (String) -> Void
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Recent searches
                if !searchService.recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Searches")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Button("Clear") {
                                searchService.clearSearchHistory()
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(searchService.recentSearches, id: \.self) { search in
                                Button(action: {
                                    onSearchTap(search)
                                }) {
                                    HStack {
                                        Image(systemName: "clock")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        
                                        Text(search)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.gray.opacity(0.2))
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                // Trending now
                VStack(alignment: .leading, spacing: 12) {
                    Text("Trending Now")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(searchService.getTrendingMovies()) { movie in
                                TrendingMovieCard(movie: movie) {
                                    onMovieTap(movie)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                // Browse by category
                VStack(alignment: .leading, spacing: 12) {
                    Text("Browse by Category")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(SearchService.availableGenres, id: \.self) { genre in
                            Button(action: {
                                onSearchTap(genre)
                            }) {
                                Text(genre)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.red.opacity(0.8))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Trending Movie Card

struct TrendingMovieCard: View {
    let movie: Movie
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Movie poster
            AsyncImage(url: URL(string: movie.posterURL)) { image in
                image
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
            }
            .frame(width: 120, height: 180)
            .clipped()
            .cornerRadius(8)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                    onTap()
                }
            }
            
            // Movie info
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(movie.genre)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
        }
        .frame(width: 120)
    }
}

// MARK: - Search Loading View

struct SearchLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.red)
            
            Text("Searching...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - No Results View

struct NoResultsView: View {
    let searchQuery: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No results found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Try searching for something else")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Text("Searched for: \"\(searchQuery)\"")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}

// MARK: - Search Results View

struct SearchResultsView: View {
    let results: [Movie]
    let searchQuery: String
    let onMovieTap: (Movie) -> Void
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Results header
                HStack {
                    Text("Results for \"\(searchQuery)\"")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(results.count) found")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                
                // Results grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(results) { movie in
                        SearchResultCard(movie: movie) {
                            onMovieTap(movie)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 100)
        }
    }
}

// MARK: - Search Result Card

struct SearchResultCard: View {
    let movie: Movie
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Movie poster
            AsyncImage(url: URL(string: movie.posterURL)) { image in
                image
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
            }
            .frame(height: 200)
            .clipped()
            .cornerRadius(8)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                    onTap()
                }
            }
            
            // Movie info
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                HStack {
                    Text(movie.rating)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    Text("\(movie.releaseYear)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
            }
        }
    }
}

// Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(searchText: .constant("")) { _ in }
    }
}
