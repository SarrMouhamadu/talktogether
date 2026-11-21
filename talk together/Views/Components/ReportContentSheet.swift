import SwiftUI

public enum ReportReason: String, CaseIterable, Identifiable, Sendable {
    case nudity = "Nudity or sexual content"
    case violence = "Violence or threats"
    case hateSpeech = "Hate speech or discrimination"
    case harassment = "Harassment or bullying"
    case spam = "Spam or scam"
    case notEnglish = "Not in English"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .nudity: return "eye.slash"
        case .violence: return "exclamationmark.triangle"
        case .hateSpeech: return "hand.raised.slash"
        case .harassment: return "person.crop.circle.badge.xmark"
        case .spam: return "megaphone"
        case .notEnglish: return "globe"
        }
    }
}

public struct ReportContentSheet: View {
    @Environment(\.dismiss) private var dismiss
    public var onSubmit: ((ReportReason) -> Void)?
    
    @State private var selectedReason: ReportReason? = nil
    @State private var isSubmitted: Bool = false
    
    public init(onSubmit: ((ReportReason) -> Void)? = nil) {
        self.onSubmit = onSubmit
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                if isSubmitted {
                    VStack(spacing: AppTheme.space16) {
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(AppTheme.successGreen)
                        
                        Text("Report Submitted")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("Thank you for helping keep WaxUp safe and respectful.")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.space24)
                        
                        Spacer()
                        
                        Button(action: { dismiss() }) {
                            Text("Done")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(AppTheme.primaryBlue)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusButton, style: .continuous))
                        }
                        .padding(.horizontal, AppTheme.space20)
                        .padding(.bottom, AppTheme.space20)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppTheme.space16) {
                            Text("Why are you reporting this content?")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.secondaryText)
                                .padding(.horizontal, AppTheme.space4)
                            
                            VStack(spacing: 0) {
                                ForEach(Array(ReportReason.allCases.enumerated()), id: \.element.id) { index, reason in
                                    Button(action: {
                                        selectedReason = reason
                                        onSubmit?(reason)
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isSubmitted = true
                                        }
                                    }) {
                                        HStack(spacing: AppTheme.space12) {
                                            Image(systemName: reason.iconName)
                                                .font(.system(size: 16))
                                                .foregroundColor(AppTheme.primaryText)
                                                .frame(width: 24)
                                            
                                            Text(reason.rawValue)
                                                .font(.system(size: 15))
                                                .foregroundColor(AppTheme.primaryText)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(AppTheme.secondaryText)
                                        }
                                        .padding(.horizontal, AppTheme.space16)
                                        .frame(height: 50)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    if index < ReportReason.allCases.count - 1 {
                                        Rectangle()
                                            .fill(AppTheme.separator)
                                            .frame(height: 1)
                                            .padding(.leading, 52)
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
                        .padding(.horizontal, AppTheme.space20)
                        .padding(.top, AppTheme.space16)
                    }
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    ReportContentSheet()
}
