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
                        Text("Create Account")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("Join the English speaking and debate community.")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(.top, AppTheme.space8)
                    
                    // Form Fields with Visible Labels & High Contrast
                    VStack(spacing: AppTheme.space16) {
                        // 1. Full Name
                        formField(
                            label: "Full Name",
                            icon: "person.fill",
                            placeholder: "e.g. Mouhamadou Sarr",
                            text: $fullName
                        )
                        .textContentType(.name)
                        
                        // 2. Username
                        formField(
                            label: "Username",
                            icon: "at",
                            placeholder: "e.g. mouha_sarr",
                            text: $username
                        )
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        
                        // 3. Country
                        formField(
                            label: "Country",
                            icon: "globe.americas.fill",
                            placeholder: "e.g. Senegal",
                            text: $country
                        )
                        
                        // 4. Email
                        formField(
                            label: "Email Address",
                            icon: "envelope.fill",
                            placeholder: "name@example.com",
                            text: $email
                        )
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        
                        // 5. Password with Visibility Toggle
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
                                        prompt: Text("Min 6 characters").foregroundColor(AppTheme.placeholderText)
                                    )
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.primaryText)
                                    .tint(AppTheme.primaryBlue)
                                } else {
                                    SecureField(
                                        "",
                                        text: $password,
                                        prompt: Text("Min 6 characters").foregroundColor(AppTheme.placeholderText)
                                    )
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.primaryText)
                                    .tint(AppTheme.primaryBlue)
                                    .textContentType(.newPassword)
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
                    
                    // 6. English Level Picker
                    VStack(alignment: .leading, spacing: 6) {
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
                            HStack(spacing: AppTheme.space12) {
                                Image(systemName: "graduationcap.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.primaryBlue)
                                    .frame(width: 20)
                                
                                Text(level.rawValue)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppTheme.primaryText)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.secondaryText)
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
                    
                    // 7. Community Rules Agreement
                    VStack(alignment: .leading, spacing: AppTheme.space8) {
                        Toggle(isOn: $agreesToRules) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("I agree to the Community Rules")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.primaryText)
                                Text("No nudity, violence, hate speech, or harassment. English only.")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.secondaryText)
                                    .lineLimit(2)
                            }
                        }
                        .tint(AppTheme.primaryBlue)
                        
                        Button(action: { isShowingRules = true }) {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 11))
                                Text("Read full Community & Safety Rules")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(AppTheme.primaryBlue)
                            .padding(.top, 4)
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
                    .sheet(isPresented: $isShowingRules) {
                        NavigationStack {
                            CommunityRulesView()
                                .toolbar {
                                    ToolbarItem(placement: .cancellationAction) {
                                        Button("Close") { isShowingRules = false }
                                            .foregroundColor(AppTheme.primaryBlue)
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                }
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
                    
                    // Submit CTA Button
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
                        .frame(height: 52)
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
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.primaryBlue)
                }
            }
        }
    }
    
    private func formField(label: String, icon: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.primaryText)
            
            HStack(spacing: AppTheme.space12) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.primaryBlue)
                    .frame(width: 20)
                
                TextField(
                    "",
                    text: text,
                    prompt: Text(placeholder).foregroundColor(AppTheme.placeholderText)
                )
                .font(.system(size: 15))
                .foregroundColor(AppTheme.primaryText)
                .tint(AppTheme.primaryBlue)
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
