import Foundation

// MARK: - Post Comment
public struct PostComment: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let author: User
    public let text: String
    public let createdAtText: String
    
    public init(
        id: UUID = UUID(),
        author: User,
        text: String,
        createdAtText: String = "Just now"
    ) {
        self.id = id
        self.author = author
        self.text = text
        self.createdAtText = createdAtText
    }
}

// MARK: - Feed Post (Instagram-inspired Community Post: Text, Voice, and/or Photo — No Video)
public struct FeedPost: Identifiable, Codable, Sendable, Hashable {
    public let id: UUID
    public let author: User
    public var topicTitle: String?
    public var stance: DebateStance?
    public var quoteText: String?
    public var caption: String?
    public var imageData: Data?
    public var audioURL: URL?
    public var audioDurationSeconds: Int?
    public var waveformSamples: [Float]
    public var uploadProgress: Double? // nil = uploaded, 0.0...1.0 = WhatsApp-style uploading ring
    public var likesCount: Int
    public var isLiked: Bool
    public var isBookmarked: Bool
    public var comments: [PostComment]
    public let createdAtText: String
    
    public init(
        id: UUID = UUID(),
        author: User,
        topicTitle: String? = nil,
        stance: DebateStance? = nil,
        quoteText: String? = nil,
        caption: String? = nil,
        imageData: Data? = nil,
        audioURL: URL? = nil,
        audioDurationSeconds: Int? = nil,
        waveformSamples: [Float] = [],
        uploadProgress: Double? = nil,
        likesCount: Int = 0,
        isLiked: Bool = false,
        isBookmarked: Bool = false,
        comments: [PostComment] = [],
        createdAtText: String = "10m"
    ) {
        self.id = id
        self.author = author
        self.topicTitle = topicTitle
        self.stance = stance
        self.quoteText = quoteText
        self.caption = caption
        self.imageData = imageData
        self.audioURL = audioURL
        self.audioDurationSeconds = audioDurationSeconds
        self.waveformSamples = waveformSamples
        self.uploadProgress = uploadProgress
        self.likesCount = likesCount
        self.isLiked = isLiked
        self.isBookmarked = isBookmarked
        self.comments = comments
        self.createdAtText = createdAtText
    }
}

// MARK: - Sample Posts
extension FeedPost {
    public static let samplePosts: [FeedPost] = [
        FeedPost(
            author: User.sampleDebater1,
            topicTitle: "Social Media Impact",
            stance: .againstSide,
            quoteText: "Social media connects us globally, yet it quietly erodes deep face-to-face conversations.",
            caption: "My key argument from today's live session. Listen to the 45-second voice recap and tell me if you agree.",
            audioDurationSeconds: 45,
            likesCount: 48,
            isLiked: false,
            isBookmarked: false,
            comments: [
                PostComment(author: User.sampleModerator, text: "Great point Fatou! Your pronunciation was super clear today.", createdAtText: "8m"),
                PostComment(author: User.sampleDebater3, text: "I partly agree, though it helped me find English practice groups.", createdAtText: "4m")
            ],
            createdAtText: "14m"
        ),
        FeedPost(
            author: User.sampleDebater3,
            topicTitle: "AI and Job Security",
            stance: .forSide,
            quoteText: "AI won't replace creative professionals — professionals who use AI will replace those who don't.",
            caption: "Preparing my opening statement for the next debate in the FIFO queue. Who is joining the Against side?",
            audioDurationSeconds: nil,
            likesCount: 73,
            isLiked: true,
            isBookmarked: true,
            comments: [
                PostComment(author: User.sampleDebater2, text: "Count me in for the Against side! See you in the room.", createdAtText: "25m")
            ],
            createdAtText: "1h"
        ),
        FeedPost(
            author: User.sampleDebater4,
            topicTitle: "Free Higher Education",
            stance: .forSide,
            quoteText: nil,
            caption: nil,
            audioDurationSeconds: 62,
            likesCount: 31,
            isLiked: false,
            isBookmarked: false,
            comments: [
                PostComment(author: User.sampleDebater1, text: "Strong opening hook! Very natural pacing.", createdAtText: "1h")
            ],
            createdAtText: "3h"
        )
    ]
}
