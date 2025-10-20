//
//  ProfileSelectionView.swift
//  Netflix
//
//  Created by Chirag Dodia on 9/2/25.
//

import SwiftUI

struct AppUserProfile: Identifiable, Codable {
    let id = UUID()
    let name: String
    let iconColor: String
    let userEmail: String
    let createdAt: Date
    
    var colorValue: Color {
        switch iconColor {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "cyan": return .cyan
        default: return .red
        }
    }
}

class ProfileService: ObservableObject {
    static let shared = ProfileService()
    
    @Published var profiles: [AppUserProfile] = []
    @Published var currentProfile: AppUserProfile?
    
    private let profilesKey = "user_profiles"
    private let currentProfileKey = "current_profile_id"
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadProfiles()
    }
    
    func loadProfiles(for userEmail: String? = nil, autoSelectProfile: Bool = false) {
        guard let data = userDefaults.data(forKey: profilesKey),
              let allProfiles = try? JSONDecoder().decode([AppUserProfile].self, from: data) else {
            profiles = []
            currentProfile = nil
            return
        }
        
        if let email = userEmail {
            profiles = allProfiles.filter { $0.userEmail == email }
        } else {
            profiles = allProfiles
        }
        
        if autoSelectProfile {
            loadCurrentProfile()
        }
    }
    
    func createProfile(name: String, iconColor: String, userEmail: String) {
        let newProfile = AppUserProfile(
            name: name,
            iconColor: iconColor,
            userEmail: userEmail,
            createdAt: Date()
        )
        
        var allProfiles = getAllProfiles()
        allProfiles.append(newProfile)
        saveAllProfiles(allProfiles)
        
        profiles.append(newProfile)
        selectProfile(newProfile)
    }
    
    func selectProfile(_ profile: AppUserProfile) {
        print("👤 Selecting profile: \(profile.name) (ID: \(profile.id))")
        currentProfile = profile
        if let data = try? JSONEncoder().encode(profile.id) {
            userDefaults.set(data, forKey: currentProfileKey)
        }
        print("   Current profile set to: \(currentProfile?.name ?? "nil")")
    }
    
    func deleteProfile(_ profile: AppUserProfile) {
        var allProfiles = getAllProfiles()
        allProfiles.removeAll { $0.id == profile.id }
        saveAllProfiles(allProfiles)
        
        profiles.removeAll { $0.id == profile.id }
        
        if currentProfile?.id == profile.id {
            currentProfile = profiles.first
            if let first = profiles.first {
                selectProfile(first)
            } else {
                userDefaults.removeObject(forKey: currentProfileKey)
            }
        }
    }
    
    func clearCurrentProfile() {
        currentProfile = nil
        userDefaults.removeObject(forKey: currentProfileKey)
    }
    
    func resetForNewUser() {
        currentProfile = nil
        profiles = []
        userDefaults.removeObject(forKey: currentProfileKey)
    }
    
    private func getAllProfiles() -> [AppUserProfile] {
        guard let data = userDefaults.data(forKey: profilesKey),
              let profiles = try? JSONDecoder().decode([AppUserProfile].self, from: data) else {
            return []
        }
        return profiles
    }
    
    private func saveAllProfiles(_ profiles: [AppUserProfile]) {
        if let data = try? JSONEncoder().encode(profiles) {
            userDefaults.set(data, forKey: profilesKey)
        }
    }
    
    private func loadCurrentProfile() {
        guard let data = userDefaults.data(forKey: currentProfileKey),
              let profileId = try? JSONDecoder().decode(UUID.self, from: data) else {
            currentProfile = profiles.first
            return
        }
        
        currentProfile = profiles.first { $0.id == profileId }
    }
}

struct ProfileSelectionView: View {
    @EnvironmentObject var profileService: ProfileService
    @EnvironmentObject var authService: LocalAuthService
    @State private var showCreateProfile = false
    @State private var showManageProfiles = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color.red.opacity(0.2),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with logo
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)
                            
                            HStack(spacing: 2) {
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 3, height: 12)
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 3, height: 12)
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 3, height: 12)
                            }
                        }
                        
                        Text("Cinemora")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 60)
                    
                    Text("Who's watching?")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Profiles Grid
                if profileService.profiles.isEmpty {
                    EmptyProfilesView(showCreateProfile: $showCreateProfile)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 30) {
                            ForEach(profileService.profiles) { profile in
                                ProfileCard(profile: profile) {
                                    profileService.selectProfile(profile)
                                }
                            }
                            
                            // Add Profile Button
                            if profileService.profiles.count < 4 {
                                AddProfileCard {
                                    showCreateProfile = true
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                }
                
                Spacer()
                
                // Manage Profiles Button
                if !profileService.profiles.isEmpty {
                    Button(action: {
                        showManageProfiles = true
                    }) {
                        Text("Manage Profiles")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 32)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showCreateProfile) {
            CreateProfileView { name, color in
                if let userEmail = authService.currentUser?.email {
                    profileService.createProfile(name: name, iconColor: color, userEmail: userEmail)
                }
            }
        }
        .sheet(isPresented: $showManageProfiles) {
            ManageProfilesView()
        }
        .onAppear {
            if let userEmail = authService.currentUser?.email {
                // Load profiles without auto-selecting one
                profileService.loadProfiles(for: userEmail, autoSelectProfile: false)
                
                // If no profiles exist, show create profile sheet automatically
                if profileService.profiles.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showCreateProfile = true
                    }
                }
            }
        }
    }
}

