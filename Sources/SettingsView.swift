import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var testResult = ""
    @State private var testing = false

    var body: some View {
        Form {
            Section("Server") {
                TextField("Base URL", text: $settings.baseURL)
                    .autocorrectionDisabled()
                SecureField("API key (optional)", text: $settings.apiKey)
                Button(testing ? "Testing…" : "Test") { Task { await test() } }
                    .disabled(testing)
            }
            if !testResult.isEmpty {
                Section("Result") {
                    Text(testResult)
                        .font(.footnote)
                        .foregroundStyle(testResult.hasPrefix("OK") ? .green : .red)
                }
            }
            Section {
                Text("Base URL and API key stay on-device in UserDefaults. The key is sent as an Authorization Bearer header when set.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }

    private func test() async {
        testing = true
        defer { testing = false }
        do {
            let body = try await AetherClient(settings: settings).getRaw("/api/health")
            testResult = "OK: \(body.prefix(120))"
        } catch {
            testResult = "FAIL: \(error.localizedDescription)"
        }
    }
}
