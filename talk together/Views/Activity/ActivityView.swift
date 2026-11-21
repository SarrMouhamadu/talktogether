import SwiftUI

public struct ActivityItem: Identifiable, Sendable {
    public let id: UUID
    public let iconName: String
    public let title: String
    public let description: String
    public let timestamp: String
    public let isUnread: Bool
    
    public init(
        id: UUID = UUID(),
        iconName: String,
        title: String,
        description: String,
        timestamp: String,
        isUnread: Bool = false
    ) {
        self.id = id
        self.iconName = iconName
        self.title = title
        self.description = description
        self.timestamp = timestamp
        self.isUnread = isUnread
    }
}

public struct ActivityView: View {
    @State private var notifications: [ActivityItem] = [
        ActivityItem(
            iconName: "waveform",
            title: "Debate Live Now",
            description: "'Social Media Impact' has started.",
            timestamp: "5m",
            isUnread: true
        ),
        ActivityItem(
            iconName: "list.number",
            title: "Queue Update",
            description: "'AI and Job Security' is next in line.",
            timestamp: "35m",
            isUnread: false
        ),
        ActivityItem(
            iconName: "checkmark.circle",
            title: "Topic Scheduled",
            description: "'Should university education be free?' is in queue.",
            timestamp: "2h",
            isUnread: false
        )
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Group {
                if notifications.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(notifications.enumerated()), id: \.element.id) { index, item in
                                notificationRow(item)
                                
                                if index < notifications.count - 1 {
                                    Rectangle()
                                        .fill(AppTheme.separator)
                                        .frame(height: 1)
                                        .padding(.leading, 56)
                                }
                            }
                        }
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                                .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                        )
                        .padding(.horizontal, AppTheme.space20)
                        .padding(.top, AppTheme.space16)
                    }
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Quiet Notification Row (Apple Mail Style)
    private func notificationRow(_ item: ActivityItem) -> some View {
        HStack(alignment: .center, spacing: AppTheme.space12) {
            ZStack(alignment: .topLeading) {
                Image(systemName: item.iconName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(item.isUnread ? AppTheme.primaryBlue : AppTheme.secondaryText)
                    .frame(width: 32, height: 32)
                    .background(item.isUnread ? AppTheme.primaryBlue.opacity(0.10) : AppTheme.neutralSubtle)
                    .clipShape(Circle())
                
                if item.isUnread {
                    Circle()
                        .fill(AppTheme.primaryBlue)
                        .frame(width: 7, height: 7)
                        .offset(x: -2, y: -1)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                    
                    Spacer()
                    
                    Text(item.timestamp)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.secondaryText)
                }
                
                Text(item.description)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, AppTheme.space16)
        .padding(.vertical, 14)
    }
    
    // MARK: - Quiet Empty State
    private var emptyState: some View {
        VStack(spacing: AppTheme.space12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(AppTheme.secondaryText)
            
            Text("No Activity")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.primaryText)
            
            Text("Queue updates and live alerts will appear here.")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ActivityView()
}
