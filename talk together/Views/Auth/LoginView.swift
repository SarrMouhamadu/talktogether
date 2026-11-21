import SwiftUI

public struct LoginView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable public var authManager: AuthManager
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    public init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.space20) {
                    // Credentials Form
                    VStack(alignment: .leading, spacing: AppTheme.space12) {
                        Text("Sign In")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("Enter your email and password to access your account.")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(.top, AppTheme.space8)
                    
                    VStack(spacing: AppTheme.space12) {
                        TextField("Email address", text: $email)
                            .font(.system(size: 15))
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(AppTheme.space16)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                                    .stroke(AppTheme.separator, lineWidth: 1)
                            )
                        
                        SecureField("Password", text: $password)
                            .font(.system(size: 15))
                            .textContentType(.password)
                            .padding(AppTheme.space16)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                                    .stroke(AppTheme.separator, lineWidth: 1)
                            )
                    }
                    
                    if let error = authManager.errorMessage {
                        Text(error)
                            .foregroundColor(AppTheme.liveRed)
                            .font(.system(size: 13))
                    }
                    
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
                        .frame(height: 50)
                        .background(isValid ? AppTheme.primaryBlue : AppTheme.primaryBlue.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusButton, style: .continuous))
                    }
                    .disabled(!isValid || authManager.isLoading)
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
                    .font(.system(size: 15))
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
