import SwiftUI

@main
struct CinemoraApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authService = LocalAuthService.shared
    @StateObject private var profileService = ProfileService.shared
    @StateObject private var myListService = MyListService.shared
    @StateObject private var watchProgressService = WatchProgressService.shared
    @StateObject private var watchPartyService = WatchPartyService.shared

    var body: some Scene {
        WindowGroup {
            if profileService.currentProfile == nil {
                ProfileSelectionView()
                    .environmentObject(authService)
                    .environmentObject(profileService)
                    .environmentObject(myListService)
                    .environmentObject(watchProgressService)
                    .environmentObject(watchPartyService)
            } else {
                SimpleContentView()
                    .environmentObject(authService)
                    .environmentObject(profileService)
                    .environmentObject(myListService)
                    .environmentObject(watchProgressService)
                    .environmentObject(watchPartyService)
            }
        }
    }
}
