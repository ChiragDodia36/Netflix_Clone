# Cinemora — Implementation Plan

> Living document. Update status after each feature ships.

---

## Implementation Order

| Priority | ID | Feature | Status | Notes |
|----------|----|---------|--------|-------|
| 0 | — | Project docs (CLAUDE.md + this file) | **Done** | |
| 1 | A | TMDB API Integration | Planned | Requires TMDB API key |
| 2 | B | Video Playback (AVPlayer) | Planned | Depends on A |
| 3 | F | Continue Watching | Planned | Depends on B |
| 4 | H | Viewing History | Planned | Depends on F |
| 5 | I | Recommendations Engine | Planned | Depends on H |
| 6 | C | Custom Collections / Playlists | Planned | Independent |
| 7 | D | Community Reviews & 5-Star Ratings | Planned | Independent |
| 8 | E | X-Ray Scene Intelligence | Planned | Depends on B |
| 9 | G | Download for Offline | Planned | Depends on B |
| 10 | J | Watch Party | Planned | Depends on B, uses Supabase Realtime |

---

## Feature A — TMDB API Integration

**Goal:** Replace 12 hardcoded sample movies with live TMDB data.

**New files:**
- `Netflix/Services/TMDBService.swift`
- `Netflix/Models/TMDBModels.swift`
- `Netflix/Services/ImageCacheService.swift`

**Modified files:**
- `Netflix/MovieData.swift` — replace sampleMovies with TMDB fetch
- `Netflix/SearchService.swift` — wire to TMDBService for search

**Endpoints:**
- `GET /trending/all/week`
- `GET /movie/popular`
- `GET /tv/popular`
- `GET /search/multi?query=`
- `GET /movie/{id}/videos` (trailers)
- `GET /movie/{id}/credits` (cast, for X-Ray later)

**Setup:**
1. Get free API key from themoviedb.org
2. Add to Info.plist as `TMDBAPIKey`
3. Image base URL: `https://image.tmdb.org/t/p/w500`

**Verification:** Home shows real posters; search returns live results; app works offline with sample fallback.

---

## Feature B — Video Playback (AVPlayer)

**Goal:** Make "Play Now" button launch a real video player.

**New files:**
- `Netflix/Views/VideoPlayerView.swift`
- `Netflix/Views/PlayerOverlayView.swift`
- `Netflix/Services/PlaybackService.swift`

**Modified files:**
- `Netflix/SimpleContentView.swift` — wire Play Now button to VideoPlayerView

**Approach:**
- YouTube trailers via WKWebView (from TMDB trailer URLs)
- HLS demo streams via AVPlayer for AVKit integration
- Custom controls overlay (play/pause, scrubber, back)

**Verification:** Tap Play Now → video plays fullscreen; back button dismisses cleanly.

---

## Feature F — Continue Watching

**Goal:** Track where the user left off; show resume row on Home.

**New files:**
- `Netflix/Models/WatchProgress.swift`
- `Netflix/Services/WatchProgressService.swift`

**Modified files:**
- `Netflix/Services/PlaybackService.swift` — call WatchProgressService.save() on pause/exit
- `Netflix/SimpleContentView.swift` — add "Continue Watching" row above Trending

**Verification:** Play 30s, exit, reopen → appears in Continue Watching with progress bar.

---

## Feature H — Viewing History

**Goal:** Full per-profile watch history.

**New files:**
- `Netflix/Models/WatchHistory.swift`
- `Netflix/Services/HistoryService.swift`

**Modified files:**
- `Netflix/Services/WatchProgressService.swift` — write to HistoryService at >90% watched
- `Netflix/ProfileSelectionView.swift` — add "Viewing History" section in profile settings

**Verification:** Watch movie → appears in history → can remove individual items.

---

## Feature I — Recommendations Engine

**Goal:** "Because You Watched X" rows on Home.

