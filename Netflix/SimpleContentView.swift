//
//  SimpleContentView.swift
//  Netflix
//
//  Created by Chirag Dodia on 9/2/25.
//

import SwiftUI


struct SimpleContentView: View {
    @StateObject private var searchService = SearchService.shared
    @StateObject private var movieService = MovieService.shared
    @EnvironmentObject var profileService: ProfileService
    @EnvironmentObject var myListService: MyListService
    @State private var selectedMovie: Movie? = nil
    @State private var showMovieDetail = false
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var showFilters = false
    @State private var filters = SearchFilters()
    @State private var downloadedMovies: [Movie] = []
    @State private var showJoinParty = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Modern Header
                SimpleHeaderView(
                    searchText: $searchText,
                    showSearch: $showSearch,
                    showJoinParty: $showJoinParty
                )

                // Main Content
                Group {
                    switch selectedTab {
                    case 0:
                        SimpleHomeTabView(
                            movies: movieService.movies,
                            isLoading: movieService.isLoading,
                            onMovieTap: { movie in
                                selectedMovie = movie
                                showMovieDetail = true
                            }
                        )
                    case 1:
                        SimpleCategoriesTabView(
                            movies: movieService.movies,
                            onMovieTap: { movie in
                                selectedMovie = movie
                                showMovieDetail = true
                            }
                        )
                    case 2:
                        VStack {
                            TextField("Search movies...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(10)
                                .padding()
                                .foregroundColor(.white)
                            SimpleSearchView(searchText: $searchText) { movie in
                                selectedMovie = movie
                                showMovieDetail = true
                            }
                        }
                    default:
                        SimpleMyListTabView(
                            movies: movieService.movies,
                            onMovieTap: { movie in
                                selectedMovie = movie
                                showMovieDetail = true
                            }
                        )
                    }
                }
            }

            // Floating pill tab bar
            SimpleTabBar(selectedTab: $selectedTab)
        }
        .sheet(isPresented: $showMovieDetail) {
            if let movie = selectedMovie {
                SimpleMovieDetailView(movie: movie)
            }
        }
        .sheet(isPresented: $showJoinParty) {
            JoinWatchPartyView()
        }
        .onChange(of: searchText) { newValue in
            if !newValue.isEmpty {
                searchService.search(query: newValue, filters: filters)
            }
        }
        .onAppear {
            if let profileId = profileService.currentProfile?.id {
                myListService.loadMyList(for: profileId)
            }
        }
        .onChange(of: profileService.currentProfile?.id) { newProfileId in
            if let profileId = profileService.currentProfile?.id {
                myListService.loadMyList(for: profileId)
            }
        }
        .onChange(of: selectedTab) { newTab in
            if newTab == 3 {
                if let profileId = profileService.currentProfile?.id {
                    myListService.loadMyList(for: profileId)
                }
            }
        }
    }
}

// MARK: - Simple Header
struct SimpleHeaderView: View {
    @Binding var searchText: String
    @Binding var showSearch: Bool
    @Binding var showJoinParty: Bool

    var body: some View {
        ZStack {
            Text("CINEMORA")
                .font(.system(size: 28, weight: .heavy, design: .default))
                .foregroundColor(Color(red: 229/255, green: 9/255, blue: 20/255))
                .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                Button(action: { showJoinParty = true }) {
                    HStack(spacing: 5) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Join Party")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.red.opacity(0.85))
                    .cornerRadius(20)
                }
                .padding(.trailing, 16)
            }
        }
        .padding(.top, 50)
        .padding(.bottom, 15)
        .background(Color.black)
    }
}

// MARK: - Simple Search View
struct SimpleSearchView: View {
    @Binding var searchText: String
    let onMovieTap: (Movie) -> Void

    private var allMovies: [Movie] { MovieService.shared.movies }

