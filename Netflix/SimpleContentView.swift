//
//  SimpleContentView.swift
//  Netflix
//
//  Created by Chirag Dodia on 9/2/25.
//

import SwiftUI


struct SimpleContentView: View {
    @StateObject private var searchService = SearchService.shared
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

    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.05, blue: 0.15),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Modern Header
                SimpleHeaderView(
                    searchText: $searchText,
                    showSearch: $showSearch
                )
                
                if showSearch {
                    // Search View with filters
                    SearchView(searchText: $searchText) { movie in
                        selectedMovie = movie
                        showMovieDetail = true
                    }
                } else {
                    // Main Content with Tab Navigation
                    TabView(selection: $selectedTab) {
                        // Home Tab
                        SimpleHomeTabView(
                            movies: sampleMovies,
                            onMovieTap: { movie in
                                selectedMovie = movie
                                showMovieDetail = true
                            }
                        )
                        .tag(0)
                        
                        // Categories Tab
                        SimpleCategoriesTabView(
                            movies: sampleMovies,
                            onMovieTap: { movie in
                                selectedMovie = movie
                                showMovieDetail = true
                            }
                        )
                        .tag(1)
                        
                        // Downloads Tab
                        SimpleDownloadsTabView(
                            downloadedMovies: downloadedMovies,
                            onMovieTap: { movie in
                                selectedMovie = movie
                                showMovieDetail = true
                            }
                        )
                        .tag(2)
                        
                        // My List Tab
                        SimpleMyListTabView(
                            movies: sampleMovies,
                            onMovieTap: { movie in
                                selectedMovie = movie
                                showMovieDetail = true
                            }
                        )
                        .tag(3)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Custom Tab Bar
                    SimpleTabBar(selectedTab: $selectedTab)
                }
            }
        }
        .sheet(isPresented: $showMovieDetail) {
            if let movie = selectedMovie {
                SimpleMovieDetailView(movie: movie)
            }
        }
        .sheet(isPresented: $showFilters) {
            SearchFiltersView(filters: $filters) {
                // Apply filters
                searchService.currentFilters = filters
                searchService.search(query: searchText, filters: filters)
            }
        }
        .onChange(of: searchText) { newValue in
            if !newValue.isEmpty {
                searchService.search(query: newValue, filters: filters)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showMovieDetail)
        .animation(.easeInOut(duration: 0.3), value: showSearch)
        .onAppear {
            // Load my list for the current profile
            print("🎬 SimpleContentView appeared")
            if let profileId = profileService.currentProfile?.id {
                print("   Current profile: \(profileService.currentProfile?.name ?? "unknown") (\(profileId))")
                myListService.loadMyList(for: profileId)
            } else {
                print("   No current profile!")
            }
        }
        .onChange(of: profileService.currentProfile?.id) { newProfileId in
            // Reload my list when profile changes
            print("🔄 Profile changed detected in SimpleContentView")
            print("   New profile ID: \(newProfileId?.uuidString ?? "nil")")
            if let profileId = profileService.currentProfile?.id {
                print("   Loading My List for new profile...")
                myListService.loadMyList(for: profileId)
            }
        }
        .onChange(of: selectedTab) { newTab in
            // Reload My List when My List tab (tab 3) is selected
            if newTab == 3 {
                print("📑 My List tab selected - reloading...")
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
    @State private var showFilters = false
    @State private var showProfileMenu = false
    @State private var showLogoutAlert = false
    @EnvironmentObject var authService: LocalAuthService
    @EnvironmentObject var profileService: ProfileService
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Netflix Logo
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 36, height: 24)
                        
                        HStack(spacing: 2) {
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 3, height: 12)
                            
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 3, height: 12)
                            
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 3, height: 12)
                        }
                    }
                    
                    Text("Cinemora")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Search and Profile
                HStack(spacing: 20) {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showSearch.toggle()
                            if !showSearch {
                                searchText = ""
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Menu {
                        // Profile Name
                        if let profile = profileService.currentProfile {
                            Text(profile.name)
                                .font(.headline)
                        }
                        
                        Divider()
                        
                        // Switch Profile
                        Button(action: {
                            profileService.clearCurrentProfile()
                        }) {
                            Label("Switch Profile", systemImage: "person.2.fill")
                        }
                        
                        // Logout
                        Button(role: .destructive, action: {
                            showLogoutAlert = true
                        }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            profileService.currentProfile?.colorValue ?? .red,
                                            (profileService.currentProfile?.colorValue ?? .red).opacity(0.7)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            
                            if let profile = profileService.currentProfile {
                                Text(String(profile.name.prefix(1).uppercased()))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 16)
            
            // Search Bar (when active)
            if showSearch {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search movies, shows...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Filters button
                    Button(action: {
                        showFilters = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.red)
                            .font(.title2)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(25)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .background(
            Color.black.opacity(0.8)
                .blur(radius: 10)
        )
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                authService.signOut()
                profileService.clearCurrentProfile()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}

// MARK: - Simple Search View
struct SimpleSearchView: View {
    @Binding var searchText: String
    let onMovieTap: (Movie) -> Void
    
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
        )
    ]
    
    var filteredMovies: [Movie] {
        if searchText.isEmpty {
            return sampleMovies
        }
        return sampleMovies.filter { movie in
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
    let onMovieTap: (Movie) -> Void
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 24) {
                // Hero Section
                if let featuredMovie = movies.first(where: { $0.isFeatured }) {
                    SimpleHeroSection(movie: featuredMovie, onTap: { onMovieTap(featuredMovie) })
                }
                
                // Content Sections
                SimpleContentSection(
                    title: "Trending Now",
                    movies: movies.filter { $0.isTrending },
                    onMovieTap: onMovieTap
                )
                
                SimpleContentSection(
                    title: "New Releases",
                    movies: movies.prefix(6).map { $0 },
                    onMovieTap: onMovieTap
                )
                
                SimpleContentSection(
                    title: "Movies",
                    movies: movies.filter { $0.isMovie },
                    onMovieTap: onMovieTap
                )
                
                SimpleContentSection(
                    title: "TV Shows",
                    movies: movies.filter { !$0.isMovie },
                    onMovieTap: onMovieTap
                )
            }
            .padding(.bottom, 100)
        }
    }
}

struct SimpleCategoriesTabView: View {
    let movies: [Movie]
    let onMovieTap: (Movie) -> Void
    @State private var selectedCategory = "All"
    
    let categories = ["All", "Action", "Comedy", "Drama", "Horror", "Sci-Fi", "Romance", "Thriller"]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Category Filter
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
                
                // Movies Grid
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
            .padding(.bottom, 100)
        }
    }
    
    private var filteredMovies: [Movie] {
        if selectedCategory == "All" {
            return movies
        }
        return movies.filter { movie in
            movie.genre.lowercased().contains(selectedCategory.lowercased())
        }
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
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
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
                    Button(action: onTap) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Play Now")
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
                .padding(.horizontal, 20)
            }
        }
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
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
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
                        .foregroundColor(.gray)
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
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ?
                    AnyView(LinearGradient(
                        gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )) : AnyView(Color.black.opacity(0.3))
                )
                .cornerRadius(20)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SimpleTabBar: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            SimpleTabButton(
                title: "Home",
                icon: "house.fill",
                isSelected: selectedTab == 0
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 0
                }
            }
            
            SimpleTabButton(
                title: "Categories",
                icon: "square.grid.2x2.fill",
                isSelected: selectedTab == 1
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 1
                }
            }
            
            SimpleTabButton(
                title: "Downloads",
                icon: "arrow.down.circle.fill",
                isSelected: selectedTab == 2
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 2
                }
            }
            
            SimpleTabButton(
                title: "My List",
                icon: "heart.fill",
                isSelected: selectedTab == 3
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 3
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color.black.opacity(0.9)
                .blur(radius: 10)
        )
    }
}

struct SimpleTabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gray)
                
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                AnyView(LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )) : AnyView(Color.clear)
            )
            .cornerRadius(12)
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
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
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
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "play.fill")
                                    Text("Play Now")
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
    }
}

#Preview {
    SimpleContentView()
}
