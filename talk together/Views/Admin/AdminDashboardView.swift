import SwiftUI
import AVFoundation
import Darwin

public enum AdminSection: String, CaseIterable, Identifiable {
    case overview = "Executive"
    case users = "Users"
    case posts = "Content"
    case telemetry = "Telemetry"
    case reports = "Safety"
    
    public var id: String { rawValue }
}

public struct AdminDashboardView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable public var debateManager: DebateManager
    
    @State private var selectedSection: AdminSection = .overview
    @State private var userSearchQuery: String = ""
    @State private var userFilterTab: String = "All"
    @State private var inspectedUser: User? = nil
    @State private var exportToastMessage: String? = nil
    @State private var userPendingDelete: User? = nil
    @State private var postPendingDelete: FeedPost? = nil
    @State private var topicPendingDelete: Topic? = nil
    
    public init(debateManager: DebateManager) {
        self.debateManager = debateManager
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Tab Switcher
                Picker("Admin Section", selection: $selectedSection) {
                    ForEach(AdminSection.allCases) { section in
                        if section == .reports && debateManager.pendingReportsCount > 0 {
                            Text("\(section.rawValue) (\(debateManager.pendingReportsCount))").tag(section)
                        } else {
                            Text(section.rawValue).tag(section)
                        }
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppTheme.space20)
                .padding(.vertical, AppTheme.space12)
                .background(AppTheme.surface)
                
                Rectangle()
                    .fill(AppTheme.separator)
                    .frame(height: 1)
                
                // Active Section Content
                ScrollView {
                    Group {
                        switch selectedSection {
                        case .overview:
                            overviewSection
                        case .users:
                            usersSection
                        case .posts:
                            postsSection
                        case .telemetry:
                            telemetrySection
                        case .reports:
                            reportsSection
                        }
                    }
                    .padding(.horizontal, AppTheme.space20)
                    .padding(.vertical, AppTheme.space16)
                }
                .background(AppTheme.background.ignoresSafeArea())
            }
            .navigationTitle("Admin Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.primaryBlue)
                }
            }
            // Delete User Confirmation
            .alert(
                "Delete User Account?",
                isPresented: Binding(
                    get: { userPendingDelete != nil },
                    set: { if !$0 { userPendingDelete = nil } }
                ),
                presenting: userPendingDelete
            ) { user in
                Button("Delete Permanently", role: .destructive) {
                    withAnimation {
                        debateManager.deleteUserAccount(id: user.id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { user in
                Text("This will permanently delete @\(user.username), all of their posts, comments, and queued topics.")
            }
            // Delete Post Confirmation
            .alert(
                "Delete Post?",
                isPresented: Binding(
                    get: { postPendingDelete != nil },
                    set: { if !$0 { postPendingDelete = nil } }
                ),
                presenting: postPendingDelete
            ) { post in
                Button("Delete Post", role: .destructive) {
                    withAnimation {
                        debateManager.deletePost(id: post.id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { post in
                Text("Remove this post by @\(post.author.username) from the feed.")
            }
            // Delete Topic Confirmation
            .alert(
                "Remove Topic from Queue?",
                isPresented: Binding(
                    get: { topicPendingDelete != nil },
                    set: { if !$0 { topicPendingDelete = nil } }
                ),
                presenting: topicPendingDelete
            ) { topic in
                Button("Remove", role: .destructive) {
                    withAnimation {
                        debateManager.deleteTopic(id: topic.id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { topic in
                Text("Remove '\(topic.title)' from the schedule.")
            }
            .sheet(item: $inspectedUser) { user in
                UserDetailAdminSheet(user: user, debateManager: debateManager)
            }
            .overlay(alignment: .bottom) {
                if let toast = exportToastMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                        Text(toast)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - 1. Overview & Live Monitoring
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.space24) {
            // Master Total Inscrits Hero Card
            VStack(alignment: .leading, spacing: AppTheme.space12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(AppTheme.successGreen)
                                .frame(width: 8, height: 8)
                            Text("COMMUNITY ROSTER & LIVE METRICS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        
                        Text("\(debateManager.allUsers.count)")
                            .font(.system(size: 38, weight: .bold).monospacedDigit())
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("Total Registered Members")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button {
                        let report = debateManager.generateFullPlatformAuditReport()
                        UIPasteboard.general.string = report
                        withAnimation(.spring(response: 0.3)) {
                            exportToastMessage = "Full Audit Report Copied"
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                exportToastMessage = nil
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 12))
                            Text("Export Report")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(AppTheme.primaryBlue)
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(AppTheme.primaryBlue.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Status breakdown pills
                HStack(spacing: 8) {
                    summaryPill(label: "Active", count: debateManager.activeUsersCount, color: AppTheme.successGreen)
                    summaryPill(label: "Suspended", count: debateManager.suspendedUsersCount, color: AppTheme.liveRed)
                    summaryPill(label: "Premium", count: debateManager.premiumUsersCount, color: AppTheme.primaryBlue)
                    summaryPill(label: "Admins", count: debateManager.adminUsersCount, color: AppTheme.primaryText)
                    summaryPill(label: "Topics", count: debateManager.topicsQueue.count, color: AppTheme.warningOrange)
                }
                .padding(.top, 4)
            }
            .padding(AppTheme.space16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                    .stroke(AppTheme.primaryBlue.opacity(0.20), lineWidth: 1)
            )
            
            // Live Room Pulse Card
            VStack(alignment: .leading, spacing: AppTheme.space12) {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(debateManager.currentSession != nil ? AppTheme.liveRed : AppTheme.secondaryText)
                            .frame(width: 8, height: 8)
                        Text(debateManager.currentSession != nil ? "LIVE ROOM PULSE" : "DEBATE ROOM STATUS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    Spacer()
                    if debateManager.currentSession != nil {
                        Text(debateManager.formattedSessionDuration)
                            .font(.system(size: 13, weight: .bold).monospacedDigit())
                            .foregroundColor(AppTheme.liveRed)
                    }
                }
                
                if let session = debateManager.currentSession {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.topic.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                            .lineLimit(2)
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 11))
                                Text("\(session.participants.filter { $0.role == .debater }.count) debaters")
                                    .font(.system(size: 12))
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "headphones")
                                    .font(.system(size: 11))
                                Text("\(session.participants.filter { $0.role == .listener }.count) listeners")
                                    .font(.system(size: 12))
                            }
                            if session.isSpeakingTurnActive {
                                HStack(spacing: 4) {
                                    Image(systemName: "timer")
                                        .font(.system(size: 11))
                                    Text("\(session.speakingTurnSecondsRemaining)s turn")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppTheme.warningOrange)
                                }
                            }
                        }
                        .foregroundColor(AppTheme.secondaryText)
                    }
                } else {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No Active Debate In Session")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.primaryText)
                            if let next = debateManager.topicsQueue.first {
                                Text("Next in queue: \(next.title)")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.secondaryText)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                        Button(action: {
                            withAnimation {
                                debateManager.advanceQueueToNext()
                            }
                        }) {
                            Text("Start Next")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.primaryBlue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppTheme.primaryBlue.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(AppTheme.space16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                    .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
            )
            
            // Community Champions
            VStack(alignment: .leading, spacing: AppTheme.space12) {
                Text("Community Champions")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.horizontal, AppTheme.space4)
                
                HStack(spacing: AppTheme.space12) {
                    if let topSpeaker = debateManager.topActiveUser {
                        championCard(
                            role: "Top Debater",
                            icon: "mic.badge.plus",
                            name: topSpeaker.fullName,
                            username: topSpeaker.username,
                            metric: "\(topSpeaker.debatesParticipatedCount) debates",
                            tint: AppTheme.primaryBlue
                        )
                    }
                    if let topStreak = debateManager.topStreakUser {
                        championCard(
                            role: "Consistency Champion",
                            icon: "flame.fill",
                            name: topStreak.fullName,
                            username: topStreak.username,
                            metric: "\(topStreak.dailyStreak)d streak",
                            tint: AppTheme.warningOrange
                        )
                    }
                }
            }
            
            // Platform Activity KPIs Grid
            VStack(alignment: .leading, spacing: AppTheme.space12) {
                Text("Activity & Engagement")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.horizontal, AppTheme.space4)
                
                LazyVGrid(columns: [GridItem(.flexible(), spacing: AppTheme.space12), GridItem(.flexible(), spacing: AppTheme.space12)], spacing: AppTheme.space12) {
                    metricCard(title: "Debates Joined", value: "\(debateManager.totalDebatesParticipatedAcrossPlatform)", icon: "mic.fill", tint: AppTheme.primaryBlue)
                    metricCard(title: "Community Posts", value: "\(debateManager.feedPosts.count)", icon: "doc.plaintext", tint: AppTheme.primaryText)
                    metricCard(title: "Voice Notes", value: "\(debateManager.totalVoicePostsCount)", icon: "waveform", tint: AppTheme.primaryBlue)
                    metricCard(title: "Likes & Comments", value: "\(debateManager.totalLikesCount + debateManager.totalCommentsCount)", icon: "heart.fill", tint: AppTheme.liveRed)
                    metricCard(title: "Queue Topics", value: "\(debateManager.topicsQueue.count)", icon: "list.number", tint: AppTheme.warningOrange)
                    metricCard(title: "Pending Reports", value: "\(debateManager.pendingReportsCount)", icon: "shield.fill", tint: debateManager.pendingReportsCount > 0 ? AppTheme.liveRed : AppTheme.successGreen)
                }
            }
            
            // English Level Breakdown
            VStack(alignment: .leading, spacing: AppTheme.space12) {
                Text("English Proficiency Breakdown")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.horizontal, AppTheme.space4)
                
                VStack(spacing: AppTheme.space12) {
                    ForEach(debateManager.usersByLevelCounts, id: \.level) { item in
                        VStack(spacing: 4) {
                            HStack {
                                Text(item.level.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.primaryText)
                                Spacer()
                                Text("\(item.count) learners (\(percentString(count: item.count, total: debateManager.allUsers.count)))")
                                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            
                            GeometryReader { proxy in
                                let width = proxy.size.width
                                let ratio = debateManager.allUsers.isEmpty ? 0 : CGFloat(item.count) / CGFloat(debateManager.allUsers.count)
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(AppTheme.separator.opacity(0.6))
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(levelColor(for: item.level))
                                        .frame(width: max(6, width * ratio), height: 6)
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
                .padding(AppTheme.space16)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                        .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                )
            }
            
            // Geographic Distribution
            VStack(alignment: .leading, spacing: AppTheme.space12) {
                Text("Geographic Distribution")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.secondaryText)
                    .padding(.horizontal, AppTheme.space4)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.space8) {
                        ForEach(debateManager.usersByCountryCounts, id: \.country) { item in
                            HStack(spacing: 6) {
                                Image(systemName: "globe")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.primaryBlue)
                                Text(item.country)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.primaryText)
                                Text("\(item.count)")
                                    .font(.system(size: 11, weight: .bold).monospacedDigit())
                                    .foregroundColor(AppTheme.secondaryText)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(AppTheme.separator)
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .background(AppTheme.surface)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(AppTheme.separator, lineWidth: 1)
                            )
                        }
                    }
                }
            }
            
            // Live & FIFO Queue Control
            VStack(alignment: .leading, spacing: AppTheme.space12) {
                HStack {
                    Text("Debate Queue Control (\(debateManager.topicsQueue.count))")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.secondaryText)
                    Spacer()
                    Button(action: {
                        withAnimation {
                            debateManager.advanceQueueToNext()
                        }
                    }) {
                        Label("Next Topic", systemImage: "forward.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, AppTheme.space4)
                
                VStack(spacing: 0) {
                    ForEach(Array(debateManager.topicsQueue.enumerated()), id: \.element.id) { index, topic in
                        HStack(spacing: AppTheme.space12) {
                            StatusBadge(status: topic.status, queuePosition: topic.queuePosition)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(topic.title)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryText)
                                    .lineLimit(1)
                                Text("@\(topic.creator.username) · \(topic.category.rawValue)\(topic.shortScheduledTime != nil ? " · \(topic.shortScheduledTime!)" : "")")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            
                            Spacer()
                            
                            Button(action: { topicPendingDelete = topic }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.liveRed)
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, AppTheme.space16)
                        .padding(.vertical, 12)
                        
                        if index < debateManager.topicsQueue.count - 1 {
                            Rectangle()
                                .fill(AppTheme.separator)
                                .frame(height: 1)
                                .padding(.leading, AppTheme.space16)
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
    
    private func summaryPill(label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(label):")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.secondaryText)
            Text("\(count)")
                .font(.system(size: 11, weight: .bold).monospacedDigit())
                .foregroundColor(AppTheme.primaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.08))
        .clipShape(Capsule())
    }
    
    private func percentString(count: Int, total: Int) -> String {
        guard total > 0 else { return "0%" }
        let pct = Int((Double(count) / Double(total)) * 100)
        return "\(pct)%"
    }
    
    private func levelColor(for level: EnglishLevel) -> Color {
        switch level {
        case .beginner: return AppTheme.secondaryText
        case .intermediate: return AppTheme.warningOrange
        case .advanced: return AppTheme.primaryBlue
        case .fluent: return AppTheme.successGreen
        }
    }
    
    private func metricCard(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.space12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(tint)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold).monospacedDigit())
                    .foregroundColor(AppTheme.primaryText)
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding(AppTheme.space16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
        )
    }
    
    // MARK: - 2. Users Management
    private var filteredUsers: [User] {
        var list = debateManager.allUsers
        
        switch userFilterTab {
        case "Active":
            list = list.filter { !$0.isSuspended }
        case "Suspended":
            list = list.filter { $0.isSuspended }
        case "Admins":
            list = list.filter { $0.isAdmin }
        default:
            break
        }
        
        let query = userSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return list }
        return list.filter {
            $0.fullName.lowercased().contains(query) ||
            $0.username.lowercased().contains(query) ||
            $0.email.lowercased().contains(query) ||
            $0.country.lowercased().contains(query)
        }
    }
    
    private var usersSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.space16) {
            // Search Input + Export Button
            HStack(spacing: AppTheme.space8) {
                HStack(spacing: AppTheme.space8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.secondaryText)
                    TextField("Search users, emails, country...", text: $userSearchQuery)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, AppTheme.space12)
                .frame(height: 42)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                )
                
                Button {
                    let csv = debateManager.generateUsersExportReport()
                    UIPasteboard.general.string = csv
                    withAnimation(.spring(response: 0.3)) {
                        exportToastMessage = "Users CSV Copied"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            exportToastMessage = nil
                        }
                    }
                } label: {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.primaryBlue)
                        .frame(width: 42, height: 42)
                        .background(AppTheme.primaryBlue.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Export Users CSV")
            }
            
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.space8) {
                    filterPill(title: "All", count: debateManager.allUsers.count)
                    filterPill(title: "Active", count: debateManager.allUsers.filter { !$0.isSuspended }.count)
                    filterPill(title: "Suspended", count: debateManager.allUsers.filter { $0.isSuspended }.count)
                    filterPill(title: "Admins", count: debateManager.allUsers.filter { $0.isAdmin }.count)
                }
            }
            
            Text("\(filteredUsers.count) monitored accounts")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.secondaryText)
                .padding(.horizontal, AppTheme.space4)
            
            if filteredUsers.isEmpty {
                emptyPlaceholder(icon: "person.2", text: "No accounts match this filter")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredUsers.enumerated()), id: \.element.id) { index, user in
                        Button {
                            inspectedUser = user
                        } label: {
                            HStack(spacing: AppTheme.space12) {
                                Circle()
                                    .fill(user.isSuspended ? AppTheme.liveRedSubtle : AppTheme.neutralSubtle)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Text(user.initials)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(user.isSuspended ? AppTheme.liveRed : AppTheme.primaryText)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(user.fullName)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(AppTheme.primaryText)
                                        
                                        if user.isAdmin {
                                            tagPill("ADMIN", color: AppTheme.primaryBlue)
                                        }
                                        if user.isSuspended {
                                            tagPill("SUSPENDED", color: AppTheme.liveRed)
                                        }
                                    }
                                    
                                    Text("@\(user.username) · \(user.email)")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.secondaryText)
                                        .lineLimit(1)
                                    
                                    Text("\(user.debatesParticipatedCount) debates · \(user.topicsCreatedCount) topics · \(user.country)")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.horizontal, AppTheme.space16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if index < filteredUsers.count - 1 {
                            Rectangle()
                                .fill(AppTheme.separator)
                                .frame(height: 1)
                                .padding(.leading, 68)
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
    
    private func filterPill(title: String, count: Int) -> some View {
        Button {
            userFilterTab = title
        } label: {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 13, weight: userFilterTab == title ? .semibold : .regular))
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold).monospacedDigit())
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(userFilterTab == title ? Color.white.opacity(0.2) : AppTheme.separator)
                    .clipShape(Capsule())
            }
            .foregroundColor(userFilterTab == title ? .white : AppTheme.primaryText)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(userFilterTab == title ? AppTheme.primaryBlue : AppTheme.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(userFilterTab == title ? Color.clear : AppTheme.separator, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 3. Posts Moderation
    private var postsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.space12) {
            Text("\(debateManager.feedPosts.count) published posts")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.secondaryText)
                .padding(.horizontal, AppTheme.space4)
            
            if debateManager.feedPosts.isEmpty {
                emptyPlaceholder(icon: "doc.plaintext", text: "No posts on the platform")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(debateManager.feedPosts.enumerated()), id: \.element.id) { index, post in
                        HStack(alignment: .top, spacing: AppTheme.space12) {
                            Circle()
                                .fill(AppTheme.neutralSubtle)
                                .frame(width: 34, height: 34)
                                .overlay(
                                    Text(post.author.initials)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(AppTheme.primaryText)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Text("@\(post.author.username)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppTheme.primaryText)
                                    Text("· \(post.createdAtText)")
                                        .font(.system(size: 12))
                                        .foregroundColor(AppTheme.secondaryText)
                                    
                                    if post.audioDurationSeconds != nil {
                                        tagPill("VOICE", color: AppTheme.primaryBlue)
                                    }
                                    if post.imageData != nil {
                                        tagPill("PHOTO", color: AppTheme.successGreen)
                                    }
                                }
                                
                                Text(post.quoteText ?? post.caption ?? "Media-only post")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.primaryText)
                                    .lineLimit(2)
                                
                                Text("\(post.likesCount) likes · \(post.comments.count) comments")
                                    .font(.system(size: 11))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            
                            Spacer()
                            
                            Button(action: { postPendingDelete = post }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.liveRed)
                                    .frame(width: 34, height: 34)
                                    .background(AppTheme.liveRedSubtle)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(AppTheme.space16)
                        
                        if index < debateManager.feedPosts.count - 1 {
                            Rectangle()
                                .fill(AppTheme.separator)
                                .frame(height: 1)
                                .padding(.leading, 62)
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
    
    // MARK: - 4. Technical Monitoring & System Telemetry
    private var telemetrySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.space16) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("System & Telemetry Vitals")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.secondaryText)
                    Text("Real-time iOS hardware, AVFoundation and sandbox diagnostics")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.secondaryText)
                }
                Spacer()
                Button(action: {
                    let diagnostics = generateDiagnosticsReport()
                    UIPasteboard.general.string = diagnostics
                    withAnimation(.spring(response: 0.3)) {
                        exportToastMessage = "Diagnostics Copied"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            exportToastMessage = nil
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .font(.system(size: 11))
                        Text("Copy Logs")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.primaryBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.primaryBlue.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, AppTheme.space4)
            
            // Device & OS Card
            VStack(alignment: .leading, spacing: AppTheme.space12) {
                Label("Device & Operating System", systemImage: "iphone")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                
                VStack(spacing: 8) {
                    telemetryRow(title: "Hardware Model", value: UIDevice.current.model)
                    telemetryRow(title: "System Version", value: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
                    telemetryRow(title: "App Bundle Version", value: "v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                    telemetryRow(title: "Bundle Identifier", value: Bundle.main.bundleIdentifier ?? "com.mouhamadousarr.waxup")
                    telemetryRow(title: "Display Profile", value: screenSizeDescription)
                }
            }
            .padding(AppTheme.space16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                    .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
            )
            
            // Audio Pipeline Card
            VStack(alignment: .leading, spacing: AppTheme.space12) {
                Label("AVAudioSession & Voice Pipeline", systemImage: "waveform")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                
                VStack(spacing: 8) {
                    telemetryRow(
                        title: "Microphone Access",
                        value: debateManager.audioService.permissionGranted ? "Authorized" : "Restricted",
                        color: debateManager.audioService.permissionGranted ? AppTheme.successGreen : AppTheme.liveRed
                    )
                    telemetryRow(
                        title: "Session Status",
                        value: debateManager.audioService.isSessionActive ? "Active (.voiceChat)" : "Idle / Standing By",
                        color: debateManager.audioService.isSessionActive ? AppTheme.primaryBlue : AppTheme.secondaryText
                    )
                    telemetryRow(
                        title: "Microphone State",
                        value: debateManager.audioService.isMuted ? "Hardware Muted" : "Active Input",
                        color: debateManager.audioService.isMuted ? AppTheme.secondaryText : AppTheme.successGreen
                    )
                    telemetryRow(
                        title: "Live Input Level",
                        value: "\(Int(debateManager.audioService.audioLevel * 100))% peak"
                    )
                    telemetryRow(
                        title: "Voice Notes Format",
                        value: "MPEG4 AAC (64kbps, mono)"
                    )
                }
            }
            .padding(AppTheme.space16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                    .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
            )
            
            // Runtime & Memory Card
            VStack(alignment: .leading, spacing: AppTheme.space12) {
                Label("Runtime & Hardware Resources", systemImage: "speedometer")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                
                VStack(spacing: 8) {
                    let ramMB = os_proc_available_memory() / 1_048_576
                    telemetryRow(title: "Process RAM Available", value: "\(ramMB) MB")
                    telemetryRow(title: "Active CPU Cores", value: "\(ProcessInfo.processInfo.activeProcessorCount) Cores")
                    telemetryRow(title: "Thermal State", value: thermalStateDescription)
                    telemetryRow(title: "System Uptime", value: formattedUptime)
                }
            }
            .padding(AppTheme.space16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                    .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
            )
            
            // Storage & Persistence Card
            VStack(alignment: .leading, spacing: AppTheme.space12) {
                Label("Storage & Persistence Sandbox", systemImage: "internaldrive")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.primaryText)
                
                VStack(spacing: 8) {
                    telemetryRow(title: "UserDefaults Profiles", value: "\(debateManager.allUsers.count) accounts")
                    telemetryRow(title: "Community Feed Posts", value: "\(debateManager.feedPosts.count) items cached")
                    telemetryRow(title: "Voice Notes on Disk", value: "\(debateManager.totalVoicePostsCount) recordings")
                    telemetryRow(title: "Queue Topics Stored", value: "\(debateManager.topicsQueue.count) topics")
                    telemetryRow(title: "Content Reports", value: "\(debateManager.reports.count) records (\(debateManager.pendingReportsCount) pending)")
                }
            }
            .padding(AppTheme.space16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                    .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
            )
        }
    }
    
    // MARK: - 5. Safety Reports Queue
    private var reportsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.space12) {
            let pending = debateManager.reports.filter { !$0.isResolved }
            Text("\(pending.count) pending reports")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.secondaryText)
                .padding(.horizontal, AppTheme.space4)
            
            if pending.isEmpty {
                emptyPlaceholder(icon: "checkmark.shield", text: "All reports resolved")
            } else {
                VStack(spacing: AppTheme.space12) {
                    ForEach(pending) { report in
                        VStack(alignment: .leading, spacing: AppTheme.space12) {
                            HStack(spacing: AppTheme.space8) {
                                Image(systemName: report.reasonIconName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.liveRed)
                                Text(report.reason)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.liveRed)
                                Spacer()
                                Text(report.createdAtText)
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            
                            Text(report.postPreview)
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.primaryText)
                                .lineLimit(2)
                            
                            Text("Target: @\(report.reportedAuthor.username) · Reported by @\(report.reporterUsername)")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.secondaryText)
                            
                            // Quick Moderation Actions
                            HStack(spacing: AppTheme.space8) {
                                Button(action: {
                                    withAnimation {
                                        debateManager.deleteReportedPostAndResolve(report: report)
                                    }
                                }) {
                                    Text("Delete Post")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 34)
                                        .background(AppTheme.liveRed)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    withAnimation {
                                        debateManager.banAuthorAndResolve(report: report)
                                    }
                                }) {
                                    Text("Delete User")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppTheme.liveRed)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 34)
                                        .background(AppTheme.liveRedSubtle)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    withAnimation {
                                        debateManager.resolveReport(id: report.id)
                                    }
                                }) {
                                    Text("Dismiss")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppTheme.secondaryText)
                                        .padding(.horizontal, 12)
                                        .frame(height: 34)
                                        .background(AppTheme.neutralSubtle)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .premiumCard(cornerRadius: AppTheme.radiusCard, padding: AppTheme.space16)
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func tagPill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
    
    private func emptyPlaceholder(icon: String, text: String) -> some View {
        VStack(spacing: AppTheme.space8) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .light))
                .foregroundColor(AppTheme.secondaryText)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.space40)
    }
    
    private func championCard(role: String, icon: String, name: String, username: String, metric: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(tint)
                Spacer()
                Text(role.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(tint)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(tint.opacity(0.12))
                    .clipShape(Capsule())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(1)
                Text("@\(username)")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
            }
            
            Text(metric)
                .font(.system(size: 12, weight: .bold).monospacedDigit())
                .foregroundColor(AppTheme.primaryText)
        }
        .padding(AppTheme.space12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
        )
    }
    
    private func telemetryRow(title: String, value: String, color: Color = AppTheme.primaryText) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundColor(color)
        }
    }
    
    private var thermalStateDescription: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Nominal (Cool)"
        case .fair: return "Fair"
        case .serious: return "Serious (Throttling)"
        case .critical: return "Critical"
        @unknown default: return "Standard"
        }
    }
    
    private var formattedUptime: String {
        let seconds = Int(ProcessInfo.processInfo.systemUptime)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    private var screenSizeDescription: String {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            let bounds = scene.screen.bounds
            let scale = scene.screen.scale
            return "\(Int(bounds.width))x\(Int(bounds.height)) pt (@\(Int(scale))x)"
        }
        return "Standard Retina (iOS)"
    }
    
    private func generateDiagnosticsReport() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let nowStr = formatter.string(from: Date())
        let ramMB = os_proc_available_memory() / 1_048_576
        
        return """
        ==================================================
        WAXUP SYSTEM & TELEMETRY DIAGNOSTICS
        Timestamp: \(nowStr)
        ==================================================
        [DEVICE & OPERATING SYSTEM]
        Device Model: \(UIDevice.current.model)
        System Version: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
        App Version: v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))
        Bundle ID: \(Bundle.main.bundleIdentifier ?? "com.mouhamadousarr.waxup")
        Screen: \(screenSizeDescription)
        System Uptime: \(formattedUptime)

        [HARDWARE RESOURCES]
        Process RAM Available: \(ramMB) MB
        Active CPU Cores: \(ProcessInfo.processInfo.activeProcessorCount) Cores
        Thermal State: \(thermalStateDescription)

        [AVFOUNDATION & AUDIO ENGINE]
        Microphone Authorization: \(debateManager.audioService.permissionGranted ? "Authorized" : "Not Authorized")
        Audio Engine Session: \(debateManager.audioService.isSessionActive ? "Active (.voiceChat)" : "Idle")
        Hardware Mic State: \(debateManager.audioService.isMuted ? "Hardware Muted" : "Active Input")
        Peak Audio Level: \(Int(debateManager.audioService.audioLevel * 100))%
        Voice Notes Format: MPEG4 AAC (64kbps, mono)

        [DATA STORAGE & SANDBOX]
        Registered Accounts: \(debateManager.allUsers.count) profiles in UserDefaults
        Active / Suspended: \(debateManager.activeUsersCount) active / \(debateManager.suspendedUsersCount) suspended
        Premium Members: \(debateManager.premiumUsersCount)
        Community Feed Posts: \(debateManager.feedPosts.count) cached
        Voice Audio Files: \(debateManager.totalVoicePostsCount) recordings
        Debate Queue Topics: \(debateManager.topicsQueue.count) items
        Content Reports: \(debateManager.reports.count) total (\(debateManager.pendingReportsCount) unresolved)
        ==================================================
        """
    }
}