    var filteredMovies: [Movie] {
        if searchText.isEmpty { return allMovies }
        return allMovies.filter { movie in
            movie.title.localizedCaseInsensitiveContains(searchText) ||
            movie.genre.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                ForEach(filteredMovies) { movie in
                    SimpleMovieCard(movie: movie) {
                        onMovieTap(movie)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Simple Tab Views
struct SimpleHomeTabView: View {
    let movies: [Movie]
    let isLoading: Bool
    let onMovieTap: (Movie) -> Void
    @EnvironmentObject var watchProgressService: WatchProgressService
    @EnvironmentObject var profileService: ProfileService
    @State private var selectedCategory = "ALL"
    
    let categories = ["ALL", "ACTION", "ADVENTURE", "ROMANCE", "THRILLER"]

    // Computed properties
    private var filteredMovies: [Movie] {
        if selectedCategory == "ALL" { return movies }
        return movies.filter { $0.genre.localizedCaseInsensitiveContains(selectedCategory) }
    }
    
    private var heroMovie: Movie? {
        filteredMovies.first(where: { $0.isFeatured }) ?? filteredMovies.first
    }
    
    private var newMovies: [Movie] {
        // Just return a subset of movies for the CoverFlow, unaffected by category pills
        Array(movies.suffix(10).reversed())
    }

    private var trendingMovies: [Movie] {
        movies.filter { $0.isTrending }
    }

    private var continueItems: [WatchProgress] {
        guard let profileId = profileService.currentProfile?.id else { return [] }
        return watchProgressService.inProgress(for: profileId)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                let _ = Color.clear // forces full-width VStack layout in TabView
                // Categories Pill Scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                withAnimation { selectedCategory = category }
                            }) {
                                Text(category)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(selectedCategory == category ? .white : .gray)
                                    .padding(.horizontal, selectedCategory == category ? 20 : 10)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedCategory == category ? Color(red: 229/255, green: 9/255, blue: 20/255) : Color.clear)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                if isLoading && movies.isEmpty {
                    loadingSkeleton
                } else {
                    // Hero Banner (Inset)
                    if let hero = heroMovie {
                        Button(action: { onMovieTap(hero) }) {
                            ZStack {
                                AsyncImage(url: URL(string: hero.backdropURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle().fill(Color.gray.opacity(0.3))
                                }
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .cornerRadius(12)
                                .clipped()
                                
                                LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                                    .cornerRadius(12)
                                
                                VStack {
                                    Spacer()
                                    Text(hero.title)
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.bottom, 15)
                                }
                            }
                            .shadow(color: Color.black.opacity(0.5), radius: 15, x: 0, y: 5)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 20)
                    }
                    
                    // New Movies (3D Carousel, unaffected by category pills)
                    CoverFlowCarousel(
                        movies: newMovies,
                        onMovieTap: onMovieTap
                    )
                    
                    if !continueItems.isEmpty {
                        ContinueWatchingSection(
                            items: continueItems,
                            movies: movies,
                            onMovieTap: onMovieTap
                        )
                        .padding(.top, 10)
                    }

                    SimpleContentSection(
                        title: "Trending Now",
                        movies: trendingMovies,
                        onMovieTap: onMovieTap
                    )
                    .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 100)
        }
    }

    private var loadingSkeleton: some View {
        VStack(spacing: 20) {
            // Skeleton Hero Banner
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .aspectRatio(0.8, contentMode: .fit)
                .cornerRadius(12)
                .padding(.horizontal)
            
            // Skeleton Row (Carousel/Shows)
            HStack(spacing: 15) {
                ForEach(0..<4, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 140, height: 210)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 10)
    }
}

// MARK: - Carousel / CoverFlow
struct CoverFlowCarousel: View {
    let movies: [Movie]
    let onMovieTap: (Movie) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("NEW MOVIES")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.white)
                Spacer()
                Text("SEE ALL")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: -30) {
                    ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                        GeometryReader { geometry in
                            let midX = geometry.frame(in: .global).midX
                            let screenWidth = UIScreen.main.bounds.width
                            let distance = abs(screenWidth / 2 - midX)
                            let scale = max(0.8, 1 - distance / screenWidth)
                            let zIndex = 1 - (distance / screenWidth)
                            
                            AsyncImage(url: URL(string: movie.posterURL)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle().fill(Color.gray)
                            }
                            .frame(width: 140, height: 210)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 10)
                            .scaleEffect(scale)
                            .zIndex(zIndex)
                            .onTapGesture {
                                onMovieTap(movie)
                            }
                        }
                        .frame(width: 140, height: 210)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
            }
        }
    }
}

struct SimpleCategoriesTabView: View {
    let movies: [Movie]
    let onMovieTap: (Movie) -> Void
    @State private var selectedType = "All"
    @State private var selectedCategory = "All"

