import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    // Simulator screenshot hook: launch with e.g. `-AETHER_TAB Research`.
    @State private var selection: String = {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-AETHER_TAB"), i + 1 < args.count {
            return args[i + 1]
        }
        return "Chat"
    }()

    var body: some View {
        TabView(selection: $selection) {
            NavigationStack { ChatView() }
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right") }
                .tag("Chat")
            NavigationStack { ResearchView() }
                .tabItem { Label("Research", systemImage: "magnifyingglass") }
                .tag("Research")
            NavigationStack { BrainView() }
                .tabItem { Label("Brain", systemImage: "brain.head.profile") }
                .tag("Brain")
            NavigationStack { LibraryView() }
                .tabItem { Label("Library", systemImage: "books.vertical") }
                .tag("Library")
            NavigationStack { StatusView() }
                .tabItem { Label("Status", systemImage: "gauge.with.dots.needle.33percent") }
                .tag("Status")
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gear") }
                .tag("Settings")
        }
    }
}
