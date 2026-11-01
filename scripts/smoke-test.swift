import AppKit
import ApplicationServices

// Uses an isolated in-memory Velopaste session and restores the system clipboard afterward.
// Requires the invoking terminal/agent to have Accessibility permission for synthesized keys.
let app = NSApplication.shared
app.setActivationPolicy(.regular)
let mainMenu = NSMenu()
let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
let editMenu = NSMenu(title: "Edit")
editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
editItem.submenu = editMenu
mainMenu.addItem(editItem)
app.mainMenu = mainMenu
let board = NSPasteboard.general
let backup: [[NSPasteboard.PasteboardType: Data]] = (board.pasteboardItems ?? []).map { item in
    Dictionary(uniqueKeysWithValues: item.types.compactMap { type in item.data(forType: type).map { (type, $0) } })
}
let helper = Process()
helper.executableURL = URL(fileURLWithPath: CommandLine.arguments[1] + "/Contents/MacOS/Velopaste")
helper.arguments = ["--smoke-test"]
let window = NSWindow(contentRect: NSRect(x: 90, y: 100, width: 480, height: 200), styleMask: [.titled], backing: .buffered, defer: false)
window.title = "Velopaste paste verification"
let editor = NSTextView(frame: NSRect(x: 20, y: 20, width: 440, height: 160))
editor.isRichText = false
window.contentView?.addSubview(editor)
window.makeKeyAndOrderFront(nil)
window.makeFirstResponder(editor)
app.activate(ignoringOtherApps: true)
let fixture = "Velopaste end-to-end paste verified."
func press(_ code: CGKeyCode, flags: CGEventFlags = []) {
    for down in [true, false] {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: down)!
        event.flags = flags
        event.post(tap: .cghidEventTap)
    }
}
func finish(_ passed: Bool, _ detail: String) {
    if helper.isRunning { helper.terminate(); helper.waitUntilExit() }
    board.clearContents()
    let restored = backup.map { formats -> NSPasteboardItem in
        let item = NSPasteboardItem()
        for (type, bytes) in formats { item.setData(bytes, forType: type) }
        return item
    }
    if !restored.isEmpty { board.writeObjects(restored) }
    print((passed ? "PASS: " : "FAIL: ") + detail)
    exit(passed ? 0 : 1)
}
do { try helper.run() } catch { finish(false, "Couldn't launch the app") }
DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
    window.makeKeyAndOrderFront(nil)
    app.activate(ignoringOtherApps: true)
    window.makeFirstResponder(editor)
    board.clearContents()
    board.setString(fixture, forType: .string)
}
DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
    board.clearContents()
    board.setString("A newer clipboard fixture", forType: .string)
}
DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { press(9, flags: .maskAlternate) }
DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
    let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
    let visible = windows.contains { ($0[kCGWindowOwnerPID as String] as? Int32) == helper.processIdentifier && ($0[kCGWindowLayer as String] as? Int) == 3 }
    guard visible else { finish(false, "Global shortcut didn't show the panel"); return }
    print("PASS: Option+V opened the floating panel")
    press(125, flags: [.maskSecondaryFn, .maskNumericPad])
    press(125, flags: [.maskSecondaryFn, .maskNumericPad])
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { press(36) }
}
DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
    let copied = board.string(forType: .string) == fixture && board.string(forType: .init("app.velopaste.restored")) == "1"
    guard copied else { finish(false, "Return didn't select the clipboard fixture"); return }
    if AXIsProcessTrusted() {
        guard editor.string == fixture else { finish(false, "Arrow selection didn't paste into the previous app"); return }
        print("PASS: History capture → global shortcut → arrow selection → Return → paste into the previous app")
        editor.string = ""
        press(9, flags: .maskAlternate)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            press(3, flags: .maskCommand) // Command+F focuses the native search field.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                let units = Array("verified".utf16)
                units.withUnsafeBufferPointer { buffer in
                    for down in [true, false] {
                        let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: down)!
                        event.flags = []
                        event.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress!)
                        event.post(tap: .cghidEventTap)
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { press(36) }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            finish(editor.string == fixture, "Command+F → native search filtering → Return → paste matching history item")
        }
    } else {
        finish(true, "History capture → global shortcut → arrow selection → Return → copy. Direct paste requires Accessibility.")
    }
}
app.run()