    private let contentTypes = ["All", "Movies", "TV Shows"]
    private let categories = ["All", "Action", "Comedy", "Drama", "Horror", "Sci-Fi", "Romance", "Thriller"]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Content Type Segmented Control
                HStack(spacing: 4) {
                    ForEach(contentTypes, id: \.self) { type in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedType = type
                                selectedCategory = "All"
                            }
                        }) {
                            Text(type)
                                .font(.system(size: 14, weight: selectedType == type ? .bold : .semibold))
                                .foregroundColor(selectedType == type ? .white : Color.white.opacity(0.45))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedType == type ? Color.red : Color.clear)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(4)
                .background(Color.white.opacity(0.07))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Genre Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            SimpleCategoryChip(
                                title: category,
                                isSelected: selectedCategory == category
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // Results count
                HStack {
                    Text("\(filteredMovies.count) titles")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.4))
                    Spacer()
                }
                .padding(.horizontal, 20)

                // Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 20) {
                    ForEach(filteredMovies) { movie in
                        SimpleMovieCard(movie: movie) {
                            onMovieTap(movie)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 100)
        }
    }

    private var filteredMovies: [Movie] {
        var result = movies
        switch selectedType {
        case "Movies":   result = result.filter { $0.isMovie }
        case "TV Shows": result = result.filter { !$0.isMovie }
        default: break
        }
        if selectedCategory != "All" {
            result = result.filter { $0.genre.lowercased().contains(selectedCategory.lowercased()) }
        }
        return result
    }
}

struct SimpleDownloadsTabView: View {
    let downloadedMovies: [Movie]
    let onMovieTap: (Movie) -> Void
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                if downloadedMovies.isEmpty {
                    SimpleEmptyDownloadsView()
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        ForEach(downloadedMovies) { movie in
                            SimpleMovieCard(movie: movie) {
                                onMovieTap(movie)
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

struct SimpleMyListTabView: View {
    let movies: [Movie]
    let onMovieTap: (Movie) -> Void
    @EnvironmentObject var myListService: MyListService
    @EnvironmentObject var profileService: ProfileService
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                if myListService.myListItems.isEmpty {
                    SimpleEmptyMyListView()
                        .onAppear {
                            // Reload when empty view appears
                            if let profileId = profileService.currentProfile?.id {
                                print("📱 Empty My List view appeared - reloading...")
                                myListService.loadMyList(for: profileId)
                            }
                        }
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("My List")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(myListService.myListItems.count) items")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            ForEach(myListService.myListItems) { movie in
                                MyListMovieCard(movie: movie, onTap: {
                                    onMovieTap(movie)
                                }, onRemove: {
                                    if let profileId = profileService.currentProfile?.id {
                                        myListService.removeFromMyList(movieTitle: movie.title, profileId: profileId)
                                    }
                                })
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .onAppear {
            // Always reload My List when this tab appears
            if let profileId = profileService.currentProfile?.id {
                print("📱 My List tab appeared - loading list...")
                myListService.loadMyList(for: profileId)
            }
        }
    }
}

// MARK: - My List Movie Card
struct MyListMovieCard: View {
    let movie: Movie
    let onTap: () -> Void
    let onRemove: () -> Void
    @State private var isPressed = false
    @State private var imageLoaded = false
    @State private var showRemoveConfirmation = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: movie.posterURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .onAppear {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    imageLoaded = true
                                }
                            }
                    } placeholder: {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            )
                    }
                    .frame(width: 160, height: 240)
                    .cornerRadius(16)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Color(red: 0.02, green: 0.05, blue: 0.2).opacity(0.6), radius: 10, x: 0, y: 5)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .opacity(imageLoaded ? 1.0 : 0.7)

