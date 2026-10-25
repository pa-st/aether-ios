import SwiftUI

@MainActor
final class StatusViewModel: ObservableObject {
    @Published var health: String?
    @Published var status: String?
    @Published var errorText: String?
    @Published var loading = true

    func load(client: AetherClient) async {
        loading = true
        defer { loading = false }
        do {
            async let h = client.getRaw("/api/health")
            async let s = client.getRaw("/api/status")
            health = try await h
            status = try await s
            errorText = nil
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
                if vm.loading && vm.health == nil {
                    ProgressView("Contacting server…")
                        .padding(.top, 40)
                } else if let err = vm.errorText, vm.health == nil {
                    ContentUnavailableView(
                        "Server unreachable",
                        systemImage: "wifi.exclamationmark",
                        description: Text(err)
                    )
                    .padding(.top, 40)
                } else {
                    glassCard(title: "Health", body: vm.health ?? "…")
                    glassCard(title: "Server", body: vm.status ?? "…")
                    if let err = vm.errorText {
                        Text(err).font(.footnote).foregroundStyle(.orange)
                    }
                }
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
