import SwiftUI

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var input = ""
    @Published var searchEnabled = false
    @Published var brainEnabled = true
    @Published var models: [ModelInfo] = []
    @Published var selectedModelId: String?
    @Published var isStreaming = false
    @Published var errorText: String?
    @Published var conversationId: String?

    private var lastFailedInput: String?

    func loadModels(client: AetherClient) async {
        do {
            let ms = try await client.fetchModels()
            models = ms
            if selectedModelId == nil { selectedModelId = ms.first?.id ?? ms.first?.name }
        } catch {
            errorText = error.localizedDescription
        }
    }

    func send(client: AetherClient) async {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isStreaming else { return }
        errorText = nil
        lastFailedInput = nil
        input = ""
        messages.append(ChatMessage(role: "user", content: text))
        let assistantIndex = messages.count
        messages.append(ChatMessage(role: "assistant", content: ""))
        isStreaming = true
        defer { isStreaming = false }
        do {
            let model = selectedModelId ?? models.first?.id ?? models.first?.name ?? "default"
            var full = ""
            for try await token in client.streamChat(model: model, content: text, search: searchEnabled, brain: brainEnabled, conversationId: conversationId) {
                full += token
                messages[assistantIndex].content = full
            }
        } catch {
            lastFailedInput = text
            errorText = error.localizedDescription
            if messages[assistantIndex].content?.isEmpty == true {
                messages.remove(at: assistantIndex)
            }
        }
    }

    func retry(client: AetherClient) async {
        guard let failed = lastFailedInput else { return }
        lastFailedInput = nil
        errorText = nil
        input = failed
        await send(client: client)
    }
}

struct ChatView: View {
    @EnvironmentObject private var settings: AppSettings
    @StateObject private var vm = ChatViewModel()

    var body: some View {
        VStack(spacing: 0) {
            controlsBar
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        if vm.messages.isEmpty && vm.errorText == nil && !vm.isStreaming {
                            ContentUnavailableView(
                                "Ask anything",
                                systemImage: "bubble.left.and.bubble.right",
                                description: Text("Messages stream here. Toggle Search for the web, Brain for your notes.")
                            )
                            .padding(.top, 60)
                        }
                        ForEach(vm.messages) { msg in
                            messageBubble(msg)
                                .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: vm.messages.count) { proxy.scrollTo(vm.messages.last?.id, anchor: .bottom) }
            }
            if let err = vm.errorText {
                Button { Task { await vm.retry(client: AetherClient(settings: settings)) } } label: {
                    Text("Error: \(err). Tap to retry.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(8)
                }
            }
            inputBar
        }
        .navigationTitle("Chat")
        .task { await vm.loadModels(client: AetherClient(settings: settings)) }
    }

    private var controlsBar: some View {
        HStack(spacing: 10) {
            Picker("Model", selection: $vm.selectedModelId) {
                ForEach(vm.models, id: \.id) { m in
                    Text(m.name ?? m.id ?? "?").tag(m.id)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 4) {
                Text("Search").font(.caption).foregroundStyle(.secondary)
                Toggle("", isOn: $vm.searchEnabled).labelsHidden()
            }
            HStack(spacing: 4) {
                Text("Brain").font(.caption).foregroundStyle(.secondary)
                Toggle("", isOn: $vm.brainEnabled).labelsHidden()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isUser = msg.role == "user"
        return VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
            Text(msg.content ?? "")
                .padding(12)
                .background(isUser ? Color.accentColor.opacity(0.85) : Color.gray.opacity(0.18))
                .foregroundStyle(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            if let sources = msg.sources, !sources.isEmpty {
                ForEach(sources.indices, id: \.self) { i in
                    if let urlString = sources[i].url, let url = URL(string: urlString) {
                        Link(sources[i].title ?? urlString, destination: url)
                            .font(.caption)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    private var inputBar: some View {
        HStack {
            TextField("Message…", text: $vm.input, axis: .vertical)
                .textFieldStyle(.roundedBorder)
            Button {
                Task { await vm.send(client: AetherClient(settings: settings)) }
            } label: {
                Image(systemName: "arrow.up")
                    .padding(10)
            }
            .glassEffect(.regular, in: .circle)
            .disabled(vm.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || vm.isStreaming)
        }
        .padding()
    }
}
