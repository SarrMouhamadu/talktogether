import SwiftUI

public struct ParticipantAvatarView: View {
    public let participant: Participant
    public var size: CGFloat = 56
    public var showDetails: Bool = true
    
    @State private var isPulsing: Bool = false
    
    public init(participant: Participant, size: CGFloat = 56, showDetails: Bool = true) {
        self.participant = participant
        self.size = size
        self.showDetails = showDetails
    }
    
    public var body: some View {
        VStack(spacing: AppTheme.space6) {
            ZStack {
                // Speaking ripple animation
                if participant.isSpeaking {
                    Circle()
                        .stroke(ringColor.opacity(0.4), lineWidth: 2)
                        .frame(width: size + 12, height: size + 12)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                        .opacity(isPulsing ? 0 : 0.7)
                        .animation(
                            .easeOut(duration: 1.0).repeatForever(autoreverses: false),
                            value: isPulsing
                        )
                }
                
                // Avatar background circle
                Circle()
                    .fill(AppTheme.surface)
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .stroke(ringColor, lineWidth: participant.isSpeaking ? 2.5 : 1)
                    )
                    .overlay(
                        Text(participant.user.initials)
                            .font(.system(size: size * 0.36, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                    )
                
                // Moderator Badge
                if participant.role == .moderator {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(3.5)
                        .background(AppTheme.primaryBlue)
                        .clipShape(Circle())
                        .offset(x: size * 0.34, y: -size * 0.34)
                }
                
                // Muted Microphone Indicator
                if participant.isMuted {
                    Image(systemName: "mic.slash.fill")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(3.5)
                        .background(AppTheme.secondaryText)
                        .clipShape(Circle())
                        .offset(x: size * 0.34, y: size * 0.34)
                }
                
                // Raised Hand Indicator (SF Symbol, NO EMOJI)
                if participant.hasRaisedHand {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(3.5)
                        .background(AppTheme.warningOrange)
                        .clipShape(Circle())
                        .offset(x: -size * 0.34, y: -size * 0.34)
                }
            }
            .onAppear {
                if participant.isSpeaking {
                    isPulsing = true
                }
            }
            .onChange(of: participant.isSpeaking) { _, speaking in
                isPulsing = speaking
            }
            
            if showDetails {
                VStack(spacing: 1) {
                    Text(participant.user.fullName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.primaryText)
                        .lineLimit(1)
                        .frame(maxWidth: size + 16)
                    
                    if participant.role == .moderator {
                        Text("Moderator")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.primaryBlue)
                    }
                }
            }
        }
    }
    
    private var ringColor: Color {
        switch participant.stance {
        case .forSide:
            return AppTheme.successGreen
        case .againstSide:
            return AppTheme.warningOrange
        case .neutral:
            return participant.role == .moderator ? AppTheme.primaryBlue : AppTheme.separator
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        ParticipantAvatarView(participant: Participant.sampleModerator)
        ParticipantAvatarView(participant: Participant.sampleForDebater)
        ParticipantAvatarView(participant: Participant.sampleAgainstDebater)
        ParticipantAvatarView(participant: Participant.sampleListener)
    }
    .padding()
    .background(AppTheme.background)
}
