import SwiftUI

public struct SavedPostsView: View {
    @Bindable public var debateManager: DebateManager
    
    public init(debateManager: DebateManager) {
        self.debateManager = debateManager
    }
    
    private var bookmarkedPosts: [FeedPost] {
        debateManager.feedPosts.filter { $0.isBookmarked }
    }
    
    public var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.space16) {
                if bookmarkedPosts.isEmpty {
                    VStack(spacing: AppTheme.space16) {
                        Circle()
                            .fill(AppTheme.separator.opacity(0.4))
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: "bookmark")
                                    .font(.system(size: 26))
                                    .foregroundColor(AppTheme.secondaryText)
                            )
                        
                        Text("No Saved Posts Yet")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("Tap the bookmark icon on any community post or audio note to save it here for future listening and study.")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.space32)
                    }
                    .padding(.top, 80)
                } else {
                    ForEach($debateManager.feedPosts) { $post in
                        if post.isBookmarked {
                            FeedPostCardView(
                                post: $post,
                                currentUser: debateManager.currentUser,
                                onCommentTap: {},
                                onEditTap: {},
                                onDeleteTap: {
                                    debateManager.deletePost(id: post.id)
                                },
                                onReportSubmitted: { reason in
                                    debateManager.submitReport(post: post, reason: reason)
                                }
                            )
                        }
                    }
                }
            }
            .padding(.top, AppTheme.space16)
            .padding(.bottom, AppTheme.space32)
        }
        .background(AppTheme.surface.ignoresSafeArea())
        .navigationTitle("Saved Posts")
        .navigationBarTitleDisplayMode(.inline)
    }
}
