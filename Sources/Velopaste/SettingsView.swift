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
        VStack(alignment: .leading, spacing: 0) {
            Text("Settings").font(.title2).fontWeight(.semibold).padding(.horizontal, 20).padding(.top, 20)
            Form {
                Section("General") {
                    HStack {
                        Text("Keyboard shortcut")
                        Spacer()
                        Picker("Keyboard shortcut", selection: $store.shortcut) {
                            Text("⌥V").tag("⌥V")
                            Text("⌘⇧V").tag("⌘⇧V")
                            Text("⌃⌥V").tag("⌃⌥V")
                        }.labelsHidden().frame(width: 110)
                    }
                    HStack {
                        Text("History limit")
                        Spacer()
                        Picker("History limit", selection: $store.capacity) {
                            ForEach([25, 50, 100, 250], id: \.self) { Text("\($0) items").tag($0) }
                        }.labelsHidden().frame(width: 110)
                    }
                    Toggle("Open at login", isOn: $loginEnabled)
                        .onChange(of: loginEnabled) { enabled in
                            do {
                                if enabled { try SMAppService.mainApp.register() }
                                else { try SMAppService.mainApp.unregister() }
                            } catch {
                                loginEnabled = SMAppService.mainApp.status == .enabled
                                store.toast("Manage login items in System Settings")
                            }
                        }
                    HStack {
                        Text("Appearance")
                        Spacer()
                        Picker("Appearance", selection: $store.appearance) {
                            ForEach(["System", "Light", "Dark"], id: \.self) { Text($0).tag($0) }
                        }.labelsHidden().frame(width: 110)
                    }
                }
                Section {
                    Toggle("Paste directly into apps", isOn: $store.autoPaste)
                    Text("When direct paste is off, choose an item, then press ⌘V in your app.")
                        .font(.callout).foregroundStyle(.secondary)
                    if store.autoPaste && !trusted {
                        Button("Enable Accessibility…") { store.requestAccessibility() }
                        Text("Allow Velopaste in System Settings → Privacy & Security → Accessibility.")
                            .font(.callout).foregroundStyle(.secondary)
                    } else if trusted {
                        Label("Accessibility enabled", systemImage: "checkmark.circle.fill")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                } header: { Text("Pasting") }
                Section {
                    Toggle("Remember history", isOn: $store.remember)
                    Text("History is encrypted on this Mac using a key in your Keychain. Turning this off deletes saved history. Confidential copies are skipped when marked; unmarked secrets can still be captured.")
                        .font(.callout).foregroundStyle(.secondary)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Excluded apps")
                        Text("One app bundle identifier per line.").font(.callout).foregroundStyle(.secondary)
                        TextEditor(text: $store.excludedApps).font(.system(.callout, design: .monospaced))
                            .frame(height: 85).padding(6).scrollContentBackground(.hidden)
                            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 5))
                            .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(MacStyle.separator, lineWidth: 0.5))
                    }
                    Button("Delete All History…", role: .destructive) { confirmingDelete = true }
                } header: { Text("Privacy") }
                Section {
                    LabeledContent("Version", value: "1.1.0")
                    Text("Open source · MIT License").foregroundStyle(.secondary)
                    Link("View on GitHub", destination: URL(string: "https://github.com/phcodesage/velopaste")!)
                    Button("Quit Velopaste") { NSApp.terminate(nil) }
                } header: { Text("About Velopaste") }
            }.formStyle(.grouped).scrollContentBackground(.hidden)
        }.toggleStyle(.switch)
        .onReceive(refresh) { _ in trusted = AXIsProcessTrusted() }
        .alert("Delete all saved copies?", isPresented: $confirmingDelete) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Everything", role: .destructive) { store.deleteEverything() }
        } message: { Text("This also deletes pinned items. Your current system clipboard is kept.") }
    }
}
