//
//  LocalAuthService.swift
//  Netflix
//
//  Created by Chirag Dodia on 9/2/25.
//

import Foundation
import SwiftUI

// Simple user model for local storage
struct LocalUser: Identifiable, Codable {
    let id = UUID()
    let email: String
    let password: String
    let firstName: String?
    let lastName: String?
    let createdAt: Date
    
    var displayName: String {
        if let first = firstName, let last = lastName {
            return "\(first) \(last)"
        } else if let first = firstName {
            return first
        } else {
            return email
        }
    }
}

class LocalAuthService: ObservableObject {
    static let shared = LocalAuthService()
    
    @Published var currentUser: LocalUser?
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let usersKey = "local_users"
    private let currentUserKey = "current_user_email"
    
    private init() {
        loadCurrentUser()
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String, firstName: String? = nil, lastName: String? = nil) -> Result<LocalUser, AuthError> {
        // Validate input
        guard isValidEmail(email) else {
            return .failure(.invalidEmail)
        }
        
        guard password.count >= 6 else {
            return .failure(.passwordTooShort)
        }
        
        // Check if user already exists
        if userExists(email: email) {
            return .failure(.userAlreadyExists)
        }
        
        // Create new user
        let newUser = LocalUser(
            email: email.lowercased(),
            password: password, // In a real app, you'd hash this
            firstName: firstName,
            lastName: lastName,
            createdAt: Date()
        )
        
        // Save user to local storage
        var users = getAllUsers()
        users.append(newUser)
        saveUsers(users)
        
        // Set as current user
        currentUser = newUser
        isAuthenticated = true
        saveCurrentUser(email: email)
        
        return .success(newUser)
    }
    
    func signIn(email: String, password: String) -> Result<LocalUser, AuthError> {
        // Validate input
        guard isValidEmail(email) else {
            return .failure(.invalidEmail)
        }
        
        guard !password.isEmpty else {
            return .failure(.invalidPassword)
        }
        
        // Find user
        guard let user = getUser(email: email) else {
            return .failure(.userNotFound)
        }
        
        // Verify password
        guard user.password == password else {
            return .failure(.invalidPassword)
        }
        
        // Set as current user
        currentUser = user
        isAuthenticated = true
        saveCurrentUser(email: email)
        
        return .success(user)
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        userDefaults.removeObject(forKey: currentUserKey)
    }
    
    // MARK: - Helper Methods
    
    private func getAllUsers() -> [LocalUser] {
        guard let data = userDefaults.data(forKey: usersKey),
              let users = try? JSONDecoder().decode([LocalUser].self, from: data) else {
            return []
        }
        return users
    }
    
    private func saveUsers(_ users: [LocalUser]) {
        if let data = try? JSONEncoder().encode(users) {
            userDefaults.set(data, forKey: usersKey)
        }
    }
    
    private func getUser(email: String) -> LocalUser? {
        let users = getAllUsers()
        return users.first { $0.email == email.lowercased() }
    }
    
    private func userExists(email: String) -> Bool {
        return getUser(email: email) != nil
    }
    
    private func saveCurrentUser(email: String) {
        userDefaults.set(email, forKey: currentUserKey)
    }
    
    private func loadCurrentUser() {
        if let email = userDefaults.string(forKey: currentUserKey),
           let user = getUser(email: email) {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidEmail
    case passwordTooShort
    case userAlreadyExists
    case userNotFound
    case invalidPassword
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .passwordTooShort:
            return "Password must be at least 6 characters long"
        case .userAlreadyExists:
            return "An account with this email already exists"
        case .userNotFound:
            return "No account found with this email"
        case .invalidPassword:
            return "Invalid password"
        }
    }
}
