import SwiftUI

public struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable public var authManager: AuthManager
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    
    public init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.space20) {
                    // Header
                    VStack(alignment: .leading, spacing: AppTheme.space6) {
                        Text("Sign In")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("Enter your email and password to access your account.")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(.top, AppTheme.space8)
                    
                    // Credentials Form with Visible Labels & High Contrast
                    VStack(spacing: AppTheme.space16) {
                        // 1. Email Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText)
                            
                            HStack(spacing: AppTheme.space12) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.primaryBlue)
                                    .frame(width: 20)
                                
                                TextField(
                                    "",
                                    text: $email,
                                    prompt: Text("name@example.com").foregroundColor(AppTheme.placeholderText)
                                )
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.primaryText)
                                .tint(AppTheme.primaryBlue)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            }
                            .padding(AppTheme.space16)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                                    .stroke(AppTheme.inputBorder, lineWidth: 1.2)
                            )
                        }
                        
                        // 2. Password Field with Visibility Toggle
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText)
                            
                            HStack(spacing: AppTheme.space12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.primaryBlue)
                                    .frame(width: 20)
                                
                                if isPasswordVisible {
                                    TextField(
                                        "",
                                        text: $password,
                                        prompt: Text("Enter your password").foregroundColor(AppTheme.placeholderText)
                                    )
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.primaryText)
                                    .tint(AppTheme.primaryBlue)
                                } else {
                                    SecureField(
                                        "",
                                        text: $password,
                                        prompt: Text("Enter your password").foregroundColor(AppTheme.placeholderText)
                                    )
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.primaryText)
                                    .tint(AppTheme.primaryBlue)
                                    .textContentType(.password)
                                }
                                
                                Button(action: { isPasswordVisible.toggle() }) {
                                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(AppTheme.space16)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                                    .stroke(AppTheme.inputBorder, lineWidth: 1.2)
                            )
                        }
                    }
                    
                    if let error = authManager.errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 13))
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(AppTheme.liveRed)
                        .padding(.horizontal, 4)
                    }
                    
                    // Submit CTA
                    Button(action: handleLogin) {
                        HStack {
                            Spacer()
                            if authManager.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .frame(height: 52)
                        .background(isValid ? AppTheme.primaryBlue : AppTheme.primaryBlue.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusButton, style: .continuous))
                    }
                    .disabled(!isValid || authManager.isLoading)
                    .padding(.top, AppTheme.space8)
                }
                .padding(.horizontal, AppTheme.space20)
                .padding(.vertical, AppTheme.space16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.primaryBlue)
                }
            }
        }
    }
    
    private var isValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && password.count >= 6
    }
    
    private func handleLogin() {
        Task {
            let success = await authManager.login(email: email, password: password)
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    LoginView(authManager: AuthManager())
}
