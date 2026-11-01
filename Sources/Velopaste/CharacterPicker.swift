import SwiftUI

struct CharacterPicker: View {
    @ObservedObject var store: ClipboardStore
    @State private var category = "All"
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    struct CharacterItem {
        let value: String
        let keywords: String
        let category: String
    }
    private var catalog: [CharacterItem] { store.mode == .emoji ? Self.emoji : Self.symbols }
    private var categories: [String] { ["All"] + catalog.map(\.category).reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } } }
    private var matches: [CharacterItem] {
        catalog.filter { (category == "All" || $0.category == category) && (store.query.isEmpty || $0.keywords.localizedCaseInsensitiveContains(store.query) || $0.value.contains(store.query)) }
    }
    var body: some View {
        VStack(spacing: 13) {
            Picker("Category", selection: $category) {
                ForEach(categories, id: \.self) { Text($0).tag($0) }
            }.labelsHidden().pickerStyle(.segmented).controlSize(.small)
            if matches.isEmpty {
                Spacer()
                Text("No matching characters").font(.body).foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(matches, id: \.value) { item in
                            Button { store.chooseText(item.value) } label: {
                                Text(item.value).font(.system(size: store.mode == .emoji ? 26 : 22))
                                    .frame(maxWidth: .infinity).frame(height: 44)
                                    .background(MacStyle.surface, in: RoundedRectangle(cornerRadius: 6))
                            }.buttonStyle(.plain).help(item.keywords).accessibilityLabel(item.keywords)
                        }
                    }.padding(.bottom, 15)
                }
            }
        }.padding(.horizontal, 16).frame(maxHeight: .infinity)
            .onChange(of: store.mode) { _ in category = "All" }
    }
    private static func group(_ category: String, _ entries: [(String, String)]) -> [CharacterItem] {
        entries.map { CharacterItem(value: $0.0, keywords: $0.1, category: category) }
    }
    static let emoji = group("Faces", [
        ("😀", "grinning happy smile"), ("😃", "smiley happy"), ("😄", "smile happy eyes"), ("😁", "beaming grin"), ("😆", "laughing satisfied"), ("😅", "sweat smile relief"), ("😂", "tears joy laughing"),
        ("🤣", "rolling floor laughing"), ("😊", "blush happy"), ("🙂", "slightly smiling"), ("😉", "wink"), ("😍", "heart eyes love"), ("🥰", "smiling hearts love"), ("😘", "kiss heart"),
        ("😎", "cool sunglasses"), ("🤩", "star struck excited"), ("🥳", "party celebration"), ("🤔", "thinking consider"), ("🫡", "salute yes"), ("🤗", "hug embrace"), ("🤫", "shush quiet"),
        ("😴", "sleep tired"), ("🥹", "holding tears touched"), ("😭", "cry sob tears"), ("😬", "grimace awkward"), ("🙃", "upside down"), ("😇", "angel innocent"), ("🤯", "mind blown")
    ]) + group("Gestures", [
        ("👍", "thumbs up yes good"), ("👎", "thumbs down no"), ("👏", "clap applause"), ("🙌", "raised hands hooray"), ("👋", "wave hello goodbye"), ("🤝", "handshake agreement"), ("🙏", "pray thanks please"),
        ("✌️", "peace victory"), ("🤞", "crossed fingers luck"), ("💪", "muscle strong"), ("👌", "okay perfect"), ("🫶", "heart hands love"), ("👀", "eyes look"), ("🧠", "brain idea")
    ]) + group("Things", [
        ("✨", "sparkles magic"), ("🎉", "party popper celebration"), ("🚀", "rocket launch ship"), ("💡", "light bulb idea"), ("🔥", "fire hot"), ("❤️", "red heart love"), ("💜", "purple heart love"),
        ("✅", "check done yes"), ("❌", "cross no wrong"), ("⚡️", "lightning energy fast"), ("⭐️", "star favorite"), ("🌈", "rainbow colors"), ("☀️", "sun sunny"), ("🌙", "moon night"),
        ("☕️", "coffee tea"), ("🍕", "pizza food"), ("🥑", "avocado"), ("🌱", "seedling plant growth"), ("🐈", "cat"), ("🐶", "dog puppy"), ("🦋", "butterfly"),
        ("💻", "laptop computer"), ("📋", "clipboard"), ("📌", "pin pushpin"), ("📎", "paperclip"), ("🎨", "art paint design"), ("🎵", "music note"), ("🎯", "target goal")
    ])
    static let symbols = group("Useful", [
        ("©", "copyright"), ("®", "registered"), ("™", "trademark"), ("°", "degree"), ("•", "bullet"), ("·", "middle dot"), ("…", "ellipsis"),
        ("—", "em dash"), ("–", "en dash"), ("§", "section"), ("¶", "paragraph"), ("†", "dagger"), ("‡", "double dagger"), ("№", "number")
    ]) + group("Arrows", [
        ("←", "left arrow"), ("→", "right arrow"), ("↑", "up arrow"), ("↓", "down arrow"), ("↔", "left right arrow"), ("↗", "up right arrow"), ("↘", "down right arrow"),
        ("↵", "return enter"), ("⇧", "shift"), ("⌘", "command"), ("⌥", "option alt"), ("⌃", "control"), ("⇥", "tab")
    ]) + group("Math", [
        ("±", "plus minus"), ("×", "multiply times"), ("÷", "divide"), ("≠", "not equal"), ("≈", "approximately"), ("≤", "less equal"), ("≥", "greater equal"),
        ("∞", "infinity"), ("√", "square root"), ("π", "pi"), ("∑", "sum sigma"), ("∆", "delta difference"), ("½", "one half fraction"), ("¼", "one quarter fraction"), ("¾", "three quarters fraction")
    ]) + group("Currency", [
        ("$", "dollar"), ("€", "euro"), ("£", "pound"), ("¥", "yen yuan"), ("₱", "peso"), ("₹", "rupee"), ("₩", "won"), ("₿", "bitcoin"), ("¢", "cent")
    ])
}