                    // Remove button
                    Button(action: {
                        showRemoveConfirmation = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .offset(x: -8, y: 8)
                    .buttonStyle(PlainButtonStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(movie.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(movie.genre)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                .frame(width: 160, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Remove from My List", isPresented: $showRemoveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    onRemove()
                }
            }
        } message: {
            Text("Are you sure you want to remove '\(movie.title)' from your list?")
        }
    }
}

// MARK: - Simple Components
struct SimpleHeroSection: View {
    let movie: Movie
    let onTap: () -> Void
    @EnvironmentObject var myListService: MyListService
    @EnvironmentObject var profileService: ProfileService
    @State private var imageLoaded = false
    @State private var isInMyList = false
    @State private var showPlayer = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: URL(string: movie.backdropURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            imageLoaded = true
                        }
                    }
            } placeholder: {
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.red.opacity(0.3), Color.purple.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            .frame(height: 400)
            .clipped()
            .cornerRadius(20)
            .padding(.horizontal, 20)
            
            // Gradient overlay
            LinearGradient(
                gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .cornerRadius(20)
            .padding(.horizontal, 20)
            
            // Content
            VStack(alignment: .center, spacing: 8) {
                Text(movie.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                
                HStack(spacing: 12) {
                    Text(movie.rating)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    
                    Text("\(movie.releaseYear)")
                        .font(.body)
                        .foregroundColor(.white)
                    
                    if movie.isMovie {
                        Text("\(movie.duration) min")
                            .font(.body)
                            .foregroundColor(.white)
                    } else {
                        Text("TV Series")
                            .font(.body)
                            .foregroundColor(.white)
                    }
                }
                
                Text(movie.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.8), radius: 1, x: 0, y: 1)
                    .padding(.horizontal, 40)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 16) {
                    Button(action: { showPlayer = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Play Trailer")
                                .fontWeight(.semibold)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .fullScreenCover(isPresented: $showPlayer) {
                        VideoPlayerView(movie: movie)
                    }
                    
                    Button(action: {
                        if let profileId = profileService.currentProfile?.id {
                            if isInMyList {
                                myListService.removeFromMyList(movieTitle: movie.title, profileId: profileId)
                                isInMyList = false
                            } else {
                                myListService.addToMyList(movie: movie, profileId: profileId)
                                isInMyList = true
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: isInMyList ? "checkmark" : "plus")
                            Text(isInMyList ? "In My List" : "Add to List")
                                .fontWeight(.semibold)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(isInMyList ? Color.green.opacity(0.7) : Color.red.opacity(0.7))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .onAppear {
                        if let profileId = profileService.currentProfile?.id {
                            isInMyList = myListService.isInMyList(movieTitle: movie.title, profileId: profileId)
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .onTapGesture {
            onTap()
        }
        .onChange(of: profileService.currentProfile?.id) { _ in
            if let profileId = profileService.currentProfile?.id {
                isInMyList = myListService.isInMyList(movieTitle: movie.title, profileId: profileId)
            }
        }
    }
}

struct SimpleContentSection: View {
    let title: String
    let movies: [Movie]
    let onMovieTap: (Movie) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {}) {
                    Text("See All")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(movies) { movie in
                        SimpleMovieCard(movie: movie) {
                            onMovieTap(movie)
                        }
                    }
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 290)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SimpleMovieCard: View {
    let movie: Movie
    let onTap: () -> Void
    @State private var isPressed = false
    @State private var imageLoaded = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                AsyncImage(url: URL(string: movie.posterURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                imageLoaded = true
                            }
                        }
                } placeholder: {
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
                .frame(width: 160, height: 240)
                .cornerRadius(16)
                .clipped()
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color(red: 0.02, green: 0.05, blue: 0.2).opacity(0.6), radius: 10, x: 0, y: 5)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .opacity(imageLoaded ? 1.0 : 0.7)

                VStack(alignment: .leading, spacing: 4) {
                    Text(movie.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(movie.genre)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.45))
                        .lineLimit(1)
                }
                .frame(width: 160, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SimpleCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color.white.opacity(0.5))
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(
                    isSelected ?
                    AnyView(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.red)
                    ) :
                    AnyView(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(red: 0.06, green: 0.1, blue: 0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SimpleTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var authService: LocalAuthService
    @EnvironmentObject var profileService: ProfileService
    @State private var showLogoutAlert = false

    var body: some View {
        HStack {
            SimpleTabButton(icon: "house", isSelected: selectedTab == 0) { selectedTab = 0 }
            Spacer()
            SimpleTabButton(icon: "tv", isSelected: selectedTab == 1) { selectedTab = 1 }
            Spacer()
            SimpleTabButton(icon: "magnifyingglass", isSelected: selectedTab == 2) { selectedTab = 2 }
            Spacer()
            SimpleTabButton(icon: "heart", isSelected: selectedTab == 3) { selectedTab = 3 }
            Spacer()
            
            // Profile / Menu Button
            Menu {
                if let profile = profileService.currentProfile { Text(profile.name) }
                Divider()
                Button(action: { profileService.clearCurrentProfile() }) { Label("Switch Profile", systemImage: "person.2.fill") }
                Button(role: .destructive, action: { showLogoutAlert = true }) { Label("Logout", systemImage: "rectangle.portrait.and.arrow.right") }
            } label: {
                SimpleTabButton(icon: "person", isSelected: selectedTab == 4) { selectedTab = 4 }
            }
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 14)
        .background(
            Color(red: 25/255, green: 25/255, blue: 25/255)
                .cornerRadius(25)
                .padding(.horizontal, 16)
        )
        .padding(.bottom, 10)
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                authService.signOut()
                profileService.clearCurrentProfile()
            }
        }
    }
}

struct SimpleTabButton: View {
    let icon: String // system image name
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.spring()) { action() }
        }) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 229/255, green: 9/255, blue: 20/255))
                        .frame(width: 44, height: 44)
                }
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .bold : .light))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SimpleEmptyDownloadsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Downloads Yet")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Download movies and shows to watch offline")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 100)
    }
}

