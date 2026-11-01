import SwiftUI
import AppKit

// Semantic macOS colors adapt to appearance and contrast; system blue replaces the brand palette.
enum MacStyle {
    static let accent = Color(nsColor: .systemBlue)
    static let surface = Color(nsColor: .controlBackgroundColor)
    static let separator = Color(nsColor: .separatorColor)
}

struct PanelView: View {
    @ObservedObject var store: ClipboardStore
    @State private var searchFocus = UUID()
    @State private var confirmingClear = false

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if store.showingSettings { SettingsView(store: store) }
            else { workspace }
            footer
        }
        .frame(width: 410, height: 640)
        .font(.body)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(MacStyle.separator.opacity(0.5), lineWidth: 0.5))
        .tint(MacStyle.accent)
        .accentColor(MacStyle.accent)
        .preferredColorScheme(store.colorScheme)
        .onReceive(NotificationCenter.default.publisher(for: .panelOpened)) { _ in searchFocus = UUID() }
        .onReceive(NotificationCenter.default.publisher(for: .focusClipboardSearch)) { _ in searchFocus = UUID() }
        .alert("Clear clipboard history?", isPresented: $confirmingClear) {
            Button("Cancel", role: .cancel) { }
            Button("Clear History", role: .destructive) { store.clear() }
        } message: { Text("Unpinned items will be deleted. Your pinned items and current system clipboard are kept.") }
    }
    private var toolbar: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard").font(.title3).foregroundStyle(.secondary)
            Text("Velopaste").font(.headline)
            Spacer()
            Button { store.dismiss?() } label: {
                Image(systemName: "xmark.circle.fill").symbolRenderingMode(.hierarchical).font(.title3)
            }.buttonStyle(.borderless).foregroundStyle(.secondary).help("Close · Esc").accessibilityLabel("Close panel")
        }.padding(.horizontal, 16).frame(height: 48)
    }
    private var workspace: some View {
        VStack(spacing: 12) {
            Picker("Content", selection: $store.mode) {
                ForEach(ClipboardStore.PanelMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }.labelsHidden().pickerStyle(.segmented)
                .padding(.horizontal, 16).padding(.top, 16)
                .onChange(of: store.mode) { _ in store.query = ""; searchFocus = UUID() }
            HStack {
                Text(store.mode == .clipboard ? "Clipboard History" : store.mode.rawValue).font(.title2).fontWeight(.semibold)
                Spacer()
                if store.mode == .clipboard {
                    Button("Clear All…") { confirmingClear = true }
                        .buttonStyle(.borderless)
                        .disabled(!store.history.items.contains { !$0.pinned })
                }
            }.padding(.horizontal, 16).padding(.top, 4)
            NativeSearchField(text: $store.query, placeholder: store.mode == .clipboard ? "Search clipboard history" : "Search \(store.mode.rawValue.lowercased())", focusToken: searchFocus)
                .frame(height: 28).padding(.horizontal, 16)
            if store.mode == .clipboard {
                Picker("Filter", selection: $store.filter) {
                    ForEach(ClipFilter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }.labelsHidden().pickerStyle(.segmented).controlSize(.small).padding(.horizontal, 16)
                clipboardContent
            } else {
                CharacterPicker(store: store)
            }
        }
        .onChange(of: store.query) { _ in store.selectedID = nil }
        .onChange(of: store.filter) { _ in store.selectedID = nil }

    }
    private var clipboardContent: some View {
        Group {
            if store.items.isEmpty { emptyState }
            else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            HStack {
                                Text(store.filter == .pinned ? "Pinned" : store.query.isEmpty ? "Recent" : "Results")
                                Spacer()
                                Text("\(store.items.count) \(store.items.count == 1 ? "item" : "items")")
                            }.font(.caption).foregroundStyle(.secondary).padding(.horizontal, 2).padding(.bottom, 2)
                            ForEach(Array(store.items.enumerated()), id: \.element.id) { index, clip in
                                ClipCard(clip: clip, index: index, selected: clip.id == store.selectedID, store: store).id(clip.id)
                            }
                        }.padding(.horizontal, 16).padding(.bottom, 12)
                    }.onChange(of: store.selectedID) { id in
                        if let id { withAnimation(.easeOut(duration: 0.15)) { proxy.scrollTo(id, anchor: .center) } }
                    }
                }
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: store.query.isEmpty ? (store.filter == .pinned ? "pin" : "doc.on.clipboard") : "magnifyingglass")
                .font(.system(size: 40, weight: .regular)).foregroundStyle(.secondary).padding(.bottom, 4)
            Text(store.query.isEmpty ? store.filter == .all ? "No Clipboard History" : "No \(store.filter.rawValue) Items" : "No Results")
                .font(.headline)
            Text(store.query.isEmpty ? (store.filter == .pinned ? "Pin an item to keep it when you clear your history." : "Copy text or an image, then press \(store.shortcut)\nto find it here.") : "Try a different search or source app.")
                .foregroundStyle(.secondary).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            if store.filter == .all && store.query.isEmpty {
                Label("History stays on this Mac", systemImage: "lock.shield").font(.caption).foregroundStyle(.secondary).padding(.top, 4)
            }
            Spacer()
        }.padding(24).frame(maxWidth: .infinity)
    }
    private var footer: some View {
        VStack(spacing: 0) {
            if let warning = store.storageWarning ?? store.shortcutWarning {
                Label(warning, systemImage: "exclamationmark.triangle.fill").font(.caption).foregroundStyle(Color(nsColor: .systemOrange)).padding(12)
            }
            if let notice = store.notice { Text(notice).font(.callout).foregroundStyle(.secondary).padding(.bottom, 8) }
            Divider()
            HStack(spacing: 8) {
                Button { store.isPaused.toggle() } label: {
                    HStack(spacing: 5) {
                        Image(systemName: store.isPaused ? "pause.circle.fill" : "circle.fill")
                            .font(.system(size: store.isPaused ? 11 : 6))
                            .foregroundStyle(Color(nsColor: store.isPaused ? .systemOrange : .systemGreen))
                        Text(store.isPaused ? "Paused" : "Listening")
                    }
                }.buttonStyle(.borderless).foregroundStyle(.secondary).help("Pause or resume clipboard history")
                Spacer(minLength: 4)
                if !store.showingSettings { Text(store.pasteEnabled ? "↵ Paste  ↑↓ Select" : "↵ Copy  ⌘V Paste").foregroundStyle(.secondary) }
                Spacer(minLength: 4)
                Text(store.shortcut).foregroundStyle(.secondary)
                Button { store.showingSettings.toggle() } label: {
                    Image(systemName: store.showingSettings ? "chevron.left" : "gearshape").font(.body)
                }.buttonStyle(.borderless).foregroundStyle(.secondary).help(store.showingSettings ? "Back to clipboard" : "Settings").accessibilityLabel("Settings")
            }.font(.caption).padding(.horizontal, 16).frame(height: 40)
        }
    }
}

