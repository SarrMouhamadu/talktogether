import SwiftUI

public struct TopicDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    public let topic: Topic
    public var currentUser: User?
    public var onJoinAction: (() -> Void)?
    public var onEditAction: (() -> Void)?
    public var onDeleteAction: (() -> Void)?
    
    @State private var isReminderSet: Bool = false
    @State private var isShowingDeleteAlert: Bool = false
    
    public init(
        topic: Topic,
        currentUser: User? = nil,
        onJoinAction: (() -> Void)? = nil,
        onEditAction: (() -> Void)? = nil,
        onDeleteAction: (() -> Void)? = nil
    ) {
        self.topic = topic
        self.currentUser = currentUser
        self.onJoinAction = onJoinAction
        self.onEditAction = onEditAction
        self.onDeleteAction = onDeleteAction
    }
    
    private var isCreator: Bool {
        guard let currentUser else { return false }
        return topic.creator.id == currentUser.id
    }
    
    public var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppTheme.space24) {
                // Status & Category
                HStack(spacing: AppTheme.space8) {
                    StatusBadge(status: topic.status, queuePosition: topic.queuePosition)
                    
                    Text("·")
                        .foregroundColor(AppTheme.secondaryText)
                    
                    Label(topic.category.rawValue, systemImage: topic.category.iconName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                // Main Question
                Text(topic.debateQuestion)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Context (Progressive disclosure)
                if let desc = topic.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.secondaryText)
                        .lineSpacing(3)
                }
                
                Divider()
                    .background(AppTheme.separator)
                
                // Moderator Info
                HStack(spacing: AppTheme.space12) {
                    Circle()
                        .fill(AppTheme.neutralSubtle)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(topic.creator.initials)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(topic.creator.fullName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                        Text("Session Moderator · \(topic.creator.country)")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                // Primary Action
                if topic.status == .live {
                    Button(action: {
                        dismiss()
                        onJoinAction?()
                    }) {
                        HStack(spacing: AppTheme.space8) {
                            Image(systemName: "waveform")
                            Text("Join Debate")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppTheme.primaryBlue)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusButton, style: .continuous))
                    }
                } else {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isReminderSet.toggle()
                        }
                    }) {
                        HStack(spacing: AppTheme.space8) {
                            Image(systemName: isReminderSet ? "bell.fill" : "bell")
                            Text(isReminderSet ? "Reminder Set" : "Remind Me When Live")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isReminderSet ? AppTheme.primaryBlue : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(isReminderSet ? AppTheme.primaryBlue.opacity(0.12) : AppTheme.primaryBlue)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusButton, style: .continuous))
                    }
                }
            }
            .padding(AppTheme.space24)
            .background(AppTheme.surface.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.secondaryText)
                }
                
                if isCreator && (onEditAction != nil || onDeleteAction != nil) {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            if let onEditAction {
                                Button(action: {
                                    dismiss()
                                    onEditAction()
                                }) {
                                    Label("Edit Topic", systemImage: "pencil")
                                }
                            }
                            if onDeleteAction != nil {
                                Button(role: .destructive, action: {
                                    isShowingDeleteAlert = true
                                }) {
                                    Label("Delete Topic", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.primaryText)
                        }
                    }
                }
            }
            .alert("Delete Topic?", isPresented: $isShowingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    dismiss()
                    onDeleteAction?()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This topic will be removed from the queue.")
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    TopicDetailSheet(topic: Topic.sampleNextInQueue, currentUser: User.sampleDebater1)
}
