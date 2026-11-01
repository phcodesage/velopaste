import Carbon

@MainActor
final class HotKey {
    private var reference: EventHotKeyRef?
    private var handler: EventHandlerRef?
    var onPress: (() -> Void)?

    init() {
        var event = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            MainActor.assumeIsolated {
                Unmanaged<HotKey>.fromOpaque(context).takeUnretainedValue().onPress?()
            }
            return noErr
        }, 1, &event, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }
    func register(_ shortcut: String) -> Bool {
        if let reference { UnregisterEventHotKey(reference); self.reference = nil }
        let modifiers: Int
        switch shortcut {
        case "⌘⇧V": modifiers = cmdKey | shiftKey
        case "⌃⌥V": modifiers = controlKey | optionKey
        default: modifiers = optionKey
        }
        let identity = EventHotKeyID(signature: 0x56454C4F, id: 1)
        return RegisterEventHotKey(UInt32(kVK_ANSI_V), UInt32(modifiers), identity, GetApplicationEventTarget(), 0, &reference) == noErr
    }
}
