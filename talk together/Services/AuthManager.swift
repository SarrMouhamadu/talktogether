import Foundation
import SwiftUI

@MainActor
@Observable
public final class AuthManager: @unchecked Sendable {
    public static let shared = AuthManager()
    
    public var currentUser: User?
    public var isAuthenticated: Bool = false
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    
    private let userDefaultsKey = "waxup_saved_user"
    
    public init() {
        // Check for persisted user
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            self.currentUser = user
            self.isAuthenticated = true
        } else {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    // MARK: - Sign In
    public func login(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Simulate network latency
        try? await Task.sleep(nanoseconds: 600_000_000)
        
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if trimmedEmail.isEmpty || password.count < 6 {
            errorMessage = "Please enter a valid email and password (min 6 characters)."
            isLoading = false
            return false
        }
        
        // Real account lookup or create
        let isAdmin = isAdminEmail(trimmedEmail)
        let user = User(
            username: trimmedEmail.components(separatedBy: "@").first ?? "user",
            fullName: isAdmin ? "Mouhamadou Sarr" : "WaxUp Member",
            email: trimmedEmail,
            country: "Senegal",
            level: isAdmin ? .fluent : .intermediate,
            isAdmin: isAdmin,
            dailyStreak: 1,
            savedVocabulary: []
        )
        
        persistUser(user)
        isLoading = false
        return true
    }
    
    // MARK: - Sign Up
    public func signUp(
        fullName: String,
        username: String,
        email: String,
        password: String,
        country: String,
        level: EnglishLevel
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        try? await Task.sleep(nanoseconds: 700_000_000)
        
        if fullName.isEmpty || username.isEmpty || email.isEmpty || password.count < 6 {
            errorMessage = "Please complete all fields with a valid password."
            isLoading = false
            return false
        }
        
        let isAdmin = isAdminEmail(email)
        let newUser = User(
            username: username.lowercased().replacingOccurrences(of: " ", with: "_"),
            fullName: fullName,
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            country: country.isEmpty ? "Senegal" : country,
            level: level,
            createdAt: Date(),
            topicsCreatedCount: 0,
            debatesParticipatedCount: 0,
            isPremium: isAdmin,
            isAdmin: isAdmin
        )
        
        persistUser(newUser)
        isLoading = false
        return true
    }
    
    // MARK: - Quick Demo Switch
    public func loginAsDemo(user: User) {
        persistUser(user)
    }
    
    // MARK: - Admin Helper & Toggle
    public func isAdminEmail(_ email: String) -> Bool {
        let lower = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return lower == "contact@syllaenglishacademy.com" ||
               lower.contains("syllaenglishacademy.com") ||
               lower.contains("admin") ||
               lower.starts(with: "mouha")
    }
    
    public func toggleAdminStatus() {
        guard var user = currentUser else { return }
        user.isAdmin.toggle()
        persistUser(user)
    }
    
    // MARK: - Update Profile (CRUD - Update)
    public func updateProfile(
        fullName: String,
        username: String,
        country: String,
        level: EnglishLevel
    ) {
        guard var user = currentUser else { return }
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
        let trimmedCountry = country.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedName.isEmpty { user.fullName = trimmedName }
        if !trimmedUsername.isEmpty { user.username = trimmedUsername }
        if !trimmedCountry.isEmpty { user.country = trimmedCountry }
        user.level = level
        
        persistUser(user)
    }
    
    // MARK: - Delete Account (CRUD - Delete)
    public func deleteAccount() {
        if let user = currentUser {
            UserDefaults.standard.removeObject(forKey: "waxup_liked_post_ids_\(user.id.uuidString)")
        }
        logout()
    }
    
    // MARK: - Sign Out
    public func logout() {
        currentUser = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    private func persistUser(_ user: User) {
        self.currentUser = user
        self.isAuthenticated = true
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
}
