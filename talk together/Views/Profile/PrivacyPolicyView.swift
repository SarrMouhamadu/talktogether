import SwiftUI

public struct PrivacyPolicyView: View {
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.space20) {
                // Last updated
                Text("Last updated: November 20, 2026")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.secondaryText)
                
                // Introduction
                Text("Welcome to WaxUp, operated by Sylla English Academy. We are committed to protecting your personal data and ensuring a safe, respectful environment for practicing oral English.")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(3)
                
                // Section 1: Data Collection
                policySection(
                    title: "1. Information We Collect",
                    items: [
                        "Account Data: Your name, username, email, country, and English proficiency level.",
                        "Audio Content: Real-time voice transmissions during live debates and voice note snippets shared to the community feed.",
                        "User Content: Posts, comments, bookmarks, and debate votes.",
                        "Device Permissions: Microphone access strictly when speaking in a live room or recording audio; Photo access only when you attach an image."
                    ]
                )
                
                // Section 2: How We Use Data
                policySection(
                    title: "2. How We Use Your Data",
                    items: [
                        "To host live voice debate rooms and maintain speaking queues.",
                        "To calculate daily practice streaks and community rankings.",
                        "To enforce our Zero-Tolerance Community Safety Rules (no hate speech, nudity, or harassment).",
                        "We NEVER sell or monetize your personal data or voice recordings to third parties."
                    ]
                )
                
                // Section 3: Data Control & Deletion
                policySection(
                    title: "3. Account Deletion & Rights",
                    items: [
                        "You can edit your profile information at any time in Profile > Edit Profile.",
                        "You have the right to permanently delete your account at any time via Profile > Delete Account.",
                        "Account deletion permanently removes your profile and local session data."
                    ]
                )
                
                // Section 4: Contact
                VStack(alignment: .leading, spacing: AppTheme.space8) {
                    Text("4. Contact Information")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sylla English Academy")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                        Text("Email: contact@syllaenglishacademy.com")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.secondaryText)
                        Text("Phone: +221 77 709 19 13")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(AppTheme.space16)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func policySection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.primaryText)
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(AppTheme.primaryBlue)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        
                        Text(item)
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.secondaryText)
                            .lineSpacing(2)
                    }
                }
            }
            .padding(AppTheme.space16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                    .stroke(AppTheme.separator, lineWidth: 1)
            )
        }
    }
}
