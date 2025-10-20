//
//  Persistence.swift
//  Netflix
//
//  Created by Chirag Dodia on 9/2/25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<10 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Netflix")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Handle Core Data migration errors by deleting and recreating
                if error.code == 134110 { // NSCocoaErrorDomain migration error
                    print("Core Data migration failed. Deleting and recreating database...")
                    
                    // Get the store URL
                    guard let storeURL = storeDescription.url else {
                        fatalError("Could not get store URL")
                    }
                    
                    // Delete the existing store and related files
                    do {
                        try FileManager.default.removeItem(at: storeURL)
                        // Also delete the .wal and .shm files if they exist
                        let walURL = storeURL.appendingPathExtension("wal")
                        let shmURL = storeURL.appendingPathExtension("shm")
                        try? FileManager.default.removeItem(at: walURL)
                        try? FileManager.default.removeItem(at: shmURL)
                        
                        print("Successfully deleted old database")
                        
                        // Try to load the store again with a fresh container
                        let freshContainer = NSPersistentContainer(name: "Netflix")
                        freshContainer.loadPersistentStores { _, newError in
                            if let newError = newError {
                                fatalError("Failed to recreate database: \(newError)")
                            } else {
                                print("Successfully recreated database with new schema")
                            }
                        }
                    } catch {
                        fatalError("Failed to delete old database: \(error)")
                    }
                } else {
                    // Other Core Data errors
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
