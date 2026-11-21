import Foundation
import CloudKit
import SwiftUI

@MainActor
@Observable
public final class CloudKitManager: @unchecked Sendable {
    public static let shared = CloudKitManager()
    
    // MARK: - State
    public private(set) var isAvailable: Bool = false
    public private(set) var accountStatusDescription: String = "Checking iCloud..."
    public private(set) var lastSyncDate: Date? = nil
    public private(set) var isSyncing: Bool = false
    public private(set) var syncError: String? = nil
    
    private let container: CKContainer
    private var publicDB: CKDatabase { container.publicCloudDatabase }
    
    public init() {
        self.container = CKContainer.default()
        Task {
            await checkAccountStatus()
        }
    }
    
    // MARK: - Account Status
    public func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                self.isAvailable = true
                self.accountStatusDescription = "iCloud Connected"
                self.syncError = nil
            case .noAccount:
                self.isAvailable = false
                self.accountStatusDescription = "No iCloud Account Signed In"
            case .restricted:
                self.isAvailable = false
                self.accountStatusDescription = "iCloud Restricted"
            case .couldNotDetermine:
                self.isAvailable = false
                self.accountStatusDescription = "Could Not Determine iCloud Status"
            case .temporarilyUnavailable:
                self.isAvailable = false
                self.accountStatusDescription = "iCloud Temporarily Unavailable"
            @unknown default:
                self.isAvailable = false
                self.accountStatusDescription = "iCloud Unknown Status"
            }
        } catch {
            self.isAvailable = false
            self.accountStatusDescription = "iCloud Check Error"
            self.syncError = error.localizedDescription
        }
    }
    
    // MARK: - Topics (CloudKit Public Database)
    public func fetchPublicTopics() async throws -> [Topic] {
        let query = CKQuery(recordType: "Topic", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let (results, _) = try await publicDB.records(matching: query)
        var topics: [Topic] = []
        
        for (_, result) in results {
            if let record = try? result.get() {
                if let topic = topicFromRecord(record) {
                    topics.append(topic)
                }
            }
        }
        
        return topics
    }
    
    public func saveTopic(_ topic: Topic) async throws {
        let recordID = CKRecord.ID(recordName: topic.id.uuidString)
        let record = CKRecord(recordType: "Topic", recordID: recordID)
        
        record["title"] = topic.title as CKRecordValue
        record["debateQuestion"] = topic.debateQuestion as CKRecordValue
        if let desc = topic.description {
            record["description"] = desc as CKRecordValue
        }
        record["category"] = topic.category.rawValue as CKRecordValue
        record["creatorId"] = topic.creator.id.uuidString as CKRecordValue
        record["creatorName"] = topic.creator.fullName as CKRecordValue
        record["creatorUsername"] = topic.creator.username as CKRecordValue
        record["creatorCountry"] = topic.creator.country as CKRecordValue
        record["creatorLevel"] = topic.creator.level.rawValue as CKRecordValue
        record["status"] = topic.status.rawValue as CKRecordValue
        if let pos = topic.queuePosition {
            record["queuePosition"] = pos as CKRecordValue
        }
        if let scheduled = topic.scheduledStartTime {
            record["scheduledStartTime"] = scheduled as CKRecordValue
        }
        record["createdAt"] = topic.createdAt as CKRecordValue
        
        _ = try await publicDB.save(record)
        self.lastSyncDate = Date()
    }
    
    public func deleteTopic(id: UUID) async throws {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        _ = try await publicDB.deleteRecord(withID: recordID)
        self.lastSyncDate = Date()
    }
    
    // MARK: - Feed Posts (CloudKit Public Database)
    public func fetchPublicFeedPosts() async throws -> [FeedPost] {
        let query = CKQuery(recordType: "FeedPost", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let (results, _) = try await publicDB.records(matching: query)
        var posts: [FeedPost] = []
        
        for (_, result) in results {
            if let record = try? result.get() {
                if let post = feedPostFromRecord(record) {
                    posts.append(post)
                }
            }
        }
        
        return posts
    }
    
    public func saveFeedPost(_ post: FeedPost) async throws {
        let recordID = CKRecord.ID(recordName: post.id.uuidString)
        let record = CKRecord(recordType: "FeedPost", recordID: recordID)
        
        record["authorId"] = post.author.id.uuidString as CKRecordValue
        record["authorName"] = post.author.fullName as CKRecordValue
        record["authorUsername"] = post.author.username as CKRecordValue
        record["authorCountry"] = post.author.country as CKRecordValue
        record["authorLevel"] = post.author.level.rawValue as CKRecordValue
        
        if let topic = post.topicTitle {
            record["topicTitle"] = topic as CKRecordValue
        }
        if let stance = post.stance {
            record["stance"] = stance.rawValue as CKRecordValue
        }
        if let quote = post.quoteText {
            record["quoteText"] = quote as CKRecordValue
        }
        if let caption = post.caption {
            record["caption"] = caption as CKRecordValue
        }
        if let duration = post.audioDurationSeconds {
            record["audioDurationSeconds"] = duration as CKRecordValue
        }
        record["likesCount"] = post.likesCount as CKRecordValue
        record["createdAtText"] = post.createdAtText as CKRecordValue
        record["createdAt"] = Date() as CKRecordValue
        
        // Save audio voice file as CKAsset if present
        if let audioURL = post.audioURL, FileManager.default.fileExists(atPath: audioURL.path) {
            record["audioAsset"] = CKAsset(fileURL: audioURL)
        }
        
        // Save image file as CKAsset if present
        if let imageData = post.imageData {
            let tempDir = FileManager.default.temporaryDirectory
            let tempFile = tempDir.appendingPathComponent("\(post.id.uuidString).jpg")
            try? imageData.write(to: tempFile)
            record["imageAsset"] = CKAsset(fileURL: tempFile)
        }
        
        _ = try await publicDB.save(record)
        self.lastSyncDate = Date()
    }
    
    public func deleteFeedPost(id: UUID) async throws {
        let recordID = CKRecord.ID(recordName: id.uuidString)
        _ = try await publicDB.deleteRecord(withID: recordID)
        self.lastSyncDate = Date()
    }
    
    // MARK: - Community User Profiles (CloudKit Public Database)
    public func fetchCommunityUsers() async throws -> [User] {
        let query = CKQuery(recordType: "UserProfile", predicate: NSPredicate(value: true))
        let (results, _) = try await publicDB.records(matching: query)
        var users: [User] = []
        
        for (_, result) in results {
            if let record = try? result.get(), let user = userFromRecord(record) {
                users.append(user)
            }
        }
        
        return users
    }
    
    public func saveUserProfile(_ user: User) async throws {
        let recordID = CKRecord.ID(recordName: user.id.uuidString)
        let record = CKRecord(recordType: "UserProfile", recordID: recordID)
        
        record["fullName"] = user.fullName as CKRecordValue
        record["username"] = user.username as CKRecordValue
        record["email"] = user.email as CKRecordValue
        record["country"] = user.country as CKRecordValue
        record["level"] = user.level.rawValue as CKRecordValue
        record["debatesCount"] = user.debatesParticipatedCount as CKRecordValue
        record["topicsCount"] = user.topicsCreatedCount as CKRecordValue
        record["dailyStreak"] = user.dailyStreak as CKRecordValue
        record["isAdmin"] = (user.isAdmin ? 1 : 0) as CKRecordValue
        record["isSuspended"] = (user.isSuspended ? 1 : 0) as CKRecordValue
        record["isPremium"] = (user.isPremium ? 1 : 0) as CKRecordValue
        record["createdAt"] = user.createdAt as CKRecordValue
        
        _ = try await publicDB.save(record)
        self.lastSyncDate = Date()
    }
    
    // MARK: - Mapping Helpers
    private func topicFromRecord(_ record: CKRecord) -> Topic? {
        guard let title = record["title"] as? String,
              let question = record["debateQuestion"] as? String,
              let catRaw = record["category"] as? String,
              let category = TopicCategory(rawValue: catRaw),
              let creatorIdStr = record["creatorId"] as? String,
              let creatorUUID = UUID(uuidString: creatorIdStr),
              let creatorName = record["creatorName"] as? String,
              let creatorUsername = record["creatorUsername"] as? String else {
            return nil
        }
        
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let desc = record["description"] as? String
        let country = (record["creatorCountry"] as? String) ?? "Senegal"
        let levelRaw = (record["creatorLevel"] as? String) ?? "Intermediate"
        let level = EnglishLevel(rawValue: levelRaw) ?? .intermediate
        let statusRaw = (record["status"] as? String) ?? "In Queue"
        let status = TopicStatus(rawValue: statusRaw) ?? .inQueue
        let pos = record["queuePosition"] as? Int
        let scheduled = record["scheduledStartTime"] as? Date
        let createdAt = (record["createdAt"] as? Date) ?? Date()
        
        let creator = User(
            id: creatorUUID,
            username: creatorUsername,
            fullName: creatorName,
            email: "\(creatorUsername)@syllaenglishacademy.com",
            country: country,
            level: level
        )
        
        return Topic(
            id: id,
            title: title,
            debateQuestion: question,
            description: desc,
            category: category,
            creator: creator,
            status: status,
            queuePosition: pos,
            createdAt: createdAt,
            scheduledStartTime: scheduled
        )
    }
    
    private func feedPostFromRecord(_ record: CKRecord) -> FeedPost? {
        guard let authorIdStr = record["authorId"] as? String,
              let authorUUID = UUID(uuidString: authorIdStr),
              let authorName = record["authorName"] as? String,
              let authorUsername = record["authorUsername"] as? String else {
            return nil
        }
        
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let country = (record["authorCountry"] as? String) ?? "Senegal"
        let levelRaw = (record["authorLevel"] as? String) ?? "Intermediate"
        let level = EnglishLevel(rawValue: levelRaw) ?? .intermediate
        
        let author = User(
            id: authorUUID,
            username: authorUsername,
            fullName: authorName,
            email: "\(authorUsername)@syllaenglishacademy.com",
            country: country,
            level: level
        )
        
        let topicTitle = record["topicTitle"] as? String
        let stanceRaw = record["stance"] as? String
        let stance = stanceRaw != nil ? DebateStance(rawValue: stanceRaw!) : nil
        let quoteText = record["quoteText"] as? String
        let caption = record["caption"] as? String
        let duration = record["audioDurationSeconds"] as? Int
        let likesCount = (record["likesCount"] as? Int) ?? 0
        let createdAtText = (record["createdAtText"] as? String) ?? "Recently"
        
        var audioURL: URL? = nil
        if let asset = record["audioAsset"] as? CKAsset, let fileURL = asset.fileURL {
            audioURL = fileURL
        }
        
        var imageData: Data? = nil
        if let asset = record["imageAsset"] as? CKAsset, let fileURL = asset.fileURL {
            imageData = try? Data(contentsOf: fileURL)
        }
        
        return FeedPost(
            id: id,
            author: author,
            topicTitle: topicTitle,
            stance: stance,
            quoteText: quoteText,
            caption: caption,
            imageData: imageData,
            audioURL: audioURL,
            audioDurationSeconds: duration,
            likesCount: likesCount,
            createdAtText: createdAtText
        )
    }
    
    private func userFromRecord(_ record: CKRecord) -> User? {
        guard let fullName = record["fullName"] as? String,
              let username = record["username"] as? String else {
            return nil
        }
        
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let email = (record["email"] as? String) ?? "\(username)@syllaenglishacademy.com"
        let country = (record["country"] as? String) ?? "Senegal"
        let levelRaw = (record["level"] as? String) ?? "Intermediate"
        let level = EnglishLevel(rawValue: levelRaw) ?? .intermediate
        let debatesCount = (record["debatesCount"] as? Int) ?? 0
        let topicsCount = (record["topicsCount"] as? Int) ?? 0
        let streak = (record["dailyStreak"] as? Int) ?? 1
        let isAdmin = ((record["isAdmin"] as? Int) ?? 0) == 1
        let isSuspended = ((record["isSuspended"] as? Int) ?? 0) == 1
        let isPremium = ((record["isPremium"] as? Int) ?? 0) == 1
        let createdAt = (record["createdAt"] as? Date) ?? Date()
        
        return User(
            id: id,
            username: username,
            fullName: fullName,
            email: email,
            country: country,
            level: level,
            createdAt: createdAt,
            topicsCreatedCount: topicsCount,
            debatesParticipatedCount: debatesCount,
            isPremium: isPremium,
            isAdmin: isAdmin,
            isSuspended: isSuspended,
            dailyStreak: streak
        )
    }
}
