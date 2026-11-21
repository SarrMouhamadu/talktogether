import SwiftUI

public struct HomeView: View {
    @Bindable public var debateManager: DebateManager
    public var onSelectTopic: ((Topic) -> Void)?
    public var onCreateTopic: (() -> Void)?
    
    @State private var isShowingLeaderboard: Bool = false
    @State private var isShowingCreatePost: Bool = false
    @State private var editingPost: FeedPost? = nil
    @State private var postPendingDelete: FeedPost? = nil
    @State private var inspectedTopic: Topic? = nil
    @State private var editingTopic: Topic? = nil
    @State private var activeCommentPostID: UUID? = nil
    
    public init(
        debateManager: DebateManager,
        onSelectTopic: ((Topic) -> Void)? = nil,
        onCreateTopic: (() -> Void)? = nil
    ) {
        self.debateManager = debateManager
        self.onSelectTopic = onSelectTopic
        self.onCreateTopic = onCreateTopic
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // 1. Instagram Stories-Style Live & Queue Strip
                    debateStoriesStrip
                    
                    // 2. Daily Speaking Prompt Card
                    dailyPromptCard
                    
                    Rectangle()
                        .fill(AppTheme.separator)
                        .frame(height: 1)
                    
                    // 3. Instagram-Style Vertical Community Feed
                    if debateManager.feedPosts.isEmpty {
                        VStack(spacing: AppTheme.space16) {
                            Circle()
                                .fill(AppTheme.separator.opacity(0.4))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.system(size: 22))
                                        .foregroundColor(AppTheme.secondaryText)
                                )
                            Text("No Community Posts Yet")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText)
                            Text("Be the first to share an audio note or start a discussion with the + button above.")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppTheme.space32)
                        }
                        .padding(.top, 48)
                        .padding(.bottom, 48)
                    } else {
                        ForEach($debateManager.feedPosts) { $post in
                            FeedPostCardView(
                                post: $post,
                                currentUser: debateManager.currentUser,
                                onCommentTap: {
                                    activeCommentPostID = post.id
                                },
                                onEditTap: {
                                    editingPost = post
                                },
                                onDeleteTap: {
                                    postPendingDelete = post
                                },
                                onReportSubmitted: { reason in
                                    debateManager.submitReport(post: post, reason: reason)
                                }
                            )
                        }
                    }
                }
                .padding(.bottom, AppTheme.space24)
            }
            .background(AppTheme.surface.ignoresSafeArea())
            .navigationTitle("WaxUp")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    // Daily Speaking Streak Counter
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.warningOrange)
                        
                        Text("\(debateManager.currentUser.dailyStreak)")
                            .font(.system(size: 13, weight: .bold).monospacedDigit())
                            .foregroundColor(AppTheme.primaryText)
                    }
                    .padding(.horizontal, 9)
                    .frame(height: 28)
                    .background(AppTheme.warningOrange.opacity(0.12))
                    .clipShape(Capsule())
                    .accessibilityLabel("\(debateManager.currentUser.dailyStreak) day speaking streak")
                }
                
                ToolbarItemGroup(placement: .primaryAction) {
                    Button(action: { isShowingCreatePost = true }) {
                        Image(systemName: "plus.app")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppTheme.primaryText)
                    }
                    .accessibilityLabel("Create Post")
                    
                    Button(action: { isShowingLeaderboard = true }) {
                        Image(systemName: "trophy")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.primaryText)
                    }
                    .accessibilityLabel("Leaderboard")
                }
            }
            .sheet(isPresented: $isShowingCreatePost) {
                CreateFeedPostView(
                    currentUser: debateManager.currentUser,
                    availableTopics: debateManager.topicsQueue
                ) { newPost in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        debateManager.addPost(newPost)
                    }
                }
            }
            .sheet(item: $editingPost) { postToEdit in
                CreateFeedPostView(
                    currentUser: debateManager.currentUser,
                    availableTopics: debateManager.topicsQueue,
                    editingPost: postToEdit
                ) { updatedPost in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        debateManager.updatePost(updatedPost)
                    }
                }
            }
            .alert(
                "Delete Post?",
                isPresented: Binding(
                    get: { postPendingDelete != nil },
                    set: { if !$0 { postPendingDelete = nil } }
                ),
                presenting: postPendingDelete
            ) { post in
                Button("Delete", role: .destructive) {
                    withAnimation {
                        debateManager.deletePost(id: post.id)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("This post will be permanently removed from the feed.")
            }
            .sheet(isPresented: $isShowingLeaderboard) {
                LeaderboardView(allUsers: debateManager.allUsers, currentUser: debateManager.currentUser)
            }
            .sheet(item: $inspectedTopic) { topic in
                TopicDetailSheet(
                    topic: topic,
                    currentUser: debateManager.currentUser,
                    onJoinAction: {
                        onSelectTopic?(topic)
                    },
                    onEditAction: {
                        editingTopic = topic
                    },
                    onDeleteAction: {
                        withAnimation {
                            debateManager.deleteTopic(id: topic.id)
                        }
                    }
                )
            }
            .sheet(item: $editingTopic) { topicToEdit in
                CreateTopicView(editingTopic: topicToEdit) { updatedTopic in
                    debateManager.updateTopic(updatedTopic)
                }
            }
            .sheet(isPresented: Binding(
                get: { activeCommentPostID != nil },
                set: { if !$0 { activeCommentPostID = nil } }
            )) {
                if let id = activeCommentPostID,
                   let index = debateManager.feedPosts.firstIndex(where: { $0.id == id }) {
                    PostCommentsSheet(post: $debateManager.feedPosts[index], currentUser: debateManager.currentUser)
                }
            }
        }
    }
    
    // MARK: - Instagram Stories-Style Live & Upcoming Debates Strip
    private var debateStoriesStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.space16) {
                // "New Debate" shortcut
                Button(action: { onCreateTopic?() }) {
                    VStack(spacing: AppTheme.space6) {
                        Circle()
                            .strokeBorder(AppTheme.separator, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                            .frame(width: 66, height: 66)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryBlue)
                            )
                        
                        Text("New Topic")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.primaryText)
                            .lineLimit(1)
                            .frame(width: 72)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                ForEach(debateManager.topicsQueue) { topic in
                    let isLive = topic.status == .live
                    
                    Button(action: {
                        if isLive {
                            onSelectTopic?(topic)
                        } else {
                            inspectedTopic = topic
                        }
                    }) {
                        VStack(spacing: AppTheme.space6) {
                            ZStack(alignment: .bottom) {
                                Circle()
                                    .stroke(
                                        isLive ? AppTheme.liveRed : AppTheme.separator,
                                        lineWidth: isLive ? 2.5 : 1.5
                                    )
                                    .frame(width: 66, height: 66)
                                    .overlay(
                                        Circle()
                                            .fill(AppTheme.background)
                                            .frame(width: 58, height: 58)
                                            .overlay(
                                                Text(topic.creator.initials)
                                                    .font(.system(size: 17, weight: .semibold))
                                                    .foregroundColor(AppTheme.primaryText)
                                            )
                                    )
                                
                                if isLive {
                                    Text("LIVE")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AppTheme.liveRed)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(AppTheme.surface, lineWidth: 2)
                                        )
                                        .offset(y: 4)
                                } else if let pos = topic.queuePosition {
                                    Text("#\(pos)")
                                        .font(.system(size: 9, weight: .bold).monospacedDigit())
                                        .foregroundColor(AppTheme.primaryText)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(AppTheme.surface)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(AppTheme.separator, lineWidth: 1)
                                        )
                                        .offset(y: 4)
                                }
                            }
                            
                            Text(topic.title)
                                .font(.system(size: 11, weight: isLive ? .semibold : .regular))
                                .foregroundColor(isLive ? AppTheme.primaryText : AppTheme.secondaryText)
                                .lineLimit(1)
                                .frame(width: 72)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, AppTheme.space16)
            .padding(.vertical, AppTheme.space12)
        }
        .background(AppTheme.surface)
    }
    
    // MARK: - Daily Speaking Challenge Prompt Card
    private var dailyPromptCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.space12) {
            HStack(spacing: AppTheme.space8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.primaryBlue)
                
                Text("DAILY SPEAKING CHALLENGE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.primaryBlue)
                
                Spacer()
                
                Text("30s Voice")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Text(debateManager.dailyPrompt)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.primaryText)
                .lineSpacing(2)
            
            Button {
                isShowingCreatePost = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("Record Voice Response")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(AppTheme.primaryBlue)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(AppTheme.space16)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                .stroke(AppTheme.primaryBlue.opacity(0.18), lineWidth: 1)
        )
        .padding(.horizontal, AppTheme.space16)
        .padding(.vertical, AppTheme.space12)
    }
}

#Preview {
    HomeView(debateManager: DebateManager())
}
