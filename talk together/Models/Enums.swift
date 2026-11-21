import Foundation

// MARK: - Debate Stance
public enum DebateStance: String, Codable, Sendable, CaseIterable, Identifiable {
    case forSide = "For"
    case againstSide = "Against"
    case neutral = "Open"
    
    public var id: String { rawValue }
    
    public var description: String {
        switch self {
        case .forSide:
            return "In favor of the proposition"
        case .againstSide:
            return "Opposed to the proposition"
        case .neutral:
            return "Open discussion / Neutral"
        }
    }
}

// MARK: - Participant Role
public enum ParticipantRole: String, Codable, Sendable, CaseIterable, Identifiable {
    case moderator = "Moderator"
    case debater = "Debater"
    case listener = "Listener"
    
    public var id: String { rawValue }
}

// MARK: - Topic & Session Status
public enum TopicStatus: String, Codable, Sendable, CaseIterable, Identifiable {
    case inQueue = "In Queue"
    case scheduled = "Scheduled"
    case live = "Live Now"
    case completed = "Completed"
    case cancelled = "Cancelled"
    
    public var id: String { rawValue }
    
    public var badgeColorName: String {
        switch self {
        case .inQueue: return "orange"
        case .scheduled: return "blue"
        case .live: return "green"
        case .completed: return "gray"
        case .cancelled: return "red"
        }
    }
}

// MARK: - Topic Category
public enum TopicCategory: String, Codable, Sendable, CaseIterable, Identifiable {
    case society = "Society"
    case technology = "Technology"
    case education = "Education"
    case economy = "Economy"
    case culture = "Culture"
    case philosophy = "Philosophy"
    case general = "General"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .society: return "person.3.fill"
        case .technology: return "cpu"
        case .education: return "graduationcap.fill"
        case .economy: return "chart.line.uptrend.xyaxis"
        case .culture: return "globe.americas.fill"
        case .philosophy: return "brain.head.profile"
        case .general: return "bubble.left.and.bubble.right.fill"
        }
    }
}

// MARK: - English Proficiency Level
public enum EnglishLevel: String, Codable, Sendable, CaseIterable, Identifiable {
    case beginner = "Beginner (A1-A2)"
    case intermediate = "Intermediate (B1-B2)"
    case advanced = "Advanced (C1)"
    case fluent = "Fluent / Native (C2)"
    
    public var id: String { rawValue }
}