// MARK: - User Detail Admin Sheet
public struct UserDetailAdminSheet: View {
    @Environment(\.dismiss) private var dismiss
    public var user: User
    @Bindable public var debateManager: DebateManager
    
    @State private var showDeleteAlert: Bool = false
    
    public init(user: User, debateManager: DebateManager) {
        self.user = user
        self.debateManager = debateManager
    }
    
    private var currentUserState: User {
        debateManager.allUsers.first(where: { $0.id == user.id }) ?? user
    }
    
    private var userPosts: [FeedPost] {
        debateManager.feedPosts.filter { $0.author.id == user.id }
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.space24) {
                    // Header Card
                    VStack(spacing: AppTheme.space12) {
                        Circle()
                            .fill(currentUserState.isSuspended ? AppTheme.liveRedSubtle : AppTheme.neutralSubtle)
                            .frame(width: 72, height: 72)
                            .overlay(
                                Text(currentUserState.initials)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(currentUserState.isSuspended ? AppTheme.liveRed : AppTheme.primaryText)
                            )
                        
                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Text(currentUserState.fullName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppTheme.primaryText)
                                
                                if currentUserState.isAdmin {
                                    Text("ADMIN")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(AppTheme.primaryBlue)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AppTheme.primaryBlue.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                            }
                            
                            Text("@\(currentUserState.username) · \(currentUserState.email)")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.secondaryText)
                            
                            HStack(spacing: 6) {
                                Text(currentUserState.country)
                                Text("·")
                                Text(currentUserState.level.rawValue)
                                Text("·")
                                Text(currentUserState.isSuspended ? "Suspended" : "Active")
                                    .foregroundColor(currentUserState.isSuspended ? AppTheme.liveRed : AppTheme.successGreen)
                                    .fontWeight(.semibold)
                            }
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.secondaryText)
                            .padding(.top, 2)
                        }
                    }
                    .padding(.top, AppTheme.space16)
                    
                    // User Activity KPIs
                    HStack(spacing: AppTheme.space12) {
                        metricItem(title: "Debates", value: "\(currentUserState.debatesParticipatedCount)")
                        metricItem(title: "Topics", value: "\(currentUserState.topicsCreatedCount)")
                        metricItem(title: "Posts", value: "\(userPosts.count)")
                        metricItem(title: "Streak", value: "\(currentUserState.dailyStreak)d")
                    }
                    .padding(.horizontal, AppTheme.space20)
                    
                    // Account Profile Details
                    VStack(alignment: .leading, spacing: AppTheme.space12) {
                        Text("Account Metadata")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.secondaryText)
                            .padding(.horizontal, AppTheme.space4)
                        
                        VStack(spacing: 8) {
                            telemetryRow(title: "Member Since", value: currentUserState.memberSinceText)
                            telemetryRow(
                                title: "Subscription Tier",
                                value: currentUserState.isPremium ? "Premium Plan" : "Free Tier",
                                color: currentUserState.isPremium ? AppTheme.primaryBlue : AppTheme.secondaryText
                            )
                            telemetryRow(title: "Vocabulary Saved", value: "\(currentUserState.savedVocabulary.count) expressions")
                            telemetryRow(
                                title: "Platform Standing",
                                value: currentUserState.isSuspended ? "Suspended" : "Active & Good Standing",
                                color: currentUserState.isSuspended ? AppTheme.liveRed : AppTheme.successGreen
                            )
                        }
                        .padding(AppTheme.space16)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                                .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, AppTheme.space20)
                    
                    // Authored Posts by User
                    if !userPosts.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.space12) {
                            Text("Authored Posts (\(userPosts.count))")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.secondaryText)
                                .padding(.horizontal, AppTheme.space4)
                            
                            VStack(spacing: 0) {
                                ForEach(Array(userPosts.enumerated()), id: \.element.id) { idx, post in
                                    HStack(spacing: AppTheme.space12) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(post.quoteText ?? post.caption ?? "Media Post")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(AppTheme.primaryText)
                                                .lineLimit(2)
                                            Text("\(post.createdAtText) · \(post.likesCount) likes · \(post.comments.count) comments")
                                                .font(.system(size: 11))
                                                .foregroundColor(AppTheme.secondaryText)
                                        }
                                        
                                        Spacer()
                                        
                                        Button(action: {
                                            withAnimation {
                                                debateManager.deletePost(id: post.id)
                                            }
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 13))
                                                .foregroundColor(AppTheme.liveRed)
                                                .frame(width: 32, height: 32)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                    .padding(.horizontal, AppTheme.space16)
                                    .padding(.vertical, 10)
                                    
                                    if idx < userPosts.count - 1 {
                                        Rectangle()
                                            .fill(AppTheme.separator)
                                            .frame(height: 1)
                                            .padding(.leading, AppTheme.space16)
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
                        .padding(.horizontal, AppTheme.space20)
                    }
                    
                    // Admin Control Actions
                    VStack(alignment: .leading, spacing: AppTheme.space12) {
                        Text("Admin Actions")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.secondaryText)
                            .padding(.horizontal, AppTheme.space4)
                        
                        VStack(spacing: 0) {
                            // Toggle Suspend
                            Button {
                                withAnimation {
                                    debateManager.toggleSuspendUser(id: currentUserState.id)
                                }
                            } label: {
                                HStack(spacing: AppTheme.space12) {
                                    Image(systemName: currentUserState.isSuspended ? "checkmark.circle.fill" : "nosign")
                                        .font(.system(size: 16))
                                        .foregroundColor(currentUserState.isSuspended ? AppTheme.successGreen : AppTheme.warningOrange)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(currentUserState.isSuspended ? "Restore Account Access" : "Suspend User Account")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(AppTheme.primaryText)
                                        Text(currentUserState.isSuspended ? "Allow user to speak and post" : "Block speaking in live rooms and posting")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.secondaryText)
                                    }
                                    Spacer()
                                }
                                .padding(AppTheme.space16)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Rectangle()
                                .fill(AppTheme.separator)
                                .frame(height: 1)
                                .padding(.leading, 52)
                            
                            // Toggle Admin Role
                            Button {
                                withAnimation {
                                    debateManager.toggleUserAdminRole(id: currentUserState.id)
                                }
                            } label: {
                                HStack(spacing: AppTheme.space12) {
                                    Image(systemName: currentUserState.isAdmin ? "shield.slash" : "shield.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.primaryBlue)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(currentUserState.isAdmin ? "Revoke Admin Rights" : "Make Co-Administrator")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(AppTheme.primaryText)
                                        Text(currentUserState.isAdmin ? "Demote to standard member" : "Grant platform moderation access")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.secondaryText)
                                    }
                                    Spacer()
                                }
                                .padding(AppTheme.space16)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Rectangle()
                                .fill(AppTheme.separator)
                                .frame(height: 1)
                                .padding(.leading, 52)
                            
                            // Delete User
                            Button {
                                showDeleteAlert = true
                            } label: {
                                HStack(spacing: AppTheme.space12) {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(AppTheme.liveRed)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("Delete Account Permanently")
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(AppTheme.liveRed)
                                        Text("Remove all posts, comments, topics and data")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppTheme.secondaryText)
                                    }
                                    Spacer()
                                }
                                .padding(AppTheme.space16)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                                .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, AppTheme.space20)
                }
                .padding(.bottom, AppTheme.space32)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("User Inspector")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.primaryBlue)
                }
            }
            .alert("Delete Account Permanently?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    debateManager.deleteUserAccount(id: currentUserState.id)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All posts, comments, and topics by @\(currentUserState.username) will be deleted immediately.")
            }
        }
    }
    
    private func metricItem(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold).monospacedDigit())
                .foregroundColor(AppTheme.primaryText)
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
        )
    }
    
    private func telemetryRow(title: String, value: String, color: Color = AppTheme.primaryText) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundColor(color)
        }
    }
}

#Preview {
    AdminDashboardView(debateManager: DebateManager())
}
