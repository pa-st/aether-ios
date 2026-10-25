import SwiftUI

@MainActor
final class StatusViewModel: ObservableObject {
    @Published var health = ""
    @Published var status = ""
    @Published var errorText: String?

    func load(client: AetherClient) async {
        do {
            async let h = client.getRaw("/api/health")
            async let s = client.getRaw("/api/status")
            health = (try? await h) ?? "(no response)"
            status = (try? await s) ?? "(no response)"
        } catch {
            errorText = error.localizedDescription
        }
    }
}

struct StatusView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var vm = StatusViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                glassCard(title: "Health", body: vm.health)
                glassCard(title: "Status", body: vm.status)
                Button("Refresh") {
                    Task { await vm.load(client: AetherClient(settings: settings)) }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: .capsule)
            }
            .padding()
        }
        .navigationTitle("Status")
        .task { await vm.load(client: AetherClient(settings: settings)) }
    }

    private func glassCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(body.isEmpty ? "…" : body)
                .font(.system(.caption, design: .monospaced))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}