struct SimpleEmptyMyListView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Your List is Empty")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text("Add movies and shows to your list to watch them later")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 100)
    }
}

struct SimpleMovieDetailView: View {
    let movie: Movie
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var myListService: MyListService
    @EnvironmentObject var profileService: ProfileService
    @State private var isPlayPressed = false
    @State private var isDownloadPressed = false
    @State private var isInMyList = false
    @State private var showPlayer = false
    @State private var showWatchParty = false
    @State private var runtime: Int? = nil
    
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.05, blue: 0.13).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Full poster image
                    AsyncImage(url: URL(string: movie.posterURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.red.opacity(0.3), Color.purple.opacity(0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .aspectRatio(2/3, contentMode: .fit)
                    }
                    .frame(maxWidth: .infinity)
                    .clipped()
                    
                    // Content below the image
                    VStack(spacing: 20) {
                        Text(movie.title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                        
                        HStack(spacing: 16) {
                            Text(movie.rating)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            
                            Text("\(movie.releaseYear)")
                                .font(.body)
                                .foregroundColor(.gray)
                            
                            if movie.isMovie {
                                Text("\(movie.duration) min")
                                    .font(.body)
                                    .foregroundColor(.gray)
                            } else {
                                Text("TV Series")
                                    .font(.body)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text(movie.description)
                            .font(.body)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        .padding(.horizontal, 20)
                        
                        // Runtime row (real value fetched from TMDB)
                        if let rt = runtime {
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                                Text(movie.isMovie ? "\(rt) min" : "\(rt) min / ep")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }

                        // Action buttons
                        VStack(spacing: 16) {
                            // Play Now button
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    isPlayPressed = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        isPlayPressed = false
                                    }
                                    showPlayer = true
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.fill")
                                    Text("Play Trailer")
                                        .fontWeight(.semibold)
                                }
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .cornerRadius(25)
                                .scaleEffect(isPlayPressed ? 0.95 : 1.0)
                            }

                            // Watch Together button
                            Button(action: { showWatchParty = true }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "person.2.fill")
                                    Text("Watch Together")
                                        .fontWeight(.semibold)
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(red: 0.45, green: 0.18, blue: 0.85))
                                .cornerRadius(25)
                            }

                            // Secondary buttons row
                            HStack(spacing: 16) {
                                // Add to List button
                                Button(action: {
                                    if let profileId = profileService.currentProfile?.id {
                                        if isInMyList {
                                            myListService.removeFromMyList(movieTitle: movie.title, profileId: profileId)
                                            isInMyList = false
                                        } else {
                                            myListService.addToMyList(movie: movie, profileId: profileId)
                                            isInMyList = true
                                        }
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: isInMyList ? "checkmark" : "plus")
                                        Text(isInMyList ? "In My List" : "Add to List")
                                            .fontWeight(.semibold)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(isInMyList ? Color.green.opacity(0.8) : Color.red.opacity(0.8))
                                    .cornerRadius(20)
                                }
                                
                                // Download button
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        isDownloadPressed = true
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            isDownloadPressed = false
                                        }
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.down.circle.fill")
                                        Text("Download")
                                            .fontWeight(.semibold)
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(Color.black.opacity(0.8))
                                    .cornerRadius(20)
                                    .scaleEffect(isDownloadPressed ? 0.95 : 1.0)
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
                    }
                    .background(Color.black)
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 10)
                }
                Spacer()
            }
        }
        .onAppear {
            if let profileId = profileService.currentProfile?.id {
                isInMyList = myListService.isInMyList(movieTitle: movie.title, profileId: profileId)
            }
        }
        .onChange(of: profileService.currentProfile?.id) { _ in
            if let profileId = profileService.currentProfile?.id {
                isInMyList = myListService.isInMyList(movieTitle: movie.title, profileId: profileId)
            }
        }
        .task {
            // Fetch real runtime from TMDB
            if movie.tmdbId != 0 {
                if movie.isMovie {
                    runtime = await TMDBService.shared.fetchMovieRuntime(id: movie.tmdbId)
                } else {
                    runtime = await TMDBService.shared.fetchTVRuntime(id: movie.tmdbId)
                }
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            VideoPlayerView(movie: movie)
        }
        .sheet(isPresented: $showWatchParty) {
            WatchPartyView(movie: movie)
                .environmentObject(profileService)
        }
    }
}

#Preview {
    SimpleContentView()
}
