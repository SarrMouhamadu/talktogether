import SwiftUI

public struct MainTabView: View {
    @Bindable public var authManager: AuthManager
    
    @State private var selectedTab: Int = 0
    @State private var isShowingCreateSheet: Bool = false
    @State private var isShowingLiveRoom: Bool = false
    
    // Centralized real-time state & audio manager
    @State private var debateManager: DebateManager
    
    @MainActor
    public init(authManager: AuthManager) {
        self.authManager = authManager
        let manager = DebateManager(currentUser: authManager.currentUser)
        _debateManager = State(initialValue: manager)
    }
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                debateManager: debateManager,
                onSelectTopic: { topic in
                    debateManager.loadSession(for: topic)
                    isShowingLiveRoom = true
                },
                onCreateTopic: {
                    isShowingCreateSheet = true
                }
            )
            .tabItem {
                Label("Home", systemImage: selectedTab == 0 ? "house.fill" : "house")
            }
            .tag(0)
            
            ScheduleView(
                debateManager: debateManager,
                onSelectTopic: { topic in
                    debateManager.loadSession(for: topic)
                    isShowingLiveRoom = true
                }
            )
            .tabItem {
                Label("Schedule", systemImage: selectedTab == 1 ? "calendar.badge.clock" : "calendar")
            }
            .tag(1)
            
            // Empty view trigger for Create modal
            Color.clear
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(2)
            
            ActivityView()
                .tabItem {
                    Label("Activity", systemImage: selectedTab == 3 ? "bell.fill" : "bell")
                }
                .tag(3)
            
            ProfileView(authManager: authManager, debateManager: debateManager)
                .tabItem {
                    Label("Profile", systemImage: selectedTab == 4 ? "person.fill" : "person")
                }
                .tag(4)
        }
        .tint(AppTheme.primaryBlue)
        .onChange(of: selectedTab) { _, newTab in
            if newTab == 2 {
                isShowingCreateSheet = true
                selectedTab = 0
            }
        }
        .onChange(of: authManager.currentUser) { _, newUser in
            if let user = newUser {
                debateManager.currentUser = user
            }
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            CreateTopicView(onTopicCreated: { newTopic in
                debateManager.addTopicToQueue(newTopic)
            })
        }
        .fullScreenCover(isPresented: $isShowingLiveRoom) {
            LiveDebateRoomView(debateManager: debateManager)
        }
        .overlay(alignment: .bottom) {
            if debateManager.isMiniPlayerActive && debateManager.currentSession != nil {
                FloatingMiniPlayerBar(debateManager: debateManager) {
                    debateManager.isMiniPlayerActive = false
                    isShowingLiveRoom = true
                }
                .padding(.bottom, 54)
            }
        }
    }
}

#Preview {
    MainTabView(authManager: AuthManager())
}
