import SwiftUI

@MainActor
final class BrainViewModel: ObservableObject {
    @Published var query = ""
    @Published var notes: [BrainNote] = []
    @Published var inbox: [BrainItem] = []
    @Published var tags: [TagCount] = []
    @Published var selectedPath: String?
    @Published var noteBody = ""
    @Published var showCapture = false
    @Published var captureTitle = ""
    @Published var captureBody = ""
    @Published var captureTags = ""
    @Published var errorText: String?

    var filtered: [BrainNote] {
        guard !query.isEmpty else { return notes }
        return notes.filter {
            ($0.title ?? "").localizedCaseInsensitiveContains(query)
                || ($0.path ?? "").localizedCaseInsensitiveContains(query)
        }
    }

    func load(client: AetherClient) async {
        do {
            async let n = client.listNotes(limit: 100)
            async let i = client.listInbox()
            async let t = client.listTags()
            notes = try await n
            inbox = (try? await i) ?? []
            tags = (try? await t) ?? []
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

    func dismiss(client: AetherClient, id: String) async {
        do {
            try await client.dismissInbox(id: id)
            inbox.removeAll { $0.id == id }
        } catch {
            errorText = error.localizedDescription
        }
    }

    func capture(client: AetherClient) async {
        let tagList = captureTags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        do {
            try await client.captureNote(title: captureTitle, body: captureBody, tags: tagList)
            captureTitle = ""; captureBody = ""; captureTags = ""
            showCapture = false
            await load(client: client)
        } catch {
            errorText = error.localizedDescription
        }
    }
}

struct BrainView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var vm = BrainViewModel()

    var body: some View {
        List {
            Section("Inbox") {
                ForEach(vm.inbox) { item in
                    VStack(alignment: .leading) {
                        Text(item.title ?? "(untitled)")
                        Text(item.content ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                    .swipeActions {
                        Button("Dismiss") {
                            Task { await vm.dismiss(client: AetherClient(settings: settings), id: item.id ?? "") }
                        }
                        .tint(.gray)
                    }
                }
            }
            Section("Notes") {
                ForEach(vm.filtered) { note in
                    Button {
                        Task { await vm.open(client: AetherClient(settings: settings), path: note.path ?? "") }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(note.title ?? note.path ?? "(note)")
                            Text(note.updated_at ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .searchable(text: $vm.query)
        .navigationTitle("Brain")
        .toolbar {
            Button { vm.showCapture = true } label: { Image(systemName: "square.and.pencil") }
                .glassEffect(.regular, in: .circle)
        }
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
        .sheet(isPresented: $vm.showCapture) {
            NavigationStack {
                Form {
                    TextField("Title", text: $vm.captureTitle)
                    TextField("Body", text: $vm.captureBody, axis: .vertical)
                    TextField("Tags (comma separated)", text: $vm.captureTags)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(vm.tags.prefix(12), id: \.tag) { t in
                                Button(t.tag ?? "") {
                                    if !vm.captureTags.isEmpty { vm.captureTags += ", " }
                                    vm.captureTags += (t.tag ?? "")
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .glassEffect(.regular, in: .capsule)
                            }
                        }
                    }
                }
                .navigationTitle("Capture")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { vm.showCapture = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { Task { await vm.capture(client: AetherClient(settings: settings)) } }
                            .glassEffect(.regular, in: .capsule)
                    }
                }
            }
        }
    }
}

extension String: @retroactive Identifiable {
    public var id: String { self }
}
