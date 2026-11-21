import SwiftUI

public enum LeaderboardTimeframe: String, CaseIterable, Identifiable {
    case allTime = "All Time"
    case thisMonth = "Month"
    case thisWeek = "Week"
    
    public var id: String { rawValue }
}

public struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    
    public var allUsers: [User]
    public var currentUser: User
    @State private var timeframe: LeaderboardTimeframe = .allTime
    
    public init(allUsers: [User] = [], currentUser: User = User(username: "user", fullName: "Member", email: "user@waxup.app")) {
        self.allUsers = allUsers
        self.currentUser = currentUser
    }
    
    private var rankedUsers: [User] {
        allUsers.sorted(by: { $0.debatesParticipatedCount > $1.debatesParticipatedCount })
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Timeframe Segmented Control
                Picker("Timeframe", selection: $timeframe) {
                    ForEach(LeaderboardTimeframe.allCases) { tf in
                        Text(tf.rawValue).tag(tf)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.space20)
                .padding(.vertical, AppTheme.space12)
                
                ScrollView {
                    VStack(spacing: AppTheme.space24) {
                        if rankedUsers.isEmpty {
                            VStack(spacing: AppTheme.space16) {
                                Circle()
                                    .fill(AppTheme.separator.opacity(0.4))
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        Image(systemName: "trophy")
                                            .font(.system(size: 26))
                                            .foregroundColor(AppTheme.secondaryText)
                                    )
                                
                                Text("No Rankings Yet")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryText)
                                
                                Text("Participate in live voice debates to earn your spot on the community leaderboard.")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, AppTheme.space32)
                            }
                            .padding(.top, 80)
                        } else {
                            // Airy Top 3 Directly on Canvas (No heavy boxes)
                            if rankedUsers.count >= 3 {
                                HStack(alignment: .bottom, spacing: AppTheme.space16) {
                                    topMember(user: rankedUsers[1], rank: 2, avatarSize: 52)
                                    topMember(user: rankedUsers[0], rank: 1, avatarSize: 68)
                                    topMember(user: rankedUsers[2], rank: 3, avatarSize: 48)
                                }
                                .padding(.top, AppTheme.space12)
                            }
                            
                            // Single Grouped List for Ranks 4+
                            let remaining = Array(rankedUsers.enumerated()).filter { $0.offset >= 3 }
                            if !remaining.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(Array(remaining.enumerated()), id: \.element.element.id) { idx, entry in
                                        rankingRow(rank: entry.offset + 1, user: entry.element)
                                        
                                        if idx < remaining.count - 1 {
                                            Rectangle()
                                                .fill(AppTheme.separator)
                                                .frame(height: 1)
                                                .padding(.leading, 56)
                                        }
                                    }
                                }
                                .background(AppTheme.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                                        .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.space20)
                    .padding(.bottom, 88)
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .overlay(alignment: .bottom) {
                currentUserStickyBar
            }
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.primaryBlue)
                }
            }
        }
    }
    
    // MARK: - Airy Top 3 Item
    private func topMember(user: User, rank: Int, avatarSize: CGFloat) -> some View {
        VStack(spacing: AppTheme.space8) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(AppTheme.surface)
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay(
                        Circle()
                            .stroke(rank == 1 ? AppTheme.primaryBlue : AppTheme.separator, lineWidth: rank == 1 ? 2 : 1)
                    )
                    .overlay(
                        Text(user.initials)
                            .font(.system(size: rank == 1 ? 20 : 15, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                    )
                
                Text("\(rank)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(rank == 1 ? AppTheme.primaryBlue : AppTheme.secondaryText)
                    .clipShape(Circle())
                    .offset(x: 2, y: 2)
            }
            
            VStack(spacing: 2) {
                Text(user.fullName.components(separatedBy: " ").first ?? user.fullName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)
                
                Text("\(user.debatesParticipatedCount) debates")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Quiet Ranking Row
    private func rankingRow(rank: Int, user: User) -> some View {
        let isMe = user.id == currentUser.id
        
        return HStack(spacing: AppTheme.space12) {
            Text("\(rank)")
                .font(.system(size: 14, weight: .medium).monospacedDigit())
                .foregroundColor(isMe ? AppTheme.primaryBlue : AppTheme.secondaryText)
                .frame(width: 24, alignment: .leading)
            
            Circle()
                .fill(isMe ? AppTheme.primaryBlue.opacity(0.12) : AppTheme.neutralSubtle)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(user.initials)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isMe ? AppTheme.primaryBlue : AppTheme.primaryText)
                )
            
            Text(user.fullName)
                .font(.system(size: 15, weight: isMe ? .semibold : .regular))
                .foregroundColor(AppTheme.primaryText)
            
            Spacer()
            
            Text("\(user.debatesParticipatedCount)")
                .font(.system(size: 14, weight: .semibold).monospacedDigit())
                .foregroundColor(isMe ? AppTheme.primaryBlue : AppTheme.secondaryText)
        }
        .padding(.horizontal, AppTheme.space16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Sleek Pinned User Bar
    private var currentUserStickyBar: some View {
        let myRankIndex = rankedUsers.firstIndex(where: { $0.id == currentUser.id }) ?? 1
        let myRank = myRankIndex + 1
        
        return HStack(spacing: AppTheme.space12) {
            Text("#\(myRank)")
                .font(.system(size: 15, weight: .bold).monospacedDigit())
                .foregroundColor(AppTheme.primaryBlue)
                .frame(width: 32, alignment: .leading)
            
            Text(currentUser.fullName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppTheme.primaryText)
            
            Spacer()
            
            Text("\(currentUser.debatesParticipatedCount) debates")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(.horizontal, AppTheme.space20)
        .padding(.vertical, 16)
        .background(AppTheme.surface)
        .overlay(
            Rectangle()
                .fill(AppTheme.separator)
                .frame(height: 1),
            alignment: .top
        )
    }
}

#Preview {
    LeaderboardView(currentUser: User.sampleModerator)
}
