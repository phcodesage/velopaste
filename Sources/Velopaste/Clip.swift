import Foundation
import CryptoKit

struct Clip: Identifiable, Codable, Equatable {
    enum Kind: String, Codable { case text, link, image }
    var id = UUID()
    var text: String
    var formats: [String: Data]
    var kind: Kind
    var sourceName: String
    var sourceBundleID: String
    var createdAt = Date()
    var pinned = false

    var fingerprint: String {
        // Text equality ignores presentation formats; image equality uses the actual pixels' representation.
        let data = kind == .image ? (formats["public.png"] ?? formats["public.tiff"] ?? Data()) : Data(text.utf8)
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
    var byteCount: Int { formats.values.reduce(0) { $0 + $1.count } }
    var isCode: Bool {
        text.contains("\n") && ["func ", "const ", "import ", "let ", "return ", "{", "</"].contains { text.contains($0) }
    }
    var hostname: String? { kind == .link ? URL(string: text)?.host : nil }
    var subtitle: String {
        if kind == .image { return "Image · \(ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file))" }
        if let hostname { return hostname }
        return "\(text.count.formatted()) characters"
    }
    static func classify(_ text: String) -> Kind {
        guard !text.contains(where: \.isWhitespace), let url = URL(string: text),
              ["https", "http"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else { return .text }
        return .link
    }
}

struct History {
    static let itemLimit = 4 * 1_024 * 1_024
    static let byteLimit = 32 * 1_024 * 1_024
    private(set) var items: [Clip] = []
    var capacity = 25

    init(items: [Clip] = [], capacity: Int = 25) {
        self.items = items
        self.capacity = capacity
        trim()
    }
    @discardableResult mutating func insert(_ clip: Clip) -> Bool {
        guard clip.byteCount <= Self.itemLimit, !clip.text.isEmpty || clip.kind == .image else { return false }
        var incoming = clip
        if let index = items.firstIndex(where: { $0.fingerprint == clip.fingerprint && $0.kind == clip.kind }) {
            incoming.id = items[index].id
            incoming.pinned = items[index].pinned
            items.remove(at: index)
        }
        items.insert(incoming, at: 0)
        trim()
        return items.contains { $0.id == incoming.id }
    }
    mutating func pin(_ id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].pinned.toggle()
        trim()
    }
    mutating func remove(_ id: UUID) { items.removeAll { $0.id == id } }
    mutating func clear(keepingPins: Bool = true) { items.removeAll { !keepingPins || !$0.pinned } }
    mutating func trim() {
        while items.count > capacity || items.reduce(0, { $0 + $1.byteCount }) > Self.byteLimit {
            guard let index = items.lastIndex(where: { !$0.pinned }) else { break }
            items.remove(at: index)
        }
    }
    func filtered(query: String, filter: ClipFilter) -> [Clip] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return items.filter { clip in
            let matches = needle.isEmpty || clip.text.localizedCaseInsensitiveContains(needle) || clip.sourceName.localizedCaseInsensitiveContains(needle)
            return matches && (filter == .all || (filter == .pinned && clip.pinned) || (filter == .images && clip.kind == .image) || (filter == .links && clip.kind == .link))
        }
    }
}

enum ClipFilter: String, CaseIterable {
    case all = "All", pinned = "Pinned", images = "Images", links = "Links"
    var icon: String {
        switch self { case .all: return "square.stack"; case .pinned: return "pin"; case .images: return "photo"; case .links: return "link" }
    }
}
