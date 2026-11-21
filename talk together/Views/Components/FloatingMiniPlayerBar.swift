import SwiftUI

public struct FloatingMiniPlayerBar: View {
    @Bindable public var debateManager: DebateManager
    public var onExpand: () -> Void
    
    public init(debateManager: DebateManager, onExpand: @escaping () -> Void) {
        self.debateManager = debateManager
        self.onExpand = onExpand
    }
    
    private var session: DebateSession? {
        debateManager.currentSession
    }
    
    public var body: some View {
        if let session = session {
            Button(action: onExpand) {
                HStack(spacing: AppTheme.space12) {
                    // Pulsing Live Indicator
                    Circle()
                        .fill(AppTheme.liveRed)
                        .frame(width: 8, height: 8)
                    
                    // Debate Question snippet
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.topic.debateQuestion)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppTheme.primaryText)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            Text("\(session.participants.count) listening")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.secondaryText)
                            
                            if session.isSpeakingTurnActive {
                                Text("· \(session.speakingTurnSecondsRemaining)s turn")
                                    .font(.system(size: 11, weight: .medium).monospacedDigit())
                                    .foregroundColor(AppTheme.primaryBlue)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Quick Mute / Unmute Button
                    Button {
                        debateManager.toggleMicrophone()
                    } label: {
                        Image(systemName: debateManager.audioService.isMuted ? "mic.slash.fill" : "mic.fill")
                            .font(.system(size: 14))
                            .foregroundColor(debateManager.audioService.isMuted ? AppTheme.secondaryText : AppTheme.primaryBlue)
                            .frame(width: 32, height: 32)
                            .background(AppTheme.surface)
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Leave room button
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            debateManager.leaveSession()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.secondaryText)
                            .frame(width: 28, height: 28)
                            .background(AppTheme.separator.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, AppTheme.space16)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.surface)
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.separator, lineWidth: 1)
                )
                .padding(.horizontal, AppTheme.space12)
            }
            .buttonStyle(PlainButtonStyle())
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
