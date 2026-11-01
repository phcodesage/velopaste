import SwiftUI
import AppKit

private let violet = Color(red: 0.43, green: 0.34, blue: 0.91)

struct PanelView: View {
    @ObservedObject var store: ClipboardStore
    @Environment(\.colorScheme) private var scheme
    @FocusState private var searchFocused: Bool
    @State private var confirmingClear = false
    private var background: Color { scheme == .dark ? Color(red: 0.105, green: 0.11, blue: 0.14) : Color(red: 0.97, green: 0.966, blue: 0.985) }

    var body: some View {
        VStack(spacing: 0) {
            brandBar
            if store.showingSettings {
                SettingsView(store: store)
            } else {
                workspace
            }
            footer
        }
        .frame(width: 410, height: 640)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.primary.opacity(0.09), lineWidth: 1))
        .tint(violet)
        .preferredColorScheme(store.colorScheme)
        .onAppear { searchFocused = true }
        .onReceive(NotificationCenter.default.publisher(for: .panelOpened)) { _ in
            searchFocused = true
        }
        .alert("Clear clipboard history?", isPresented: $confirmingClear) {
            Button("Cancel", role: .cancel) { }
            Button("Clear history", role: .destructive) { store.clear() }
        } message: { Text("Unpinned items will be deleted. Your pinned items and current system clipboard are kept.") }
    }
    private var brandBar: some View {
        HStack(spacing: 9) {
            ZStack {
                RoundedRectangle(cornerRadius: 9).fill(LinearGradient(colors: [violet, Color(red: 0.57, green: 0.43, blue: 0.97)], startPoint: .bottomLeading, endPoint: .topTrailing))
                Image(systemName: "doc.on.clipboard.fill").font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
            }.frame(width: 32, height: 32)
            Text("velopaste").font(.system(size: 16, weight: .bold, design: .rounded)).tracking(-0.5)
            Spacer()
            Text("YOUR COPY, KEPT.").font(.system(size: 8, weight: .bold)).tracking(1.25).foregroundStyle(.secondary)
            Button { store.dismiss?() } label: { Image(systemName: "xmark").font(.system(size: 10, weight: .semibold)).frame(width: 24, height: 24) }
                .buttonStyle(.plain).foregroundStyle(.secondary).help("Close · Esc").accessibilityLabel("Close panel")
        }.padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 17)
    }
    private var workspace: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(ClipboardStore.PanelMode.allCases, id: \.self) { mode in
                    Button {
                        store.mode = mode
                        store.query = ""
                        searchFocused = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon).font(.system(size: 13))
                            Text(mode.rawValue).font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundStyle(store.mode == mode ? violet : .secondary)
                        .frame(maxWidth: .infinity).frame(height: 35)
                        .background(store.mode == mode ? violet.opacity(scheme == .dark ? 0.2 : 0.09) : .clear, in: RoundedRectangle(cornerRadius: 10))
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 20)
            HStack(alignment: .firstTextBaseline) {
                Text(store.mode == .clipboard ? "Clipboard history" : store.mode == .emoji ? "A little expression." : "Find your character.")
                    .font(.system(size: 23, weight: .bold)).tracking(-0.8)
                Spacer()
                if store.mode == .clipboard {
                    Button("Clear all") { confirmingClear = true }
                        .font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary).buttonStyle(.plain)
                        .disabled(!store.history.items.contains { !$0.pinned })
                }
            }.padding(.horizontal, 22).padding(.top, 23).padding(.bottom, 5)
            HStack {
                Text(store.mode == .clipboard ? "Good things are worth keeping." : "The right touch, one click away.")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
                Spacer()
            }.padding(.horizontal, 22).padding(.bottom, 17)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 13)).foregroundStyle(.secondary)
                TextField(store.mode == .clipboard ? "Search your copies…" : "Search \(store.mode.rawValue.lowercased())…", text: $store.query)
                    .textFieldStyle(.plain).font(.system(size: 12)).focused($searchFocused)
                    .accessibilityLabel("Search")
                if !store.query.isEmpty {
                    Button { store.query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.tertiary) }.buttonStyle(.plain).accessibilityLabel("Clear search")
                } else {
                    Text("⌘F").font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(.tertiary)
                }
            }.padding(.horizontal, 12).frame(height: 38)
                .background(scheme == .dark ? Color.white.opacity(0.045) : .white.opacity(0.85), in: RoundedRectangle(cornerRadius: 11))
                .overlay(RoundedRectangle(cornerRadius: 11).strokeBorder(.primary.opacity(0.07)))
                .padding(.horizontal, 20)
            if store.mode == .clipboard {
                filters.padding(.top, 13).padding(.bottom, 12)
                clipboardContent
            } else {
                CharacterPicker(store: store).padding(.top, 15)
            }
        }
        .onChange(of: store.query) { _ in store.selectedID = nil }
        .onChange(of: store.filter) { _ in store.selectedID = nil }
        .background {
            Button("") { searchFocused = true }.keyboardShortcut("f").hidden()
        }
    }
    private var filters: some View {
        HStack(spacing: 6) {
            ForEach(ClipFilter.allCases, id: \.self) { filter in
                Button { store.filter = filter } label: {
                    HStack(spacing: 4) {
                        if filter == .pinned { Image(systemName: "pin.fill").font(.system(size: 9)) }
                        Text(filter.rawValue).font(.system(size: 10, weight: .semibold))
                        if filter == .all { Text("\(store.history.items.count)").font(.system(size: 9, weight: .bold)).opacity(0.7) }
                    }.padding(.horizontal, 11).frame(height: 26)
                        .background(store.filter == filter ? violet : .primary.opacity(0.045), in: Capsule())
                        .foregroundStyle(store.filter == filter ? .white : .secondary)
                }.buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }.padding(.horizontal, 20)
    }
    private var clipboardContent: some View {
        Group {
            if store.items.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 9) {
                            HStack {
                                Text(store.filter == .pinned ? "ALWAYS WITHIN REACH" : store.query.isEmpty ? "RECENT COPIES" : "SEARCH RESULTS")
                                    .font(.system(size: 8, weight: .bold)).tracking(1.5).foregroundStyle(.tertiary)
                                Spacer()
                                Text("\(store.items.count) \(store.items.count == 1 ? "item" : "items")").font(.system(size: 9)).foregroundStyle(.tertiary)
                            }.padding(.horizontal, 2).padding(.bottom, 1)
                            ForEach(Array(store.items.enumerated()), id: \.element.id) { index, clip in
                                ClipCard(clip: clip, index: index, selected: clip.id == store.selectedID, store: store)
                                    .id(clip.id)
                            }
                        }.padding(.horizontal, 20).padding(.top, 2).padding(.bottom, 14)
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
            ZStack {
                Circle().fill(violet.opacity(0.065)).frame(width: 100, height: 100)
                RoundedRectangle(cornerRadius: 10).fill(violet.opacity(0.13)).frame(width: 42, height: 53).rotationEffect(.degrees(-13)).offset(x: -9, y: -2)
                Image(systemName: store.query.isEmpty ? (store.filter == .pinned ? "pin.fill" : "doc.on.clipboard") : "magnifyingglass")
                    .font(.system(size: 32, weight: .light)).foregroundStyle(violet).offset(x: 4, y: 2)
            }
            Text(store.query.isEmpty ? store.filter == .all ? "Your next copy starts here." : "Nothing here just yet." : "No matching copies.")
                .font(.system(size: 16, weight: .semibold)).tracking(-0.4)
            Text(store.query.isEmpty ? (store.filter == .pinned ? "Pin a copy to keep it close, even after\nyou clear your history." : "Copy some text or an image, then press\n\(store.shortcut) to find it here.") : "Try a different word or search by app.")
                .font(.system(size: 12)).foregroundStyle(.secondary).multilineTextAlignment(.center).lineSpacing(4)
            if store.filter == .all && store.query.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield").font(.system(size: 10))
                    Text("On your Mac. Always.").font(.system(size: 10))
                }.foregroundStyle(.tertiary).padding(.top, 6)
            }
            Spacer()
            Spacer().frame(height: 12)
        }.frame(maxWidth: .infinity)
    }
    private var footer: some View {
        VStack(spacing: 0) {
            if let warning = store.storageWarning ?? store.shortcutWarning {
                Text(warning).font(.system(size: 10)).foregroundStyle(.orange).padding(10).frame(maxWidth: .infinity)
            }
            if let notice = store.notice {
                Text(notice).font(.system(size: 11, weight: .medium)).foregroundStyle(violet).padding(.bottom, 9)
            }
            Rectangle().fill(.primary.opacity(0.07)).frame(height: 1)
            HStack(spacing: 6) {
                Circle().fill(store.isPaused ? .orange : Color(red: 0.25, green: 0.67, blue: 0.47)).frame(width: 5, height: 5)
                Button { store.isPaused.toggle() } label: {
                    Text(store.isPaused ? "Paused" : "Listening").font(.system(size: 10, weight: .medium))
                }.buttonStyle(.plain).foregroundStyle(.secondary).help("Pause or resume clipboard history")
                Spacer()
                Text(store.showingSettings ? "Made for your flow." : store.pasteEnabled ? "↵ paste   ·   ↑↓ navigate" : "↵ copy   ·   ⌘V paste")
                    .font(.system(size: 9)).foregroundStyle(.secondary)
                Spacer()
                Text(store.shortcut).font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(.secondary)
                    .padding(.horizontal, 6).padding(.vertical, 3).background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 4))
                Button { store.showingSettings.toggle() } label: {
                    Image(systemName: store.showingSettings ? "arrow.left" : "gearshape").font(.system(size: 13)).frame(width: 23, height: 24)
                }.buttonStyle(.plain).foregroundStyle(.secondary).help(store.showingSettings ? "Back to clipboard" : "Settings").accessibilityLabel("Settings")
            }.padding(.horizontal, 20).frame(height: 46)
        }
    }
}

