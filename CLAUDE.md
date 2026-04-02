# Cinemora — Netflix Clone (iOS)

## Project Overview

**Cinemora** is a Netflix-clone streaming platform built entirely with SwiftUI for iOS 18.4+. It replicates core Netflix features and adds unique differentiators not found on Netflix (Custom Collections, Community Reviews, X-Ray, Watch Party).

**Bundle ID:** Netflix  
**Xcode project:** `Netflix.xcodeproj`  
**Entry point:** `Netflix/NetflixApp.swift`

---

## Architecture

**Pattern:** MVVM with SwiftUI  
**State management:** `@StateObject` (initialization) → `@EnvironmentObject` (child access) → `@Published` (reactive updates)  
**Persistence:** UserDefaults (primary) + Core Data (defined, not yet actively used)  
**Singletons:** Services use `static let shared` pattern for cross-view access

**App flow:**
```
NetflixApp
  └── if isAuthenticated
        └── if currentProfile selected
              └── SimpleContentView (main 4-tab hub)
        └── else ProfileSelectionView
      else AuthView
```

---

## Key Files

| File | Responsibility |
|------|---------------|
| `Netflix/NetflixApp.swift` | App entry point, injects EnvironmentObjects |
| `Netflix/SimpleContentView.swift` | Main tab hub (Home, Categories, Downloads, My List) — 1100+ lines |
| `Netflix/MovieData.swift` | `Movie` model + `MovieService` (falls back to 12 hardcoded sample movies) |
| `Netflix/LocalAuthService.swift` | Email/password auth, UserDefaults persistence |
| `Netflix/ProfileSelectionView.swift` | `ProfileService` + profile CRUD UI (up to 4 profiles) |
| `Netflix/MyListService.swift` | Profile-scoped watchlist, UserDefaults |
| `Netflix/SearchView.swift` | Real-time search UI with filter integration |
| `Netflix/SearchService.swift` | Search logic, history, relevance sorting |
| `Netflix/SearchFiltersView.swift` | Advanced filter sheet (genre, type, rating, year, duration) |
| `Netflix/ContentService.swift` | Seeds sample data into Core Data |
| `Netflix/Persistence.swift` | Core Data stack (PersistenceController) |
| `Netflix/AppLifecycleManager.swift` | Saves context on app backgrounding/termination |

---

## Coding Conventions

- **File size:** Keep files under 400 lines. If a file grows beyond this, split by responsibility.
- **Services:** Follow the existing singleton pattern (`static let shared = ServiceName()`), conform to `ObservableObject`, use `@Published` for reactive state.
- **Views:** One `View` struct per file for new files. Sub-views (small, file-private) may live in the same file as their parent.
- **Models:** Plain `struct` types, `Identifiable + Codable` for anything persisted.
- **Persistence:** New features use UserDefaults (same as existing services) until Core Data migration is planned.
- **API keys:** Store in `Info.plist` under descriptive keys (e.g., `TMDBAPIKey`). Never hardcode in Swift files.
- **No force unwrap:** Use `guard let` / `if let` / `??` defaults throughout.
- **SwiftUI previews:** Optional — skip unless explicitly requested.
- **Comments:** Only where logic is non-obvious. No docstrings on every function.

---

## Environment Objects (injected in NetflixApp.swift)

```swift
@StateObject var authService = LocalAuthService()
@StateObject var profileService = ProfileService()
@StateObject var myListService = MyListService()
```

New services that need app-wide access should be added here.

---

## Data Models

### Movie
```swift
struct Movie: Identifiable {
    let id: UUID
    let title: String
    let posterURL: String        // TMDB image path or full URL
    let backdropURL: String
    let releaseYear: Int
    let rating: String          // "TV-14", "R", etc.
    let duration: Int           // minutes
    let genre: String           // comma-separated
    let isMovie: Bool
    let isTrending: Bool
    let isFeatured: Bool
    let description: String
}
```

### AppUserProfile
```swift
struct AppUserProfile: Identifiable, Codable {
    let id: UUID
    let name: String
    let iconColor: String       // color name string
    let userEmail: String       // FK to LocalUser.email
    let createdAt: Date
}
```

---

## UserDefaults Keys

| Key | Type | Owner |
|-----|------|-------|
| `local_users` | `[LocalUser]` | LocalAuthService |
| `current_user_email` | `String` | LocalAuthService |
| `user_profiles` | `[AppUserProfile]` | ProfileService |
| `current_profile_id` | `UUID` | ProfileService |
| `my_list_items` | `[MyListItem]` | MyListService |
| `search_history` | `[String]` | SearchService |
| `watch_progress_items` | `[WatchProgress]` | WatchProgressService |

New features should document their keys here.

---

## Feature Status

| Feature | Status |
|---------|--------|
| Authentication (email/password) | Done |
| Profile management (up to 4) | Done |
| Home tab (hero + 4 sections) | Done (hardcoded data) |
| Categories tab (genre filter + grid) | Done |
| My List tab (profile-scoped) | Done |
| Search + advanced filters | Done |
| Downloads tab | Empty placeholder |
| **A — TMDB API Integration** | Done |
| **B — Video Playback (AVPlayer/Vimeo)** | Done |
| **F — Continue Watching** | Done |
| **H — Viewing History** | Done |
| **I — Recommendations Engine** | Planned (Priority 5) |
| **C — Custom Collections** | Planned (Priority 6) |
| **D — Community Reviews & Ratings** | Planned (Priority 7) |
| **E — X-Ray Scene Intelligence** | Planned (Priority 8) |
| **G — Download for Offline** | Planned (Priority 9) |
| **J — Watch Party** | Planned (Priority 10) |

---

## TMDB API

- Register at [themoviedb.org](https://www.themoviedb.org) (free)
- Store key in `Info.plist` as `TMDBAPIKey`
- Base URL: `https://api.themoviedb.org/3`
- Image base URL: `https://image.tmdb.org/t/p/w500` (poster) / `w1280` (backdrop)

---

## Known Issues / Tech Debt

- Passwords stored in plaintext in UserDefaults (should use CryptoKit SHA-256 or Keychain)
- `SimpleContentView.swift` is 1100+ lines — split into sub-files when touching it
- Core Data models defined but not used (UserDefaults is primary store)
- No unit tests yet
