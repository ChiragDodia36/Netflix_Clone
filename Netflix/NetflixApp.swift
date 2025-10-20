import SwiftUI

@main
struct NetflixApp: App {
    @StateObject private var authService = LocalAuthService.shared
    @StateObject private var profileService = ProfileService.shared
    @StateObject private var myListService = MyListService.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    if profileService.currentProfile != nil {
                        SimpleContentView()
                    } else {
                        ProfileSelectionView()
                    }
                } else {
                    AuthView()
                }
            }
            .environmentObject(authService)
            .environmentObject(profileService)
            .environmentObject(myListService)
        }
    }
}

