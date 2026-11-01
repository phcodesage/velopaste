import Foundation
import CryptoKit
import Security

/// No network or third-party dependencies. Only encrypted clipboard payloads reach disk.
final class Vault: Sendable {
    let url: URL
    private let key: SymmetricKey

    static func historyURL() throws -> URL {
        let folder = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("Velopaste", isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        return folder.appendingPathComponent("history.encrypted")
    }
    init() throws {
        url = try Self.historyURL()
        key = try Self.loadKey()
    }
    init(url: URL, key: SymmetricKey) {
        self.url = url
        self.key = key
    }
    private static func loadKey() throws -> SymmetricKey {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: "app.velopaste.history",
                                    kSecAttrAccount as String: "local-history-v1"]
        var lookup = query
        lookup[kSecReturnData as String] = true
        lookup[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(lookup as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data, data.count == 32 { return SymmetricKey(data: data) }
        guard status == errSecItemNotFound else { throw VaultError.keychain(status) }
        let newKey = SymmetricKey(size: .bits256)
        var addition = query
        addition[kSecValueData as String] = newKey.withUnsafeBytes { Data($0) }
        addition[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let added = SecItemAdd(addition as CFDictionary, nil)
        guard added == errSecSuccess else { throw VaultError.keychain(added) }
        return newKey
    }
    func read() throws -> [Clip] {
        guard FileManager.default.fileExists(atPath: url.path) else { return [] }
        let bytes = try Data(contentsOf: url)
        let box = try AES.GCM.SealedBox(combined: bytes)
        return try JSONDecoder().decode([Clip].self, from: AES.GCM.open(box, using: key))
    }
    func write(_ clips: [Clip]) throws {
        let bytes = try JSONEncoder().encode(clips)
        let sealed = try AES.GCM.seal(bytes, using: key)
        guard let combined = sealed.combined else { throw VaultError.encoding }
        try combined.write(to: url, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }
    func delete() throws {
        if FileManager.default.fileExists(atPath: url.path) { try FileManager.default.removeItem(at: url) }
    }
    enum VaultError: Error { case keychain(OSStatus), encoding }
}
