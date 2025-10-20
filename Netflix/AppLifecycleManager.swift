import Foundation
import UIKit

class AppLifecycleManager: ObservableObject {
    static let shared = AppLifecycleManager()
    
    private init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc private func appWillTerminate() {
        print("App is about to terminate - saving data...")
        saveAllData()
    }
    
    @objc private func appDidEnterBackground() {
        print("App entered background - saving data...")
        saveAllData()
    }
    
    @objc private func appWillEnterForeground() {
        print("App will enter foreground")
    }
    
    private func saveAllData() {
        // Save Core Data context
        let context = PersistenceController.shared.container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("Core Data context saved successfully")
            } catch {
                print("Error saving Core Data context: \(error)")
            }
        }
        
        // Force save UserDefaults
        UserDefaults.standard.synchronize()
        print("UserDefaults synchronized")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
