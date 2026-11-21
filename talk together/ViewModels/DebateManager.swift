import Foundation
import SwiftUI

@MainActor
@Observable
public final class DebateManager: @unchecked Sendable {
    // MARK: - State
    public var currentSession: DebateSession?
    public var topicsQueue: [Topic] = []
    public var feedPosts: [FeedPost] = []
    public var allUsers: [User] = []
    public var reports: [ContentReport] = []
    public var currentUser: User
    public var myRole: ParticipantRole = .listener
    public var myStance: DebateStance = .neutral
    public var hasRaisedHand: Bool = false
    public var sessionDuration: Int = 0
    public var isMiniPlayerActive: Bool = false
    public var dailyPrompt: String = "Today's 30s Challenge: What is one habit that changed your life for the better?"
    
    public var audioService: AudioService = AudioService.shared
    public var cloudKitManager: CloudKitManager = CloudKitManager.shared
    
    private var sessionTimer: Timer?
    private var speakingTurnTimer: Timer?
    private let usersDefaultsKey = "waxup_persisted_users"
    private let topicsDefaultsKey = "waxup_persisted_topics"
    private let postsDefaultsKey = "waxup_persisted_posts"
    private let reportsDefaultsKey = "waxup_persisted_reports"
    
    public init(currentUser: User? = nil) {
        let user = currentUser ?? User(
            username: "mouha_sarr",
            fullName: "Mouhamadou Sarr",
            email: "contact@syllaenglishacademy.com",
            country: "Senegal",
            level: .fluent,
            isPremium: true,
            isAdmin: true,
            dailyStreak: 3,
            savedVocabulary: []
        )
        self.currentUser = user
        
        // 1. Load persisted users or seed with registered community members
        if let data = UserDefaults.standard.data(forKey: usersDefaultsKey),
           let saved = try? JSONDecoder().decode([User].self, from: data), !saved.isEmpty {
            var loaded = saved
            if let idx = loaded.firstIndex(where: { $0.id == user.id || $0.email.lowercased() == user.email.lowercased() }) {
                loaded[idx].isAdmin = user.isAdmin
                loaded[idx].fullName = user.fullName
            } else {
                loaded.insert(user, at: 0)
            }
            self.allUsers = loaded
        } else {
            var seeded = User.sampleUsers
            if let idx = seeded.firstIndex(where: { $0.email.lowercased() == user.email.lowercased() }) {
                seeded[idx] = user
            } else if !seeded.contains(where: { $0.id == user.id }) {
                seeded.insert(user, at: 0)
            }
            self.allUsers = seeded
            self.persistUsers()
        }
        
        // 2. Load persisted debate topics or seed with community queue
        if let data = UserDefaults.standard.data(forKey: topicsDefaultsKey),
           let saved = try? JSONDecoder().decode([Topic].self, from: data), !saved.isEmpty {
            self.topicsQueue = saved
        } else {
            self.topicsQueue = Topic.sampleTopics
            self.persistTopics()
        }
        
        // 3. Load persisted feed posts or seed with community posts
        if let data = UserDefaults.standard.data(forKey: postsDefaultsKey),
           let saved = try? JSONDecoder().decode([FeedPost].self, from: data), !saved.isEmpty {
            self.feedPosts = saved
        } else {
            self.feedPosts = FeedPost.samplePosts
            self.persistPosts()
        }
        
        // 4. Load persisted safety reports
        if let data = UserDefaults.standard.data(forKey: reportsDefaultsKey),
           let saved = try? JSONDecoder().decode([ContentReport].self, from: data) {
            self.reports = saved
        }
        
        // 5. Asynchronous CloudKit Multi-Device Sync
        Task {
            await syncWithCloudKit()
        }
    }
    
    public func persistUsers() {
        if let data = try? JSONEncoder().encode(allUsers) {
            UserDefaults.standard.set(data, forKey: usersDefaultsKey)
        }
    }
    
    public func persistTopics() {
        if let data = try? JSONEncoder().encode(topicsQueue) {
            UserDefaults.standard.set(data, forKey: topicsDefaultsKey)
        }
    }
    
