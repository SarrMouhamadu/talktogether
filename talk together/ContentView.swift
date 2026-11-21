import SwiftUI

struct ContentView: View {
    @State private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView(authManager: authManager)
            } else {
                WelcomeView(authManager: authManager)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authManager.isAuthenticated)
    }
}

#Preview {
    ContentView()
}