struct ClipCard: View {
    let clip: Clip
    let index: Int
    let selected: Bool
    @ObservedObject var store: ClipboardStore
    @Environment(\.colorScheme) private var scheme
    @State private var hovering = false
    @State private var expanded = false

    private var icon: String { clip.kind == .image ? "photo" : clip.kind == .link ? "link" : clip.isCode ? "chevron.left.forwardslash.chevron.right" : "text.alignleft" }
    private var accent: Color { clip.kind == .link ? .blue : clip.isCode ? .orange : violet }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 10, weight: .semibold)).foregroundStyle(accent)
                Text(clip.sourceName).font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
                Text("·").foregroundStyle(.tertiary)
                Text(clip.createdAt, style: .relative).font(.system(size: 9)).foregroundStyle(.tertiary)
                Spacer(minLength: 0)
                if clip.pinned { Image(systemName: "pin.fill").font(.system(size: 9)).foregroundStyle(violet).accessibilityLabel("Pinned") }
                Menu {
                    Button(store.pasteEnabled ? "Paste" : "Copy") { store.choose?(clip, false) }
                    if clip.kind != .image { Button(store.pasteEnabled ? "Paste as plain text" : "Copy as plain text") { store.choose?(clip, true) } }
                    Divider()
                    Button(clip.pinned ? "Unpin" : "Pin") { store.pin(clip) }
                    Button("Preview") { expanded = true }
                    Divider()
                    Button("Delete", role: .destructive) { store.delete(clip) }
                } label: { Image(systemName: "ellipsis").font(.system(size: 12, weight: .bold)).foregroundStyle(.secondary).frame(width: 19, height: 16) }
                    .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize().help("More actions").accessibilityLabel("More actions for clipboard item")
            }
            if clip.kind == .image, let image = clip.previewImage {
                Image(nsImage: image).resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else if clip.kind == .link {
                VStack(alignment: .leading, spacing: 4) {
                    Text(clip.hostname ?? "Link").font(.system(size: 13, weight: .semibold)).foregroundStyle(.primary)
                    Text(clip.text).font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                }
            } else {
                Text(String(clip.text.prefix(600)))
                    .font(.system(size: clip.isCode ? 11 : 13, weight: .regular, design: clip.isCode ? .monospaced : .default))
                    .foregroundStyle(.primary.opacity(0.9)).lineLimit(3).lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if hovering || selected {
                HStack {
                    Text(clip.subtitle).font(.system(size: 9)).foregroundStyle(.tertiary)
                    Spacer()
                    Text(index < 9 ? "⌘\(index + 1)" : "↵").font(.system(size: 9, design: .monospaced)).foregroundStyle(violet)
                }
            }
        }
        .padding(13).frame(maxWidth: .infinity, alignment: .leading)
        .background(scheme == .dark ? Color.white.opacity(hovering || selected ? 0.075 : 0.035) : .white.opacity(hovering || selected ? 1 : 0.85), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selected ? violet.opacity(0.75) : hovering ? violet.opacity(0.3) : .primary.opacity(0.065), lineWidth: selected ? 1.5 : 1))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture { store.choose?(clip, NSEvent.modifierFlags.contains(.shift)) }
        .onHover { if !store.preview { hovering = $0 } }
        .contextMenu {
            Button(clip.pinned ? "Unpin" : "Pin") { store.pin(clip) }
            Button("Preview") { expanded = true }
            if clip.kind != .image { Button("Copy as plain text") { if store.copy(clip, plain: true) { store.toast("Copied as plain text") } } }
            Button("Delete", role: .destructive) { store.delete(clip) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(clip.kind.rawValue) from \(clip.sourceName)")
        .popover(isPresented: $expanded, arrowEdge: .leading) {
            ScrollView {
                if let image = clip.previewImage {
                    Image(nsImage: image).resizable().scaledToFit().frame(maxWidth: 580, maxHeight: 500)
                } else {
                    Text(clip.text).font(.system(size: 13, design: clip.isCode ? .monospaced : .default)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                }
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

extension Notification.Name { static let panelOpened = Notification.Name("VelopastePanelOpened") }
