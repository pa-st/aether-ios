import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        TabView {
            NavigationStack { ChatView() }
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
            NavigationStack { ResearchView() }
                .tabItem { Label("Research", systemImage: "magnifyingglass") }
            NavigationStack { BrainView() }
                .tabItem { Label("Brain", systemImage: "brain.head.profile") }
            NavigationStack { LibraryView() }
                .tabItem { Label("Library", systemImage: "books.vertical") }
            NavigationStack { StatusView() }
                .tabItem { Label("Status", systemImage: "gauge.with.dots.needle.33percent") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
