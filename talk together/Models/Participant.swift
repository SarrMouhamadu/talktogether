import Foundation

// MARK: - Participant Model
public struct Participant: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public var user: User
    public var role: ParticipantRole
    public var stance: DebateStance
    public var isMuted: Bool
    public var isSpeaking: Bool
    public var hasRaisedHand: Bool
    public var joinedAt: Date
    
    public init(
        id: UUID = UUID(),
        user: User,
        role: ParticipantRole = .listener,
        stance: DebateStance = .neutral,
        isMuted: Bool = true,
        isSpeaking: Bool = false,
        hasRaisedHand: Bool = false,
        joinedAt: Date = Date()
    ) {
        self.id = id
        self.user = user
        self.role = role
        self.stance = stance
        self.isMuted = isMuted
        self.isSpeaking = isSpeaking
        self.hasRaisedHand = hasRaisedHand
        self.joinedAt = joinedAt
    }
}

// MARK: - Sample Previews
extension Participant {
    public static let sampleModerator = Participant(
        user: User.sampleModerator,
        role: .moderator,
        stance: .neutral,
        isMuted: false,
        isSpeaking: true
    )
    
    public static let sampleForDebater = Participant(
        user: User.sampleDebater1,
        role: .debater,
        stance: .forSide,
        isMuted: false,
        isSpeaking: false
    )
    
    public static let sampleAgainstDebater = Participant(
        user: User.sampleDebater2,
        role: .debater,
        stance: .againstSide,
        isMuted: true,
        isSpeaking: false
    )
    
    public static let sampleListener = Participant(
        user: User.sampleDebater3,
        role: .listener,
        stance: .neutral,
        isMuted: true,
        isSpeaking: false,
        hasRaisedHand: true
    )
}
