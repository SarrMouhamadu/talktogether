import SwiftUI

public struct ProfileView: View {
    @Bindable public var authManager: AuthManager
    public var debateManager: DebateManager?
    
    @State private var isShowingEditProfile: Bool = false
    @State private var isShowingAdminDashboard: Bool = false
    @State private var isShowingDeleteAccountAlert: Bool = false
    @State private var versionTapCount: Int = 0
    @State private var adminToastMessage: String? = nil
    
    @MainActor
    public init(authManager: AuthManager, debateManager: DebateManager? = nil) {
        self.authManager = authManager
        self.debateManager = debateManager
    }
    
    private var user: User {
        authManager.currentUser ?? User.sampleModerator
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.space24) {
                    // Airy Apple Account-Style Header (Directly on Canvas)
                    VStack(spacing: AppTheme.space12) {
                        Circle()
                            .fill(AppTheme.surface)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Circle()
                                    .stroke(AppTheme.separator, lineWidth: 1)
                            )
                            .overlay(
                                Text(user.initials)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryText)
                            )
                        
                        VStack(spacing: 4) {
                            HStack(spacing: AppTheme.space6) {
                                Text(user.fullName)
                                    .font(.system(size: 21, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryText)
                                
                                if user.isPremium {
                                    Text("PRO")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(AppTheme.primaryBlue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AppTheme.primaryBlue.opacity(0.10))
                                        .clipShape(Capsule())
                                }
                            }
                            
                            Text("@\(user.username) · \(user.country)")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    .padding(.top, AppTheme.space8)
                    
                    // Compact Horizontal Statistics
                    HStack {
                        statItem(title: "Debates", value: "\(user.debatesParticipatedCount)")
                        
                        Rectangle()
                            .fill(AppTheme.separator)
                            .frame(width: 1, height: 28)
                        
                        statItem(title: "Streak", value: "\(user.dailyStreak)d")
                        
                        Rectangle()
                            .fill(AppTheme.separator)
                            .frame(width: 1, height: 28)
                        
                        statItem(title: "Topics", value: "\(user.topicsCreatedCount)")
                        
                        Rectangle()
                            .fill(AppTheme.separator)
                            .frame(width: 1, height: 28)
                        
                        statItem(title: "Level", value: user.level.rawValue.components(separatedBy: " ").first ?? "Intermediate")
                    }
                    .padding(.vertical, AppTheme.space16)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                            .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                    )
                    
                    // Admin Dashboard Entry (Visible to Admins only)
                    if user.isAdmin, let debateManager {
                        Button(action: { isShowingAdminDashboard = true }) {
                            HStack(spacing: AppTheme.space12) {
                                Image(systemName: "shield.lefthalf.filled")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryBlue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Admin Dashboard")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(AppTheme.primaryText)
                                    Text("Monitor users, posts, queue & reports")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                                
                                Spacer()
                                
                                if debateManager.pendingReportsCount > 0 {
                                    Text("\(debateManager.pendingReportsCount)")
                                        .font(.system(size: 12, weight: .bold).monospacedDigit())
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(AppTheme.liveRed)
                                        .clipShape(Capsule())
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.horizontal, AppTheme.space16)
                            .padding(.vertical, 14)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                                    .stroke(AppTheme.primaryBlue.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Clean Grouped Settings
                    VStack(spacing: 0) {
                        Button(action: { isShowingEditProfile = true }) {
                            HStack(spacing: AppTheme.space12) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.primaryText)
                                    .frame(width: 24)
                                
                                Text("Edit Profile")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.primaryText)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.horizontal, AppTheme.space16)
                            .frame(height: 50)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Rectangle()
                            .fill(AppTheme.separator)
                            .frame(height: 1)
                            .padding(.leading, 52)
                        
                        if let debateManager {
                            NavigationLink {
                                SavedPostsView(debateManager: debateManager)
                            } label: {
                                HStack(spacing: AppTheme.space12) {
                                    Image(systemName: "bookmark")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.primaryText)
                                        .frame(width: 24)
                                    
                                    Text("Saved Posts & Audios")
                                        .font(.system(size: 15))
                                        .foregroundColor(AppTheme.primaryText)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                                .padding(.horizontal, AppTheme.space16)
                                .frame(height: 50)
                            }
                            
                            Rectangle()
                                .fill(AppTheme.separator)
                                .frame(height: 1)
                                .padding(.leading, 52)
                            
                            NavigationLink {
                                SavedVocabularyView(debateManager: debateManager)
                            } label: {
                                HStack(spacing: AppTheme.space12) {
                                    Image(systemName: "character.book.closed")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.primaryText)
                                        .frame(width: 24)
                                    
                                    Text("Vocabulary Notebook")
                                        .font(.system(size: 15))
                                        .foregroundColor(AppTheme.primaryText)
                                    
                                    Spacer()
                                    
                                    Text("\(debateManager.currentUser.savedVocabulary.count)")
                                        .font(.system(size: 13, weight: .medium).monospacedDigit())
                                        .foregroundColor(AppTheme.secondaryText)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                                .padding(.horizontal, AppTheme.space16)
                                .frame(height: 50)
                            }
                            
                            Rectangle()
                                .fill(AppTheme.separator)
                                .frame(height: 1)
                                .padding(.leading, 52)
                        }
                        
                        NavigationLink {
                            CommunityRulesView()
                        } label: {
                            HStack(spacing: AppTheme.space12) {
                                Image(systemName: "shield")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.primaryText)
                                    .frame(width: 24)
                                
                                Text("Community Rules")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.primaryText)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.horizontal, AppTheme.space16)
                            .frame(height: 50)
                        }
                        
                        Rectangle()
                            .fill(AppTheme.separator)
                            .frame(height: 1)
                            .padding(.leading, 52)
                        
                        NavigationLink {
                            PrivacyPolicyView()
                        } label: {
                            HStack(spacing: AppTheme.space12) {
                                Image(systemName: "lock.shield")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.primaryText)
                                    .frame(width: 24)
                                
                                Text("Privacy Policy")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.primaryText)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.horizontal, AppTheme.space16)
                            .frame(height: 50)
                        }
                        
