import Foundation

// MARK: - User Model
public struct User: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var username: String
    public var fullName: String
    public var email: String
    public var avatarUrl: URL?
    public var country: String
    public var level: EnglishLevel
    public var createdAt: Date
    public var topicsCreatedCount: Int
    public var debatesParticipatedCount: Int
    public var isPremium: Bool
    public var isAdmin: Bool
    public var isSuspended: Bool
    public var dailyStreak: Int
    public var savedVocabulary: [String]
    
    public init(
        id: UUID = UUID(),
        username: String,
        fullName: String,
        email: String,
        avatarUrl: URL? = nil,
        country: String = "Senegal",
        level: EnglishLevel = .intermediate,
        createdAt: Date = Date(),
        topicsCreatedCount: Int = 0,
        debatesParticipatedCount: Int = 0,
        isPremium: Bool = false,
        isAdmin: Bool = false,
        isSuspended: Bool = false,
        dailyStreak: Int = 3,
        savedVocabulary: [String] = [
            "To play devil's advocate",
            "Food for thought",
            "At the end of the day",
            "On the fence"
        ]
    ) {
        self.id = id
        self.username = username
        self.fullName = fullName
        self.email = email
        self.avatarUrl = avatarUrl
        self.country = country
        self.level = level
        self.createdAt = createdAt
        self.topicsCreatedCount = topicsCreatedCount
        self.debatesParticipatedCount = debatesParticipatedCount
        self.isPremium = isPremium
        self.isAdmin = isAdmin
        self.isSuspended = isSuspended
        self.dailyStreak = dailyStreak
        self.savedVocabulary = savedVocabulary
    }
    
    public var initials: String {
        let parts = fullName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(username.prefix(2)).uppercased()
    }
    
    public var memberSinceText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
}

// MARK: - Sample Previews
extension User {
    public static let sampleModerator = User(
        id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
        username: "mouha_sarr",
        fullName: "Mouhamadou Sarr",
        email: "mouhamadou@example.com",
        country: "Senegal",
        level: .fluent,
        topicsCreatedCount: 5,
        debatesParticipatedCount: 18,
        isPremium: true,
        isAdmin: true
    )
    
    public static let sampleDebater1 = User(
        id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
        username: "fatou_diop",
        fullName: "Fatou Diop",
        email: "fatou@example.com",
        country: "Senegal",
        level: .advanced,
        topicsCreatedCount: 2,
        debatesParticipatedCount: 12
    )
    
    public static let sampleDebater2 = User(
        id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
        username: "alioune_ba",
        fullName: "Alioune Ba",
        email: "alioune@example.com",
        country: "Senegal",
        level: .intermediate,
        topicsCreatedCount: 1,
        debatesParticipatedCount: 7
    )
    
    public static let sampleDebater3 = User(
        id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
        username: "aicha_ndiaye",
        fullName: "Aïcha Ndiaye",
        email: "aicha@example.com",
        country: "Senegal",
        level: .advanced,
        topicsCreatedCount: 3,
        debatesParticipatedCount: 24
    )
    
    public static let sampleDebater4 = User(
        id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
        username: "ibrahima_fall",
        fullName: "Ibrahima Fall",
        email: "ibrahima@example.com",
        country: "Senegal",
        level: .fluent,
        topicsCreatedCount: 4,
        debatesParticipatedCount: 15
    )
    
    public static let sampleDebater5 = User(
        id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
        username: "mariama_sow",
        fullName: "Mariama Sow",
        email: "mariama@example.com",
        country: "Senegal",
        level: .intermediate,
        topicsCreatedCount: 1,
        debatesParticipatedCount: 10
    )
    
    public static let sampleDebater6 = User(
        id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
        username: "cheikh_tidiane",
        fullName: "Cheikh Tidiane",
        email: "cheikh@example.com",
        country: "Senegal",
        level: .advanced,
        topicsCreatedCount: 2,
        debatesParticipatedCount: 9
    )
    
    public static let sampleDebater7 = User(
        id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
        username: "ousmane_diallo",
        fullName: "Ousmane Diallo",
        email: "ousmane@example.com",
        country: "Senegal",
        level: .beginner,
        topicsCreatedCount: 0,
        debatesParticipatedCount: 5
    )
    
    public static let sampleUsers: [User] = [
        sampleDebater3,  // 24 debates - #1
        sampleModerator, // 18 debates - #2
        sampleDebater4,  // 15 debates - #3
        sampleDebater1,  // 12 debates - #4
        sampleDebater5,  // 10 debates - #5
        sampleDebater6,  // 9 debates - #6
        sampleDebater2,  // 7 debates - #7
        sampleDebater7   // 5 debates - #8
    ]
}
