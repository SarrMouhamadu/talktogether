import Foundation

// MARK: - Debate Vote
public struct DebateVote: Identifiable, Codable, Sendable {
    public let id: UUID
    public let userId: UUID
    public let stance: DebateStance
    public let createdAt: Date
    
    public init(id: UUID = UUID(), userId: UUID, stance: DebateStance, createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.stance = stance
        self.createdAt = createdAt
    }
}

// MARK: - Debate Session (Live Room)
public struct DebateSession: Identifiable, Codable, Sendable {
    public let id: UUID
    public var topic: Topic
    public var moderator: User
    public var roomName: String
    public var status: TopicStatus
    public var startedAt: Date?
    public var endedAt: Date?
    public var participants: [Participant]
    public var votes: [DebateVote]
    public var speakingTurnSecondsRemaining: Int
    public var isSpeakingTurnActive: Bool
    public var activeSpeakerId: UUID?
    
    public init(
        id: UUID = UUID(),
        topic: Topic,
        moderator: User,
        roomName: String = "session-\(UUID().uuidString.prefix(8))",
        status: TopicStatus = .live,
        startedAt: Date? = Date(),
        endedAt: Date? = nil,
        participants: [Participant] = [],
        votes: [DebateVote] = [],
        speakingTurnSecondsRemaining: Int = 60,
        isSpeakingTurnActive: Bool = false,
        activeSpeakerId: UUID? = nil
    ) {
        self.id = id
        self.topic = topic
        self.moderator = moderator
        self.roomName = roomName
        self.status = status
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.participants = participants
        self.votes = votes
        self.speakingTurnSecondsRemaining = speakingTurnSecondsRemaining
        self.isSpeakingTurnActive = isSpeakingTurnActive
        self.activeSpeakerId = activeSpeakerId
    }
    
    // MARK: - Filtered Participant Accessors
    public var debatersFor: [Participant] {
        participants.filter { $0.stance == .forSide && $0.role != .listener }
    }
    
    public var debatersAgainst: [Participant] {
        participants.filter { $0.stance == .againstSide && $0.role != .listener }
    }
    
    public var speakers: [Participant] {
        participants.filter { $0.role == .moderator || $0.role == .debater }
    }
    
    public var listeners: [Participant] {
        participants.filter { $0.role == .listener }
    }
    
    public var raisedHands: [Participant] {
        participants.filter { $0.hasRaisedHand }
    }
    
    // MARK: - Voting Metrics
    public var votesForCount: Int {
        votes.filter { $0.stance == .forSide }.count
    }
    
    public var votesAgainstCount: Int {
        votes.filter { $0.stance == .againstSide }.count
    }
    
    public var totalVotesCount: Int {
        votes.count
    }
    
    public var forPercentage: Double {
        guard totalVotesCount > 0 else { return 50.0 }
        return (Double(votesForCount) / Double(totalVotesCount)) * 100.0
    }
    
    public var againstPercentage: Double {
        guard totalVotesCount > 0 else { return 50.0 }
        return (Double(votesAgainstCount) / Double(totalVotesCount)) * 100.0
    }
}

// MARK: - Sample Previews
extension DebateSession {
    public static let sampleLiveSession = DebateSession(
        id: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
        topic: Topic.sampleLive,
        moderator: User.sampleModerator,
        roomName: "speak-room-01",
        status: .live,
        startedAt: Date().addingTimeInterval(-600),
        participants: [
            Participant.sampleModerator,
            Participant.sampleForDebater,
            Participant.sampleAgainstDebater,
            Participant.sampleListener
        ]
    )
}