                        Rectangle()
                            .fill(AppTheme.separator)
                            .frame(height: 1)
                            .padding(.leading, 52)
                        
                        NavigationLink {
                            ContactSuggestionsView()
                        } label: {
                            HStack(spacing: AppTheme.space12) {
                                Image(systemName: "lightbulb")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.primaryText)
                                    .frame(width: 24)
                                
                                Text("Suggestions & Contact")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.primaryText)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.horizontal, AppTheme.space16)
                            .frame(height: 50)
                        }
                        
                        Rectangle()
                            .fill(AppTheme.separator)
                            .frame(height: 1)
                            .padding(.leading, 52)
                        
                        HStack(spacing: AppTheme.space12) {
                            Image(systemName: "globe")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.primaryText)
                                .frame(width: 24)
                            
                            Text("Language")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.primaryText)
                            
                            Spacer()
                            
                            Text("English Only")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .padding(.horizontal, AppTheme.space16)
                        .frame(height: 50)
                        
                        Rectangle()
                            .fill(AppTheme.separator)
                            .frame(height: 1)
                            .padding(.leading, 52)
                        
                        Button(action: {
                            authManager.logout()
                        }) {
                            HStack(spacing: AppTheme.space12) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.primaryText)
                                    .frame(width: 24)
                                
                                Text("Log Out")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.primaryText)
                                
                                Spacer()
                            }
                            .padding(.horizontal, AppTheme.space16)
                            .frame(height: 50)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Rectangle()
                            .fill(AppTheme.separator)
                            .frame(height: 1)
                            .padding(.leading, 52)
                        
                        Button(action: {
                            isShowingDeleteAccountAlert = true
                        }) {
                            HStack(spacing: AppTheme.space12) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.liveRed)
                                    .frame(width: 24)
                                
                                Text("Delete Account")
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.liveRed)
                                
                                Spacer()
                            }
                            .padding(.horizontal, AppTheme.space16)
                            .frame(height: 50)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                            .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                    )
                    
                    Text("Version 1.0")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.top, AppTheme.space4)
                        .onTapGesture {
                            versionTapCount += 1
                            if versionTapCount >= 5 {
                                versionTapCount = 0
                                authManager.toggleAdminStatus()
                                let isNowAdmin = authManager.currentUser?.isAdmin ?? false
                                withAnimation(.spring(response: 0.3)) {
                                    adminToastMessage = isNowAdmin ? "Admin Dashboard Unlocked" : "Admin Dashboard Hidden"
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                                    withAnimation {
                                        adminToastMessage = nil
                                    }
                                }
                            }
                        }
                }
                .padding(.horizontal, AppTheme.space20)
                .padding(.vertical, AppTheme.space16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingEditProfile) {
                EditProfileSheet(authManager: authManager)
            }
            .fullScreenCover(isPresented: $isShowingAdminDashboard) {
                if let debateManager {
                    AdminDashboardView(debateManager: debateManager)
                }
            }
            .alert("Delete Account?", isPresented: $isShowingDeleteAccountAlert) {
                Button("Delete", role: .destructive) {
                    authManager.deleteAccount()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your profile and local session will be permanently removed.")
            }
            .overlay(alignment: .bottom) {
                if let toast = adminToastMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "shield.fill")
                            .font(.system(size: 13))
                        Text(toast)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(AppTheme.primaryBlue)
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.primaryText)
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Edit Profile Sheet (CRUD - Update User)
public struct EditProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable public var authManager: AuthManager
    
    @State private var fullName: String
    @State private var username: String
    @State private var country: String
    @State private var level: EnglishLevel
    
    @MainActor
    public init(authManager: AuthManager) {
        self.authManager = authManager
        let user = authManager.currentUser ?? User.sampleModerator
        _fullName = State(initialValue: user.fullName)
        _username = State(initialValue: user.username)
        _country = State(initialValue: user.country)
        _level = State(initialValue: user.level)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.space20) {
                    VStack(spacing: 0) {
                        TextField("Full Name", text: $fullName)
                            .font(.system(size: 15))
                            .padding(AppTheme.space16)
                        
                        Rectangle()
                            .fill(AppTheme.separator)
                            .frame(height: 1)
                            .padding(.leading, AppTheme.space16)
                        
                        TextField("Username", text: $username)
                            .font(.system(size: 15))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(AppTheme.space16)
                        
                        Rectangle()
                            .fill(AppTheme.separator)
                            .frame(height: 1)
                            .padding(.leading, AppTheme.space16)
                        
                        TextField("Country", text: $country)
                            .font(.system(size: 15))
                            .padding(AppTheme.space16)
                    }
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                            .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                    )
                    
                    Menu {
                        ForEach(EnglishLevel.allCases) { lvl in
                            Button(lvl.rawValue) {
                                level = lvl
                            }
                        }
                    } label: {
                        HStack {
                            Text("English Level")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.primaryText)
                            Spacer()
                            HStack(spacing: AppTheme.space6) {
                                Text(level.rawValue)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.secondaryText)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                        }
                        .padding(.horizontal, AppTheme.space16)
                        .frame(height: 50)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                                .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, AppTheme.space20)
                .padding(.top, AppTheme.space20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.secondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        authManager.updateProfile(
                            fullName: fullName,
                            username: username,
                            country: country,
                            level: level
                        )
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isValid ? AppTheme.primaryBlue : AppTheme.secondaryText.opacity(0.4))
                    .disabled(!isValid)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

