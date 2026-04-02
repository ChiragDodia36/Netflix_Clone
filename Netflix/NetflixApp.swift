import SwiftUI

@main
struct NetflixApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authService = LocalAuthService.shared
    @StateObject private var profileService = ProfileService.shared
    @StateObject private var myListService = MyListService.shared
    @StateObject private var watchProgressService = WatchProgressService.shared

    var body: some Scene {
        WindowGroup {
            SimpleContentView()
                .environmentObject(authService)
                .environmentObject(profileService)
                .environmentObject(myListService)
                .environmentObject(watchProgressService)
                .onAppear {
                    // Auto-create a default profile so My List works
                    if profileService.currentProfile == nil {
                        let defaultProfile = AppUserProfile(
                            name: "Guest",
                            iconColor: "red",
                            userEmail: "guest@cinemora.app",
                            createdAt: Date()
                        )
                        profileService.profiles = [defaultProfile]
                        profileService.currentProfile = defaultProfile
                    }
                }
        }
    }
}

