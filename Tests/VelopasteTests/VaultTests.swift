import XCTest
import CryptoKit
@testable import Velopaste

final class VaultTests: XCTestCase {
    func testEncryptedRoundTripTamperDetectionAndDeletion() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("history.encrypted")
        let vault = Vault(url: url, key: SymmetricKey(size: .bits256))
        let secret = "This private clipboard content must never be plaintext on disk"
        let clip = Clip(text: secret, formats: ["public.utf8-plain-text": Data(secret.utf8)], kind: .text, sourceName: "Test", sourceBundleID: "test")
        XCTAssertEqual(try vault.read(), [])
        try vault.write([clip])
        XCTAssertEqual(try vault.read(), [clip])
        var bytes = try Data(contentsOf: url)
        XCTAssertNil(bytes.range(of: Data(secret.utf8)))
        let permissions = try FileManager.default.attributesOfItem(atPath: url.path)[.posixPermissions] as? Int
        XCTAssertEqual(permissions, 0o600)
        bytes[bytes.count / 2] ^= 0xFF
        try bytes.write(to: url)
        XCTAssertThrowsError(try vault.read())
        try vault.delete()
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }
}