    public func persistPosts() {
        if let data = try? JSONEncoder().encode(feedPosts) {
            UserDefaults.standard.set(data, forKey: postsDefaultsKey)
        }
    }
    
    public func persistReports() {
        if let data = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(data, forKey: reportsDefaultsKey)
        }
    }
    
    // MARK: - CloudKit Multi-Device Synchronization
    public func syncWithCloudKit() async {
        guard cloudKitManager.isAvailable else { return }
        
        do {
            // 1. Fetch remote topics created by other users worldwide
            let remoteTopics = try await cloudKitManager.fetchPublicTopics()
            if !remoteTopics.isEmpty {
                for remote in remoteTopics {
                    if let idx = topicsQueue.firstIndex(where: { $0.id == remote.id }) {
                        topicsQueue[idx] = remote
                    } else {
                        topicsQueue.append(remote)
                    }
                }
                persistTopics()
            }
            
            // 2. Fetch remote posts created by other users worldwide
            let remotePosts = try await cloudKitManager.fetchPublicFeedPosts()
            if !remotePosts.isEmpty {
                for remote in remotePosts {
                    if let idx = feedPosts.firstIndex(where: { $0.id == remote.id }) {
                        feedPosts[idx] = remote
                    } else {
                        feedPosts.insert(remote, at: 0)
                    }
                }
                persistPosts()
            }
            
            // 3. Fetch remote community users
            let remoteUsers = try await cloudKitManager.fetchCommunityUsers()
            if !remoteUsers.isEmpty {
                for remote in remoteUsers {
                    if let idx = allUsers.firstIndex(where: { $0.id == remote.id }) {
                        allUsers[idx] = remote
                    } else {
                        allUsers.append(remote)
                    }
                }
                persistUsers()
            }
        } catch {
            print("CloudKit sync notice: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Session Management
    public func loadSession(for topic: Topic) {
        let isModerator = topic.creator.id == currentUser.id
        let initialRole: ParticipantRole = isModerator ? .moderator : .listener
        let initialStance: DebateStance = isModerator ? .neutral : .neutral
        
        self.myRole = initialRole
        self.myStance = initialStance
        self.hasRaisedHand = false
        
        // Build real participants list
        var initialParticipants: [Participant] = []
        
        let moderatorParticipant = Participant(
            user: topic.creator,
            role: .moderator,
            stance: .neutral,
            isMuted: false,
            isSpeaking: false,
            hasRaisedHand: false
        )
        initialParticipants.append(moderatorParticipant)
        
        // Add current user if different from moderator
        if topic.creator.id != currentUser.id {
            let localParticipant = Participant(
                user: currentUser,
                role: initialRole,
                stance: initialStance,
                isMuted: audioService.isMuted,
                isSpeaking: false,
                hasRaisedHand: false
            )
            initialParticipants.append(localParticipant)
        }
        
        self.currentSession = DebateSession(
            topic: topic,
            moderator: topic.creator,
            status: .live,
            participants: initialParticipants,
            votes: []
        )
        
        startTimer()
    }
    
    // MARK: - Audio & Voice Actions
    public func toggleMicrophone() {
        audioService.toggleMute()
        updateLocalParticipantState()
    }
    
    public func toggleHandRaise() {
        hasRaisedHand.toggle()
        updateLocalParticipantState()
    }
    
    public func switchStance(to stance: DebateStance) {
        myStance = stance
        myRole = .debater
        updateLocalParticipantState()
    }
    
    public func switchToListener() {
        myStance = .neutral
        myRole = .listener
        audioService.mute()
        hasRaisedHand = false
        updateLocalParticipantState()
    }
    
    public func leaveSession() {
        audioService.stopAudioSession()
        sessionTimer?.invalidate()
        sessionTimer = nil
        speakingTurnTimer?.invalidate()
        speakingTurnTimer = nil
        isMiniPlayerActive = false
        currentSession = nil
    }
    
    // MARK: - Synchronize Local Participant
    public func updateLocalParticipantState() {
        guard var session = currentSession else { return }
        if let index = session.participants.firstIndex(where: { $0.user.id == currentUser.id }) {
            session.participants[index].role = myRole
            session.participants[index].stance = myStance
            session.participants[index].isMuted = audioService.isMuted
            session.participants[index].isSpeaking = audioService.isSpeaking
            session.participants[index].hasRaisedHand = hasRaisedHand
            self.currentSession = session
        }
    }
    
    // MARK: - Queue & FIFO Advancing
    public func advanceQueueToNext() {
        guard !topicsQueue.isEmpty else { return }
        
        // Complete current live topic
        if let liveIndex = topicsQueue.firstIndex(where: { $0.status == .live }) {
            topicsQueue[liveIndex].status = .completed
            topicsQueue[liveIndex].queuePosition = nil
        }
        
        // Find next in queue
        if let nextIndex = topicsQueue.firstIndex(where: { $0.status == .inQueue }) {
            topicsQueue[nextIndex].status = .live
            topicsQueue[nextIndex].queuePosition = 1
            loadSession(for: topicsQueue[nextIndex])
        }
        
        // Re-number remaining queue
        var pos = 2
        for i in 0..<topicsQueue.count {
            if topicsQueue[i].status == .inQueue && topicsQueue[i].queuePosition != 1 {
                topicsQueue[i].queuePosition = pos
                pos += 1
            }
        }
        persistTopics()
    }
    
    public func addTopicToQueue(_ topic: Topic) {
        var newTopic = topic
        let queueCount = topicsQueue.filter { $0.status == .inQueue }.count
        newTopic.queuePosition = queueCount + 2 // after live and current queue
        topicsQueue.append(newTopic)
        persistTopics()
        
        Task {
            try? await cloudKitManager.saveTopic(newTopic)
        }
    }
    
    // MARK: - Topic CRUD (Update & Delete)
    public func updateTopic(_ updated: Topic) {
        if let index = topicsQueue.firstIndex(where: { $0.id == updated.id }) {
            topicsQueue[index] = updated
        }
        if currentSession?.topic.id == updated.id {
            currentSession?.topic = updated
        }
        persistTopics()
        
        Task {
            try? await cloudKitManager.saveTopic(updated)
        }
    }
    
    public func deleteTopic(id: UUID) {
        topicsQueue.removeAll { $0.id == id }
        if currentSession?.topic.id == id {
            leaveSession()
        }
        renumberQueue()
        persistTopics()
        
        Task {
            try? await cloudKitManager.deleteTopic(id: id)
        }
    }
    
    private func renumberQueue() {
        var pos = topicsQueue.contains(where: { $0.status == .live }) ? 2 : 1
        for i in 0..<topicsQueue.count {
            if topicsQueue[i].status == .inQueue {
                topicsQueue[i].queuePosition = pos
                pos += 1
            }
        }
    }
    
    // MARK: - Feed Post CRUD (Create, Read, Update, Delete)
    public func addPost(_ post: FeedPost) {
        var newPost = post
        let hasMedia = newPost.imageData != nil || newPost.audioURL != nil
        if hasMedia {
            newPost.uploadProgress = 0.05
        }
        feedPosts.insert(newPost, at: 0)
        persistPosts()
        
        Task {
            try? await cloudKitManager.saveFeedPost(newPost)
        }
        
        if hasMedia {
            simulateWhatsAppUpload(for: newPost.id)
        }
    }
    
    private func simulateWhatsAppUpload(for postID: UUID) {
        Task {
            for step in 1...10 {
                try? await Task.sleep(nanoseconds: 75_000_000)
                if let index = feedPosts.firstIndex(where: { $0.id == postID }) {
                    feedPosts[index].uploadProgress = Double(step) / 10.0
                } else {
                    return
                }
            }
            try? await Task.sleep(nanoseconds: 120_000_000)
            if let index = feedPosts.firstIndex(where: { $0.id == postID }) {
                feedPosts[index].uploadProgress = nil
                self.persistPosts()
            }
        }
    }
    
    public func updatePost(_ updated: FeedPost) {
        if let index = feedPosts.firstIndex(where: { $0.id == updated.id }) {
            feedPosts[index] = updated
            persistPosts()
            Task {
                try? await cloudKitManager.saveFeedPost(updated)
            }
        }
    }
    
    public func deletePost(id: UUID) {
        if let post = feedPosts.first(where: { $0.id == id }), let audioURL = post.audioURL {
            try? FileManager.default.removeItem(at: audioURL)
        }
        feedPosts.removeAll { $0.id == id }
        persistPosts()
        
        Task {
            try? await cloudKitManager.deleteFeedPost(id: id)
        }
    }
    
    public func deleteComment(postID: UUID, commentID: UUID) {
        if let index = feedPosts.firstIndex(where: { $0.id == postID }) {
            feedPosts[index].comments.removeAll { $0.id == commentID }
            persistPosts()
        }
    }
    
    // MARK: - Admin Monitoring & Moderation Actions
    public var pendingReportsCount: Int {
        reports.filter { !$0.isResolved }.count
    }
    
    public var totalLikesCount: Int {
        feedPosts.reduce(0) { $0 + $1.likesCount }
    }
    
    public var totalCommentsCount: Int {
        feedPosts.reduce(0) { $0 + $1.comments.count }
    }
    
    public var totalVoicePostsCount: Int {
        feedPosts.filter { $0.audioDurationSeconds != nil }.count
    }
    
    public var totalPhotoPostsCount: Int {
        feedPosts.filter { $0.imageData != nil }.count
    }
    
    public var activeUsersCount: Int {
        allUsers.filter { !$0.isSuspended }.count
    }
    
    public var suspendedUsersCount: Int {
        allUsers.filter { $0.isSuspended }.count
    }
    
    public var adminUsersCount: Int {
        allUsers.filter { $0.isAdmin }.count
    }
    
    public var freeUsersCount: Int {
        allUsers.filter { !$0.isPremium }.count
    }
    
    public var premiumUsersCount: Int {
        allUsers.filter { $0.isPremium }.count
    }
    
    public var formattedSessionDuration: String {
        let minutes = sessionDuration / 60
        let seconds = sessionDuration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    public var totalBookmarksCount: Int {
        feedPosts.filter { $0.isBookmarked }.count
    }
    
    public var topActiveUser: User? {
        allUsers.max(by: { $0.debatesParticipatedCount < $1.debatesParticipatedCount })
    }
    
    public var topStreakUser: User? {
        allUsers.max(by: { $0.dailyStreak < $1.dailyStreak })
    }
    
    public var totalDebatesParticipatedAcrossPlatform: Int {
        allUsers.reduce(0) { $0 + $1.debatesParticipatedCount }
    }
    
    public var totalTopicsCreatedAcrossPlatform: Int {
        allUsers.reduce(0) { $0 + $1.topicsCreatedCount }
    }
    
    public var usersByLevelCounts: [(level: EnglishLevel, count: Int)] {
        EnglishLevel.allCases.map { lvl in
            (level: lvl, count: allUsers.filter { $0.level == lvl }.count)
        }
    }
    
    public var usersByCountryCounts: [(country: String, count: Int)] {
        let grouped = Dictionary(grouping: allUsers, by: { $0.country })
        return grouped.map { (country: $0.key, count: $0.value.count) }
            .sorted(by: { $0.count > $1.count })
    }
    
    public func generateFullPlatformAuditReport() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        let nowStr = formatter.string(from: Date())
        
        var report = """
        ==================================================
        WAXUP PLATFORM AUDIT REPORT - MASTER MONITORING
        Generated: \(nowStr)
        Organization: Sylla English Academy
        ==================================================
        
        [ 1. USER METRICS & REGISTRATIONS ]
        • Total Registered Users : \(allUsers.count)
        • Active Users           : \(activeUsersCount)
        • Suspended Accounts     : \(suspendedUsersCount)
        • Administrator Accounts : \(adminUsersCount)
        
        [ 2. ENGLISH PROFICIENCY BREAKDOWN ]
        """
        for item in usersByLevelCounts {
            report += "\n• \(item.level.rawValue): \(item.count) users"
        }
        
        report += "\n\n[ 3. GEOGRAPHIC DISTRIBUTION ]"
        for item in usersByCountryCounts {
            report += "\n• \(item.country): \(item.count) users"
        }
        
        report += """
        
        
        [ 4. DEBATES & SPEAKING ACTIVITY ]
        • Total Debates Completed : \(totalDebatesParticipatedAcrossPlatform)
        • Active & Queued Topics  : \(topicsQueue.count)
        
        [ 5. COMMUNITY FEED & CONTENT ]
        • Total Feed Posts       : \(feedPosts.count)
        • Voice Audio Posts      : \(totalVoicePostsCount)
        • Photo Posts            : \(totalPhotoPostsCount)
        • Total Likes            : \(totalLikesCount)
        • Total Comments         : \(totalCommentsCount)
        
        [ 6. MODERATION & SAFETY ]
        • Total Reports          : \(reports.count)
        • Pending Action         : \(pendingReportsCount)
        • Resolved Reports       : \(reports.filter { $0.isResolved }.count)
        
        ==================================================
        REGISTERED USERS ROSTER
        ==================================================
        """
        for u in allUsers {
            report += "\n• \(u.fullName) (@\(u.username)) | \(u.email) | \(u.country) | \(u.level.rawValue) | Debates: \(u.debatesParticipatedCount) | Topics: \(u.topicsCreatedCount) | Admin: \(u.isAdmin ? "YES" : "NO") | Status: \(u.isSuspended ? "SUSPENDED" : "ACTIVE")"
        }
        report += "\n==================================================\n"
        return report
    }
    
    public func submitReport(post: FeedPost, reason: ReportReason) {
        let preview = post.quoteText ?? post.caption ?? (post.audioDurationSeconds != nil ? "Voice note post" : "Photo post")
        let report = ContentReport(
            postID: post.id,
            postPreview: preview,
            reportedAuthor: post.author,
            reporterUsername: currentUser.username,
            reason: reason.rawValue,
            reasonIconName: reason.iconName,
            createdAtText: "Just now"
        )
        reports.insert(report, at: 0)
    }
    
    public func toggleSuspendUser(id: UUID) {
        if let index = allUsers.firstIndex(where: { $0.id == id }) {
            allUsers[index].isSuspended.toggle()
            persistUsers()
        }
    }
    
    public func toggleUserAdminRole(id: UUID) {
        if let index = allUsers.firstIndex(where: { $0.id == id }) {
            allUsers[index].isAdmin.toggle()
            persistUsers()
        }
    }
    
    public func generateUsersExportReport() -> String {
        var csv = "Full Name,Username,Email,Country,Level,Debates,Topics,Streak,Admin,Suspended,Joined\n"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        for u in allUsers {
            csv += "\"\(u.fullName)\",\"@\(u.username)\",\"\(u.email)\",\"\(u.country)\",\"\(u.level.rawValue)\",\(u.debatesParticipatedCount),\(u.topicsCreatedCount),\(u.dailyStreak),\(u.isAdmin ? "YES" : "NO"),\(u.isSuspended ? "YES" : "NO"),\"\(formatter.string(from: u.createdAt))\"\n"
        }
        return csv
    }
    
    public func deleteUserAccount(id: UUID) {
        // Remove all user's posts and audio files
        let userPosts = feedPosts.filter { $0.author.id == id }
        for post in userPosts {
            if let audioURL = post.audioURL {
                try? FileManager.default.removeItem(at: audioURL)
            }
        }
        feedPosts.removeAll { $0.author.id == id }
        
        // Remove user's comments from all posts
        for i in 0..<feedPosts.count {
            feedPosts[i].comments.removeAll { $0.author.id == id }
        }
        
        // Remove user's queued/live topics and renumber FIFO
        topicsQueue.removeAll { $0.creator.id == id }
        renumberQueue()
        persistTopics()
        persistPosts()
        
        // Remove user from platform
        allUsers.removeAll { $0.id == id }
        persistUsers()
        
        // Resolve related reports
        for i in 0..<reports.count where reports[i].reportedAuthor.id == id {
            reports[i].isResolved = true
        }
        persistReports()
    }
    
    public func resolveReport(id: UUID) {
        if let index = reports.firstIndex(where: { $0.id == id }) {
            reports[index].isResolved = true
            persistReports()
        }
    }
    
    public func deleteReportedPostAndResolve(report: ContentReport) {
        deletePost(id: report.postID)
        resolveReport(id: report.id)
    }
    
    public func banAuthorAndResolve(report: ContentReport) {
        deleteUserAccount(id: report.reportedAuthor.id)
        resolveReport(id: report.id)
    }
    
    // MARK: - Speaking Turn Countdown Timer
    public func startSpeakingTurn(speakerId: UUID, durationSeconds: Int = 60) {
        guard var session = currentSession else { return }
        session.activeSpeakerId = speakerId
        session.speakingTurnSecondsRemaining = durationSeconds
        session.isSpeakingTurnActive = true
        self.currentSession = session
        
        speakingTurnTimer?.invalidate()
        speakingTurnTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                guard var current = self.currentSession, current.isSpeakingTurnActive else {
                    self.speakingTurnTimer?.invalidate()
                    return
                }
                if current.speakingTurnSecondsRemaining > 0 {
                    current.speakingTurnSecondsRemaining -= 1
                    self.currentSession = current
                } else {
                    current.isSpeakingTurnActive = false
                    self.currentSession = current
                    self.speakingTurnTimer?.invalidate()
                }
            }
        }
    }
    
    public func pauseSpeakingTurn() {
        guard var session = currentSession else { return }
        session.isSpeakingTurnActive = false
        self.currentSession = session
        speakingTurnTimer?.invalidate()
    }
    
    public func resetSpeakingTurn(durationSeconds: Int = 60) {
        guard var session = currentSession else { return }
        session.speakingTurnSecondsRemaining = durationSeconds
        session.isSpeakingTurnActive = false
        self.currentSession = session
        speakingTurnTimer?.invalidate()
    }
    
    // MARK: - End-of-Debate Conviction Voting
    public var hasCurrentUserVoted: Bool {
        guard let session = currentSession else { return false }
        return session.votes.contains(where: { $0.userId == currentUser.id })
    }
    
    public var currentUserVotedStance: DebateStance? {
        guard let session = currentSession else { return nil }
        return session.votes.first(where: { $0.userId == currentUser.id })?.stance
    }
    
    public func castVote(stance: DebateStance) {
        guard var session = currentSession else { return }
        // Remove prior vote from this user if any
        session.votes.removeAll { $0.userId == currentUser.id }
        session.votes.append(DebateVote(userId: currentUser.id, stance: stance))
        self.currentSession = session
        recordPracticeActivity()
    }
    
    // MARK: - Vocabulary & Expressions
    public func addVocabularyItem(_ word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !currentUser.savedVocabulary.contains(trimmed) else { return }
        currentUser.savedVocabulary.insert(trimmed, at: 0)
        if let idx = allUsers.firstIndex(where: { $0.id == currentUser.id }) {
            allUsers[idx].savedVocabulary = currentUser.savedVocabulary
        }
    }
    
    public func removeVocabularyItem(_ word: String) {
        currentUser.savedVocabulary.removeAll { $0 == word }
        if let idx = allUsers.firstIndex(where: { $0.id == currentUser.id }) {
            allUsers[idx].savedVocabulary = currentUser.savedVocabulary
        }
    }
    
    // MARK: - Gamification & Streak
    public func recordPracticeActivity() {
        // Increment streak once per day simulation
        currentUser.dailyStreak += 1
        currentUser.debatesParticipatedCount += 1
        if let idx = allUsers.firstIndex(where: { $0.id == currentUser.id }) {
            allUsers[idx].dailyStreak = currentUser.dailyStreak
            allUsers[idx].debatesParticipatedCount = currentUser.debatesParticipatedCount
        }
    }
    
    // MARK: - Timer
    private func startTimer() {
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.sessionDuration += 1
                // Sync speaking state from real audio service
                self.updateLocalParticipantState()
            }
        }
    }
}
