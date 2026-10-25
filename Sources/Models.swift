import Foundation

// MARK: - Chat

struct ChatSource: Codable {
    var title: String?
    var url: String?

    enum CodingKeys: String, CodingKey { case title, url }

    init(title: String? = nil, url: String? = nil) {
        self.title = title
        self.url = url
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        url = try c.decodeIfPresent(String.self, forKey: .url)
    }
}

struct ChatMessage: Codable, Identifiable {
    var id = UUID()
    var role: String?
    var content: String?
    var sources: [ChatSource]?

    enum CodingKeys: String, CodingKey { case role, content, text, sources }

    init(role: String? = nil, content: String? = nil, sources: [ChatSource]? = nil) {
        self.role = role
        self.content = content
        self.sources = sources
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        role = try c.decodeIfPresent(String.self, forKey: .role)
        content = try c.decodeIfPresent(String.self, forKey: .content)
            ?? c.decodeIfPresent(String.self, forKey: .text)
        sources = try c.decodeIfPresent([ChatSource].self, forKey: .sources)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(role, forKey: .role)
        try c.encodeIfPresent(content, forKey: .content)
        try c.encodeIfPresent(sources, forKey: .sources)
    }
}

// MARK: - Research

struct ResearchRun: Codable, Identifiable {
    var id: String?
    var question: String?
    var status: String?
    var created_at: String?
    var updated_at: String?

    enum CodingKeys: String, CodingKey {
        case id, question, status, created_at, updated_at
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id)
        question = try c.decodeIfPresent(String.self, forKey: .question)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        created_at = try c.decodeIfPresent(String.self, forKey: .created_at)
        updated_at = try c.decodeIfPresent(String.self, forKey: .updated_at)
    }
}

struct ResearchClaim: Codable, Identifiable {
    var id = UUID()
    var claim: String?
    var text: String?
    var type: String?

    enum CodingKeys: String, CodingKey { case claim, text, type }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        claim = try c.decodeIfPresent(String.self, forKey: .claim)
        text = try c.decodeIfPresent(String.self, forKey: .text)
        type = try c.decodeIfPresent(String.self, forKey: .type)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(claim, forKey: .claim)
        try c.encodeIfPresent(text, forKey: .text)
        try c.encodeIfPresent(type, forKey: .type)
    }
}

struct ResearchDetail: Codable {
    var run: ResearchRun?
    var sources: [ChatSource]?
    var claims: [ResearchClaim]?

    enum CodingKeys: String, CodingKey { case run, sources, claims }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        run = try c.decodeIfPresent(ResearchRun.self, forKey: .run)
        sources = try c.decodeIfPresent([ChatSource].self, forKey: .sources)
        claims = try c.decodeIfPresent([ResearchClaim].self, forKey: .claims)
    }
}

// MARK: - Brain / Library

struct BrainNote: Codable, Identifiable {
    var id: String? { path }
    var path: String?
    var title: String?
    var updated_at: String?

    enum CodingKeys: String, CodingKey { case path, title, updated_at }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        path = try c.decodeIfPresent(String.self, forKey: .path)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        updated_at = try c.decodeIfPresent(String.self, forKey: .updated_at)
    }
}

struct BrainItem: Codable, Identifiable {
    var id: String?
    var title: String?
    var content: String?
    var source: String?
    var tags: [String]?

    enum CodingKeys: String, CodingKey { case id, title, content, body, source, tags }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        content = try c.decodeIfPresent(String.self, forKey: .content)
            ?? c.decodeIfPresent(String.self, forKey: .body)
        source = try c.decodeIfPresent(String.self, forKey: .source)
        tags = try c.decodeIfPresent([String].self, forKey: .tags)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(title, forKey: .title)
        try c.encodeIfPresent(content, forKey: .content)
        try c.encodeIfPresent(source, forKey: .source)
        try c.encodeIfPresent(tags, forKey: .tags)
    }
}

struct TagCount: Codable {
    var tag: String?
    var count: Int?

    enum CodingKeys: String, CodingKey { case tag, count }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        tag = try c.decodeIfPresent(String.self, forKey: .tag)
        count = try c.decodeIfPresent(Int.self, forKey: .count)
    }
}

// MARK: - Models / status

struct ModelInfo: Codable, Identifiable {
    var id: String?
    var name: String?

    enum CodingKeys: String, CodingKey { case id, name, model }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id)
            ?? c.decodeIfPresent(String.self, forKey: .model)
        name = try c.decodeIfPresent(String.self, forKey: .name)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
    }
}
