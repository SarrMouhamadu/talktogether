import SwiftUI

// MARK: - Live Debate Hero Card (Visually Quiet, Clubhouse-style)
public struct TopicCardView: View {
    public let topic: Topic
    public var onJoinAction: (() -> Void)?
    
    public init(topic: Topic, onJoinAction: (() -> Void)? = nil) {
        self.topic = topic
        self.onJoinAction = onJoinAction
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.space16) {
            // Subtle Top Metadata
            HStack(spacing: AppTheme.space8) {
                if topic.status == .live {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(AppTheme.liveRed)
                            .frame(width: 7, height: 7)
                        Text("Live")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.liveRed)
                    }
                    Text("·")
                        .foregroundColor(AppTheme.secondaryText)
                } else if let pos = topic.queuePosition {
                    Text("#\(pos)")
                        .font(.system(size: 13, weight: .semibold).monospacedDigit())
                        .foregroundColor(AppTheme.secondaryText)
                    Text("·")
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Text(topic.category.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText)
                
                Spacer()
                
                if let timeStr = topic.formattedScheduledTime {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 11))
                        Text(timeStr)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(AppTheme.primaryBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AppTheme.primaryBlue.opacity(0.10))
                    .clipShape(Capsule())
                }
            }
            
            // Debate Question (Main Focal Point)
            Text(topic.debateQuestion)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppTheme.primaryText)
                .lineSpacing(3)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            
            // Minimal Footer: Moderator + Primary Action
            HStack(spacing: AppTheme.space12) {
                HStack(spacing: AppTheme.space8) {
                    Circle()
                        .fill(AppTheme.neutralSubtle)
                        .frame(width: 26, height: 26)
                        .overlay(
                            Text(topic.creator.initials)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText)
                        )
                    
                    Text(topic.creator.fullName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Button(action: {
                    onJoinAction?()
                }) {
                    Text(topic.status == .live ? "Join" : "Remind")
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, AppTheme.space20)
                        .frame(height: 36)
                        .foregroundColor(topic.status == .live ? .white : AppTheme.primaryText)
                        .background(topic.status == .live ? AppTheme.primaryBlue : AppTheme.neutralSubtle)
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(AppTheme.space20)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
        )
    }
}

// MARK: - Quiet Scannable Queue Row (Apple Native List Style)
public struct QueueTopicRow: View {
    public let topic: Topic
    @State private var isReminded: Bool = false
    
    public init(topic: Topic) {
        self.topic = topic
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: AppTheme.space12) {
            // Queue Number
            Text("#\(topic.queuePosition ?? 0)")
                .font(.system(size: 14, weight: .semibold).monospacedDigit())
                .foregroundColor(AppTheme.secondaryText)
                .frame(width: 26, alignment: .leading)
            
            // Question & Minimal Meta
            VStack(alignment: .leading, spacing: 3) {
                Text(topic.debateQuestion)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 6) {
                    Text("\(topic.creator.fullName) · \(topic.category.rawValue)")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(1)
                    
                    if let timeStr = topic.shortScheduledTime {
                        Text("·")
                            .foregroundColor(AppTheme.secondaryText)
                        HStack(spacing: 3) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(timeStr)
                                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                        }
                        .foregroundColor(AppTheme.primaryBlue)
                    }
                }
            }
            
            Spacer(minLength: AppTheme.space8)
            
            // Subtle Bell Toggle
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isReminded.toggle()
                }
            }) {
                Image(systemName: isReminded ? "bell.fill" : "bell")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isReminded ? AppTheme.primaryBlue : AppTheme.secondaryText)
                    .frame(width: 36, height: 36)
                    .background(isReminded ? AppTheme.primaryBlue.opacity(0.10) : Color.clear)
                    .clipShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, AppTheme.space16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 20) {
        TopicCardView(topic: Topic.sampleLive)
        
        VStack(spacing: 0) {
            QueueTopicRow(topic: Topic.sampleNextInQueue)
            Divider().padding(.leading, 54)
            QueueTopicRow(topic: Topic.sampleQueue3)
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
    }
    .padding(20)
    .background(AppTheme.background)
}