**New files:**
- `Netflix/Services/RecommendationService.swift`

**Modified files:**
- `Netflix/SimpleContentView.swift` — add dynamic recommendation rows on Home tab

**TMDB endpoints:**
- `GET /movie/{id}/recommendations`
- `GET /tv/{id}/recommendations`

**Verification:** Watch 3 movies in same genre → recommendation row appears on Home.

---

## Feature C — Custom Collections / Playlists

**Goal:** Users create named folders to organize their saves.

**New files:**
- `Netflix/Models/Collection.swift`
- `Netflix/Services/CollectionService.swift`
- `Netflix/Views/CollectionsView.swift`
- `Netflix/Views/CreateCollectionView.swift`
- `Netflix/Views/CollectionDetailView.swift`

**Modified files:**
- `Netflix/SimpleContentView.swift` — "Add to Collection" in movie action sheet; Collections grid on My List tab

**UX:** Long-press movie → Add to Collection → pick or create folder → collections shown as cover-art grid.

**Verification:** Create collection, add movies, view detail, remove movie.

---

## Feature D — Community Reviews & 5-Star Ratings

**Goal:** Bring back star ratings and reviews that Netflix removed in 2018.

**New files:**
- `Netflix/Models/Review.swift`
- `Netflix/Services/ReviewService.swift`
- `Netflix/Views/ReviewsView.swift`
- `Netflix/Views/WriteReviewView.swift`

**Modified files:**
- `Netflix/SimpleContentView.swift` (MovieDetailView) — add Reviews tab

**Verification:** Write review, see aggregate star rating on card, spoiler toggle hides/reveals text.

---

## Feature E — X-Ray Scene Intelligence

**Goal:** Amazon Prime-style cast overlay when video is paused.

**New files:**
- `Netflix/Views/XRayOverlayView.swift`
- `Netflix/Models/XRayData.swift`
- `Netflix/Services/XRayService.swift`

**Modified files:**
- `Netflix/Views/VideoPlayerView.swift` — show overlay on pause state

**TMDB endpoint:** `GET /movie/{id}/credits`

**Verification:** Pause video → cast overlay appears; tap actor → brief info card.

---

## Feature G — Download for Offline

**Goal:** Fill the empty Downloads tab; allow offline viewing.

**New files:**
- `Netflix/Services/DownloadService.swift`
- `Netflix/Views/DownloadsView.swift`
- `Netflix/Models/DownloadedItem.swift`

**Modified files:**
- `Netflix/SimpleContentView.swift` — replace empty Downloads tab with DownloadsView

**Note:** Requires HLS streams (YouTube trailers cannot be downloaded via AVAssetDownloadTask).

**Verification:** Download movie → progress shown → appears in Downloads tab → plays offline.

---

## Feature J — Watch Party

**Goal:** Synchronized co-watching with real-time chat.

**Backend:** Supabase Realtime (available via MCP)

**New files:**
- `Netflix/Services/WatchPartyService.swift`
- `Netflix/Models/WatchPartySession.swift`
- `Netflix/Models/ChatMessage.swift`
- `Netflix/Views/WatchPartyView.swift`
- `Netflix/Views/WatchPartyChatOverlayView.swift`

**Modified files:**
- `Netflix/Views/VideoPlayerView.swift` — broadcast/receive sync events
- `Netflix/SimpleContentView.swift` (MovieDetailView) — "Watch Together" button

**Sync strategy:** Host is source of truth. Guests snap to host position within 2s tolerance.

**Verification:** Create session → share 6-char code → friend joins → countdown → sync playback → chat works.

---

## Dependency Graph

```
A (TMDB)
└── B (Playback)
    ├── F (Continue Watching)
    │   └── H (Viewing History)
    │       └── I (Recommendations)
    ├── E (X-Ray)
    ├── G (Downloads)
    └── J (Watch Party)

C (Collections)  — independent
D (Reviews)      — independent
```
