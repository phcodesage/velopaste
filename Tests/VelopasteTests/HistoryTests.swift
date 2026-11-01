import XCTest
import CryptoKit
@testable import Velopaste

final class HistoryTests: XCTestCase {
    private func clip(_ text: String, pinned: Bool = false, source: String = "Notes") -> Clip {
        Clip(text: text, formats: ["public.utf8-plain-text": Data(text.utf8)], kind: Clip.classify(text), sourceName: source, sourceBundleID: "test.notes", pinned: pinned)
    }
    func testRecencyAndDuplicatePreservesPinAndIdentity() {
        var history = History()
        let original = clip("Keep me", pinned: true)
        history.insert(original)
        history.insert(clip("Another item"))
        history.insert(clip("Keep me"))
        XCTAssertEqual(history.items.count, 2)
        XCTAssertEqual(history.items.first?.id, original.id)
        XCTAssertEqual(history.items.first?.pinned, true)
    }
    func testClearPreservesPinsAndDeleteEverythingRemovesThem() {
        var history = History(items: [clip("Pinned", pinned: true), clip("Recent")])
        history.clear()
        XCTAssertEqual(history.items.map(\.text), ["Pinned"])
        history.clear(keepingPins: false)
        XCTAssertTrue(history.items.isEmpty)
    }
    func testEvictionRemovesOldestUnpinned() {
        var history = History(capacity: 2)
        history.insert(clip("Pinned", pinned: true))
        history.insert(clip("Old"))
        history.insert(clip("New"))
        XCTAssertEqual(history.items.map(\.text), ["New", "Pinned"])
    }
    func testAllPinnedHistoryRejectsIncomingWithoutRemovingPins() {
        var history = History(items: [clip("A", pinned: true), clip("B", pinned: true)], capacity: 2)
        XCTAssertFalse(history.insert(clip("New")))
        XCTAssertEqual(history.items.map(\.text), ["A", "B"])
    }
    func testOversizeAndEmptyCopiesAreRejected() {
        var history = History()
        var huge = clip("Large")
        huge.formats = ["public.png": Data(repeating: 7, count: History.itemLimit + 1)]
        XCTAssertFalse(history.insert(huge))
        XCTAssertFalse(history.insert(clip("")))
        XCTAssertTrue(history.items.isEmpty)
    }
    func testByteBudgetEvictsOldCopies() {
        var history = History(capacity: 250)
        for number in 0..<12 {
            var image = clip("Image \(number)")
            image.kind = .image
            image.formats = ["public.png": Data(repeating: UInt8(number), count: History.itemLimit)]
            history.insert(image)
        }
        XCTAssertEqual(history.items.count, 8)
        XCTAssertLessThanOrEqual(history.items.reduce(0) { $0 + $1.byteCount }, History.byteLimit)
    }
    func testSearchByTextAndSourceCombinedWithFilter() {
        let history = History(items: [clip("Design system", pinned: true), clip("https://example.com", source: "Safari"), clip("Another")])
        XCTAssertEqual(history.filtered(query: "DESIGN", filter: .pinned).count, 1)
        XCTAssertEqual(history.filtered(query: "safari", filter: .links).count, 1)
        XCTAssertEqual(history.filtered(query: "Design", filter: .images).count, 0)
        XCTAssertEqual(history.filtered(query: "  ", filter: .all).count, 3)
    }
    func testURLClassification() {
        XCTAssertEqual(Clip.classify("https://example.com/path?q=1"), .link)
        XCTAssertEqual(Clip.classify("http://localhost:8080"), .link)
        for text in ["hello", "A link https://example.com", "https://example.com\n", "file:///tmp/file", "https://", "javascript:alert(1)"] {
            XCTAssertEqual(Clip.classify(text), .text, text)
        }
    }
    func testRichTextSurvivesCodableRoundTrip() throws {
        var rich = clip("Formatted text")
        rich.formats["public.rtf"] = Data("{\\rtf1 Formatted text}".utf8)
        rich.formats["public.html"] = Data("<b>Formatted text</b>".utf8)
        let decoded = try JSONDecoder().decode([Clip].self, from: JSONEncoder().encode([rich]))
        XCTAssertEqual(decoded, [rich])
    }
    func testPinningAndDeleting() {
        let item = clip("Item")
        var history = History(items: [item])
        history.pin(item.id)
        XCTAssertTrue(history.items[0].pinned)
        history.pin(item.id)
        XCTAssertFalse(history.items[0].pinned)
        history.remove(item.id)
        XCTAssertTrue(history.items.isEmpty)
    }
    func testLoweringCapacityKeepsPinsAndTrimsOnUnpin() {
        let a = clip("A", pinned: true), b = clip("B", pinned: true)
        var history = History(items: [a, b, clip("C")], capacity: 3)
        history.capacity = 1
        history.trim()
        XCTAssertEqual(history.items.count, 2)
        history.pin(b.id)
        XCTAssertEqual(history.items.map(\.text), ["A"])
    }
    func testEmojiAndSymbolCatalogHasUniqueValuesAndSearchLabels() {
        for catalog in [CharacterPicker.emoji, CharacterPicker.symbols] {
            XCTAssertEqual(Set(catalog.map(\.value)).count, catalog.count)
            XCTAssertTrue(catalog.allSatisfy { !$0.keywords.isEmpty })
        }
    }
}
