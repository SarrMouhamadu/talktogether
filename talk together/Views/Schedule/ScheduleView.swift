import SwiftUI

public struct ScheduleView: View {
    @Bindable public var debateManager: DebateManager
    public var onSelectTopic: ((Topic) -> Void)?
    
    @State private var inspectedTopic: Topic? = nil
    @State private var editingTopic: Topic? = nil
    
    public init(
        debateManager: DebateManager,
        onSelectTopic: ((Topic) -> Void)? = nil
    ) {
        self.debateManager = debateManager
        self.onSelectTopic = onSelectTopic
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.space32) {
                    // Active Session
                    let liveTopics = debateManager.topicsQueue.filter { $0.status == .live }
                    if !liveTopics.isEmpty {
                        VStack(alignment: .leading, spacing: AppTheme.space12) {
                            Text("Now")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText)
                                .padding(.horizontal, AppTheme.space4)
                            
                            ForEach(liveTopics) { topic in
                                TopicCardView(topic: topic) {
                                    onSelectTopic?(topic)
                                }
                            }
                        }
                    }
                    
                    // FIFO Queue
                    VStack(alignment: .leading, spacing: AppTheme.space12) {
                        HStack {
                            Text("Queue")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText)
                            Spacer()
                            Text("\(debateManager.topicsQueue.filter { $0.status != .live }.count) upcoming")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .padding(.horizontal, AppTheme.space4)
                        
                        let queuedTopics = debateManager.topicsQueue.filter { $0.status != .live }
                        if queuedTopics.isEmpty {
                            VStack(spacing: AppTheme.space8) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 28, weight: .light))
                                    .foregroundColor(AppTheme.secondaryText)
                                Text("No upcoming debates")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AppTheme.space40)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(queuedTopics.enumerated()), id: \.element.id) { index, topic in
                                    Button(action: {
                                        inspectedTopic = topic
                                    }) {
                                        QueueTopicRow(topic: topic)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if index < queuedTopics.count - 1 {
                                        Rectangle()
                                            .fill(AppTheme.separator)
                                            .frame(height: 1)
                                            .padding(.leading, 54)
                                    }
                                }
                            }
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                                    .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, AppTheme.space20)
                .padding(.top, AppTheme.space16)
                .padding(.bottom, AppTheme.space32)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.large)
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
        }
    }
}

#Preview {
    ScheduleView(debateManager: DebateManager())
}
