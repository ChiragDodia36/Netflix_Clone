//
//  AppDelegate.swift
//  Netflix
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    // Controlled by VideoPlayerView to lock/unlock orientation
    static var orientationLock: UIInterfaceOrientationMask = .portrait

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        // Allow landscape inside SFSafariViewController (YouTube player)
        return .allButUpsideDown
    }
}
