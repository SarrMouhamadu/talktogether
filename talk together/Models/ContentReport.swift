import Foundation

public struct ContentReport: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let postID: UUID
    public let postPreview: String
    public let reportedAuthor: User
    public let reporterUsername: String
    public let reason: String
    public let reasonIconName: String
    public let createdAtText: String
    public var isResolved: Bool
    
    public init(
        id: UUID = UUID(),
        postID: UUID,
        postPreview: String,
        reportedAuthor: User,
        reporterUsername: String,
        reason: String,
        reasonIconName: String = "flag",
        createdAtText: String = "Just now",
        isResolved: Bool = false
    ) {
        self.id = id
        self.postID = postID
        self.postPreview = postPreview
        self.reportedAuthor = reportedAuthor
        self.reporterUsername = reporterUsername
        self.reason = reason
        self.reasonIconName = reasonIconName
        self.createdAtText = createdAtText
        self.isResolved = isResolved
    }
}

extension ContentReport {
    public static let sampleReports: [ContentReport] = [
        ContentReport(
            postID: UUID(),
            postPreview: "Voice note (0:34) — Reported for off-topic promotional link in caption.",
            reportedAuthor: User.sampleDebater7,
            reporterUsername: "fatou_diop",
            reason: "Spam or scam",
            reasonIconName: "megaphone",
            createdAtText: "18m ago"
        ),
        ContentReport(
            postID: UUID(),
            postPreview: "Comment in 'Social Media Impact' debate — Aggressive language.",
            reportedAuthor: User.sampleDebater2,
            reporterUsername: "aicha_ndiaye",
            reason: "Harassment or bullying",
            reasonIconName: "person.crop.circle.badge.xmark",
            createdAtText: "1h ago"
        )
    ]
}
