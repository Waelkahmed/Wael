import SwiftUI

struct MainTabsView: View {
    @EnvironmentObject var session: AppSession

    var body: some View {
        TabView(selection: $session.selectedTabIndex) {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            NavigationStack { TripsView() }
                .tabItem { Label("Trips", systemImage: "clock.fill") }
                .tag(1)

            NavigationStack { ProfileView() }
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(2)
        }
    }
}