// MARK: - Profile Card
struct ProfileCard: View {
    let profile: AppUserProfile
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            onTap()
        }) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    profile.colorValue,
                                    profile.colorValue.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Text(String(profile.name.prefix(1).uppercased()))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
                
                Text(profile.name)
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Profile Card
struct AddProfileCard: View {
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
            onTap()
        }) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                    
                    Image(systemName: "plus")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(.white)
                }
                .scaleEffect(isPressed ? 0.95 : 1.0)
                
                Text("Add Profile")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty Profiles View
struct EmptyProfilesView: View {
    @Binding var showCreateProfile: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.5))
            
            VStack(spacing: 12) {
                Text("Create Your Profile")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("You can create up to 4 profiles")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Each profile has its own personalized experience")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                showCreateProfile = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                    Text("Create Your First Profile")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 40)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
}

// MARK: - Create Profile View
struct CreateProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileService: ProfileService
    @State private var profileName = ""
    @State private var selectedColor = "red"
    
    let colors = ["red", "blue", "green", "yellow", "purple", "orange", "pink", "cyan"]
    let onCreate: (String, String) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 30) {
                    VStack(spacing: 8) {
                        Text("Create Profile")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Profile \(profileService.profiles.count + 1) of 4")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 20)
                    
                    // Profile Icon Preview
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        colorFromString(selectedColor),
                                        colorFromString(selectedColor).opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Text(profileName.isEmpty ? "?" : String(profileName.prefix(1).uppercased()))
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Name Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        TextField("Enter profile name", text: $profileName)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    .padding(.horizontal, 32)
                    
                    // Color Selection
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Choose Color")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(colors, id: \.self) { color in
                                    ColorOption(
                                        color: color,
                                        isSelected: selectedColor == color
                                    ) {
                                        selectedColor = color
                                    }
                                }
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                    
                    Spacer()
                    
                    // Create Button
                    Button(action: {
                        onCreate(profileName, selectedColor)
                        dismiss()
                    }) {
                        Text("Create Profile")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red, Color.red.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .disabled(profileName.isEmpty)
                    .opacity(profileName.isEmpty ? 0.5 : 1.0)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "cyan": return .cyan
        default: return .red
        }
    }
}

// MARK: - Color Option
struct ColorOption: View {
    let color: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(colorFromString(color))
                    .frame(width: 60, height: 60)
                
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 70, height: 70)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "cyan": return .cyan
        default: return .red
        }
    }
}

// MARK: - Manage Profiles View
struct ManageProfilesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var profileService: ProfileService
    @State private var showDeleteConfirmation = false
    @State private var profileToDelete: AppUserProfile?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Profile count indicator
                    HStack {
                        Text("Profiles: \(profileService.profiles.count)/4")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        if profileService.profiles.count < 4 {
                            Text("You can add \(4 - profileService.profiles.count) more")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        } else {
                            Text("Maximum profiles reached")
                                .font(.caption)
                                .foregroundColor(.red.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                    
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 30) {
                            ForEach(profileService.profiles) { profile in
                                ManageProfileCard(profile: profile) {
                                    profileToDelete = profile
                                    showDeleteConfirmation = true
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                }
            }
            .navigationTitle("Manage Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .alert("Delete Profile", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let profile = profileToDelete {
                    profileService.deleteProfile(profile)
                }
            }
        } message: {
            Text("Are you sure you want to delete this profile? This action cannot be undone.")
        }
    }
}

// MARK: - Manage Profile Card
struct ManageProfileCard: View {
    let profile: AppUserProfile
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    profile.colorValue,
                                    profile.colorValue.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Text(String(profile.name.prefix(1).uppercased()))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Button(action: onDelete) {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .offset(x: 10, y: -10)
            }
            
            Text(profile.name)
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ProfileSelectionView()
}

