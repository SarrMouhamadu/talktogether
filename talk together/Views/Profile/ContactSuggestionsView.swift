import SwiftUI

public struct ContactSuggestionsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    
    @State private var suggestionText: String = ""
    @State private var isSubmitting: Bool = false
    @State private var showSuccessToast: Bool = false
    @State private var copiedItem: String? = nil
    
    private let phoneNumber = "+221777091913"
    private let formattedPhone = "+221 77 709 19 13"
    private let emailAddress = "contact@syllaenglishacademy.com"
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.space24) {
                // Header Banner
                VStack(spacing: AppTheme.space12) {
                    Circle()
                        .fill(AppTheme.primaryBlue.opacity(0.12))
                        .frame(width: 68, height: 68)
                        .overlay(
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 28))
                                .foregroundColor(AppTheme.primaryBlue)
                        )
                    
                    VStack(spacing: 4) {
                        Text("Suggestions & Contact")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("Have ideas to improve WaxUp? We'd love to hear from you.")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.space24)
                    }
                }
                .padding(.top, AppTheme.space16)
                
                // Contact Channels Card
                VStack(alignment: .leading, spacing: AppTheme.space16) {
                    Text("Direct Channels")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.horizontal, AppTheme.space4)
                    
                    VStack(spacing: 0) {
                        // Phone / WhatsApp Row
                        HStack(spacing: AppTheme.space16) {
                            Circle()
                                .fill(AppTheme.successGreen.opacity(0.12))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 17))
                                        .foregroundColor(AppTheme.successGreen)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Phone & WhatsApp")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.secondaryText)
                                
                                Text(formattedPhone)
                                    .font(.system(size: 15, weight: .bold).monospacedDigit())
                                    .foregroundColor(AppTheme.primaryText)
                            }
                            
                            Spacer()
                            
                            // WhatsApp direct link
                            Button {
                                if let url = URL(string: "https://wa.me/221777091913?text=Hello%20Sylla%20English%20Academy%2C%20I%20have%20a%20suggestion%20for%20WaxUp%3A%20") {
                                    openURL(url)
                                }
                            } label: {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.successGreen)
                                    .frame(width: 36, height: 36)
                                    .background(AppTheme.successGreen.opacity(0.12))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel("Chat on WhatsApp")
                            
                            // Call link
                            Button {
                                if let url = URL(string: "tel:\(phoneNumber)") {
                                    openURL(url)
                                }
                            } label: {
                                Image(systemName: "phone.arrow.up.right.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.primaryBlue)
                                    .frame(width: 36, height: 36)
                                    .background(AppTheme.primaryBlue.opacity(0.12))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel("Call number")
                            
                            // Copy button
                            Button {
                                UIPasteboard.general.string = phoneNumber
                                copyFeedback(for: "Phone copied")
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.secondaryText)
                                    .frame(width: 36, height: 36)
                                    .background(AppTheme.surface)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel("Copy phone number")
                        }
                        .padding(AppTheme.space16)
                        
                        Rectangle()
                            .fill(AppTheme.separator)
                            .frame(height: 1)
                            .padding(.leading, 68)
                        
                        // Email Row
                        HStack(spacing: AppTheme.space16) {
                            Circle()
                                .fill(AppTheme.primaryBlue.opacity(0.12))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 17))
                                        .foregroundColor(AppTheme.primaryBlue)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Contact Email")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.secondaryText)
                                
                                Text(emailAddress)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryText)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            
                            Spacer()
                            
                            // Email direct link
                            Button {
                                if let url = URL(string: "mailto:\(emailAddress)?subject=WaxUp%20Suggestion") {
                                    openURL(url)
                                }
                            } label: {
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryBlue)
                                    .frame(width: 36, height: 36)
                                    .background(AppTheme.primaryBlue.opacity(0.12))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel("Send email")
                            
                            // Copy button
                            Button {
                                UIPasteboard.general.string = emailAddress
                                copyFeedback(for: "Email copied")
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.secondaryText)
                                    .frame(width: 36, height: 36)
                                    .background(AppTheme.surface)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel("Copy email address")
                        }
                        .padding(AppTheme.space16)
                    }
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                            .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                    )
                }
                .padding(.horizontal, AppTheme.space20)
                
                // In-App Direct Suggestion Box
                VStack(alignment: .leading, spacing: AppTheme.space12) {
                    Text("Send a Suggestion")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.horizontal, AppTheme.space4)
                    
                    VStack(spacing: AppTheme.space12) {
                        TextField(
                            "What would make WaxUp better for you?",
                            text: $suggestionText,
                            axis: .vertical
                        )
                        .font(.system(size: 14))
                        .lineLimit(4...8)
                        .padding(AppTheme.space12)
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                                .stroke(AppTheme.separator, lineWidth: 1)
                        )
                        
                        Button {
                            submitInAppSuggestion()
                        } label: {
                            HStack(spacing: 6) {
                                if isSubmitting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Submit Feedback")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(suggestionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.secondaryText.opacity(0.3) : AppTheme.primaryBlue)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusButton, style: .continuous))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(suggestionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                    }
                    .padding(AppTheme.space16)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusCard, style: .continuous)
                            .stroke(AppTheme.separator.opacity(0.8), lineWidth: 1)
                    )
                }
                .padding(.horizontal, AppTheme.space20)
                
                // Academy Attribution
                VStack(spacing: 4) {
                    Text("WaxUp by Sylla English Academy")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText)
                    
                    Text("Dedicated to elevating oral English fluency through live debates.")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.space24)
                }
                .padding(.top, AppTheme.space8)
                .padding(.bottom, AppTheme.space24)
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Contact & Feedback")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if let toast = copiedItem {
                Text(toast)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else if showSuccessToast {
                Text("Thank you! Your suggestion has been received.")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppTheme.successGreen)
                    .clipShape(Capsule())
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    private func copyFeedback(for message: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            copiedItem = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeInOut(duration: 0.2)) {
                if copiedItem == message {
                    copiedItem = nil
                }
            }
        }
    }
    
    private func submitInAppSuggestion() {
        isSubmitting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isSubmitting = false
            suggestionText = ""
            withAnimation(.spring(response: 0.3)) {
                showSuccessToast = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSuccessToast = false
                }
            }
        }
    }
}
