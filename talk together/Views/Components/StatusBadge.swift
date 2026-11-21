import SwiftUI

// MARK: - 2026 Minimalist Status Badges
public struct StatusBadge: View {
    public let status: TopicStatus
    public var queuePosition: Int?
    
    public init(status: TopicStatus, queuePosition: Int? = nil) {
        self.status = status
        self.queuePosition = queuePosition
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            if status == .live {
                Circle()
                    .fill(AppTheme.liveRed)
                    .frame(width: 6, height: 6)
                Text("Live")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.liveRed)
            } else if let pos = queuePosition, status == .inQueue {
                Text("#\(pos) in queue")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText)
            } else {
                Text(status.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(badgeBackground)
        .clipShape(Capsule())
    }
    
    private var badgeBackground: Color {
        switch status {
        case .live:
            return AppTheme.liveRedSubtle
        case .inQueue, .scheduled, .completed, .cancelled:
            return AppTheme.neutralSubtle
        }
    }
}

// MARK: - Stance Badge (For / Against / Open)
public struct StanceBadge: View {
    public let stance: DebateStance
    
    public init(stance: DebateStance) {
        self.stance = stance
    }
    
    public var body: some View {
        Text(stance.rawValue)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .foregroundColor(textColor)
            .background(backgroundColor)
            .clipShape(Capsule())
    }
    
    private var textColor: Color {
        switch stance {
        case .forSide:
            return AppTheme.successGreen
        case .againstSide:
            return AppTheme.warningOrange
        case .neutral:
            return AppTheme.secondaryText
        }
    }
    
    private var backgroundColor: Color {
        switch stance {
        case .forSide:
            return AppTheme.successGreenSubtle
        case .againstSide:
            return AppTheme.warningOrangeSubtle
        case .neutral:
            return AppTheme.neutralSubtle
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusBadge(status: .live)
        StatusBadge(status: .inQueue, queuePosition: 2)
        StatusBadge(status: .scheduled)
        HStack {
            StanceBadge(stance: .forSide)
            StanceBadge(stance: .againstSide)
            StanceBadge(stance: .neutral)
        }
    }
    .padding()
    .background(AppTheme.background)
}
