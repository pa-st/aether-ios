import SwiftUI

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var notes: [BrainNote] = []
    @Published var selectedPath: String?
    @Published var noteBody = ""
    @Published var errorText: String?

    var researchAndOutputs: [BrainNote] {
        notes.filter {
            let p = $0.path ?? ""
            return p.hasPrefix("Research") || p.hasPrefix("Outputs")
        }
    }

    func load(client: AetherClient) async {
        do {
            notes = try await client.listNotes(limit: 100)
        } catch {
            errorText = error.localizedDescription
        }
    }

    func open(client: AetherClient, path: String) async {
        selectedPath = path
        do {
            noteBody = try await client.fetchNote(path: path)
        } catch {
            errorText = error.localizedDescription
        }
    }
}

struct LibraryView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var vm = LibraryViewModel()

    var body: some View {
        List(vm.researchAndOutputs) { note in
            Button {
                Task { await vm.open(client: AetherClient(settings: settings), path: note.path ?? "") }
            } label: {
                VStack(alignment: .leading) {
                    Text(note.title ?? note.path ?? "(note)")
                    Text(note.path ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Library")
        .task { await vm.load(client: AetherClient(settings: settings)) }
        .refreshable { await vm.load(client: AetherClient(settings: settings)) }
        .sheet(item: $vm.selectedPath) { path in
            NavigationStack {
                ScrollView { Text(vm.noteBody).padding() }
                    .navigationTitle(path)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Close") { vm.selectedPath = nil }
                        }
                    }
            }
        }
    }
}
