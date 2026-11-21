import SwiftUI

public struct WelcomeView: View {
    @Bindable public var authManager: AuthManager
    
    @State private var isShowingLogin: Bool = false
    @State private var isShowingSignUp: Bool = false
    @State private var hasAppeared: Bool = false
    @State private var pulseRings: Bool = false
    @State private var hapticTrigger: Int = 0
    
    public init(authManager: AuthManager) {
        self.authManager = authManager
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. Live Social Proof Pill (2026 Real-Time Presence)
                HStack(spacing: 6) {
                    Circle()
                        .fill(AppTheme.liveRed)
                        .frame(width: 7, height: 7)
                    Text("Live voice rooms open")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.primaryText)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(AppTheme.surface)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(AppTheme.separator, lineWidth: 1)
                )
                .padding(.top, AppTheme.space24)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : -8)
                
                Spacer()
                
                // 2. Center Focal Point: Living Logo + Editorial Typography
                VStack(spacing: AppTheme.space32) {
                    // Ambient Breathing Acoustic Rings + App Logo
                    ZStack {
                        Circle()
                            .stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1.5)
                            .frame(width: 152, height: 152)
                            .scaleEffect(pulseRings ? 1.08 : 0.96)
                            .opacity(pulseRings ? 0.35 : 0.85)
                        
                        Circle()
                            .stroke(AppTheme.primaryBlue.opacity(0.14), lineWidth: 1.5)
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulseRings ? 1.05 : 0.98)
                        
                        Image("AppLogo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 88, height: 88)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .shadow(color: AppTheme.primaryBlue.opacity(0.22), radius: 20, x: 0, y: 10)
                    }
                    .scaleEffect(hasAppeared ? 1 : 0.9)
                    .opacity(hasAppeared ? 1 : 0)
                    
                    // Confident, Minimalist Headline (Zero Feature-List Clutter)
                    VStack(spacing: AppTheme.space8) {
                        Text("WaxUp")
                            .font(.system(size: 36, weight: .bold))
                            .tracking(-0.8)
                            .foregroundColor(AppTheme.primaryText)
                        
                        Text("Speak. Debate. Improve.")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.primaryBlue)
                        
                        Text("Practice real English in live voice rooms with people who love to debate.")
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .padding(.horizontal, AppTheme.space24)
                            .padding(.top, 4)
                    }
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 12)
                }
                
                Spacer()
                
                // 3. Thumb-Zone Action Dock (Frictionless Entry)
                VStack(spacing: AppTheme.space12) {
                    Button(action: {
                        hapticTrigger += 1
                        isShowingSignUp = true
                    }) {
                        Text("Get Started")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(AppTheme.primaryBlue)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusButton, style: .continuous))
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        hapticTrigger += 1
                        isShowingLogin = true
                    }) {
                        Text("I already have an account")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.radiusButton, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.radiusButton, style: .continuous)
                                    .stroke(AppTheme.separator, lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("English-only community · Free to join")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.secondaryText)
                        .padding(.top, AppTheme.space4)
                }
                .padding(.horizontal, AppTheme.space24)
                .padding(.bottom, AppTheme.space20)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppTheme.background.ignoresSafeArea())
            .sensoryFeedback(.impact(weight: .light), trigger: hapticTrigger)
            .onAppear {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.85)) {
                    hasAppeared = true
                }
                withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
                    pulseRings = true
                }
            }
            .sheet(isPresented: $isShowingLogin) {
                LoginView(authManager: authManager)
            }
            .sheet(isPresented: $isShowingSignUp) {
                SignUpView(authManager: authManager)
            }
        }
    }
}

#Preview {
    WelcomeView(authManager: AuthManager())
}
