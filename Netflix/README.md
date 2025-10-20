# 🎬 Cinemora - Netflix Clone iOS App

A beautiful, feature-rich streaming platform clone built with SwiftUI, offering a complete Netflix-like experience with local authentication and profile management.

[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2018.4+-lightgrey.svg)](https://developer.apple.com/ios/)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0-blue.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📱 Overview

Cinemora is a fully functional streaming platform application that replicates the core features of Netflix. Built entirely with SwiftUI, it provides a modern, intuitive interface for browsing, searching, and managing your favorite movies and TV shows. All data is stored locally, making it perfect for learning iOS development or as a portfolio project.

---

## ✨ Features

### 🔐 Authentication System
- **Local Authentication**: Secure email/password authentication stored locally
- **Sign Up & Sign In**: Beautiful onboarding flow with form validation
- **Session Persistence**: Stay logged in across app launches
- **Secure Logout**: Clean session termination with confirmation alerts

![Authentication Flow]()

---

### 👥 Profile Management
- **Multiple Profiles**: Create up to 4 profiles per account
- **Personalized Experience**: Each profile maintains independent preferences
- **Custom Profile Icons**: Choose from 8 vibrant colors for your profile avatar
- **Profile Switching**: Seamlessly switch between profiles
- **Profile Management**: Add, edit, and delete profiles with ease

![Profile Selection]()
---

### 🏠 Home Experience
- **Hero Section**: Featured content with stunning backdrop images
- **Content Categories**: 
  - Trending Now
  - New Releases
  - Movies
  - TV Shows
- **Smooth Scrolling**: Horizontal and vertical scroll views
- **Beautiful Card Design**: Modern movie/show cards with shadow effects
- **Tab Navigation**: Easy access to Home, Categories, Downloads, and My List

![Home Screen]()

---

### 🔍 Advanced Search
- **Real-time Search**: Instant results as you type
- **Comprehensive Filters**:
  - Content Type (Movies, TV Shows, All)
  - Genres (Action, Comedy, Drama, Horror, Sci-Fi, Romance, Thriller, etc.)
  - Content Rating (G, PG, PG-13, R, TV-MA, etc.)
  - Release Year (Min/Max year selectors)
  - Duration (Min/Max duration in minutes)
- **Filter Persistence**: Active filters displayed with removable tags
- **Search History**: Track your recent searches

![Search & Filters]()

---

### 📂 Categories Browser
- **Genre Filtering**: Quick category chips for easy browsing
- **Grid Layout**: Clean 2-column grid for optimal viewing
- **Dynamic Filtering**: Instant results when selecting categories
- **Smooth Animations**: Spring animations for category selection

![Categories View]()

---

### ❤️ My List (Profile-Specific)
- **Personal Collections**: Each profile has its own independent My List
- **Add to List**: One-tap adding from movie details or hero section
- **Visual Feedback**: Green checkmark when item is in your list
- **Easy Removal**: Remove items directly from My List tab or detail view
- **Item Counter**: See how many items are in your list
- **Empty State**: Helpful message when list is empty

![My List]()

---

### 🎥 Movie/Show Details
- **Full-Screen Posters**: High-quality movie artwork
- **Comprehensive Info**: Title, rating, year, duration, genre, description
- **Action Buttons**:
  - Play Now (primary action)
  - Add to My List (toggleable)
  - Download (coming soon)
- **Gradient Overlays**: Beautiful visual effects
- **Close Gesture**: Easy dismissal with X button

![Movie Details]()

---

### 🎨 Modern UI/UX
- **Netflix-Inspired Design**: Familiar, professional interface
- **Custom Color Scheme**: Red accent colors with dark theme
- **Smooth Animations**: Spring animations and transitions throughout
- **Haptic Feedback**: Touch feedback for better user experience
- **Responsive Layout**: Adapts to different screen sizes
- **Custom Components**: Reusable UI components

---

## 🛠 Technical Highlights

### Architecture
- **MVVM Pattern**: Clean separation of concerns
- **ObservableObject**: Reactive state management
- **Singleton Services**: Centralized business logic
- **Environment Objects**: Efficient data passing across views

### Data Persistence
- **UserDefaults**: Local data storage for users, profiles, and My List
- **Core Data Ready**: Integration with Core Data models (User, UserProfile, Content)
- **JSON Encoding**: Reliable data serialization

### UI Components
- **SwiftUI**: 100% SwiftUI implementation
- **Custom Modifiers**: Reusable styling components
- **Adaptive Layouts**: LazyVGrid, LazyVStack for performance
- **AsyncImage**: Efficient image loading with placeholders

---

## 📸 Screenshots

### Authentication
| Login | Sign Up |
<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2025-10-20 at 12 41 00" src="https://github.com/user-attachments/assets/f5527cbc-7ded-4ebc-849f-02f74fe685e5" />
<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2025-10-20 at 12 42 02" src="https://github.com/user-attachments/assets/24bf5ac2-985c-4095-8405-d9423dab0ae0" />

### Profile Management
| Profile Selection | Create Profile | Manage Profiles |
<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2025-10-20 at 12 42 45" src="https://github.com/user-attachments/assets/9ff9b287-501d-4d41-bbf6-7ed6faf74034" />


### Main Experience
<img width="1206" height="2622" alt="Simulator Screenshot - iPhone 17 - 2025-10-20 at 12 43 03" src="https://github.com/user-attachments/assets/e2889363-d181-461c-a567-ab25a9294b83" />



## 🚀 Getting Started

### Prerequisites
- Xcode 15.0 or later
- iOS 18.4 or later
- macOS for development

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/cinemora.git
   cd cinemora
   ```

2. **Open in Xcode**
   ```bash
   open Netflix.xcodeproj
   ```

3. **Build and Run**
   - Select your target device or simulator
   - Press `⌘ + R` to build and run

### First Launch
1. Launch the app
2. Sign up with email and password
3. Create your first profile
4. Start browsing movies and shows!

---

## 💡 Key Features Deep Dive

### Profile-Specific My List
Each profile maintains its own My List, completely independent from other profiles. When you:
- Add "Stranger Things" to Profile A
- Switch to Profile B (empty list)
- Add "The Crown" to Profile B
- Switch back to Profile A → "Stranger Things" is still there!

### Advanced Search Filters
The search system allows you to filter content across multiple dimensions simultaneously:
- Filter by multiple genres at once
- Set year ranges (e.g., 2010-2020)
- Combine content type + rating + duration filters
- See active filters with one-tap removal

### Smooth Navigation
- Tab-based navigation with 4 main sections
- Profile menu accessible from any screen
- Quick search toggle from header
- Modal presentations for details and settings

---

## 🎯 Future Enhancements

- [ ] Video playback integration
- [ ] Download functionality for offline viewing
- [ ] Continue watching tracking
- [ ] Viewing history
- [ ] Recommendations engine
- [ ] Dark/Light theme toggle
- [ ] Parental controls
- [ ] Multiple language support
- [ ] Cast integration
- [ ] Social features (watch together)

---

## 🏗 Project Structure

```
Netflix/
├── App/
│   └── NetflixApp.swift              # App entry point
├── Authentication/
│   ├── AuthView.swift                # Login/Signup UI
│   └── LocalAuthService.swift        # Auth business logic
├── Profiles/
│   └── ProfileSelectionView.swift    # Profile management
├── Content/
│   ├── SimpleContentView.swift       # Main content view
│   ├── SearchView.swift              # Search interface
│   ├── SearchFiltersView.swift       # Advanced filters
│   └── MovieData.swift               # Movie models
├── Services/
│   ├── MyListService.swift           # My List management
│   ├── SearchService.swift           # Search logic
│   └── ContentService.swift          # Content fetching
├── Persistence/
│   ├── Persistence.swift             # Core Data stack
│   └── Netflix.xcdatamodeld/         # Data models
└── Resources/
    └── Assets.xcassets/              # App assets
```

---

## 🧪 Testing

The app includes comprehensive logging for debugging:
- 🎬 View lifecycle events
- 👤 Profile selection tracking
- ➕/➖ My List additions/removals
- 💾 Data persistence operations
- 🔍 Search and filter activities

Check the Xcode console for detailed logs during development.

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👏 Acknowledgments

- Inspired by Netflix's beautiful UI/UX design
- Built with SwiftUI and modern iOS development practices
- Movie data and images from TMDB (for demo purposes)

---

## 📧 Contact

**Chirag Dodia**
- GitHub: [@chiragdodia](https://github.com/chiragdodia)
- Email: your.email@example.com

---

## ⭐️ Show Your Support

Give a ⭐️ if this project helped you learn SwiftUI or iOS development!

---

<p align="center">Made with ❤️ and SwiftUI</p>

