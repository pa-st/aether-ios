import SwiftUI

@MainActor
final class ResearchViewModel: ObservableObject {
    @Published var runs: [ResearchRun] = []
    @Published var errorText: String?
    @Published var showComposer = false
    @Published var question = ""
    @Published var detail: ResearchDetail?
    @Published var detailId: String?

    func load(client: AetherClient) async {
        do {
            runs = try await client.listResearch(limit: 20)
        } catch {
            errorText = error.localizedDescription
        }
    }

    func create(client: AetherClient) async {
        let q = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        do {
            let run = try await client.createResearch(question: q)
            question = ""
            showComposer = false
            runs.insert(run, at: 0)
            detailId = run.id
        } catch {
            errorText = error.localizedDescription
        }
    }

    func pollDetail(client: AetherClient, id: String) async {
        for _ in 0..<30 {
            do {
                detail = try await client.fetchResearch(id: id)
            } catch {
                errorText = error.localizedDescription
                return
            }
            let status = detail?.run?.status?.lowercased() ?? ""
            if status != "running" && status != "pending" { return }
            try? await Task.sleep(nanoseconds: 4_000_000_000)
        }
    }
}

struct ResearchView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var vm = ResearchViewModel()

    var body: some View {
        List(vm.runs, id: \.id) { run in
            Button {
                vm.detailId = run.id
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(run.question ?? "(no question)")
                            .lineLimit(2)
                        Text(run.updated_at ?? run.created_at ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    statusPill(run.status)
                }
            }
        }
        .navigationTitle("Research")
        .toolbar {
            Button { vm.showComposer = true } label: { Image(systemName: "plus") }
                .glassEffect(.regular, in: .circle)
        }
        .task { await vm.load(client: AetherClient(settings: settings)) }
        .refreshable { await vm.load(client: AetherClient(settings: settings)) }
        .sheet(isPresented: $vm.showComposer) {
            NavigationStack {
                Form {
                    TextField("Research question", text: $vm.question, axis: .vertical)
                }
                .navigationTitle("New run")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { vm.showComposer = false } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Start") { Task { await vm.create(client: AetherClient(settings: settings)) } }
                            .glassEffect(.regular, in: .capsule)
                    }
                }
            }
        }
        .sheet(item: detailBinding) { id in
            ResearchDetailView(runId: id)
        }
        .alert("Error", isPresented: errorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorText ?? "")
        }
    }

    private var detailBinding: Binding<String?> {
        Binding(get: { vm.detailId }, set: { vm.detailId = $0 })
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { vm.errorText != nil }, set: { if !$0 { vm.errorText = nil } })
    }

    private func statusPill(_ status: String?) -> some View {
        Text(status ?? "?")
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .glassEffect(.regular, in: .capsule)
    }
}

struct ResearchDetailView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var vm = ResearchViewModel()
    let runId: String

    var body: some View {
        NavigationStack {
            List {
                Section("Status") {
                    Text(vm.detail?.run?.status ?? "…")
                    Text(vm.detail?.run?.question ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Section("Sources") {
                    ForEach((vm.detail?.sources ?? []).indices, id: \.self) { i in
                        let s = vm.detail?.sources?[i]
                        if let urlString = s?.url, let url = URL(string: urlString) {
                            Link(s?.title ?? urlString, destination: url)
                        } else {
                            Text(s?.title ?? "(source)")
                        }
                    }
                }
                Section("Claims") {
                    ForEach((vm.detail?.claims ?? []).indices, id: \.self) { i in
                        let c = vm.detail?.claims?[i]
                        VStack(alignment: .leading) {
                            Text(c?.claim ?? c?.text ?? "(claim)")
                            if let t = c?.type {
                                Text(t).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Run")
            .task { await vm.pollDetail(client: AetherClient(settings: settings), id: runId) }
        }
    }
}
