import SwiftUI

public struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable public var authManager: AuthManager
    
    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var country: String = "Senegal"
    @State private var level: EnglishLevel = .intermediate
    @State private var agreesToRules: Bool = true
    @State private var isShowingRules: Bool = false
    
    public init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.space20) {
                    VStack(alignment: .leading, spacing: AppTheme.space4) {
                        Text("Create Account")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("Join the English speaking and debate community.")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(.top, AppTheme.space8)
                    
                    // Form Fields
                    VStack(spacing: AppTheme.space12) {
                        inputField(placeholder: "Full Name", text: $fullName)
                            .textContentType(.name)
                        
                        inputField(placeholder: "Username (e.g. mouha_sarr)", text: $username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        inputField(placeholder: "Country", text: $country)
                        
                        inputField(placeholder: "Email address", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        
                        SecureField("Password (min 6 characters)", text: $password)
                            .font(.system(size: 15))
                            .textContentType(.newPassword)
                            .padding(AppTheme.space16)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                                    .stroke(AppTheme.separator, lineWidth: 1)
                            )
                    }
                    
                    // English Level Picker
                    VStack(alignment: .leading, spacing: AppTheme.space8) {
                        Text("English Proficiency Level")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                        
                        Menu {
                            ForEach(EnglishLevel.allCases) { lvl in
                                Button(lvl.rawValue) {
                                    level = lvl
                                }
                            }
                        } label: {
                            HStack {
                                Text(level.rawValue)
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.primaryText)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(AppTheme.space16)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                                    .stroke(AppTheme.separator, lineWidth: 1)
                            )
                        }
                    }
                    
                    // Agreement
                    VStack(alignment: .leading, spacing: AppTheme.space8) {
                        Toggle(isOn: $agreesToRules) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("I agree to the Community Rules")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.primaryText)
                                Text("No nudity, violence, hate speech, or harassment. English only.")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                        }
                        .tint(AppTheme.primaryBlue)
                        
                        Button(action: { isShowingRules = true }) {
                            Text("Read full Community & Safety Rules")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.primaryBlue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(AppTheme.space16)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                            .stroke(AppTheme.separator, lineWidth: 1)
                    )
                    .sheet(isPresented: $isShowingRules) {
                        NavigationStack {
                            CommunityRulesView()
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("Close") { isShowingRules = false }
                                            .foregroundColor(AppTheme.primaryBlue)
                                    }
                                }
                        }
                    }
                    
                    if let error = authManager.errorMessage {
                        Text(error)
                            .foregroundColor(AppTheme.liveRed)
                            .font(.system(size: 13))
                    }
                    
                    // Submit CTA
                    Button(action: handleSignUp) {
                        HStack {
                            Spacer()
                            if authManager.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Account")
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
                    .padding(.bottom, AppTheme.space24)
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
    
    private func inputField(placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .font(.system(size: 15))
            .padding(AppTheme.space16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.radiusInput, style: .continuous)
                    .stroke(AppTheme.separator, lineWidth: 1)
            )
    }
    
    private var isValid: Bool {
        !fullName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        password.count >= 6 &&
        agreesToRules
    }
    
    private func handleSignUp() {
        Task {
            let success = await authManager.signUp(
                fullName: fullName,
                username: username,
                email: email,
                password: password,
                country: country,
                level: level
            )
            if success {
                dismiss()
            }
        }
    }
}

#Preview {
    SignUpView(authManager: AuthManager())
}
