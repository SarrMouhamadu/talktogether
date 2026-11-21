import SwiftUI

public struct PostCommentsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding public var post: FeedPost
    public let currentUser: User
    
    @State private var newCommentText: String = ""
    
    public init(post: Binding<FeedPost>, currentUser: User) {
        self._post = post
        self.currentUser = currentUser
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if post.comments.isEmpty {
                    VStack(spacing: AppTheme.space8) {
                        Spacer()
                        Image(systemName: "bubble.right")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(AppTheme.secondaryText)
                        Text("No comments yet")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                        Text("Start the conversation in English.")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.secondaryText)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: AppTheme.space16) {
                            ForEach(post.comments) { comment in
                                HStack(alignment: .top, spacing: AppTheme.space12) {
                                    Circle()
                                        .fill(AppTheme.neutralSubtle)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text(comment.author.initials)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(AppTheme.primaryText)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack(spacing: AppTheme.space6) {
                                            Text(comment.author.username)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(AppTheme.primaryText)
                                            Text(comment.createdAtText)
                                                .font(.system(size: 12))
                                                .foregroundColor(AppTheme.secondaryText)
                                        }
                                        
                                        Text(comment.text)
                                            .font(.system(size: 14))
                                            .foregroundColor(AppTheme.primaryText)
                                            .lineSpacing(2)
                                    }
                                    
                                    Spacer()
                                    
                                    if comment.author.id == currentUser.id {
                                        Button(role: .destructive, action: {
                                            withAnimation {
                                                post.comments.removeAll { $0.id == comment.id }
                                            }
                                        }) {
                                            Image(systemName: "trash")
                                                .font(.system(size: 13))
                                                .foregroundColor(AppTheme.secondaryText)
                                                .frame(width: 28, height: 28)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding(AppTheme.space20)
                    }
                }
                
                // Divider + Comment Input Bar
                Rectangle()
                    .fill(AppTheme.separator)
                    .frame(height: 1)
                
                HStack(spacing: AppTheme.space12) {
                    Circle()
                        .fill(AppTheme.primaryBlue.opacity(0.10))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(currentUser.initials)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppTheme.primaryBlue)
                        )
                    
                    TextField("Add a comment in English...", text: $newCommentText)
                        .font(.system(size: 15))
                        .padding(.horizontal, AppTheme.space12)
                        .frame(height: 38)
                        .background(AppTheme.background)
                        .clipShape(Capsule())
                    
                    Button(action: sendComment) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(canSend ? AppTheme.primaryBlue : AppTheme.separator)
                    }
                    .disabled(!canSend)
                }
                .padding(.horizontal, AppTheme.space16)
                .padding(.vertical, AppTheme.space12)
                .background(AppTheme.surface)
            }
            .background(AppTheme.surface.ignoresSafeArea())
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var canSend: Bool {
        !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func sendComment() {
        let trimmed = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let comment = PostComment(author: currentUser, text: trimmed, createdAtText: "Now")
        post.comments.append(comment)
        newCommentText = ""
    }
}

#Preview {
    PostCommentsSheet(post: .constant(FeedPost.samplePosts[0]), currentUser: User.sampleModerator)
}
