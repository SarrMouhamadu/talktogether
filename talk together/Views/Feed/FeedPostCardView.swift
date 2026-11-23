import SwiftUI

public struct FeedPostCardView: View {
    @Binding public var post: FeedPost
    public var currentUser: User
    public var onCommentTap: (() -> Void)?
    public var onEditTap: (() -> Void)?
    public var onDeleteTap: (() -> Void)?
    public var onLikeTap: (() -> Void)?
    public var onBookmarkTap: (() -> Void)?
    public var onReportSubmitted: ((ReportReason) -> Void)?
    
    @State private var voicePlayer = VoiceNotePlayer()
    @State private var isShowingReportSheet: Bool = false
    
    public init(
        post: Binding<FeedPost>,
        currentUser: User = User.sampleModerator,
        onCommentTap: (() -> Void)? = nil,
        onEditTap: (() -> Void)? = nil,
        onDeleteTap: (() -> Void)? = nil,
        onLikeTap: (() -> Void)? = nil,
        onBookmarkTap: (() -> Void)? = nil,
        onReportSubmitted: ((ReportReason) -> Void)? = nil
    ) {
        self._post = post
        self.currentUser = currentUser
        self.onCommentTap = onCommentTap
        self.onEditTap = onEditTap
        self.onDeleteTap = onDeleteTap
        self.onLikeTap = onLikeTap
        self.onBookmarkTap = onBookmarkTap
        self.onReportSubmitted = onReportSubmitted
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Instagram-Style Post Header
            HStack(spacing: AppTheme.space12) {
                Circle()
                    .fill(AppTheme.neutralSubtle)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Text(post.author.initials)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                    )
                
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: AppTheme.space6) {
                        Text(post.author.username)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("· \(post.createdAtText)")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    if let topicTitle = post.topicTitle {
                        Text(topicTitle)
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
                
                Spacer()
                
                if let stance = post.stance {
                    StanceBadge(stance: stance)
                }
                
                Menu {
                    if post.author.id == currentUser.id {
                        Button(action: { onEditTap?() }) {
                            Label("Edit Post", systemImage: "pencil")
                        }
                        Button(role: .destructive, action: { onDeleteTap?() }) {
                            Label("Delete Post", systemImage: "trash")
                        }
                        Divider()
                    }
                    Button(action: { toggleBookmark() }) {
                        Label(post.isBookmarked ? "Remove Bookmark" : "Save Post", systemImage: post.isBookmarked ? "bookmark.slash" : "bookmark")
                    }
                    if post.author.id != currentUser.id {
                        Button(role: .destructive, action: { isShowingReportSheet = true }) {
                            Label("Report", systemImage: "flag")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, AppTheme.space16)
            .padding(.vertical, AppTheme.space12)
            
            // 2. Main Visual Content Canvas (Photo, Quote, and/or WhatsApp Voice Note)
            VStack(alignment: .leading, spacing: AppTheme.space12) {
                // Photo Post with WhatsApp-Style Circular Upload Progress Overlay
                if let imageData = post.imageData, let uiImage = UIImage(data: imageData) {
                    ZStack {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(maxHeight: 360)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                        
                        if let progress = post.uploadProgress {
                            RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                                .fill(Color.black.opacity(0.35))
                            
                            Button(action: { onDeleteTap?() }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.55))
                                        .frame(width: 54, height: 54)
                                    
                                    Circle()
                                        .stroke(Color.white.opacity(0.28), lineWidth: 3)
                                        .frame(width: 44, height: 44)
                                    
                                    Circle()
                                        .trim(from: 0, to: CGFloat(progress))
                                        .stroke(Color.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                        .frame(width: 44, height: 44)
                                        .rotationEffect(.degrees(-90))
                                        .animation(.linear(duration: 0.08), value: progress)
                                    
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                // Quote &/or WhatsApp-Style Voice Note Canvas
                if (post.quoteText != nil && !(post.quoteText ?? "").isEmpty) || post.audioDurationSeconds != nil {
                    VStack(alignment: .leading, spacing: AppTheme.space16) {
                        if let quote = post.quoteText, !quote.isEmpty {
                            Text("\"\(quote)\"")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Interactive WhatsApp Voice Note Player (Scrub + 1x/1.5x/2x + Upload Ring)
                        if let duration = post.audioDurationSeconds {
                            WhatsAppVoicePlayerView(
                                player: voicePlayer,
                                audioURL: post.audioURL,
                                duration: duration,
                                waveformSamples: post.waveformSamples,
                                uploadProgress: post.uploadProgress,
                                onCancelUpload: onDeleteTap
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(post.quoteText == nil ? AppTheme.space12 : AppTheme.space24)
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                }
            }
            .padding(.horizontal, AppTheme.space16)
            .onTapGesture(count: 2) {
                if !post.isLiked {
                    toggleLike()
                }
            }
            
            // 3. Instagram-Style Action Bar
            HStack(spacing: AppTheme.space20) {
                Button(action: toggleLike) {
                    Image(systemName: post.isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 21, weight: .regular))
                        .foregroundColor(post.isLiked ? AppTheme.liveRed : AppTheme.primaryText)
                        .scaleEffect(post.isLiked ? 1.08 : 1.0)
                        .animation(.easeOut(duration: 0.15), value: post.isLiked)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: { onCommentTap?() }) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(AppTheme.primaryText)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {}) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(AppTheme.primaryText)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                Button(action: toggleBookmark) {
                    Image(systemName: post.isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(post.isBookmarked ? AppTheme.primaryBlue : AppTheme.primaryText)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, AppTheme.space16)
            .padding(.top, AppTheme.space12)
            .padding(.bottom, AppTheme.space8)
            
            // 4. Likes, Optional Caption & Comments Link
            VStack(alignment: .leading, spacing: 5) {
                if post.likesCount > 0 {
                    Text("\(post.likesCount) \(post.likesCount == 1 ? "like" : "likes")")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                }
                
                if let caption = post.caption, !caption.isEmpty {
                    Text("\(Text(post.author.username).font(.system(size: 14, weight: .semibold)))  \(caption)")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.primaryText)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                if !post.comments.isEmpty {
                    Button(action: { onCommentTap?() }) {
                        Text("View all \(post.comments.count) \(post.comments.count == 1 ? "comment" : "comments")")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 2)
                }
            }
            .padding(.horizontal, AppTheme.space16)
            .padding(.bottom, AppTheme.space16)
            
            // Edge-to-edge Hairline Separator
            Rectangle()
                .fill(AppTheme.separator)
                .frame(height: 1)
        }
        .background(AppTheme.surface)
        .sheet(isPresented: $isShowingReportSheet) {
            ReportContentSheet { reason in
                onReportSubmitted?(reason)
            }
        }
        .onDisappear {
            voicePlayer.stop()
        }
    }
    
    // MARK: - Actions
    private func toggleLike() {
        if let onLikeTap {
            onLikeTap()
        } else {
            post.isLiked.toggle()
            post.likesCount += post.isLiked ? 1 : -1
        }
    }
    
    private func toggleBookmark() {
        if let onBookmarkTap {
            onBookmarkTap()
        } else {
            post.isBookmarked.toggle()
        }
    }
}

#Preview {
    ScrollView {
        FeedPostCardView(post: .constant(FeedPost.samplePosts[0]))
        FeedPostCardView(post: .constant(FeedPost.samplePosts[2]))
    }
}
