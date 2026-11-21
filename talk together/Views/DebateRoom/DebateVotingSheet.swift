import SwiftUI

public struct DebateVotingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable public var debateManager: DebateManager
    
    @State private var hasSelectedSide: Bool = false
    
    public init(debateManager: DebateManager) {
        self.debateManager = debateManager
    }
    
    private var session: DebateSession? {
        debateManager.currentSession
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.space24) {
                // Header icon
                Circle()
                    .fill(AppTheme.primaryBlue.opacity(0.12))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.primaryBlue)
                    )
                    .padding(.top, AppTheme.space16)
                
                // Title and prompt
                VStack(spacing: AppTheme.space8) {
                    Text("Audience Verdict")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text("Which side presented the most compelling arguments?")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.space24)
                }
                
                if let session = session {
                    // Debate Question snippet
                    Text("\"\(session.topic.debateQuestion)\"")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.primaryText)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.space20)
                    
                    // Live Tally Progress Bar
                    VStack(spacing: AppTheme.space8) {
                        HStack {
                            Text("FOR · \(Int(session.forPercentage))%")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.successGreen)
                            
                            Spacer()
                            
                            Text("\(Int(session.againstPercentage))% · AGAINST")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppTheme.warningOrange)
                        }
                        
                        GeometryReader { proxy in
                            let totalWidth = proxy.size.width
                            let forWidth = totalWidth * CGFloat(session.forPercentage / 100.0)
                            
                            HStack(spacing: 3) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(AppTheme.successGreen)
                                    .frame(width: max(8, forWidth))
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(AppTheme.warningOrange)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(height: 10)
                        
                        HStack {
                            Text("\(session.votesForCount) votes")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.secondaryText)
                            
                            Spacer()
                            
                            Text("\(session.votesAgainstCount) votes")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    .padding(.horizontal, AppTheme.space24)
                    .padding(.vertical, AppTheme.space12)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                            .stroke(AppTheme.separator, lineWidth: 1)
                    )
                    .padding(.horizontal, AppTheme.space20)
                    
                    // Voting Choice Buttons
                    VStack(spacing: AppTheme.space12) {
                        let currentVote = debateManager.currentUserVotedStance
                        
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                debateManager.castVote(stance: .forSide)
                            }
                        } label: {
                            HStack {
                                Image(systemName: currentVote == .forSide ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppTheme.successGreen)
                                
                                Text("The FOR side was more convincing")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppTheme.primaryText)
                                
                                Spacer()
                            }
                            .padding(.horizontal, AppTheme.space16)
                            .frame(height: 52)
                            .background(currentVote == .forSide ? AppTheme.successGreen.opacity(0.12) : AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                                    .stroke(currentVote == .forSide ? AppTheme.successGreen : AppTheme.separator, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                debateManager.castVote(stance: .againstSide)
                            }
                        } label: {
                            HStack {
                                Image(systemName: currentVote == .againstSide ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppTheme.warningOrange)
                                
                                Text("The AGAINST side was more convincing")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppTheme.primaryText)
                                
                                Spacer()
                            }
                            .padding(.horizontal, AppTheme.space16)
                            .frame(height: 52)
                            .background(currentVote == .againstSide ? AppTheme.warningOrange.opacity(0.12) : AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                                    .stroke(currentVote == .againstSide ? AppTheme.warningOrange : AppTheme.separator, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, AppTheme.space20)
                }
                
                Spacer()
            }
            .navigationTitle("Live Voting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.primaryBlue)
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
        }
    }
}
