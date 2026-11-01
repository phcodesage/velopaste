import AppKit
import SwiftUI
import ApplicationServices

@main
struct VelopasteMain {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }
}

final class ClipboardPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var store: ClipboardStore!
    private var panel: ClipboardPanel!
    private var statusItem: NSStatusItem!
    private var hotKey: HotKey?
    private var keyMonitor: Any?
    private var previousApp: NSRunningApplication?
    private let smoke = CommandLine.arguments.contains("--smoke-test")
    private let preview = CommandLine.arguments.contains("--preview")

    func applicationDidFinishLaunching(_ notification: Notification) {
        store = ClipboardStore(preview: preview, sessionOnly: smoke)
        let content = PanelView(store: store)
        panel = ClipboardPanel(contentRect: NSRect(x: 0, y: 0, width: 410, height: 640), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.title = "Velopaste"
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.animationBehavior = .utilityWindow
        panel.delegate = self
        panel.contentView = NSHostingView(rootView: content)
        store.dismiss = { [weak self] in self?.hide() }
        store.choose = { [weak self] clip, plain in self?.choose(clip, plain: plain) }
        if !preview {
            setupMenuBar()
            hotKey = HotKey()
            hotKey?.onPress = { [weak self] in self?.toggle() }
            store.shortcutChanged = { [weak self] in self?.registerShortcut() }
            registerShortcut()
        }
        setupKeyboard()
        if preview || (!smoke && !store.preferences.bool(forKey: "hasLaunched")) {
            show(centered: true)
            if !preview { store.preferences.set(true, forKey: "hasLaunched") }
        }
        if preview, let flagIndex = CommandLine.arguments.firstIndex(of: "--snapshot"), CommandLine.arguments.count > flagIndex + 1 {
            let destination = CommandLine.arguments[flagIndex + 1]
            if CommandLine.arguments.contains("--dark") { store.appearance = "Dark" }
            if CommandLine.arguments.contains("--settings") { store.showingSettings = true }
            if CommandLine.arguments.contains("--emoji") { store.mode = .emoji }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.snapshot(to: destination) }
        }
    }
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Velopaste clipboard history")
            button.image?.isTemplate = true
            button.toolTip = "Velopaste · \(store.shortcut)"
            button.target = self
            button.action = #selector(statusClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    private func registerShortcut() {
        store.shortcutWarning = hotKey?.register(store.shortcut) == true ? nil : "This shortcut is in use. Choose another in Settings."
        statusItem?.button?.toolTip = "Velopaste · \(store.shortcut)"
    }
    @objc private func statusClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(withTitle: "Open Velopaste", action: #selector(openFromMenu), keyEquivalent: "")
            menu.addItem(withTitle: store.isPaused ? "Resume history" : "Pause history", action: #selector(togglePause), keyEquivalent: "")
            menu.addItem(.separator())
            menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
            menu.addItem(withTitle: "Quit Velopaste", action: #selector(quit), keyEquivalent: "q")
            for item in menu.items { item.target = self }
            if let button = statusItem.button { menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.minY), in: button) }
        } else { toggle(fromMenuBar: true) }
    }
    @objc private func openFromMenu() { show(fromMenuBar: true) }
    @objc private func togglePause() { store.isPaused.toggle() }
    @objc private func openSettings() { store.showingSettings = true; show(fromMenuBar: true) }
    @objc private func quit() { NSApp.terminate(nil) }
    private func toggle(fromMenuBar: Bool = false) {
        if panel.isVisible { hide() } else { show(fromMenuBar: fromMenuBar) }
    }
    private func show(fromMenuBar: Bool = false, centered: Bool = false) {
        if !panel.isVisible {
            let front = NSWorkspace.shared.frontmostApplication
            if front?.processIdentifier != ProcessInfo.processInfo.processIdentifier { previousApp = front }
        }
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) ?? NSScreen.main
        if let visible = screen?.visibleFrame {
            let width = panel.frame.width
            let height = panel.frame.height
            var x = mouse.x - 30
            var y = mouse.y - height - 15
            if centered {
                x = visible.midX - width / 2
                y = visible.midY - height / 2
            } else if fromMenuBar, let frame = statusItem?.button?.window?.frame {
                x = frame.midX - width / 2
                y = visible.maxY - height - 8
            }
            panel.setFrameOrigin(NSPoint(x: max(visible.minX + 8, min(x, visible.maxX - width - 8)), y: max(visible.minY + 8, min(y, visible.maxY - height - 8))))
        }
        store.selectedID = nil
        panel.makeKeyAndOrderFront(nil)
        NotificationCenter.default.post(name: .panelOpened, object: nil)
    }
    private func hide() {
        panel.orderOut(nil)
        store.query = ""
    }
    func windowDidResignKey(_ notification: Notification) {
        guard !preview else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, !self.panel.isKeyWindow, self.panel.attachedSheet == nil else { return }
            if NSApp.keyWindow?.parent == self.panel { return }
            self.hide()
        }
    }
    private func choose(_ clip: Clip, plain: Bool) {
        guard store.copy(clip, plain: plain) else { return }
        let shouldPaste = store.pasteEnabled
        let target = previousApp
        hide()
        guard let target, !target.isTerminated else { return }
        target.activate(options: [])
        if shouldPaste {
            // Wait for the chosen application's focus to return, then verify the recipient before posting.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                guard NSWorkspace.shared.frontmostApplication?.processIdentifier == target.processIdentifier,
                      AXIsProcessTrusted(), let source = CGEventSource(stateID: .combinedSessionState),
                      let down = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
                      let up = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else { return }
                down.flags = .maskCommand
                up.flags = .maskCommand
                down.post(tap: .cghidEventTap)
                up.post(tap: .cghidEventTap)
            }
        }
    }
    private func setupKeyboard() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel.isVisible, self.panel.isKeyWindow else { return event }
            if event.keyCode == 53 {
                if self.store.showingSettings { self.store.showingSettings = false }
                else { self.hide() }
                return nil
            }
            if self.store.showingSettings || self.store.mode != .clipboard { return event }
            let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
            if modifiers.contains(.command), let number = Int(event.charactersIgnoringModifiers ?? ""), (1...9).contains(number), number <= self.store.items.count {
                self.choose(self.store.items[number - 1], plain: modifiers.contains(.shift))
                return nil
            }
            if modifiers.isEmpty && (event.keyCode == 125 || event.keyCode == 126) {
                self.store.moveSelection(event.keyCode == 125 ? 1 : -1)
                return nil
            }
            if (event.keyCode == 36 || event.keyCode == 76), !modifiers.contains(.command), let clip = self.store.selected {
                self.choose(clip, plain: modifiers.contains(.shift))
                return nil
            }
            if modifiers.contains(.command), event.charactersIgnoringModifiers == "," {
                self.store.showingSettings = true
                return nil
            }
            return event
        }
    }
    private func snapshot(to path: String) {
        guard let view = panel.contentView, let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { NSApp.terminate(nil); return }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        if let bytes = bitmap.representation(using: .png, properties: [:]) { try? bytes.write(to: URL(fileURLWithPath: path)) }
        NSApp.terminate(nil)
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        show(centered: true)
        return true
    }
    func applicationWillTerminate(_ notification: Notification) {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        store.flush()
    }
}
