import Foundation

enum APIError: Error, LocalizedError {
    case badURL
    case badStatus(Int, String)
    case streamError(String)

    var errorDescription: String? {
        switch self {
        case .badURL: return "Bad URL"
        case .badStatus(let code, let body): return "HTTP \(code): \(body.prefix(200))"
        case .streamError(let msg): return msg
        }
    }
}

/// JSON client for the Aether backend. All paths live under /api/.
/// Sends `Authorization: Bearer <key>` on every request when a key is set.
struct AetherClient {
    let settings: AppSettings

    private func makeRequest(path: String, method: String, query: [String: String] = [:], body: Data? = nil) throws -> URLRequest {
        var urlString = settings.normalizedBaseURL + path
        if !query.isEmpty {
            var comps = URLComponents(string: urlString) ?? URLComponents()
            comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
            urlString = comps.url?.absoluteString ?? urlString
        }
        guard let url = URL(string: urlString) else { throw APIError.badURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil { req.setValue("application/json", forHTTPHeaderField: "Content-Type") }
        req.httpBody = body
        let key = settings.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !key.isEmpty { req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization") }
        return req
    }

    private func decodeEnvelope<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        if let direct = try? decoder.decode(T.self, from: data) { return direct }
        // Tolerate {data: ...} / {result: ...} / {items: ...} wrappers.
        if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for key in ["data", "result", "items", "models", "notes", "runs"] {
                if let inner = obj[key], JSONSerialization.isValidJSONObject(inner) || inner is [Any] {
                    let innerData = try JSONSerialization.data(withJSONObject: inner)
                    if let val = try? decoder.decode(T.self, from: innerData) { return val }
                }
            }
        }
        return try decoder.decode(T.self, from: data)
    }

    func get<T: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> T {
        let req = try makeRequest(path: path, method: "GET", query: query)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw APIError.badStatus(code, String(data: data, encoding: .utf8) ?? "")
        }
        return try decodeEnvelope(T.self, from: data)
    }

    func post<Body: Encodable, Res: Decodable>(_ path: String, body: Body) async throws -> Res {
        let payload = try JSONEncoder().encode(body)
        let req = try makeRequest(path: path, method: "POST", body: payload)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw APIError.badStatus(code, String(data: data, encoding: .utf8) ?? "")
        }
        if Res.self == EmptyResponse.self { return EmptyResponse() as! Res }
        return try decodeEnvelope(Res.self, from: data)
    }

    /// Raw pretty-printed JSON string for status screens.
    func getRaw(_ path: String) async throws -> String {
        let req = try makeRequest(path: path, method: "GET")
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw APIError.badStatus(code, String(data: data, encoding: .utf8) ?? "")
        }
        if let obj = try? JSONSerialization.jsonObject(with: data),
           let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: pretty, encoding: .utf8) {
            return str
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    // MARK: - Endpoints

    func fetchModels() async throws -> [ModelInfo] {
        (try? await get([ModelInfo].self, "/api/models")) ?? []
    }

    private func get<T: Decodable>(_ type: T.Type, _ path: String, query: [String: String] = [:]) async throws -> T {
        try await get(path, query: query)
    }

    func listResearch(limit: Int = 20) async throws -> [ResearchRun] {
        (try? await get([ResearchRun].self, "/api/research", query: ["limit": "\(limit)"])) ?? []
    }

    func createResearch(question: String) async throws -> ResearchRun {
        try await post("/api/research", body: ["question": question])
    }

    func fetchResearch(id: String) async throws -> ResearchDetail {
        try await get("/api/research/\(id)")
    }

    func listNotes(limit: Int = 100) async throws -> [BrainNote] {
        (try? await get([BrainNote].self, "/api/brain/notes", query: ["limit": "\(limit)"])) ?? []
    }

    func fetchNote(path: String) async throws -> String {
        let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        return try await getRaw("/api/brain/notes/\(encoded)")
    }

    func listInbox() async throws -> [BrainItem] {
        (try? await get([BrainItem].self, "/api/brain/inbox")) ?? []
    }

    func dismissInbox(id: String) async throws {
        let req = try makeRequest(path: "/api/brain/inbox/\(id)", method: "DELETE")
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw APIError.badStatus(code, String(data: data, encoding: .utf8) ?? "")
        }
    }

    func listTags() async throws -> [TagCount] {
        (try? await get([TagCount].self, "/api/brain/tags")) ?? []
    }

    func captureNote(title: String, body: String, tags: [String]) async throws {
        struct Payload: Encodable { var title: String; var content: String; var tags: [String]; var source: String }
        let _: EmptyResponse = try await post("/api/brain/notes", body: Payload(title: title, content: body, tags: tags, source: "ios"))
    }

    // MARK: - Streaming chat (SSE)

    struct ChatRequest: Encodable {
        var model: String
        var content: String
        var stream: Bool = true
        var search: Bool
        var brain: Bool
        var conversation_id: String?
        var client_msg_id: String
    }

    /// Streams assistant tokens. SSE `data:` lines may carry:
    /// start / token (or delta/text) / done / error events.
    /// Throws on error events.
    func streamChat(model: String, content: String, search: Bool, brain: Bool, conversationId: String?) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let payload = ChatRequest(model: model, content: content, search: search, brain: brain, conversationId: conversationId, client_msg_id: UUID().uuidString)
                    let body = try JSONEncoder().encode(payload)
                    let req = try makeRequest(path: "/api/chat", method: "POST", body: body)
                    let (bytes, resp) = try await URLSession.shared.bytes(for: req)
                    let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
                    guard (200..<300).contains(code) else {
                        throw APIError.badStatus(code, "")
                    }
                    for try await line in bytes.lines {
                        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard trimmed.hasPrefix("data:") else { continue }
                        let payloadStr = trimmed.dropFirst(5).trimmingCharacters(in: .whitespaces)
                        if payloadStr == "[DONE]" { continuation.finish(); return }
                        guard let d = payloadStr.data(using: .utf8),
                              let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any] else { continue }
                        let event = (obj["event"] as? String) ?? (obj["type"] as? String) ?? ""
                        switch event {
                        case "start":
                            continue
                        case "token", "delta", "text", "message":
                            let token = (obj["token"] as? String) ?? (obj["delta"] as? String)
                                ?? (obj["text"] as? String) ?? (obj["content"] as? String) ?? ""
                            if !token.isEmpty { continuation.yield(token) }
                        case "done", "complete", "stop":
                            continuation.finish()
                            return
                        case "error", "fail":
                            let msg = (obj["error"] as? String) ?? (obj["message"] as? String) ?? "Stream error"
                            continuation.finish(throwing: APIError.streamError(msg))
                            return
                        default:
                            // Tolerate raw token shapes: {"token": "..."} with no event name.
                            let token = (obj["token"] as? String) ?? (obj["delta"] as? String) ?? (obj["text"] as? String)
                            if let t = token, !t.isEmpty { continuation.yield(t) }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}

struct EmptyResponse: Codable {}