/// NSSearchField supplies macOS typography, focus ring, clear button, and keyboard editing.
struct NativeSearchField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let focusToken: UUID

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }
    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField()
        field.delegate = context.coordinator
        field.controlSize = .regular
        field.font = .systemFont(ofSize: NSFont.systemFontSize)
        field.sendsSearchStringImmediately = true
        field.sendsWholeSearchString = false
        return field
    }
    func updateNSView(_ field: NSSearchField, context: Context) {
        context.coordinator.text = $text
        if field.stringValue != text { field.stringValue = text }
        field.placeholderString = placeholder
        field.appearance = NSAppearance(named: context.environment.colorScheme == .dark ? .darkAqua : .aqua)
        if context.coordinator.lastFocus != focusToken {
            context.coordinator.lastFocus = focusToken
            DispatchQueue.main.async { [weak field] in
                guard let field, let window = field.window, window.isKeyWindow else { return }
                window.makeFirstResponder(field)
            }
        }
    }
    final class Coordinator: NSObject, NSSearchFieldDelegate {
        var text: Binding<String>
        var lastFocus: UUID?
        init(text: Binding<String>) { self.text = text }
        func controlTextDidChange(_ notification: Notification) {
            if let field = notification.object as? NSSearchField { text.wrappedValue = field.stringValue }
        }
    }
}

