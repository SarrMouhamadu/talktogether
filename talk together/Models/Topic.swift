import Foundation

// MARK: - Topic Model (FIFO Queue & Debate Subject)
public struct Topic: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var title: String
    public var debateQuestion: String
    public var description: String?
    public var category: TopicCategory
    public var creator: User
    public var status: TopicStatus
    public var queuePosition: Int?
    public var createdAt: Date
    public var scheduledStartTime: Date?
    
    public init(
        id: UUID = UUID(),
        title: String,
        debateQuestion: String,
        description: String? = nil,
        category: TopicCategory = .general,
        creator: User,
        status: TopicStatus = .inQueue,
        queuePosition: Int? = nil,
        createdAt: Date = Date(),
        scheduledStartTime: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.debateQuestion = debateQuestion
        self.description = description
        self.category = category
        self.creator = creator
        self.status = status
        self.queuePosition = queuePosition
        self.createdAt = createdAt
        self.scheduledStartTime = scheduledStartTime
    }
    
    public var formattedScheduledTime: String? {
        guard let scheduledStartTime else { return nil }
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(scheduledStartTime) {
            formatter.dateFormat = "'Today at' HH:mm"
        } else if Calendar.current.isDateInTomorrow(scheduledStartTime) {
            formatter.dateFormat = "'Tomorrow at' HH:mm"
        } else {
            formatter.dateFormat = "MMM d, HH:mm"
        }
        return formatter.string(from: scheduledStartTime)
    }
    
    public var shortScheduledTime: String? {
        guard let scheduledStartTime else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: scheduledStartTime)
    }
}

// MARK: - Sample Previews
extension Topic {
    public static let sampleLive = Topic(
        id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
        title: "Social Media Impact",
        debateQuestion: "Is social media doing more harm than good to society?",
        description: "Join us to discuss mental health, connectivity, and misinformation in the digital age.",
        category: .society,
        creator: User.sampleModerator,
        status: .live,
        queuePosition: 1,
        createdAt: Date().addingTimeInterval(-3600),
        scheduledStartTime: Date().addingTimeInterval(-600)
    )
    
    public static let sampleNextInQueue = Topic(
        id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
        title: "AI and Job Security",
        debateQuestion: "Can artificial intelligence replace human workers in creative industries?",
        description: "Examining AI writing, design, and coding tools and their economic impact.",
        category: .technology,
        creator: User.sampleDebater1,
        status: .inQueue,
        queuePosition: 2,
        createdAt: Date().addingTimeInterval(-1800),
        scheduledStartTime: Date().addingTimeInterval(1200)
    )
    
    public static let sampleQueue3 = Topic(
        id: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc")!,
        title: "Free Higher Education",
        debateQuestion: "Should university education be completely free for everyone?",
        description: "Public funding versus private investment in higher education.",
        category: .education,
        creator: User.sampleDebater2,
        status: .inQueue,
        queuePosition: 3,
        createdAt: Date().addingTimeInterval(-900),
        scheduledStartTime: nil
    )
    
    public static let sampleTopics: [Topic] = [
        sampleLive,
        sampleNextInQueue,
        sampleQueue3
    ]
}
