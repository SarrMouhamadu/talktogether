import SwiftUI

public struct LiveDebateRoomView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable public var debateManager: DebateManager
    
    @State private var isShowingTopicInfo: Bool = false
    @State private var isShowingVotingSheet: Bool = false
    
    public init(debateManager: DebateManager) {
        self.debateManager = debateManager
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Ultra-Quiet Top Bar (FaceTime-style)
                roomHeader
                
                // Open Stage Canvas (Clubhouse-style)
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppTheme.space32) {
                        if let session = debateManager.currentSession {
                            // Topic Title Directly on Canvas
                            VStack(alignment: .leading, spacing: AppTheme.space8) {
                                Text(session.topic.debateQuestion)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryText)
                                    .lineSpacing(3)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Text("\(session.participants.count) in room · \(session.topic.category.rawValue)")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(.horizontal, AppTheme.space24)
                            
                            // Moderator
                            HStack {
                                Spacer()
                                ParticipantAvatarView(
                                    participant: session.participants.first(where: { $0.role == .moderator }) ?? Participant.sampleModerator,
                                    size: 64
                                )
                                Spacer()
                            }
                            
                            // Speaking Turn Timer Widget
                            speakingTurnWidget(session: session)
                            
                            // Open For vs Against Stage (No heavy boxes)
                            HStack(alignment: .top, spacing: AppTheme.space20) {
                                // FOR Column
                                VStack(spacing: AppTheme.space16) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(AppTheme.successGreen)
                                            .frame(width: 6, height: 6)
                                        Text("For")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(AppTheme.secondaryText)
                                    }
                                    
                                    if session.debatersFor.isEmpty {
                                        emptySideSlot(stance: .forSide)
                                    } else {
                                        VStack(spacing: AppTheme.space16) {
                                            ForEach(session.debatersFor) { debater in
                                                ParticipantAvatarView(participant: debater, size: 56)
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                
                                // Hairline Vertical Divider
                                Rectangle()
                                    .fill(AppTheme.separator)
                                    .frame(width: 1)
                                    .frame(minHeight: 90)
                                    .padding(.top, AppTheme.space24)
                                
                                // AGAINST Column
                                VStack(spacing: AppTheme.space16) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(AppTheme.warningOrange)
                                            .frame(width: 6, height: 6)
                                        Text("Against")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(AppTheme.secondaryText)
                                    }
                                    
                                    if session.debatersAgainst.isEmpty {
                                        emptySideSlot(stance: .againstSide)
                                    } else {
                                        VStack(spacing: AppTheme.space16) {
                                            ForEach(session.debatersAgainst) { debater in
                                                ParticipantAvatarView(participant: debater, size: 56)
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal, AppTheme.space24)
                            
                            // Listeners (Quiet Audience Grid)
                            if !session.listeners.isEmpty {
                                VStack(alignment: .leading, spacing: AppTheme.space16) {
                                    Text("Listening")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppTheme.secondaryText)
                                        .padding(.horizontal, AppTheme.space24)
                                    
                                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: AppTheme.space16) {
                                        ForEach(session.listeners) { listener in
                                            ParticipantAvatarView(participant: listener, size: 44, showDetails: true)
                                        }
                                    }
                                    .padding(.horizontal, AppTheme.space24)
                                }
                                .padding(.top, AppTheme.space8)
                            }
                        }
                    }
                    .padding(.vertical, AppTheme.space20)
                }
                
                // Single-Row FaceTime-Style Control Dock
                faceTimeControlDock
            }
            .background(AppTheme.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isShowingTopicInfo) {
                if let topic = debateManager.currentSession?.topic {
                    TopicDetailSheet(topic: topic)
                }
            }
            .sheet(isPresented: $isShowingVotingSheet) {
                DebateVotingSheet(debateManager: debateManager)
            }
        }
    }
    
    // MARK: - Quiet Header
    private var roomHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(AppTheme.liveRed)
                    .frame(width: 7, height: 7)
                Text(formattedTime(debateManager.sessionDuration))
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                    .foregroundColor(AppTheme.secondaryText)
            }
            
            Spacer()
            
            HStack(spacing: AppTheme.space12) {
                // Live Voting Action
                Button(action: { isShowingVotingSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 13, weight: .semibold))
                        if let session = debateManager.currentSession, session.totalVotesCount > 0 {
                            Text("\(Int(session.forPercentage))% For")
                                .font(.system(size: 11, weight: .bold).monospacedDigit())
                        } else {
                            Text("Vote")
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .foregroundColor(AppTheme.primaryBlue)
                    .padding(.horizontal, 10)
                    .frame(height: 30)
                    .background(AppTheme.primaryBlue.opacity(0.10))
                    .clipShape(Capsule())
                }
                
                Button(action: { isShowingTopicInfo = true }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(AppTheme.secondaryText)
                        .frame(width: 36, height: 36)
                }
                
                // Minimize to background mini-player
                Button(action: {
                    debateManager.isMiniPlayerActive = true
                    dismiss()
                }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                        .frame(width: 34, height: 34)
                        .background(AppTheme.surface)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, AppTheme.space20)
        .padding(.top, AppTheme.space12)
        .padding(.bottom, AppTheme.space8)
    }
    
    // MARK: - Minimal Empty Slot
    private func emptySideSlot(stance: DebateStance) -> some View {
        Button(action: {
            debateManager.switchStance(to: stance)
        }) {
            VStack(spacing: AppTheme.space6) {
                Circle()
                    .strokeBorder(AppTheme.separator, style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.secondaryText)
                    )
                
                Text("Join \(stance.rawValue)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - FaceTime-Style Single-Row Control Dock
    private var faceTimeControlDock: some View {
        HStack(spacing: AppTheme.space20) {
            // 1. Stance / Role Switcher Menu (Collapses 3 buttons into 1)
            Menu {
                Button(action: { debateManager.switchStance(to: .forSide) }) {
                    Label("Speak For", systemImage: "hand.thumbsup")
                }
                Button(action: { debateManager.switchStance(to: .againstSide) }) {
                    Label("Speak Against", systemImage: "hand.thumbsdown")
                }
                Divider()
                Button(action: { debateManager.switchToListener() }) {
                    Label("Listen Only", systemImage: "headphones")
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: currentRoleIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(currentRoleTint)
                        .frame(width: 52, height: 52)
                        .background(AppTheme.surface)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(AppTheme.separator, lineWidth: 1)
                        )
                    
                    Text(currentRoleLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            
            // 2. Raise Hand
            Button(action: { debateManager.toggleHandRaise() }) {
                VStack(spacing: 4) {
                    Image(systemName: debateManager.hasRaisedHand ? "hand.raised.fill" : "hand.raised")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(debateManager.hasRaisedHand ? .white : AppTheme.primaryText)
                        .frame(width: 52, height: 52)
                        .background(debateManager.hasRaisedHand ? AppTheme.warningOrange : AppTheme.surface)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(debateManager.hasRaisedHand ? Color.clear : AppTheme.separator, lineWidth: 1)
                        )
                    
                    Text("Hand")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 3. Microphone (Primary Control with Subtle Voice Level Halo)
            Button(action: { debateManager.toggleMicrophone() }) {
                VStack(spacing: 4) {
                    ZStack {
                        if !debateManager.audioService.isMuted {
                            Circle()
                                .fill(AppTheme.primaryBlue.opacity(0.18))
                                .frame(width: 58, height: 58)
                                .scaleEffect(1.0 + CGFloat(debateManager.audioService.audioLevel) * 0.25)
                                .animation(.easeOut(duration: 0.1), value: debateManager.audioService.audioLevel)
                        }
                        
                        Image(systemName: debateManager.audioService.isMuted ? "mic.slash.fill" : "mic.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(debateManager.audioService.isMuted ? AppTheme.primaryText : .white)
                            .frame(width: 56, height: 56)
                            .background(debateManager.audioService.isMuted ? AppTheme.surface : AppTheme.primaryBlue)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(debateManager.audioService.isMuted ? AppTheme.separator : Color.clear, lineWidth: 1)
                            )
                    }
                    
                    Text(debateManager.audioService.isMuted ? "Muted" : "Live")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(debateManager.myRole == .listener)
            .opacity(debateManager.myRole == .listener ? 0.45 : 1.0)
            
            // 4. Leave Session
            Button(action: {
                debateManager.leaveSession()
                dismiss()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "phone.down.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 52, height: 52)
                        .background(AppTheme.liveRed)
                        .clipShape(Circle())
                    
                    Text("Leave")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppTheme.space16)
        .padding(.bottom, AppTheme.space12)
        .background(
            AppTheme.background.opacity(0.95)
        )
    }
    
    private var currentRoleIcon: String {
        if debateManager.myRole == .listener { return "headphones" }
        return debateManager.myStance == .forSide ? "hand.thumbsup.fill" : "hand.thumbsdown.fill"
    }
    
    private var currentRoleTint: Color {
        if debateManager.myRole == .listener { return AppTheme.primaryText }
        return debateManager.myStance == .forSide ? AppTheme.successGreen : AppTheme.warningOrange
    }
    
    private var currentRoleLabel: String {
        if debateManager.myRole == .listener { return "Listen" }
        return debateManager.myStance.rawValue
    }
    
    private func formattedTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    // MARK: - Speaking Turn Widget
    @ViewBuilder
    private func speakingTurnWidget(session: DebateSession) -> some View {
        HStack(spacing: AppTheme.space12) {
            Image(systemName: "timer")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(session.isSpeakingTurnActive ? AppTheme.primaryBlue : AppTheme.secondaryText)
            
            if session.isSpeakingTurnActive {
                Text("Turn: \(session.speakingTurnSecondsRemaining)s remaining")
                    .font(.system(size: 13, weight: .medium).monospacedDigit())
                    .foregroundColor(session.speakingTurnSecondsRemaining <= 10 ? AppTheme.liveRed : AppTheme.primaryText)
                
                Spacer()
                
                Button("Reset") {
                    debateManager.resetSpeakingTurn(durationSeconds: 60)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.secondaryText)
            } else {
                Text("60s speaking turn timer")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.secondaryText)
                
                Spacer()
                
                Button("Start Turn") {
                    debateManager.startSpeakingTurn(speakerId: debateManager.currentUser.id, durationSeconds: 60)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.primaryBlue)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppTheme.primaryBlue.opacity(0.10))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, AppTheme.space16)
        .padding(.vertical, 10)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                .stroke(AppTheme.separator, lineWidth: 1)
        )
        .padding(.horizontal, AppTheme.space20)
    }
}

#Preview {
    LiveDebateRoomView(debateManager: DebateManager())
}
