import SwiftUI
import Combine
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var store: ClipboardStore
    @State private var loginEnabled = SMAppService.mainApp.status == .enabled
    @State private var confirmingDelete = false
    @State private var trusted = AXIsProcessTrusted()
    private let refresh = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Make it yours.").font(.system(size: 25, weight: .bold)).tracking(-0.8)
                    Text("A few small settings. A smoother flow.").font(.system(size: 11)).foregroundStyle(.secondary)
                }
                section("YOUR WORKFLOW") {
                    HStack {
                        Label("Open clipboard", systemImage: "keyboard")
                        Spacer()
                        Picker("Shortcut", selection: $store.shortcut) {
                            Text("⌥V").tag("⌥V")
                            Text("⌘⇧V").tag("⌘⇧V")
                            Text("⌃⌥V").tag("⌃⌥V")
                        }.labelsHidden().frame(width: 108)
                    }
                    Divider()
                    HStack {
                        Label("History size", systemImage: "square.stack")
                        Spacer()
                        Picker("History size", selection: $store.capacity) {
                            ForEach([25, 50, 100, 250], id: \.self) { Text("\($0) items").tag($0) }
                        }.labelsHidden().frame(width: 108)
                    }
                    Divider()
                    Toggle(isOn: $loginEnabled) { HStack { Label("Open at login", systemImage: "sunrise"); Spacer() } }
                        .onChange(of: loginEnabled) { enabled in
                            do {
                                if enabled { try SMAppService.mainApp.register() }
                                else { try SMAppService.mainApp.unregister() }
                            } catch {
                                loginEnabled = SMAppService.mainApp.status == .enabled
                                store.toast("Manage login items in System Settings")
                            }
                        }
                }
                section("LOOK & FEEL") {
                    HStack {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                        Spacer()
                        Picker("Appearance", selection: $store.appearance) {
                            ForEach(["System", "Light", "Dark"], id: \.self) { Text($0).tag($0) }
                        }.labelsHidden().frame(width: 108)
                    }
                }
                section("PASTE YOUR WAY") {
                    Toggle(isOn: $store.autoPaste) { HStack { Label("Paste directly into apps", systemImage: "arrow.turn.down.left"); Spacer() } }
                    Text("Without direct paste, choosing an item copies it. Press ⌘V in your app to paste.")
                        .font(.system(size: 10)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    if store.autoPaste && !trusted {
                        Button { store.requestAccessibility() } label: {
                            HStack { Image(systemName: "hand.raised"); Text("Enable Accessibility"); Spacer(); Image(systemName: "arrow.up.right") }
                                .font(.system(size: 11, weight: .semibold))
                        }.buttonStyle(.borderless)
                        Text("Allow Velopaste in System Settings → Privacy & Security → Accessibility.")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                    } else if trusted {
                        Label("Accessibility is enabled", systemImage: "checkmark.circle.fill").font(.system(size: 10)).foregroundStyle(.green)
                    }
                }
                section("PRIVATE BY DESIGN") {
                    Toggle(isOn: $store.remember) { HStack { Label("Remember history after quitting", systemImage: "lock.shield"); Spacer() } }
                    Text("Saved history is encrypted on this Mac with a key in your Keychain. Turning this off deletes the saved history file. Marked confidential copies are skipped; unmarked secrets can still be captured.")
                        .font(.system(size: 10)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Divider()
                    Text("Ignore these apps").font(.system(size: 11, weight: .medium))
                    Text("One app bundle identifier per line.").font(.system(size: 10)).foregroundStyle(.secondary)
                    TextEditor(text: $store.excludedApps).font(.system(size: 10, design: .monospaced))
                        .scrollContentBackground(.hidden).padding(6).frame(height: 76)
                        .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 7))
                    Divider()
                    Button("Delete all history, including pins…", role: .destructive) { confirmingDelete = true }
                        .buttonStyle(.borderless).font(.system(size: 11))
                }
                VStack(spacing: 7) {
                    Text("Velopaste 1.0.0").font(.system(size: 11, weight: .semibold))
                    Text("Open source · MIT licensed · Works offline").font(.system(size: 10)).foregroundStyle(.secondary)
                    Button("Quit Velopaste") { NSApp.terminate(nil) }.buttonStyle(.borderless).font(.system(size: 10)).padding(.top, 3)
                }.frame(maxWidth: .infinity).padding(.bottom, 12)
            }.padding(.horizontal, 22).padding(.top, 8).padding(.bottom, 16)
        }.toggleStyle(.switch).controlSize(.small)
        .onReceive(refresh) { _ in trusted = AXIsProcessTrusted() }
        .alert("Delete all saved copies?", isPresented: $confirmingDelete) {
            Button("Cancel", role: .cancel) { }
            Button("Delete everything", role: .destructive) { store.deleteEverything() }
        } message: { Text("This also deletes pinned items. Your current system clipboard is kept.") }
    }
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 8, weight: .bold)).tracking(1.3).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10, content: content)
                .font(.system(size: 11)).padding(13).frame(maxWidth: .infinity, alignment: .leading)
                .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