struct ClipCard: View {
    let clip: Clip
    let index: Int
    let selected: Bool
    @ObservedObject var store: ClipboardStore
    @State private var hovering = false
    @State private var expanded = false

    private var icon: String { clip.kind == .image ? "photo" : clip.kind == .link ? "link" : clip.isCode ? "chevron.left.forwardslash.chevron.right" : "text.alignleft" }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(.secondary)
                Text(clip.sourceName).foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Text(clip.createdAt, style: .relative).foregroundStyle(.secondary)
                if clip.pinned { Image(systemName: "pin.fill").foregroundStyle(.secondary).accessibilityLabel("Pinned") }
                Menu {
                    Button(store.pasteEnabled ? "Paste" : "Copy") { store.choose?(clip, false) }
                    if clip.kind != .image { Button(store.pasteEnabled ? "Paste as Plain Text" : "Copy as Plain Text") { store.choose?(clip, true) } }
                    Divider()
                    Button(clip.pinned ? "Unpin" : "Pin") { store.pin(clip) }
                    Button("Preview") { expanded = true }
                    Divider()
                    Button("Delete", role: .destructive) { store.delete(clip) }
                } label: { Image(systemName: "ellipsis").foregroundStyle(.secondary).frame(width: 18, height: 16) }
                    .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize().help("More actions").accessibilityLabel("More actions for clipboard item")
            }.font(.caption)
            if clip.kind == .image, let image = clip.previewImage {
                Image(nsImage: image).resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: 130).clipShape(RoundedRectangle(cornerRadius: 5))
            } else if clip.kind == .link {
                VStack(alignment: .leading, spacing: 3) {
                    Text(clip.hostname ?? "Link").font(.body).fontWeight(.medium)
                    Text(clip.text).font(.callout).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                }
            } else {
                Text(String(clip.text.prefix(600)))
                    .font(clip.isCode ? .system(.callout, design: .monospaced) : .body)
                    .lineLimit(3).lineSpacing(2).frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
                Text(clip.subtitle).foregroundStyle(.secondary)
                Spacer()
                Text(index < 9 ? "⌘\(index + 1)" : "↵").foregroundStyle(.secondary).opacity(hovering || selected ? 1 : 0)
            }.font(.caption2)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(MacStyle.surface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).fill(MacStyle.accent.opacity(selected ? 0.10 : hovering ? 0.04 : 0)).allowsHitTesting(false))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(selected ? MacStyle.accent : MacStyle.separator.opacity(0.5), lineWidth: selected ? 1.5 : 0.5))
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture { store.choose?(clip, NSEvent.modifierFlags.contains(.shift)) }
        .onHover { if !store.preview { hovering = $0 } }
        .contextMenu {
            Button(clip.pinned ? "Unpin" : "Pin") { store.pin(clip) }
            Button("Preview") { expanded = true }
            if clip.kind != .image { Button("Copy as Plain Text") { if store.copy(clip, plain: true) { store.toast("Copied as plain text") } } }
            Button("Delete", role: .destructive) { store.delete(clip) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(clip.kind.rawValue) from \(clip.sourceName)")
        .accessibilityAction { store.choose?(clip, false) }
        .popover(isPresented: $expanded, arrowEdge: .leading) {
            ScrollView {
                if let image = clip.previewImage { Image(nsImage: image).resizable().scaledToFit().frame(maxWidth: 580, maxHeight: 500) }
                else { Text(clip.text).font(clip.isCode ? .system(.body, design: .monospaced) : .body).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
            }.padding(20).frame(width: 420, height: 360)
        }
    }
}

extension Clip {
    var previewImage: NSImage? {
        guard kind == .image, let data = formats["public.png"] ?? formats["public.tiff"] else { return nil }
        return NSImage(data: data)
    }
}

extension Notification.Name {
    static let panelOpened = Notification.Name("VelopastePanelOpened")
    static let focusClipboardSearch = Notification.Name("VelopasteFocusSearch")
}