// MARK: - Community Rules Subview
public struct CommunityRulesView: View {
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.space24) {
                // Section 1: Debate Conduct
                VStack(alignment: .leading, spacing: AppTheme.space8) {
                    Text("Debate Conduct")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.horizontal, AppTheme.space4)
                    
                    VStack(spacing: 0) {
                        ruleRow(icon: "globe", title: "English only", desc: "All voice rooms, posts, and comments must be in English.")
                        divider
                        ruleRow(icon: "bubble.left.and.bubble.right", title: "Debate ideas, not people", desc: "Respect every opinion. Disagreement is welcome, disrespect is not.")
                        divider
                        ruleRow(icon: "hand.raised", title: "Respect speaking turns", desc: "Do not interrupt others. Use Raise Hand and follow the moderator.")
                    }
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                            .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                    )
                }
                
                // Section 2: Zero-Tolerance Safety Rules
                VStack(alignment: .leading, spacing: AppTheme.space8) {
                    Text("Zero-Tolerance Safety")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.horizontal, AppTheme.space4)
                    
                    VStack(spacing: 0) {
                        ruleRow(icon: "eye.slash", title: "No nudity or sexual content", desc: "Nudity, sexually explicit photos, or suggestive content are strictly forbidden.")
                        divider
                        ruleRow(icon: "exclamationmark.triangle", title: "No violence or threats", desc: "Graphic violence, threats, or promotion of self-harm are prohibited.")
                        divider
                        ruleRow(icon: "hand.raised.slash", title: "No hate speech or discrimination", desc: "Zero tolerance for racism, xenophobia, religious intolerance, or hate speech.")
                        divider
                        ruleRow(icon: "person.crop.circle.badge.xmark", title: "No harassment or bullying", desc: "Insults, intimidation, or targeted harassment will not be tolerated.")
                        divider
                        ruleRow(icon: "megaphone", title: "No spam or illegal content", desc: "No scams, misleading promotions, or unlawful material.")
                    }
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                            .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                    )
                }
                
                // Enforcement Footnote
                Text("Any violation of these rules may result in immediate content removal and permanent account suspension.")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineSpacing(2)
                    .padding(.horizontal, AppTheme.space4)
                
                // Contact / Suggestions Card
                NavigationLink {
                    ContactSuggestionsView()
                } label: {
                    HStack(spacing: AppTheme.space12) {
                        Image(systemName: "envelope.badge")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.primaryBlue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Have a suggestion or question?")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText)
                            Text("Contact Sylla English Academy (+221 77 709 19 13)")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(AppTheme.space16)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                            .stroke(AppTheme.separator, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, AppTheme.space20)
            .padding(.vertical, AppTheme.space16)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Community Rules")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var divider: some View {
        Rectangle()
            .fill(AppTheme.separator)
            .frame(height: 1)
            .padding(.leading, 52)
    }
    
    private func ruleRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: AppTheme.space12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.primaryText)
                .frame(width: 24, alignment: .center)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineSpacing(1.5)
            }
            Spacer()
        }
        .padding(AppTheme.space16)
    }
}

#Preview {
    ProfileView(authManager: AuthManager())
}
